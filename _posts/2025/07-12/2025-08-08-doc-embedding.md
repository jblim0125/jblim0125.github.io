---
layout: post
title: Vector DB를 활용한 문서 지식베이스 구축 완벽 가이드
author: jblim0125
date: 2025-08-08
category: 2025
tags: [LLM, RAG, LangGraph, Vector DB, PDF, Embedding] 
---

## Vector DB를 활용한 문서 지식베이스 구축

### 1. 개요

문서 초안 작성 시스템의 핵심은 기존 문서들로부터 관련 정보를 효과적으로 검색하고 활용하는 것입니다. 이를 위해 **Vector Database**와 **RAG(Retrieval-Augmented Generation)** 기술을 활용하여 PDF 문서들을 지식베이스로 구축하는 과정을 상세히 알아보겠습니다.

### 2. Vector Database의 작동 원리

#### 1. 임베딩(Embedding)이란?

**임베딩**은 텍스트를 숫자 벡터로 변환하는 과정입니다:

```
"문서 관리 시스템" → [0.2, -0.1, 0.8, 0.3, ..., 0.5]  # 1536차원 벡터
"파일 저장 방법" → [0.1, -0.2, 0.7, 0.4, ..., 0.6]    # 1536차원 벡터
```

- **유사한 의미**의 텍스트는 **유사한 벡터**를 가집니다
- 벡터 간 거리로 의미적 유사도를 측정할 수 있습니다

#### 2. 벡터 검색 과정

```mermaid
graph LR
    A[사용자 질문] --> B[임베딩 변환]
    B --> C[벡터 검색]
    C --> D[유사 문서 찾기]
    D --> E[관련 텍스트 반환]
```

### 3. 문서 파싱 전략: 구조 기반 vs 단순 청킹

#### 1. 문서 구조 기반 파싱의 이론적 장점

**구조 기반 파싱**은 문서의 계층 구조(목차, 섹션)를 활용하여 의미적으로 완결된 단위로 분할하는 방식입니다:

1. **의미적 완결성**: 각 청크가 하나의 완전한 주제를 다룸
2. **컨텍스트 보존**: 목차 정보를 통한 문맥 정보 유지
3. **정밀한 검색**: 특정 섹션이나 주제에 대한 정확한 검색

#### 2. 실제 테스트에서 성능 차이가 미미한 이유

하지만 실제로는 다음과 같은 이유로 성능 향상이 제한적일 수 있습니다:

```python
# 구조 기반 파싱의 한계점 분석

def analyze_document_structure_benefits():
    """구조 기반 파싱의 실제 효과 분석"""
    
    limitations = {
        "불균등한_청크_크기": {
            "문제": "목차별 내용 길이가 크게 다름",
            "영향": "너무 긴/짧은 청크로 인한 검색 성능 저하",
            "예시": "1장: 50토큰 vs 3장: 3000토큰"
        },
        
        "임베딩_모델의_한계": {
            "문제": "대부분의 임베딩 모델이 512토큰 최적화",
            "영향": "긴 섹션의 정보 손실",
            "해결": "긴 섹션은 여전히 청킹 필요"
        },
        
        "검색_패턴의_현실": {
            "문제": "사용자 질의가 항상 섹션 단위가 아님",
            "영향": "교차 섹션 정보가 필요한 경우 검색 실패",
            "예시": "여러 장에 걸친 개념 설명"
        }
    }
    
    return limitations
```

### 4. PDF 문서 처리 및 Vector DB 구축 과정

#### 1단계: PDF 파싱 및 텍스트 추출

