---
layout: post
title: SpringBoot JPA + Cache
author: jblim0125
date: 2025-02-28
category: 2025
---

## 개요

애플리케이션의 성능을 최적화하는 가장 강력한 방법 중 하나는 캐싱(Caching)입니다. 캐시를 통해 빈번한 데이터베이스 접근을 줄이고 응답 시간을 획기적으로 단축할 수 있습니다. 이번 글에서는 Spring Cache를 활용해 Redis와 JPA를 함께 사용하는 방법을 소개하고, 간단한 예제를 통해 그 흐름을 쉽게 이해할 수 있도록 설명드리겠습니다.

**Spring Cache와 Redis란?**  

- Spring Cache
    Spring에서 제공하는 캐싱 추상화 기능으로, 다양한 캐시 스토리지를 사용할 수 있습니다. 이는 애플리케이션 코드에 최소한의 변경으로 캐시 기능을 추가할 수 있게 해줍니다.

- Redis
    Redis는 인메모리 데이터 구조 스토리지로, 빠른 읽기/쓰기 성능을 제공합니다. Spring Cache와 함께 사용하면, 데이터베이스 접근 횟수를 크게 줄일 수 있습니다.  

## 프로젝트 설정

**Gradle 의존성 설정**  

```kotlin
dependencies {
    implementation("org.springframework.boot:spring-boot-starter-data-jpa")
    implementation("org.springframework.boot:spring-boot-starter-data-redis")
    implementation("org.springframework.boot:spring-boot-starter-cache")
    implementation("com.h2database:h2")
}
```

**Spring Cache -> Redis 설정**  

cache 타입을 redis로 설정하여 cache 가 redis에 저장될 수 있도록 한다.

- application.yml  

    ```yaml
    spring:
        cache:
            type: redis
    ```

## 구현  

Spring Boot 애플리케이션에서 캐시 활성화 : `@EnableCaching` 추가  

```java
package com.jblim.sample.configurations;

import org.springframework.cache.annotation.EnableCaching;
import org.springframework.context.annotation.Configuration;

@Configuration
@EnableCaching
public class CacheConfig {

}
```

**Entity**  

간단한 엔티티와 JPA 레포지토리 추가  

```java
package com.jblim.sample.entity;

@Getter
@Setter
@Entity
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "user_entity")
public class UserEntity {

    @Id
    @Column(name = "id")
    private String id;

    @Column(name = "name", nullable = false)
    private String name;

    @Column(name = "email", nullable = false)
    private String email;

    // ...
}
```

**Repository**  

```java
package com.jblim.springsample.user;

public interface UserRepository extends JpaRepository<UserEntity, Long> {
    Optional<UserEntity> findByName(String name);
}
```

**캐시 적용하기**  

Service 계층에서 데이터를 조회할 때 캐시를 적용하려면 `@Cacheable`과 `@CacheEvict`을 사용합니다.

```java
package com.jblim.sample.user;

@Service
public class UserService {

    private final UserRepository userRepository;

    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Cacheable(value = "user_entity", key = "#name" )
    public UserEntity getUserByName(String name) {
        return userRepository.findByName(name).orElse(null);
    }

    @CacheEvict(value = "user_entity", key="#user.name")
    public UserEntity createUser(UserEntity user) {
        return userRepository.save(user);
    }
}

```

- `@Cacheable(value = "users", key = "#id")`
Redis 캐시에서 데이터를 먼저 조회하고 없으면 DB에서 가져옴
- `@CacheEvict(value = "users", key = "#user.id")`
새로운 데이터를 저장하거나 업데이트하면 기존 캐시를 삭제

## 테스트

**로그 설정**  

```yaml
logging:
  level:
    root: info
    org.testcontainers: info
    com.jblim: debug
    org.hibernate.SQL: debug    # 실행되는 SQL 쿼리 로그 출력
    org.hibernate.type.descriptor.sql.BasicBinder: TRACE # 바인딩되는 파라미터 값 확인
    org.springframework.orm.jpa: DEBUG    # Spring JPA 내부 동작 로깅
    org.springframework.transaction: DEBUG  # 트랜잭션 관련 로그
```

**redis 컨테이너 실행**  

> 유닛테스트에서 testcontainer 를 활용하려고 했으나, 컨테이너가 실행되어 있음에도 연결 오류가 발생하여 실행된 상태에서 테스트를 진행함.

**redis 연결 설정**  

```yaml
spring:
  data:
    redis:
      host: localhost
      port: 51500
      password: ""
```

**entity 데이터의 Serializable 설정**  

