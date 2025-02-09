---
layout: post
title: spring security - 3
author: jblim0125
date: 2025-01-03
category: 2025
---

## 설계

### 데이터베이스 스키마

1. Auth - 인증 관련  
  우선 간단하게 `Host`와 `Client ID, Secret` 정보를 넣어 보았다.  
  ![alt text](image.png)  
2. Route - 라우팅 관련  
  인증 기능 개발 완료 후 추가 진행  

#### JSONSchema2POJO

```json

```

## 구현  

### 환경 설정  

#### Keycloak  

* 실행 정보  
`K8S` 환경에서 `PostgreSQL` 을 저장소로 사용하도록 하고, `GATEWAY` 뒤에 위치.

#### PostgreSQL

* 실행 정보  
`Gateway`, `Keycloak`을 위한 `데이터베이스`와 사용자, 권한 설정 필요.

*docker-entrypoint.d* 디렉토리에 초기화를 위한 SQL 추가  

*init_v01.sql*

```sql
CREATE DATABASE gateway_db encoding='UTF8';
\c gateway_db;
-- 사용자 생성 (비밀번호는 적절히 변경하세요)
CREATE ROLE gateway_user WITH LOGIN PASSWORD 'gateway_password';
-- 권한 부여
GRANT ALL PRIVILEGES ON DATABASE gateway_db TO gateway_user;
-- public schema 생성
CREATE SCHEMA IF NOT EXISTS public;
-- public 권한 부여
GRANT CREATE, USAGE ON SCHEMA public to gateway_user;

-- Keycloak 데이터베이스 이름
CREATE DATABASE keycloak_db encoding='UTF8';
\c keycloak_db;
-- Keycloak 사용자 생성 (비밀번호는 적절히 변경하세요)
CREATE ROLE keycloak_user WITH LOGIN PASSWORD 'keycloak_password';
-- 권한 부여
GRANT ALL PRIVILEGES ON DATABASE keycloak_db TO keycloak_user;
-- public schema 생성
CREATE SCHEMA IF NOT EXISTS public;
-- public schema 생성 에 대한 권한 부여
GRANT CREATE, USAGE ON SCHEMA public to keycloak_user;
```

#### Docker Compose

다음은 `keycloak`과 `PostgreSQL`을 실행하는 docker compose 파일이다.
추가적으로 `jaeger`가 포함되어 있다.

*docker-compose.yaml*

```yaml
version: "1.0"
services:
  postgres:
    container_name: postgres
    image: postgres:16.6-alpine3.21
    restart: always
    environment:
      POSTGRES_USER: "admin"
      POSTGRES_PASSWORD: "Admin007!"
    expose:
      - 5432
    ports:
      - "5432:5432"
    volumes:
      - ./postgres/data:/var/lib/postgresql/data
      - ./postgres/conf/my-postgres.conf:/etc/postgresql/postgresql.conf
      - ./postgres/init.d:/docker-entrypoint-initdb.d
    networks:
      - my_net
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U admin -h localhost"]
      interval: 10s
      timeout: 5s
      retries: 5
  prepare-jaeger:
    # Run this step as root so that we can change the directory owner.
    container_name: prepare-jaeger
    user: root
    image: busybox:stable
    command: "/bin/sh -c 'mkdir -p /badger/data && touch /badger/data/.initialized && chown -R 10001:10001 /badger'"
    volumes:
      - ./jaeger:/badger
  jaeger:
    container_name: jaeger
    image: jaegertracing/all-in-one:1.60
    restart: always
    environment:
      COLLECTOR_OTLP_ENABLED: "true"
      SPAN_STORAGE_TYPE: "badger"
      BADGER_EPHEMERAL: "false"
      BADGER_DIRECTORY_VALUE: "/badger/data"
      BADGER_DIRECTORY_KEY: "/badger/key"
    expose:
      - 16686
      - 4317
      - 4318
      - 14250
    ports:
      - "16686:16686"
    networks:
      - my_net 
    volumes:
      - ./jaeger:/badger
    depends_on:
      prepare-jaeger:
        condition: service_completed_successfully
    healthcheck:
      test: wget -q --spider http://localhost:16686
      interval: 15s
      timeout: 10s
      retries: 10
  keycloak:
    container_name: keycloak
    image: quay.io/keycloak/keycloak:26.0.7
    restart: always
    command: ["start-dev"]
    environment:
      KC_BOOTSTRAP_ADMIN_USERNAME: admin
      KC_BOOTSTRAP_ADMIN_PASSWORD: "Admin007!"
      KC_DB: postgres
      KC_DB_POOL_MAX_SIZE: 100    # 100 default
      KC_DB_POOL_MIN_SIZE: 10
      KC_DB_URL: "jdbc:postgresql://postgres:5432/keycloak_db"
      KC_DB_USERNAME: keycloak_user
      KC_DB_PASSWORD: keycloak_password
      KC_PROXY_HEADERS: "forwarded"
      KC_FEATURES: "opentelemetry"
      KC_TRACING_ENABLED: "true"
      KC_TRACING_ENDPOINT: "http://jaeger:4317"
      KC_TRACING_JDBC_ENABLED: "false"
    expose:
      - 8080
      - 9000
    ports:
      - "38080:8080"
    networks:
      - my_net
    depends_on:
      postgres:
        condition: service_healthy
      jaeger:
        condition: service_healthy
    healthcheck:
      test: wget -q --spider http://localhost:8080/auth
      interval: 15s
      timeout: 10s
      retries: 10
networks:
  my_net:
    ipam:
      driver: default
      config:
        - subnet: "172.19.0.0/24"
```

