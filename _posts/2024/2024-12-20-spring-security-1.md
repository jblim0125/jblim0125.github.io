---
layout: post
title: spring security - 1
author: jblim0125
date: 2024-12-20
category: 2024
---

## 시작하기 전

Spring Cloud Gateway 와 Keycloak 연동으로 사용자 인증이 마무리 되었다고 생각했다.  
하지만 다양한 요구사항을 처리하기 위해서는 많은 부분에서 해결해야 할 것이 있었다.

**목표**  

1. Keycloak 을 이용한 사용자 인증 : Host(조직) 별 Realm 연동
2. SSL 지원 : Host(조직) 별 SSL 처리  
3. UI 인터페이스 : UI를 이용한 Gateway 제어 + 프로그램 재시작 없이 가능해야 함.  

이미 keycloak 동적 연동으로 고통 받고 있다.(일주일동안 고통 받는 중)
그래서 Spring Security 에 대해서 좀 더 알아보고자 한다.  

## Spring Security Architecture

이 섹션에서는 Servlet 기반 애플리케이션 내에서 Spring Security의 고수준 아키텍처에 대해 설명합니다. 

### A Review of Filters

Spring Security의 Servlet 지원은 Servlet Filters에 기반을 두고 있으므로, 먼저 Filters의 역할을 일반적으로 살펴보는 것이 도움이 됩니다. 다음 이미지는 단일 HTTP 요청에 대한 핸들러의 일반적인 계층화를 보여줍니다.

![그림 1. 필터체인](/assets/images/spring/spring-security/image.png)

클라이언트가 애플리케이션에 요청을 보내면 컨테이너는 요청 URI 경로를 기반으로 `FilterChain`을 생성합니다. 이 `FilterChain`은 처리할 `Filter` 인스턴스와 `HttpServletRequest`를 처리할 `Servlet`을 포함합니다. Spring MVC 애플리케이션에서 이 `Servlet`은 `DispatcherServlet`의 인스턴스입니다. 하나의 `HttpServletRequest`와 `HttpServletResponse`는 최대 한 개의 `Servlet`만 처리할 수 있습니다. 하지만, 여러 개의 `Filter`를 사용하여 다음과 같은 작업을 수행할 수 있습니다:

* 하위 `Filter` 인스턴스나 `Servlet`이 호출되지 않도록 방지. 이 경우, Filter는 보통 `HttpServletResponse`를 직접 작성합니다.
* 하위 `Filter` 인스턴스나 `Servlet`에서 사용하는 `HttpServletRequest` 또는 `HttpServletResponse`를 수정.
이를 통해 요청 또는 응답을 변경할 수 있습니다.

`Filter`의 강력함은 전달된 `FilterChain`에서 비롯됩니다.  

`FilterChain` 사용 예제

```java
public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain) {
    // do something before the rest of the application
    chain.doFilter(request, response); // invoke the rest of the application
    // do something after the rest of the application
}
```

`Filter`는 하위 `Filter` 인스턴스와 `Servlet`에만 영향을 미치므로, 각 `Filter`가 호출되는 순서는 매우 중요합니다.  

### DelegatingFilterProxy

Spring은 `DelegatingFilterProxy`라는 `Filter` 구현체를 제공하여, `Servlet` 컨테이너의 생명주기와
Spring의 `ApplicationContext` 간의 연결을 가능하게 합니다. `Servlet` 컨테이너는 자체 표준을 사용하여
`Filter` 인스턴스를 등록할 수 있지만, Spring에서 정의된 Bean은 인식하지 못합니다. `DelegatingFilterProxy`를
표준 `Servlet` 컨테이너 메커니즘을 통해 등록할 수 있으며, 모든 작업은 `Filter`를 구현하는 Spring Bean에 위임됩니다.

아래는 `DelegatingFilterProxy`가 `Filter` 인스턴스 및 `FilterChain`에서 어떻게 작동하는지를 보여주는 그림입니다.  

![그림 2. DelegatingFilterProxy](/assets/images/spring/spring-security/image-1.png)

`DelegatingFilterProxy`는 `ApplicationContext`에서 Bean Filter0을 조회한 다음, Bean Filter0을 호출합니다.
아래는 DelegatingFilterProxy의 의사 코드(pseudo code)를 보여줍니다:

*DelegatingFilterProxy Pseudo Code*  

```java
public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain) {
	Filter delegate = getFilterBean(someBeanName); 
	delegate.doFilter(request, response); 
}
```

1. Spring Bean으로 등록된 Filter를 지연 로딩하여 가져옵니다. 예를 들어,
`DelegatingFilterProxy`에서 `delegate`는 Bean Filter0의 인스턴스입니다.

2. Spring Bean에 작업을 위임합니다.

`DelegatingFilterProxy`의 또 다른 장점은 Filter Bean 인스턴스의 조회를 지연할 수 있다는 점입니다. 이는 컨테이너가 Filter 인스턴스를 등록해야만 컨테이너를 시작할 수 있다는 점에서 중요합니다. 그러나 Spring은 일반적으로 `ContextLoaderListener`를 사용하여 Spring Bean을 로드하며, 이는 Filter 인스턴스가 등록된 이후에 실행됩니다.

### FilterChainProxy

Spring Security의 Servlet 지원은 `FilterChainProxy`에 포함되어 있습니다. `FilterChainProxy`는 Spring Security에서
제공하는 특별한 `Filter`로, `SecurityFilterChain`을 통해 여러 `Filter` 인스턴스에 작업을 위임할 수 있도록 해줍니다.
`FilterChainProxy`는 Bean이기 때문에 일반적으로 `DelegatingFilterProxy`로 감싸져 사용됩니다.

아래 이미지는 `FilterChainProxy`의 역할을 보여줍니다.

![그림 3. FilterChainProxy](/assets/images/spring/spring-security/image-2.png)

### SecurityFilterChain

`SecurityFilterChain`은 `FilterChainProxy`에서 사용되어, 현재 요청에 대해 호출해야 할 `Spring Security Filter`
인스턴스를 결정합니다.

아래 이미지는 `SecurityFilterChain`의 역할을 보여줍니다.

![그림 4. SecurityFilterChain](/assets/images/spring/spring-security/image-3.png)

