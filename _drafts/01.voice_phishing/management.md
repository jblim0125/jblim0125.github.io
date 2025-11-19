# 보이스피싱 1세부 관리

- [보이스피싱 1세부 관리](#보이스피싱-1세부-관리)
  - [1. 업무 리스트](#1-업무-리스트)
    - [1.2. 설계](#12-설계)
    - [1.3. 개발](#13-개발)
    - [1.4. 테스트](#14-테스트)
  - [3. 참고](#3-참고)
    - [모비젠 연구 내용](#모비젠-연구-내용)
  - [1. 아키텍처 구조와 설정 방법 설명](#1-아키텍처-구조와-설정-방법-설명)
  - [2. 데이터](#2-데이터)
  - [3. API 문서](#3-api-문서)

## 1. 업무 리스트

- [v] Nginx + WAF
  - 기능
    - HTTPS(SSL) 적용
    - 웹 방화벽(WAF) 적용
  - [ ] Nginx + WAF 상세 설정 - Zero Trust 적용 시 필요
- [v] Keycloak
  - 기능
    - 사용자 인증(OAuth2, OpenID Connect)
    - 사용자 및 그룹 관리
    - 사용자 및 그룹 권한(역할) 관리
    - 사용자 속성 관리
  - [v] voice-phishing realm 생성
  - [v] 사용자 인증 테스트 사용자, 그룹 생성
- [v] Spring Cloud Gateway
  - 기능
    - API Gateway(동적 라우팅)
    - 사용자 인증 및 권한 관리
  - [v] Auth
    - [v] OAuth2 를 이용한 keycloak 연동(사용자 인증) 완료
    - [v] JWT 토큰 기반 사용자 정보(id, group, roles, attributes) 파싱 및 전달 기능 개발 완료
  - [v] Dynamic Routing
    - [v] Actuator, GatewayRouteDefinitionRepository를 활용한 동적 라우팅 기능 개발 완료
    - [v] r2dbc를 이용한 동적 라우팅 정보 저장 기능 개발 완료
- [ ] Access Control Engine(OpenSource)
- [v] Service
  - [v] RestAPI 문서
  - [v] Collect Service
    - [v] 데이터 수신 및 처리 기능
  - [ ] Analysis Service
    - [ ] 스미싱 URL, 악성앱 배포지 등 실시간 공유 대상 데이터 추출 기술
- [v] Storage Service
  - [v] MySQL
  - [v] MinIO
  - [ ] 수평확장
    - [v] MySQL 및 MinIO 수평 확장 방안 및 설계
- [v] GitLab
  - [v] GitLab Runner
  - [v] GitLab CI/CD
- [v] Jaeger  
- [v] SonarQube

### 1.2. 설계

- Collect API
- User API
  - Group
  - Role
  - Attribute
- Share API
  - New API And Set Data - Data Search
  - API Access
- Data Search

### 1.3. 개발

### 1.4. 테스트

## 3. 참고

### 모비젠 연구 내용

- 1단계
  - 1차년도
    - 범죄 의심정보 처리를 위한 데이터 파이프라인 개발
      - 보이스피싱을 포함하는 전기통심금융사기 데이터 소스 별 수집 기술
        - 스팸, 스미싱, 보이스피싱 데이터 각 소스 별 REST API 개발
        - API 별 접근 통제를 위한 사용자 그룹 및 권한 관리 기능
        - 스미싱 URL, 악성앱 배포지 등 실시간 공유 대상 데이터 추출 기술
        - 공유 API 별 접근 통제를 위한 사용자 그룹 및 권한 관리 기능
          -> ai 도움 받아서 portal-service controller 작성
          -> rbac, abac 기반 access control api
      - 대용량 범죄 의심정보 저장을 위한 DB 구축
        - 정형 및 비정형 데이터 저장/관리를 위한 스토리지 설계 및 개발
        - 확장성과 안정성을 보장하는 수평적 확산 분산 스토리지 아키텍쳐 설계 및 개발
        - 작업 큐를 활용한 대용량 데이터 배치 처리 최적화 기술
      - 범죄 의심정보 공유 기술 개발
        - 범죄 의심정보를 외부에서 안전하게 공유 가능한 REST API 개ㅏ
          -> keycloak 인증을 포함한 공유 API
        - 공유 API 별 데이터 필터 및 공유 범위 지정이 가능한 데이터셋 설정 기능
          -> 공유 API와 연결 가능한 데이터 설정 기능
  - 2차년도
    - 범죄 의심정보(개인정보 비식별화) 안심 데이터 공유 플랫폼 개발
      - 범죄 의심정보를 관리 하기 위한 데이터 포털 개발
        - 데이터 정규화, 인덱싱 및 메타데이터 관리를 통한 대규모 데이터 관리 최적화 기술
        - 다양한 수요처에 맞는 역할기반 접근제어 및 속성기반 접근제어를 활용한 데이터 조회 권한 관리 기술
        - 파일 형식 및 데이터 구조 기반 다중 포맷 지원 기술
        - 감사 및 데이터 추적을 위한 로그 관리 기술
      - 모의해킹을 통한 안심 데이터 공유 플랫폼 보안성 점검
        - 모의해킹 전문기업을 통한 공격 표면 점검
        - 데이터 파이프라인 대상 취약점 및 데이터 유출 가능성 점검
        - 데이터 공유를 위한 API 및 웹페이지 점검
        - 취약점 점검 결과에 따른 대응 방안 수립 및 보안성 강화
- 2단계
  - 1차년도
    - 범죄 의심정보 수집 데이터 파이프라인 및 데이터 포털 고도화
      - 범죄 의심정보 수집 데이터 파이프파인 고도화
        - 메시지 큐 기반 비동기 작업 관리 및 분산 처리 기술
        - 사용자 정의 데이터 파이프라인 설정 및 관리 기술
        - 작업 스케줄링 최적화를 위한 DAG(Directed Acyclic Graph) 기반 워크플로우 스케줄링 기술
      - 범죄 의심정보 데이터 포털 고도화
        - 전기통신금융사기 데이터 통계 생성, 조회 및 시각화 기술
        - 저장된 데이터를 수동으로 분류 하고 태깅 가능한 기능
        - 대규모 데이터 내보내기 작업의 안정성 향상을 위한 작업 분배 및 워크플로우 관리 기술
  - 2차년도
    - 데이터 파이프라인 및 포털 대상 모의해킹을 통한 안전성 고도화
      - 모의해킹 전문기업을 통한 취약점 점검 및 결과 반영을 통한 보안성 고도화
        - 데이터 파이프라인의 주요 단계와 포털 대상 공격표면 분석을 통한 취약점 점검 대상 선정
        - 데이터 흐름 기반 공격 시뮬레이션 및 공격 표면 대상 모의해킹 수행 결과 발견된 취약점 대상 우선순위 설정
        - 취약점 별 상세 조치 방안 도출 및 취약점 패치를 통한 보안성 고도화
      - 제로트러스트 아키텍쳐를 적용한 시스템 고도화
        - ID 수명 주기 관리 체계 수립 및 OTP, 보안키 등 인증 설계 및 개발
        - 서비스 보안 정책 수립 및 정책 관리, 위험 수준별 통제 방안 설계 및 적용
        - 보안 정책의 실시간 적용, 실시간 접속 상황 확인 및 세션의 수명주기 관리
        - 데이터 파이프라인 대상 데이터 흐름, 보안 이벤트 모니터링 및 시각화

- 문의 내용 정리
  - 데이터 공유 시스템으로 전달되는 데이터는 어떤 형태인가요?
    - 익명화된 데이터(음성, 텍스트) + 메타데이터
  - 한번에 전달되는 데이터의 양은 어느 정도인가요?
  - 데이터는 어떤 주기로 전달되나요?
  - 데이터 공유 플랫폼에서는 수집된 데이터(익명화된 데이터)의 저장과 수요처 연동 외 연동하는 서비스(모듈은)는 없나요?
  - 수요처 별 필요로 하는 데이터는 어떤 것 인가요?
    - 공유되는 데이터는 수요처 별로 다른 내용이 될 것이고,
    - 주관에서 설계 및 모비젠과 협의할거임.

- 2025-07-04
샘플 데이터 제공은 어렵다.
하드웨어구성에 대한 상세 요구사항을 전달해야 함
다음엔 시연


keycloak 과 연동하여
group과 user 정보를 설정할 수 있는 restapi 를 만들어줘
/api-gateway/api/users
조회, 생성, 수정, 삭제, 패스워드 설정

현재 user metadata 는 다음과 같음
attributes
 - email
      "group": "user-metadata",
 - nickname
      "group": "user-metadata",
 - attributes
      "group": "user-metadata",
      "multivalued": true
```

/api-gateway/api/groups
생성, 수정, 삭제, 그룹 트리 설정
사용자 할당, 해제


스팸정책팀     ----> 보이스피싱 포털(가명처리 서비스)의 플랫폼 개발?

경찰청/이통사 <----> 보이스피싱 포털 간 양방향 데이터 공유 기능
  -> 기존에는 통계 정보의 공유로 생각되었으나, 각 관리 주체(기관, 통신사)에서 정의한 구조의 보이스피싱 데이터임
  -> 외부 데이터를 위한 데이터 저장 관련 정리 필요

1. 스팸정책팀의 데이터베이스를 직접 연동할 수 없음
  -> 따라서 가명처리 서비스에서 데이터를 저장해야 함. 


논현IDC 


안녕하세요.책임님!

UI에서 각 서비스 API를 연동에 필요한 정보였던 것 같은데, 
일단 아래 정보들이 필요할 것 같습니다.

## 1. 아키텍처 구조와 설정 방법 설명

Nginx -> API Gateway -> Service(...) 형태로 구성되어 있습니다.

1. Nginx Routing 설정
192.168.105.51:8080/ -> Api Gateway
192.168.105.51:8080/auth -> Keycloak 

2. Api Gateway 설정
API Gateway 의 라우팅 패스를 설정 가능 함.
/{name} -> http://{container-endpoint}/ 

3. API Gateway 설정 화면
192.168.105.51:8080/settings

## 2. 데이터

- 가명처리 데이터 테이블 스키마

| 컬럼명          | 데이터 타입  | 제약조건                            | 설명               |
| --------------- | ------------ | ----------------------------------- | ------------------ |
| log_id          | VARCHAR(50)  | PRIMARY KEY (복합키)                | 로그 ID            |
| data_type       | VARCHAR(20)  | PRIMARY KEY (복합키)                | 데이터 타입        |
| file_path       | VARCHAR(200) |                                     | 파일 경로          |
| file_name       | VARCHAR(100) |                                     | 파일명             |
| file_size_bytes | BIGINT       |                                     | 파일 크기 (바이트) |
| created_at      | TIMESTAMP    | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 생성 시간          |
| updated_at      | TIMESTAMP    | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 수정 시간          |

- 가명처리 데이터 JSON
JSON 포맷의 음성 to 텍스트 데이터의 가명처리 결과 

- 통계 데이터
  - 데이터 수집 통계 (5분 단위)
    | 컬럼명              | 데이터 타입 | 제약조건            | 설명                            |
    | ------------------- | ----------- | ------------------- | ------------------------------- |
    | DATE                | TIMESTAMP   | NOT NULL            | 통계 수집 시간                  |
    | input_voice         | BIGINT      | NOT NULL, DEFAULT 0 | 음성 입력 건수                  |
    | input_stt           | BIGINT      | NOT NULL, DEFAULT 0 | STT 입력 건수                   |
    | save_file           | BIGINT      | NOT NULL, DEFAULT 0 | 파일 저장 건수                  |
    | save_database       | BIGINT      | NOT NULL, DEFAULT 0 | 데이터베이스 저장 건수          |
    | update_database     | BIGINT      | NOT NULL, DEFAULT 0 | 데이터베이스 업데이트 건수      |
    | err_input_voice     | BIGINT      | NOT NULL, DEFAULT 0 | 음성 입력 오류 건수             |
    | err_input_stt       | BIGINT      | NOT NULL, DEFAULT 0 | STT 입력 오류 건수              |
    | err_save_file       | BIGINT      | NOT NULL, DEFAULT 0 | 파일 저장 오류 건수             |
    | err_save_database   | BIGINT      | NOT NULL, DEFAULT 0 | 데이터베이스 저장 오류 건수     |
    | err_update_database | BIGINT      | NOT NULL, DEFAULT 0 | 데이터베이스 업데이트 오류 건수 |

  - 데이터 가명처리 (5분 단위)
    | 컬럼명                           | 타입      | 설명                    |
    | -------------------------------- | --------- | ----------------------- |
    | `DATE`                           | TIMESTAMP | 기본 키                 |
    | `triggered`                      | BIGINT    | 트리거된 횟수           |
    | `dataload_success`               | BIGINT    | 데이터 로드 성공 수     |
    | `dataload_json_processing_error` | BIGINT    | JSON 파싱 오류 수       |
    | `dataload_queue_full_error`      | BIGINT    | 큐 가득 참 오류 수      |
    | `file_download_success`          | BIGINT    | 파일 다운로드 성공 수   |
    | `file_download_error`            | BIGINT    | 파일 다운로드 오류 수   |
    | `text_pseudo_success`            | BIGINT    | 텍스트 가명처리 성공 수 |
    | `text_pseudo_error`              | BIGINT    | 텍스트 가명처리 오류 수 |
    | `image_pseudo_success`           | BIGINT    | 이미지 가명처리 성공 수 |
    | `image_pseudo_error`             | BIGINT    | 이미지 가명처리 오류 수 |
    | `voice_pseudo_success`           | BIGINT    | 음성 가명처리 성공 수   |
    | `voice_pseudo_error`             | BIGINT    | 음성 가명처리 오류 수   |
    | `file_upload_success`            | BIGINT    | 파일 업로드 성공 수     |
    | `file_upload_error`              | BIGINT    | 파일 업로드 오류 수     |
    | `data_save_success`              | BIGINT    | 데이터 저장 성공 수     |
    | `data_save_error`                | BIGINT    | 데이터 저장 오류 수     |
    | `search_index_success`           | BIGINT    | 검색 인덱스 성공 수     |
    | `search_index_error`             | BIGINT    | 검색 인덱스 오류 수     |
    | `update_original_success`        | BIGINT    | 원본 업데이트 성공 수   |
    | `update_original_error`          | BIGINT    | 원본 업데이트 오류 수   |
    | `file_cleanup_success`           | BIGINT    | 파일 정리 성공 수       |
    | `file_cleanup_error`             | BIGINT    | 파일 정리 오류 수       |

## 3. API 문서

다음주에 전달드리겠습니다. 



책임님 문의사항이 있습니다0.! 

현재 web-server 개발 관련하여 Backend Service API 연동 중에,  Spring Cloud OpenFeign을 통해 Backend Service API를 호출하는 작업을 진행하려 하는데, Backend Service들이 각각 컨테이너로 분산 배포되어있고, 확인하기 어려워서요. 
정확한 정보가 필요할 것 같아서 문의 드립니다.

저는, 크게 2가지 서비스의 API 명세서가 필요할 것 같습니다:

1. 가명데이터 목록 조회 관련 서비스

- 가명처리된 데이터 목록 조회 API
- 검색/필터링/정렬/페이징 기능

2. 통계 및 모니터링 관련 서비스

- 원본 데이터 수집 통계 API
- 실시간 모니터링 데이터 API (Task, Queue 상태)
- 파이프라인 처리 통계 API

이 2개 서비스가 각각 어느 Backend Service에 위치해 있는지, 그리고 각 API의 상세 스펙을 확인할 수 있을까요?

필요한 정보:

- 담당 Backend Service 명 및 Base URL
- API 엔드포인트
- 요청 파라미터 (페이징: page, size / 정렬: sortBy, order / 필터: 날짜 범위, 데이터 유형 등)
- 응답 데이터 형태 (JSON 스키마)
- 필수/선택 파라미터 구분

혹시 가능하시다면 각 API의 Swagger 문서나 API 명세서를 공유해주시면 정말 감사하겠습니다!

바쁘신 와중에 번거롭게 해드려 죄송합니다. 검토 부탁드리겠습니다. 감사합니다!


