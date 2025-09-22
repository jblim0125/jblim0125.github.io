---
layout: post
title: PostgreSQL을 이용한 하이브리드 검색
author: jblim0125
date: 2025-09-22
category: 2025
tags: [RAG, HybridRetrieval, PostgreSQL]
---

대규모 언어 모델을 활용한 애플리케이션은 이제 단순 요약을 넘어, 기업이 보유한 도메인 지식을 안전하게 활용하는 수준으로 확장되고 있습니다. 이때 검색 품질을 좌우하는 핵심은 얼마나 정확하게, 그리고 얼마나 빠르게 관련 문서를 찾아낼 수 있는가입니다. 하이브리드 검색은 전통적인 키워드 검색과 임베딩을 활용한 의미 검색을 결합해 두 접근법의 장점을 동시에 취할 수 있는 전략이며, PostgreSQL과 pgvector 조합은 이를 단일 데이터베이스에서 구현할 수 있게 해줍니다.

## 하이브리드 검색이 필요한 이유
- 키워드 기반 검색(BM25 등)은 짧은 질의에서 높은 정밀도를 제공하지만, 표현이 달라지면 의미를 놓치기 쉽습니다.
- 임베딩 기반 의미 검색은 패러프레이즈에 강하지만, 너무 일반적인 문서가 함께 노출되거나 최신성을 반영하지 못하는 경우가 잦습니다.
- 두 점수를 결합하면 “문서가 질문과 얼마나 같은 단어를 공유하는지”와 “문서가 질문과 얼마나 비슷한 의미인지”를 동시에 고려할 수 있어, RAG 파이프라인에서 환각을 줄이고 정답률을 높일 수 있습니다.

## PostgreSQL과 pgvector의 조합
### pgvector가 제공하는 기능
- `vector(n)` 타입을 통해 고정 길이 임베딩을 테이블 컬럼으로 저장할 수 있습니다.
- `L2`, `cosine`, `inner product` 세 가지 거리 기반 연산자를 지원하며, `<->`, `<=>`, `<#>` syntax로 사용합니다.
- IVF Flat, HNSW 등 근사 최근접 탐색 인덱스를 제공하여 대규모 벡터 검색 성능을 크게 개선합니다.

### PostgreSQL을 선택하는 이유
- 단일 트랜잭션 안에서 메타데이터, 원문, 임베딩을 함께 관리할 수 있어 데이터 동기화 비용을 줄입니다.
- 파티셔닝, 권한 관리, 복제 등 엔터프라이즈급 운영 기능을 그대로 누릴 수 있습니다.
- `tsvector`, `tsquery`, `GIN` 인덱스를 활용하면 키워드 검색 역시 고성능으로 처리할 수 있습니다.

## 환경 준비하기
1. **pgvector 설치** – PostgreSQL 15 이상을 권장하며, 확장은 패키지 관리자를 통해 설치합니다.
   ```bash
   sudo apt install postgresql-15-pgvector  # 배포판에 따라 패키지명이 다를 수 있음
   ```
2. **확장 활성화** – 데이터베이스 접속 후 확장을 로드합니다.
   ```sql
   CREATE EXTENSION IF NOT EXISTS vector;
   CREATE EXTENSION IF NOT EXISTS pg_trgm;  -- 한글 형태소 분석기가 없다면 trigram 보정용으로 유용
   ```
3. **거리 연산자 설정** – cosine 유사도를 많이 사용하는 경우 `SET vector_ann_probes` 등을 조정해 탐색 품질을 제어할 수 있습니다.

## 문서 스키마 설계
문서를 고정 길이 청크로 분할하고, 텍스트 본문과 메타데이터를 함께 저장하는 스키마 예시는 다음과 같습니다.

```sql
CREATE TABLE knowledge_chunks (
    id              bigserial PRIMARY KEY,
    collection      text        NOT NULL,
    source_id       text        NOT NULL,
    chunk_index     integer     NOT NULL,
    title           text,
    content         text        NOT NULL,
    keywords        text[],
    embedding       vector(1536) NOT NULL,
    search_tsv      tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('simple', coalesce(title, '')), 'A') ||
        setweight(to_tsvector('simple', content), 'B') ||
        setweight(to_tsvector('simple', array_to_string(keywords, ' ')), 'C')
    ) STORED,
    created_at      timestamptz DEFAULT now(),
    updated_at      timestamptz DEFAULT now()
);

CREATE INDEX ON knowledge_chunks USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
CREATE INDEX ON knowledge_chunks USING gin (search_tsv);
CREATE INDEX ON knowledge_chunks (collection, source_id);
```

