---
layout: post
title: JUnit5 개요
author: jblim0125
date: 2024-01-10
category: 2024
---

## 1. Overview

### 1.1. What is JUnit 5?
JUnit 5 = JUnit Platform + JUnit Jupiter + JUnit Vintage

* JUnit Platform   
테스팅 프레임워크를 구동하기 위한 launcher와 테스트 엔진을 위한 API를 제공  

* JUnit Jupiter  
JUnit 5를 위한 테스트 API와 실행 엔진을 제공  

* JUnit Vintage   
JUnit 3과 4로 작성된 테스트를 JUnit 5 Platform에서 실행하기 위한 모듈을 제공


### 1.2. Getting Start
* Gradle - Java Sample
```gradle
plugins {
	id 'java'
	id 'idea' // optional (to generate IntelliJ IDEA project files)
}

repositories {
	mavenCentral()
}

dependencies {
	testImplementation(platform('org.junit:junit-bom:5.10.1'))
	testImplementation('org.junit.jupiter:junit-jupiter')
}

test {
	useJUnitPlatform()
	testLogging {
		events "passed", "skipped", "failed"
	}
}
```

## 2. Writeing Tests

```java
import static org.junit.jupiter.api.Assertions.assertEquals;

import example.util.Calculator;

import org.junit.jupiter.api.Test;

class MyFirstJUnitJupiterTests {

    private final Calculator calculator = new Calculator();

    @Test
    void addition() {
        assertEquals(2, calculator.add(1, 1));
    }

}
```

### 2.1. Annotations  
org.junit.jupiter.api 에서 제공하는 주요 어노테이션 리스트  
|Annotation|Description|
|---|---|
|@Test|테스트 메소드임을 나타냅니다. JUnit 4의 @Test주석과 달리 이 주석은 어떠한 속성도 선언하지 않습니다. 왜냐하면 JUnit Jupiter의 테스트 확장은 자체 전용 주석을 기반으로 작동하기 때문입니다. 이러한 메소드는 재정의되지 않는 한 상속됩니다.|
|@ParameterizedTest|매개변수화된 테스트임을 나타냅니다. 이러한 메소드는 재정의되지 않는 한 상속 됩니다.|
|@RepeatedTest|반복 테스트를 위한 테스트 템플릿임을 나타냅니다. 이러한 메소드는 재정의되지 않는 한 상속 됩니다.|
|@TestFactory|동적 테스트를 위한 테스트 팩토리임을 나타냅니다. 이러한 메소드는 재정의되지 않는 한 상속 됩니다.|
|@TestTemplate|메소드는 등록된 공급자가 반환한 호출 컨텍스트 수에 따라 여러 번 호출되도록 설계된 테스트 사례용 템플릿 임을 나타냅니다. 이러한 메소드는 재정의되지 않는 한 상속 됩니다.|
|@TestClassOrder|테스트 클래스 내 중첩클래스를 위한 클래스 실행 순서를 구성하는데 사용됩니다.|
|@TestMethodOrder| 테스트 메서드 실행 순서를 구성하는 데 사용됩니다. JUnit4의 @FixMethodOrder 와 유사합니다.|
|@TestInstance|테스트 클래스의 테스트 인스턴스 수명 주기를 구성하는 데 사용됩니다. 이러한 주석은 상속 됩니다.|
|@DisplayName|테스트 클래스 또는 테스트 메서드에 대한 사용자 정의 표시 이름을 선언합니다. 이러한 주석은 상속 되지 않습니다.|
|@DisplayNameGeneration|테스트 클래스에 대한 사용자 정의 표시 이름 생성기를 선언합니다. 이러한 주석은 상속 됩니다.|
|@BeforeEach|현재 클래스의 @Test, @RepeatedTest, @ParameterizedTest, @TestFactory 메서드 이전에 실행되어야 함을 나타냅니다. JUnit4의 @Before와 유사합니다.이러한 메서드는 재정의 되거나 대체되지 않는 한 상속됩니다 (즉, Java의 가시성 규칙에 관계없이 서명만을 기준으로 대체됨).|
|@AfterEach|현재 클래스의 @Test, @RepeatedTest, @ParamedterizedTest, @TestFactory 메서드 다음에 메서드가 실행되어야 함을 나타냅니다. JUnit4의 @After와 유사합니다. 이러한 메서드는 재정의 되거나 대체되지 않는 한 상속됩니다(즉, Java의 가시성 규칙에 관계없이 서명만을 기준으로 대체됨).|
|@BeforeAll|현재 클래스의 모든 @Test, @RepeatedTest, @ParameterizedTest 및 @TestFactory 메서드 보다 먼저 실행되어야 함을 나타냅니다. JUnit4의 @BeforeClass와 유사합니다 . 이러한 메서드는 숨겨지거나 재정의 되거나 대체되지 않는 한 상속 되며(즉, Java의 가시성 규칙에 관계없이 서명만을 기반으로 교체됨) "클래스별" 테스트 인스턴스 수명 주기가 사용되지 않는 한 상속되어야 합니다.|
|@AfterAll|현재 클래스의 모든 @Test, @RepeatedTest, @ParameterizedTest 및 @TestFactory 메소드 이후에 실행되어야 함을 나타냅니다. JUnit4의 @AfterClassd와 유사합니다. 이러한 메서드는 숨겨지거나 재정의 되거나 대체되지 않는 한 상속 되며(즉, Java의 가시성 규칙에 관계없이 서명만을 기반으로 교체됨) "클래스별" 테스트 인스턴스 수명 주기가 사용되지 않는 한 상속되어야 합니다.|
@Nested|비정적 중첩 테스트 클래스임을 나타냅니다. Java 8부터 Java 15까지에서는 "클래스별" 테스트 인스턴스 수명 주기를 사용하지 않는 한 @BeforeAll과 @AfterAll 메서드를 직접 사용할 수 없습니다 . Java 16부터는 테스트 인스턴스 수명 주기 모드를 사용하여 static 처럼 선언할 수 있습니다. 이러한 주석은 상속 되지 않습니다.|
|@Tag|클래스 또는 메소드 수준에서 테스트 필터링을 수행하기 위한 태그를 선언하는 데 사용됩니다. 테스트 그룹이나 JUnit4의 카테고리와 유사합니다. 이러한 주석은 클래스 수준에서는 상속 되지만 메서드 수준에서는 상속되지 않습니다.|
|@Disabled|테스트 클래스나 테스트 메서드를 비활성화하는데 사용됩니다. JUnit4의 @Ignore와 유사합니다. 이러한 주석은 상속 되지 않습니다.|
|@Timeout|실행이 지정된 기간을 초과하는 경우 테스트, 테스트 팩토리, 테스트 템플릿 또는 수명 주기 메서드를 실패시키는 데 사용됩니다. 이러한 주석은 상속 됩니다.|
|@ExtendWith|선언적으로 확장을 등록하는데 사용됩니다. 이러한 주석은 상속 됩니다.|
|@RegisterExtension|필드를 통해 프로그래밍 방식으로 확장을 등록하는 데 사용됩니다. 이러한 필드는 숨겨지지 않는 한 상속 됩니다.|
|@TempDir|수명 주기 메소드 또는 테스트 메소드에서 필드 삽입 또는 매개변수 삽입을 통해 임시 디렉토리를 제공하는데 사용됩니다. 패키지 위치 org.junit.jupiter.api.io.|

