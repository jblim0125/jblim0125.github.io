---
layout: post
title: 뉴스 데이터를 위한 PostgreSQL 하이브리드 검색 구축
author: jblim0125
date: 2025-09-30
category: 2025
tags: [RAG, HybridRetrieval, PostgreSQL]
---

대규모 언어 모델을 이용한 뉴스 요약·분석 서비스에서는 최신 기사에서 핵심 정보를 빠르게 회수하는 것이 중요합니다.
PostgreSQL과 pgvector를 활용하면 단일 데이터베이스에서 BM25 기반 키워드 검색과 OpenAI 임베딩 기반 의미 검색을
결합한 하이브리드 검색을 구축할 수 있습니다. 아래는 “타이틀, 본문, 발행일” 컬럼을 가진 뉴스 데이터를 가져와
저장하고, BM25·벡터·RRF를 조합해 검색하는 전체 과정을 순차적으로 정리한 가이드입니다.

## 전체 흐름 한눈에 보기

1. 뉴스 원천 데이터를 수집해 정규화된 스테이징 테이블에 저장합니다.
2. 본문을 청크 단위로 분할하고 전처리한 뒤 OpenAI 임베딩을 생성합니다.
3. PostgreSQL에 pgvector, pg_trgm 확장을 설치하고 검색용 테이블을 설계합니다.
4. 정규화된 텍스트와 임베딩을 함께 적재하고 GIN, IVFFLAT 인덱스를 구축합니다.
5. BM25 스코어와 벡터 유사도를 각각 계산한 뒤 Reciprocal Rank Fusion으로 결합합니다.
6. 검색 결과를 RAG 파이프라인 혹은 사용자 응답에 활용하면서 운영 지표를 모니터링합니다.

## 1단계. 뉴스 데이터 정규화와 스테이징

- 수집한 JSON/CSV를 그대로 본 테이블에 넣지 말고, 최소 컬럼을 갖춘 스테이징 테이블을 둡니다.
- 예시 스키마
  ```sql
  CREATE TABLE staging_news (
      external_id    text PRIMARY KEY,
      title          text,
      body           text,
      published_at   timestamptz,
      source         text,
      category       text,
      raw_payload    jsonb,
      ingested_at    timestamptz DEFAULT now()
  );
  ```
- 이 단계에서 중복 제거, 발행일 타임존 정규화, HTML 태그 제거, 소스별 품질 검증을 수행합니다.

## 2단계. 본문 분할과 전처리

- 문서 전체를 그대로 검색하면 긴 기사 때문에 BM25 점수가 희석됩니다. 300~500 토큰 기준으로 기사 본문을 문단 단위 청크로 자릅니다.
- 각 청크에 기사 제목, 발행일, 문단 순서를 메타데이터로 부여해 역추적이 가능하도록 합니다.
- Stopword 제거·소문자 변환 후 PostgreSQL `'korean'` 텍스트 검색 구성이 조사·어미를 정규화해 주므로, 형태소 분석기를 직접 붙이기 어렵더라도 `pg_trgm` 기반 trigram 매칭과 결합하면 충분한 재현율을 얻을 수 있습니다.

## 3단계. PostgreSQL 확장 설치와 환경 준비

1. pgvector 및 텍스트 검색 확장을 설치합니다.

   ```bash
   sudo apt install postgresql-15-pgvector
   ```

2. 데이터베이스 접속 후 확장을 활성화합니다.

   ```sql
   CREATE EXTENSION IF NOT EXISTS vector;
   CREATE EXTENSION IF NOT EXISTS pg_trgm;
   ```

3. 대량 검색을 대비해 워크로드 파라미터를 조정합니다.

   ```sql
   SET maintenance_work_mem = '1GB';
   SET vector_ann_probes = 10;   -- ivfflat 탐색 정확도 조정
   ```

## 3.5단계. 한국어 텍스트 검색 구성 정비