- `vector(1536)` 차원은 예시이며, 사용하는 임베딩 모델에 맞춰 조정합니다.
- `ivfflat` 인덱스는 근사 탐색을 사용하므로, 로딩 후 `ANALYZE`를 수행해 통계를 갱신해야 성능이 안정됩니다.
- `search_tsv`는 `GENERATED ALWAYS`로 정의해 저장 시 자동으로 갱신되도록 하면 애플리케이션 코드가 단순해집니다.

## 데이터 적재 파이프라인
1. **청크 분할** – 300~500 토큰 단위로 문서를 분할하고, 원문 위치/메타데이터를 저장합니다.
2. **임베딩 생성** – OpenAI, Naver HyperCLOVA, HuggingFace 등 외부 모델을 활용하여 벡터를 생성합니다.
3. **일괄 적재** – `COPY` 혹은 `psycopg`의 `execute_batch`를 이용해 한 번에 여러 행을 적재합니다.
4. **업데이트 전략** – 동일 문서가 다시 적재될 수 있다면 `ON CONFLICT (collection, source_id, chunk_index)` 구문으로 upsert를 구성합니다.

```python
import numpy as np
import psycopg
from datetime import datetime

chunks = [
    {
        "collection": "tech-doc",
        "source_id": "postgres-hybrid-search",
        "chunk_index": 0,
        "title": "하이브리드 검색 개요",
        "content": "...",
        "keywords": ["postgresql", "hybrid"],
        "embedding": np.array(embedding_model.embed("..."), dtype=np.float32),
    }
]

with psycopg.connect(conninfo) as conn:
    with conn.cursor() as cur:
        cur.executemany(
            """
            INSERT INTO knowledge_chunks (
                collection, source_id, chunk_index, title, content, keywords, embedding, updated_at
            ) VALUES (%(collection)s, %(source_id)s, %(chunk_index)s, %(title)s, %(content)s, %(keywords)s, %(embedding)s, %(updated_at)s)
            ON CONFLICT (collection, source_id, chunk_index)
            DO UPDATE SET
                title = EXCLUDED.title,
                content = EXCLUDED.content,
                keywords = EXCLUDED.keywords,
                embedding = EXCLUDED.embedding,
                updated_at = EXCLUDED.updated_at;
            """,
            [{**row, "updated_at": datetime.utcnow()} for row in chunks],
        )
```

## 하이브리드 검색 쿼리 레시피
### 1. 가중 합 기반 스코어링
벡터 유사도와 키워드 점수를 동일 쿼리 안에서 결합할 수 있습니다. cosine 거리 값을 유사도로 변환하고, 문맥에 맞춰 가중치를 조정합니다.

```sql
WITH query AS (
    SELECT
        '배터리 열화 원인을 파악하고 싶어'::text AS q_text,
        '[0.12, 0.04, -0.08, ...]'::vector(1536) AS q_embedding,
        0.6::float8 AS semantic_weight,
        0.4::float8 AS lexical_weight
)
SELECT
    kc.id,
    kc.title,
    kc.source_id,
    ts_rank_cd(kc.search_tsv, plainto_tsquery('simple', query.q_text)) AS lexical_score,
    1 - (kc.embedding <=> query.q_embedding) AS semantic_score,
    query.semantic_weight * (1 - (kc.embedding <=> query.q_embedding)) +
    query.lexical_weight * ts_rank_cd(kc.search_tsv, plainto_tsquery('simple', query.q_text)) AS hybrid_score
FROM knowledge_chunks kc
CROSS JOIN query
WHERE kc.search_tsv @@ plainto_tsquery('simple', query.q_text)
ORDER BY hybrid_score DESC
LIMIT 10;
```

- cosine 거리는 0(일치)~2(정반대) 범위를 가지므로 `1 - distance`로 유사도(0~1 사이)를 만들어 사용합니다.
- 질의어가 너무 짧아 `@@` 필터가 거칠 경우, `||`를 이용해 `phraseto_tsquery`와 `websearch_to_tsquery`를 혼합하거나, lexical 필터 자체를 완화할 수 있습니다.