### 2.2. Definitions  
* Platform Concepts
    - Container   
        다른 컨테이너나 테스트를 하위 항목으로 포함하는 테스트 트리 노드입니다.(예. test class)  
    - Test  
        실행 시 예상되는 동작을 확인하는 테스트 트리의 노드입니다.(예. test method)  

* Jupiter Concepts    
    - Lifecycle Method(수명주기 메서드)  
        @BeforeAll, @AfterAll, @BeforeEach또는 로 직접 주석이 추가되거나 메타 주석이 추가되는 메소드입니다 @AfterEach.
    - Test Class  
        최상위 클래스, static 멤버 클래스 또는 하나 이상의 테스트 메소드를 포함하는 @Nested 중첩 클래스입니다. 
        테스트 클래스는 추상 클래스가 아니어야 하며, 단일 생성자를 가져야 합니다.  
    - Test Method(테스트 메서드)  
        @Test, @RepeatedTest, @ParameterizedTest, @TestFactory또는 @TestTemplate, 직접 주석이 추가되거나 메타 주석이 추가되는 모든 인스턴스 메서드입니다.


### 2.3. Test Classes and Methods  
테스트 메서드와 수명 주기 메서드는 현재 테스트 클래스 내에서 로컬로 선언되거나, 슈퍼클래스에서 상속되거나, 인터페이스에서 상속될 수 있습니다(테스트 인터페이스 및 기본 메서드 참조). 
또한 테스트 메서드와 수명 주기 메서드는 abstract 여서는 안 되며, 반환 값을 가지면 안 됩니다.( 예외로 @TestFactory와 같이 값을 반환하는 메서드 제외).

> 클래스 및 메서드 가시성
테스트 클래스, 테스트 메소드 및 수명 주기 메소드는 반드시 public 이어야 할 필요는 없지만 private은 아니어야 합니다.

> 기술적인 이유가 없는 한(예: 테스트 클래스가 다른 패키지의 테스트 클래스에 의해 확장되는 경우) 일반적으로 테스트 클래스, 테스트 메서드 및 수명 주기 메서드에 대한 수정자를 생략하는 것이 좋습니다. 또 다른 기술적인 이유는 Java 모듈 시스템을 사용할 때 모듈 경로에 대한 테스트를 단순화하기 위한 것입니다.

다음 테스트 클래스는 @Test 메서드 사용과 모든 수명 주기 메서드를 보여줍니다.  
```java
import static org.junit.jupiter.api.Assertions.fail;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.Test;

class StandardTests {

    @BeforeAll
    static void initAll() {
    }

    @BeforeEach
    void init() {
    }

    @Test
    void succeedingTest() {
    }

    @Test
    void failingTest() {
        fail("a failing test");
    }

    @Test
    @Disabled("for demonstration purposes")
    void skippedTest() {
        // not executed
    }

    @Test
    void abortedTest() {
        assumeTrue("abc".contains("Z"));
        fail("test should have been aborted");
    }

    @AfterEach
    void tearDown() {
    }

    @AfterAll
    static void tearDownAll() {
    }

}
```

### 2.4. DisplayName  
테스트 클래스와 테스트 메서드는 @DisplayName를 이용해 공백, 특수 문자, 심지어 이모티콘을 사용하여 테스트 보고서와 테스트 실행기 및 IDE에 표시되는 사용자 지정 표시 이름을 선언할 수 있습니다.

#### 2.4.1. DisplayNameGeneration  
메서드마다 이름을 설정하지 않고 규칙 기반으로 이름을 설정할 수 있는 @DisplayNameGeneration의 사용을 지원한다.   
*@DisplayName 은 DisplayNameGeneration 보다 우선한다.*  

Jupiter에서 사용할 수 있는 기본 기능은 다음과 같습니다.  
|DisplayNameGenerator|Action|
|---|---|
|Standard| 표준 표시 이름 생성 동작과 일치합니다.|
|Simple|메소드의 후행 괄호를 제거(매개변수가 없는)합니다.|
|ReplaceUnderscores|밑줄을 공백으로 바꿉니다.|
|IndicativeSentences|테스트 이름과 바깥쪽 클래스 이름을 연결하여 완전한 문장을 생성합니다.|

```java
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.DisplayNameGeneration;
import org.junit.jupiter.api.DisplayNameGenerator;
import org.junit.jupiter.api.DisplayNameGenerator.ReplaceUnderscores;
import org.junit.jupiter.api.IndicativeSentencesGeneration;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

class DisplayNameGeneratorDemo {

    @Nested
    @DisplayNameGeneration(DisplayNameGenerator.ReplaceUnderscores.class)
    class A_year_is_not_supported {

        @Test
        void if_it_is_zero() {
        }

        @DisplayName("A negative value for year is not supported by the leap year computation.")
        @ParameterizedTest(name = "For example, year {0} is not supported.")
        @ValueSource(ints = { -1, -4 })
        void if_it_is_negative(int year) {
        }

    }

    @Nested
    @IndicativeSentencesGeneration(separator = " -> ", generator = ReplaceUnderscores.class)
    class A_year_is_a_leap_year {

        @Test
        void if_it_is_divisible_by_4_but_not_by_100() {
        }

        @ParameterizedTest(name = "Year {0} is a leap year.")
        @ValueSource(ints = { 2016, 2020, 2048 })
        void if_it_is_one_of_the_following_years(int year) {
        }

    }

}
```

결과 
```
+-- DisplayNameGeneratorDemo [OK]
  +-- A year is not supported [OK]
  | +-- A negative value for year is not supported by the leap year computation. [OK]
  | | +-- For example, year -1 is not supported. [OK]
  | | '-- For example, year -4 is not supported. [OK]
  | '-- if it is zero() [OK]
  '-- A year is a leap year [OK]
    +-- A year is a leap year -> if it is divisible by 4 but not by 100. [OK]
    '-- A year is a leap year -> if it is one of the following years. [OK]
      +-- Year 2016 is a leap year. [OK]
      +-- Year 2020 is a leap year. [OK]
      '-- Year 2048 is a leap year. [OK]
```

#### 2.4.2. Default DisplayNameGenerator Setup  
src/test/resources/junit-platform.properties 파일 설정을 통해 이름 생성기를 설정할 수 있다.  
```properties
junit.jupiter.displayname.generator.default = \
    org.junit.jupiter.api.DisplayNameGenerator$ReplaceUnderscores
```