```python
import PyPDF2
from langchain.text_splitter import RecursiveCharacterTextSplitter
import os

def extract_text_from_pdf(pdf_path):
    """PDF에서 텍스트 추출"""
    text = ""
    with open(pdf_path, 'rb') as file:
        pdf_reader = PyPDF2.PdfReader(file)
        for page in pdf_reader.pages:
            text += page.extract_text() + "\n"
    
    return text

def process_pdf_directory(pdf_directory):
    """디렉토리의 모든 PDF 처리"""
    documents = []
    
    for filename in os.listdir(pdf_directory):
        if filename.endswith('.pdf'):
            pdf_path = os.path.join(pdf_directory, filename)
            text = extract_text_from_pdf(pdf_path)
            
            # 메타데이터 추가
            document = {
                'content': text,
                'source': filename,
                'file_path': pdf_path,
                'document_type': 'pdf'
            }
            documents.append(document)
    
    return documents
```

#### 2단계: 문서 청킹(Chunking)

긴 문서를 작은 단위로 나누는 이유:
- **LLM 토큰 제한**: 대부분의 LLM은 입력 토큰 수에 제한이 있음
- **검색 정확도**: 너무 긴 텍스트는 관련 없는 정보도 포함할 수 있음
- **임베딩 품질**: 적절한 크기의 청크가 더 나은 임베딩 생성

```python
def chunk_documents(documents, chunk_size=1000, chunk_overlap=200):
    """문서를 적절한 크기로 분할"""
    text_splitter = RecursiveCharacterTextSplitter(
        chunk_size=chunk_size,
        chunk_overlap=chunk_overlap,
        length_function=len,
        separators=["\n\n", "\n", ". ", " ", ""]
    )
    
    chunked_docs = []
    for doc in documents:
        chunks = text_splitter.split_text(doc['content'])
        
        for i, chunk in enumerate(chunks):
            chunked_doc = {
                'content': chunk,
                'source': doc['source'],
                'chunk_id': f"{doc['source']}_{i}",
                'metadata': {
                    'file_path': doc['file_path'],
                    'chunk_index': i,
                    'total_chunks': len(chunks)
                }
            }
            chunked_docs.append(chunked_doc)
    
    return chunked_docs
```

#### 3단계: 임베딩 생성 및 Vector DB 저장

```python
from langchain.embeddings import OpenAIEmbeddings
from langchain.vectorstores import Chroma
import chromadb

def create_vector_database(chunked_documents, db_path="./vector_db"):
    """벡터 데이터베이스 생성"""
    
    # 임베딩 모델 초기화
    embeddings = OpenAIEmbeddings(
        model="text-embedding-ada-002"  # OpenAI의 임베딩 모델
    )
    
    # Chroma DB 클라이언트 생성
    client = chromadb.PersistentClient(path=db_path)
    
    # 컬렉션 생성 (테이블과 유사한 개념)
    collection = client.create_collection(
        name="document_knowledge_base",
        metadata={"hnsw:space": "cosine"}  # 코사인 유사도 사용
    )
    
    # 문서들을 임베딩으로 변환하여 저장
    for i, doc in enumerate(chunked_documents):
        # 텍스트를 벡터로 변환
        embedding = embeddings.embed_query(doc['content'])
        
        # Vector DB에 저장
        collection.add(
            embeddings=[embedding],
            documents=[doc['content']],
            ids=[doc['chunk_id']],
            metadatas=[doc['metadata']]
        )
        
        if i % 100 == 0:
            print(f"처리된 문서: {i}/{len(chunked_documents)}")
    
    return collection

# 실제 사용 예시
pdf_docs = process_pdf_directory("./documents/")
chunked_docs = chunk_documents(pdf_docs)
vector_db = create_vector_database(chunked_docs)
```

### 5. 검색 시스템 구현

#### 4단계: 유사도 검색 구현

