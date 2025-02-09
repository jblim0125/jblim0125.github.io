---
layout: post
title: spring security - 2
author: jblim0125
date: 2024-12-26
category: 2024
---

## Authentication Mechanisms

Spring Security 레퍼런스 페이지에서는 다양한 인증 기술에 대해서 기술하고 있다.
그 중 `OAuth2 Webflux` 과 관련된 내용을 살펴 볼 계획이다.

반복되는 부분이 있으나, 필요한 부분만 빠르게 확인하고자 할 수 있으므로
레퍼런스 문서의 내용을 빠뜨리지 않고, 정리해 보았다.  

## OAuth2 WebFlux

Spring Security는 포괄적인 OAuth 2.0 지원을 제공합니다. 이 섹션에서는 OAuth 2.0을 애플리케이션에 통합하는 방법을 설명합니다.  

### 개요

Spring Security의 OAuth2.0 지원은 두 가지 주요 기능 세트로 구성됩니다.

* OAuth2 리소스 서버  
* OAuth2 클라이언트  

> `OAuth2 로그인`은 매우 강력한 OAuth2 클라이언트 기능으로 자신만의 섹션을 가질 만합니다.
> 그러나 독립형 기능으로 존재하지 않으며 작동하려면 OAuth2 클라이언트가 필요합니다.

이러한 기능 세트는 OAuth 2.0 권한 부여 프레임워크에 정의된 리소스 서버 및 클라이언트 역할을 포괄하는 반면,
권한 부여 서버 역할은 `Spring Security` 기반으로 구축된 별도 프로젝트인 `Spring Authorization Server`에서 다룹니다 .

`OAuth2 resource server`와 `client` 역할은 일반적으로 하나 이상의 서버 측 애플리케이션으로 표현됩니다.
또한 권한 부여 서버 역할은 하나 이상의 타사로 표현될 수 있습니다(조직 내에서 ID 관리 및/또는 인증을 중앙 집중화하는 경우처럼)
-또는- 애플리케이션으로 표현될 수 있습니다(Spring Authorization Server의 경우처럼).

예를 들어, 일반적인 OAuth2 기반 마이크로서비스 아키텍처는 단일 사용자 지향 클라이언트 애플리케이션,
REST API를 제공하는 여러 백엔드 리소스 서버, 사용자 및 인증 문제를 관리하기 위한 타사 권한 부여 서버로 구성될 수 있습니다.
또한 이러한 역할 중 하나만 나타내는 단일 애플리케이션이 다른 역할을 제공하는 하나 이상의 타사와 통합해야 하는 경우도 일반적입니다.

Spring Security는 이러한 시나리오와 그 이상을 처리합니다. 다음 섹션에서는 Spring Security에서 제공하는 역할을 다루고 일반적인 시나리오에 대한 예를 포함합니다.

### OAuth2 리소스 서버

> 이 섹션에는 예제와 함께 OAuth2 리소스 서버 기능에 대한 요약이 들어 있습니다. 전체 참조 문서는 `OAuth 2.0 리소스 서버`를 참조하세요.

시작하려면 프로젝트에 `spring-security-oauth2-resource-server` 종속성을 추가하세요.
Spring Boot를 사용하는 경우 다음 스타터를 추가하세요.

*Spring Boot를 사용한 OAuth2 클라이언트*  

```gradle
implementation 'org.springframework.boot:spring-boot-starter-oauth2-resource-server'
```

OAuth2 리소스 서버에 대한 다음 사용 사례를 고려하세요.

* OAuth2를 사용하여 API에 대한 액세스를 보호하고 싶습니다 (인증 서버는 JWT 또는 불투명 액세스 토큰을 제공함).  
* JWT (커스텀 토큰)를 사용하여 API에 대한 액세스를 보호하고 싶습니다.  

#### OAuth2 액세스 토큰으로 액세스 보호

OAuth2 액세스 토큰을 사용하여 API에 대한 액세스를 보호하는 것은 매우 일반적입니다.
대부분의 경우 Spring Security는 OAuth2로 애플리케이션을 보호하기 위해 최소한의 구성만 필요합니다.

Spring Security에서 지원하는 토큰에는 두 가지 유형의 `Bearer`가 있으며, 각각 유효성 검사를 위해 다른 구성 요소를 사용합니다.

* `JWT` 는 `ReactiveJwtDecoder` 빈을 사용하여 서명을 검증하고 토큰을 디코딩합니다.
* `Opaque token` 는  `ReactiveOpaqueTokenIntrospector` 빈을 사용하여 토큰을 검사합니다.  

**JWT**  

다음 예제에서는 Spring Boot 구성 속성(application.properties)에서 `ReactiveJwtDecoder` 사용하여 빈을 구성합니다.  

```yaml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          issuer-uri: https://my-auth-server.com
```

Spring Boot를 사용할 때 필요한 것은 이것뿐입니다. Spring Boot에서 제공하는 기본 배열은 다음과 같습니다.

코드를 이용한 JWT 설정

```java
@Configuration
@EnableWebFluxSecurity
public class SecurityConfig {

    @Bean
    public SecurityWebFilterChain securityWebFilterChain(ServerHttpSecurity http) {
        http
            .authorizeExchange((authorize) -> authorize
                .anyExchange().authenticated()
            )
            .oauth2ResourceServer((oauth2) -> oauth2
                .jwt(Customizer.withDefaults())
            );
        return http.build();
    }

    @Bean
    public ReactiveJwtDecoder jwtDecoder() {
        return ReactiveJwtDecoders.fromIssuerLocation("https://my-auth-server.com");
    }

}
```

**Opaque token**  

다음 예제에서는 Spring Boot 구성 속성을 사용하여 `ReactiveOpaqueTokenIntrospector` 빈을 구성합니다.  

```yaml
spring:
  security:
    oauth2:
      resourceserver:
        opaquetoken:
          introspection-uri: https://my-auth-server.com/oauth2/introspect
          client-id: my-client-id
          client-secret: my-client-secret
```

Spring Boot를 사용할 때 필요한 것은 이것뿐입니다. Spring Boot에서 제공하는 기본 배열은 다음과 같습니다.

코드를 이용한 Opaque Token 설정  

```java
@Configuration
@EnableWebFluxSecurity
public class SecurityConfig {

    @Bean
    public SecurityWebFilterChain securityWebFilterChain(ServerHttpSecurity http) {
        http
            .authorizeExchange((authorize) -> authorize
                .anyExchange().authenticated()
            )
            .oauth2ResourceServer((oauth2) -> oauth2
                .opaqueToken(Customizer.withDefaults())
            );
        return http.build();
    }

    @Bean
    public ReactiveOpaqueTokenIntrospector opaqueTokenIntrospector() {
        return new SpringReactiveOpaqueTokenIntrospector(
            "https://my-auth-server.com/oauth2/introspect", "my-client-id", "my-client-secret");
    }

}
```