### 2.5. Assertions  
JUnit4의 많은 Assertion 메서드를 제공하며 Java 8의 람다를 활용한 몇가지가 추가되었다.  
Jupiter 의 모든 Assertion 메서드는 static 이다.  
```java
import static java.time.Duration.ofMillis;
import static java.time.Duration.ofMinutes;
import static org.junit.jupiter.api.Assertions.assertAll;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTimeout;
import static org.junit.jupiter.api.Assertions.assertTimeoutPreemptively;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.concurrent.CountDownLatch;

import example.domain.Person;
import example.util.Calculator;

import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

class AssertionsDemo {

    private final Calculator calculator = new Calculator();

    private final Person person = new Person("Jane", "Doe");

    @Test
    void standardAssertions() {
        assertEquals(2, calculator.add(1, 1));
        assertEquals(4, calculator.multiply(2, 2),
                "The optional failure message is now the last parameter");
        assertTrue('a' < 'b', () -> "Assertion messages can be lazily evaluated -- "
                + "to avoid constructing complex messages unnecessarily.");
    }

    @Test
    void groupedAssertions() {
        // In a grouped assertion all assertions are executed, and all
        // failures will be reported together.
        assertAll("person",
            () -> assertEquals("Jane", person.getFirstName()),
            () -> assertEquals("Doe", person.getLastName())
        );
    }

    @Test
    void dependentAssertions() {
        // Within a code block, if an assertion fails the
        // subsequent code in the same block will be skipped.
        assertAll("properties",
            () -> {
                String firstName = person.getFirstName();
                assertNotNull(firstName);

                // Executed only if the previous assertion is valid.
                assertAll("first name",
                    () -> assertTrue(firstName.startsWith("J")),
                    () -> assertTrue(firstName.endsWith("e"))
                );
            },
            () -> {
                // Grouped assertion, so processed independently
                // of results of first name assertions.
                String lastName = person.getLastName();
                assertNotNull(lastName);

                // Executed only if the previous assertion is valid.
                assertAll("last name",
                    () -> assertTrue(lastName.startsWith("D")),
                    () -> assertTrue(lastName.endsWith("e"))
                );
            }
        );
    }

    @Test
    void exceptionTesting() {
        Exception exception = assertThrows(ArithmeticException.class, () ->
            calculator.divide(1, 0));
        assertEquals("/ by zero", exception.getMessage());
    }

    @Test
    void timeoutNotExceeded() {
        // The following assertion succeeds.
        assertTimeout(ofMinutes(2), () -> {
            // Perform task that takes less than 2 minutes.
        });
    }

    @Test
    void timeoutNotExceededWithResult() {
        // The following assertion succeeds, and returns the supplied object.
        String actualResult = assertTimeout(ofMinutes(2), () -> {
            return "a result";
        });
        assertEquals("a result", actualResult);
    }

    @Test
    void timeoutNotExceededWithMethod() {
        // The following assertion invokes a method reference and returns an object.
        String actualGreeting = assertTimeout(ofMinutes(2), AssertionsDemo::greeting);
        assertEquals("Hello, World!", actualGreeting);
    }

    @Test
    void timeoutExceeded() {
        // The following assertion fails with an error message similar to:
        // execution exceeded timeout of 10 ms by 91 ms
        assertTimeout(ofMillis(10), () -> {
            // Simulate task that takes more than 10 ms.
            Thread.sleep(100);
        });
    }

    @Test
    void timeoutExceededWithPreemptiveTermination() {
        // The following assertion fails with an error message similar to:
        // execution timed out after 10 ms
        assertTimeoutPreemptively(ofMillis(10), () -> {
            // Simulate task that takes more than 10 ms.
            new CountDownLatch(1).await();
        });
    }

    private static String greeting() {
        return "Hello, World!";
    }

}
```
> 선제적 시간 초과 assertTimeoutPreemptively()  
Assertions 클래스의 assertTimeoutPreemptively()메서드는 executable or supplier에서 제공되는 스레드(테스트 코드와 다른)에서 실행된다. 
이 동작은 스레드 저장소에 의존하는 경우 바람직하지 않은 부작용을 초래할 수 있습니다.
이에 대한 예는 Spring Framework의 트랜잭션 테스트입니다. 
Spring의 테스트에서는 테스트 메서드가 호출되기 전에 트랜잭션 상태를 현재 스레드에 바인딩합니다(ThreadLocal을 통해).??   
ThreadLocal 스토리지에 의존하는 다른 프레임워크에서도 비슷한 부작용이 발생할 수 있습니다.

#### 2.5.1. 타사 Assertions 사용  
테스트 작성 시 더 많은 기능을 사용하고자 타사 Assertion을 사용할 수 있다. 
AssertJ, Hamcrest, Truth 등과 같은 타사 라이브러리의 사용이 가능
다음은 Hamcrest 사용 예시 
```java
import static org.hamcrest.CoreMatchers.equalTo;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;

import example.util.Calculator;

import org.junit.jupiter.api.Test;

class HamcrestAssertionsDemo {

    private final Calculator calculator = new Calculator();

    @Test
    void assertWithHamcrestMatcher() {
        assertThat(calculator.subtract(4, 1), is(equalTo(3)));
    }

}
```
*JUnit4 기반으로 하는 레거시 테스트에서는 org.junit.Assert#assertThat.*

### 2.6. Assumptions  
JUnit4가 제공하는 Assumptions 메소드의 하위 세트와 함께 Java 8 람다 표현식 및 메소드 참조와 함께 사용하기에 적합한 몇 가지가 추가되었다.  
org.junit.jupiter.api.Assumptions클래스의 정적 메소드  

```java
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assumptions.assumeTrue;
import static org.junit.jupiter.api.Assumptions.assumingThat;

import example.util.Calculator;

import org.junit.jupiter.api.Test;

class AssumptionsDemo {

    private final Calculator calculator = new Calculator();

    @Test
    void testOnlyOnCiServer() {
        assumeTrue("CI".equals(System.getenv("ENV")));
        // remainder of test
    }

    @Test
    void testOnlyOnDeveloperWorkstation() {
        assumeTrue("DEV".equals(System.getenv("ENV")),
            () -> "Aborting test: not on developer workstation");
        // remainder of test
    }

    @Test
    void testInAllEnvironments() {
        assumingThat("CI".equals(System.getenv("ENV")),
            () -> {
                // perform these assertions only on the CI server
                assertEquals(2, calculator.divide(4, 2));
            });

        // perform these assertions in all environments
        assertEquals(42, calculator.multiply(6, 7));
    }

}
```

### 2.7. Disabling Tests  
테스트 클래스, 테스트 메서드를 @Disabled 를 이용해 비활성화 할 수 있다.  