```python
def search_similar_documents(query, collection, embeddings, top_k=5):
    """질의와 유사한 문서 검색"""
    
    # 질의를 벡터로 변환
    query_embedding = embeddings.embed_query(query)
    
    # 유사한 문서 검색
    results = collection.query(
        query_embeddings=[query_embedding],
        n_results=top_k,
        include=['documents', 'metadatas', 'distances']
    )
    
    # 결과 정리
    search_results = []
    for i in range(len(results['documents'][0])):
        result = {
            'content': results['documents'][0][i],
            'metadata': results['metadatas'][0][i],
            'similarity_score': 1 - results['distances'][0][i],  # 거리를 유사도로 변환
            'source': results['metadatas'][0][i]['file_path']
        }
        search_results.append(result)
    
    return search_results

# 사용 예시
query = "프로젝트 관리 방법론에 대해 알려줘"
similar_docs = search_similar_documents(query, collection, embeddings)

for doc in similar_docs:
    print(f"유사도: {doc['similarity_score']:.3f}")
    print(f"출처: {doc['source']}")
    print(f"내용: {doc['content'][:200]}...")
    print("-" * 50)
```

### 6. 고급 검색 전략

#### 1. 하이브리드 검색 (Hybrid Search)

벡터 검색과 키워드 검색을 결합:

```python
def hybrid_search(query, collection, embeddings, top_k=10):
    """벡터 검색 + 키워드 검색 결합"""
    
    # 1. 벡터 검색
    vector_results = search_similar_documents(query, collection, embeddings, top_k)
    
    # 2. 키워드 검색 (BM25 등)
    keyword_results = keyword_search(query, collection, top_k)
    
    # 3. 결과 병합 및 재순위화
    combined_results = combine_and_rerank(vector_results, keyword_results)
    
    return combined_results
```

#### 2. 메타데이터 필터링

```python
def filtered_search(query, collection, embeddings, filters=None, top_k=5):
    """메타데이터를 활용한 필터링 검색"""
    
    where_clause = {}
    if filters:
        if 'document_type' in filters:
            where_clause['document_type'] = filters['document_type']
        if 'date_range' in filters:
            where_clause['created_date'] = {"$gte": filters['date_range']['start']}
    
    query_embedding = embeddings.embed_query(query)
    
    results = collection.query(
        query_embeddings=[query_embedding],
        n_results=top_k,
        where=where_clause,
        include=['documents', 'metadatas', 'distances']
    )
    
    return results
```

### 7. 데이터 저장 구조 이해

#### Vector DB 내부 구조

```
Vector Database
├── Collection: "document_knowledge_base"
│   ├── Document_1
│   │   ├── id: "doc1_chunk_0"
│   │   ├── embedding: [0.1, 0.2, ..., 0.9]  # 1536차원 벡터
│   │   ├── content: "프로젝트 관리는..."
│   │   └── metadata: {source: "pm_guide.pdf", chunk_index: 0}
│   │
│   ├── Document_2
│   │   ├── id: "doc1_chunk_1"
│   │   ├── embedding: [0.3, 0.1, ..., 0.7]
│   │   ├── content: "애자일 방법론의 핵심은..."
│   │   └── metadata: {source: "pm_guide.pdf", chunk_index: 1}
│   │
│   └── ...
```

#### 검색 과정 상세 분석

1. **질의 입력**: "프로젝트 일정 관리 방법"
2. **임베딩 변환**: [0.2, 0.4, ..., 0.8] (1536차원)
3. **유사도 계산**: 코사인 유사도 계산
   ```
   similarity = (query_vector · doc_vector) / (||query_vector|| × ||doc_vector||)
   ```
4. **순위 매기기**: 유사도 점수로 정렬
5. **결과 반환**: 상위 K개 문서 청크 반환

### 8. 성능 최적화 전략

#### 1. 인덱싱 최적화

```python
# HNSW (Hierarchical Navigable Small World) 인덱스 설정
collection = client.create_collection(
    name="optimized_knowledge_base",
    metadata={
        "hnsw:space": "cosine",
        "hnsw:construction_ef": 200,  # 구축 시 정확도
        "hnsw:search_ef": 100,       # 검색 시 정확도
        "hnsw:M": 16                 # 연결성
    }
)
```

#### 2. 배치 처리