`SecurityFilterChain`에 포함된 보안 필터(`Security Filters`)는 일반적으로 Bean으로 정의되지만,
`DelegatingFilterProxy` 대신 `FilterChainProxy`에 등록됩니다. `FilterChainProxy`를 사용하면 Servlet 컨테이너나
`DelegatingFilterProxy`에 직접 등록하는 것보다 여러 가지 이점을 제공합니다.

1. Spring Security의 Servlet 지원의 시작점 제공  
Spring Security의 Servlet 지원 문제를 디버그하려면 `FilterChainProxy`에 디버그 포인트를 추가하는 것이 좋은 시작점입니다.

2. Spring Security 사용의 중심 역할 수행  
`FilterChainProxy`는 선택 사항이 아닌 필수 작업을 수행할 수 있습니다. 예를 들어, 메모리 누수를 방지하기 위해
`SecurityContext`를 정리하거나 특정 유형의 공격으로부터 애플리케이션을 보호하기 위해 Spring Security의
`HttpFirewall`을 적용합니다.  

3. `SecurityFilterChain`의 유연한 호출 결정 제공  
Servlet 컨테이너에서는 `Filter` 인스턴스가 URL을 기반으로 호출됩니다. 그러나 `FilterChainProxy`는
`RequestMatcher` 인터페이스를 사용하여 `HttpServletRequest`의 어떤 요소라도 해당 요소를 기반으로도 
호출 여부를 결정할 수 있습니다.

아래 이미지는 여러 개의 `SecurityFilterChain` 인스턴스를 보여줍니다.

![그림 5. Multiple SecurityFilterChain](/assets/images/spring/spring-security/image-4.png)

`Multiple SecurityFilterChain` 그림에서 `FilterChainProxy`는 어떤 `SecurityFilterChain`을 사용할지 결정합니다.
일치하는 첫 번째 `SecurityFilterChain`만 호출됩니다.

예를 들어, `/api/messages/` URL 요청이 들어오면, 먼저 `/api/**` 패턴과 일치하는 `SecurityFilterChain'0`과 매칭됩니다.
따라서 `SecurityFilterChain0`만 호출되며, 비록 `SecurityFilterChain'n`과도 매칭되더라도 호출되지 않습니다.

반면 `/messages/` URL 요청이 들어오면 `/api/**` 패턴과 일치하지 않으므로 `FilterChainProxy`는 다른
`SecurityFilterChain`들을 계속 시도합니다. 다른 `SecurityFilterChain`과도 매칭되지 않는다고 가정하면,
`SecurityFilterChain'n`이 호출됩니다.

또한 `SecurityFilterChain'0`은 보안 필터(`Security Filter`) 인스턴스가 3개만 설정되어 있는 반면,
`SecurityFilterChain'n`은 4개의 보안 필터가 설정되어 있습니다. 각 `SecurityFilterChain`은 고유하며 독립적으로
구성할 수 있다는 점이 중요합니다. 심지어 애플리케이션에서 특정 요청을 `Spring Security`가 무시하도록
하려면 `SecurityFilterChain`에 보안 필터를 0개로 설정할 수도 있습니다.

### Security Filters

Security Filters는 `SecurityFilterChain` API를 통해 `FilterChainProxy`에 삽입됩니다. 이러한 필터는
익스플로잇 방지(exploit protection), 인증(Authentication), 인가(Authorization) 등 다양한 목적으로 사용될 수 있습니다.
필터들은 특정 순서에 따라 실행되어야 하며, 예를 들어, 인증을 수행하는 필터는 인가를 수행하는 필터보다 먼저 호출되어야 합니다.

Spring Security의 필터 순서를 반드시 알아야 하는 경우는 드물지만, 특정 상황에서 이를 알면 유용할 수 있습니다.
필터 순서를 확인하고 싶다면 `FilterOrderRegistration` 코드를 참고할 수 있습니다.

이 보안 필터들은 주로 `HttpSecurity` 인스턴스를 사용하여 선언됩니다. 이를 설명하기 위해 아래와 같은
보안 구성을 고려해보겠습니다:

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(Customizer.withDefaults())            // 1
            .httpBasic(Customizer.withDefaults())       // 2
            .formLogin(Customizer.withDefaults())       // 2
            .authorizeHttpRequests(authorize -> authorize       // 3
                .anyRequest().authenticated()
            );

        return http.build();
    }
}

@Configuration
@EnableWebFluxSecurity
public class SecurityConfig {

    @Bean
    public SecurityWebFilterChain securityWebFilterChain(ServerHttpSecurity http) {
        http
            .csrf(ServerHttpSecurity.CsrfSpec::disable) // 1: Customize CSRF settings
            .httpBasic(ServerHttpSecurity.HttpBasicSpec::withDefaults) // 2: Enable HTTP Basic authentication
            .formLogin(ServerHttpSecurity.FormLoginSpec::withDefaults) // 2: Enable Form-based authentication
            .authorizeExchange(authorize -> authorize
                .anyExchange().authenticated() // 3: All requests require authentication
            );

        return http.build();
    }
}