테스트 클래스 비활성화 
```java
import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.Test;

@Disabled("Disabled until bug #99 has been fixed")
class DisabledClassDemo {

    @Test
    void testWillBeSkipped() {
    }

}
```

테스트 메서드 비활성화  
```java
import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.Test;

class DisabledTestsDemo {

    @Disabled("Disabled until bug #42 has been resolved")
    @Test
    void testWillBeSkipped() {
    }

    @Test
    void testWillBeExecuted() {
    }

}
```
> @Disabled을 주석(설명) 없이 설정 가능하다. 그러나 비활성화된 이유에 대해서 다른 개발자에게 제공할 것을 권장한다.  

> @Disabled는 상속되지 않는다. 슈퍼클래스가 인 클래스를 비활성화하려면 하위 클래스에 대해서 @Disabled를 다시 선언해야 한다.    


### 2.8. Conditional Test Execution    
Jupiter의 확장 API를 사용하면 개발자는 컨테이너의 활성화 또는 비활성화를 특정 조건을 기반으로 프로그래밍 방식으로 작성하여 테스트할 수 있습니다.  

#### 2.8.1 운영체제, 아키텍처 조건 : @EnabledOnOs  
운영체제  
```java
@Test
@EnabledOnOs(MAC)
void onlyOnMacOs() {
    // ...
}

@TestOnMac
void testOnMac() {
    // ...
}

@Test
@EnabledOnOs({ LINUX, MAC })
void onLinuxOrMac() {
    // ...
}

@Test
@DisabledOnOs(WINDOWS)
void notOnWindows() {
    // ...
}

@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
@Test
@EnabledOnOs(MAC)
@interface TestOnMac {
}
```
아키텍처  
```java
@Test
@EnabledOnOs(architectures = "aarch64")
void onAarch64() {
    // ...
}

@Test
@DisabledOnOs(architectures = "x86_64")
void notOnX86_64() {
    // ...
}

@Test
@EnabledOnOs(value = MAC, architectures = "aarch64")
void onNewMacs() {
    // ...
}

@Test
@DisabledOnOs(value = MAC, architectures = "aarch64")
void notOnNewMacs() {
    // ...
}
```

#### 2.8.2. Java Runtime Condition : @EnabledOnJre / @DisabledOnJre   
```java
@Test
@EnabledOnJre(JAVA_8)
void onlyOnJava8() {
    // ...
}

@Test
@EnabledOnJre({ JAVA_9, JAVA_10 })
void onJava9Or10() {
    // ...
}

@Test
@EnabledForJreRange(min = JAVA_9, max = JAVA_11)
void fromJava9to11() {
    // ...
}

@Test
@EnabledForJreRange(min = JAVA_9)
void fromJava9toCurrentJavaFeatureNumber() {
    // ...
}

@Test
@EnabledForJreRange(max = JAVA_11)
void fromJava8To11() {
    // ...
}

@Test
@DisabledOnJre(JAVA_9)
void notOnJava9() {
    // ...
}

@Test
@DisabledForJreRange(min = JAVA_9, max = JAVA_11)
void notFromJava9to11() {
    // ...
}

@Test
@DisabledForJreRange(min = JAVA_9)
void notFromJava9toCurrentJavaFeatureNumber() {
    // ...
}

@Test
@DisabledForJreRange(max = JAVA_11)
void notFromJava8to11() {
    // ...
}
```

#### 2.8.3. Native Image(GraalVM)  
컨테이너 네이티브 이미지 생성으로 컨테이너(GraalVM) 내부에서 테스트를 실행해야 하는 경우  
```java
@Test
@EnabledInNativeImage
void onlyWithinNativeImage() {
    // ...
}

@Test
@DisabledInNativeImage
void neverWithinNativeImage() {
    // ...
}
```

#### 2.8.4. Envirionments Condition  
```java
@Test
@EnabledIfEnvironmentVariable(named = "ENV", matches = "staging-server")
void onlyOnStagingServer() {
    // ...
}

@Test
@DisabledIfEnvironmentVariable(named = "ENV", matches = ".*development.*")
void notOnDeveloperWorkstation() {
    // ...
}
```

#### 2.8.5. 그 외 방법과 사용자 정의 방법  
조건을 직접 작성하거나, 외부의 도움을 받는 방법  
```java
@Test
@EnabledIf("customCondition")
void enabled() {
    // ...
}

@Test
@DisabledIf("customCondition")
void disabled() {
    // ...
}

boolean customCondition() {
    return true;
}
```

```java
package example;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIf;

class ExternalCustomConditionDemo {

    @Test
    @EnabledIf("example.ExternalCondition#customCondition")
    void enabled() {
        // ...
    }

}

class ExternalCondition {

    static boolean customCondition() {
        return true;
    }

}
```

### 2.9. Tagging and Filtering  
테스트 클래스와 메서드에는 @Tag주석을 통해 태그를 지정할 수 있습니다. 이러한 태그는 나중에 테스트 검색 및 실행을 필터링하는 데 사용될 수 있습니다.  

```java
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

@Tag("fast")
@Tag("model")
class TaggingDemo {

    @Test
    @Tag("taxes")
    void testingTaxCalculation() {
    }

}
```

### 2.10. Test Execution Order  
#### 2.10.1. 실행 순서 설정  
실제 단위 테스트는 일반적으로 실행 순서에 의존해서는 안 되지만 특정 테스트 메서드 실행 순서를 적용해야 하는 경우가 있습니다. 
실행 순서 지정 방법은 사용자 직접 설정과 MethodOrderer에서 제공되는 방법 중 하나를 사용할 수 있습니다.

* MethodOrderer.DisplayName  
    표시 이름(displayname)을 기준으로 테스트 방법을 영숫자순으로 정렬합니다.  
* MethodOrderer.MethodName  
    이름과 공식 매개변수 목록을 기준으로 영숫자순으로 테스트 방법을 정렬합니다.  
* MethodOrderer.OrderAnnotation  
    @Order를 통해 지정된 값을 기준으로 정렬합니다.  
* MethodOrderer.Random  
    테스트 방법을 무작위로 사용자 정의 시드 구성을 지원합니다.  

Order를 이용한 실행 순서 지정   
```java
import org.junit.jupiter.api.MethodOrderer.OrderAnnotation;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;

@TestMethodOrder(OrderAnnotation.class)
class OrderedTestsDemo {

    @Test
    @Order(1)
    void nullValues() {
        // perform assertions against null values
    }

    @Test
    @Order(2)
    void emptyValues() {
        // perform assertions against empty values
    }

    @Test
    @Order(3)
    void validValues() {
        // perform assertions against valid values
    }

}
```

> 환경 설정에서 기본 실행 순서 설정 방법  
junit.jupiter.testmethod.order.default = \
    org.junit.jupiter.api.MethodOrderer$OrderAnnotation

