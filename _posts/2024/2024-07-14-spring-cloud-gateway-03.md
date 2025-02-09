---
layout: post
title: spring cloud gatgeway 03
author: jblim0125
date: 2024-07-14
category: 2024
---

## Spring Cloud Gateway

Spring Cloud Gateway과 관련해서 테스트를 진행하면서 변경된 부분과 새롭게 알게된 내용들 정리  

### 1. 주요 변경 부분  

1. spring cloud gateway와 spring boot의 버전 호환성 문제  
    spring cloud gateway = 4.1.0  
    spring boot = 3.2.x  

2. spring cloud gateway 사용 시 spring boot starter web 사용 불가  
    spring-boot-starter-web => spring-boot-starter-webflux  

3. R2DBC 를 이용한 데이터베이스 접근  
    JPA -> R2DBC  

4. R2DBC 를 사용하는 경우 JPA의 임베디드 기능을 이용 불가  
    서비스 레이어에서 서브데이터를 처리할 수 있도록 조치  

### 2. 소스와 간략한 설명

#### build.gradle.kts

R2DBC 적용에 따른 데이터베이스와 관련된 디펜던시의 변경
데이터베이스 Init을 위한 Flayway 추가  

```gradle
plugins {
    java
    id("org.springframework.boot") version "3.2.7"
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
    // For Annotation
    compileOnly("org.projectlombok:lombok:1.18.30")
    annotationProcessor("org.projectlombok:lombok:1.18.30")
    // For Unit Test Code Annotation
    testCompileOnly("org.projectlombok:lombok:1.18.30")
    testAnnotationProcessor("org.projectlombok:lombok:1.18.30")

    // For Log
    implementation("org.apache.logging.log4j:log4j-api:2.20.0")
    implementation("org.apache.logging.log4j:log4j-core:2.20.0")
    implementation("org.apache.logging.log4j:log4j-slf4j-impl:2.20.0")
    implementation("com.fasterxml.jackson.core:jackson-databind:2.15.2")
    implementation("com.fasterxml.jackson.dataformat:jackson-dataformat-yaml:2.15.2")

    // Spring Cloud Gateway
    // Spring Boot
    implementation("org.springframework.boot:spring-boot-starter:3.2.7")
    implementation("org.springframework.boot:spring-boot-starter-webflux:3.2.7")
//    implementation("org.springframework.boot:spring-boot-starter-validation:3.2.7")
//    implementation("org.springframework.boot:spring-boot-configuration-processor:3.2.7")
//    implementation("org.springframework.boot:spring-boot-starter-oauth2-client")
    implementation("org.springframework.boot:spring-boot-starter-actuator")

    developmentOnly("org.springframework.boot:spring-boot-devtools:3.2.7")
//    implementation("org.springframework.cloud:spring-cloud-loadbalancer:4.1.0")
//    implementation("org.springframework.boot:spring-boot-starter-data-redis:3.3.1")
//    implementation("org.springframework.boot:spring-boot-starter-security:3.3.1")

    // R2DBC
    implementation("org.springframework.boot:spring-boot-starter-data-r2dbc:3.2.7")
    // mariadb
    implementation("org.mariadb.jdbc:mariadb-java-client:3.3.1")
    implementation("org.mariadb:r2dbc-mariadb:1.2.1")
    // flyway
    implementation("org.flywaydb:flyway-core:10.15.2")
    implementation("org.flywaydb:flyway-mysql:10.15.2")

    // Gateway
    implementation("org.springframework.cloud:spring-cloud-starter-gateway:4.1.0")

//    implementation("io.projectreactor.addons:reactor-extra")

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

#### Application.properties

Actuator 사용을 위한 설정 추가  

```yaml
logging:
  level:
    root: DEBUG

server:
  port: 8080

spring:
  application:
    name: gateway
  r2dbc:
    url: r2dbc:mariadb://localhost:3306
    name: gateway-database
    username: gateway
    password: gateway-secret
  flyway:
    enabled: true
    locations: "classpath:migrations"
    url: jdbc:mariadb://localhost:3306/gateway-database
    user: gateway
    password: gateway-secret
  cloud:
    gateway:
      enabled: true
    # YAML을 이용한 설정 샘플 
    #   routes:
    #     - id: service-a
    #       uri: http://localhost:8082
    #       predicates:
    #         - Path=/aservice/**
    #       filters:
    #         - RewritePath=/aservice/(?<path>.*), /$\{path}

