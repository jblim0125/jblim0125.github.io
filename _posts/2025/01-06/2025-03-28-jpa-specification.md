---
layout: post
title: JPA Specification
author: jblim0125
date: 2025-03-28
category: 2025
tags: [jpa, spring boot, specification]
---

### 개요

Spring Data JPA를 사용하다 보면 동적 쿼리(Dynamic Query)가 필요한 경우가 자주 발생합니다.
예를 들어, 검색 조건이 여러 개고 그 조합이 유동적일 때, if-else나 QueryDSL을 사용하기도 하지만, JPA Specification을 활용하면 코드의 재사용성과 가독성을 높일 수 있습니다.

이번 포스트에서는 Spring Boot 프로젝트에서 JPA Specification을 사용하여 동적 쿼리를 구현하는 방법을 정리해보겠습니다.

### 📌 JPA Specification이란?

JPA Specification은 [Specification 패턴](https://en.wikipedia.org/wiki/Specification_pattern)을 활용하여 조건을 객체화하고, 
이들을 조합하여 복잡한 쿼리를 구성할 수 있게 해주는 기능입니다. `JpaSpecificationExecutor`를 통해 사용할 수 있으며, `Predicate`를 기반으로 동작합니다.

### 🛠️ 예제

먼저 예제로 사용할 `User` 엔티티는 아래와 같습니다:

```java
@Getter
@Setter
@Entity
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_name", nullable = false)
    private String username;

    private Integer age;
}
```

JpaSpecificationExecutor를 상속해야 Specification 기반 쿼리를 사용할 수 있습니다.

```java
public interface UserRepository extends JpaRepository<User, Long>, JpaSpecificationExecutor<User> {
}
```

#### Specification 작성 예시

> 💡 **주의:** `root.get("username")`처럼 사용할 때, `"username"`은 실제 엔티티 클래스의 필드 이름과 일치해야 합니다.  
> 예를 들어 컬럼명이 `username` or `user_name`로 필드명과 다른 경우라도 `User` 클래스의 필드명이 `userName`이라면
> `root.get("userName")`으로 작성해야 하며, 오타가 있을 경우 런타임에서 오류가 발생합니다.

```java
public class UserSpecification {

    public static Specification<User> hasUsername(String username) {
        return (root, query, criteriaBuilder) ->
            username == null ? null : criteriaBuilder.equal(root.get("username"), username);
    }

    public static Specification<User> hasUsernameIn(List<String> usernames) {
        return (root, query, criteriaBuilder) ->
            usernames == null || usernames.isEmpty()
                ? null
                : root.get("username").in(usernames);
    }

    public static Specification<User> hasAgeGreaterThan(Integer age) {
        return (root, query, criteriaBuilder) ->
            age == null ? null : criteriaBuilder.greaterThan(root.get("age"), age);
    }
}
```

null 체크를 통해 조건이 없을 때는 Predicate를 생성하지 않도록 하면, 깔끔한 동적 쿼리 구현이 가능합니다.

#### Specification 조합

```java
Specification<User> spec = Specification
    .where(UserSpecification.hasUsername(username))
    .and(UserSpecification.hasAgeGreaterThan(age));

List<User> results = userRepository.findAll(spec);
```

#### Specification 장단점

💡 장점
    • 조건별 메서드 분리 → 가독성 증가
    • 재사용성 높은 쿼리 구성
    • 조건 조합이 유연함

⚠️ 주의점
    • 복잡한 조인이 많은 경우에는 QueryDSL이 더 적합할 수 있음
    • Specification이 지나치게 많아질 경우 오히려 관리가 어려울 수 있음

### 🔚 마무리

JPA Specification은 동적 쿼리 작성에 있어 매우 강력한 도구입니다. 간단한 검색 필터가 있는 화면에서는 충분히 유용하게 사용할 수 있으며,
코드의 재사용성과 테스트 용이성도 높일 수 있습니다.