### 2.11. Test Instance Lifecycle  
기본적으로 개별 테스트 메서드를 독립적으로 실행할 수 있도록 하고, 예기치 않은 부작용(에러)으로 
테스트 인스턴스의 상태가 변경되는 것을 방지하기 위해 JUnit은 각 테스트 메서드를 실행하기 전에 
테스트 클래스의 새 인스턴스를 만듭니다.  

그러나 필요에 따라 모드를 설정하여 '클래스별', '메서드별' 인스턴스를 생성하도록 설정할 수 있습니다.

@TestInstance(Lifecycle.PER_CLASS) 왼쪽과 같이 설정 시 테스트 클래스당 한 번씩 새 테스트 인스턴스가 생성된다.
이 모드에서는 조심해야 할 부분은 테스트 메서드가 인스턴스 변수에 저장된 상태(인스턴스 변수)에 의존하는 경우 
@BeforeEach또는 @AfterEach메서드에서 해당 상태를 재설정해야 할 수도 있습니다.  

"클래스별" 모드는 기본 "메서드별" 모드에 비해 몇 가지 추가 이점이 있습니다. 특히, "클래스별" 모드를 사용하면 
인터페이스 메서드뿐만 아니라 비정적 메서드에서도 @BeforeAll선언이 가능해집니다. 따라서 "클래스별" 모드를 사용하면 
@Nested 테스트 클래스에서도 사용할 수 있습니다.(코틀린과 관계가 많은 부분이라고 생각됨)  

#### 2.11.1 인스턴스 기본 수명 주기 설정 방법     
JUnit Jupiter는 인스턴스 수명 주기(@TestInstance) 설정이 없으면 기본적으로 '메서드 별' 수명주기를 따르도록 되어 있다.  

> JVM 파라미터를 설정 방법   
-Djunit.jupiter.testinstance.lifecycle.default=per_class 

src/test/resources/junit-platform.properties 파일 설정  
> 환경 설정 파일 설정 방법  
junit.jupiter.testinstance.lifecycle.default = per_class  


### 2.12. Nested Tests  
@Nested를 이용한 중첩 클래스 구조는 여러 테스트 그룹 간의 관계를 표현하는 방법과 함께 많은 기능을 제공합니다.
테스트 구조에 대한 계층적 사고를 촉진

중첩 테스트를 이용한 계층 구조 예제
```java
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.EmptyStackException;
import java.util.Stack;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

@DisplayName("A stack")
class TestingAStackDemo {

    Stack<Object> stack;

    @Test
    @DisplayName("is instantiated with new Stack()")
    void isInstantiatedWithNew() {
        new Stack<>();
    }

    @Nested
    @DisplayName("when new")
    class WhenNew {

        @BeforeEach
        void createNewStack() {
            stack = new Stack<>();
        }

        @Test
        @DisplayName("is empty")
        void isEmpty() {
            assertTrue(stack.isEmpty());
        }

        @Test
        @DisplayName("throws EmptyStackException when popped")
        void throwsExceptionWhenPopped() {
            assertThrows(EmptyStackException.class, stack::pop);
        }

        @Test
        @DisplayName("throws EmptyStackException when peeked")
        void throwsExceptionWhenPeeked() {
            assertThrows(EmptyStackException.class, stack::peek);
        }

        @Nested
        @DisplayName("after pushing an element")
        class AfterPushing {

            String anElement = "an element";

            @BeforeEach
            void pushAnElement() {
                stack.push(anElement);
            }

            @Test
            @DisplayName("it is no longer empty")
            void isNotEmpty() {
                assertFalse(stack.isEmpty());
            }

            @Test
            @DisplayName("returns the element when popped and is empty")
            void returnElementWhenPopped() {
                assertEquals(anElement, stack.pop());
                assertTrue(stack.isEmpty());
            }

            @Test
            @DisplayName("returns the element when peeked but remains not empty")
            void returnElementWhenPeeked() {
                assertEquals(anElement, stack.peek());
                assertFalse(stack.isEmpty());
            }
        }
    }
}
```

예제 실행 결과
```
- Test Results
  - A Stack
      is instantiated with new Stack()
    - when new
        throws EmptyStackException when peeked
        throws EmptyStackException when popped
        is empty
      - after pushing an element
          returns the element when peeked but remains not empty
          returns the element when popped and is empty
          it is no longer empty
```
이 예에서는 설정 코드에 대한 계층적 수명 주기 메서드를 정의하여 외부 테스트의 전제 조건이 내부 테스트에 사용됩니다.
예로 @BeforeEach 는 테스트 클래스와 중첩 테스트 클래스 모두에서 사용되는 수명 주기 메서드이다.

> 비정적 중첩 클래스는 분리되어 동작할 수 있다. 중첩 클래스 사용 시 주의할 부분은 @BeforeAll 과 @AfterAll 메서드를 
기본적으로 사용할 수 없다는 점이다. 사용을 원한다면 수명 주기 설정을 '클래스별'로 설정하거나, Java 16버전 이상을 
사용해야 한다.  

### 2.13. Dependency injection for Constructors and Methods  
이전 JUnit 버전에서는 테스트 생성자 또는 메소드에 매개변수가 허용되지 않았습니다.
JUnit Jupiter의 주요 변경 사항 중 하나로 이제 테스트 생성자와 메서드 모두 매개 변수를 가질 수 있습니다. 
이를 통해 유연성이 향상되고 생성자와 메서드에 대한 종속성 주입이 가능해집니다.  

ParameterResolver는 런타임 시 매개변수를 동적으로 설정할 수 있는 테스트 확장 API이다. 
테스트 클래스 생성자, 테스트 메서드 또는 수명 주기 메서드가 매개 변수를 설정하려는 경우
ParameterResolver에 등록하여 런타임에서 확인될 수 있도록 해야 합니다.  

기본으로 제공되는 파라미터 사용 방법 세가지  
* TestInfoParameterResolver   
생성자 또는 메서드 매개 변수로 TestInfo를 사용하여 현재 컨테이너에 해당하는 인스턴스 정보를 제공.
제공되는 정보는 표시 이름(displayname), 테스트 클래스, 테스트 메서드 및 태그(tag)와 같은 현재 컨테이너 또는 테스트에 대한 정보.
```java
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestInfo;

@DisplayName("TestInfo Demo")
class TestInfoDemo {

    TestInfoDemo(TestInfo testInfo) {
        assertEquals("TestInfo Demo", testInfo.getDisplayName());
    }

    @BeforeEach
    void init(TestInfo testInfo) {
        String displayName = testInfo.getDisplayName();
        assertTrue(displayName.equals("TEST 1") || displayName.equals("test2()"));
    }

    @Test
    @DisplayName("TEST 1")
    @Tag("my-tag")
    void test1(TestInfo testInfo) {
        assertEquals("TEST 1", testInfo.getDisplayName());
        assertTrue(testInfo.getTags().contains("my-tag"));
    }

    @Test
    void test2() {
    }

}
```