테스트 과정에서 오류로 알게 된 부분으로 redis에 저장 및 불러오기 위한 방법 설정 필요.

```java
package com.jblim.sample.configurations;

@Configuration
public class RedisConfig {

    @Bean
    public RedisCacheManagerBuilderCustomizer redisCacheManagerBuilderCustomizer() {
        return builder -> {
            RedisCacheConfiguration config = RedisCacheConfiguration.defaultCacheConfig()
                    .entryTtl(Duration.ofMinutes(10)) // 캐시 만료 시간 설정
                    .disableCachingNullValues()
                    .serializeKeysWith(RedisSerializationContext.SerializationPair.fromSerializer(
                            new StringRedisSerializer()))
                    .serializeValuesWith(RedisSerializationContext.SerializationPair.fromSerializer(
                            new GenericJackson2JsonRedisSerializer()));

            builder.cacheDefaults(config);
        };
    }

    @Bean
    public RedisTemplate<String, Object> redisTemplate(RedisConnectionFactory connectionFactory) {
        RedisTemplate<String, Object> template = new RedisTemplate<>();
        template.setConnectionFactory(connectionFactory);

        // Jackson JSON Serializer 설정
        ObjectMapper objectMapper = new ObjectMapper();
        objectMapper.configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);
        objectMapper.disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);
        objectMapper.setDateFormat(Utilities.DATE_TIME_FORMAT);
        objectMapper.registerModule(new JavaTimeModule());

        GenericJackson2JsonRedisSerializer serializer = new GenericJackson2JsonRedisSerializer(
                objectMapper);

        // Key와 Value 직렬화 방식 지정
        template.setKeySerializer(new StringRedisSerializer());
        template.setValueSerializer(serializer);
        template.setHashKeySerializer(new StringRedisSerializer());
        template.setHashValueSerializer(serializer);

        template.afterPropertiesSet();
        return template;
    }
}
```

**unittest 작성**

```java
package com.jblim.sample.user;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jblim.sample.entity.UserEntity;
import com.redis.testcontainers.RedisContainer;
import java.util.Arrays;
import java.util.List;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.SystemProperties;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.containers.MySQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.shaded.com.fasterxml.jackson.databind.ObjectMapper;
import org.testcontainers.utility.DockerImageName;

@Slf4j
@Testcontainers
@SpringBootTest
@AutoConfigureMockMvc
public class UserControllerTest {

    @Autowired
    private MockMvc mockMvc;

    private static final ObjectMapper mapper;

    static {
        mapper = new ObjectMapper();
    }

    @Container
    public static MySQLContainer<?> mysql = new MySQLContainer<>("mysql:8.3.0")
            .withReuse(true)
            .withUsername("sample_user")
            .withPassword("sample_password")
            .withDatabaseName("sample");

//    @Container
//    public static GenericContainer<?> redis = new RedisContainer(
//            DockerImageName.parse("redis:6.2.6"))
//            .withReuse(true)
//            .withExposedPorts(6379);
//    오류 발생하여 container 직접 실행하는 방법으로 변경

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        mysql.start();
        registry.add("spring.datasource.url", mysql::getJdbcUrl);
        registry.add("spring.datasource.username", mysql::getUsername);
        registry.add("spring.datasource.password", mysql::getPassword);
        // redis.start();
        // registry.add("spring.data.redis.host", redis::getHost);
        // registry.add("spring.data.redis.port", () -> redis.getMappedPort(6379));
    }

    @BeforeAll
    static void beforeAll() {
        // Flyway 마이그레이션 실행
        Flyway flyway = Flyway.configure()
                .dataSource(mysql.getJdbcUrl(), mysql.getUsername(), mysql.getPassword())
                .load();
        flyway.migrate();
        log.info("flyway migration finish");
    }

    @Test
    @DisplayName("cache test")
    void createAndGet() throws Exception {

        UserEntity request = UserEntity.builder()
                .name("user-01").email("user-01@jblim.com").build();

        MvcResult result = mockMvc.perform(post("/user")
                        .contentType(MediaType.APPLICATION_JSON)
                        .accept(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andReturn();

        log.info("Create UserEntity: {}", result.getResponse().getContentAsString());

        UserEntity userResponse = mapper.readValue(result.getResponse().getContentAsString(),
                UserEntity.class);
        Assertions.assertNotNull(userResponse.getId());
        Assertions.assertEquals("user-01", userResponse.getName());
        Assertions.assertEquals("user-01@jblim.com", userResponse.getEmail());

        result = mockMvc.perform(get("/user")
                        .queryParam("name", "user-01")
                        .accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andReturn();
        UserEntity userResponse2 = mapper.readValue(result.getResponse().getContentAsString(),
                UserEntity.class);
        Assertions.assertEquals(userResponse.getId(), userResponse2.getId());
        Assertions.assertEquals(userResponse.getName(), userResponse2.getName());
        Assertions.assertEquals(userResponse.getEmail(), userResponse2.getEmail());

        log.info("Get 01 - UserEntity: {}", result.getResponse().getContentAsString());

        result = mockMvc.perform(get("/user")
                        .queryParam("name", "user-01")
                        .accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andReturn();
        UserEntity userResponse3 = mapper.readValue(result.getResponse().getContentAsString(),
                UserEntity.class);
        Assertions.assertEquals(userResponse.getId(), userResponse3.getId());
        Assertions.assertEquals(userResponse.getName(), userResponse3.getName());
        Assertions.assertEquals(userResponse.getEmail(), userResponse3.getEmail());

        log.info("Get 02 - UserEntity: {}", result.getResponse().getContentAsString());
    }

    @AfterAll
    static void afterAll() {
        mysql.stop();
    }
}
```