이 외 `사용자 정의 JWT`를 이용하는 방법에 대해서 설명이 있었는데 생략하겠습니다.  

### OAuth2 Client

> 이 섹션에는 예제와 함께 OAuth2 클라이언트 기능에 대한 요약이 포함되어 있습니다.

시작하려면 프로젝트에 `spring-security-oauth2-client` 종속성을 추가하세요.

Spring Boot를 사용한 OAuth2 클라이언트

```gradle
implementation 'org.springframework.boot:spring-boot-starter-oauth2-client'
```

Consider the following use cases for OAuth2 Client:

* I want to log users in using OAuth 2.0 or OpenID Connect 1.0  
* I want to obtain an access token for users in order to access a third-party API  
* I want to do both (log users in and access a third-party API)  
* I want to enable an extension grant type  
* I want to customize an existing grant type  
* I want to customize token request parameters  
* I want to customize the WebClient used by OAuth2 Client components  

#### OAuth2로 사용자 로그인

사용자가 OAuth2를 통해 로그인하도록 요구하는 것은 매우 일반적입니다.
OpenID Connect 1.0은 OAuth2 클라이언트가 사용자 신원 검증을 수행하고 사용자를 로그인할 수
있도록 설계된 특수 토큰인 `id_token` 을 제공합니다.
특정 경우에 OAuth2를 사용하여 사용자를 직접 로그인할 수 있습니다(GitHub 및 Facebook과 같이
OpenID Connect를 구현하지 않는 인기 있는 소셜 로그인 제공자의 경우와 같이).

다음 예제에서는 OAuth2 또는 OpenID Connect를 사용하여 사용자를 로그인시킬 수 있는 OAuth2
클라이언트 역할을 하도록 애플리케이션을 구성합니다.  

```java
@Configuration
@EnableWebFluxSecurity
public class SecurityConfig {

    @Bean
    public SecurityWebFilterChain securityWebFilterChain(ServerHttpSecurity http) {
        http
            // ...
            .oauth2Login(Customizer.withDefaults());
        return http.build();
    }

}
```

위의 구성 외에도 애플리케이션은 적어도 `ClientRegistration`하나를 사용하여 `ReactiveClientRegistrationRepository`
빈을 구성해야 합니다. 다음 예제는 Spring Boot 구성 속성을 사용하여 `InMemoryReactiveClientRegistrationRepository` 빈을 구성합니다.

```yaml
spring:
  security:
    oauth2:
      client:
        registration:
          my-oidc-client:
            provider: my-oidc-provider
            client-id: my-client-id
            client-secret: my-client-secret
            authorization-grant-type: authorization_code
            scope: openid,profile
        provider:
          my-oidc-provider:
            issuer-uri: https://my-oidc-provider.com
```

위의 구성을 사용하면 이제 애플리케이션이 두 개의 추가 엔드포인트를 지원합니다.

1. 로그인 엔드포인트(예: /oauth2/authorization/my-oidc-client)는 로그인을 시작하고 타사 인증서버로 리디렉션을 수행하는 데 사용됩니다.  
2. 리디렉션 엔드포인트(예: /login/oauth2/code/my-oidc-client)는 권한 부여 서버가 클라이언트 애플리케이션으로 다시 리디렉션하는 데 사용되며
   액세스 토큰 요청을 통해 `id_token` and/or `access_token` code 를 얻는 데 사용되는 매개변수를 포함합니다.  

#### 보호된 리소스에 액세스

OAuth2로 보호되는 (타사) API에 요청을 하는 것은 OAuth2 클라이언트의 핵심 사용 사례입니다.
이는 클라이언트(Spring Security의 `OAuth2AuthorizedClient` 클래스로 표현됨)를 승인하고
`Bearer`토큰을 아웃바운드 요청의 헤더에 배치하여 보호된 리소스에 액세스함으로써 달성 됩니다.

다음 예제에서는 타사 API에서 보호된 리소스를 요청할 수 있는 OAuth2 클라이언트 역할을 하도록 애플리케이션을 구성합니다.

**OAuth2 클라이언트 구성**  

```java
@Configuration
@EnableWebFluxSecurity
public class SecurityConfig {

    @Bean
    public SecurityWebFilterChain securityWebFilterChain(ServerHttpSecurity http) {
        http
            // ...
            .oauth2Client(Customizer.withDefaults());
        return http.build();
    }

}
```

> 위의 예는 사용자를 로그인하는 방법을 제공하지 않습니다. `.oauth2Client()` 와 `oauth2Login()` 결합하는 예는 다음 섹션을 참조하세요.

위의 구성 외에도 애플리케이션은 적어도 `ClientRegistration` 을 사용하여 `ReactiveClientRegistrationRepository`
빈을 구성해야 합니다. 다음 예제는 Spring Boot 구성 속성을 사용하여 `InMemoryReactiveClientRegistrationRepository` 빈을 구성합니다.  

```yaml
spring:
  security:
    oauth2:
      client:
        registration:
          my-oauth2-client:
            provider: my-auth-server
            client-id: my-client-id
            client-secret: my-client-secret
            authorization-grant-type: authorization_code
            scope: message.read,message.write
        provider:
          my-auth-server:
            issuer-uri: https://my-auth-server.com
```

OAuth2 클라이언트 기능을 지원하도록 Spring Security를 구성하는 것 외에도 보호된 리소스에 액세스하는 방법을 결정하고
그에 따라 애플리케이션을 구성해야 합니다. Spring Security는 보호된 리소스에 액세스하는 데 사용할 수 있는 액세스 토큰을
얻기 위한 `ReactiveOAuth2AuthorizedClientManager` 구현을 제공합니다.  

> Spring Security는 기본 `ReactiveOAuth2AuthorizedClientManager`빈이 존재하지 않는 경우 이를 등록합니다.

`ReactiveOAuth2AuthorizedClientManager` 를 사용하는 가장 쉬운 방법은 `ExchangeFilterFunctionWebClient` 를 통해 요청을 가로채는 것 입니다 .

다음 예제에서는 각 요청의 헤더에 토큰을 배치하여 보호된 리소스에 액세스할 수 있도록
`ReactiveOAuth2AuthorizedClientManager` 구성하는 `WebClientBearerAuthorization` 기본값을 사용합니다.

*WebClient구성 하기ExchangeFilterFunction*  

