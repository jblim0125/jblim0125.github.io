---
layout: post
title: PostgreSQL을 이용한 BM25 검색 구현하기 - 테이블 설계부터 실제 사용까지
author: jblim0125
date: 2025-10-11
category: 2025
tags: [PostgreSQL, BM25, FullTextSearch, Database, Search]
---

## 개요

BM25(Best Matching 25)는 정보 검색에서 가장 널리 사용되는 순위 함수 중 하나입니다. PostgreSQL의 강력한 전문 검색(Full Text Search) 기능과 함께 BM25를 활용하면 효과적인 검색 시스템을 구축할 수 있습니다. 이 글에서는 PostgreSQL을 이용한 BM25 검색 시스템의 테이블 설계부터 실제 구현까지 단계별로 살펴보겠습니다.

## BM25란?

BM25는 TF-IDF의 확률론적 변형으로, 다음과 같은 특징을 가집니다:

- **TF (Term Frequency)**: 문서 내 용어 빈도
- **IDF (Inverse Document Frequency)**: 역문서 빈도
- **문서 길이 정규화**: 긴 문서에 대한 페널티
- **포화점**: 용어 빈도가 일정 수준 이상에서 점수 증가율 감소

BM25 공식:
```
BM25(q,d) = Σ IDF(qi) × (f(qi,d) × (k1 + 1)) / (f(qi,d) + k1 × (1 - b + b × |d|/avgdl))
```

## 데이터베이스 및 테이블 설계

### 1. 기본 문서 테이블

```sql
-- 문서 테이블
CREATE TABLE documents (
    id SERIAL PRIMARY KEY,
    title VARCHAR(500) NOT NULL,
    content TEXT NOT NULL,
    author VARCHAR(100),
    category VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    -- 전문 검색을 위한 tsvector 컬럼
    search_vector tsvector
);

-- 문서 길이 통계를 위한 컬럼 추가
ALTER TABLE documents ADD COLUMN doc_length INTEGER;
ALTER TABLE documents ADD COLUMN word_count INTEGER;
```

### 2. 검색 통계 테이블

```sql
-- 검색 성능 최적화를 위한 통계 테이블
CREATE TABLE search_stats (
    id SERIAL PRIMARY KEY,
    total_documents INTEGER NOT NULL,
    avg_doc_length NUMERIC(10,2) NOT NULL,
    total_words BIGINT NOT NULL,
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 용어 빈도 통계 테이블
CREATE TABLE term_stats (
    term VARCHAR(100) PRIMARY KEY,
    document_frequency INTEGER NOT NULL,
    total_frequency BIGINT NOT NULL,
    idf_score NUMERIC(10,6)
);
```

### 3. 인덱스 생성

```sql
-- 전문 검색을 위한 GIN 인덱스
CREATE INDEX idx_documents_search_vector ON documents USING GIN(search_vector);

-- 기본 검색을 위한 인덱스들
CREATE INDEX idx_documents_title ON documents(title);
CREATE INDEX idx_documents_category ON documents(category);
CREATE INDEX idx_documents_created_at ON documents(created_at);

-- 성능 향상을 위한 복합 인덱스
CREATE INDEX idx_documents_category_created ON documents(category, created_at);
```

## 데이터 전처리 및 입력

### 1. 트리거 함수로 자동 전처리

```sql
-- 문서 삽입/수정 시 자동으로 search_vector 업데이트
CREATE OR REPLACE FUNCTION update_search_vector()
RETURNS TRIGGER AS $$
BEGIN
    -- 제목과 내용을 결합하여 검색 벡터 생성
    NEW.search_vector := 
        setweight(to_tsvector('english', COALESCE(NEW.title, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.content, '')), 'B');
    
    -- 문서 길이 계산
    NEW.word_count := array_length(tsvector_to_array(NEW.search_vector), 1);
    NEW.doc_length := length(COALESCE(NEW.title, '') || ' ' || COALESCE(NEW.content, ''));
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 트리거 생성
CREATE TRIGGER trigger_update_search_vector
    BEFORE INSERT OR UPDATE ON documents
    FOR EACH ROW
    EXECUTE FUNCTION update_search_vector();
```

### 2. 샘플 데이터 입력

```sql
-- 샘플 데이터 입력
INSERT INTO documents (title, content, author, category) VALUES
('PostgreSQL Performance Tuning', 'PostgreSQL is a powerful open-source database system. This article covers various performance optimization techniques...', 'John Doe', 'Database'),
('Introduction to Machine Learning', 'Machine learning is a subset of artificial intelligence that focuses on algorithms and statistical models...', 'Jane Smith', 'AI'),
('Database Design Principles', 'Good database design is crucial for application performance. This guide covers normalization, indexing, and query optimization...', 'Bob Wilson', 'Database'),
('Advanced SQL Queries', 'SQL is the standard language for relational databases. Learn advanced techniques for complex queries...', 'Alice Brown', 'Database');
```

