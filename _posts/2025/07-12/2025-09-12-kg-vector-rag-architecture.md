---
layout: post
title: 지식그래프 + 벡터DB 하이브리드 RAG 설계와 동작 원리
author: jblim0125
date: 2025-09-12
category: 2025
tags: [RAG, KnowledgeGraph, VectorDB, HybridRetrieval, GraphRAG]
---

## 목표

지식그래프(Knowledge Graph, KG)와 벡터 데이터베이스(Vector DB)를 함께 사용할 때, RAG(Retrieval-Augmented Generation)가 질의→검색→문맥조립→생성 단계에서 어떻게 동작하는지 아키텍처와 구현 패턴을 상세히 정리합니다.

## 전체 아키텍처 개요

```
[사용자 질의]
   ↓
Query Understanding (의도 파악, NER, 엔티티 링크)
   ↓                         ↓
KG Retrieval (제약·확장)    Vector Retrieval (유사도)
   ↓                         ↓
     Hybrid Fusion (병렬/순차, 필터·재랭킹·결합)
                        ↓
           Context Assembly (중복 제거, 다양성, 예산)
                        ↓
             Generator (LLM, 출처 인용, 포맷)
```

핵심은 “검색 자체를 이원화”하고, KG를 통해 “검색 공간을 제약/확장/검증”하는 것입니다. 벡터는 표현 기반 유사도로 빠르게 후보를 만들고, KG는 정확한 스코프·제약·관계적 근거를 제공합니다.

## 데이터 모델 설계

- 문서 청크(Chunk): 원문을 문단/문장 단위로 분할, `chunk_id`를 부여
- 벡터 인덱스(Vector DB): `chunk_id`, `embedding`, `metadata`(엔티티ID들, 타입, 소스, 버전, 테넌트 등)
- 지식그래프(KG): 엔티티 노드와 관계 엣지, 문서/섹션/청크 노드까지 포함 가능
- 브릿지 매핑: `(:Entity)-[:MENTIONS {weight}]->(:Chunk)` 또는 조인 테이블 `chunk_entity(chunk_id, entity_id, weight)`

예시 스키마(Neo4j 스타일):

```
(:Document {id})-[:HAS_SECTION]->(:Section {id})-[:HAS_CHUNK]->(:Chunk {id, source, version, tenant})
(:Entity {id, type, name, aliases})
(:Entity)-[:REL {type, score}]->(:Entity)
(:Entity)-[:MENTIONS {weight}]->(:Chunk)
```

메타데이터 설계 팁
- 최소: `chunk_id`, `source`, `version`, `tenant`, `entity_ids[]`, `entity_types[]`
- 선택: `doc_id`, `section_id`, `timestamp`, `access_level`, `language`, `hash`

## 수집/전처리 파이프라인

1) 문서 → 청킹 → 정규화
- 문서 파서(HTML/PDF/Office) → 구조화(제목/목차/섹션) → 청킹(토큰 길이 기반)

2) 임베딩 → Vector DB 적재
- 임베딩 모델 선택(도메인 특화 권장) → `upsert(chunks)` with metadata

3) 정보추출(IE) → KG 업데이트
- NER/RE(엔티티/관계 추출) → 동형/동의어 정규화 → 엔티티/관계 upsert

4) 브릿지 생성
- 청크가 언급하는 엔티티 연결 `(:Entity)-[:MENTIONS]->(:Chunk)` 또는 매핑 테이블 적재

5) 버전/일관성
- `version` 고정 단위로 인덱싱 → 교체 시 롤백 용이
- VDB/KG 동시 커밋이 어려우면 이벤트 기반 비동기 동기화 + 유효성 검증 배치

## 질의 파이프라인 상세

### 1) Query Understanding
- 의도 분류: 질의 유형(정의, 절차, 비교, 요약, 근거 요청)
- NER/키워드 추출: 주요 엔티티 후보, 시간/수량 제약
- 엔티티 링크: KG의 canonical 엔티티에 매핑(동음이의, 별칭 해결)

