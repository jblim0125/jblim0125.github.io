---
layout: post
title: java stream operations
author: jblim0125
date: 2024-08-30
category: 2024
---

## Java Stream

* Java 8 부터 추가된 컬렉션(Collection) 형태의 데이터를 람다를 이용해 간결하고 직관적으로 처리할 수 있게 해 준다.
* `for`, `while` 등을 이용한 기존 코드들을 대체할 수 있다.
* 쉽게 병렬 처리를 할 수 있게 해 준다.

### Stream Pipeline(구조)

스트림 파이프라인은 크게 세 가지로 구성되어 있다.  
컬렉션으로 들어온 데이터들이 여러 개의 중간 처리 과정을 거쳐 종결처리된다.  
자세한 예시는 뒤에서 확인할 수 있다.  

* Source (소스)  
    스트림 파이프라인의 시작점으로, 스트림을 생성하는 데이터 소스를 의미합니다.
    일반적으로 컬렉션, 배열, 파일, I/O 채널 또는 정수 범위 등이 소스가 될 수 있습니다.
    스트림은 이러한 소스로부터 데이터를 받아 처리하며, 스트림의 소스는 변경되지 않으며 데이터의 순차적 또는 병렬적 처리를 지원합니다.

    예시:

    ```java
    // 컬렉션
    List<String> list = Arrays.asList("a", "b", "c");  
    Stream<String> stream = list.stream();  
    // 배열
    String[] array = {"a", "b", "c"};  
    Stream<String> stream = Arrays.stream(array);  
    // 정수 범위
    IntStream range = IntStream.range(1, 10);
    ```

* Intermediate Operations (중간 처리)  
    스트림의 요소들을 변환하거나 필터링하는 등의 작업을 수행하지만, 최종적으로 결과를 생성하지 않는 연산들입니다.
    중간 연산들은 모두 **lazy(지연 연산)**로, 최종 연산이 호출될 때까지 실제로 수행되지 않습니다.
    중간 연산은 연쇄적으로 호출할 수 있으며, 그 결과는 또 다른 스트림을 반환합니다.  

    주요 중간 연산들:  

        1. filter(Predicate): 조건에 맞는 요소만을 걸러냅니다.  
        2. map(Function): 요소를 다른 형태로 변환합니다.  
        3. flatMap(Function): 각 요소를 스트림으로 변환한 후 평면화합니다.  
        4. distinct(): 중복된 요소를 제거합니다.  
        5. sorted(): 요소를 정렬합니다.  
        6. limit(long): 스트림의 크기를 제한합니다.  
        7. skip(long): 앞의 요소들을 건너뜁니다.  

    이러한 중간 연산은 스트림을 원하는 형태로 가공하고, 최종 연산과 결합하여 효율적인 데이터 처리를 가능하게 합니다.  

* Terminal Operation (종결 처리)  
    데이터를 처리하고 최종 결과를 생성하는 연산들입니다.
    스트림 파이프라인의 마지막 단계에서 수행되며, 스트림을 소비하고 더 이상 사용할 수 없게 만듭니다.
    종료 연산이 호출되기 전까지는 중간 연산들이 실제로 수행되지 않습니다.  

    주요 종료 연산들:

        1. forEach(): 각 요소에 대해 작업을 수행합니다.  
        2. collect(): 스트림의 요소들을 컬렉션으로 수집합니다.  
        3. reduce(): 스트림의 요소들을 하나로 축약합니다.  
        4. count(): 스트림의 요소 개수를 반환합니다.  
        5. findFirst() / findAny(): 첫 번째 요소 또는 임의의 요소를 반환합니다.  
        6. allMatch() / anyMatch() / noneMatch(): 조건과 일치하는 요소가 있는지 확인합니다.  
        7. min() / max(): 최소 또는 최대 값을 찾습니다.  

    이러한 종료 연산은 스트림을 처리하고, 결과를 생성하거나 부수 효과를 발생시킵니다.

### Stream 예제와 설명  

