---
layout: post
title: "하이브리드 온톨로지: 관계형 DB와 벡터 DB를 활용한 지식 그래프 구축"
author: jblim0125
date: 2025-07-12
category: 2025
tags: [OpenAI, RAG, AI, 임베딩, 벡터검색, LLM, 온톨로지, 그래프데이터베이스, PostgreSQL, ChromaDB]
---

- [개요](#개요)
- [하이브리드 온톨로지의 필요성](#하이브리드-온톨로지의-필요성)
  - [기존 그래프 데이터베이스의 한계](#기존-그래프-데이터베이스의-한계)
  - [하이브리드 접근법의 장점](#하이브리드-접근법의-장점)
- [시스템 아키텍처](#시스템-아키텍처)
- [데이터 모델 설계](#데이터-모델-설계)
  - [1. PostgreSQL 스키마 (구조화된 데이터)](#1-postgresql-스키마-구조화된-데이터)
  - [2. ChromaDB 컬렉션 (비정형 데이터)](#2-chromadb-컬렉션-비정형-데이터)
- [데이터 저장 및 임베딩 생성](#데이터-저장-및-임베딩-생성)
  - [1. 구조화된 데이터 저장](#1-구조화된-데이터-저장)
  - [2. 비정형 데이터 임베딩 및 저장](#2-비정형-데이터-임베딩-및-저장)
- [RAG 기반 질의 처리 시스템](#rag-기반-질의-처리-시스템)
  - [1. 하이브리드 검색 엔진](#1-하이브리드-검색-엔진)
  - [2. LLM 기반 답변 생성](#2-llm-기반-답변-생성)
- [실제 활용 예시](#실제-활용-예시)
  - [시나리오: "AI팀에서 수행하기에 알맞은 연구과제 찾기"](#시나리오-ai팀에서-수행하기에-알맞은-연구과제-찾기)
  - [예상 답변](#예상-답변)
- [시스템 구축 시 고려사항](#시스템-구축-시-고려사항)
  - [1. 데이터 동기화](#1-데이터-동기화)
  - [2. 성능 최적화](#2-성능-최적화)
  - [3. 확장성](#3-확장성)
- [결론](#결론)


## 개요

전통적인 온톨로지 구축은 그래프 데이터베이스를 사용하는 것이 일반적이지만, 실제 비즈니스 환경에서는 다양한
형태의 데이터를 효율적으로 관리해야 하는 경우가 많습니다. 이번 글에서는 **관계형 데이터베이스(PostgreSQL)**와
**벡터 데이터베이스(ChromaDB)**를 조합한 하이브리드 온톨로지 구축 방법을 소개하고, 실제 회사 내 지식 관리 시스템
구축 사례를 통해 그 활용 방법을 살펴보겠습니다.

## 하이브리드 온톨로지의 필요성

### 기존 그래프 데이터베이스의 한계

- **구조화된 데이터 처리의 비효율성**: 복잡한 관계를 표현하기 어려움
- **대용량 비정형 데이터 처리의 한계**: 텍스트, 문서 등의 의미적 검색이 어려움
- **확장성 문제**: 대용량 데이터 처리 시 성능 저하

### 하이브리드 접근법의 장점

- **구조화된 데이터**: 관계형 DB로 효율적 관리
- **비정형 데이터**: 벡터 DB로 의미적 검색 가능
- **유연한 확장**: 각 데이터 특성에 맞는 최적화된 저장소 활용

## 시스템 아키텍처

```plantuml
@startuml
!include <archimate/Archimate>

title Arch

Application_DataObject(postgresql, "PostgreSQL\n정형 데이터")
Application_DataObject(chromadb, "ChromaDB\n비정형 데이터")
Application_DataObject(llm, "LLM\n질의 처리")

Technology_Service(rag, "RAG Pipeline")

Rel_Serving_Up(rag, llm, "")
Rel_Serving_Up(rag, chromadb, "")
Rel_Serving_Up(rag, postgresql, "")

' ┌──────────────────┐    ┌──────────────────┐    ┌─────────────────┐
' │   PostgreSQL     │    │    ChromaDB      │    │      LLM        │
' │  (구조화 데이터) │    │  (비정형 데이터) │    │   (질의 처리)   │
' └──────────────────┘    └──────────────────┘    └─────────────────┘
'          │                       │                       │
'          └───────────────────────┼───────────────────────┘
'                                  │
'                     ┌─────────────────┐
'                     │  RAG Pipeline   │
'                     └─────────────────┘
@enduml
```

## 데이터 모델 설계

### 1. PostgreSQL 스키마 (구조화된 데이터)

```sql
-- 부서 정보
CREATE TABLE departments (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    parent_id INTEGER REFERENCES departments(id)
);

-- 프로젝트 정보
CREATE TABLE projects (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    department_id INTEGER REFERENCES departments(id),
    status VARCHAR(50),
    start_date DATE,
    end_date DATE,
    technologies TEXT[]
);

-- 연구과제 정보
CREATE TABLE research_projects (
    id SERIAL PRIMARY KEY,
    title VARCHAR(300) NOT NULL,
    requirements TEXT,
    functional_requirements TEXT,
    performance_requirements TEXT,
    budget DECIMAL(15,2),
    duration_months INTEGER
);

-- 부서-연구과제 매핑
CREATE TABLE department_research_mapping (
    department_id INTEGER REFERENCES departments(id),
    research_project_id INTEGER REFERENCES research_projects(id),
    PRIMARY KEY (department_id, research_project_id)
);
```

### 2. ChromaDB 컬렉션 (비정형 데이터)

```python
import chromadb
from chromadb.config import Settings

# ChromaDB 클라이언트 설정
client = chromadb.Client(Settings(
    chroma_db_impl="duckdb+parquet",
    persist_directory="./chroma_db"
))

# 문서 컬렉션 생성
documents_collection = client.create_collection(
    name="project_documents",
    metadata={"hnsw:space": "cosine"}
)

# 연구과제 문서 컬렉션 생성
research_collection = client.create_collection(
    name="research_documents",
    metadata={"hnsw:space": "cosine"}
)
```

## 데이터 저장 및 임베딩 생성

### 1. 구조화된 데이터 저장

```python
import psycopg2
from psycopg2.extras import RealDictCursor

def save_department_data():
    conn = psycopg2.connect("postgresql://user:password@localhost/ontology_db")
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    # 부서 정보 저장
    departments = [
        ("개발팀", "소프트웨어 개발 및 유지보수", None),
        ("AI팀", "인공지능 및 머신러닝 연구", None),
        ("데이터팀", "데이터 분석 및 엔지니어링", None)
    ]
    
    for dept in departments:
        cur.execute("""
            INSERT INTO departments (name, description, parent_id)
            VALUES (%s, %s, %s)
        """, dept)
    
    conn.commit()
    cur.close()
    conn.close()
```

### 2. 비정형 데이터 임베딩 및 저장

```python
from sentence_transformers import SentenceTransformer
import chromadb

def embed_and_store_documents():
    # 임베딩 모델 로드
    model = SentenceTransformer('sentence-transformers/all-MiniLM-L6-v2')
    
    # 프로젝트 문서 임베딩
    project_docs = [
        "AI 기반 음성 피싱 탐지 시스템 개발 - Python, TensorFlow, FastAPI 사용",
        "대용량 데이터 처리 파이프라인 구축 - Apache Spark, Kafka, Elasticsearch 활용",
        "클라우드 네이티브 마이크로서비스 아키텍처 구현 - Docker, Kubernetes, Spring Boot"
    ]
    
    embeddings = model.encode(project_docs)
    
    # ChromaDB에 저장
    documents_collection.add(
        embeddings=embeddings.tolist(),
        documents=project_docs,
        ids=[f"project_{i}" for i in range(len(project_docs))]
    )
```

## RAG 기반 질의 처리 시스템

### 1. 하이브리드 검색 엔진

```python
class HybridSearchEngine:
    def __init__(self, pg_conn, chroma_client):
        self.pg_conn = pg_conn
        self.chroma_client = chroma_client
        self.model = SentenceTransformer('sentence-transformers/all-MiniLM-L6-v2')
    
    def search_departments_for_research(self, research_query):
        # 1. 벡터 검색으로 관련 문서 찾기
        query_embedding = self.model.encode([research_query])
        
        results = self.chroma_client.get_collection("research_documents").query(
            query_embeddings=query_embedding.tolist(),
            n_results=5
        )
        
        # 2. 관계형 DB에서 부서 정보 조회
        cur = self.pg_conn.cursor(cursor_factory=RealDictCursor)
        
        # 부서별 프로젝트 히스토리 조회
        cur.execute("""
            SELECT 
                d.name as department_name,
                d.description as department_desc,
                p.name as project_name,
                p.technologies,
                p.status
            FROM departments d
            LEFT JOIN projects p ON d.id = p.department_id
            ORDER BY d.name, p.start_date DESC
        """)
        
        department_data = cur.fetchall()
        cur.close()
        
        return {
            'vector_results': results,
            'department_data': department_data
        }
```

### 2. LLM 기반 답변 생성

```python
from openai import OpenAI
import json

class OntologyLLM:
    def __init__(self, openai_api_key):
        self.client = OpenAI(api_key=openai_api_key)
    
    def generate_response(self, query, search_results):
        # 컨텍스트 구성
        context = self._build_context(search_results)
        
        # 프롬프트 구성
        prompt = f"""
다음은 회사 내 부서 정보와 연구과제 정보입니다:

{context}

질문: {query}

위 정보를 바탕으로 적절한 부서를 추천하고 그 이유를 설명해주세요.
답변은 한국어로 작성하고, 구체적인 근거를 제시해주세요.
"""
        
        response = self.client.chat.completions.create(
            model="gpt-4",
            messages=[
                {"role": "system", "content": "당신은 회사 내 부서와 프로젝트 매칭 전문가입니다."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.7
        )
        
        return response.choices[0].message.content
    
    def _build_context(self, search_results):
        context = "=== 부서별 프로젝트 히스토리 ===\n"
        
        for dept in search_results['department_data']:
            context += f"부서: {dept['department_name']}\n"
            context += f"설명: {dept['department_desc']}\n"
            if dept['project_name']:
                context += f"프로젝트: {dept['project_name']} (기술: {dept['technologies']})\n"
            context += "\n"
        
        context += "=== 관련 연구과제 정보 ===\n"
        for doc in search_results['vector_results']['documents'][0]:
            context += f"- {doc}\n"
        
        return context
```

## 실제 활용 예시

### 시나리오: "AI팀에서 수행하기에 알맞은 연구과제 찾기"

```python
# 시스템 초기화
search_engine = HybridSearchEngine(pg_conn, chroma_client)
llm = OntologyLLM(openai_api_key)

# 질의 처리
query = "AI팀에서 수행하기에 알맞은 연구과제들을 찾아줘"
search_results = search_engine.search_departments_for_research(query)

# LLM 답변 생성
response = llm.generate_response(query, search_results)
print(response)
```

### 예상 답변

```text
AI팀에 적합한 연구과제 분석 결과:

1. **AI 기반 음성 피싱 탐지 시스템 개발**
   - 적합도: 매우 높음
   - 근거: AI팀의 기존 머신러닝 프로젝트 경험과 음성 처리 기술 활용 가능
   - 기술 스택: Python, TensorFlow (AI팀 보유 기술과 일치)

2. **대용량 데이터 처리 파이프라인 구축**
   - 적합도: 높음
   - 근거: AI 모델 학습을 위한 대용량 데이터 처리 경험 필요
   - 기술 스택: Apache Spark, Kafka (AI팀 확장 가능한 기술)

3. **클라우드 네이티브 마이크로서비스 아키텍처**
   - 적합도: 보통
   - 근거: AI 서비스 배포를 위한 인프라 구축 필요
   - 기술 스택: Docker, Kubernetes (AI팀 학습 가능한 기술)

추천 우선순위: 1 > 2 > 3
```

## 시스템 구축 시 고려사항

### 1. 데이터 동기화

- 관계형 DB와 벡터 DB 간의 데이터 일관성 유지
- 실시간 업데이트를 위한 이벤트 기반 아키텍처 고려

### 2. 성능 최적화

- 벡터 검색 결과 캐싱
- 관계형 DB 인덱싱 전략
- 임베딩 모델 선택 및 최적화

### 3. 확장성

- 수평적 확장을 위한 샤딩 전략
- 마이크로서비스 아키텍처 적용

## 결론

하이브리드 온톨로지 접근법은 구조화된 데이터와 비정형 데이터를 각각의 특성에 맞는
최적의 저장소에 저장하여 효율적인 지식 관리와 검색을 가능하게 합니다.
특히 RAG(Retrieval-Augmented Generation) 기법과 결합하여 LLM의 정확하고 맥락에 맞는 답변을 생성할 수 있습니다.

이러한 시스템은 단순한 키워드 검색을 넘어서 의미적 이해를 바탕으로 한 지능적인 질의응답이
가능하며, 조직의 지식 자산을 효과적으로 활용할 수 있게 해줍니다.