```

The above configuration will result in the following Filter ordering:

| Filter                               | Added by                           |
| ------------------------------------ | ---------------------------------- |
| CsrfFilter                           | HttpSecurity#csrf                  |
| UsernamePasswordAuthenticationFilter | HttpSecurity#formLogin             |
| BasicAuthenticationFilter            | HttpSecurity#httpBasic             |
| AuthorizationFilter                  | HttpSecurity#authorizeHttpRequests |

1. `CsrfFilter`가 호출되어 CSRF 공격으로부터 보호합니다.
2. 그 다음으로, `Authentication Filter`가 호출되어 요청을 인증합니다.
3. 마지막으로, `AuthorizationFilter`가 호출되어 요청을 인가합니다.

#### Printing the Security Filters

특정 요청에 대해 호출되는 보안 필터(Security Filters) 목록을 확인하는 것은 종종 유용합니다.
예를 들어, 추가한 필터가 보안 필터 목록에 포함되었는지 확인하고 싶을 수 있습니다.

보안 필터 목록은 애플리케이션이 시작될 때 DEBUG 레벨에서 출력되므로, 콘솔에서 다음과 같은 내용을 확인할 수 있습니다:

```log
2023-06-14T08:55:22.321-03:00  DEBUG 76975 --- [           main] o.s.s.web.DefaultSecurityFilterChain     : Will secure any request with [ DisableEncodeUrlFilter, WebAsyncManagerIntegrationFilter, SecurityContextHolderFilter, HeaderWriterFilter, CsrfFilter, LogoutFilter, UsernamePasswordAuthenticationFilter, DefaultLoginPageGeneratingFilter, DefaultLogoutPageGeneratingFilter, BasicAuthenticationFilter, RequestCacheAwareFilter, SecurityContextHolderAwareRequestFilter, AnonymousAuthenticationFilter, ExceptionTranslationFilter, AuthorizationFilter]
```

이 정보는 각 필터 체인에 구성된 보안 필터를 이해하는 데 매우 유용합니다.

뿐만 아니라, 애플리케이션이 각 요청마다 개별 필터가 호출되는 것을 기록하도록 설정할 수도 있습니다.
이는 특정 요청에 대해 추가한 필터가 호출되는지 확인하거나, 예외가 어디에서 발생하는지 확인하는 데 도움이 됩니다.
이를 위해 보안 이벤트를 기록하도록 애플리케이션을 설정할 수 있습니다.  
`Log The Security Events` 절에서 설정 방법 확인.

#### Addding Filters to the Filter Chain

대부분의 경우, 기본 제공되는 보안 필터만으로 애플리케이션 보안에 충분합니다.
하지만 커스텀 필터를 `SecurityFilterChain`에 추가해야 할 때도 있습니다.

`HttpSecurity`, `ServerHttpSecurity`는 필터를 추가하기 위한 세 가지 메서드를 제공합니다:

1. `#addFilterBefore(Filter, Class<?>)` 다른 필터 앞에 필터를 추가합니다.  
2. `#addFilterAfter(Filter, Class<?>)` 다른 필터 뒤에 필터를 추가합니다.  
3. `#addFilterAt(Filter, Class<?>)` 다른 필터를 대체하여 필터를 추가합니다.

**커스텀 필터 추가하기**  

자체 필터를 생성하는 경우, 필터 체인에서 해당 필터의 위치를 결정해야 합니다.
필터 체인에서 발생하는 주요 이벤트는 다음과 같습니다:

1. `SecurityContext`가 세션에서 로드됩니다.
2. 공통적인 익스플로잇(CSRF, CORS 등)으로부터 요청이 보호됩니다.
3. 요청이 인증(authenticated)됩니다.
4. 요청이 인가(authorized)됩니다.

필터의 위치를 결정하기 위해 필요한 이벤트를 고려하세요. 아래는 일반적인 가이드라인입니다:

|---|---|---|
|If your filter is a(n)|Then place it after|As these events have already occurred|
|exploit protection filter|SecurityContextHolderFilter|1|
|authentication filter|LogoutFilter|1, 2|
|authorization filter|AnonymousAuthenticationFilter|1, 2, 3|

> 대부분의 경우, 애플리케이션은 커스텀 인증을 추가합니다. 이러한 경우, 필터는 LogoutFilter 뒤에 배치되어야 합니다.  

예를 들어, 특정 테넌트 ID(Tenant ID) 헤더를 가져오고 현재 사용자가 해당 테넌트에 접근 권한이 있는지 확인하는
필터를 추가하고 싶다고 가정해봅시다.

먼저, 필터를 생성합니다:

```java
import java.io.IOException;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import org.springframework.security.access.AccessDeniedException;

public class TenantFilter implements Filter {

    @Override
    public void doFilter(ServletRequest servletRequest, ServletResponse servletResponse, FilterChain filterChain) throws IOException, ServletException {
        HttpServletRequest request = (HttpServletRequest) servletRequest;
        HttpServletResponse response = (HttpServletResponse) servletResponse;

        String tenantId = request.getHeader("X-Tenant-Id");         // (1)
        boolean hasAccess = isUserAllowed(tenantId);                // (2)
        if (hasAccess) {
            filterChain.doFilter(request, response);                // (3)
            return;
        }
        throw new AccessDeniedException("Access denied");           // (4)
    }
}
```

위 샘플 코드는 다음 작업을 수행합니다:

1. 요청 헤더에서 테넌트 ID를 가져옵니다.
2. 현재 사용자가 해당 테넌트 ID에 접근할 수 있는지 확인합니다.
3. 사용자가 접근 권한이 있다면, 필터 체인의 나머지 필터들을 호출합니다.
4. 사용자가 접근 권한이 없다면, `AccessDeniedException`을 발생시킵니다.

`Filter`를 직접 구현하는 대신, 요청당 한 번만 호출되는 필터를 위한 기본 클래스인 `OncePerRequestFilter`를 확장할 수 있습니다.
이 클래스는 `HttpServletRequest`와 `HttpServletResponse` 매개변수를 사용하는 `doFilterInternal` 메서드를 제공합니다.

이제 이 필터를 `SecurityFilterChain`에 추가해야 합니다. 앞서 설명된 내용을 기반으로 필터를 추가할 위치를 정할 수 있습니다.
현재 사용자를 알아야 하므로, 필터는 인증 필터(Authentication Filters) 뒤에 추가해야 합니다.

규칙에 따라, 필터를 체인의 마지막 인증 필터인 `AnonymousAuthenticationFilter` 뒤에 추가합니다. 다음과 같이 구성할 수 있습니다:

```java
@Bean
SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
    http
        // ...
        .addFilterAfter(new TenantFilter(), AnonymousAuthenticationFilter.class); // 1
    return http.build();
}
```

`HttpSecurity#addFilterAfter`를 사용하여 `TenantFilter`를 `AnonymousAuthenticationFilter` 뒤에 추가합니다.
`AnonymousAuthenticationFilter` 뒤에 필터를 추가함으로써, `TenantFilter`가 인증 필터들이 실행된 이후에 호출되도록 보장합니다.

이제 `TenantFilter`는 필터 체인에서 호출되어 현재 사용자가 해당 `테넌트 ID`에 접근할 수 있는지 확인합니다.

**Declaring Your Filter as a Bean**  