* RepetitionExtension  
@RepeatedTest, @BeforeEach, @AfterEach의 매개변수로 RepetitionInfo를 사용하여 RepetitionExtension 인스턴스 정보를 제공.
제공되는 정보는 현재 반복, 총 반복 횟수, 실패한 반복 횟수 및 실패 임계값
@RepeatedTest 예제는 반복 테스트에서 확인 바랍니다.

* TestReporterParameterResolver  
매개변수 TestReporter 유형인 경우 TestReporterParameterResolver의 인스턴스 정보를 제공.
TestReporters는 현재 테스트 실행에 대한 추가 데이터를 게시하는데 사용할 수 있다.
TestReporters의 데이터는 TestExecutionListener의 reportingEntryPublished() 메서드를 통해 소비되거나, 보고서에 포함된다. 

JUnit Jupiter에서 TestReporter를 JUnit4에서 stdout, stderr를 이용해 정보를 인쇄하듯이 사용해야 한다. 
@RunWith(JUnitPlatform.class) 사용 시 모든 테스트 리포트를 stdout으로 출력할 수 있다. 

```java
class TestReporterDemo {

    @Test
    void reportSingleValue(TestReporter testReporter) {
        testReporter.publishEntry("a status message");
    }

    @Test
    void reportKeyValuePair(TestReporter testReporter) {
        testReporter.publishEntry("a key", "a value");
    }

    @Test
    void reportMultipleKeyValuePairs(TestReporter testReporter) {
        Map<String, String> values = new HashMap<>();
        values.put("user name", "dk38");
        values.put("award year", "1974");

        testReporter.publishEntry(values);
    }

}
```

다음은 ParameterResolver 를 사용한 사용자 정의 예시로 RandomParametersExtension 예제이다.
높은 수준의 예시는 아니지만 매개변수 확장과 매개변수 확인 프로세스 모두의 단순성과 표현력을 보여줍니다.

```java
@ExtendWith(RandomParametersExtension.class)
class MyRandomParametersTest {

    @Test
    void injectsInteger(@Random int i, @Random int j) {
        assertNotEquals(i, j);
    }

    @Test
    void injectsDouble(@Random double d) {
        assertEquals(0.0, d, 1.0);
    }

}
```

실제 사용사례는 MockitoExtension과 SpringExtension 에서 확인 가능하다.


### 2.14. Test Interfaces and Deault Methods    
Jupiter에서는 default 인터페이스 메서드에 @Test, @RepeatedTest, @ParameterizedTest, @TestFactory, 
@TestTemplate, @BeforeEach를 선언할 수 있습니다. @BeforeAll과 @AfterAll의 경우 static 메서드 or default 메서드 or
수명 주기가 '클래스별(TestInstance(Lifecycle.PER_CLASS)로 설정된 테스트 클래스의 인터페이스에 설정될 수 있다. 

```java
@TestInstance(Lifecycle.PER_CLASS)
interface TestLifecycleLogger {

    static final Logger logger = Logger.getLogger(TestLifecycleLogger.class.getName());

    @BeforeAll
    default void beforeAllTests() {
        logger.info("Before all tests");
    }

    @AfterAll
    default void afterAllTests() {
        logger.info("After all tests");
    }

    @BeforeEach
    default void beforeEachTest(TestInfo testInfo) {
        logger.info(() -> String.format("About to execute [%s]",
            testInfo.getDisplayName()));
    }

    @AfterEach
    default void afterEachTest(TestInfo testInfo) {
        logger.info(() -> String.format("Finished executing [%s]",
            testInfo.getDisplayName()));
    }

}
```

```java
interface TestInterfaceDynamicTestsDemo {

    @TestFactory
    default Stream<DynamicTest> dynamicTestsForPalindromes() {
        return Stream.of("racecar", "radar", "mom", "dad")
            .map(text -> dynamicTest(text, () -> assertTrue(isPalindrome(text))));
    }

}
```

@Tag와 @ExtendWith을 자동으로 상속되도록 설정이 가능.
```java
@Tag("timed")
@ExtendWith(TimingExtension.class)
interface TimeExecutionLogger {
}
```

구현 클래스에서 인터페이스들을 적용할 수 있다.
```java
class TestInterfaceDemo implements TestLifecycleLogger,
        TimeExecutionLogger, TestInterfaceDynamicTestsDemo {

    @Test
    void isEqualValue() {
        assertEquals(1, "a".length(), "is always equal");
    }

}
```

실행 시 출력 결과 
```
INFO  example.TestLifecycleLogger - Before all tests
INFO  example.TestLifecycleLogger - About to execute [dynamicTestsForPalindromes()]
INFO  example.TimingExtension - Method [dynamicTestsForPalindromes] took 19 ms.
INFO  example.TestLifecycleLogger - Finished executing [dynamicTestsForPalindromes()]
INFO  example.TestLifecycleLogger - About to execute [isEqualValue()]
INFO  example.TimingExtension - Method [isEqualValue] took 1 ms.
INFO  example.TestLifecycleLogger - Finished executing [isEqualValue()]
INFO  example.TestLifecycleLogger - After all tests
```


### 2.15. Repeated Tests  
Jupiter는 메소드에 @RepeatedTest 어노테이션을 달아 원하는 총 반복 횟수를 지정하여 지정된 횟수만큼 
테스트를 반복하는 기능을 제공합니다. 반복되는 테스트의 각 호출은 동일한 수명 주기 콜백 및 확장을 완벽하게 
지원하는 일반 메서드 실행처럼 동작합니다.

다음 예제에서는 자동으로 10번 반복되는 테스트를 선언하는 방법을 보여줍니다.
```java
@RepeatedTest(10)
void repeatedTest() {
    // ...
}
```
Jupiter 5.10부터는 @RepeatedTest실패 횟수를 나타내는 실패 임계값으로 구성할 수 있으며 이후 남은 반복은 
자동으로 건너뜁니다. 지정된 실패 횟수가 발생한 후 나머지 반복 호출을 건너뛰려면 failureThreshold 속성을 총 반복 
횟수보다 작은 양수로 설정하십시오.

예를들어 @RepeatedTest를 사용하여 불안정하다고 의심되는 테스트를 반복적으로 호출하는 경우 단일 실패만으로도 
테스트가 불안정하다는 것을 입증할 수 있으며 나머지 반복을 호출할 필요가 없습니다. 
사용 사례에 따라 임계값을 1보다 큰 숫자로 설정할 수도 있습니다. failureThreshold = 1

기본적으로 failureThreshold 은 Integer.MAX_VALUE로 설정되어 실패 임계값이 적용되지 않습니다. 
이는 반복 실패 여부에 관계없이 지정된 반복 횟수가 호출된다는 의미입니다.