- `plainto_tsquery('korean', ...)`를 활용하려면 `tsvector` 또한 동일한 `'korean'` 구성으로 생성되어야 토큰화 기준이 일치합니다.
- `'simple'` 구성은 공백 단위 분리에 의존해 조사·어미가 포함된 상태로 저장되므로, 자연어 질의에서는 `'korean'` 구성으로 전환할 때 검색 재현율이 크게 개선됩니다.
- `ALTER DATABASE yourdb SET default_text_search_config = 'pg_catalog.korean';`으로 기본 구성을 지정하면 애플리케이션 코드의 명시를 줄일 수 있습니다.
- `ALTER TEXT SEARCH CONFIGURATION korean ADD MAPPING FOR hword, hword_part WITH korean_stem;`처럼 사용자 사전을 추가해 도메인 전문 용어를 확장할 수 있습니다.
- 구성 전환 후에는 기존 `tsvector` 컬럼을 재생성하거나 관련 GIN 인덱스를 `REINDEX` 해야 변경된 토큰이 반영됩니다.

## 4단계. 운영 스키마 설계

뉴스 검색 파이프라인에서는 기사 단위 메타데이터와 청크 단위 본문을 나눠 저장하는 것이 유용합니다.

```sql
CREATE TABLE news_articles (
    article_id     bigserial PRIMARY KEY,
    external_id    text UNIQUE,
    title          text        NOT NULL,
    published_at   timestamptz NOT NULL,
    source         text,
    category       text,
    created_at     timestamptz DEFAULT now(),
    updated_at     timestamptz DEFAULT now()
);
CREATE TABLE news_article_chunks (
    chunk_id       bigserial PRIMARY KEY,
    article_id     bigint      NOT NULL REFERENCES news_articles(article_id) ON DELETE CASCADE,
    chunk_index    integer     NOT NULL,
    title          text        NOT NULL,
    content        text        NOT NULL,
    keywords       text[],
    embedding      vector(1536) NOT NULL,
    search_tsv     tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('korean', title), 'A') ||
        setweight(to_tsvector('korean', content), 'B') ||
        setweight(to_tsvector('simple', coalesce(array_to_string(keywords, ' '), '')), 'C')
    ) STORED,
    published_at   timestamptz NOT NULL,
    created_at     timestamptz DEFAULT now(),
    updated_at     timestamptz DEFAULT now(),
    UNIQUE(article_id, chunk_index)
);
CREATE INDEX ON news_article_chunks USING gin (search_tsv);
CREATE INDEX ON news_article_chunks USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
CREATE INDEX ON news_article_chunks (published_at DESC);
```
- `vector(1536)`은 OpenAI `text-embedding-3-large` 기준입니다. 모델 차원에 맞게 수정합니다.
- `search_tsv` 컬럼은 저장 시 자동 갱신되므로 애플리케이션에서 텍스트 검색용 인덱스를 직접 다룰 필요가 없습니다. 
  제목·본문은 `'korean'` 구성으로, 영문 비중이 높은 키워드는 `'simple'` 구성을 혼용했습니다.
- `setweight(..., 'A'|'B'|'C'|'D')` 조합은 기본 랭킹에서 제목(A)·키워드(C)에 더 큰 가중치를 주는 기반이 되며,
  검색 시 `ts_rank_cd('{0.05,0.7,0.3,1.0}', search_tsv, ...)`처럼 (배열 순서: D,C,B,A) 가중치 배열을 지정해 점수를 세밀하게 조정할 수 있습니다.
- `keywords` 컬럼은 원문 기사에서 추출한 핵심 키워드 배열을 저장하며, 청크 전처리 단계에서 `extract_keywords` 같은 유틸리티 함수로 생성합니다.
- `content` 컬럼은 기사 전체가 아닌 분할된 청크 텍스트를 담아 BM25 랭킹의 희석을 방지하고, 동일 기사 내에서도 문단별로 세밀하게 검색할 수 있도록 합니다.
- 텍스트 검색 인덱스로는 조회 성능이 뛰어난 `GIN`을 기본으로 사용하고, 업데이트 비용이 중요하거나 다른 자료형과 결합한
  쿼리에는 `GiST` 보조 인덱스를 추가로 고려합니다.
- 기사 발행일은 정렬과 필터링에 자주 사용되므로 별도 컬럼으로 중복 저장합니다.

### JSON 기반 키워드 저장 옵션