필터를 Spring Bean으로 선언할 경우, `@Component`로 어노테이션을 추가하거나 설정에서 `Bean`으로 선언하면 됩니다.
이 경우, Spring Boot는 자동으로 필터를 임베디드 컨테이너에 등록합니다.
하지만 이렇게 하면 필터가 두 번 호출되는 문제가 발생할 수 있습니다.

1. 한 번은 컨테이너에서 호출  
2. 한 번은 Spring Security에서 호출 (그리고 호출 순서도 달라질 수 있음)  

이 문제 때문에, 필터는 일반적으로 Spring Bean으로 선언되지 않습니다.

하지만, 필터가 Spring Bean이어야 하는 경우(예: 의존성 주입을 사용해야 하는 경우), 필터를 컨테이너에
등록하지 않도록 `FilterRegistrationBean`을 선언하고 `enabled` 속성을 `false`로 설정할 수 있습니다:

```java
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class FilterConfig {

    @Bean
    public FilterRegistrationBean<TenantFilter> tenantFilterRegistration(TenantFilter tenantFilter) {
        FilterRegistrationBean<TenantFilter> registrationBean = new FilterRegistrationBean<>(tenantFilter);
        registrationBean.setEnabled(false); // 컨테이너에 등록되지 않도록 설정
        return registrationBean;
    }
}
```

이 설정을 통해 필터는 Spring Bean으로 선언되지만, 컨테이너에 등록되지 않아 호출 순서 문제를 방지할 수 있습니다.

**Customizing a Spring Security Filter**  

일반적으로 Spring Security의 필터를 구성할 때는 필터의 DSL 메서드를 사용하는 것이 좋습니다.
예를 들어, `BasicAuthenticationFilter`를 추가하는 가장 간단한 방법은 DSL을 통해 추가하는 것입니다:

```java
@Bean
SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
	http
		.httpBasic(Customizer.withDefaults())
        // ...

	return http.build();
}
```

하지만, Spring Security 필터를 직접 생성해야 하는 경우, addFilterAt을 사용하여 DSL에서 명시적으로 필터를 추가할 수 있습니다:

```java
@Bean
SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
	BasicAuthenticationFilter basic = new BasicAuthenticationFilter();
	// ... 필터 구성

	http
		// ...
		.addFilterAt(basic, BasicAuthenticationFilter.class);

	return http.build();
}
```

중요한 점

해당 필터가 이미 추가되어 있다면, Spring Security는 예외를 발생시킵니다.
예를 들어, `HttpSecurity#httpBasic`을 호출하면 Spring Security가 자동으로 `BasicAuthenticationFilter`를 추가합니다.
따라서 다음과 같은 구성이 실패합니다. 이유는 두 번의 호출이 모두 `BasicAuthenticationFilter`를 추가하려고 시도하기 때문입니다:

```java
@Bean
SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
	BasicAuthenticationFilter basic = new BasicAuthenticationFilter();
	// ... 필터 구성

	http
		.httpBasic(Customizer.withDefaults())
		// ... 오류 발생! BasicAuthenticationFilter가 두 번 추가됩니다.
		.addFilterAt(basic, BasicAuthenticationFilter.class);

	return http.build();
}
```

이 경우, 직접 `BasicAuthenticationFilter`를 구성했으므로 `httpBasic` 호출을 제거해야 합니다.

> 필터 비활성화
> HttpSecurity를 재구성하여 특정 필터를 추가하지 못하는 경우, 해당 Spring Security 필터를 비활성화할 수 있습니다.
> 이를 위해 DSL의 disable 메서드를 호출하면 됩니다:
> `.httpBasic((basic) -> basic.disable())`

### Handling Security Exceptions

`ExceptionTranslationFilter`는 `AccessDeniedException`과 `AuthenticationException`을 HTTP 응답으로 변환할 수 있도록 도와줍니다.
`ExceptionTranslationFilter`는 `FilterChainProxy`에 보안 필터(Security Filters) 중 하나로 삽입됩니다.

아래는 `ExceptionTranslationFilter`와 다른 구성 요소 간의 관계를 설명한 내용입니다:

![그림 6. Handling Security Exceptions](/assets/images/spring/spring-security/image-5.png)

동작 과정

1 `ExceptionTranslationFilter`는 `FilterChain.doFilter(request, response)`를 호출하여
애플리케이션의 나머지 부분을 실행합니다.  
2 사용자가 인증되지 않았거나(AuthenticationException) `AuthenticationException`이 발생한 경우 Start Authentication이 진행됩니다.  
    - `SecurityContextHolder`가 비워집니다.  
    - `HttpServletRequest`가 저장되어 인증 성공 후 원래 요청을 다시 실행할 수 있도록 합니다.  
    - `AuthenticationEntryPoint`를 사용하여 클라이언트로부터 자격 증명을 요청합니다. 예를 들어, 로그인 페이지로 리디렉션하거나 WWW-Authenticate 헤더를 전송할 수 있습니다.
3 `AccessDeniedException`인 경우
    - `Access Denied`가 처리됩니다.
    - `AccessDeniedHandler`가 호출되어 접근 거부 상황을 처리합니다.

참고 사항

* `ExceptionTranslationFilter`는 인증 실패와 접근 거부를 처리하기 위해 각각 `AuthenticationEntryPoint`와 `AccessDeniedHandler`를 활용합니다.
* 인증이 성공하면 원래 요청을 재실행하여 애플리케이션이 정상적으로 동작하도록 지원합니다.  

> 애플리케이션이 `AccessDeniedException` 또는 `AuthenticationException`을 발생시키지 않으면,
> `ExceptionTranslationFilter`는 아무 작업도 수행하지 않습니다.

ExceptionTranslationFilter pseudocode

```java
try {
	filterChain.doFilter(request, response); // 1
} catch (AccessDeniedException | AuthenticationException ex) {
	if (!authenticated || ex instanceof AuthenticationException) {
		startAuthentication(); // 2
	} else {
		accessDenied();  // 3
	}
}
```

* `FilterChain.doFilter(request, response)`를 호출하는 것은 애플리케이션의 나머지 부분을 호출하는 것과 같습니다. 따라서 애플리케이션의 다른 부분(예: `FilterSecurityInterceptor` 또는 메서드 보안)에서 `AuthenticationException` 또는 `AccessDeniedException`을 발생시키면 이 필터에서 예외를 포착하여 처리합니다.
* 사용자가 인증되지 않았거나 `AuthenticationException`인 경우: Start Authentication을 진행합니다.
* 그 외의 경우: Access Denied를 처리합니다.