```java
@Configuration
public class WebClientConfig {

    @Bean
    public WebClient webClient(ReactiveOAuth2AuthorizedClientManager authorizedClientManager) {
        ServerOAuth2AuthorizedClientExchangeFilterFunction filter =
                new ServerOAuth2AuthorizedClientExchangeFilterFunction(authorizedClientManager);
        return WebClient.builder()
                .filter(filter)
                .build();
    }

}
```

이 `WebClient` 구성은 다음 예와 같이 사용될 수 있습니다:  

```java
import static org.springframework.security.oauth2.client.web.reactive.function.client.ServerOAuth2AuthorizedClientExchangeFilterFunction.clientRegistrationId;

@RestController
public class MessagesController {

    private final WebClient webClient;

    public MessagesController(WebClient webClient) {
        this.webClient = webClient;
    }

    @GetMapping("/messages")
    public Mono<ResponseEntity<List<Message>>> messages() {
        return this.webClient.get()
                .uri("http://localhost:8090/messages")
                .attributes(clientRegistrationId("my-oauth2-client"))
                .retrieve()
                .toEntityList(Message.class);
    }

    public record Message(String message) {
    }

}
```

#### 현재 사용자의 보호된 리소스에 액세스

사용자가 OAuth2 또는 OpenID Connect를 통해 로그인하면 권한 부여 서버는
보호된 리소스에 직접 액세스하는데 사용할 수 있는 액세스 토큰을 제공할 수 있습니다.
이는 두 사용 사례에 대해 하나의 `ClientRegistration`구성하면 되므로 편리합니다.

> 이 섹션에서는 `Log Users In With OAuth2` 및 `Access Protected Resources`를 단일 구성으로 결합합니다.

다음 예제에서는 애플리케이션을 구성하여 사용자를 로그인시키고 (타사) API에서 보호된 리소스를
요청할 수 있는 OAuth2 클라이언트 역할을 하도록 합니다.

*OAuth2 로그인 및 OAuth2 클라이언트 구성*  

```java
@Configuration
@EnableWebFluxSecurity
public class SecurityConfig {
    @Bean
    public SecurityWebFilterChain securityWebFilterChain(ServerHttpSecurity http) {
        http
            // ...
            .oauth2Login(Customizer.withDefaults())
            .oauth2Client(Customizer.withDefaults());
        return http.build();
    }
}
```

위의 구성 외에도 애플리케이션은 `ClientRegistration` 사용하여
`ReactiveClientRegistrationRepository` 빈을 적어도 하나 이상 구성해야 합니다.

다음 예제는 Spring Boot 구성 속성을 사용하여 `InMemoryReactiveClientRegistrationRepository` 빈을 구성합니다.

```yaml
spring:
  security:
    oauth2:
      client:
        registration:
          my-combined-client:
            provider: my-auth-server
            client-id: my-client-id
            client-secret: my-client-secret
            authorization-grant-type: authorization_code
            scope: openid,profile,message.read,message.write
        provider:
          my-auth-server:
            issuer-uri: https://my-auth-server.com
```

> Memo:: 이전 예제(OAuth2를 사용하여 사용자 로그인, 보호된 리소스 액세스)와 이 예제의 주요 차이점은
> `scope`로  openid, profile, 사용자 지정 범위(message.read, message.write)를 결합하는 속성을 통해 구성된다는 점입니다.

OAuth2 클라이언트 기능을 지원하도록 Spring Security를 구성하는 것 외에도 보호된 리소스에 액세스하는 방법을 결정하고
그에 따라 애플리케이션을 구성해야 합니다. Spring Security는 보호된 리소스에 액세스하는 데 사용할 수 있는 액세스 토큰을
얻기 위한 `ReactiveOAuth2AuthorizedClientManager` 구현을 제공합니다.

`ReactiveOAuth2AuthorizedClientManager` 를 사용하는 가장 쉬운 방법은 `WebClient`의 `ExchangeFilterFunction` 를 통해 요청을 가로채는 것 입니다.

`WebClient`의 `ReactiveOAuth2AuthorizedClientManager` 기본값을 사용하여 각 요청의 헤더에 `Bearer` 토큰을 배치,
보호된 리소스에 액세스할 수 있도록 사용합니다.

*Configure WebClient with ExchangeFilterFunction*  

```java
@Configuration
public class WebClientConfig {

    @Bean
    public WebClient webClient(ReactiveOAuth2AuthorizedClientManager authorizedClientManager) {
        ServerOAuth2AuthorizedClientExchangeFilterFunction filter =
                new ServerOAuth2AuthorizedClientExchangeFilterFunction(authorizedClientManager);
        return WebClient.builder()
                .filter(filter)
                .build();
    }

}
```

이 `WebClient` 구성은 다음 예와 같이 사용될 수 있습니다:

*보호된 리소스에 액세스하는데 사용 (현재 사용자)*  

```java
@RestController
public class MessagesController {

    private final WebClient webClient;

    public MessagesController(WebClient webClient) {
        this.webClient = webClient;
    }

    @GetMapping("/messages")
    public Mono<ResponseEntity<List<Message>>> messages() {
        return this.webClient.get()
                .uri("http://localhost:8090/messages")
                .retrieve()
                .toEntityList(Message.class);
    }

    public record Message(String message) {
    }

}
```

#### Enable an Extension Grant Type

일반적인 사용 사례에는 `Extension Grant Type`을 활성화 또는 구성하는 것이 포함됩니다.
예를 들어, Spring Security는 `jwt-bearer`및 `token-exchange` 유형에 대한 지원을 제공하지만,
OAuth 2.0 핵심 사양의 일부가 아니기 때문에 기본적으로 활성화하지 않습니다.

Spring Security 6.3 이상에서는 간단히 하나 이상의 빈을 게시하면 `ReactiveOAuth2AuthorizedClientProvider`자동으로 선택됩니다.
다음 예에서는 간단히 `jwt-bearer` 유형을 활성화합니다.

*Enable jwt-bearer Grant Type*  

```java
@Configuration
public class SecurityConfig {

    @Bean
    public ReactiveOAuth2AuthorizedClientProvider jwtBearer() {
        return new JwtBearerReactiveOAuth2AuthorizedClientProvider();
    }

}
```

기본값이 제공되지 않은 경우 Spring Security에서 자동으로 `ReactiveOAuth2AuthorizedClientManager` 기본값을 게시합니다.

> Tip:  
> 사용자 정의 `OAuth2AuthorizedClientProvider` 빈(Custom OAuth2AuthorizedClientProvider bean)은
> 기본 부여 유형(default grant types)이 적용된 후, 제공된 `ReactiveOAuth2AuthorizedClientManager`에 의해 감지되고 적용됩니다.

