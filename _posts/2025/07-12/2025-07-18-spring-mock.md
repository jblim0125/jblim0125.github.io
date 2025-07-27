
# Java 21 & Spring 3.5 Mock 사용 변화

> 최근 Java 21과 Spring Framework 3.5 이상 환경에서 테스트 코드 작성 시 Mock 객체의 사용 방식에 변화가 생겼다. 특히 데이터 설정과 메모리 관리 측면에서 개선된 부분을 중심으로 정리한다.

---

## 1. Mock 데이터 설정 방식의 변화

- **기존:**
    - Mockito, EasyMock 등에서 `when(...).thenReturn(...)` 패턴을 주로 사용
    - 복잡한 객체나 컬렉션을 설정할 때, 테스트 코드가 장황해지는 문제가 있었음

- **Spring 3.5+ & Java 21:**
    - 레코드(Record) 타입 지원으로 불변 객체를 더 쉽게 Mock 데이터로 활용 가능
    - `@MockitoBean`과 `@MockitoSpyBean`의 생성자/빌더 패턴 지원 강화
    - 테스트용 데이터 생성 라이브러리(Faker, Instancio 등)와의 연동이 자연스러워짐


#### 예시

```java
@MockitoBean
private UserService userService;

when(userService.getUser(anyLong()))
    .thenReturn(new UserRecord(1L, "홍길동"));
```

---

## 2. 메모리 관리 및 성능 개선

- **기존:**
    - Mock 객체가 많아질수록 JVM 메모리 사용량 증가
    - 테스트 실행 후 GC가 즉시 이루어지지 않아, 대규모 테스트에서 OutOfMemory 발생 가능
- **Spring 3.5+ & Java 21:**
    - Mock 객체의 라이프사이클을 테스트 컨텍스트와 연동하여 자동 관리
    - JDK 21의 GC(가비지 컬렉터) 개선으로 테스트 후 Mock 객체 메모리 회수 속도 향상
    - `@DirtiesContext` 사용 시 Mock 객체도 즉시 정리됨

#### 예시
```java
@DirtiesContext
@SpringBootTest
class UserServiceTest {
    // ...테스트 코드...
}
```

---

## 3. 기타 변화 및 팁

- Mock 객체의 동적 생성 및 파라미터화가 쉬워짐 (람다, record, builder 활용)
- 테스트 데이터 생성 자동화 도구와의 통합이 자연스러워짐
- 메모리 누수 방지를 위한 테스트 컨텍스트 분리 전략 권장

---

## 참고

- [Spring Framework 3.5 Release Notes](https://github.com/spring-projects/spring-framework/releases)
- [Java 21 공식 문서](https://docs.oracle.com/en/java/javase/21/)
- [Mockito 공식 문서](https://site.mockito.org/)