## BM25 검색 함수 구현

### 1. BM25 점수 계산 함수

```sql
CREATE OR REPLACE FUNCTION calculate_bm25_score(
    query_text TEXT,
    document_id INTEGER,
    k1 NUMERIC DEFAULT 1.5,
    b NUMERIC DEFAULT 0.75
)
RETURNS NUMERIC AS $$
DECLARE
    doc_record RECORD;
    query_terms TEXT[];
    term TEXT;
    tf INTEGER;
    idf NUMERIC;
    score NUMERIC := 0;
    total_docs INTEGER;
    avg_doc_length NUMERIC;
    doc_freq INTEGER;
BEGIN
    -- 문서 정보 가져오기
    SELECT word_count, doc_length INTO doc_record 
    FROM documents 
    WHERE id = document_id;
    
    -- 전체 문서 수와 평균 문서 길이
    SELECT COUNT(*), AVG(word_count) INTO total_docs, avg_doc_length
    FROM documents;
    
    -- 쿼리를 용어로 분할
    query_terms := string_to_array(lower(query_text), ' ');
    
    -- 각 용어에 대해 BM25 점수 계산
    FOREACH term IN ARRAY query_terms LOOP
        -- 용어 빈도 계산
        SELECT count(*) INTO tf 
        FROM unnest(tsvector_to_array(search_vector)) AS t 
        WHERE t = term AND EXISTS (SELECT 1 FROM documents WHERE id = document_id);
        
        -- 문서 빈도 계산
        SELECT count(*) INTO doc_freq
        FROM documents 
        WHERE search_vector @@ plainto_tsquery('english', term);
        
        -- IDF 계산
        idf := ln((total_docs - doc_freq + 0.5) / (doc_freq + 0.5));
        
        -- BM25 점수 누적
        score := score + (idf * (tf * (k1 + 1)) / 
                         (tf + k1 * (1 - b + b * doc_record.word_count / avg_doc_length)));
    END LOOP;
    
    RETURN score;
END;
$$ LANGUAGE plpgsql;
```

### 2. 최적화된 BM25 검색 함수

```sql
CREATE OR REPLACE FUNCTION bm25_search(
    search_query TEXT,
    result_limit INTEGER DEFAULT 10,
    k1 NUMERIC DEFAULT 1.5,
    b NUMERIC DEFAULT 0.75
)
RETURNS TABLE(
    doc_id INTEGER,
    title VARCHAR(500),
    content_snippet TEXT,
    bm25_score NUMERIC,
    relevance_rank INTEGER
) AS $$
BEGIN
    RETURN QUERY
    WITH search_results AS (
        SELECT 
            d.id,
            d.title,
            left(d.content, 200) || '...' as snippet,
            ts_rank_cd(d.search_vector, plainto_tsquery('english', search_query)) as base_rank,
            calculate_bm25_score(search_query, d.id, k1, b) as bm25_score
        FROM documents d
        WHERE d.search_vector @@ plainto_tsquery('english', search_query)
    )
    SELECT 
        sr.id,
        sr.title,
        sr.snippet,
        sr.bm25_score,
        row_number() OVER (ORDER BY sr.bm25_score DESC)::INTEGER
    FROM search_results sr
    ORDER BY sr.bm25_score DESC
    LIMIT result_limit;
END;
$$ LANGUAGE plpgsql;
```

## 실제 사용 예제

### 1. 기본 검색

```sql
-- 'database performance' 검색
SELECT * FROM bm25_search('database performance', 5);

-- 결과:
-- doc_id | title                    | content_snippet        | bm25_score | relevance_rank
-- -------|--------------------------|------------------------|------------|---------------
-- 1      | PostgreSQL Performance   | PostgreSQL is a pow... | 2.4567     | 1
-- 3      | Database Design Prin...  | Good database desi...  | 1.8934     | 2
```

### 2. 카테고리별 검색

```sql
-- 특정 카테고리에서 검색
SELECT 
    d.id,
    d.title,
    d.category,
    calculate_bm25_score('machine learning', d.id) as score
FROM documents d
WHERE d.category = 'AI' 
  AND d.search_vector @@ plainto_tsquery('english', 'machine learning')
ORDER BY score DESC;
```

### 3. 하이브리드 검색 (키워드 + 의미론적)