## Actuator 를 이용한 게이트웨이 설정 기능 활성화 시 사용
# management:
#   endpoint:
#     gateway:
#       enabled: true
#   endpoints:
#     web:
#       exposure:
#         include: "gateway"
```

#### Configuration : RouteLocator

SpringCloudGateway 코드 분석 과정에서 본 `lookupRoute` 에서 사용될 수 있도록 `RouteLocator` 를 반환  

`protected Mono<Route> lookupRoute(ServerWebExchange exchange)`

```java
@Configuration
public class GatewayConfiguration {
    @Bean
    public RouteLocator routeLocator(ApiRouteService apiRouteService,
            RouteLocatorBuilder routeLocatorBuilder) {
        return new ApiPathRouteLocatorImpl(apiRouteService, routeLocatorBuilder);
    }
}
```

#### Entity

SpringCloudGateway의 `RouteDefinition`과 `Predicate`와 유사하게 변경  

```java
@Table(TableName.APP_ROUTE_DEFINITION)
public class AppRouteDefinition {

    @Id
    @Column("ID")
    private String id;

    @Column("URI")
    private String uri;

    @Transient
    private List<AppPredicate> predicate;
}

@Table(name = TableName.APP_PREDICATE)
public class AppPredicate {

    @Column("ROUTE_ID")
    private String routeId;

    @Column("NAME")
    private String name;

    @Column("ARGS")
    private Map<String, String> args;
}
```

#### Repository  

`AppRouteDeinition` 에서 `predicate` 에 `@Transient`를 설정했으나 문제가 되어 `@Query`를 추가하여 처리  
`AppPredicate` 의 경우 `ROUTE_ID` 를 이용해 데이터를 조회하고 삭제할 수 있도록 추가  

```java
@Repository
public interface ApiRouteRepository extends ReactiveCrudRepository<AppRouteDefinition, String> {

    @Query("INSERT INTO APP_ROUTE_DEFINITION (ID, URI) VALUES (:#{#routeDefinition.id}, :#{#routeDefinition.uri})")
    Mono<AppRouteDefinition> save(AppRouteDefinition routeDefinition);
}

@Repository
public interface AppPredicateRepository extends ReactiveCrudRepository<AppPredicate, UUID> {

    @Query("SELECT * FROM APP_PREDICATE WHERE ROUTE_ID = :#{#routeId}")
    Flux<AppPredicate> findByRouteId(String routeId);

    Mono<Void> deleteByRouteId(String routeId);
}
```

#### Service

R2DBC의 사용에 따른 서브 데이터 처리 추가  

```java
@Service
public class ApiRouteServiceImpl implements ApiRouteService {

    // ...
    // ...


    // 조회  
    @Override
    public Flux<AppRouteDefinition> findApiRoutes() {
        return apiRouteRepository.findAll().flatMap(this::loadPredicates);
    }

    private Mono<AppRouteDefinition> loadPredicates(AppRouteDefinition routeDefinition) {
        return appPredicateRepository.findByRouteId(routeDefinition.getId())
                .collectList()
                .map(predicates -> {
                    routeDefinition.setPredicate(predicates);
                    return routeDefinition;
                });
    }

    @Override
    public Mono<AppRouteDefinition> findApiRoute(String id) {
        return findAndValidateApiRoute(id);
    }

    // 추가  
    @Override
    public Mono<Void> createApiRoute(CreateOrUpdateApiRouteRequest createOrUpdateApiRouteRequest) {
        AppRouteDefinition routeDefinition = setNewApiRoute(new AppRouteDefinition(),
                createOrUpdateApiRouteRequest);
        return apiRouteRepository.save(routeDefinition)
                .then(Mono.defer( () ->
                            Flux.fromIterable(routeDefinition.getPredicate())
                                    .flatMap(appPredicateRepository::save)
                                    .then(Mono.just(routeDefinition))
                        )
                )
                .doOnSuccess(obj -> gatewayRouteService.refreshRoutes())
                .then();
    }

    // 업데이트 
    @Override
    public Mono<Void> updateApiRoute(String id,
            CreateOrUpdateApiRouteRequest createOrUpdateApiRouteRequest) {
        return findAndValidateApiRoute(id)
                .map(routeDefinition -> setNewApiRoute(routeDefinition, createOrUpdateApiRouteRequest))
                .flatMap(apiRouteRepository::save)
                .flatMap(route -> appPredicateRepository.saveAll(setNewApiRoute(route, createOrUpdateApiRouteRequest).getPredicate()).then(Mono.just(route)))
                .doOnSuccess(obj -> gatewayRouteService.refreshRoutes())
                .then();
    }

