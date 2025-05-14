---
layout: post
title: spring cloud gatgeway 04
author: jblim0125
date: 2024-07-21
category: 2024
---

## Spring Cloud Gateway

게이트웨이에 인증 기능은 keycloak 을 이용해 추가해보자.
keycloak에 대해서 잠시 알아보고 설치 및 설정을 진행할 계획이다.  

### 1. 소개  

Keycloak은 오픈 소스로 신원 및 액세스 관리 솔루션입니다. 싱글 사인온, 사용자 인증, 웹 애플리케이션 및
서비스에 대한 인증과 같은 기능을 제공합니다. Keycloak을 사용하면 사용자 신원, 역할 및 권한을 관리하여
애플리케이션을 보호할 수 있습니다. 사용자 이름/암호, 소셜 로그인 및 다중 요소 인증을 포함한 다양한 인증
메커니즘을 지원합니다. 또한, Keycloak은 Google, Facebook 및 LDAP 디렉토리와 같은 인기있는 신원
제공자와의 통합을 제공합니다.  

### 2. 설치

이 문서에서는 도커를 이용해 설치를 진행하는 방법에 대해서 설명한다.  

#### 1. 시작하기 전

도커가 설치되어 있어야 합니다.
서비스하고자 하는 규모에 맞게 키클락을 위한 CPU와 메모리를 제공할 수 있는지 확인하세요. [권장성능사양](#3-권장-성능-사양)

#### 2. Keycloak 시작

터미널에서 다음 명령을 이용해 키클락 시작합니다.

```shell
docker run -itd --name keycloak \
   -p 9090:8080 \
   -e KEYCLOAK_ADMIN=admin \
   -e KEYCLOAK_ADMIN_PASSWORD=admin \
   quay.io/keycloak/keycloak:25.0.2 start-dev
```

위 명령은 테스트 용도(`start-dev`)로 로컬 포트 9090으로 Keycloak에 연결될 수 있도록 하며
사용자 이름 admin 비밀번호 admin 초기 관리자 사용자를 만듭니다.

#### 3. 관리자 콘솔 로그인

1. 관리자 콘솔 접속 (`http://localhost:9090`)  
2. 2단계에서 작성한 관리자 정보로 로그인하세요.  

#### 4. 영역(realm) 생성  

realm을 하나의 가상 공간으로 인지. 그리고 이 공간에 사용자, 그룹, 권한, 어플리케이션을 연결하고 관리할 수 있습니다.  
초기에 Keycloak에는 master라는 단일 Realm이 포함되어 있습니다. 이 Realm은 Keycloak을 관리하는 데만 사용하세요.

Realm을 만들기 위한 단계는 다음과 같습니다.  

1. Keycloak 관리 콘솔에 접속합니다.  
2. 상단의 Realm 선택 영역을 선택하고, Realm 생성을 클릭합니다.  
3. Realm 이름 필드에 'test'을 입력합니다.  
4. 생성을 클릭합니다.  
![create-realm](/assets/images/spring/gateway/04/create-realm.png)

#### 5. 사용자 생성  

1. Keycloak 관리 콘솔에 접속합니다.  
2. 좌측상단의 master를 클릭하여 'test' realm 으로 이동합니다.  
3. 좌측 패널의 Users - Create 를 클릭한다.  
4. 다음과 같이 아이디와 성, 이름을 입력하고 Create 를 클릭한다.  
![add-user](/assets/images/spring/gateway/04/add-user.png)
5. Credential - Set Password 를 클릭한다.  
6. 패스워드를 입력하고 Temporary 를 off 한다.  
![set-password](/assets/images/spring/gateway/04/set-password.png)
7. 관리자 콘솔 로그아웃한다.
8. (`localhost:9090/realms/test/account/`)에서 로그인 되는지 확인한다.  
![login-success](/assets/images/spring/gateway/04/login-personal-info.png)

#### 6. 클라이언트 생성

1. Keycloak 관리 콘솔에 접속합니다.  
2. 좌측상단의 master를 클릭하여 'test' realm 으로 이동합니다.  
3. Clients 클릭합니다.  
4. 다음을 참고하여 데이터를 입력합니다.  
    Client type: OpenID Connect  
    Client ID: gateway  
    Name: gateway  
    Description: Testing the integration of spring cloud gateway and keycloak  
![create-client-01](/assets/images/spring/gateway/04/create-client-01.png)
5. Capability Config를 설정합니다.  
![capability-set](/assets/images/spring/gateway/04/capability-set.png)
6. Login 설정 후 save를 클릭하여 클라이언트를 생성합니다.  
![create-client-02](/assets/images/spring/gateway/04/create-client-02.png)
7. credential 란으로 이동하여 client secret 을 확인합니다.  
![client-secret](/assets/images/spring/gateway/04/client-secret.png)

### 3. 권장 성능 사양

[참고: Keycloak Guides - CPU And Memory](https://www.keycloak.org/high-availability/concepts-memory-and-cpu-sizing)

#### 사양 정보

* 기본 메모리 사용량은 1000MB  
* 100,000개의 사용자 세션마다 3노드 클러스터 구성에서 파드당 500MB  
* 초당 45개의 암호 기반 사용자 로그인 처리에 대해 3노드 클러스터 구성에서 파드당 1개의 vCPU  
* 초당 500개의 클라이언트 자격 증명 부여에 대해 3노드 클러스터에서 파드당 1개의 vCPU  
* 초당 350개의 새로 고침 토큰 요청에 대해 3노드 클러스터의 파드당 1개의 vCPU  

컨테이너 용량 제한 시 최대 부하 상태보다 더 높게 CPU 제한을 설정하셔야 합니다.  
이것은 노드의 빠른 시작과 하나의 노드가 실패할 때 Infinispan 캐시 재조정과 같은 장애 조치 작업을
처리할 수 있는 충분한 용량을 보장합니다. 테스트에서 컨테이너의 CPU 사용량 제한에 걸린경우
Keycloak의 성능이 크게 떨어졌습니다.  

#### 계산 예시

* 목표  
    50,000개의 활성 사용자 세션  
    초당 45 로그인  
    초당 500개의 고객 자격 증명 보조금  
    초당 350개의 새로 고침 토큰 요청  

* 계산  
  * 최소 CPU: 3 vCPU  
        초당 45개의 로그인 = 1 vCPU  
        초당 500개의 클라이언트 자격 증명 부여 = 1개의 vCPU  
        350개의 새로 고침 토큰 = 1개의 vCPU  
  * 최대 CPU: 9 vCPU  
        피크, 시작 및 장애 조치 작업을 처리하기 위해 요청된 CPU의 세 배 허용

  * 최소 메모리: 1250 MB  
        1000MB 기본 메모리와 50,000개의 활성 세션을 위한 250MB RAM

  * 최대 메모리: 1360MB  
        1250MB 예상 메모리 사용량에서 300 비힙 메모리 사용량을 뺀 값, 0.7로 나눈 값

### 4. Spring Cloud Gateway

#### Dependencies

keycloak 연동을 위한 security, oauth2-client 추가

```kotlin
dependencies {
    ...
    implementation("org.springframework.boot:spring-boot-starter-security:3.2.7")
    implementation("org.springframework.boot:spring-boot-starter-oauth2-client:3.2.7")
    implementation("org.springframework.boot:spring-boot-starter-oauth2-resource-server:3.2.7")
    ...
}
```

#### App Configuration

SpringBoot - Keycloak 연동을 위해 필요한 정보 설정  

1. keycloak 관지 콘솔에 접속  
2. 좌측 패널에서 Realm settings 클릭  
3. 다음 사진에서 endpints 중 `OpenID Endpoint Configuration` 클릭  
![endpoint-config](/assets/images/spring/gateway/04/endpoint-config.png)
4. Spring Config 작성 시 참고  
![endpoint-info](/assets/images/spring/gateway/04/endpoint-info.png)

```yaml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          jwk-set-uri: "http://localhost:9090/realms/test/protocol/openid-connect/certs"
          issuer-uri: "http://localhost:9090/realms/test"
      client:
        provider:
          keycloak:
            issuer-uri: "http://localhost:9090/realms/test"
        registration:
          keycloak:
            client-id: gateway
            client-secret: "JxNXRCswbQNb5oiy09fUNQizg0tg9OI8"
            authorization-grant-type: authorization_code
            scope:
              - openid

```

#### GatewayFilterConfig

SecurityWebFilterChain 을 이용해 Gateway에서 Keycloak을 연동할 수 있도록 설정  

```java
@Configuration
@EnableWebFluxSecurity
public class SecurityConfig {

    @Bean
    public SecurityWebFilterChain springSecurityFilterChain(ServerHttpSecurity http) {
        http.authorizeExchange(auth -> auth.anyExchange().authenticated())
                .oauth2Login(withDefaults())
                .oauth2ResourceServer((oauth2) -> oauth2.jwt(Customizer.withDefaults()));
        http.csrf(ServerHttpSecurity.CsrfSpec::disable);
        return http.build();
    }
}
```

#### RestController

Token에 대해서 keycloak으로 전송될 수 있도록 설정  

```java
@RestController
public class Security {

    @GetMapping(value = "/token")
    public Mono<String> getHome(@RegisteredOAuth2AuthorizedClient OAuth2AuthorizedClient authorizedClient) {
        return Mono.just(authorizedClient.getAccessToken().getTokenValue());
    }
}
```

#### TokenReply

HTTP 헤더의 토큰을 내부 서버로 전송할 수 있도록 글로벌 필터 설정

```yaml
spring:
  cloud:
    gateway:
      enabled: true
      default-filters:
        - TokenRelay=
```

### 5. Test

1. login 페이지가 깨지지만 확인 가능  
    ![login-request](/assets/images/spring/gateway/04/login-request.png)
    > 로그인 페이지 설정 필요

2. 생성한 유저정보(test)를 이용해 로그인 성공 시  
    ![alt text](/assets/images/spring/gateway/04/login-success.png)
