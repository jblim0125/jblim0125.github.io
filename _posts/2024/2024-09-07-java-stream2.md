---
layout: post
title: java stream operations 2
author: jblim0125
date: 2024-09-07
category: 2024
---

### 고급 Stream 예제

여러 스트림 작업을 결합하면 강력하고 간결한 코드가 나올 수 있습니다.
여기서는 간단한 `Employee`모델을 기반으로 하는 Java Stream API를 사용하여 몇 가지 문제와 이러한 문제에 대한 솔루션을 제시하겠습니다.

```java
public class Advanced {
    enum Gender {
        MALE, FEMALE
    }

    record Employee(String name, int age, int salary, Gender gender) {
    }

    public static void main(String[] args) {
        Employee employee1 = new Employee("John", 20, 2000, Gender.MALE);
        Employee employee2 = new Employee("Jane", 28, 2000, Gender.FEMALE);
        Employee employee3 = new Employee("Alex", 38, 2750, Gender.MALE);
        Employee employee4 = new Employee("Mary", 35, 3500, Gender.FEMALE);
        Employee employee5 = new Employee("Pedro", 40, 3100, Gender.MALE);

        List<Employee> employees = List.of(employee1, employee2, employee3, employee4, employee5);
  
        // ...
    }

}
```

1. 25세 이상 남성 직원의 총 급여는 얼마입니까?  

    `filter` 를 통해 25세 이상의 남성 직원을 필터링한 다음 그들의 급여`salary`를 `mapToDouble`을 이용해 매핑합니다.
    그런 다음 `sum`을 이용해 필터링된 직원의 총 급여를 계산합니다.  

    ```java
    double summed = employees
            .stream()
            .filter(employee -> employee.gender.equals(Gender.MALE) && employee.age > 25)
            .mapToDouble(Employee::salary)
            .sum();
    assert summed == 2750 + 3100;
    ```

2. '제인'이라는 이름의 30세 미만의 여성 직원이 있습니까?  

    우리는 `filter` 연산을 사용하여 여성이고 30세 미만인 직원만 포함하도록 직원을 필터링합니다.
    그런 다음 람다 표현식 `anyMatch` 을 사용하여 필터링된 직원 중 "Jane"이라는 이름을 가진 직원이 있는지 확인합니다.  

    ```java
    boolean existsFemaleEmployeeWithName = employees
            .stream()
            .filter(employee -> employee.gender.equals(Gender.FEMALE) && employee.age < 30)
            .anyMatch(employee -> employee.name.equals("Jane"));
    assert existsFemaleEmployeeWithName;
    ```

3. 모든 직원의 총 급여 예산은 얼마입니까?  

    우리는 먼저 `map` 연산을 사용하여 각 직원 급여를 매핑?합니다.
    그런 다음 `reduce` 연산을 사용하여 초기값 `0`부터 시작하여 모든 급여를 합산합니다.  

    ```java
    Integer totalSalaryBudget = employees
            .stream()
            .map(Employee::salary)
            .reduce(0, Integer::sum);
    assert totalSalaryBudget == 2000 + 2000 + 2750 + 3500 + 3100;
    ```

4. 직원들 사이에서 가장 높은 급여를 받는 상위 3명은 누구입니까?  

    먼저 `map` 을 이용해 각 직원의 급여를 매핑, 이를 `sorted` 를 이용해 내림차순으로 정렬,
    `limit` 을 이용해 상위 3명으로 필터링합니다.  

    ```java
    List<Integer> top3HighestSalaries = employees
            .stream()
            .map(Employee::salary)
            .sorted(Comparator.reverseOrder())
            .limit(3)
            .toList();
    assert List.of("Mary", "Alex", "Pedro").equals(top3HighestSalaries);
    ```

5. 직원들 사이에서 가장 높은 급여 3개는 무엇인가요?  

    먼저 `map` 을 이용해 각 직원의 급여를 매핑, 이를 `sorted` 를 이용해 내림차순으로 정렬,
    `distinct`를 이용해 중복제거, `limit` 을 이용해 상위 3개로 필터링합니다.  

    ```java
    List<Integer> top3HighestSalaries = employees
            .stream()
            .map(Employee::salary)
            .sorted(Comparator.reverseOrder())
            .distinct()
            .limit(3)
            .toList();
    assert List.of(3500, 3100, 2750).equals(top3HighestSalaries);
    ```