실행 후 로그를 살펴보면

```text
25-03-02 15:54:42.231 [Test worker ] [DEBUG] [AbstractPlatformTr:790] : Initiating transaction commit
25-03-02 15:54:42.231 [Test worker ] [DEBUG] [JpaTransactionMana:557] : Committing JPA transaction on EntityManager [SessionImpl(430428967<open>)]
25-03-02 15:54:42.241 [Test worker ] [DEBUG] [SqlStatementLogger:135] : insert into user_entity (email,name,id) values (?,?,?)
Hibernate: insert into user_entity (email,name,id) values (?,?,?)
25-03-02 15:54:42.251 [Test worker ] [DEBUG] [JpaTransactionMana:657] : Not closing pre-bound JPA EntityManager after transaction
25-03-02 15:54:42.537 [Test worker ] [DEBUG] [OpenEntityManagerI:111] : Closing JPA EntityManager in OpenEntityManagerInViewInterceptor
25-03-02 15:54:42.543 [Test worker ] [INFO ] [UserControllerTest: 99] : Create UserEntity: {"id":"019555a2-b7f4-7903-aea1-e63fad8e75dd","name":"user-01","email":"user-01@jblim.com"}
25-03-02 15:54:42.549 [Test worker ] [DEBUG] [OpenEntityManagerI: 86] : Opening JPA EntityManager in OpenEntityManagerInViewInterceptor
25-03-02 15:54:42.630 [Test worker ] [DEBUG] [SqlStatementLogger:135] : select ue1_0.id,ue1_0.email,ue1_0.name from user_entity ue1_0 where ue1_0.name=?
Hibernate: select ue1_0.id,ue1_0.email,ue1_0.name from user_entity ue1_0 where ue1_0.name=?
25-03-02 15:54:42.647 [Test worker ] [DEBUG] [OpenEntityManagerI:111] : Closing JPA EntityManager in OpenEntityManagerInViewInterceptor
25-03-02 15:54:42.648 [Test worker ] [INFO ] [UserControllerTest:118] : Get 01 - UserEntity: {"id":"019555a2-b7f4-7903-aea1-e63fad8e75dd","name":"user-01","email":"user-01@jblim.com"}
25-03-02 15:54:42.648 [Test worker ] [DEBUG] [OpenEntityManagerI: 86] : Opening JPA EntityManager in OpenEntityManagerInViewInterceptor
25-03-02 15:54:42.656 [Test worker ] [DEBUG] [OpenEntityManagerI:111] : Closing JPA EntityManager in OpenEntityManagerInViewInterceptor
25-03-02 15:54:42.657 [Test worker ] [INFO ] [UserControllerTest:131] : Get 02 - UserEntity: {"id":"019555a2-b7f4-7903-aea1-e63fad8e75dd","name":"user-01","email":"user-01@jblim.com"}
```

두번째 조회에서 데이터베이스 조회 쿼리가 실행되지 않은 것을 확인할 수 있다.  

## 추가로 참고할 내용과 사이트 정리

Spring Boot와 JPA에서 캐시로 인해 발생한 데이터 불일치 문제 해결하기
https://jypark1111.tistory.com/238

캐시 설명
https://dingdingmin-back-end-developer.tistory.com/entry/Spring-Boot-JPA-1%EC%B0%A8-%EC%BA%90%EC%8B%9C-%EC%A0%95%EB%A6%AC


## Sample Source Link

전체 코드는 다음 링크에서 확인할 수 있다.
https://github.com/jblim0125/java-samle