위의 구성을 달성하기 위해, Spring Security 6.3 이전 버전에서는 직접 게시하고 기본 부여 유형도 다시 활성화해야 했습니다.

*Enable jwt-bearer Grant Type(6.3 이전 버전)*  

```java
@Configuration
public class SecurityConfig {

    @Bean
    public ReactiveOAuth2AuthorizedClientManager authorizedClientManager(
            ReactiveClientRegistrationRepository clientRegistrationRepository,
            ServerOAuth2AuthorizedClientRepository authorizedClientRepository) {

        ReactiveOAuth2AuthorizedClientProvider authorizedClientProvider =
            ReactiveOAuth2AuthorizedClientProviderBuilder.builder()
                .authorizationCode()
                .refreshToken()
                .clientCredentials()
                .password()
                .provider(new JwtBearerReactiveOAuth2AuthorizedClientProvider())
                .build();

        DefaultReactiveOAuth2AuthorizedClientManager authorizedClientManager =
            new DefaultReactiveOAuth2AuthorizedClientManager(
                clientRegistrationRepository, authorizedClientRepository);
        authorizedClientManager.setAuthorizedClientProvider(authorizedClientProvider);

        return authorizedClientManager;
    }

}
```

*Customize an Existing Grant Type*  

빈(bean)을 게시하여 확장 부여 유형(extension grant types)을 활성화할 수 있는 기능은 기본값을 재정의하지 않고도
기존 부여 유형을 사용자 정의할 수 있는 기회를 제공합니다. 예를 들어, `client_credentials` 부여 유형에 대한
`ReactiveOAuth2AuthorizedClientProvider`의 시계 편차(clock skew)를 사용자 정의하려면, 다음과 같이 간단히 빈을 게시할 수 있습니다:

*클라이언트 자격 증명 부여 유형 사용자 정의(Customize Client Credentials Grant Type)”*  

```java
@Configuration
public class SecurityConfig {

    @Bean
    public ReactiveOAuth2AuthorizedClientProvider clientCredentials() {
        ClientCredentialsReactiveOAuth2AuthorizedClientProvider authorizedClientProvider =
                new ClientCredentialsReactiveOAuth2AuthorizedClientProvider();
        authorizedClientProvider.setClockSkew(Duration.ofMinutes(5));

        return authorizedClientProvider;
    }

}
```

*Customize Token Request Parameters* (인증 코드 부여를 위한 토큰 요청 매개변수 사용자 정의)  

액세스 토큰을 얻을 때 요청 매개변수를 사용자 정의해야 하는 경우는 비교적 일반적입니다.
예를 들어, `authorization_code` 부여 방식에서 공급자가 특정 매개변수(`audience`)를 요구하는 경우.  

이를 위해 Spring Security가 OAuth2 클라이언트 구성 요소를 설정하는 데 사용할 수 있도록,
제네릭 타입 `OAuth2AuthorizationCodeGrantRequest`인 `ReactiveOAuth2AccessTokenResponseClient` 타입의 빈(bean)을 간단히 게시할 수 있습니다.

다음 예제는 `authorization_code` 부여 방식에 대해 토큰 요청 매개변수를 사용자 정의하는 방법을 보여줍니다:

```java
@Configuration
public class SecurityConfig {

    @Bean
    public ReactiveOAuth2AccessTokenResponseClient<OAuth2AuthorizationCodeGrantRequest> authorizationCodeAccessTokenResponseClient() {
        WebClientReactiveAuthorizationCodeTokenResponseClient accessTokenResponseClient =
            new WebClientReactiveAuthorizationCodeTokenResponseClient();
        accessTokenResponseClient.addParametersConverter(parametersConverter());

        return accessTokenResponseClient;
    }

    private static Converter<OAuth2AuthorizationCodeGrantRequest, MultiValueMap<String, String>> parametersConverter() {
        return (grantRequest) -> {
            MultiValueMap<String, String> parameters = new LinkedMultiValueMap<>();
            parameters.set("audience", "xyz_value");

            return parameters;
        };
    }

}
```

> Tip:  
> 이 경우 우리는 `SecurityWebFilterChain` 빈의 사용자 정의할 필요는 없습니다.
> 만일 추가적인 사용자 정의 없이 Spring Boot를 사용하는 경우 실제로 `SecurityWebFilterChain` 빈을 생략할 수 있습니다.

보시다시피, `ReactiveOAuth2AccessTokenResponseClient`빈으로 제공하는 것은 매우 편리합니다.
Spring Security DSL을 직접 사용하는 경우, `OAuth2 Login`과 `OAuth2 Client` 구성 요소 모두에 적용되도록 해야 합니다.
DSL을 사용한 방법을 살펴보고 내부적으로 구성되는 내용을 이해하려고 해봅시다.

```java
@Configuration
@EnableWebFluxSecurity
public class SecurityConfig {

    @Bean
    public SecurityWebFilterChain securityWebFilterChain(ServerHttpSecurity http) {
        WebClientReactiveAuthorizationCodeTokenResponseClient accessTokenResponseClient =
            new WebClientReactiveAuthorizationCodeTokenResponseClient();
        accessTokenResponseClient.addParametersConverter(parametersConverter()); 

        http
            .authorizeExchange((authorize) -> authorize
                .anyExchange().authenticated()
            )
            .oauth2Login((oauth2Login) -> oauth2Login
                .authenticationManager(new DelegatingReactiveAuthenticationManager(
                    new OidcAuthorizationCodeReactiveAuthenticationManager(
                        accessTokenResponseClient, new OidcReactiveOAuth2UserService()
                    ),
                    new OAuth2LoginReactiveAuthenticationManager(
                        accessTokenResponseClient, new DefaultReactiveOAuth2UserService()
                    )
                ))
            )
            .oauth2Client((oauth2Client) -> oauth2Client
                .authenticationManager(new OAuth2AuthorizationCodeReactiveAuthenticationManager(
                    accessTokenResponseClient
                ))
            );

        return http.build();
    }

    private static Converter<OAuth2AuthorizationCodeGrantRequest, MultiValueMap<String, String>> parametersConverter() {
        // ...
    }

}
```

