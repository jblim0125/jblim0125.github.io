# OpenMetadata

## 개요

OpenMetadata 는 Server, Database, ElasticSearch, Ingestion 4개의 서비스들로 구성되어 있습니다.
데이터패브릭 과제에서는 1.4.0 버전을 사용하여 2024년 과제를 수행하였습니다.

다음은 각 서비스들에 대해서 알아보겠습니다.

## 1. Server

DropWizard 를 이용해 개발되었으며, 웹 + 웹서버로 구성되어있다. 웹은 OVP에서 담당하므로 웹에 대해서는 생략하겠습니다.
서버는 시스템 코어로써 동작하여 모든 동작에서 시작 or 종료 되는 지점입니다.

1. 기능
    - 회원
        - 회원관리(내부 데이터베이스에 회원 정보를 관리)
        - 인증 서버 연동(Keycloak, ...)
        - 메일 인증(메일 서버 연동)
        - 팀 관리 기능
        - 역할 관리 기능  
        - 권한 관리(메뉴 접근) 기능
    - 저장소 가상화
        - 데이터베이스
        - 검색(OpenSearch, ElasticSearch)
        - Hive
        - S3
        - 기타
    - 탐색
        - 저장소 별 하위 데이터 탐색
    - 검색
        - 다양한 필터를 이용한 데이터 검색(ElasticSearch 연동)
        - 데이터베이스 - 검색 엔진 간 동기화(스케줄링을 통해 1일 1회 실행 or 수동 실행 가능)
    - 데이터 정보
        - 일반
            - 이름, 별칭, 설명
            - 태그, 사전
        - 스키마
            - 컬럼
            - 컬럼 별 태그 및 사전
        - 리니지
            - 데이터 연관 관계(FK)
        - 샘플 데이터
        - 프로파일링
            - 기술 통계(min, max, null, unique, ...)

2. 수정부분
    - MinIO 타입 저장소 추가
    - 비정형 데이터 처리를 위한 Container 타입 데이터 스키마 수정

## 2. Metadata Ingestion

Airflow 위에서 동작하는 서비스로 메타데이터 수집, 프로파일링(샘플 및 기술 통계 데이터 수집), 기타 작업들이 수행됩니다.
`Server`는 사용자의 요청(연결 테스트, Pipeline 생성/실행/로그 등)을 수신하여 `MetadataIngestion` 서비스로 작업을 요청하고 결과를 수신합니다.

`Metadata Ingestion` 은 `Plugin`과 `Ingestion` 2가지로 구성되고, Plugin 은 Airflow REST API Plugin으로 `OpenMetadata Server`와의 통신을 목적으로 구성되었습니다.
Ingestion 은 Airflow 의 DAG 형태로 Pipeline 별 1개의 DAG와 1대1 매칭됩니다.

1. 기능(Pipeline)  
    - 연결 테스트
    - 메타데이터 수집
      - 데이터 상태(신규, 수정, 삭제) 확인
      - 이름
      - 설명(Comment)
      - 스키마(컬럼)
        - 이름
        - 데이터 타입
        - 설명
    - 프로파일
      - 샘플 데이터 수집
      - 프로파일용 데이터 로드(% or line) 후 통계 정보 작성
      - min
      - max
      - null
      - unique
      - avg
      - median
      - sum
      - avg
      - ...
    - 데이터 리니지
      - 해당 기능에 대해서는 사용하지 않음.
    - User Testsuite
      - 해당 기능에 대해서는 사용하지 않음.

2. 수정 부분
    - MinIO 에 대한 처리 추가
      - S3를 바탕으로 작성
    - 엑셀 파일 처리 추가
      - 시트 중 1번째 시트에 대한 데이터만 처리
    - Doc, Hwp 등 문서 데이터 처리 추가
      - 메타데이터 수집, 샘플 수집

## 3. Database

MySQL과 PostgreSQL 두가지를 지원합니다.
데이터베이스 스키마는 `bootstrap` 내에 존재하며, 각 버전 별 마이그레이션을 위한 SQL들이 있습니다.
bootstrap 내 파일의 실행은 `openmetadata-service/src/main/org/openmetadata/service/migration` 에서 처리됩니다.

## 4. ElasticSearch

데이터 검색을 위한 서비스로 오픈메타데이터에서는 다양한 데이터에 대해 인덱스를 분리하여 관리하고 검색을 처리합니다.

1. 필요 부분
   - 클러스터 구성
     - 검색 속도 향상을 위해 클러스터 구성에 대한 요구사항이 있습니다.

2. 참고할 부분
    엘라스틱 서치의 인덱스는 다음의 위치에서 확인할 수 있습니다.
    `openmetadata-service/src/main/resources/elasticsearch`, `openmetadata-service/src/main/resources/elasticsearch/en`