    // 삭제  
    @Override
    @Transactional
    public Mono<Void> deleteApiRoute(String id) {
        return findAndValidateApiRoute(id)
                .flatMap(routeDefinition -> apiRouteRepository.deleteById(routeDefinition.getId()))
                .then(Mono.defer(() -> appPredicateRepository.deleteByRouteId(id)))
                .doOnSuccess(obj -> gatewayRouteService.refreshRoutes());
    }

    private Mono<AppRouteDefinition> findAndValidateApiRoute(String id) {
        return apiRouteRepository.findById(id)   // .flatMap(this::loadPredicates)
                .switchIfEmpty(Mono.error(
                        new RuntimeException(String.format("Api route with id %s not found", id))));
    }

    private AppRouteDefinition setNewApiRoute(AppRouteDefinition routeDefinition,
            CreateOrUpdateApiRouteRequest createOrUpdateApiRouteRequest) {
        routeDefinition.setId(createOrUpdateApiRouteRequest.getId());
        routeDefinition.setUri(createOrUpdateApiRouteRequest.getUri());
        List<AppPredicate> appPredicateList = new ArrayList<>();

        if (createOrUpdateApiRouteRequest.getPath() != null &&
                !createOrUpdateApiRouteRequest.getPath().isEmpty()) {
            // Path predicate
            AppPredicate predicate = new AppPredicate();
            HashMap<String, String> args = new HashMap<>();
            predicate.setRouteId(routeDefinition.getId());
            predicate.setName(routeDefinition.getId() + "-path-predicate");
            args.put("patterns", String.join(",", createOrUpdateApiRouteRequest.getPath()));
            predicate.setArgs(args);
            appPredicateList.add(predicate);
        }
        if (createOrUpdateApiRouteRequest.getMethod() != null &&
                !createOrUpdateApiRouteRequest.getMethod().isEmpty()) {
            // Method predicate
            AppPredicate predicate = new AppPredicate();
            HashMap<String, String> args = new HashMap<>();
            predicate.setRouteId(routeDefinition.getId());
            predicate.setName(routeDefinition.getId() + "-method-predicate");
            args.put("methods", String.join(",", createOrUpdateApiRouteRequest.getMethod()));
            predicate.setArgs(args);
            appPredicateList.add(predicate);
        }
        routeDefinition.setPredicate(appPredicateList);
        return routeDefinition;
    }
}
```

#### Controller  

```java
@RestController
@RequestMapping(path = ApiPath.INTERNAL_API_ROUTES)
public class InternalApiRouteController {

    private final ApiRouteService apiRouteService;

    public InternalApiRouteController(ApiRouteService apiRouteService) {
        this.apiRouteService = apiRouteService;
    }

    @GetMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    public Mono<List<ApiRouteResponse>> findApiRoutes() {
        return apiRouteService.findApiRoutes()
                .map(this::convertApiRouteIntoApiRouteResponse)
                .collectList()
                .subscribeOn(Schedulers.boundedElastic());
    }

    @GetMapping(path = "/{id}", produces = MediaType.APPLICATION_JSON_VALUE)
    public Mono<ApiRouteResponse> findApiRoute(@PathVariable String id) {
        return apiRouteService.findApiRoute(id)
                .map(this::convertApiRouteIntoApiRouteResponse)
                .subscribeOn(Schedulers.boundedElastic());
    }

    @PostMapping(consumes = MediaType.APPLICATION_JSON_VALUE,
            produces = MediaType.APPLICATION_JSON_VALUE)
    @ResponseStatus(HttpStatus.CREATED)
    public Mono<?> createApiRoute(
            @RequestBody @Validated CreateOrUpdateApiRouteRequest createOrUpdateApiRouteRequest) {
        return apiRouteService.createApiRoute(createOrUpdateApiRouteRequest)
                .subscribeOn(Schedulers.boundedElastic());
    }