- 코드 설명
    위의 코드는 Spring Security를 활용한 OAuth2 인증 및 클라이언트 구성을 보여줍니다.
    이를 통해 `ReactiveOAuth2AccessTokenResponseClient`를 활용하여 `authorization_code` 부여 방식에서
    사용자 정의된 요청 매개변수를 추가하는 방법을 설정합니다. 아래에서 주요 섹션을 단계적으로 설명하겠습니다.

    1. SecurityConfig 클래스  
        * 이 클래스는 Spring Security 구성을 정의하는 데 사용됩니다.
        * @Configuration 어노테이션을 사용하여 스프링 컨텍스트에서 구성 클래스로 인식되며, `@EnableWebFluxSecurity`는 WebFlux 기반 애플리케이션에 Spring Security를 활성화합니다.

    2. SecurityWebFilterChain 빈 정의  
        * 이 메서드는 보안 필터 체인을 정의하며, Spring Security의 필수 구성 요소입니다.
        * ServerHttpSecurity를 사용해 세부적인 보안 정책과 OAuth2 인증 구성을 설정합니다.

    3. accessTokenResponseClient 생성

        ```java
        WebClientReactiveAuthorizationCodeTokenResponseClient accessTokenResponseClient =
          new WebClientReactiveAuthorizationCodeTokenResponseClient();
        accessTokenResponseClient.addParametersConverter(parametersConverter()); 
        ```

        * WebClientReactiveAuthorizationCodeTokenResponseClient는 OAuth2 토큰 요청을 처리하기 위한 기본 클라이언트입니다.
        * addParametersConverter 메서드는 사용자 정의 매개변수 변환기를 추가합니다. 이를 통해 토큰 요청 시 필요한 추가 매개변수를 쉽게 설정할 수 있습니다.

    4. HTTP 보안 구성  
        * http.authorizeExchange:
        * 모든 요청을 인증된 사용자만 사용할 수 있도록 설정합니다.

        *OAuth2 Login 구성*  

        ```java
        .oauth2Login((oauth2Login) -> oauth2Login
          .authenticationManager(new DelegatingReactiveAuthenticationManager(
            new OidcAuthorizationCodeReactiveAuthenticationManager(
              accessTokenResponseClient, new OidcReactiveOAuth2UserService()
            ),
            new OAuth2LoginReactiveAuthenticationManager(
              accessTokenResponseClient, new DefaultReactiveOAuth2UserService()
            )
          ))
        )
        ```

        * oauth2Login:
        * OAuth2 로그인 구성 섹션입니다.
        * authenticationManager는 인증 관리를 위해 여러 인증 관리자를 위임(DelegatingReactiveAuthenticationManager)하여 설정합니다.
        * OidcAuthorizationCodeReactiveAuthenticationManager는 OpenID Connect 인증을 처리하며, accessTokenResponseClient와 사용자 서비스를 사용합니다.
        * OAuth2LoginReactiveAuthenticationManager는 일반 OAuth2 인증을 처리하며, 동일하게 accessTokenResponseClient를 사용합니다.

        *OAuth2 Client 구성*  

        ```java
        .oauth2Client((oauth2Client) -> oauth2Client
          .authenticationManager(new OAuth2AuthorizationCodeReactiveAuthenticationManager(
            accessTokenResponseClient
          ))
        )
        ```

        * oauth2Client:
        * OAuth2 클라이언트 구성 섹션입니다.
        * authenticationManager는 authorization_code 부여 방식의 인증 관리를 처리합니다.

    5. parametersConverter 메서드

        ```java
        private static Converter<OAuth2AuthorizationCodeGrantRequest, MultiValueMap<String, String>> parametersConverter() {
          // ...
        }
        ```

        * 이 메서드는 사용자 정의 매개변수 변환기를 생성합니다.
        * OAuth2AuthorizationCodeGrantRequest를 입력받아 요청 매개변수를 변환하는 로직을 정의합니다.
        * 예를 들어, 요청 매개변수에 audience와 같은 값을 추가하는 로직을 구현할 수 있습니다.


다른 유형의 `grant type`의 경우 `ReactiveOAuth2AccessTokenResponseClient` 기본값을 재정의 한 빈을 게시할 수 있습니다.
예를 들어 `client_credentials` grant type 대한 토큰 요청을 사용자 정의하려면 다음 빈을 게시할 수 있습니다.

```java
@Configuration
public class SecurityConfig {

    @Bean
    public ReactiveOAuth2AccessTokenResponseClient<OAuth2ClientCredentialsGrantRequest> clientCredentialsAccessTokenResponseClient() {
        WebClientReactiveClientCredentialsTokenResponseClient accessTokenResponseClient =
                new WebClientReactiveClientCredentialsTokenResponseClient();
        accessTokenResponseClient.addParametersConverter(parametersConverter());

        return accessTokenResponseClient;
    }

    private static Converter<OAuth2ClientCredentialsGrantRequest, MultiValueMap<String, String>> parametersConverter() {
        // ...
    }

}
```

Spring Security는 다음과 같은 일반적인 유형의 `ReactiveOAuth2AccessTokenResponseClient` Bean 을 자동으로 해결합니다.

* OAuth2AuthorizationCodeGrantRequest(WebClientReactiveAuthorizationCodeTokenResponseClient)  
* OAuth2RefreshTokenGrantRequest(WebClientReactiveRefreshTokenTokenResponseClient)  
* OAuth2ClientCredentialsGrantRequest(WebClientReactiveClientCredentialsTokenResponseClient)  
* OAuth2PasswordGrantRequest(WebClientReactivePasswordTokenResponseClient)  
* JwtBearerGrantRequest(WebClientReactiveJwtBearerTokenResponseClient)  
* TokenExchangeGrantRequest(WebClientReactiveTokenExchangeTokenResponseClient) 

#### Customize the WebClient used by OAuth2 Client Components

또 다른 일반적인 사용 사례는 액세스 토큰을 얻을 때 사용되는 `WebClient`를 사용자 정의해야 하는 경우입니다.
SSL 설정을 구성하거나 회사 네트워크에 프록시 설정을 적용하기 위해 기본 HTTP 클라이언트 라이브러리
(`ClientHttpConnector` 사용자 정의를 통해)를 사용자 정의하기 위해 수행해야 할 수도 있습니다.

Spring Security 6.3 이상에서는 간단히 해당 유형의 `ReactiveOAuth2AccessTokenResponseClient` 빈을 게시하면 Spring Security 
`ReactiveOAuth2AuthorizedClientManager` 가 해당 빈을 구성하여 게시해줍니다.

다음 예에서는 지원되는 모든 `grant type` 대해 `WebClient` 를 사용자 정의를 수행합니다.

OAuth2 클라이언트에 맞게 사용자 WebClient 정의