### 2. Reciprocal Rank Fusion(RRF)
두 결과를 각각 순위화한 뒤 RRF로 결합하면 가중치를 조정하기 쉽고, 특정 점수 스케일에 덜 민감합니다.

```sql
WITH query AS (
    SELECT
        '하이브리드 검색 인덱스 튜닝 방법'::text AS q_text,
        '[0.05, -0.02, 0.11, ...]'::vector(1536) AS q_embedding
),
lexical AS (
    SELECT id, row_number() OVER (ORDER BY ts_rank_cd(search_tsv, plainto_tsquery('simple', q.q_text)) DESC) AS rank
    FROM knowledge_chunks, query q
    WHERE search_tsv @@ plainto_tsquery('simple', q.q_text)
),
semantic AS (
    SELECT id, row_number() OVER (ORDER BY embedding <=> q.q_embedding ASC) AS rank
    FROM knowledge_chunks, query q
    ORDER BY embedding <=> q.q_embedding
    LIMIT 200
)
SELECT
    kc.id,
    kc.title,
    1.0 / (COALESCE(l.rank, 1000) + 60) +
    1.0 / (COALESCE(s.rank, 1000) + 60) AS hybrid_score
FROM knowledge_chunks kc
LEFT JOIN lexical l USING (id)
LEFT JOIN semantic s USING (id)
ORDER BY hybrid_score DESC
LIMIT 10;
```

- `limit 200`과 같은 근사 탐색 범위를 지정해도 전체 스코어 품질이 크게 떨어지지 않습니다.
- RRF 상수(`60`)는 도메인에 맞게 조정해야 하며, 스코어가 0인 문서도 최소 가중치를 부여할 수 있습니다.

### 3. 필터링과 재랭크 조합
- `collection`이나 사용자 권한에 따라 SQL `WHERE` 절에서 필터링하면 애플리케이션 레벨 필터보다 효율적입니다.
- 초기 20개 후보를 고른 뒤, 언어 모델이나 Cross-Encoder를 이용해 재랭크하면서 최종 결과를 결정하는 패턴이 일반적입니다.

## RAG 파이프라인 통합 전략
1. **Pre-Retrieval 정제** – 문서를 수집할 때 정규화, 중복 제거, 출처 저장을 선행합니다.
2. **Retrieval** – 하이브리드 검색 쿼리로 후보 10~20개를 획득합니다.
3. **Post-Retrieval 필터링** – 문서 길이, 작성 시점, 신뢰도 메타데이터를 기준으로 추가 필터를 실행합니다.
4. **재랭크** – 필요 시 Cross-Encoder 모델을 통해 최종 3~5개 문서를 정렬합니다.
5. **LLM 프롬프트 구성** – 하이브리드 점수와 함께 문서 근거를 LLM에 전달하고, 응답 내 증거 표기를 강제합니다.

## 운영 및 최적화 체크리스트
- **ANALYZE 주기** – 대량 적재 후 `ANALYZE knowledge_chunks;`를 실행해 통계를 최신 상태로 유지합니다.
- **인덱스 파라미터 튜닝** – `ivfflat`의 `lists`, `probes` 값을 데이터 규모에 맞게 조정합니다. HNSW 인덱스를 선택하면 `m`, `ef_construction`, `ef_search`를 조율해야 합니다.
- **VACUUM** – 임베딩 업데이트가 잦다면 `VACUUM (ANALYZE)`로 블로트(bloat)를 방지합니다.
- **모니터링** – `pg_stat_statements`, `pgstattuple` 등을 활용해 쿼리 응답 시간과 인덱스 히트율을 지속적으로 추적합니다.
- **백업/복제** – 물리/논리 복제를 구성하면 검색 인덱스를 포함한 전체 파이프라인을 손쉽게 확장할 수 있습니다.

## 마무리
PostgreSQL과 pgvector를 결합하면 별도의 전문 검색엔진 없이도 하이브리드 검색 파이프라인을 구축할 수 있습니다. 핵심은 스키마 설계, 인덱스 파라미터 조정, 그리고 검색 점수를 조합하는 전략을 도메인 특성에 맞게 반복적으로 실험하는 것입니다. 잘 설계된 하이브리드 검색은 RAG 시스템의 정답률을 높이고, 운영 복잡도는 줄이는 가장 현실적인 해결책이 되어줄 것입니다.