> @RepeatedTest를 테스트하는데 병렬로 실행되는 경우 실패 임계값에 관해 보장할 수 없습니다. 
따라서 병렬 실행을 구성할 때 @RepeatedTest메서드에 @Excution(SAME_THREAD) 주석을 추가하는 것이 좋습니다. 
자세한 내용은 병렬 실행을 참조하세요.  

반복 횟수 및 실패 임계값을 지정하는 것 외에도 name 속성을 통해 각 반복에 대해 사용자 정의 표시 이름을 구성할 수 있습니다.
- {displayName}: @RepeatedTest메소드 의 표시 이름
- {currentRepetition}: 현재 반복 횟수
- {totalRepetitions}: 총 반복 횟수

테스트 리포트 외 코드 내에서 검색할 수 있도록 메서드 매개변수로 RepetitionInfo를 사용할 수 있습니다.   

#### 2.15.1. Repeated Test Examples  
```
INFO: About to execute repetition 1 of 10 for repeatedTest
INFO: About to execute repetition 2 of 10 for repeatedTest
INFO: About to execute repetition 3 of 10 for repeatedTest
INFO: About to execute repetition 4 of 10 for repeatedTest
INFO: About to execute repetition 5 of 10 for repeatedTest
INFO: About to execute repetition 6 of 10 for repeatedTest
INFO: About to execute repetition 7 of 10 for repeatedTest
INFO: About to execute repetition 8 of 10 for repeatedTest
INFO: About to execute repetition 9 of 10 for repeatedTest
INFO: About to execute repetition 10 of 10 for repeatedTest
INFO: About to execute repetition 1 of 5 for repeatedTestWithRepetitionInfo
INFO: About to execute repetition 2 of 5 for repeatedTestWithRepetitionInfo
INFO: About to execute repetition 3 of 5 for repeatedTestWithRepetitionInfo
INFO: About to execute repetition 4 of 5 for repeatedTestWithRepetitionInfo
INFO: About to execute repetition 5 of 5 for repeatedTestWithRepetitionInfo
INFO: About to execute repetition 1 of 8 for repeatedTestWithFailureThreshold
INFO: About to execute repetition 2 of 8 for repeatedTestWithFailureThreshold
INFO: About to execute repetition 3 of 8 for repeatedTestWithFailureThreshold
INFO: About to execute repetition 4 of 8 for repeatedTestWithFailureThreshold
INFO: About to execute repetition 1 of 1 for customDisplayName
INFO: About to execute repetition 1 of 1 for customDisplayNameWithLongPattern
INFO: About to execute repetition 1 of 5 for repeatedTestInGerman
INFO: About to execute repetition 2 of 5 for repeatedTestInGerman
INFO: About to execute repetition 3 of 5 for repeatedTestInGerman
INFO: About to execute repetition 4 of 5 for repeatedTestInGerman
INFO: About to execute repetition 5 of 5 for repeatedTestInGerman
```

```
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.fail;

import java.util.logging.Logger;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.RepeatedTest;
import org.junit.jupiter.api.RepetitionInfo;
import org.junit.jupiter.api.TestInfo;

class RepeatedTestsDemo {

    private Logger logger = // ...

    @BeforeEach
    void beforeEach(TestInfo testInfo, RepetitionInfo repetitionInfo) {
        int currentRepetition = repetitionInfo.getCurrentRepetition();
        int totalRepetitions = repetitionInfo.getTotalRepetitions();
        String methodName = testInfo.getTestMethod().get().getName();
        logger.info(String.format("About to execute repetition %d of %d for %s", //
            currentRepetition, totalRepetitions, methodName));
    }

    @RepeatedTest(10)
    void repeatedTest() {
        // ...
    }

    @RepeatedTest(5)
    void repeatedTestWithRepetitionInfo(RepetitionInfo repetitionInfo) {
        assertEquals(5, repetitionInfo.getTotalRepetitions());
    }

    @RepeatedTest(value = 8, failureThreshold = 2)
    void repeatedTestWithFailureThreshold(RepetitionInfo repetitionInfo) {
        // Simulate unexpected failure every second repetition
        if (repetitionInfo.getCurrentRepetition() % 2 == 0) {
            fail("Boom!");
        }
    }

    @RepeatedTest(value = 1, name = "{displayName} {currentRepetition}/{totalRepetitions}")
    @DisplayName("Repeat!")
    void customDisplayName(TestInfo testInfo) {
        assertEquals("Repeat! 1/1", testInfo.getDisplayName());
    }

    @RepeatedTest(value = 1, name = RepeatedTest.LONG_DISPLAY_NAME)
    @DisplayName("Details...")
    void customDisplayNameWithLongPattern(TestInfo testInfo) {
        assertEquals("Details... :: repetition 1 of 1", testInfo.getDisplayName());
    }

    @RepeatedTest(value = 5, name = "Wiederholung {currentRepetition} von {totalRepetitions}")
    void repeatedTestInGerman() {
        // ...
    }

}
```

```
├─ RepeatedTestsDemo ✔
│  ├─ repeatedTest() ✔
│  │  ├─ repetition 1 of 10 ✔
│  │  ├─ repetition 2 of 10 ✔
│  │  ├─ repetition 3 of 10 ✔
│  │  ├─ repetition 4 of 10 ✔
│  │  ├─ repetition 5 of 10 ✔
│  │  ├─ repetition 6 of 10 ✔
│  │  ├─ repetition 7 of 10 ✔
│  │  ├─ repetition 8 of 10 ✔
│  │  ├─ repetition 9 of 10 ✔
│  │  └─ repetition 10 of 10 ✔
│  ├─ repeatedTestWithRepetitionInfo(RepetitionInfo) ✔
│  │  ├─ repetition 1 of 5 ✔
│  │  ├─ repetition 2 of 5 ✔
│  │  ├─ repetition 3 of 5 ✔
│  │  ├─ repetition 4 of 5 ✔
│  │  └─ repetition 5 of 5 ✔
│  ├─ repeatedTestWithFailureThreshold(RepetitionInfo) ✔
│  │  ├─ repetition 1 of 8 ✔
│  │  ├─ repetition 2 of 8 ✘ Boom!
│  │  ├─ repetition 3 of 8 ✔
│  │  ├─ repetition 4 of 8 ✘ Boom!
│  │  ├─ repetition 5 of 8 ↷ Failure threshold [2] exceeded
│  │  ├─ repetition 6 of 8 ↷ Failure threshold [2] exceeded
│  │  ├─ repetition 7 of 8 ↷ Failure threshold [2] exceeded
│  │  └─ repetition 8 of 8 ↷ Failure threshold [2] exceeded
│  ├─ Repeat! ✔
│  │  └─ Repeat! 1/1 ✔
│  ├─ Details... ✔
│  │  └─ Details... :: repetition 1 of 1 ✔
│  └─ repeatedTestInGerman() ✔
│     ├─ Wiederholung 1 von 5 ✔
│     ├─ Wiederholung 2 von 5 ✔
│     ├─ Wiederholung 3 von 5 ✔
│     ├─ Wiederholung 4 von 5 ✔
│     └─ Wiederholung 5 von 5 ✔
```