출력 예시
```
intent=PROCEDURE
entities=[{"id":"E:Oracle-19c", "name":"Oracle 19c", "type":"Product"}]
constraints={"version": ">=19.12", "tenant":"acme"}
```

### 2) Retrieval 전략

전략 A: Vector-first + KG Filter(기본값, 빠르고 범용)
1. VDB에서 상위 k1 청크 검색(쿼리 임베딩)
2. KG 기반 필터 적용: `tenant/access/version/type/entity` 등 메타데이터로 후보 축소
3. KG 점수로 보정: 후보 청크에 연결된 엔티티의 “질의 엔티티와의 그래프 거리/유형 호환성/관계 신뢰도”로 가중치 부여

전략 B: KG-first + Vector Re-rank(도메인 강한 제약 필요)
1. KG에서 질의 엔티티 주변 r-hop 서브그래프 추출(관련 엔티티/문서 경로)
2. 해당 서브그래프가 참조하는 청크 집합만 대상으로 VDB 재랭킹

전략 C: 병렬 Hybrid + Late Fusion(Reciprocal Rank Fusion 권장)
1. Vector 후보 k1, KG 후보 k2를 병렬 수집
2. RRF 등 간단하고 강건한 결합으로 최종 순위 생성

KG 활용 패턴
- 제약: 테넌트/버전/권한/타입/시간 윈도우로 검색 공간 축소
- 확장: 동의어/별칭/상위-하위 개념/연관 엔티티로 질의 확장
- 근거: 후보 청크가 어떤 엔티티/관계로 정당화되는지 경로 제공(출처 설명 강화)

### 3) Re-ranking
- Cross-Encoder 재랭킹 또는 LLM-as-a-reranker로 상위 n 재평가
- 특징량: 텍스트 유사도 + KG 근거 점수(경로 길이, 타입 일치, 관계 신뢰도)

### 4) Context Assembly(문맥 조립)
- 중복 제거: 동일 문서 인접 청크는 합치되 중복 내용 제거
- 다양성 확보: 서로 다른 출처/관점 균형 배치
- 예산 관리: 토큰 한도 내 우선순위 조합(답변에 필요한 최소 근거 우선)
- 그래프-근거 직렬화: 핵심 서브그래프를 표/트리플/간단 JSON으로 요약해 컨텍스트에 포함

### 5) 생성(Generation)
- 시스템 프롬프트에 요구 포맷/인용 규칙/금지사항 명시
- 청크와 서브그래프 요약을 함께 투입 → 근거 기반 답변
- 각 문장 끝에 출처(문서/섹션/chunk_id) 부여

## 예시 쿼리/코드 스니펫

KG에서 질의 엔티티 주변 청크 후보 가져오기(Neo4j Cypher)

```cypher
// 1-hop 이내에서 언급된 청크 후보 상위 N
MATCH (qe:Entity {id: $query_entity_id})-[:REL*0..1]-(e:Entity)-[m:MENTIONS]->(c:Chunk)
WHERE c.tenant = $tenant AND c.version >= $minVersion
RETURN c.id AS chunk_id, sum(coalesce(m.weight,1)) AS kg_score
ORDER BY kg_score DESC
LIMIT $k2
```

Vector-first 검색 + KG 필터(Python 유사 코드)

```python
def retrieve(query, k1=50, k2=50, tenant="acme"):
    q_emb = embed(query)
    # 1) VDB 후보
    vdb_hits = vdb.search(q_emb, top_k=k1, filter={"tenant": tenant})
    # 2) KG 후보
    kg_hits = neo4j.run(CYPHER_KG, params).records()
    kg_map = {r["chunk_id"]: r["kg_score"] for r in kg_hits}
    # 3) 통합 스코어링
    results = []
    for h in vdb_hits:
        score = alpha * h.sim + beta * kg_map.get(h.chunk_id, 0)
        results.append((h.chunk_id, score))
    # 4) KG-only 보완(벡터 미포함 KG 후보 상위 일부 추가)
    for cid, kg_score in kg_map.items():
        if cid not in {x[0] for x in results}:
            results.append((cid, beta * kg_score))
    # 5) 상위 N 추출 후 재랭킹(Cross-Encoder)
    top = sorted(results, key=lambda x: x[1], reverse=True)[:k2]
    reranked = cross_encoder_rerank(query, [cid for cid, _ in top])
    return assemble_context(reranked)
```