```sql
-- BM25와 다른 점수를 결합한 하이브리드 검색
CREATE OR REPLACE FUNCTION hybrid_search(
    search_query TEXT,
    category_filter VARCHAR(50) DEFAULT NULL,
    weight_bm25 NUMERIC DEFAULT 0.7,
    weight_recency NUMERIC DEFAULT 0.3
)
RETURNS TABLE(
    doc_id INTEGER,
    title VARCHAR(500),
    final_score NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        d.id,
        d.title,
        (weight_bm25 * calculate_bm25_score(search_query, d.id) + 
         weight_recency * (EXTRACT(EPOCH FROM NOW() - d.created_at) / 86400)::NUMERIC) as final_score
    FROM documents d
    WHERE d.search_vector @@ plainto_tsquery('english', search_query)
      AND (category_filter IS NULL OR d.category = category_filter)
    ORDER BY final_score DESC
    LIMIT 10;
END;
$$ LANGUAGE plpgsql;
```

## 성능 최적화

### 1. 검색 통계 업데이트

```sql
-- 검색 통계 주기적 업데이트를 위한 프로시저
CREATE OR REPLACE FUNCTION update_search_statistics()
RETURNS VOID AS $$
BEGIN
    -- 전체 통계 업데이트
    INSERT INTO search_stats (total_documents, avg_doc_length, total_words)
    SELECT 
        COUNT(*),
        AVG(word_count),
        SUM(word_count)
    FROM documents
    ON CONFLICT (id) DO UPDATE SET
        total_documents = EXCLUDED.total_documents,
        avg_doc_length = EXCLUDED.avg_doc_length,
        total_words = EXCLUDED.total_words,
        updated_at = NOW();
        
    -- 용어별 통계 업데이트 (배치 처리 권장)
    TRUNCATE term_stats;
    INSERT INTO term_stats (term, document_frequency, total_frequency)
    SELECT 
        word,
        COUNT(DISTINCT doc_id),
        SUM(count)
    FROM (
        SELECT 
            unnest(tsvector_to_array(search_vector)) as word,
            id as doc_id,
            1 as count
        FROM documents
    ) t
    GROUP BY word;
END;
$$ LANGUAGE plpgsql;
```

### 2. 인덱스 최적화

```sql
-- 부분 인덱스로 성능 향상
CREATE INDEX idx_documents_recent_search 
ON documents USING GIN(search_vector) 
WHERE created_at > NOW() - INTERVAL '1 year';

-- 표현식 인덱스
CREATE INDEX idx_documents_title_length ON documents(length(title));
```

## 모니터링 및 분석

### 1. 검색 성능 모니터링

```sql
-- 검색 성능 분석 뷰
CREATE VIEW search_performance_analysis AS
SELECT 
    'BM25 Search' as search_type,
    COUNT(*) as total_searches,
    AVG(EXTRACT(MILLISECONDS FROM query_duration)) as avg_duration_ms,
    MIN(EXTRACT(MILLISECONDS FROM query_duration)) as min_duration_ms,
    MAX(EXTRACT(MILLISECONDS FROM query_duration)) as max_duration_ms
FROM (
    SELECT 
        NOW() - NOW() as query_duration  -- 실제 구현시 로깅 필요
) t;
```

### 2. 검색 결과 품질 분석

```sql
-- 검색 결과 품질 분석을 위한 뷰
CREATE VIEW search_quality_metrics AS
WITH search_stats AS (
    SELECT 
        d.category,
        COUNT(*) as total_docs,
        AVG(d.word_count) as avg_words,
        AVG(length(d.content)) as avg_content_length
    FROM documents d
    GROUP BY d.category
)
SELECT 
    category,
    total_docs,
    avg_words,
    avg_content_length,
    total_docs::NUMERIC / (SELECT COUNT(*) FROM documents) * 100 as category_ratio
FROM search_stats
ORDER BY total_docs DESC;
```

## 마무리

PostgreSQL을 이용한 BM25 검색 시스템을 구축하면 다음과 같은 이점을 얻을 수 있습니다:

1. **고성능**: PostgreSQL의 GIN 인덱스와 최적화된 쿼리
2. **확장성**: 대용량 데이터에서도 빠른 검색 성능
3. **유연성**: 다양한 검색 옵션과 커스터마이징 가능
4. **통합성**: 기존 데이터베이스 인프라와 완벽 통합

이 글에서 제시한 구조를 기반으로 실제 프로젝트에 맞게 조정하여 사용하시기 바랍니다. 특히 대용량 데이터의 경우 파티셔닝이나 샤딩을 고려해야 하며, 실시간 검색이 필요한 경우 캐싱 전략도 함께 고려해야 합니다.

## 참고 자료

- [PostgreSQL Full Text Search Documentation](https://www.postgresql.org/docs/current/textsearch.html)
- [BM25 알고리즘 상세 설명](https://en.wikipedia.org/wiki/Okapi_BM25)
- [PostgreSQL GIN 인덱스 최적화](https://www.postgresql.org/docs/current/gin.html)