```python
def batch_insert_documents(collection, documents, batch_size=100):
    """배치 단위로 문서 삽입"""
    for i in range(0, len(documents), batch_size):
        batch = documents[i:i + batch_size]
        
        embeddings = [embed_text(doc['content']) for doc in batch]
        ids = [doc['chunk_id'] for doc in batch]
        contents = [doc['content'] for doc in batch]
        metadatas = [doc['metadata'] for doc in batch]
        
        collection.add(
            embeddings=embeddings,
            documents=contents,
            ids=ids,
            metadatas=metadatas
        )
```

### 9. 실제 구축 시 고려사항

#### 1. 데이터 품질 관리

```python
def preprocess_text(text):
    """텍스트 전처리"""
    # 불필요한 공백 제거
    text = re.sub(r'\s+', ' ', text)
    
    # 특수 문자 정리
    text = re.sub(r'[^\w\s가-힣]', ' ', text)
    
    # OCR 오류 수정 (필요시)
    text = correct_ocr_errors(text)
    
    return text.strip()
```

#### 2. 메타데이터 활용

```python
def extract_metadata(pdf_path, content):
    """PDF 메타데이터 추출"""
    metadata = {
        'file_name': os.path.basename(pdf_path),
        'file_size': os.path.getsize(pdf_path),
        'creation_date': datetime.now().isoformat(),
        'content_length': len(content),
        'language': detect_language(content),
        'document_category': classify_document(content)
    }
    return metadata
```

### 10. 하이브리드 파싱 전략: 실용적 접근

구조 기반과 단순 청킹을 결합한 **하이브리드 접근법**이 실용적입니다:

```python
import re
from typing import List, Dict, Tuple

def extract_document_structure(text: str) -> Dict:
    """PDF에서 목차 구조 추출"""
    
    # 목차 패턴 정의 (다양한 형태 고려)
    heading_patterns = [
        r'^(\d+\.?\s+.+)$',                    # 1. 제목
        r'^(\d+\.\d+\.?\s+.+)$',               # 1.1. 소제목
        r'^(\d+\.\d+\.\d+\.?\s+.+)$',          # 1.1.1. 세부제목
        r'^(제\s*\d+\s*장.+)$',                # 제1장 형태
        r'^([A-Z][A-Z\s]+)$',                  # 대문자 제목
        r'^(Chapter\s+\d+.+)$',                # Chapter 형태
    ]
    
    structure = {
        'headings': [],
        'sections': [],
        'metadata': {}
    }
    
    lines = text.split('\n')
    current_section = None
    section_content = []
    
    for line_num, line in enumerate(lines):
        line = line.strip()
        if not line:
            continue
            
        # 제목 패턴 매칭
        heading_level = None
        heading_text = None
        
        for level, pattern in enumerate(heading_patterns):
            if re.match(pattern, line, re.IGNORECASE):
                heading_level = level + 1
                heading_text = line
                break
        
        if heading_text:
            # 이전 섹션 저장
            if current_section and section_content:
                current_section['content'] = '\n'.join(section_content)
                structure['sections'].append(current_section)
            
            # 새 섹션 시작
            current_section = {
                'level': heading_level,
                'title': heading_text,
                'line_start': line_num,
                'content': ''
            }
            section_content = []
            structure['headings'].append({
                'level': heading_level,
                'title': heading_text,
                'line': line_num
            })
        else:
            if current_section:
                section_content.append(line)
    
    # 마지막 섹션 저장
    if current_section and section_content:
        current_section['content'] = '\n'.join(section_content)
        structure['sections'].append(current_section)
    
    return structure

def hybrid_chunking_strategy(document_structure: Dict, 
                           max_chunk_size: int = 1000,
                           min_chunk_size: int = 200) -> List[Dict]:
    """구조 기반 + 크기 기반 하이브리드 청킹"""
    
    chunks = []
    
    for section in document_structure['sections']:
        section_text = section['content']
        section_length = len(section_text)
        
        # 섹션이 적절한 크기인 경우 그대로 사용
        if min_chunk_size <= section_length <= max_chunk_size:
            chunks.append({
                'content': section_text,
                'metadata': {
                    'section_title': section['title'],
                    'section_level': section['level'],
                    'chunk_type': 'section_based',
                    'is_complete_section': True
                }
            })
        
        # 섹션이 너무 긴 경우 추가 분할
        elif section_length > max_chunk_size:
            sub_chunks = recursive_text_split(
                section_text, 
                max_chunk_size, 
                overlap=200
            )
            
            for i, sub_chunk in enumerate(sub_chunks):
                chunks.append({
                    'content': sub_chunk,
                    'metadata': {
                        'section_title': section['title'],
                        'section_level': section['level'],
                        'chunk_type': 'hybrid_split',
                        'sub_chunk_index': i,
                        'is_complete_section': False
                    }
                })
        
        # 섹션이 너무 짧은 경우 인접 섹션과 병합 고려
        elif section_length < min_chunk_size:
            chunks.append({
                'content': section_text,
                'metadata': {
                    'section_title': section['title'],
                    'section_level': section['level'],
                    'chunk_type': 'small_section',
                    'is_complete_section': True,
                    'requires_merging': True
                }
            })
    
    return merge_small_chunks(chunks, min_chunk_size)

def merge_small_chunks(chunks: List[Dict], min_size: int) -> List[Dict]:
    """작은 청크들을 병합"""
    merged_chunks = []
    pending_merge = []
    
    for chunk in chunks:
        if chunk['metadata'].get('requires_merging', False):
            pending_merge.append(chunk)
            
            # 병합된 크기가 최소 크기를 넘으면 병합 실행
            total_size = sum(len(c['content']) for c in pending_merge)
            if total_size >= min_size:
                merged_content = '\n\n'.join(c['content'] for c in pending_merge)
                merged_titles = ' + '.join(c['metadata']['section_title'] 
                                         for c in pending_merge)
                
                merged_chunks.append({
                    'content': merged_content,
                    'metadata': {
                        'section_title': merged_titles,
                        'chunk_type': 'merged_sections',
                        'merged_from': len(pending_merge),
                        'is_complete_section': False
                    }
                })
                pending_merge = []
        else:
            # 대기 중인 병합이 있으면 먼저 처리
            if pending_merge:
                merged_content = '\n\n'.join(c['content'] for c in pending_merge)
                merged_titles = ' + '.join(c['metadata']['section_title'] 
                                         for c in pending_merge)
                merged_chunks.append({
                    'content': merged_content,
                    'metadata': {
                        'section_title': merged_titles,
                        'chunk_type': 'merged_sections',
                        'merged_from': len(pending_merge)
                    }
                })
                pending_merge = []
            
            merged_chunks.append(chunk)
    
    return merged_chunks
```

### 11. 고급 메타데이터 활용 전략

구조 정보를 효과적으로 활용하기 위한 메타데이터 강화:

```python
def enhanced_metadata_extraction(document_structure: Dict, 
                               file_path: str) -> Dict:
    """향상된 메타데이터 추출"""
    
    metadata = {
        'document_info': {
            'file_path': file_path,
            'total_sections': len(document_structure['sections']),
            'heading_levels': len(set(h['level'] for h in document_structure['headings'])),
            'document_type': classify_document_type(document_structure),
            'estimated_reading_time': calculate_reading_time(document_structure)
        },
        
        'structural_features': {
            'has_toc': detect_table_of_contents(document_structure),
            'has_appendix': detect_appendix(document_structure),
            'has_bibliography': detect_bibliography(document_structure),
            'section_balance': analyze_section_balance(document_structure)
        },
        
        'content_features': {
            'primary_topics': extract_key_topics(document_structure),
            'technical_level': assess_technical_level(document_structure),
            'document_domain': classify_domain(document_structure)
        }
    }
    
    return metadata

def classify_document_type(structure: Dict) -> str:
    """문서 타입 자동 분류"""
    headings = [h['title'].lower() for h in structure['headings']]
    
    # 패턴 기반 분류
    if any('abstract' in h or '초록' in h for h in headings):
        return 'academic_paper'
    elif any('manual' in h or '매뉴얼' in h for h in headings):
        return 'manual'
    elif any('specification' in h or '명세' in h for h in headings):
        return 'specification'
    elif len([h for h in headings if 'chapter' in h or '장' in h]) > 3:
        return 'book'
    else:
        return 'report'

def create_hierarchical_embeddings(chunks: List[Dict], 
                                 embeddings_model) -> List[Dict]:
    """계층적 임베딩 생성"""
    
    for chunk in chunks:
        # 1. 기본 콘텐츠 임베딩
        content_embedding = embeddings_model.embed_query(chunk['content'])
        
        # 2. 제목 임베딩 (더 높은 가중치)
        title_embedding = embeddings_model.embed_query(
            chunk['metadata']['section_title']
        )
        
        # 3. 계층적 컨텍스트 임베딩
        hierarchical_context = build_hierarchical_context(chunk)
        context_embedding = embeddings_model.embed_query(hierarchical_context)
        
        # 4. 가중 평균으로 최종 임베딩 생성
        chunk['embedding'] = combine_embeddings([
            (content_embedding, 0.6),    # 내용에 높은 가중치
            (title_embedding, 0.3),      # 제목에 중간 가중치  
            (context_embedding, 0.1)     # 컨텍스트에 낮은 가중치
        ])
        
        # 5. 검색을 위한 다중 임베딩 저장
        chunk['multi_embeddings'] = {
            'content': content_embedding,
            'title': title_embedding,
            'context': context_embedding,
            'combined': chunk['embedding']
        }
    
    return chunks

def build_hierarchical_context(chunk: Dict) -> str:
    """청크의 계층적 컨텍스트 구축"""
    context_parts = []
    
    # 상위 제목 정보
    if 'parent_sections' in chunk['metadata']:
        context_parts.extend(chunk['metadata']['parent_sections'])
    
    # 현재 제목
    context_parts.append(chunk['metadata']['section_title'])
    
    # 형제 섹션 정보 (선택적)
    if 'sibling_sections' in chunk['metadata']:
        context_parts.append("Related sections: " + 
                           ", ".join(chunk['metadata']['sibling_sections'][:3]))
    
    return " -> ".join(context_parts)
```

### 12. 검색 성능 최적화: 다중 인덱스 전략

