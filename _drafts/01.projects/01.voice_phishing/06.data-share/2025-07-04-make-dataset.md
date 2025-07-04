# Voice Phishing 데이터셋 생성 시퀀스 및 UI 설계

작성일: 2025년 7월 4일  
작성자: JB  

## 개요

Voice Phishing 데이터 공유 플랫폼에서 데이터셋을 생성하고 공유하는 과정의 시퀀스 다이어그램과 사용자 인터페이스 설계를 정의합니다.

## 1. 데이터셋 생성 시퀀스 다이어그램

### 1.1 전체 데이터셋 생성 프로세스

```plantuml
@startuml Dataset Creation Process
title Voice Phishing 데이터셋 생성 프로세스

actor User as "사용자"
participant UI as "웹 인터페이스"
participant API as "Dataset API"
participant Search as "검색 엔진"
participant Access as "접근 제어"
participant DB as "데이터베이스"
participant Storage as "파일 저장소"

== 데이터 검색 및 필터링 ==
User -> UI: 데이터 검색 조건 입력
UI -> API: POST /data/search
API -> Access: 사용자 권한 확인
Access -> API: 권한 승인
API -> Search: 검색 조건으로 데이터 조회
Search -> DB: 데이터 필터링 실행
DB -> Search: 검색 결과 반환
Search -> API: 미리보기 데이터 생성
API -> UI: 검색 결과 미리보기
UI -> User: 데이터 미리보기 표시

== 데이터셋 생성 ==
User -> UI: 데이터셋 이름/설명 입력
User -> UI: 접근 제어 설정
UI -> API: POST /datasets
API -> Access: 접근 제어 규칙 검증
Access -> API: 규칙 검증 완료
API -> DB: 데이터셋 메타데이터 생성
DB -> API: 데이터셋 ID 반환
API -> Search: 실제 데이터셋 생성 작업 시작
Search -> Storage: 데이터 파일 복사/링크 생성
Storage -> Search: 작업 완료
Search -> DB: 데이터셋 상태 업데이트 (READY)
API -> UI: 데이터셋 생성 완료
UI -> User: 생성 완료 알림

== 공유 링크 생성 ==
User -> UI: 공유 설정 요청
UI -> API: POST /datasets/{id}/share
API -> Access: 공유 권한 확인
Access -> API: 권한 승인
API -> DB: 공유 토큰 생성
DB -> API: 공유 정보 반환
API -> UI: 공유 링크 제공
UI -> User: 공유 링크 표시

@enduml
```

### 1.2 접근 제어 통합 시퀀스

```plantuml
@startuml Access Control Integration
title 접근 제어가 통합된 데이터셋 생성

actor User as "사용자"
participant UI as "웹 UI"
participant DatasetAPI as "Dataset API"
participant AccessAPI as "Access Control API"
participant UserMgmt as "User Management"
participant DB as "데이터베이스"

== 사용자 검색 및 권한 설정 ==
User -> UI: 접근 권한 설정 요청
UI -> AccessAPI: GET /search/users?query=검색어
AccessAPI -> UserMgmt: 사용자 검색
UserMgmt -> AccessAPI: 검색 결과
AccessAPI -> UI: 사용자 목록
UI -> User: 사용자 선택 UI 표시

User -> UI: 그룹 검색 요청
UI -> AccessAPI: GET /search/groups?query=검색어
AccessAPI -> UserMgmt: 그룹 검색
UserMgmt -> AccessAPI: 그룹 목록
AccessAPI -> UI: 그룹 목록
UI -> User: 그룹 선택 UI 표시

User -> UI: 역할 및 속성 설정
UI -> AccessAPI: GET /search/roles
UI -> AccessAPI: GET /search/attributes
AccessAPI -> UI: 역할/속성 목록
UI -> User: 선택 옵션 제공

== 데이터셋 생성 및 접근 제어 적용 ==
User -> UI: 데이터셋 생성 확정
UI -> DatasetAPI: POST /datasets (with access settings)
DatasetAPI -> AccessAPI: 접근 규칙 생성 요청
AccessAPI -> DB: 접근 규칙 저장
DB -> AccessAPI: 규칙 ID 반환
AccessAPI -> DatasetAPI: 규칙 적용 완료
DatasetAPI -> DB: 데이터셋 생성
DB -> DatasetAPI: 데이터셋 ID
DatasetAPI -> UI: 생성 완료
UI -> User: 성공 메시지

@enduml
```

## 2. 사용자 인터페이스 설계

### 2.1 사용자 인터페이스 플로우