- 키워드를 원문 형태 그대로 남기고 싶다면 `keywords` 대신 `keywords_json jsonb DEFAULT '[]'::jsonb` 컬럼을 사용해 배열을 저장하고, `jsonb_to_tsvector` 결과를 `search_tsv`에 합칠 수 있습니다.
  ```sql
  CREATE TABLE news_article_chunks (
      ...
      keywords_json jsonb DEFAULT '[]'::jsonb,
      search_tsv tsvector GENERATED ALWAYS AS (
          setweight(to_tsvector('korean', title), 'A') ||
          setweight(to_tsvector('korean', content), 'B') ||
          setweight(coalesce(jsonb_to_tsvector('simple', keywords_json), ''::tsvector), 'C')
      ) STORED,
      ...
  );
  CREATE INDEX ON news_article_chunks USING gin (keywords_json jsonb_path_ops);
  ```
- `jsonb_to_tsvector`는 JSON 내 문자열 값을 자동으로 펼쳐 토큰화하므로, 태그·엔티티 등 메타데이터 구조를 유지한 채 검색 가중치에 반영할 수 있습니다. 특정 경로만 추출하려면 세 번째 인수로 `'$[*].value'` 같은 JSONPath를 지정하면 됩니다.
- 적재 파이프라인에서는 `extract_keywords`가 반환한 리스트를 `json.dumps(...)`로 직렬화해 `keywords_json`에 넣고, 필요 시 `to_tsvector('simple', array_to_string(...))` 방식과 병행해 백필드 호환성을 유지할 수 있습니다.

## 5단계. 임베딩 생성과 적재 파이프라인

Python과 OpenAI 임베딩 API를 활용해 청크 데이터를 생성·적재하는 예시는 아래와 같습니다.

```python
import os
from datetime import datetime
import numpy as np
import psycopg
from openai import OpenAI
openai_client = OpenAI(api_key=os.environ["OPENAI_API_KEY"])
def build_chunks(row):
    for idx, chunk_text in enumerate(split_into_chunks(row["body"], max_tokens=350)):
        response = openai_client.embeddings.create(
            model="text-embedding-3-large",
            input=chunk_text,
        )
        yield {
            "chunk_index": idx,
            "title": row["title"],
            "content": chunk_text,
            "keywords": extract_keywords(chunk_text),
            "embedding": np.array(response.data[0].embedding, dtype=np.float32),
        }
with psycopg.connect(os.environ["PG_DSN"]) as conn:
    with conn.cursor() as cur:
        for row in fetch_news_from_staging(cur):  # row는 dict 형태라고 가정
            cur.execute(
                """
                INSERT INTO news_articles (external_id, title, published_at, source, category, updated_at)
                VALUES (%(external_id)s, %(title)s, %(published_at)s, %(source)s, %(category)s, now())
                ON CONFLICT (external_id)
                DO UPDATE SET title = EXCLUDED.title,
                              published_at = EXCLUDED.published_at,
                              source = EXCLUDED.source,
                              category = EXCLUDED.category,
                              updated_at = now()
                RETURNING article_id;
                """,
                row,
            )
            article_id = cur.fetchone()[0]
            for chunk in build_chunks(row):
                cur.execute(
                    """
                    INSERT INTO news_article_chunks (
                        article_id, chunk_index, title, content, keywords, embedding, published_at, updated_at
                    ) VALUES (%(article_id)s, %(chunk_index)s, %(title)s, %(content)s, %(keywords)s, %(embedding)s, %(published_at)s, now())
                    ON CONFLICT (article_id, chunk_index)
                    DO UPDATE SET title = EXCLUDED.title,
                                  content = EXCLUDED.content,
                                  keywords = EXCLUDED.keywords,
                                  embedding = EXCLUDED.embedding,
                                  updated_at = now();
                    """,
                    {
                        **chunk,
                        "article_id": article_id,
                        "published_at": row["published_at"],
                    },
                )
    conn.commit()
```

- `split_into_chunks`, `extract_keywords`는 서비스 상황에 맞춰 구현합니다.
- 임베딩은 `float32`로 캐스팅해야 pgvector가 기대하는 바이너리 형식과 일치합니다.
- 대량 적재 시에는 `execute_batch`나 `COPY`를 사용해 트랜잭션 수를 최소화합니다.

## 6단계. BM25·벡터·RRF 하이브리드 검색 쿼리

먼저 BM25(Built-in `ts_rank_cd`)와 코사인 유사도를 별도로 계산한 후 RRF로 결합합니다.

