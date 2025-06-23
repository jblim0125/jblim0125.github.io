---
layout: post
title: JSONSchema 2 POJO Gradle
author: jblim0125
date: 2025-01-02
category: 2025
---

## 개요

OpenSource 를 살펴보던 중 JSONSchema2POJO를 활용해 사용하는 것을 보고 정리해보았다.

## JSONSchema2pojo

**jsonschema2pojo**는 JSON Schema 또는 JSON 데이터를 기반으로 Java POJO (Plain Old Java Object)를 자동으로 생성해주는 오픈 소스 도구입니다.
이 도구는 특히 REST API 개발, 데이터 모델링, 또는 JSON 데이터를 다루는 프로젝트에서 유용합니다.

### 주요 기능

1. JSON 또는 JSON Schema를 기반으로 Java 클래스 생성:
  • 입력으로 JSON Schema나 JSON 파일을 제공하면, 해당 데이터를 표현할 수 있는 Java 클래스를 생성합니다.
2. 다양한 애노테이션 지원:
  • Jackson 또는 GSON과 같은 라이브러리의 애노테이션(@JsonProperty, @SerializedName 등)을 추가해 직렬화 및 역직렬화에 적합한 클래스를 생성합니다.
3. JAXB 지원:
  • XML 바인딩을 위한 JAXB 애노테이션을 추가할 수도 있습니다.
4. 맞춤형 생성 설정:
  • 필드명, 메서드명 포맷 설정(예: camelCase, snake_case 등)
  • getter/setter 생성 여부
  • 생성자 포함 여부 설정 가능
5. Lombok 지원:
  • Lombok 애노테이션(@Data, @Getter, @Setter 등)을 활용해 코드 양을 줄일 수 있습니다.
6. 유효성 검사:
  • JSON Schema에서 정의된 제약조건(예: 필수 필드, 데이터 형식 등)을 Java 코드에 반영할 수 있습니다.  

### 사용 방법

1. 의존성 추가
    * maven  

      ```xml
      <plugin>
          <groupId>org.jsonschema2pojo</groupId>
          <artifactId>jsonschema2pojo-maven-plugin</artifactId>
          <version>1.1.2</version>
          <executions>
              <execution>
                  <goals>
                      <goal>generate</goal>
                  </goals>
              </execution>
          </executions>
          <configuration>
              <sourceDirectory>${project.basedir}/src/main/resources/schema</sourceDirectory>
              <targetPackage>com.example.generated</targetPackage>
          </configuration>
      </plugin>
      ```

    * gradle  

      ```kotlin
      plugins {
        id("java")
        id("org.jsonschema2pojo") version "1.2.2"
      }

      jsonSchema2Pojo {
        ...
      }
      ```

2. 명령어 실행:
    JSON Schema를 기반으로 Java 클래스를 생성합니다.
    * maven

      ```shell
      mvn jsonschema2pojo:generate
      ```

    * gradle

      ```shell
      gradle jsonschema2pojo
      ```

3. JSON Schema 입력:
schema 폴더에 JSON 파일 또는 JSON Schema 파일을 넣습니다.

4. 결과:
targetPackage 디렉토리에 Java POJO가 생성됩니다.

### 주요 옵션

• sourceType: 입력 파일 형식(JSON, JSON Schema 등)
• annotationStyle: 사용할 애노테이션 스타일(jackson, gson, none)
• includeConstructors: 생성자 포함 여부
• useLombokAnnotations: Lombok 애노테이션 사용 여부
• targetPackage: 생성될 Java 파일의 패키지명

### 예제

JSON Schema:

```json
{
  "type": "object",
  "properties": {
    "id": { "type": "integer" },
    "name": { "type": "string" },
    "email": { "type": "string", "format": "email" }
  },
  "required": ["id", "name"]
}
```

생성된 POJO:

```java
package com.example.generated;

import com.fasterxml.jackson.annotation.JsonProperty;

public class User {

    @JsonProperty("id")
    private Integer id;

    @JsonProperty("name")
    private String name;

    @JsonProperty("email")
    private String email;

    // Getters and setters
}
```

장점

1. 수작업 없이 데이터 모델을 자동으로 생성해 개발 시간 단축.
2. JSON 및 XML과의 호환성을 높여 API 개발을 단순화.
3. Jackson, Gson 등 라이브러리와 자연스럽게 통합 가능.

단점

1. JSON Schema가 복잡할 경우 생성된 클래스도 복잡해질 수 있음.
2. 기본 설정으로 생성된 클래스가 항상 이상적이지는 않을 수 있음(예: 커스터마이징 필요).

### 참고

* [jsonschema2pojo - wiki](https://github.com/joelittlejohn/jsonschema2pojo/wiki)

## Reference - 번역

### Schema Feature Support

|JSON Schema rule|Supported|Since|Note|
|---|---|---|---|
|type(Simple)|Yes|0.1.0||
|type(Union)|No|||
|properties|Yes|0.1.0||
|patternProperties|No|||
|additionalProperties|Yes|0.1.3||
|items|Yes|0.1.0||


| JSON Schema rule | Supported | Since | Note |
| --------------- |:---------:|:-----:|------|
| [type (Simple)](#type) | <font color="green">Yes</font> | 0.1.0 | |
| type (Union)| <font color="red">No</font> | | |
| [properties](#properties) | <font color="green">Yes</font> | 0.1.0 | |
| patternProperties | <font color="red">No</font> | | |
| [additionalProperties](#additionalproperties) | <font color="green">Yes</font> | 0.1.3 | |
| [items](#items) |  <font color="green">Yes</font> | 0.1.0 | |
| additionalItems | <font color="red">No</font> | | |
| [required](#required) | <font color="green">Yes</font> | 0.1.6 | |
| [optional](#optional) | <font color="green">Yes</font> | 0.1.0 | Deprecated |
| dependencies | <font color="red">No</font> | | |
| [minimum, maximum](#minimummaximum-minitemsmaxitems-pattern-minlengthmaxlength) | <font color="green">Yes</font> | 0.3.2 | Via optional JSR-303 annotations |
| exclusiveMinimum, exclusiveMaximum | <font color="red">No</font> | | |
| [minItems, maxItems](#minimummaximum-minitemsmaxitems-pattern-minlengthmaxlength) | <font color="green">Yes</font> | 0.3.2 |  Via optional JSR-303 annotations |
| [uniqueItems](#uniqueitems) | <font color="green">Yes</font> | 0.1.0 | |
| [pattern](#minimummaximum-minitemsmaxitems-pattern-minlengthmaxlength) | <font color="green">Yes</font> | 0.3.2 | Via optional JSR-303 annotations |
| [minLength, maxLength](#minimummaximum-minitemsmaxitems-pattern-minlengthmaxlength) | <font color="green">Yes</font> | 0.3.4 | Via optional JSR-303 annotations |
| [enum](#enum) | <font color="green">Yes</font> | 0.1.0 |
| [default](#default) | <font color="green">Yes</font> | 0.1.7 | |
| [title](#title) | <font color="green">Yes</font> | 0.1.6 | |
| [description](#description) | <font color="green">Yes</font> | 0.1.0 |
| [format](#format) | <font color="green">Yes</font> | 0.1.0 | |
| divisibleBy | <font color="red">No</font> | | |
| disallow | <font color="red">No</font> | | |
| [extends](#extends) | <font color="green">Yes</font> | 0.1.8 | |
| id | <font color="red">No</font> | | |
| [$ref](#ref) | <font color="green">Yes</font> | 0.1.6 | Supports absolute, relative, slash & dot delimited fragment paths, self-ref |
| $schema | <font color="red">No</font> | | |

### Type

JSONSchema 내 `type`을 다음과 같이 매핑합니다.

| Schema type | Java type |
| ----------- | --------- |
| `string` | `java.lang.String` |
| `number` | `java.lang.Double` |
| `integer` | `java.lang.Integer` |
| `boolean` | `java.lang.Boolean` |
| `object` | _generated Java type_ |
| `array` | `java.util.List` |
| `array` (with `"uniqueItems":true`) | `java.util.Set` |
| `null` | `java.lang.Object` |
| `any` | `java.lang.Object` |

`usePrimitives` 옵션을 적용할 경우, `double`, `integer`, `boolean` 기본형이 위의 wrapper type을 대체합니다.

### Properties

`properties` 내 각 속성은 `JavaBeans spec`에 따라 주어진 Java 클래스에 속성을 추가합니다.
부모 클래스에 `private` 필드가 추가되며, 이에 따른 접근자 메서드(getter, setter)가 추가됩니다.

E.g. json schema

```json
    {
        "type" : "object",
        "properties" : {
            "foo" : {
                "type" : "string"
            }
        }
    }
```

resulting Java type:

```java
    public class MyObject {
        private String foo;
        public String getFoo() {
           return foo;
        }
        public void setFoo(String foo) {
           this.foo = foo;
        }
    }
```

`generate-builders` 속성이 `true` 설정된 경우 빌더 메소드가 추가됩니다.  

```java
        public MyObject withFoo(String foo) {
            this.foo = foo;
            return this;
        }
```

이 빌더 메소드는 객체를 생성하고 초기화하는데 사용됩니다.

```java
    MyObject o = new MyObject().withFoo("foo").withBar("bar").withBaz("baz");
```

### AdditionalProperties

`additionalProperties`가 false 값으로 설정되는 경우 생성된 `Java Class` 는 추가 속성을 지원하지 않습니다.

`additionalProperties` 노드가 정의되지 않았거나(존재하지 않음) 비어 있는 경우
생성된 `Java Class`에서 `additionalProperties`라는 이름의 새 빈 속성이 Map<String,Object>으로 추가됩니다(적절한 접근자와 함께). 접근자는 Jackson이 JSON 데이터에서 발견된 인식되지 않은(추가) 속성을 이 맵에서/으로 마샬링/언마샬링할 수 있도록 주석이 달려 있습니다.

따라서 스키마 파일 myObject.json은 다음과 같습니다.

So, schema file myObject.json like:

```json
    {
        "type" : "object"
    }
```

or

```json
    {
        "type" : "object",
        "additionalProperties" : {}
    }
```

produces:

```java
    public class MyObject {
    
        private java.util.Map<String, Object> additionalProperties = new java.util.HashMap<String, Object>();
    
        @org.codehaus.jackson.annotate.JsonAnyGetter
        public java.util.Map<String, Object> getAdditionalProperties() {
            return this.additionalProperties;
        }
    
        @org.codehaus.jackson.annotate.JsonAnySetter
        public void setAdditionalProperties(String name, Object value) {
            this.additionalProperties.put(name, value);
        }
    
    }
```

`additionalProperties` 노드가 있고 스키마를 지정하는 경우 생성된 유형에 `additionalProperties` 맵이 추가되고 맵 값은 `additionalProperties` 스키마에 따라 제한됩니다.

So, schema file myObject.json like:

```json
    {
        "type" : "object",
        "additionalProperties" : {
            "type" : "number"
        }
    }
```

produces:

```java
    public class MyObject {
    
        private java.util.Map<String, Double> additionalProperties = new java.util.HashMap<String, Double>();
    
        @org.codehaus.jackson.annotate.JsonAnyGetter
        public java.util.Map<String, Double> getAdditionalProperties() {
            return this.additionalProperties;
        }
    
        @org.codehaus.jackson.annotate.JsonAnySetter
        public void setAdditionalProperties(String name, Double value) {
            this.additionalProperties.put(name, value);
        }
    
    }
```

`additionalProperties` 스키마가 유형을 지정하는 경우 `object`맵 값은 새로 생성된 `Java Class`의
인스턴스로 제한됩니다. 지정된 스키마가 속성을 지정하지 않으면 새로 생성된 유형의 이름은 부모 유형 이름과 접미사 'Property'에서 파생됩니다.

So, schema file myObject.json like:

```json
    {
        "type" : "object",
        "additionalProperties" : {
            "type" : "object"
        }
    }
```

produces:

```java
    public class MyObject {
    
        private java.util.Map<String, MyObjectProperty> additionalProperties = new java.util.HashMap<String, MyObjectProperty>();
    
        @org.codehaus.jackson.annotate.JsonAnyGetter
        public java.util.Map<String, MyObjectProperty> getAdditionalProperties() {
            return this.additionalProperties;
        }
    
        @org.codehaus.jackson.annotate.JsonAnySetter
        public void setAdditionalProperties(String name, MyObjectProperty value) {
            this.additionalProperties.put(name, value);
        }
    
    }
```

### Items

'items' 은 배열 스키마를 정의합니다.

So, this example JSON Schema:

```json
    {
        "type" : "object",
        "properties" : {
            "myArrayProperty" : {
                "type" : "array",
                "items" : {
                    "type" : "string"
                }
            }
        }
    }
```

Java 파일의 `myArrayProperty`라는 List<String> 속성을 생성합니다.
items 자체가 복합 유형("type" : "object")을 선언하는 경우 List 또는 Set의 제네릭 유형 자체가 생성된 유형이 됩니다.  예: `List<MyComplexType>`

### Required

'Required' 는 `Java Class`에 구조적 변경을 일으키지 않고, 단순히 (Required)필드,
`getter`, `setter`에 대한 텍스트가 JavaDoc에 추가되도록 합니다.

### Optional

`optional` 은 `Java Class`에 구조적 변경을 일으키지 않고, 단순히 (Optional)필드,
`getter`, `setter`에 대한 텍스트가 JavaDoc에 추가되도록 합니다.

이 스키마 규칙은 더 이상 사용되지 않습니다. `optional` 보다 `required`를 사용해야 합니다.

### UniqueItems

'array' 속성에 대해 `uniqueItems`을 `false`로 설정 하거나 완전히 생략하면
`Java Class`에서 `java.util.List`로 생성됩니다.  

`uniqueItems`을 `true`로 설정하면 `Java Class`에서 `java.util.Set`으로 생성됩니다.

### Enum

`jsonschema2pojo`가 `enum` 유형의 JSON 스키마 선언을 발견 하면 Java enum 유형을 생성합니다 .

`JSONSchema`의 `properties` 내 `enum`은 `Static Inner Class`로 생성됩니다.
`enum`이 루트에서 선언되면 단독 `Java Class` 형태로 생성됩니다. 

실제 'enum' 값은 내부의 'value' 속성에 보관됩니다. 생성된 `java class` 에서는 Jackson이
JSON 값을 올바르게 마샬링/언마샬링할 수 있도록 하는 주석도 포함되어 있습니다.
실제 값에 공백이 포함되어 있거나 숫자로 시작하거나 Java `enum` 이름의 일부가 될 수 없는
다른 문자가 포함되어 있어도 마찬가지입니다.

So, if we declare a schema myObject.json with an enum property:

```json
    {
        "type" : "object",
        "properties" : {
            "myEnum" : {
                "type" : "string",
                "enum" : ["one", "secondOne", "3rd one"]
            }
        }
    }
```

we see a generated MyObject Java type with an inner enum type like:

```java
    @Generated("com.googlecode.jsonschema2pojo")
    public static enum MyEnum {
    
        ONE("one"),
        SECOND_ONE("secondOne"),
        _3_RD_ONE("3rd one");
        private final String value;
    
        private MyEnum(String value) {
            this.value = value;
        }
    
        @JsonValue
        @Override
        public String toString() {
            return this.value;
        }
    
        @JsonCreator
        public static MyObject.MyEnum fromValue(String value) {
            for (MyObject.MyEnum c: MyObject.MyEnum.values()) {
                if (c.value.equals(value)) {
                    return c;
                }
            }
            throw new IllegalArgumentException(value);
        }
    
    }
```

### Default

`JSONSchema`에서 `default`를 사용하면 생성된 `Java Class`의 해당 속성이
기본값으로 초기화됩니다. 필드 선언 중에 기본값이 할당되는 것을 볼 수 있습니다.

`default`는 `JSONSchema`의 속성 string, integer, number및 boolean, enum 유형에 대해 지원됩니다.
`utc-millisec`과 `date-time` 의 `format`; 또는 `array`

일부 JSON 스키마 속성 정의와 해당 Java 필드 선언의 예는 다음과 같습니다.

| JSON Schema | Java |
| ------------- | ------- |
| `myString : { "type":"string", "default":"abc"}` | `private String myString = "abc";` |
| `myInteger : { "type":"integer", "default":"100"}` | `private Integer myInteger = 100;` |
| `myNumber : { "type":"number", "default":"10.3"}` | `private Double myNumber = 10.3D;` |
| `myMillis : { "type":"string", "format":"utc-millisec", "default":"500"}` | `private Long myMillis = 500L;` |
| `myDate : { "type":"string", "format":"date-time", "default":"500"}` | `private Date myDate = new Date(500L);` |
| `myDate : { "type":"string", "format":"date-time", "default":"2011-02-24T09:25:23.1.2.2000"}` | `private Date myDate = new Date(1298539523112L);` |
| `myList : { "type":"array", "default":["a","b","c"]}` | `private List<String> myList = new ArrayList<String>(Arrays.asList("a","b","c"));` |

위의 표에서 알 수 있듯이, 날짜는 epoch 이후의 밀리초 수나 날짜 문자열(ISO 8601 또는 RFC 1123)을
사용하여 기본값을 지정할 수 있습니다. 어느 경우든 날짜는 생성된 Java 유형의 밀리초 값을사용하여
초기화됩니다.

### Title

JSONSchema에서 속성에 추가한 `title` 은 해당 속성의 제목으로 JavaDoc에 추가되도록 합니다.
제목 항상 설명보다 먼저(앞에) 생성됩니다.

### Description

JSONSchema에서 속성에 추가한 `description` 은 해당 속성의 설명으로 JavaDoc에 추가되도록 합니다.
설명은 항상 제목 뒤에 생성됩니다.

### Format

JSONSchema에서 속성을 작성할 때 `format`을 사용하면 `Java Object Type`에 영향을 줄 수 있습니다.

예를 들어, JSON 파일에서 속성을 `string`으로 설정하고, `format`을 `uri`로 설정하면,
`java.lang.String` 대신 `java.net.URI` 으로 설정된다.


| Format value     | Java type        |
| ---------------- | ---------------- |
| `"date-time"`    | `java.util.Date` |
| `"date"`         | `String`         |
| `"time"`         | `String`         |
| `"utc-millisec"` | `long`           |
| `"regex"`        | `java.util.regex.Pattern` |
| `"color"`        | `String`         |
| `"style"`        | `String`         |
| `"phone"`        | `String`         |
| `"uri"`          | `java.net.URI`   |
| `"email"`        | `String`         |
| `"ip-address"`   | `String`         |
| `"ipv6"`         | `String`         |
| `"host-name"`    | `String`         |
| `"uuid"`         | `java.util.UUID` |
| anything else (unrecognised format) | type is unchanged |

### Extends

`JSONSchema`에서 extends 규칙이 발견되면(한 유형이 다른 유형을 확장함을 나타냄) 생성된 
`Java Class`와 관계가 생성됩니다. 해당 `extends` 값은 인라인으로 제공된 스키마이거나 `$ref`으로 연결될 수 있습니다.

As an example, lets imagine a file `flower.json` with the following content:

```json
    {
        "type" : "object"
    }
```

and a second file `rose.json` which contains: 

```json
    {
        "type" : "object",
        "extends" : {
            "$ref" : "flower.json"
        }
    }
```

The two resulting Java types generated from these schemas would be:

```java
    public class Flower {
        ....
    }
```

and 

```java
    public class Rose extends Flower {
        ....
    }
```

참고: JSON 스키마의 extends 규칙은 스키마 또는 스키마 배열을 허용합니다.
`jsonschema2pojo`는 단일 스키마 변형만 지원합니다.

### ref

'$ref' 규칙은 스키마가 예상되는 곳 어디에서나 사용할 수 있습니다. 즉, 스키마 문서의 루트,
속성 정의의 일부, 배열 유형에 대한 항목 정의의 일부, additionalProperties 정의의 일부로
사용할 수 있습니다.

지원되는 프로토콜:

* http://, https://  
* file://  
* classpath:, resource:, java: (클래스 경로에서 스키마를 확인하는 데 사용되는 모든 동의어).

참고: 현재 Maven 모듈에서 클래스 경로 리소스를 참조하려면 jsonschema2pojo를 이후 단계에
바인딩해야 합니다. 기본적으로 jsonschema2pojo는 바인딩되지만 generate-sources플러그인이
실행될 때 현재 모듈에 있는 리소스를 클래스 경로에 두려면 jsonschema2pojo를 process-resources
단계에 바인딩해야 합니다.

예를 들어, 같은 디렉토리에 있는 다른 문서를 참조해 'User' 개체의 정의를 제공하려면
다음과 같은 스키마를 만들 수 있습니다.

```json
    {
       "type" : "object",
       "properties" : {
          "loggedInUser" : {
              "$ref" : "user.json"
          }
       }
    }
```

jsonschema2pojo expects $ref values (URIs) to be URLs. Both absolute and relative URLs are valid. You may also refer to part of a schema document using the '#' character followed by a slash or dot delimited path.

`jsonschema2pojo`는 `$ref` 값(URI)이 URL이 되기를 기대합니다. `absolute URL`과 `relative URL`이
모두 유효합니다. '#' 문자 뒤에 슬래시나 점으로 구분된 경로를 사용하여 스키마 문서의 일부를
참조할 수도 있습니다.

Example using an absolute reference:

```json
    {
        "type" : "object",
        "properties" : {
            "address" : {
                "$ref" : "http://json-schema.org/address"
            }
        }
    }
```

Example using a fragment path to reuse a schema definition:

```json
    {
        "type" : "object",
        "properties" : {
            "child1" : {
                "type" : "string"
            },
            "child2" : {
               "$ref" : "#/properties/child1"
            }
        }
    }
```

Example treeNode.json using a self reference to build a tree:

```json
    {
       "description" : "Tree node",
       "type" : "object",
       "properties" : {
          "children" : {
             "type" : "array",
             "items" : {
                 "$ref" : "#"
             }
          }
       }
    }
```

which produces Java code similar to:

```java
    public class TreeNode {
    
       public List<TreeNode> getChildren() {...}
    
       public void setChildren(List<TreeNode> children) {...}
    
    }
```

### Minimum/Maximum MinItems/MaxItems Pattern MinLength/MaxLength

Maven 플러그인, CLI 및 Ant 태스크를 사용하면 구성 인수를 통해 JSR-303 주석을 활성화할 수 있습니다. 
활성화되면 다음 JSR-303 주석이 생성됩니다.

| Schema rule         | Annotation    |
| ------------------- | ------------- |
| maximum             | `@DecimalMax` |
| minimum             | `@DecimalMin` |
| minItems,maxItems   | `@Size`       |
| minLength,maxLength | `@Size`       |
| pattern             | `@Pattern`    |
| required            | `@NotNull`    |

Example using `minimum` with `BigDecimal`

```json
{
    "type" : "object",
    "properties" : {
        "minimum" : {
            "existingJavaType" : "java.math.BigDecimal",
            "minimum" : 1
        }
    }
}
```

## Extension

### JavaType

`jsonschema2pojo`는 `javaType`을 지원하며 생성된 Java 파일의 이름과 패키지 이름을 지정할 수 있게 해줍니다.

예를 들어, 다음과 같은 `fooBar.json` 스키마를 상상해 보세요.

```json
{
    "type" : "object"
}
```

패키지 인수로 `com.example` jsonschema2pojo를 호출하면 정규화된 이름은 com.example.FooBar .

`fooBar.json`에 `javaType` 속성이 다음과 같이 추가되면:

```json
{
    "javaType" : "com.other.package.CustomTypeName",
    "type" : "object"
}
```

그런 다음 `jsonschema2pojo`를 호출하면 `com.other.package.CustomTypeName`을 생성됩니다 

javaType 속성은 스키마 문서의 루트 스키마뿐만 아니라 모든 스키마 정의에 나타날 수 있습니다.
예를 들어, 이 파일 'parent.json'은 `com.example` 패키지 이름을 사용하여 호출됩니다.

```json
{
    "type" : "object",
    "properties" : {
        "myProperty" : {
            "javaType" : "com.other.package.CustomChildName",
            "type" : "object"
        }
    }
}
```

두 개의 Java 유형이 생성됩니다.

* com.example.Parent  
* com.other.package.CustomChildName  

### existingJavaType

`existingJavaType` 속성은 이미 있는(선언)된 `Java Type`을 사용할 수 있도록 합니다.
`existingJavaType`에 설정할 수 있는 값은 존재하는 `class`나 `interface`이며,
`class/interface` 는 생성되는 것이 아니어야 합니다.

When referencing existing classes, it's also possible to supply generic type arguments, for instance:

```json
    {
        "type" : "object",
        "properties" : {
            "myProperty" : {
                "existingJavaType" : "java.util.Map<String,Integer>",
                "type" : "object"
            }
        }
    }
```

## javaEnumNames

**참고: `javaEnumNames` 또는 `javaEnums` 중 하나만 사용해야 하며 후자가 더 강력한 확장 기능입니다.**

Any schema that makes use of `enum` may include `javaEnumNames`. This property allows you to take control of naming your Java enum constants and avoid relying on auto-generated names.

`enum` 을 사용하는 모든 스키마에는 `javaEnumNames` 이 포함될 수 있습니다.
이 속성을 사용하면 Java 열거형 상수의 이름을 지정하고 자동 생성된 이름에 의존하지 않도록 제어할 수 있습니다.

If your schema includes `javaEnumNames` like:

```json
{
    "type" : "object",
    "properties" : {
        "foo" : {
            "type" : "string",
            "enum" : ["H","L"],
            "javaEnumNames" : ["HIGH","LOW"]
        }
    }
}
```

Then you'll see a generated type like:

```java
public enum Foo {
    HIGH("H"),
    LOW("L");
    ...
}
```

## javaEnums

**참고: `javaEnumNames` 또는 `javaEnums` 중 하나만 사용해야 하며 후자가 더 강력한 확장 기능입니다.**

`enum` 을 사용하는 모든 스키마에는 이 `javaEnums` 속성이 포함될 수 있습니다.
이 속성을 사용하면 Java 열거형 상수의 이름을 지정하고 자동 생성된 이름에 의존하지 않고
제목과 설명이 있는 열거형 상수별 문서를 추가할 수 있습니다 .

If your schema includes `javaEnumNames` like:

```json
{
	"$id": "https://cubrc.org/rigors/schemas/common/com/examples/Digits.schema.json",
	"$schema": "http://json-schema.org/draft-07/schema#",
	"type": "string",
	"enum": ["1", "2", "3", "4"],
	"javaEnums": [
		{
			"name": "ONE",
			"title": "The first number.",
			"description": "1 (one, also called unit, unity, and (multiplicative) identity) is a number, and a numerical digit used to represent that number in numerals. (https://en.wikipedia.org/wiki/1)"
		},
		{
			"name": "TWO",
			"title": "The second number.",
			"description": "2 (two) is a number, numeral, and glyph. \n\nIt is the natural number following 1 and preceding 3. (https://en.wikipedia.org/wiki/2)"
		}, {
			"name": "THREE",
			"title": "The third number.",
			"description": "3 (three) is a number, numeral, and glyph. It is the natural number following 2 and preceding 4. (https://en.wikipedia.org/wiki/3)"
		}, {
			"name": "FOUR",
			"title": "The fourth number.",
			"description": "4 (four) is a number, numeral, and glyph. It is the natural number following 3 and preceding 5. (https://en.wikipedia.org/wiki/4)"
		}
	],
	"additionalProperties": false,
	"required": [],
	"definitions": {}
}
```

Then you'll see a generated type like:

```java
public enum Digits {

    /**
     * The first number.
     * <p>
     *  1 (one, also called unit, unity, and (multiplicative) identity) is a number, and a numerical digit used to represent that number in numerals. (https://en.wikipedia.org/wiki/1)
     * 
     */
    ONE("1"),

    /**
     * The second number.
     * <p>
     *  2 (two) is a number, numeral, and glyph. 
     * 
     * It is the natural number following 1 and preceding 3. (https://en.wikipedia.org/wiki/2)
     * 
     */
    TWO("2"),

    /**
     * The third number.
     * <p>
     *  3 (three) is a number, numeral, and glyph. It is the natural number following 2 and preceding 4. (https://en.wikipedia.org/wiki/3)
     * 
     */
    THREE("3"),

    /**
     * The fourth number.
     * <p>
     *  4 (four) is a number, numeral, and glyph. It is the natural number following 3 and preceding 5. (https://en.wikipedia.org/wiki/4)
     * 
     */
    FOUR("4");
    ...
}
```

## javaInterfaces

Any schema may include a `javaInterfaces` property, the value of this property is an array of strings. Each string is expected to contain the fully-qualified name of a Java interface. The Java type generated by the schema will implement all the given interfaces.

모든 스키마는 `javaInterfaces` 속성을 포함할 수 있으며 이 속성의 값은 문자열 배열입니다.
각 문자열은 Java 인터페이스의 정규화된 이름을 포함할 것으로 예상됩니다.
스키마에서 생성된 Java 유형은 제공된 모든 인터페이스를 구현합니다.

If the `javaInterfaces` property is added to fooBar.json like:

```json
{
    "javaInterfaces" : ["java.io.Serializable", "Cloneable"],
    "type" : "object"
}
```

then the result will be a class defined like:

```java
public class FooBar implements Serializable, Cloneable
{
...
```

## javaName

Using `javaName` rule allows you to define custom names for java bean properties instead of those inferred from the corresponding json property names. This also affects setters and getters.

`javaName`을 사용하면 해당 json 속성 이름에서 추론된 이름 대신 사용자 정의 이름을 정의할 수 있습니다.
이는 setter와 getter에도 영향을 미칩니다.

For example, the following schema:

```json
{
  "type": "object",
  "properties": {
    "a": {
      "javaName": "b",
      "type": "string"
    }
  }
}
```

will produce Java code similar to the following:

```java
public class MyClass {
    @JsonProperty("a")
    private String b;

    @JsonProperty("a")
    public String getB() {
        return b;
    }

    @JsonProperty("a")
    public void setB(String b) {
        this.b = b;
    }
}
```

그 외에도 customPattern / customTimezone, excludeFromEqualsAndHashCode 이 있습니다.