6. 21세 이상 근로자의 성별별 총 급여는 얼마인가요?

    우리는 직원을 연령 기준에 따라 분류하고, 성별에 따라 그룹화하여 총 급여를 계산합니다.

    ```java
    Map<Gender, Integer> genderToTotalSalaryMap = employees
            .stream()
            .filter(employee -> employee.age >= 21)
            .collect(Collectors.groupingBy(Employee::gender, Collectors.summingInt(Employee::salary)));
    assert genderToTotalSalaryMap.get(Gender.MALE) == 2750 + 3100;
    assert genderToTotalSalaryMap.get(Gender.FEMALE) == 2000 + 3500;
    ```

이러한 질문은 일상 업무에서 마주치는 정확한 시나리오를 반영하지 않을 수 있지만 충분히 유사합니다.
이러한 간단한 작업을 처리하는 방법을 숙달함으로써 스트림을 사용하여 더 복잡한 문제를 손쉽게 해결할 수 있는 기술을 빠르게 구축할 수 있습니다.  

### 스트림에 대한 5가지 재미있는 사실

**스트림을 사용** 하면 여러 작업을 체인으로 묶을 수 있습니다.  

```java
List<String> words = Arrays.asList("apple", "banana", "cat", "dog");

long count = words.stream()             // Make a stream
    .filter(word -> word.length() > 3)  // 길이가 3보다 큰 단어 
    .map(String::toUpperCase)           // 선택된 단어들을 대문자로 변환
    .count();                           
```

이는 데이터의 컨베이어 벨트와 같으며, 각 단계가 데이터에 대해 서로 다른 작업을 수행합니다.

* Lazy Evaluation  
    결과가 필요할 때까지 스트림에서 아무 일도 일어나지 않습니다. 스트림의 각 단계는 필요할 때만 발생하여 시간과 리소스를 절약합니다.

    ```java
    List<Integer> numbers = Arrays.asList(5, 12, 8, 3, 15, 20);

    Integer result = numbers.stream()
        .filter(n -> n % 2 == 0)    // Only even numbers
        .filter(n -> n > 10)        // Only numbers greater than 10
        .findFirst()                // Find the first matching number
        .orElse(null);              // Return null if no match
    ```

    필터링은 즉시 수행되지 않습니다. 필터링 조건을 설정하지만 스트림이 소비되거나 터미널 작업이 적용될 때까지 기다립니다.  

* Parallel Processing  
    스트림은 자동으로 여러 스레드를 사용하여 작업을 더 빠르게 수행할 수 있습니다.

    ```java
    List<Integer> numbers = Arrays.asList( 1 , 2 , 3 , 4 , 5 , 6 , 7 , 8 , 9 , 10 ); 

    int  sum  = numbers.parallelStream() // 병렬로 처리
        .mapToInt(n -> n)               // IntStream으로 변환
        .sum();                         // 모든 숫자를 더함
    ```

    매핑, 필터링, 축소와 같이 병렬화할 수 있는 작업의 성능을 크게 향상시킬 수 있습니다.
    > 하지만 결과가 손상되지 않도록 어떤 작업을 병렬화할지 신중하게 결정해야 합니다.

* Immutable Data  
    스트림을 만든 후에는 변경할 수 없습니다.  

    ```java
    List<String> names = Arrays.asList( "Alice" , "Bob" , "Charlie" ); 

    List<String> upperCaseNames = names.stream()    // 스트림을 만듭니다
        .map(String::toUpperCase)                  // 모든 이름을 대문자로 만듭니다
        .collect(Collectors.toList());             // 새 목록으로 수집합니다.
    ```

    스트림에서 각 작업이 새 스트림을 만듭니다. 이렇게 하면 데이터를 안전하게 보관하고 코드를 더 쉽게 이해할 수 있습니다.

* Optional  
    스트림은 종종 잠재적으로 존재하지 않는 값을 처리하기 위해 함께 사용됩니다.  

    ```java
    Optional<String> firstFruit = fruits.stream()   // 스트림 만들기
        .findFirst();                               // 첫 번째 fruit 찾기
    ```

    `findFirst` 연산은 Optional 처리가 가능,
    스트림의 첫 번째 요소를 반환하거나 스트림이 비어 있으면 빈 데이터를 반환합니다.
    이렇게 하면 null 값을 우아하게 처리할 수 있습니다.

스트림 연산을 사용하여 문제를 처리하는 방법이 1개 이상인 경우가 있으므로 창의적으로 생각하고
고유한 솔루션을 가지고 놀아보세요. 연습은 기술을 다듬는 데 중요하므로 다양한 조합과 시나리오를 직접 실험해보시길 권장합니다.

물론, 이 튜토리얼은 스트림에 대한 포괄적인 가이드가 되기 위한 것이 아닙니다. 탐구할 것이 많은 심오한 주제이며,
마스터하려면 시간이 걸립니다.