```java
@Configuration
public class SecurityConfig {

    @Bean
    public ReactiveOAuth2AccessTokenResponseClient<OAuth2AuthorizationCodeGrantRequest> authorizationCodeAccessTokenResponseClient() {
        WebClientReactiveAuthorizationCodeTokenResponseClient accessTokenResponseClient =
            new WebClientReactiveAuthorizationCodeTokenResponseClient();
        accessTokenResponseClient.setWebClient(webClient());

        return accessTokenResponseClient;
    }

    @Bean
    public ReactiveOAuth2AccessTokenResponseClient<OAuth2RefreshTokenGrantRequest> refreshTokenAccessTokenResponseClient() {
        WebClientReactiveRefreshTokenTokenResponseClient accessTokenResponseClient =
            new WebClientReactiveRefreshTokenTokenResponseClient();
        accessTokenResponseClient.setWebClient(webClient());

        return accessTokenResponseClient;
    }

    @Bean
    public ReactiveOAuth2AccessTokenResponseClient<OAuth2ClientCredentialsGrantRequest> clientCredentialsAccessTokenResponseClient() {
        WebClientReactiveClientCredentialsTokenResponseClient accessTokenResponseClient =
            new WebClientReactiveClientCredentialsTokenResponseClient();
        accessTokenResponseClient.setWebClient(webClient());

        return accessTokenResponseClient;
    }

    @Bean
    public ReactiveOAuth2AccessTokenResponseClient<OAuth2PasswordGrantRequest> passwordAccessTokenResponseClient() {
        WebClientReactivePasswordTokenResponseClient accessTokenResponseClient =
            new WebClientReactivePasswordTokenResponseClient();
        accessTokenResponseClient.setWebClient(webClient());

        return accessTokenResponseClient;
    }

    @Bean
    public ReactiveOAuth2AccessTokenResponseClient<JwtBearerGrantRequest> jwtBearerAccessTokenResponseClient() {
        WebClientReactiveJwtBearerTokenResponseClient accessTokenResponseClient =
            new WebClientReactiveJwtBearerTokenResponseClient();
        accessTokenResponseClient.setWebClient(webClient());

        return accessTokenResponseClient;
    }

    @Bean
    public ReactiveOAuth2AccessTokenResponseClient<TokenExchangeGrantRequest> tokenExchangeAccessTokenResponseClient() {
        WebClientReactiveTokenExchangeTokenResponseClient accessTokenResponseClient =
            new WebClientReactiveTokenExchangeTokenResponseClient();
        accessTokenResponseClient.setWebClient(webClient());

        return accessTokenResponseClient;
    }

    @Bean
    public WebClient webClient() {
        // ...
    }

}
```

기본값이 제공되지 않은 경우 Spring Security에서 자동으로 `ReactiveOAuth2AuthorizedClientManager` 기본값을 게시합니다.

> Memo:  
> Spring Security 6.3 이전 버전에서는 사용자 정의 시 구성 요소에 적용되었는지 직접 확인해야 했습니다.

*Spring Security 6.3 이전 버전에서의 사용자 정의 설정*  

```java
@Configuration
public class SecurityConfig {

    @Bean
    public ReactiveOAuth2AccessTokenResponseClient<OAuth2AuthorizationCodeGrantRequest> authorizationCodeAccessTokenResponseClient() {
        WebClientReactiveAuthorizationCodeTokenResponseClient accessTokenResponseClient =
            new WebClientReactiveAuthorizationCodeTokenResponseClient();
        accessTokenResponseClient.setWebClient(webClient());

        return accessTokenResponseClient;
    }

    @Bean
    public ReactiveOAuth2AuthorizedClientManager authorizedClientManager(
            ReactiveClientRegistrationRepository clientRegistrationRepository,
            ServerOAuth2AuthorizedClientRepository authorizedClientRepository) {

        WebClientReactiveRefreshTokenTokenResponseClient refreshTokenAccessTokenResponseClient =
            new WebClientReactiveRefreshTokenTokenResponseClient();
        refreshTokenAccessTokenResponseClient.setWebClient(webClient());

        WebClientReactiveClientCredentialsTokenResponseClient clientCredentialsAccessTokenResponseClient =
            new WebClientReactiveClientCredentialsTokenResponseClient();
        clientCredentialsAccessTokenResponseClient.setWebClient(webClient());

        WebClientReactivePasswordTokenResponseClient passwordAccessTokenResponseClient =
            new WebClientReactivePasswordTokenResponseClient();
        passwordAccessTokenResponseClient.setWebClient(webClient());

        WebClientReactiveJwtBearerTokenResponseClient jwtBearerAccessTokenResponseClient =
            new WebClientReactiveJwtBearerTokenResponseClient();
        jwtBearerAccessTokenResponseClient.setWebClient(webClient());

        JwtBearerReactiveOAuth2AuthorizedClientProvider jwtBearerAuthorizedClientProvider =
            new JwtBearerReactiveOAuth2AuthorizedClientProvider();
        jwtBearerAuthorizedClientProvider.setAccessTokenResponseClient(jwtBearerAccessTokenResponseClient);

        WebClientReactiveTokenExchangeTokenResponseClient tokenExchangeAccessTokenResponseClient =
            new WebClientReactiveTokenExchangeTokenResponseClient();
        tokenExchangeAccessTokenResponseClient.setWebClient(webClient());

        TokenExchangeReactiveOAuth2AuthorizedClientProvider tokenExchangeAuthorizedClientProvider =
            new TokenExchangeReactiveOAuth2AuthorizedClientProvider();
        tokenExchangeAuthorizedClientProvider.setAccessTokenResponseClient(tokenExchangeAccessTokenResponseClient);

        ReactiveOAuth2AuthorizedClientProvider authorizedClientProvider =
            ReactiveOAuth2AuthorizedClientProviderBuilder.builder()
                .authorizationCode()
                .refreshToken((refreshToken) -> refreshToken
                    .accessTokenResponseClient(refreshTokenAccessTokenResponseClient)
                )
                .clientCredentials((clientCredentials) -> clientCredentials
                    .accessTokenResponseClient(clientCredentialsAccessTokenResponseClient)
                )
                .password((password) -> password
                    .accessTokenResponseClient(passwordAccessTokenResponseClient)
                )
                .provider(jwtBearerAuthorizedClientProvider)
                .provider(tokenExchangeAuthorizedClientProvider)
                .build();

        DefaultReactiveOAuth2AuthorizedClientManager authorizedClientManager =
            new DefaultReactiveOAuth2AuthorizedClientManager(
                clientRegistrationRepository, authorizedClientRepository);
        authorizedClientManager.setAuthorizedClientProvider(authorizedClientProvider);

        return authorizedClientManager;
    }

    @Bean
    public WebClient webClient() {
        // ...
    }

}
```