### 2.16. Parameterized Tests  
매개변수를 이용한 테스트작성 시 직접 코딩 없이 다양한 인수를 사용하여 테스트를 여러 번 실행할 수 있습니다. 
일반 메소드의 @Test 대신 @ParameterizedTest 주석을 사용합니다. 또한 각 호출에 대한 인수를 제공하고 
테스트 메서드에서 인수를 사용할 소스를 하나 이상 선언해야 합니다.

다음 예에서는 @ParameterizedTest, @ValueSource를 사용하여 매개변수를 이용한 테스트를 보여줍니다.

```java
@ParameterizedTest
@ValueSource(strings = { "racecar", "radar", "able was I ere I saw elba" })
void palindromes(String candidate) {
    assertTrue(StringUtils.isPalindrome(candidate));
}
```

위의 매개변수화된 테스트 메서드를 실행할 때 각 호출은 별도로 보고됩니다. 
예를들어 ConsoleLauncher는 다음과 유사한 출력을 인쇄합니다.
```
palindromes(String) ✔ 
├─ [1] Candidate=racecar ✔ 
├─ [2] Candidate=radar ✔ 
└─ [3] Candidate=able was I ere I saw elba ✔
```

#### 2.16.1. Parameterized Test 사용 필수 설정 
매개변수화된 테스트를 사용하려면 junit-jupiter-params아티팩트에 대한 종속성을 추가해야 합니다.
```
group : org.junit.jupiter
artifact : junit-jupiter-params
version : ....
```

#### 2.16.2. 매개변수(인수) 소비(Consuming)  
매개변수를 이용한 테스트 방법은 다음 규칙에 따라 매개변수를 선언해야 합니다.  
- 0개 이상의 색인화된 인수를 선언해야 합니다.
- 0개 이상의 집계자를 선언해야 합니다.
- a에서 제공하는 0개 이상의 인수는 ParameterResolver 마지막에 선언되어야 합니다.??

#### 2.16.3. 매개변수 전달 방법  
* @ValueSource  
    가장 간단한 방법 중 하나. 이를 통해 리터럴 값의 단일 배열을 지정할 수 있으며, 
    테스트 호출 당 하나의 인수를 제공 가능. 
    - short  
    - byte  
    - int  
    - long  
    - float  
    - double  
    - char  
    - boolean  
    - java.lang.String  
    - java.lang.Class  

* Null 및 Empty Source  
    Null이거나 비어있는 입력을 테스트할 수 있음. 
    @NullSource, @EmptySource, @NullAndEmptySource  
    ```java
    @ParameterizedTest
    @NullSource
    @EmptySource
    @ValueSource(strings = { " ", "   ", "\t", "\n" })
    void nullEmptyAndBlankStrings(String text) {
        assertTrue(text == null || text.trim().isEmpty());
    }

    @ParameterizedTest
    @NullAndEmptySource
    @ValueSource(strings = { " ", "   ", "\t", "\n" })
    void nullEmptyAndBlankStrings(String text) {
        assertTrue(text == null || text.trim().isEmpty());
    }
    ```
    위 예제는 총 6번의 호출이 발생하며, Null, Empty, 그리고 ValueSource의 데이터 4개를 이용해 호출 됨.

* @EnumSource  
    @EnumSource 는 Enum 상수를 사용하는 편리한 방법을 제공합니다.
    ```java
    @ParameterizedTest
    @EnumSource(ChronoUnit.class)
    void testWithEnumSource(TemporalUnit unit) {
        assertNotNull(unit);
    }
    ```
    @EnumSource의 value속성은 선택사항으로 생략하는 경우 첫번째 매개 변수가 사용됩니다. 따라서 위 예에서는 
    메소드 매개변수가 선언되었기 때문에 속성이 필요합니다. 즉, 열거형 유형이 아닌 TemporalUnit으로 구현된 인터페이스 입니다. 
    ChronoUnit메소드 매개변수 유형을 변경하면 ChronoUnit다음과 같이 주석에서 명시적인 열거형 유형을 생략할 수 있습니다.
    ```java
    @ParameterizedTest
    @EnumSource
    void testWithEnumSourceWithAutoDetection(ChronoUnit unit) {
        assertNotNull(unit);
    }
    ```

    주석은 names다음 예와 같이 사용할 상수를 지정할 수 있는 선택적 속성을 제공합니다. 생략하면 모든 상수가 사용됩니다.
    ```java
    @ParameterizedTest
    @EnumSource(names = { "DAYS", "HOURS" })
    void testWithEnumSourceInclude(ChronoUnit unit) {
        assertTrue(EnumSet.of(ChronoUnit.DAYS, ChronoUnit.HOURS).contains(unit));
    }
    ```
    다음은 다양한 상수 지정 방법 예제이다.
    ```java
    @ParameterizedTest
    @EnumSource(mode = EXCLUDE, names = { "ERAS", "FOREVER" })
    void testWithEnumSourceExclude(ChronoUnit unit) {
        assertFalse(EnumSet.of(ChronoUnit.ERAS, ChronoUnit.FOREVER).contains(unit));
    }

    @ParameterizedTest
    @EnumSource(mode = MATCH_ALL, names = "^.*DAYS$")
    void testWithEnumSourceRegex(ChronoUnit unit) {
        assertTrue(unit.name().endsWith("DAYS"));
    }
    ```
* MethodSource  
테스트 클래스 또는 외부 클래스의 팩토리 메소드를 하나 이상 참조할 수 있습니다.  
테스트 클래스에 @TestInstance(Lifecycle.PER_CLASS)이 달린 경우를 제외하고 테스트 클래스 내
팩토리 메소드는 static 이어야 한다. 반면, 외부 클래스의 팩토리 메소드는 항상 static 이어야 합니다.  

단일 매개변수만 필요한 경우 예제
```java
@ParameterizedTest
@MethodSource("stringProvider")
void testWithExplicitLocalMethodSource(String argument) {
    assertNotNull(argument);
}

static Stream<String> stringProvider() {
    return Stream.of("apple", "banana");
}
```

### 2.17. Test Templates  
JUnit5 레퍼런스 문서를 참고  

### 2.18. Dynamic Tests  
JUnit5 레퍼런스 문서를 참고  

### 2.19. Timeouts  
JUnit5 레퍼런스 문서를 참고  

### 2.20. Parallel Execution  
JUnit5 레퍼런스 문서를 참고  

### 2.21. Built-in Extensions  
JUnit5 레퍼런스 문서를 참고  