### Saving Requests Between Authentication

`Handling Security Exceptions`에서 설명한 것처럼, 인증이 없는 상태에서 인증이 필요한 리소스에 대한 요청이 들어오면,
인증 성공 후 해당 요청을 다시 시도하기 위해 요청을 저장해야 합니다. Spring Security에서는 `RequestCache` 구현을 사용하여 `HttpServletRequest`를 저장합니다.

**RequestCache**  

* `HttpServletRequest`는 `RequestCache`에 저장됩니다.  
* 사용자가 인증에 성공하면, `RequestCache`를 사용하여 원래 요청을 재실행합니다.  
* `RequestCacheAwareFilter`는 사용자가 인증한 후 `RequestCache`를 사용하여 저장된 `HttpServletRequest`를 가져옵니다.  
* `ExceptionTranslationFilter`는 `AuthenticationException`을 감지한 후 사용자를 로그인 엔드포인트로 리디렉션하기 전에 `HttpServletRequest`를 저장합니다.

기본 동작

* 기본적으로 `HttpSessionRequestCache`가 사용됩니다.
* 아래 코드는 continue라는 매개변수가 있는 경우에만 저장된 요청을 확인하도록 `RequestCache` 구현을 사용자 정의하는 방법을 보여줍니다.

*RequestCache가 저장된 요청을 확인하는 경우: continue 매개변수 존재 시*  

```java
@Bean
DefaultSecurityFilterChain springSecurity(HttpSecurity http) throws Exception {
	HttpSessionRequestCache requestCache = new HttpSessionRequestCache();
	requestCache.setMatchingRequestParameterName("continue");
	http
		// ...
		.requestCache((cache) -> cache
			.requestCache(requestCache)
		);
	return http.build();
}
```

**Prevent the Request From Being Saved : 요청이 저장되지 않도록 방지하기**
사용자의 인증되지 않은 요청을 세션에 저장하지 않아야 하는 여러 가지 이유가 있을 수 있습니다.

* 예를 들어, 해당 데이터를 사용자의 브라우저로 저장하거나 데이터베이스에 저장하고 싶을 수 있습니다.
* 또는, 로그인 전 사용자가 방문하려던 페이지로 리디렉션하지 않고 항상 홈 페이지로 리디렉션하도록 이 기능을 비활성화하고 싶을 수도 있습니다.

이 경우 `NullRequestCache` 구현을 사용할 수 있습니다.

*요청 저장 방지하기*  

```java
@Bean
SecurityFilterChain springSecurity(HttpSecurity http) throws Exception {
    RequestCache nullRequestCache = new NullRequestCache();
    http
        // ...
        .requestCache((cache) -> cache
            .requestCache(nullRequestCache)
        );
    return http.build();
}
```

**RequestCacheAwareFilter**  
`RequestCacheAwareFilter`는 `RequestCache`를 사용하여 원래 요청을 재실행합니다.

### Logging

Spring Security는 `DEBUG` 및 `TRACE` 수준에서 모든 보안 관련 이벤트에 대한 포괄적인 로그를 제공합니다.
이는 애플리케이션을 디버깅할 때 매우 유용합니다.
보안상의 이유로 Spring Security는 요청이 거부된 이유에 대한 세부 정보를 응답 본문에 추가하지 않기 때문입니다.

예를 들어, 401 또는 403 오류가 발생하면, 로그 메시지를 통해 상황을 이해하는 데 도움이 될 수 있습니다.

예: CSRF 토큰 없이 POST 요청

* 사용자가 `CSRF 보호가 활성화`된 리소스에 CSRF 토큰 없이 POST 요청을 보냈다고 가정해봅시다.
* 로그가 없는 경우 사용자는 403 오류를 보고 요청이 거부된 이유를 알 수 없습니다.
* 하지만 Spring Security의 로그를 활성화하면 다음과 같은 로그 메시지를 확인할 수 있습니다:

로그 메시지 예시:

```log
2023-06-14T09:44:25.797-03:00 DEBUG 76975 --- [nio-8080-exec-1] o.s.security.web.FilterChainProxy        : Securing POST /hello
2023-06-14T09:44:25.797-03:00 TRACE 76975 --- [nio-8080-exec-1] o.s.security.web.FilterChainProxy        : Invoking DisableEncodeUrlFilter (1/15)
2023-06-14T09:44:25.798-03:00 TRACE 76975 --- [nio-8080-exec-1] o.s.security.web.FilterChainProxy        : Invoking WebAsyncManagerIntegrationFilter (2/15)
2023-06-14T09:44:25.800-03:00 TRACE 76975 --- [nio-8080-exec-1] o.s.security.web.FilterChainProxy        : Invoking SecurityContextHolderFilter (3/15)
2023-06-14T09:44:25.801-03:00 TRACE 76975 --- [nio-8080-exec-1] o.s.security.web.FilterChainProxy        : Invoking HeaderWriterFilter (4/15)
2023-06-14T09:44:25.802-03:00 TRACE 76975 --- [nio-8080-exec-1] o.s.security.web.FilterChainProxy        : Invoking CsrfFilter (5/15)
2023-06-14T09:44:25.814-03:00 DEBUG 76975 --- [nio-8080-exec-1] o.s.security.web.csrf.CsrfFilter         : Invalid CSRF token found for http://localhost:8080/hello
2023-06-14T09:44:25.814-03:00 DEBUG 76975 --- [nio-8080-exec-1] o.s.s.w.access.AccessDeniedHandlerImpl   : Responding with 403 status code
2023-06-14T09:44:25.814-03:00 TRACE 76975 --- [nio-8080-exec-1] o.s.s.w.header.writers.HstsHeaderWriter  : Not injecting HSTS header since it did not match request to [Is Secure]
```

> 이 로그를 통해 CSRF 토큰이 누락되어 요청이 거부되었음을 알 수 있습니다.

**애플리케이션에 보안 이벤트 로그 활성화**  
Spring Security의 모든 보안 이벤트를 로그로 기록하려면, 다음과 같이 로그 설정을 추가합니다:

*application.properties* 로그 레벨 설정  

```yaml
logging.level.org.springframework.security=TRACE
```

*logback.xml* 로그 output 설정  

```xml
<configuration>
    <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
        <!-- ... -->
    </appender>
    <!-- ... -->
    <logger name="org.springframework.security" level="trace" additivity="false">
        <appender-ref ref="Console" />
    </logger>
</configuration>
```

위 설정은 보안 이벤트에 대한 세부 정보를 콘솔에 기록하여 디버깅 과정을 지원합니다.  

## Authentication

### Servlet Authentication Architecture

이 논의는 `Servlet Security: The Big Picture`를 확장하여 Spring Security에서 Servlet 인증에 사용되는
주요 아키텍처 구성 요소를 설명합니다. 각 구성 요소가 어떻게 연결되는지에 대한 구체적인 흐름은
`Authentication Mechanism`에 대한 섹션을 참조하세요.

주요 아키텍처 구성 요소

1. SecurityContextHolder : Spring Security가 인증된 사용자의 세부 정보를 저장하는 핵심 장소입니다.  
2. SecurityContext : SecurityContextHolder에서 가져오며, 현재 인증된 사용자의 Authentication 정보를 포함합니다.  
3. Authentication  
    * 인증 관리자인 AuthenticationManager에 사용자 자격 증명을 제공하여 인증을 시도하는 입력값일 수 있습니다.
    * 또는, SecurityContext에서 가져온 현재 사용자 정보일 수도 있습니다.
4. GrantedAuthority : 인증된 사용자(Principal)에게 부여된 권한(예: 역할, 스코프 등)을 나타냅니다.  
5. AuthenticationManager : Spring Security의 필터가 인증을 수행하는 방법을 정의하는 API입니다.  
6. ProviderManager : AuthenticationManager의 가장 일반적인 구현체입니다.  
7. AuthenticationProvider : ProviderManager에서 특정 유형의 인증을 수행하기 위해 사용됩니다.  
8. Request Credentials with AuthenticationEntryPoint : 클라이언트에게 자격 증명을 요청하기 위해 사용됩니다(예: 로그인 페이지로 리디렉션하거나 WWW-Authenticate 응답 전송).  
9. AbstractAuthenticationProcessingFilter : 인증을 위한 기본 필터입니다. 인증의 상위 흐름과 구성 요소 간의 작동 방식을 이해하는 데 유용합니다.  

#### SecurityContextHolder

Spring Security의 인증 모델의 중심에는 SecurityContextHolder가 있습니다.
이곳에 SecurityContext가 저장됩니다.

![그림 6. SecurityContextHolder](/assets/images/spring/spring-security/image-6.png)

`SecurityContextHolder`는 Spring Security가 인증된 사용자에 대한 세부 정보를 저장하는 곳입니다.
`SecurityContextHolder`가 어떻게 채워지는지는 Spring Security가 신경 쓰지 않습니다.
단, 값이 있으면 이를 현재 인증된 사용자로 간주합니다.

*SecurityContextHolder* 설정하기

```java
SecurityContext context = SecurityContextHolder.createEmptyContext();  // 1
Authentication authentication =
    new TestingAuthenticationToken("username", "password", "ROLE_USER");  // 2
context.setAuthentication(authentication);

SecurityContextHolder.setContext(context); // 3
```

설명 

1. 새 `SecurityContext` 인스턴스를 생성합니다.`SecurityContextHolder.getContext().setAuthentication(authentication)`를 사용하는 대신, 새 `SecurityContext`를 생성해야 여러 스레드에서 발생할 수 있는 경쟁 상태를 방지할 수 있습니다.  
2. 새 `Authentication` 객체 생성. Spring Security는 `SecurityContext`에 어떤 유형의 `Authentication` 구현이 설정되는지에 대해 제한하지 않습니다. 위 예제에서는 간단하게 `TestingAuthenticationToken`을 사용했으며, 실제 환경에서는 주로 `UsernamePasswordAuthenticationToken(userDetails, password, authorities)`를 사용합니다.  
3. `SecurityContextHolder`에 `SecurityContext` 설정. Spring Security는 이 정보를 사용하여 권한 부여를 처리합니다.  

현재 인증된 사용자 정보 얻기

```java
SecurityContext context = SecurityContextHolder.getContext();
Authentication authentication = context.getAuthentication();
String username = authentication.getName();
Object principal = authentication.getPrincipal();
Collection<? extends GrantedAuthority> authorities = authentication.getAuthorities();
```

*설명*  

* `SecurityContextHolder.getContext()`를 통해 `SecurityContext`를 가져옵니다.
* `Authentication` 객체에서 현재 인증된 사용자 정보를 얻을 수 있습니다  
  * getName(): 사용자 이름
  * getPrincipal(): 주체(Principal) 정보
  * getAuthorities(): 부여된 권한 목록  

* `ThreadLocal` 을 사용하는 기본 동작  
  * 기본적으로 `SecurityContextHolder`는 `ThreadLocal`을 사용하여 세부 정보를 저장합니다.  
  * 이는 `SecurityContext`가 명시적으로 메서드에 전달되지 않아도 같은 스레드의 모든 메서드에서 항상 사용할 수 있음을 의미합니다.  
  * Spring Security의 `FilterChainProxy`는 요청 처리가 완료되면 항상 `SecurityContext`를 정리하여 안전성을 보장합니다.  

* `ThreadLocal` 사용이 적합하지 않은 경우
  * 일부 애플리케이션은 특정 스레드 작업 방식 때문에 `ThreadLocal` 사용이 적합하지 않을 수 있습니다.  
  *예제*  
    * Swing 클라이언트: Java Virtual Machine의 모든 스레드가 동일한 보안 컨텍스트를 사용해야 할 경우
      `SecurityContextHolder.MODE_GLOBAL` 사용
    * 스레드에서 파생된 하위 스레드: 보안 스레드에서 생성된 하위 스레드가 동일한 보안 ID를 가져야 할 경우
      `SecurityContextHolder.MODE_INHERITABLETHREADLOCAL` 사용