```mermaid
flowchart TD
    A[메인 대시보드] --> B[데이터 검색]
    A --> C[내 데이터셋 관리]
    A --> D[공유받은 데이터셋]
    
    B --> E[검색 조건 입력]
    E --> F[검색 결과 미리보기]
    F --> G{결과 만족?}
    G -->|No| E
    G -->|Yes| H[데이터셋 설정]
    
    H --> I[기본 정보 입력]
    I --> J[접근 제어 설정]
    J --> K[사용자/그룹 선택]
    J --> L[역할/속성 설정]
    J --> M[제한 사항 설정]
    
    K --> N[데이터셋 생성]
    L --> N
    M --> N
    
    N --> O[생성 완료]
    O --> P[공유 링크 생성]
    O --> Q[데이터셋 관리]
    
    C --> R[데이터셋 목록]
    R --> S[데이터셋 상세]
    S --> T[데이터 조회/다운로드]
    S --> U[공유 관리]
    S --> V[접근 제어 수정]
    
    D --> W[공유 데이터셋 목록]
    W --> X[공유 데이터셋 접근]
```

### 2.2 컴포넌트 다이어그램

```plantuml
@startuml UI Components
title 데이터셋 생성 UI 컴포넌트 구조

package "데이터셋 생성 UI" {
    [검색 필터 컴포넌트] as SearchFilter
    [결과 미리보기] as Preview
    [데이터셋 설정] as DatasetConfig
    [접근 제어 패널] as AccessControl
    [공유 설정] as ShareConfig
}

package "공통 컴포넌트" {
    [사용자 검색] as UserSearch
    [그룹 검색] as GroupSearch
    [역할 선택기] as RoleSelector
    [속성 편집기] as AttributeEditor
    [날짜 선택기] as DatePicker
    [파일 타입 선택] as FileTypeSelector
}

package "데이터 표시 컴포넌트" {
    [데이터 테이블] as DataTable
    [통계 차트] as StatsChart
    [분포 그래프] as DistributionChart
}

SearchFilter --> DatePicker
SearchFilter --> FileTypeSelector
SearchFilter --> Preview

Preview --> DataTable
Preview --> StatsChart
Preview --> DistributionChart

DatasetConfig --> AccessControl
AccessControl --> UserSearch
AccessControl --> GroupSearch
AccessControl --> RoleSelector
AccessControl --> AttributeEditor

DatasetConfig --> ShareConfig

@enduml
```

### 2.3 상태 다이어그램

```mermaid
stateDiagram-v2
    [*] --> 검색조건입력
    
    검색조건입력 --> 검색중 : 검색 실행
    검색중 --> 미리보기표시 : 검색 완료
    검색중 --> 검색오류 : 검색 실패
    검색오류 --> 검색조건입력 : 조건 수정
    
    미리보기표시 --> 검색조건입력 : 조건 재설정
    미리보기표시 --> 데이터셋설정 : 결과 승인
    
    데이터셋설정 --> 기본정보입력
    기본정보입력 --> 접근제어설정
    접근제어설정 --> 사용자선택 : 사용자 기반
    접근제어설정 --> 그룹선택 : 그룹 기반
    접근제어설정 --> 역할설정 : 역할 기반
    접근제어설정 --> 속성설정 : 속성 기반
    
    사용자선택 --> 제한사항설정
    그룹선택 --> 제한사항설정
    역할설정 --> 제한사항설정
    속성설정 --> 제한사항설정
    
    제한사항설정 --> 데이터셋생성중 : 생성 요청
    데이터셋생성중 --> 생성완료 : 성공
    데이터셋생성중 --> 생성오류 : 실패
    생성오류 --> 데이터셋설정 : 재시도
    
    생성완료 --> 공유링크생성 : 공유 설정
    생성완료 --> [*] : 완료
```

## 3. 화면 와이어프레임

### 3.1 데이터 검색 화면

```plantuml
@startsalt
{
    Voice Phishing 데이터셋 생성
    ---
    데이터 타입: □ 음성  □ 이미지  □ 텍스트
    날짜 범위:  [2024-01-01] ~ [2024-12-31]
    통신사: □ SKT  □ KT  □ LGU+  □ MVNO
    키워드: [검색 키워드 입력]
    파일 크기: [최소] MB ~ [최대] MB
    재생시간:  [최소] 초 ~ [최대] 초
        [검색 실행] [조건 초기화]
}
@endsalt
```

