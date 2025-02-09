---
layout: post
title: spring cloud gatgeway 02
author: jblim0125
date: 2024-06-29
category: 2024
---

## Spring Cloud Gateway

'Spring Cloud Gateway - 01' 에서 기본적인 기능에 대해서 확인하고  
구현을 진행하는 과정에서 추가로 확인한 내용을 작성하며 기억해두려고 한다.  

## How It Works

![diagram](/assets/images/gateway/spring-gateway-diagram.png)

1. Client  
2. HttpWebHandlerAdapter  
3. DispatcherHandler  
4. RoutePredicateHandlerMapping  
5. FilteringWebHandler(Gateway Filter Chain)  

[출처](https://dlsrb6342.github.io/2019/05/14/spring-cloud-gateway-%EA%B5%AC%EC%A1%B0/)

### HttpWebHandlerAdapter

`org.springframework.web.server.adapter.HttpWebHandlerAdapter`

ReactorHttpHandlerAdapter로부터 받은 ReactorServerRequest / ReactorServerResponse를
ServerWebExchange로 만들어 DispatcherHandler에게 넘겨준다.

```java
public Mono<Void> handle(ServerHttpRequest request, ServerHttpResponse response) {
    ...
    ServerWebExchange exchange = this.createExchange(request, response);
    ...
}
```

### DispatcherHandler

* 멤버변수  
Request 처리 Handler  
HandlerMapping, HandlerAdapter, HandlerResultHandler  

    ```java
    @Nullable
    private List<HandlerMapping> handlerMappings;
    @Nullable
    private List<HandlerAdapter> handlerAdapters;
    @Nullable
    private List<HandlerResultHandler> resultHandlers;
    ```

* 멤버변수의 초기화  
Handler는 Application Context에서 컴포넌트를 검색, 정렬

    ```java
     protected void initStrategies(ApplicationContext context) {
        Map<String, HandlerMapping> mappingBeans = BeanFactoryUtils.beansOfTypeIncludingAncestors(context, HandlerMapping.class, true, false);
        ArrayList<HandlerMapping> mappings = new ArrayList(mappingBeans.values());
        AnnotationAwareOrderComparator.sort(mappings);
        this.handlerMappings = Collections.unmodifiableList(mappings);
        Map<String, HandlerAdapter> adapterBeans = BeanFactoryUtils.beansOfTypeIncludingAncestors(context, HandlerAdapter.class, true, false);
        this.handlerAdapters = new ArrayList(adapterBeans.values());
        AnnotationAwareOrderComparator.sort(this.handlerAdapters);
        Map<String, HandlerResultHandler> beans = BeanFactoryUtils.beansOfTypeIncludingAncestors(context, HandlerResultHandler.class, true, false);
        this.resultHandlers = new ArrayList(beans.values());
        AnnotationAwareOrderComparator.sort(this.resultHandlers);
    }
    ```

* handler  
request를 처리하기 위해 등록된 handler들을 실행.  

  ```java
  public Mono<Void> handle(ServerWebExchange exchange) {
      if (this.handlerMappings == null) {
          return this.createNotFoundError();
      } else {
          return CorsUtils.isPreFlightRequest(exchange.getRequest()) ? this.handlePreFlight(exchange) : Flux.fromIterable(this.handlerMappings).concatMap((mapping) -> {
              return mapping.getHandler(exchange);
          }).next().switchIfEmpty(this.createNotFoundError()).onErrorResume((ex) -> {
              return this.handleResultMono(exchange, Mono.error(ex));
          }).flatMap((handler) -> {
              return this.handleRequestWith(exchange, handler);
          });
      }
  }
  ```

### RoutePredicateHandlerMapping

```java
public class RoutePredicateHandlerMapping extends AbstractHandlerMapping 
```

`AbstractHandlerMapping` 상속 : DispatcherHandler.handle 에서 handlerMapping 에서 사용.

exchange 로 매핑되는 Route 를 찾고, FilteringWebHandler를 return한다.

```java
@Override
protected Mono<?> getHandlerInternal(ServerWebExchange exchange) {
    ...

    return Mono.deferContextual(contextView -> {
        exchange.getAttributes().put(GATEWAY_REACTOR_CONTEXT_ATTR, contextView);
        return lookupRoute(exchange)
                // .log("route-predicate-handler-mapping", Level.FINER) //name this
                .map((Function<Route, ?>) r -> {
                    exchange.getAttributes().remove(GATEWAY_PREDICATE_ROUTE_ATTR);
                    if (logger.isDebugEnabled()) {
                        logger.debug("Mapping [" + getExchangeDesc(exchange) + "] to " + r);
                    }
            ...
        ...
    ...
}

protected Mono<Route> lookupRoute(ServerWebExchange exchange) {
    return this.routeLocator.getRoutes()
        .concatMap(route -> Mono.just(route).filterWhen(r -> {
                exchange.getAttributes().put(GATEWAY_PREDICATE_ROUTE_ATTR, r.getId());
                return r.getPredicate().apply(exchange);
            })
            .doOnError(e -> logger.error("Error applying predicate for route: " + route.getId(), e))
            .onErrorResume(e -> Mono.empty())
        )
        .next()
        .map(route -> {
            validateRoute(route, exchange);
            return route;
        });

}
```

## 구현  

### 구현할 기능

* 동적 라우팅
    평소에도 궁금했던 내용으로 동적(RestAPI, DB) 리버스 프록시가 가능한 게이트웨이를 만들고자 했던 부분이 있어
    인증과 더불어 동적 라우팅 기능이 포함된 게이트웨이를 구성해보고자 함.  

* 인증
    동적 라우팅 완료 후 진행  

### build.gradle.kts

```gradle
plugins {
    java
    id("org.springframework.boot") version "3.3.1"
    id("io.spring.dependency-management") version "1.1.5"
}

group = "com.jblim"
version = "v1.0.0-SNAPSHOT"

repositories {
    mavenCentral()
}

java {
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(21))
    }
}

configurations {
    compileOnly {
        extendsFrom(configurations.annotationProcessor.get())
    }
}

dependencies {
    // Annotation
    compileOnly("org.projectlombok:lombok:1.18.30")
    annotationProcessor("org.projectlombok:lombok:1.18.30")
    // Test 
    testCompileOnly("org.projectlombok:lombok:1.18.30")
    testAnnotationProcessor("org.projectlombok:lombok:1.18.30")

    // For Log
    implementation("org.apache.logging.log4j:log4j-api:2.20.0")
    implementation("org.apache.logging.log4j:log4j-core:2.20.0")
    implementation("org.apache.logging.log4j:log4j-slf4j-impl:2.20.0")
    implementation("com.fasterxml.jackson.core:jackson-databind:2.15.2")
    implementation("com.fasterxml.jackson.dataformat:jackson-dataformat-yaml:2.15.2")

    // Spring Boot
    implementation("org.springframework.boot:spring-boot-starter:3.3.1")
    implementation("org.springframework.boot:spring-boot-starter-web:3.3.1")
    implementation("org.springframework.boot:spring-boot-starter-webflux:3.3.1")
//    implementation("org.springframework.boot:spring-boot-starter-validation:3.3.1")
//    implementation("org.springframework.boot:spring-boot-configuration-processor:3.3.1")
//    implementation("org.springframework.boot:spring-boot-starter-oauth2-client")
//    implementation("org.springframework.boot:spring-boot-starter-actuator")

    developmentOnly("org.springframework.boot:spring-boot-devtools:3.3.1")
//    implementation("org.springframework.cloud:spring-cloud-loadbalancer:4.1.0")
//    implementation("org.springframework.boot:spring-boot-starter-data-redis:3.3.1")
//    implementation("org.springframework.boot:spring-boot-starter-security:3.3.1")

    // jpa
    implementation("org.springframework.boot:spring-boot-starter-data-jpa:3.3.1")
    // mariadb
    implementation("org.mariadb.jdbc:mariadb-java-client:3.3.1")
    // test h2
    testRuntimeOnly("com.h2database:h2:2.2.224")

    // Gateway
    implementation("org.springframework.cloud:spring-cloud-starter-gateway:4.1.0")

//    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.9.20")
//    implementation("org.jetbrains.kotlin:kotlin-reflect:1.9.20")

//    implementation("io.projectreactor.addons:reactor-extra")
//    implementation("io.projectreactor.kotlin:reactor-kotlin-extensions")

    // For Test
//    testImplementation(platform(Dependencies.JUNIT.BOM))
//    testImplementation(Dependencies.JUNIT.JUPITER)
//    testRuntimeOnly(Dependencies.JUNIT.PLATFORM_LAUNCH)
//    testRuntimeOnly(Dependencies.JUNIT.JUPITER_ENGINE)
//    testRuntimeOnly("org.junit.platform:junit-platform-reporting:1.10.1")
//    testImplementation(Dependencies.JUNIT.MOCKITO)
}

tasks.named<Test>("test") {
    useJUnitPlatform() // <5>

    testLogging {
        events("passed", "skipped", "failed") // <6>
    }
}

```

### Application.properties

```yaml

logging:
  level:
    root: DEBUG

server:
  port: 8080

spring:
  application:
    name: gateway
  datasource:
    url: "jdbc:mariadb://localhost:3306?useUnicode=true&characterEncoding=UTF-8&serverTimezone=UTC"
    username: ${DB_USER}
    password: ${DB_PASSWORD}
    hikari:
      connection-test-query: SELECT 1
      minimum-idle: 20
      maximum-pool-size: 20
  jpa:
    database-platform: org.hibernate.dialect.MariaDB103Dialect
    show-sql: false
    hibernate:
      ddl-auto: create
      naming:
        physical-strategy: org.hibernate.boot.model.naming.PhysicalNamingStrategyStandardImpl
    properties:
      hibernate:
        show_sql: false
        format_sql: false
        jdbc: "time_zone=UTC"
  cloud:
    gateway:
      enabled: true
      routes: []
```

### Entity

`Gateway`에서 사용되는 `RouteDefinition` 을 따라 작성

`AppRouteDefinication.java`

```java
@Entity
@Table(name = "app_route_definition")
public class AppRouteDefinition {

    @Id
    private String name;

    @NotNull
    private URI uri;

    @NotEmpty
    @ElementCollection
    @CollectionTable(name = "app_predicate", joinColumns = @JoinColumn(name = "name"))
    private List<AppPredicate> predicates;

    private int order;
//    private List<FilterDefinition> filters;
}
```

`AppPredicate.java`

```java
@Entity
@Embeddable
@Table(name = "app_predicate")
public class AppPredicate {
    @Id
    @GeneratedValue(generator = "uuid")
    private String uuid;
    private String name;
    @Lob
    private String dataJson;
    @Transient
    private Map<String, String> data;
    @PostLoad
    private void postLoad() {
        ObjectMapper objectMapper = new ObjectMapper();
        try{
            this.data = objectMapper.readValue(dataJson, Map.class);
        } catch (IOException e) {
            this.data = null;
        }
    }
    @PrePersist
    @PreUpdate
    private void prePersist() {
        ObjectMapper objectMapper = new ObjectMapper();
        try {
            this.dataJson = objectMapper.writeValueAsString(data);
        } catch (IOException e) {
            this.dataJson = null;
        }
    }
}
```

### Repository

```java
@Repository
public interface AppRouteDefinitionRepository extends JpaRepository<AppRouteDefinition, String> {

}
```

### Service

```java
@Service
public class RouteService {

    @Autowired
    private AppRouteDefinitionRepository repository;

    public AppRouteDefinition addRoute(AppRouteDefinition route) {
        return repository.save(route);
    }

    public void deleteRoute(String id) {
        repository.deleteById(id);
    }

    public List<AppRouteDefinition> getAllRoutes() {
        return repository.findAll();
    }

    public Flux<AppRouteDefinition> getRouteDefinitions() {
        return Flux.fromIterable(repository.findAll());
    }
}
```

### Configuration

`RouteDefinitionLocator` 를 반환하는 코드를 추가하여 `Gateway`에서 사용될 수 있도록 함.

```java
@Configuration
public class GatewayConfiguration {

    private final AppRouteDefinitionRepository repo;

    public GatewayConfiguration(AppRouteDefinitionRepository repo) {
        this.repo = repo;
    }

    @Bean
    public RouteDefinitionLocator routeDefinitionLocator() {
        return new DatabaseRouteDefinitionLocator(repo);
    }
}
```

### Controller

```java
@RestController
@RequestMapping("/routes")
public class RouteController {

    private final RouteService routeService;

    public RouteController(RouteService routeService) {
        this.routeService = routeService;
    }

    @PostMapping
    public AppRouteDefinition addRoute(@RequestBody AppRouteDefinition route) {
        return routeService.addRoute(route);
    }

    @DeleteMapping("/{id}")
    public void deleteRoute(@PathVariable String id) {
        routeService.deleteRoute(id);
    }

    @GetMapping
    public List<AppRouteDefinition> getAllRoutes() {
        return routeService.getAllRoutes();
    }
}
```

## 테스트

보완 필요...  

## 참고 사이트

[Spring Cloud Gateway Source](https://github.com/spring-cloud/spring-cloud-gateway)  
[Spring Cloud Gateway Doc](https://docs.spring.io/spring-cloud-gateway/reference/spring-cloud-gateway/how-it-works.html)  
[그림출처](https://dlsrb6342.github.io/2019/05/14/spring-cloud-gateway-%EA%B5%AC%EC%A1%B0/)  
