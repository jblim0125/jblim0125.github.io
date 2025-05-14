---
layout: post
title: spring cloud gatgeway 01
author: jblim0125
date: 2024-06-22
category: 2024
---

## 개요

JWT 적용을 위해 자료들을 찾아보는 과정에서 Spring Cloud Gateway, Keycloak 를 접하게 되었고,
이를 활용해 보고자 합니다. Spring Cloud Gateway와 KeyCloak을 이용해 인증과 함께 다양한 내용을
다뤄볼 예정입니다.  

## API 게이트웨이

![api_gateway-01](/assets/images/spring/gateway/gateway-01.png)

마이크로 서비스 아키텍처(Micro Service Architecture) 환경에서 많은 서비스들의 엔드포인트를 관리하는 데 있어서 어려움이 생기고,
또 각 서비스마다 공통적으로 들어가는 기능(ex 인증/인가, 로깅 등)들을 중복으로 개발해야 한다는 문제점이 발생합니다.

위 그림과 같이 클라이언트로부터 요청을 수신하여 게이트웨이의 설정에 따라 내부처리(인증)와 각 엔드포인트로 전달하는 프록시(proxy) 역할을 한다.  

### 주요 기능

1. 인증 (Authentication) 과 인가 (Authorization)  
    * 인증 (Authentication) : 사용자의 신원을 검증하는 행위  
    * 인가 (Authorization)  : 사용자에게 요청을 실행할 수 있는 권한 부여 절차  
    * 인증과 인가는 필수적으로 제공되어야 하는 기능  
    * 인증과 인가 서비스를 위해 자체 기능을 구현해서 사용하거나, 별도의 외부 서비스와 연계하여 제공  
2. API 라우팅 (Routing)  
    API 요청을 식별하여 적절한 마이크로 서비스로 전달하는 기능  
3. QoS (Quality of Service)  
    안정적인 서비스 제공 및 네트워크 품질 관리를 위하여 사용자 / 클라이언트 / API 단위로 접속 제어 기능  
4. 로깅 (Logging) 및 모니터링 (Monitoring)  
    API 요청에 대한 로깅 지원 및 모니터링 기능  
5. 입력 유효성 검사  
    API 요청이 적절한 형식과 필수 데이터를 포함하는지 식별 및 관리 기능 제공  

### 오픈소스 활용

Kong, Tyk, KrakenD, Apache APISIX API Gateway, Spring Cloud Gateway, Netflix Zuul API Gateway 등  
단순히 설치해서 활용하는 방법도 있겠지만 코드를 보고 확인해보고자 Spring Cloud Gateway 를 이용해 보고자 한다.

## Spring Cloud Gateway

1. 작동 원리  
다음 다이어그램은 Spring Cloud Gateway의 작동 방식에 대한 개념도이다.  

![spring-cloud-gateway](/assets/images/spring/gateway/gateway-02.png)

> 필터가 점선으로 구분된 이유:  
> 클라이언트 요청이 전송되기 전 -> "Pre Filter Chain"  
> 백엔드 서비스 응답 전송 전 -> "Post Filter Chain"  

1. 클라이언트에서 게이트웨이에 요청 전송  
2. 게이트웨이 핸들러 매핑에서 요청 확인 후 게이트웨이 웹 핸들러로 전송
3. 게이트웨이 웹 핸들러에서는 필터 체인을 통해 요청을 실행
4. "Pre Filter Chain"이 실행된 후 백엔드 서비스로 요청 전송(프록시)
5. 백엔드 서비스로부터 응답 "Post Filter Chain" 실행

## 환경

로컬 환경에서 도커 기반으로 다음 서비스들을 이용할 계획이다.

* Spring Cloud Gateway  
  * JDK 21
  * Gradle
  * Spring Boot 3.3.1
  * Spring Cloud Starter Gateway 4.1.0
* KeyCloak
  * keycloak/keycloak:24.0.0  
  * [KeyCloak - Install On Docker](https://www.keycloak.org/getting-started/getting-started-docker)
* MariaDB
  * mariadb:11.4.2  

## 기능

* 인증
* 다이나믹 라우팅

## 구현  

Spring Cloud Gateway 활용과 관련 너무 많은 내용들에 산으로 가버렸다...
다음편에서 인증과 다이나믹 라우팅에 대해서 이어서 다뤄보겠습니다.

## 참고 사이트

[Spring Cloud Gateway Source](https://github.com/spring-cloud/spring-cloud-gateway)
[Spring Cloud Gateway Doc](https://docs.spring.io/spring-cloud-gateway/reference/spring-cloud-gateway/how-it-works.html)