    @PutMapping(path = "/{id}",
            consumes = MediaType.APPLICATION_JSON_VALUE,
            produces = MediaType.APPLICATION_JSON_VALUE)
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public Mono<?> updateApiRoute(@PathVariable String id,
            @RequestBody @Validated CreateOrUpdateApiRouteRequest createOrUpdateApiRouteRequest) {
        return apiRouteService.updateApiRoute(id, createOrUpdateApiRouteRequest)
                .subscribeOn(Schedulers.boundedElastic());
    }

    @DeleteMapping(path = "/{id}",
            produces = MediaType.APPLICATION_JSON_VALUE)
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public Mono<?> deleteApiRoute(@PathVariable String id) {
        return apiRouteService.deleteApiRoute(id)
                .subscribeOn(Schedulers.boundedElastic());
    }

    private ApiRouteResponse convertApiRouteIntoApiRouteResponse(AppRouteDefinition apiRoute) {
        List<String> path = new ArrayList<>();
        List<String> method = new ArrayList<>();
        for( AppPredicate predicate : apiRoute.getPredicate()) {
            for( String key : predicate.getArgs().keySet()) {
                if( key.equals("patterns")) {
                    path.add(predicate.getArgs().get(key));
                } else if( key.equals("methods")) {
                    method.add(predicate.getArgs().get(key));
                }
            }
        }
        return ApiRouteResponse.builder()
                .id(apiRoute.getId())
                .path(path)
                .method(method)
                .uri(apiRoute.getUri().toString())
                .build();
    }
}
```

#### refreshRoutes

라우팅 변경에 따른 이벤트를 전달하여 Gateway의 데이터가 변경될 수 있도록 함.

```java
@Service
public class GatewayRouteServiceImpl implements GatewayRouteService {
  
  private final ApplicationEventPublisher applicationEventPublisher;

  public GatewayRouteServiceImpl(ApplicationEventPublisher applicationEventPublisher) {
    this.applicationEventPublisher = applicationEventPublisher;
  }

  @Override
  public void refreshRoutes() {
    applicationEventPublisher.publishEvent(new RefreshRoutesEvent(this));
  }
}
```

### 3. Test  

#### 준비  

1. HTTP Server  
    `/hello` prefix 를 가지는 8082 포트의 http 서버 실행  

2. Database  
    docker를 활용해 mariadb 실행  

    ```shell
    docker run --name gateway-mariadb \
        --env MARIADB_USER=gateway \
        --env MARIADB_PASSWORD=gateway-secret \
        --env MARIADB_DATABASE=gateway-database \
        --env MARIADB_ROOT_PASSWORD=root-secret \
        -p 3306:3306 \
        -v ${PWD}/mariadb-data:/var/lib/mysql \
        mariadb:latest
    ```

#### 시험  

조회 -> 라우팅 추가 -> 조회 -> 서비스 연결 순으로 테스트 진행  

1. 조회  

    ```text
    GET http://localhost:8080/internal/api-routes

    Response
    없음  
    ```

2. 추가  

    ```text
    POST http://localhost:8080/internal/api-routes
    Content-Type: application/json

    {
        "id": "hello",
        "uri": "http://localhost:8082",
        "path": [
            "/hello/**"
        ]
    }

    HTTP/1.1 201 Created
    Content-Type: application/json
    Content-Length: 0

    <Response body is empty>
    ```

3. 라우팅 조회  

    ```text
    GET http://localhost:8080/internal/api-routes

    Response
    HTTP/1.1 200 OK
    Content-Type: application/json
    Content-Length: 67

    [
        {
            "id": "hello",
            "uri": "http://localhost:8082",
            "path": [
            "/hello/**"
            ]
        }
    ]
    ```

4. Actuator 를 이용한 라우팅 조회  

    ```text
    GET http://127.0.0.1:8080/actuator/gateway/routes

    HTTP/1.1 200 OK
    transfer-encoding: chunked
    Content-Type: application/json

    [
        {
            "predicate": "Paths: [/hello/**], match trailing slash: true",
            "route_id": "hello",
            "filters": [],
            "uri": "http://localhost:8082",
            "order": 0
        }
    ]
    ```

5. 서비스 연결 테스트  

    ```text
    GET http://localhost:8080/hello

    HTTP/1.1 200 OK
    Content-Type: text/plain;charset=UTF-8
    Content-Length: 14
    Date: Sun, 14 Jul 2024 14:35:51 GMT

    Hello Gateway!
    ```

### 4. 다음은

라우팅 기능의 강화와 인증(keycloak)과 로깅(Jager?)을 적용해 보자.  