## OAuth2.0 Login

OAuth 2.0 로그인 기능은 애플리케이션에 사용자가 OAuth 2.0 공급자(예: GitHub) 또는 OpenID Connect 1.0 공급자(예: Google)에서
기존 계정을 사용하여 애플리케이션에 로그인할 수 있는 기능을 제공합니다. OAuth 2.0 로그인은 "Google로 로그인" 또는
"GitHub로 로그인" 사용 사례를 구현합니다.  

이 섹션에서는 keycloak 을 인증 공급자로 사용한 로그인 방법을 보여주며 다음 주제를 다룹니다.

* Initial Setup  
* Setting the Redirect URI  
* Configure application.yml  
* Boot the Application  

### Initial Setup

로그인에 keycloak을 idp로 사용하는 경우 realm 생성에서 client, user 등록을 비롯해
추가로 Identity Provider(IdP) 브로커로 사용한다면 google, github, naver, kakao 등 요구사항에 맞춰 다양한 설정이 필요할 수 있습니다.
keycloak 과 관련된 자세한 내용은 keycloak 공식 사이트에서 확인해 주시기 바랍니다.

여기에서는 keycloak 에 realm, client, user 생성을 통해 사용자 인증을 수행하는 과정만을 다루도록 하겠습니다.

### Setting the Redirect URI

다음은 `Redirect URI` 의 이해를 돕기 위한 내용이다.

**기본 이해**  

1. Keycloak의 역할:  
    * 브로커로 동작하는 경우 : Keycloak은 사용자 인증을 위임받아 Google, Apple, GitHub 등 외부 IdP와 상호작용합니다.
    * Keycloak은 최종적으로 사용자 정보를 애플리케이션에 전달합니다.
2. OAuth2 Login의 Redirect URI:  
    * `Redirect URI`은 애플리케이션이 사용자를 인증 후 수신하기 위해 Keycloak에 제공하는 정보입니다.
    * Keycloak은 인증 완료 후 이 URL로 사용자 정보와 함께 인증 코드를 보냅니다.

**Keycloak 연동 구성 시의 Redirect URL 설정**  

1. Keycloak에서 리디렉션 설정  
    Keycloak 관리 콘솔에서 설정해야 할 주요 항목:
    * Keycloak Realm에서 **클라이언트(Client)**를 생성합니다.
    * 해당 클라이언트의 Redirect URI에 애플리케이션의 리디렉트 URL을 추가합니다.
    예시:
    `*https*://jblim0125.github.com/login/oauth2/code/keycloak`

    * 여기서 `/login/oauth2/code/keycloak`은 Spring Security에서 사용하는 기본 리디렉트 경로입니다.
    * 필요에 따라 이 경로는 커스터마이징 가능합니다.

2. Spring Security 사용 앱 설정(Configure application.yaml 참조)  

3. Keycloak에 Google, Apple, GitHub 연동  
    * Keycloak 관리 콘솔에서 Identity Providers를 설정하여 Google, Apple, GitHub 등을 추가합니다.  
    * 사용자는 애플리케이션에서 로그인 시 Keycloak의 로그인 화면으로 리디렉션되며, Keycloak은 Google, Apple, GitHub 등의 IdP 중 하나를 선택하게 합니다.  

    *요청 흐름*  
    1. 사용자가 애플리케이션에 접속하여 로그인을 시도합니다.
    2. Spring Security는 사용자를 Keycloak 로그인 페이지로 리디렉션합니다.
    3. Keycloak은 Google, Apple, GitHub 등의 외부 IdP로 인증을 위임합니다.
    4. 인증이 성공하면 Keycloak은 사용자를 애플리케이션의 `redirect_uri`로 다시 리디렉션합니다.
    5. Spring Security는 Keycloak에서 받은 인증 코드를 사용해 토큰을 교환하고 사용자 정보를 얻습니다.

    *리디렉션 URL의 올바른 구성*  
    * Keycloak에 설정된 Redirect URI는 애플리케이션에서 사용하는 URI와 정확히 일치해야 합니다.
    * 일반적으로 Spring Security는 `/login/oauth2/code/{registrationId}` 형식을 사용합니다.
    * `{registrationId}`는 Keycloak의 `registrationId`와 동일해야 합니다.

    예:
    * Keycloak 클라이언트에서 설정:  
      `Redirect URI: https://jblim0125.github.com/login/oauth2/code/keycloak`  
    * Spring Security의 구성:  
      `redirect-uri: "{baseUrl}/login/oauth2/code/keycloak"`

**요약**  

* Keycloak은 인증(브로커) 역할을 수행하므로, 애플리케이션은 Keycloak과만 통신합니다.
* Spring Security의 redirect_uri는 Keycloak 클라이언트의 Redirect URI와 일치해야 합니다.
* Keycloak이 (외부 IdP) 인증을 처리하고 최종적으로 애플리케이션으로 리디렉션합니다.
* Keycloak 관리 콘솔에서 Google, Apple, GitHub 등을 설정하면, 애플리케이션은 별도의 IdP 통합 없이 Keycloak과의 통합만으로 모든 인증을 처리할 수 있습니다.

### Configure application.yml

Spring Security를 사용하는 애플리케이션에서 application.yml 또는 application.properties에 아래 설정을 추가합니다.

```yaml
spring:
  security:
    oauth2:
      client:
        registration:
          keycloak:
            client-id: your-client-id
            client-secret: your-client-secret
            provider: keycloak
            redirect-uri: "{baseUrl}/login/oauth2/code/keycloak"
            scope:
              - openid
              - profile
              - email
        provider:
          keycloak:
            issuer-uri: https://keycloak-server/auth/realms/your-realm
```

* `client-id`와 `client-secret`: Keycloak에 등록한 클라이언트의 ID와 비밀 키입니다.
* `issuer-uri`: Keycloak의 Realm URL입니다. (.well-known/openid-configuration 정보를 제공합니다.)

### Boot the Application

Spring Boot 샘플을 실행하고 `localhost:8080`. 그러면 기본 자동으로 keycloak 로그인 페이지로 리디렉션됩니다.
(IdP 브로커로 동작하는 경우 Google, Apple, Github 등 아이콘(버튼)을 클릭 시 인증을 위해 해당 사이트로 리디렉션됩니다.)

이 후 OAuth 클라이언트에 대한 접근 허용/거부와 내 정보(이메일 주소를 포함한 기본 프로파일 정보)에 대한 동의 과정이 거칩니다.

### Spring Boot 자동 구성 재정의