Reciprocal Rank Fusion(RRF)

```python
def rrf_fusion(v_list, g_list, k=60):
    # v_list/g_list: [(id, rank1_based), ...]
    from collections import defaultdict
    s = defaultdict(float)
    for i, (cid, r) in enumerate(v_list):
        s[cid] += 1.0 / (k + r)
    for i, (cid, r) in enumerate(g_list):
        s[cid] += 1.0 / (k + r)
    return sorted(s.items(), key=lambda x: x[1], reverse=True)
```

서브그래프를 컨텍스트에 싣기 위한 단순 직렬화 예

```cypher
// 질의 엔티티 중심 2-hop 서브그래프
MATCH path = (qe:Entity {id:$qe})-[:REL*0..2]-(e:Entity)
WITH qe, collect(distinct e) AS nodes, collect(distinct relationships(path)) AS rels
RETURN qe, nodes, rels
```

```json
{
  "qe": "Oracle 19c",
  "facts": [
    {"head":"Oracle 19c","rel":"SUPPORTS","tail":"Data Pump","conf":0.92},
    {"head":"Oracle 19c","rel":"MIN_PATCH","tail":"19.12","conf":0.88}
  ]
}
```

## 운영 및 모니터링

- 품질 지표: Recall@k, nDCG/MRR, 정답률(Human eval), 근거 인용 정확도
- 성능 지표: p50/p95 지연, 실패율, 재시도율, 캐시 적중률
- 전략 선택: 쿼리 유형/길이/도메인에 따라 A/B 또는 정책 라우팅
- 캐시: 인기 쿼리, 엔티티 중심 서브그래프, 재랭킹 결과 TTL 캐시
- 접근제어: `tenant/access_level` 메타데이터로 필터 일관성 유지(생성 단계에서도 헤더/클레임 반영)

## 한계와 주의사항

- KG 구축/유지 비용: 스키마 설계와 정규화, 지속적 동기화 비용이 큼
- 동음이의/별칭: 엔티티 링크 실패 시 품질 급락 → 사전/룰/피드백 루프 필요
- 포괄성 vs 정확성: KG 제약을 과하게 걸면 recall 저하, 완화하면 노이즈 증가 → 하이브리드 튜닝 필수
- 일관성: VDB/KG 버전 동기화와 롤백 시나리오 준비

## 체크리스트(실전)

- [ ] 청크 메타데이터에 `entity_ids[]`, `tenant`, `version`이 들어가는가?
- [ ] KG에 `(:Entity)-[:MENTIONS]->(:Chunk)` 또는 동등 매핑이 존재하는가?
- [ ] Vector-first/KG-first/병렬 전략을 상황별로 스위칭할 수 있는가?
- [ ] 재랭커 도입 전/후 품질지표가 개선되는가?
- [ ] 생성 응답에 출처/근거 경로를 일관되게 표기하는가?

## 결론

하이브리드 RAG의 핵심은 “표현 유사도(벡터)”와 “관계적 근거(KG)”의 상호 보완입니다. Vector-first로 속도를 확보하고, KG로 제약/확장/검증을 더해 품질을 끌어올리되, 재랭킹과 컨텍스트 예산 관리로 최종 답변의 안정성을 확보하세요. 데이터 수집부터 버전·보안·모니터링까지 파이프라인을 일관되게 설계하면, 도메인 지식이 중요한 업무에서도 신뢰도 높은 RAG를 운영할 수 있습니다.