```plantuml
@startsalt
{
    검색 결과 미리보기
    ---
    총 데이터 수: 1,234건
    예상 크기: 2.3 GB

    데이터 타입 분포:
    ■ 음성: 856건 (69%)
    ■ 이미지: 234건 (19%)
    ■ 텍스트: 144건 (12%)

    통신사 분포:
    ■ SKT: 445건 ■ KT: 389건 ■ LGU+: 290건 ■ MVNO: 110건
    [샘플 데이터 보기] [다음 단계]
}
@endsalt
```

### 3.2 접근 제어 설정 화면

```text
┌─────────────────────────────────────────────────────────────┐
│ 2단계: 데이터셋 설정                                         │
├─────────────────────────────────────────────────────────────┤
│ 기본 정보                                                   │
│ 데이터셋 이름: [보이스피싱_2024Q4_데이터]                    │
│ 설명: [2024년 4분기 보이스피싱 데이터 모음]                  │
│ 만료일: [30일 후] ▼                                        │
├─────────────────────────────────────────────────────────────┤
│ 접근 제어 설정                                               │
│                                                             │
│ ○ 공개 데이터셋                                             │
│ ● 제한된 접근                                               │
│                                                             │
│ 허용 대상:                                                  │
│ ┌─────────────────────┬─────────────────────────────────┐   │
│ │ 사용자              │ 그룹                            │   │
│ │ [검색...        ] ▼│ [검색...               ] ▼    │   │
│ │ ✓ 홍길동(hong@ex..)  │ ✓ 데이터분석팀                   │   │
│ │ ✓ 김철수(kim@exa..)  │ ✓ 연구개발팀                     │   │
│ │ + 사용자 추가        │ + 그룹 추가                     │   │
│ └─────────────────────┴─────────────────────────────────┘   │
│                                                             │
│ ┌─────────────────────┬─────────────────────────────────┐   │
│ │ 역할                │ 속성 조건                        │   │
│ │ □ data-analyst      │ department = "보안팀"           │   │
│ │ □ researcher        │ clearance_level >= "LEVEL_3"    │   │
│ │ □ admin             │ + 조건 추가                     │   │
│ └─────────────────────┴─────────────────────────────────┘   │
│                                                             │
│ 제한 사항:                                                  │
│ 다운로드 횟수: [10] 회                                      │
│ 접근 횟수: [100] 회                                         │
│                                                             │
│              [이전] [데이터셋 생성]                          │
└─────────────────────────────────────────────────────────────┘
```

## 4. API 호출 시퀀스

### 4.1 실제 API 호출 순서

```mermaid
sequenceDiagram
    participant UI as 웹 UI
    participant DataAPI as Dataset API
    participant AccessAPI as Access API
    participant UserAPI as User Management API

    Note over UI: 사용자가 검색 조건 입력
    UI->>DataAPI: POST /api/v1/dataset/data/search
    DataAPI-->>UI: 200 OK (미리보기 데이터)

    Note over UI: 사용자 검색 (접근 제어 설정 시)
    UI->>AccessAPI: GET /api/v1/access/search/users?query=홍길동
    AccessAPI->>UserAPI: 사용자 검색 요청
    UserAPI-->>AccessAPI: 사용자 목록
    AccessAPI-->>UI: 검색 결과

    Note over UI: 그룹 검색
    UI->>AccessAPI: GET /api/v1/access/search/groups?query=분석팀
    AccessAPI->>UserAPI: 그룹 검색 요청
    UserAPI-->>AccessAPI: 그룹 목록
    AccessAPI-->>UI: 검색 결과

    Note over UI: 역할 및 속성 조회
    UI->>AccessAPI: GET /api/v1/access/search/roles
    UI->>AccessAPI: GET /api/v1/access/search/attributes
    AccessAPI-->>UI: 역할 목록
    AccessAPI-->>UI: 속성 목록

    Note over UI: 데이터셋 생성
    UI->>DataAPI: POST /api/v1/dataset/datasets
    Note right of UI: {<br/>  name: "데이터셋명",<br/>  filter: {...},<br/>  accessSettings: {...}<br/>}
    DataAPI->>AccessAPI: 접근 규칙 검증
    AccessAPI-->>DataAPI: 검증 완료
    DataAPI-->>UI: 201 Created (데이터셋 정보)

    Note over UI: 공유 링크 생성 (선택사항)
    UI->>DataAPI: POST /api/v1/dataset/datasets/{id}/share
    DataAPI-->>UI: 201 Created (공유 정보)
```

이 문서는 Voice Phishing 데이터셋 생성의 전체 프로세스를 시각화하고, 사용자 인터페이스의 구조와 흐름을 명확하게 정의합니다.