### Project Init

* Gradle Dependencies

```java
plugins {
	java
	id("org.springframework.boot") version "3.4.1"
	id("io.spring.dependency-management") version "1.1.7"
}

group = "com.mobigen"
version = "0.0.1-SNAPSHOT"

java {
	toolchain {
		languageVersion = JavaLanguageVersion.of(21)
	}
}

configurations {
	compileOnly {
		extendsFrom(configurations.annotationProcessor.get())
	}
}

repositories {
	mavenCentral()
}

extra["springCloudVersion"] = "2024.0.0"

dependencies {
	implementation("org.springframework.boot:spring-boot-starter-actuator")
	implementation("org.springframework.boot:spring-boot-starter-data-r2dbc")
	implementation("org.springframework.boot:spring-boot-starter-oauth2-authorization-server")
	implementation("org.springframework.boot:spring-boot-starter-oauth2-client")
	implementation("org.springframework.boot:spring-boot-starter-security")
	implementation("org.springframework.boot:spring-boot-starter-thymeleaf")
	implementation("org.springframework.boot:spring-boot-starter-webflux")
	implementation("org.flywaydb:flyway-core")
	implementation("org.flywaydb:flyway-database-postgresql")
	implementation("org.springframework:spring-jdbc")
	implementation("org.springframework.cloud:spring-cloud-starter-gateway")
	implementation("org.thymeleaf.extras:thymeleaf-extras-springsecurity6")
	compileOnly("org.projectlombok:lombok")
	developmentOnly("org.springframework.boot:spring-boot-devtools")
	runtimeOnly("org.postgresql:postgresql")
	runtimeOnly("org.postgresql:r2dbc-postgresql")
	annotationProcessor("org.springframework.boot:spring-boot-configuration-processor")
	annotationProcessor("org.projectlombok:lombok")
	testImplementation("org.springframework.boot:spring-boot-starter-test")
	testImplementation("io.projectreactor:reactor-test")
	testImplementation("org.springframework.security:spring-security-test")
	testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}

dependencyManagement {
	imports {
		mavenBom("org.springframework.cloud:spring-cloud-dependencies:${property("springCloudVersion")}")
	}
}

tasks.withType<Test> {
	useJUnitPlatform()
}
```

### Data Structure

jsonschema2pojo를 활용 예정?

```json
{
  "$id": "https://jblim0125.github.io/schema/entity/data/organization.json",
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Organization",
  "description": "Host 별 설정 정보 저장을 위한 루트 엔티티", 
  "type": "object",
  "javaType": "com.jblim.gateway.schema.entity.Organization",
//   "javaInterfaces": [
//     "com.jblim.gateway.schema.....Interface"
//   ],
  "definitions": {
    "keycloakClientInfo": {
      "type": "object",
      "javaType": "com.jblim.gateway.schema.",
      "title": "object",
      "description": "Type of Profile Sample (percentage or rows)",
      "properties": {
        "name": {
            "type": "string",
            "minLength" : 1,
            "maxLength" : 256,
            "pattern" : ""
        },
        "clientId": {
            "type": "string",
            "minLength" : 1,
            "maxLength" : 256,
            "pattern" : ""
        },
        "clientSecret": {
            "type": "string",
            "minLength" : 1,
            "maxLength" : 256,
            "pattern" : ""
        }
      }
    }
  },
  "properties": {
    "$ref": "#/definitions/...",
    "description": ""
  }
}
```

### Entity

### R2DBC Configuration

### Security Configuration