```python
def create_multi_index_vector_db(chunks: List[Dict], db_path: str):
    """다중 인덱스 벡터 DB 생성"""
    
    client = chromadb.PersistentClient(path=db_path)
    
    # 1. 메인 콘텐츠 인덱스
    main_collection = client.create_collection(
        name="main_content",
        metadata={"hnsw:space": "cosine"}
    )
    
    # 2. 제목 전용 인덱스
    title_collection = client.create_collection(
        name="section_titles", 
        metadata={"hnsw:space": "cosine"}
    )
    
    # 3. 구조 정보 인덱스
    structure_collection = client.create_collection(
        name="document_structure",
        metadata={"hnsw:space": "cosine"}
    )
    
    for chunk in chunks:
        chunk_id = chunk['metadata']['chunk_id']
        
        # 메인 콘텐츠 저장
        main_collection.add(
            embeddings=[chunk['multi_embeddings']['content']],
            documents=[chunk['content']],
            ids=[f"content_{chunk_id}"],
            metadatas=[chunk['metadata']]
        )
        
        # 제목 정보 저장
        title_collection.add(
            embeddings=[chunk['multi_embeddings']['title']],
            documents=[chunk['metadata']['section_title']],
            ids=[f"title_{chunk_id}"],
            metadatas=[chunk['metadata']]
        )
        
        # 구조 정보 저장
        hierarchical_context = build_hierarchical_context(chunk)
        structure_collection.add(
            embeddings=[chunk['multi_embeddings']['context']],
            documents=[hierarchical_context],
            ids=[f"structure_{chunk_id}"],
            metadatas=[chunk['metadata']]
        )
    
    return {
        'main': main_collection,
        'titles': title_collection, 
        'structure': structure_collection
    }

def multi_index_search(query: str, collections: Dict, 
                      embeddings_model, top_k: int = 5) -> List[Dict]:
    """다중 인덱스를 활용한 검색"""
    
    query_embedding = embeddings_model.embed_query(query)
    
    # 1. 각 인덱스에서 검색
    content_results = collections['main'].query(
        query_embeddings=[query_embedding],
        n_results=top_k * 2,
        include=['documents', 'metadatas', 'distances']
    )
    
    title_results = collections['titles'].query(
        query_embeddings=[query_embedding], 
        n_results=top_k,
        include=['documents', 'metadatas', 'distances']
    )
    
    structure_results = collections['structure'].query(
        query_embeddings=[query_embedding],
        n_results=top_k,
        include=['documents', 'metadatas', 'distances']
    )
    
    # 2. 결과 병합 및 재순위화
    combined_results = merge_search_results([
        (content_results, 0.6),      # 내용 검색에 높은 가중치
        (title_results, 0.3),        # 제목 검색에 중간 가중치
        (structure_results, 0.1)     # 구조 검색에 낮은 가중치
    ])
    
    return combined_results[:top_k]
```

### 13. 실제 성능 비교 및 평가

```python
def evaluate_chunking_strategies(test_queries: List[str], 
                               ground_truth: List[str]) -> Dict:
    """청킹 전략별 성능 평가"""
    
    strategies = {
        'simple_chunking': simple_chunk_strategy,
        'structure_based': structure_based_strategy, 
        'hybrid_approach': hybrid_chunking_strategy
    }
    
    results = {}
    
    for strategy_name, strategy_func in strategies.items():
        # 각 전략으로 청킹
        chunks = strategy_func(documents)
        
        # Vector DB 구축
        vector_db = create_vector_database(chunks)
        
        # 검색 성능 측정
        metrics = {
            'precision': [],
            'recall': [],
            'response_time': [],
            'chunk_size_distribution': analyze_chunk_sizes(chunks)
        }
        
        for query, expected in zip(test_queries, ground_truth):
            start_time = time.time()
            search_results = search_similar_documents(query, vector_db)
            response_time = time.time() - start_time
            
            precision, recall = calculate_precision_recall(
                search_results, expected
            )
            
            metrics['precision'].append(precision)
            metrics['recall'].append(recall)
            metrics['response_time'].append(response_time)
        
        results[strategy_name] = {
            'avg_precision': np.mean(metrics['precision']),
            'avg_recall': np.mean(metrics['recall']),
            'avg_response_time': np.mean(metrics['response_time']),
            'chunk_stats': metrics['chunk_size_distribution']
        }
    
    return results
```

### 결론: 언제 구조 기반 파싱이 유효한가?

구조 기반 파싱이 효과적인 경우:

1. **명확한 계층 구조**를 가진 기술 문서나 매뉴얼
2. **섹션별로 독립적인 주제**를 다루는 학술 논문
3. **목차 기반 검색**이 주된 사용 패턴인 경우
4. **문서 네비게이션**이 중요한 애플리케이션

단순 청킹이 더 나은 경우:

1. **자유로운 형식**의 에세이나 소설
2. **주제가 섹션 간 연결**되어 있는 문서
3. **다양한 검색 패턴**을 지원해야 하는 경우
4. **처리 속도**가 중요한 실시간 시스템

**최종 권장사항**: 대부분의 실무 환경에서는 **하이브리드 접근법**이 가장 실용적이며,
문서 타입과 사용 패턴에 따라 전략을 조정하는 것이 효과적입니다.