* `ThreadLocal` 전략 변경하기  
  기본값인 `SecurityContextHolder.MODE_THREADLOCAL`에서 다른 모드로 변경하려면 두 가지 방법이 있습니다:

  1. 시스템 속성 설정  
    애플리케이션 시작 시 시스템 속성을 통해 설정합니다.  
  2. 정적 메서드 호출  
    SecurityContextHolder의 정적 메서드를 호출하여 설정합니다.

대부분의 애플리케이션은 기본값을 변경할 필요가 없습니다. 변경이 필요한 경우,
`SecurityContextHolder`의 JavaDoc을 참조하여 자세한 내용을 확인하세요.

#### SecurityContext

SecurityContextHolder에서 SecurityContext를 가져온다. SecurityContext는 Authentication객체를 포함한다.

#### Authentication

`Authentication` 인터페이스는 Spring Security에서 두 가지 주요 역할을 수행합니다:

1. AuthenticationManager의 입력으로 사용  
  사용자가 인증을 위해 제공한 자격 증명(credentials)을 전달합니다. 이 경우, `isAuthenticated()` 메서드는 `false`를 반환합니다.  
2. 현재 인증된 사용자 표현  
  `SecurityContext`에서 현재 `Authentication` 객체를 가져올 수 있습니다.  

Authentication이 포함하는 정보:

* principal  
  사용자를 식별합니다.
  일반적으로 사용자 이름과 비밀번호를 사용하는 인증에서는 `UserDetails`의 인스턴스입니다.
* credentials  
  보통 사용자의 비밀번호를 나타냅니다. 인증 후 이 정보는 누출 방지를 위해 삭제되는 경우가 많습니다.  
* authorities
  사용자가 부여받은 고수준 권한을 나타내는 `GrantedAuthority` 인스턴스입니다.  
  예: 역할(roles), 스코프(scopes).  

#### GrantedAuthority

`GrantedAuthority`는 사용자가 부여받은 고수준 권한을 나타냅니다. 예: 역할(roles), 스코프(scopes).  

* `Authentication.getAuthorities()` 메서드를 통해 `GrantedAuthority` 인스턴스를 얻을 수 있습니다.
* 이 메서드는 `GrantedAuthority` 객체의 컬렉션을 반환합니다.

*권한의 일반적인 형태:*  

* `ROLE_ADMINISTRATOR`, `ROLE_HR_SUPERVISOR` 등과 같은 '역할'이 주로 사용됩니다.  
* 이러한 역할은 웹 권한, 메서드 권한, 도메인 객체 권한에서 구성됩니다.
* Spring Security의 다른 구성 요소들은 이 권한을 해석하고 사용자가 해당 권한을 갖고 있기를 기대합니다.

*사용자 이름/비밀번호 기반 인증:*  

* `GrantedAuthority` 객체는 주로 `UserDetailsService`를 통해 로드됩니다.  

*도메인 객체에 특정되지 않음:*  

* `GrantedAuthority`는 애플리케이션 전반에 걸친 권한을 나타냅니다.  
* 특정 도메인 객체에 대한 권한을 나타내지는 않습니다.
* 예를 들어, 특정 Employee 객체 54에 대한 권한을 부여하는 `GrantedAuthority`는 메모리 문제나 성능 저하를 유발할 수 있습니다.
* 이러한 요구 사항은 Spring Security의 도메인 객체 보안 기능을 사용하여 처리해야 합니다.

#### AuthenticationManager

`AuthenticationManager`는 Spring Security의 필터들이 인증을 수행하는 방식을 정의하는 API입니다.

* 인증된 `Authentication` 객체는 이를 호출한 컨트롤러(주로 Spring Security의 필터 인스턴스)에 의해 `SecurityContextHolder`에 설정됩니다.
* Spring Security의 필터를 사용하지 않는 경우, `AuthenticationManager`를 반드시 사용할 필요는 없으며 `SecurityContextHolder`를 직접 설정할 수도 있습니다.

*일반적인 구현:*  
가장 일반적인 구현은 `ProviderManager`입니다.

#### ProviderManager

`ProviderManager`는 `AuthenticationManager`의 가장 일반적인 구현체입니다.
`ProviderManager`는 `AuthenticationProvider` 인스턴스의 리스트에 위임합니다.

*동작 방식:*  

1. 각 `AuthenticationProvider`는 인증을 성공 또는 실패로 처리하거나, 판단을 내리지 않고 다음
  `AuthenticationProvider`에 위임할 수 있습니다.
2. 구성된 `AuthenticationProvider` 중 어느 것도 인증을 수행하지 못하면, 인증은
  `ProviderNotFoundException`과 함께 실패합니다. `ProviderNotFoundException`은 특별한
  `AuthenticationException`으로, `ProviderManager`가 전달된 `Authentication`유형을 지원하도록
  구성되지 않았음을 나타냅니다.

![그림 8. ProviderManager](/assets/images/spring/spring-security/image-7.png)

실제 사용 사례

각 `AuthenticationProvider`는 특정 유형의 인증을 수행하는 방법을 알고 있습니다.
예를 들어:

* 하나의 `AuthenticationProvider`는 사용자 이름/비밀번호를 검증할 수 있습니다.
* 다른 하나는 `SAML assertion`을 인증할 수 있습니다.

이러한 방식으로 각 `AuthenticationProvider`는 특정 유형의 인증에만 집중하면서,
여러 인증 유형을 지원할 수 있으며, 단일 `AuthenticationManager` 빈만 노출합니다.

`ProviderManager`의 부모 `AuthenticationManager`  
`ProviderManager`는 선택적으로 부모 `AuthenticationManager`를 구성할 수 있습니다.

* 모든 `AuthenticationProvider`가 인증을 수행하지 못한 경우, 부모 `AuthenticationManager`가 호출됩니다.
* 부모는 어떤 유형의 `AuthenticationManager`도 될 수 있지만, 일반적으로 `ProviderManager`의 인스턴스입니다.

![그림 9. ProviderManager Parent](/assets/images/spring/spring-security/image-8.png)

*Shared Parent AuthenticationManager*  

* 여러 `ProviderManager` 인스턴스가 동일한 부모 `AuthenticationManager`를 공유할 수 있습니다.  
* 이는 다음과 같은 시나리오에서 흔히 사용됩니다:  
* 여러 `SecurityFilterChain` 인스턴스가 공통의 인증 메커니즘(`Shared Parent AuthenticationManager`)과
  서로 다른 인증 메커니즘(개별 `ProviderManager`)을 사용하는 경우.