```sql
WITH query AS (
    SELECT
        '전기차 배터리 화재 원인'::text        AS q_text,
        '[0.12, -0.04, 0.09, ...]'::vector(1536) AS q_embedding,
        '2024-01-01'::date                      AS from_date
),
lexical AS (
    SELECT
        chunk_id,
        article_id,
        row_number() OVER (
            ORDER BY ts_rank_cd('{0.05, 0.7, 0.3, 1.0}', search_tsv, plainto_tsquery('korean', q.q_text)) DESC
        ) AS rank
    FROM news_article_chunks, query q
    WHERE search_tsv @@ websearch_to_tsquery('korean', q.q_text)
      AND published_at >= q.from_date
    LIMIT 500
),
semantic AS (
    SELECT
        chunk_id,
        article_id,
        row_number() OVER (
            ORDER BY embedding <=> q.q_embedding ASC
        ) AS rank
    FROM news_article_chunks, query q
    WHERE published_at >= q.from_date
    ORDER BY embedding <=> q.q_embedding
    LIMIT 500
)
SELECT
    nac.article_id,
    na.title,
    na.published_at,
    nac.content,
    1.0 / (COALESCE(l.rank, 1000) + 60) +
    1.0 / (COALESCE(s.rank, 1000) + 60) AS rrf_score
FROM news_article_chunks nac
JOIN news_articles na ON na.article_id = nac.article_id
LEFT JOIN lexical  l  ON l.chunk_id = nac.chunk_id
LEFT JOIN semantic s  ON s.chunk_id = nac.chunk_id
ORDER BY rrf_score DESC
LIMIT 20;
```

- `websearch_to_tsquery`는 자연어 질의에 강하며, `'korean'` 구성을 사용하면 동일한 질의어라도 조사·어미가 정규화되어 `'simple'` 대비 더 많은 문장이 매칭됩니다. `ts_rank_cd`에 가중치 배열을 넘기면 제목(A=1.0)과 키워드(C=0.7) 등 원하는 필드를 더 높게 반영할 수 있습니다.
- 공백으로 구분된 단어는 기본적으로 AND(`&`)로 결합되므로 OR 검색이 필요하면 질의어를 `전기차 OR 배터리` 혹은 `전기차 | 배터리`처럼 명시적으로 작성하거나, 애플리케이션에서 `foo bar` 패턴을 `foo OR bar`로 전처리합니다.
- RRF 상수 60은 일반적인 시작점입니다. 코사인 유사도 후보를 200~500건으로 제한해도 대부분의 질의에서 품질 저하가 없습니다.
- 결과를 기사 단위로 합산하고 싶다면 `group by article_id` 후 최고 점수를 선택하는 방식으로 조정합니다.

## 7단계. 운영 체크리스트

- **인덱스 유지**: 대량 적재 후 `ANALYZE news_article_chunks;`를 실행하고, 주기적으로 `VACUUM (ANALYZE)`를 돌려 블로트를 줄입니다.
- **구성 확인**: `SELECT to_tsvector('korean', '예시 문장'), plainto_tsquery('korean', '예시 문장');`처럼 토큰과 질의 일치 여부를 수시로 점검하고, 구성 변경 시 `REINDEX` 또는 재적재를 수행합니다.
- **임베딩 재생성**: 제목이나 본문이 변경되면 해당 청크의 임베딩을 즉시 재생성해야 의미 검색 정확도가 유지됩니다.
- **신선도 제어**: `published_at`에 최신 가중치를 주어 최근 뉴스가 더 잘 노출되도록 `ORDER BY rrf_score, published_at DESC` 형태를 고려합니다.
- **모니터링**: `pg_stat_statements`로 질의 빈도와 시간대를 확인하고, IVFFLAT의 `lists`, `probes`를 데이터량에 맞춰 조정합니다.

## 마무리

뉴스 데이터는 시의성과 어휘 다양성이 모두 중요한 영역입니다. PostgreSQL과 pgvector를 활용하면 별도 검색 엔진 없이도 BM25, 임베딩 검색, RRF 결합을 단일 SQL로 처리할 수 있습니다. 위 과정을 차근차근 따라가면 정규화된 저장 구조와 안정적인 검색 품질을 동시에 확보할 수 있으며, 이후에는 재랭킹 모델이나 메타데이터 필터링을 추가해 맞춤형 뉴스 추천·요약 서비스를 확장할 수 있습니다.