OAuth 클라이언트 지원을 위한 Spring Boot 자동 구성 클래스는 `ReactiveOAuth2ClientAutoConfiguration` 입니다.

다음과 같은 작업을 수행합니다.

* OAuth 클라이언트 속성에서 `ClientRegistration(s)` 정보를 `ReactiveClientRegistrationRepository` @Bean 으로 등록합니다.  
* `SecurityWebFilterChain` @Bean을 등록하고 `serverHttpSecurity.oauth2Login().`을 통해 `OAuth 2.0 Login`을 활성화합니다.  

특정 요구 사항에 따라 자동 구성을 재정의해야 하는 경우 다음과 같은 방법을 사용할 수 있습니다.  

* Register a ReactiveClientRegistrationRepository @Bean
* Register a SecurityWebFilterChain @Bean
* Completely Override the Auth-configuration

*`ReactiveClientRegistrationRepository` @Bean*  
다음 예제에서는 `ReactiveClientRegistrationRepository` @Bean 을 등록하는 방법을 보여줍니다:

```java
@Configuration
public class OAuth2LoginConfig {

	@Bean
	public ReactiveClientRegistrationRepository clientRegistrationRepository() {
		return new InMemoryReactiveClientRegistrationRepository(this.googleClientRegistration());
	}

	private ClientRegistration googleClientRegistration() {
		return ClientRegistration.withRegistrationId("google")
				.clientId("google-client-id")
				.clientSecret("google-client-secret")
				.clientAuthenticationMethod(ClientAuthenticationMethod.CLIENT_SECRET_BASIC)
				.authorizationGrantType(AuthorizationGrantType.AUTHORIZATION_CODE)
				.redirectUri("{baseUrl}/login/oauth2/code/{registrationId}")
				.scope("openid", "profile", "email", "address", "phone")
				.authorizationUri("https://accounts.google.com/o/oauth2/v2/auth")
				.tokenUri("https://www.googleapis.com/oauth2/v4/token")
				.userInfoUri("https://www.googleapis.com/oauth2/v3/userinfo")
				.userNameAttributeName(IdTokenClaimNames.SUB)
				.jwkSetUri("https://www.googleapis.com/oauth2/v3/certs")
				.clientName("Google")
				.build();
	}
}
```

*`SecurityWebFilterChain` @Bean*  
다음 예제는 `SecurityWebFilterChain` @Bean을 등록하고 `@EnableWebFluxSecurity`과
`serverHttpSecurity.oauth2Login()`을 통해 `OAuth 2.0 Login`을 활성화 하는 방법을 보여줍니다.

```java
@Configuration
@EnableWebFluxSecurity
public class OAuth2LoginSecurityConfig {

	@Bean
	public SecurityWebFilterChain securityWebFilterChain(ServerHttpSecurity http) {
		http
			.authorizeExchange(authorize -> authorize
				.anyExchange().authenticated()
			)
			.oauth2Login(withDefaults());

		return http.build();
	}
}
```

*Completely Override the Auth-configuration*  
`ReactiveClientRegistrationRepository` @Bean과 `SecurityWebFilterChain` @Bean을 등록하여
자동 구성을 완전히 재정의 하는 방법을 보여줍니다.

```java
@Configuration
@EnableWebFluxSecurity
public class OAuth2LoginConfig {

	@Bean
	public SecurityWebFilterChain securityWebFilterChain(ServerHttpSecurity http) {
		http
			.authorizeExchange(authorize -> authorize
				.anyExchange().authenticated()
			)
			.oauth2Login(withDefaults());

		return http.build();
	}

	@Bean
	public ReactiveClientRegistrationRepository clientRegistrationRepository() {
		return new InMemoryReactiveClientRegistrationRepository(this.googleClientRegistration());
	}

	private ClientRegistration googleClientRegistration() {
		return ClientRegistration.withRegistrationId("google")
				.clientId("google-client-id")
				.clientSecret("google-client-secret")
				.clientAuthenticationMethod(ClientAuthenticationMethod.CLIENT_SECRET_BASIC)
				.authorizationGrantType(AuthorizationGrantType.AUTHORIZATION_CODE)
				.redirectUri("{baseUrl}/login/oauth2/code/{registrationId}")
				.scope("openid", "profile", "email", "address", "phone")
				.authorizationUri("https://accounts.google.com/o/oauth2/v2/auth")
				.tokenUri("https://www.googleapis.com/oauth2/v4/token")
				.userInfoUri("https://www.googleapis.com/oauth2/v3/userinfo")
				.userNameAttributeName(IdTokenClaimNames.SUB)
				.jwkSetUri("https://www.googleapis.com/oauth2/v3/certs")
				.clientName("Google")
				.build();
	}
}
```

*Spring Boot 없이 구성*  
Spring Boot를 사용할 수 없고 미리 정의된 공급자(예: Google) 중 하나를 구성하려는 경우 CommonOAuth2Provider다음 구성을 적용하세요.

```java
@Configuration
@EnableWebFluxSecurity
public class OAuth2LoginConfig {

	@Bean
	public SecurityWebFilterChain securityWebFilterChain(ServerHttpSecurity http) {
		http
			.authorizeExchange(authorize -> authorize
				.anyExchange().authenticated()
			)
			.oauth2Login(withDefaults());

		return http.build();
	}

	@Bean
	public ReactiveClientRegistrationRepository clientRegistrationRepository() {
		return new InMemoryReactiveClientRegistrationRepository(this.googleClientRegistration());
	}

	@Bean
	public ReactiveOAuth2AuthorizedClientService authorizedClientService(
			ReactiveClientRegistrationRepository clientRegistrationRepository) {
		return new InMemoryReactiveOAuth2AuthorizedClientService(clientRegistrationRepository);
	}

	@Bean
	public ServerOAuth2AuthorizedClientRepository authorizedClientRepository(
			ReactiveOAuth2AuthorizedClientService authorizedClientService) {
		return new AuthenticatedPrincipalServerOAuth2AuthorizedClientRepository(authorizedClientService);
	}

	private ClientRegistration googleClientRegistration() {
		return CommonOAuth2Provider.GOOGLE.getBuilder("google")
				.clientId("google-client-id")
				.clientSecret("google-client-secret")
				.build();
	}
}
```

다음은 목표로 했던 `Host(base url)을 이용한 Keycloak의 개별 Realm과의 연동`을 위해 하나씩 수행해 나가는 과정을 담아보고자 한다.
개인적인 일에 할애 할 시간이 얼마남지 않았다. 1월에는 회사 업무(25년도 목표 달성을 위한 계획)의 연속이 될 것 같다.  