1. `map`  
    `map`은 스트림의 각 요소에 함수를 적용하여 변환된 요소의 새로운 스트림을 생성하는 데 사용됩니다.  

    > 예제 : 연산을 사용하여 모든 애완동물 이름을 대문자로 변환하고, 대문자로 된 결과르 새 목록에 저장합니다.  

    ```java
    public void mapTest() {
        List<String> pets = List.of("Hamster", "Cat", "Dog");
        List<String> upperCaseNames = pets
                .stream()
                .map(String::toUpperCase)
                .toList();
        assert List.of("HAMSTER", "CAT", "DOG").equals(upperCaseNames);
    }
    ```

2. `filter`  
    지정된 조건에 따라 스트림에 요소를 선택적으로 포함시키는 데 사용됩니다.

    > 예 : `filter`를 사용하여 2로 나누어 떨어지는지 확인하는 람다 표현식을 적용하여, 짝수만 선택적으로 유지합니다.  

    ```java
    public void filterTest() {
        List<Integer> numbers = List.of(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
        List<Integer> evenNumbers = numbers
                .stream()
                .filter(number -> number % 2 == 0)
                .toList();
        assert List.of(2, 4, 6, 8, 10).equals(evenNumbers);
    }

3. `collect`  
    스트림의 요소를 `List`, `Set`, `Map`과 같은 컬렉션으로 축적합니다.
    ( 위에서 이미 이러한 수집기 중 하나를 사용했습니다 ).

    > 예: `collect`와 `Collectors.toSet`를 사용하여 과일 집합으로 변환하여 요소의 고유성을 보장할 수 있습니다.  

    ```java
    public void collectTest() {
        List<String> fruits = List.of("apple", "peach", "banana", "cherry", "banana", "peach");
        Set<String> fruitSet = fruits
                .stream()
                .collect(Collectors.toSet());
        assert fruitSet.size() == 4;
    }
    ```

4. `flatMap`  
    여러 스트림을 하나의 스트림으로 병합하여 중첩된 구조를 효과적으로 평면화하는데 사용됩니다.

    > 예 : 2개의 리스트를 포함하는 중첩된 리스트를 `flatMap`을 사용하여 단일 스트림으로 변환하여 중첩된 구조를 효과적으로 변환합니다. 결과 컬렉션에는 원래 중첩된 리스트의 모든 데이터가 포함됩니다.  

    ```java
    public void flatMapTest() {
        List<List<String>> shapes = List.of(
                List.of("triangle", "rectangle", "square"), // sharp forms
                List.of("circle", "ellipse", "cylinder") // rounded forms
        );

        List<String> flattenedShapes = shapes
                .stream()
                .flatMap(Collection::stream)
                .toList();

        assert flattenedShapes.size() == 6;
        assert List.of("triangle", "rectangle", "square", "circle", "ellipse", "cylinder").equals(flattenedShapes);
    }
    ```

5. `reduce`  
    누적 함수를 사용하여 스트림의 요소를 단일 결과로 결합하여 복잡한 계산을 단순화합니다.

    > 예 : 리스트에 있는 모든 숫자의 합을 계산하기 위해 `reduce` 연산을 적용합니다.
    > 초기 값은 0으로 설정되고, `Integer::sum`을 사용하여 합산을 수행합니다.  

    ```java
    public void reduceTest() {
        List<Integer> numbers = List.of(1, 2, 3, 4, 5);
        Integer sum = numbers
                .stream()
                .reduce(0, Integer::sum);
        assert sum == 15;
    }
    ```

6. `forEach`  
    스트림의 각 요소를 반복하여 작업을 수행할 수 있습니다.

    > 예 : `forEach`는 numbers 리스트의 각 요소를 반복합니다. 람다 표현식 내에서 각 숫자는 2로 곱해져 두 배의 값을 프린트합니다.  

    ```java
    public void forEachTest() {
        List<Integer> numbers = List.of( 1 , 2 , 3 , 4 , 5 ); 
        numbers.forEach(num -> System.out.println(num * 2 )); 
    }
    ```

7. `distinct`  
    스트림에서 중복된 요소를 제거하여 출력의 고유성을 보장합니다.

    > 예 : 연산을 체인화하여 중복 요소를 걸러내어 각 고유 번호가 결과 스트림에
    > 한 번만 나타나도록 합니다. 그런 다음 고유한 번호는 toList를 사용하여 
    > 새 리스에 저장합니다.  

    ```java
    public void distinctTest() {
        List<Integer> numbers = List.of(1, 2, 3, 4, 4, 4, 5);
        List<Integer> distinctNumbers = numbers
                .stream()
                .distinct()
                .toList();
        assert List.of(1, 2, 3, 4, 5).equals(distinctNumbers);
    }
    ```

8. `sort`  
    스트림의 요소를 자연스러운 순서나 사용자가 제공하는
    사용자 정의 비교자에 따라 정렬하는 데 사용됩니다.

    > 예 : `sorted`를 통해 숫자를 오름차순으로 정렬합니다.
    > 정렬된 숫자는 toList()를 통해 새 리스트로 저장됩니다.  

    ```java
    public void sortTest() {
        List<Integer> numbers = List.of(3, 1, 6, 8, 2, 4, 5, 9, 7);
        List<Integer> sorted = numbers
                .stream()
                .sorted()
                .toList();
        assert List.of(1, 2, 3, 4, 5, 6, 7, 8, 9).equals(sorted);
    }
    ```

9. `skip`  
    스트림 시작부분에서 지정된 개수의 요소를 건너뛸 수 있게 해주고, `limit`은 처리하고자 하는 최대 요소 개수를 지정할 수 있게 해줍니다.

    > 예 : `skip`을 사용하여 스트림의 처음 두 요소를 우회하여 세 번째 요소부터
    > 시작하는 새 스트림을 만듭니다. `limit`은 처음 세 요소로만 제한합니다.  

    ```java
    public void skipTest() {
        List<Integer> numbers = List.of(1, 2, 3, 4, 5);
        List<Integer> skipped = numbers
                .stream()
                .skip(2)
                .toList();
        assert List.of(3, 4, 5).equals(skipped);

        List<Integer> limited = numbers
                .stream()
                .limit(3)
                .toList();
        assert List.of(1, 2, 3).equals(limited);
    }
    ```

10. `anyMatch`, `nonMatch`, `allMatch`
    조건을 지정하고 `allMatch`[ 스트림에 있는 모든 항목 중 일치하는 항목이 있는지]
    `anyMatch`[일치하는 항목이 있는지] 또는 `nonMatch`[일치하는 항목이 없는지] 확인할 수 있습니다.

    > 예 : `anyMatch`, `noneMatch`, 및 `allMatch`을 사용하여 스트림의 요소들이 조건에
    > 만족하는지 확인합니다. 각 연산은 스트림에 연결되어 있어 조건을 효율적으로
    > 평가할 수 있습니다.  

    ```java
    public void matchTest() {
        List<Integer> numbers = List.of(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
        assert Boolean.TRUE.equals( // Is any of the numbers equal to 5?
                numbers
                .stream()
                .anyMatch(num -> num == 5)
        );
        assert Boolean.FALSE.equals( // Is any of the numbers equal to 15?
                numbers
                        .stream()
                        .anyMatch(num -> num == 15)
        );
        assert Boolean.TRUE.equals( // None of the numbers is equal to 15
                numbers
                        .stream()
                        .noneMatch(num -> num == 15)
        );
        assert Boolean.FALSE.equals( // None of the numbers is equal to 3
                numbers
                        .stream()
                        .noneMatch(num -> num == 3)
        );
        assert Boolean.TRUE.equals( // All of the numbers are greater than 0
                numbers
                        .stream()
                        .allMatch(num -> num > 0)
        );
        assert Boolean.FALSE.equals( // All of the numbers are even
                numbers
                        .stream()
                        .allMatch(num -> num % 2 == 0)
        );
    }
    ```

### 고급 Stream 예제

다음 시간에...