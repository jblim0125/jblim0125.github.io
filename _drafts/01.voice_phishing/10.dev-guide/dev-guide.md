# 개발 가이드

## 개요

1. 실행 환경
OS: Linux(Ubuntu / Rocky)
Platform: 컨테이너 환경(Docker/k8s)
Database : Postgres 16
SearchEngine : OpenSearch

2. 언어
Java 21, Python 3.11

3. Framework
SpringBoot 3.5.3
JPA
Flyway

4. Nexus 를 이용한 라이브러리 관리

## 라이브러리

1. 의존성 버전 관리
    com.mobigen.versions : libs.version.toml 파일을 관리
2. 데이터 모델
    com.mobigen.schema : grpc (proto 정의), jsonschema2pojo를 이용한 entity, dto 등 정의
3. 오류 처리 및 응답 메시지
    com.mobigen.aop : SpringBoot 응답 처리를 위한 라이브러리 (Aspect, ResponseWrapper, GlobalExceptionHander)