![그림 10. Shared Parent AuthenticationManager](/assets/images/spring/spring-security/image-9.png)

*기본 동작: 자격 증명 정보 삭제*  
기본적으로 `ProviderManager`는 인증 요청이 성공적으로 처리된 후 반환되는 `Authentication` 객체에서
민감한 자격 증명 정보를 삭제하려고 시도합니다.
*이는 비밀번호와 같은 정보가 HttpSession에 불필요하게 오래 유지되지 않도록 방지합니다.*  

`CredentialsContainer` 인터페이스  
`CredentialsContainer` 인터페이스는 인증 프로세스에서 중요한 역할을 합니다.
필요하지 않게 된 자격 증명 정보를 삭제할 수 있도록 하여 민감한 데이터가 오래 유지되지 않도록 보안을 강화합니다.

*캐시 사용 시 주의사항*  
예를 들어, 무상태 애플리케이션에서 성능을 개선하기 위해 사용자 객체를 캐시에 저장하는 경우 문제가 발생할 수 있습니다.
인증된 `Authentication` 객체가 캐시에 있는 객체(예: UserDetails 인스턴스)를 참조하고, 자격 증명이 삭제되면 해당 캐시 값을 기반으로 인증을 수행할 수 없게 됩니다.

*해결 방법*  

1. 객체 복사  
  캐시 구현 또는 `Authentication` 객체를 생성하는 `AuthenticationProvider`에서 객체를 복사한 후 사용합니다.  
2. `eraseCredentialsAfterAuthentication` 비활성화  
  `ProviderManager`의 `eraseCredentialsAfterAuthentication` 속성을 비활성화합니다.  
  이 설정에 대한 자세한 내용은 ProviderManager 클래스의 JavaDoc을 참조하세요.  

#### AuthenticationProvider

`ProviderManager`에 여러 `AuthenticationProvider` 인스턴스를 주입할 수 있습니다.
각 AuthenticationProvider는 특정 유형의 인증을 수행합니다.  
예:

* `DaoAuthenticationProvider`는 사용자 이름/비밀번호 기반 인증을 지원합니다.  
* `JwtAuthenticationProvider`는 JWT 토큰 인증을 지원합니다.  

**Request Credentials with AuthenticationEntryPoint**  

`AuthenticationEntryPoint`를 통한 자격 증명 요청

`AuthenticationEntryPoint`는 클라이언트로부터 자격 증명을 요청하는 HTTP 응답을 보내는 데 사용됩니다.

1. 클라이언트가 자격 증명을 포함하는 경우  
  클라이언트가 자격 증명(예: 사용자 이름 및 비밀번호)을 포함하여 리소스를 요청하는 경우, Spring Security는
  클라이언트에 자격 증명을 요청할 필요가 없습니다.  
2. 클라이언트가 인증되지 않은 요청을 보낸 경우  
  클라이언트가 인증되지 않은 상태로 접근 권한이 없는 리소스를 요청하면, `AuthenticationEntryPoint` 구현체가
  자격 증명을 요청합니다. 이때 `AuthenticationEntryPoint` 구현체는 다음 작업을 수행할 수 있습니다:
    * 로그인 페이지로 리디렉션
    * WWW-Authenticate 헤더를 포함한 응답
    * 기타 사용자 정의 동작

**AbstractAuthenticationProcessingFilter**  

`AbstractAuthenticationProcessingFilter`는 사용자의 자격 증명을 인증하기 위한 기본 필터로 사용됩니다.
자격 증명을 인증하기 전에, Spring Security는 일반적으로 `AuthenticationEntryPoint`를 사용하여 자격 증명을 요청합니다.
이후, `AbstractAuthenticationProcessingFilter`는 제출된 인증 요청을 처리하고 인증을 수행합니다.

![그림 11. AbstractAuthenticationProcessingFilter](/assets/images/spring/spring-security/image-10.png)

동작 흐름:

1. 사용자가 자격 증명을 제출하면  
  `AbstractAuthenticationProcessingFilter`는 `HttpServletRequest`에서 인증을 위한 `Authentication` 객체를 생성합니다.  
  생성되는 `Authentication` 객체의 유형은 `AbstractAuthenticationProcessingFilter`의 서브클래스에 따라 다릅니다.
  예: `UsernamePasswordAuthenticationFilter`는 사용자 이름과 비밀번호를 기반으로
  `UsernamePasswordAuthenticationToken`을 생성합니다.  
2. `AuthenticationManager`에 인증 요청 전달  
  생성된 `Authentication` 객체는 `AuthenticationManager`로 전달되어 인증됩니다.  
3. 인증 실패 시 처리  
    * 실패(Failure)  `SecurityContextHolder`가 비워집니다.  
    * `RememberMeServices.loginFail`이 호출됩니다. (Remember Me가 구성되지 않은 경우 이 작업은 무시됩니다.)  
    * `AuthenticationFailureHandler`가 호출됩니다. (자세한 내용은 `AuthenticationFailureHandler` 인터페이스 참조.)  
4. 인증 성공 시 처리  
    * 성공(Success): `SessionAuthenticationStrategy`가 새로운 로그인 이벤트를 알립니다.
      (자세한 내용은 SessionAuthenticationStrategy 인터페이스 참조.)  
    * 인증된 `Authentication` 객체가 `SecurityContextHolder`에 설정됩니다.  
      이후 요청에서 `SecurityContext`를 자동으로 설정하려면 `SecurityContextRepository#saveContext`를
      명시적으로 호출해야 합니다. (자세한 내용은 `SecurityContextHolderFilter` 클래스 참조.)  
    * `RememberMeServices.loginSuccess`가 호출됩니다. (Remember Me가 구성되지 않은 경우 이 작업은 무시됩니다.)  
    * `InteractiveAuthenticationSuccessEvent` 이벤트가 `ApplicationEventPublisher`에 의해 게시됩니다.  
    * `AuthenticationSuccessHandler`가 호출됩니다. (자세한 내용은 AuthenticationSuccessHandler 인터페이스 참조.)  
