---
layout: post
title: "Java, SpringBoot 컨테이너 이미지 사이즈 최적화"
author: jblim0125
date: 2024-08-11
category: 2024
---

## 개요

`Java`, `SpringBoot` 을 이용한 서비스를 컨테이너 이미지로 만들어 본 개발자라면 단순한 서비스의 이미지 크기가
꽤 크다는 것을 알아차렸을 것입니다. 이 글에서는 기본 이미지의 선택 외 `Java` 언어를 이용한 서비스의 컨테이너
이미지 크기를 최적화하기 위한 몇 가지 팁을 다룰 것입니다.  

> 이 글에서 사용된 프로그램에는 1개의 엔드포인트(GET)만 포함되어 있습니다.  
> Gradle을 이용해 빌드 되었습니다.  

### HelloController.java

- Method GET  : /hello  

```java
package com.jblim.hello.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {

    @GetMapping("/hello")
    public String hello() {
        eeturn "Hello World!";
    }
}
```

### 왜 이미지 크기에 신경을 써야 하나요?

이미지 크기는 개발자 또는 조직으로서 당신의 성과에 상당한 영향을 미칠 수 있습니다.
특히 여러 서비스로 구성된 대규모 프로젝트의 경우 하나 하나의 서비스 이미지 용량이 큰 경우 많은 돈과 시간이 들 수 있습니다.
(예 : 20개 이상의 마이크로 서비스로 구성된 서비스에서 각 서비스가 300MB 이상으로 구성되어 있다면 전체 서비스는 GB가 됩니다.)  

큰 이미지를 피해야 하는 몇 가지 이유는 다음과 같습니다:

- 디스크 공간: 도커 레지스트리와 프로덕션 서버에서 디스크 공간을 낭비하고 있습니다.  
- 느린 빌드: 이미지가 클수록 이미지를 만들고 푸시하는 데 시간이 더 오래 걸립니다.  
- 대역폭: 이미지가 클수록, 레지스트리로 이미지를 당기고 푸시할 때 대역폭 소비가 더 많아집니다.  

> 도커 빌드 시 캐시와 같은 기술을 비롯해 빌드, 배포 환경이 뛰어나 신경쓰지 않을수도 있습니다.  
> 작은 이미지 사이즈는 신규 혹은 패치 시 서버에서 빠르게 동작가능하다는 점에서 많은 이점이 있습니다.  

### 기본 이미지 선택

최적화에 대해 생각하기 전에, 애플리케이션을 패키징하는데 사용하는 기본 이미지에 항상 주의해야 합니다.
기본 이미지는 최종 이미지의 크기에 상당한 영향을 미칠 수 있습니다.  

자바 애플리케이션을 패키징하는데 사용할 수 있는 몇 가지 기본 이미지가 있으며, 그 중 일부는 다음과 같습니다:

- JDK Alpine base images  
이 이미지는 크기가 매우 작지만 모든 응용 프로그램에 적합하지 않으므로 일부 라이브러리와의  
호환성 문제가 발생할 수 있습니다.  
- JDK Slim base images  
이 이미지는 데비안이나 우분투를 기반으로 하며 전체 JDK 이미지에 비해 크기가 꽤 작지만 여전히 꽤 큽니다.  
- JDK full base images  
이 이미지는 크기가 매우 크며, 응용 프로그램을 실행하는 데 필요한 모든 모듈과 종속성을 포함합니다.

다음은 이미지의 크기에 대한 정보를 제공하기 위해 `openjdk:17-jdk-slim` 과  
`eclipse-temurin:17-jdk-alpine` 이미지의 크기를 비교한 것입니다.  

#### openjdk:17-jdk-slim  

```Dockerfile
FROM openjdk:17-jdk-slim

# 컨테이너에 작업 디렉토리를 설정하세요
WORKDIR /app

# 사용자 만들기
RUN addgroup --system spring && adduser --system spring --ingroup spring

# 사용자로 변경
USER spring:spring

COPY build/lib/*.jar app.jar

EXPOSE 8080

CMD ["java", "-jar", "app.jar"]
```

![jar와일반이미지의크기](/assets/images/docker-image-optimize/image-01.png)

이미지의 크기는 응용 프로그램 크기에 비해 꽤 크며, 약 425MB입니다.  

#### eclipse-temurin:17-jdk-alpine

> 다음 도커파일은 `linux/amd64` 환경이 아니라면 도커 빌드 시 오류가 발생할 수 있습니다.
> 원인은 해당 이미지가 `linux/amd64` 용 이미지만 제공되고 있어 발생합니다.  
> 빌드 환경이 `linux/amd64` 가 아닌 경우 아래와 같이 명령에서 플랫폼 정보를 입력합니다.  
> `docker buildx build --platform=linux/amd64 . -f Dockerfile -t hello:v0.0.1`

```Dockerfile
FROM eclipse-temurin:17-jdk-alpine

ARG APP_USER=spring

RUN addgroup --system $APP_USER && adduser --system $APP_USER --ingroup $APP_USER
RUN mkdir /app && chown -R $APP_USER /app

WORKDIR /app

COPY --chown=$APP_USER:$APP_USER build/libs/*.jar /app/app.jar

USER $APP_USER

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
```

![temuin-openjdk](/assets/images/docker-image-optimize/image-02.png)

이미지의 크기를 조정하지 않아도 기본 이미지를 어떤 것을 사용하냐에 따라 이미지 크기가 달라지는 것을 확인할 수 있습니다.  

## 이미지 최적화

이제 실행에 필요한 라이브러리/모듈만들 포함시켜 이미지를 만드는 과정을 소개하겠습니다.

> JRE 이미지를 사용하지 않는 이유는 무엇인가요?  
> `jlink`를 사용하여 더 작은 사용자 지정 런타임(JRE)을 만들고 사용할 수 있음을 소개하고자 합니다.  

### jlink를 사용한 JRE image 만들기

> 만일 우리가 만든 서비스에서 데이터베이스와 연동이 없다면 `java.sql` 모듈은 필요하지 않습니다.  

`jlink`는 위와 같은 상황에서 애플리케이션 실행에 필요한 모듈만 포함하는 사용자 지정 런타임 이미지를
만드는 데 사용할 수 있는 도구입니다.  

다음은 `jlink` 를 이용한 Dockerfile의 예시입니다.  

```Dockerfile
# 빌드 이미지 
FROM eclipse-temurin:17-jdk-alpine AS jre-builder

RUN apk update &&  \
    apk add binutils

RUN $JAVA_HOME/bin/jlink \
         --verbose \
         --add-modules ALL-MODULE-PATH \
         --strip-debug \
         --no-man-pages \
         --no-header-files \
         --compress=2 \
         --output /optimized-jdk-17

# 실행 이미지 
FROM alpine:latest
ENV JAVA_HOME=/opt/jdk/jdk-17
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# JRE 복사 
COPY --from=jre-builder /optimized-jdk-17 $JAVA_HOME

# 사용자 설정  
ARG APP_USER=spring
RUN addgroup --system $APP_USER &&  adduser --system $APP_USER --ingroup $APP_USER
RUN mkdir /app && chown -R $APP_USER /app

WORKDIR /app
# 어플리케이션 복사  
COPY --chown=$APP_USER:$APP_USER build/libs/*.jar /app/app.jar

USER $APP_USER

EXPOSE 8080

ENTRYPOINT [ "java", "-jar", "/app/app.jar" ]
```

#### 설명

첫 번째 `jlink` 사용하여 사용자 지정 JRE 이미지를 만들고,
두 번째는 첫 번째 빌드이미지(스테이지)에서 만든 JRE와 애플리케이션을 복사하여 실행 가능한 이미지를 만듭니다.  

![alt text](/assets/images/docker-image-optimize/image-03.png)

`jlink` 를 이용해 직접 JRE를 만들자 이미지의 크기가 120MB로 작아졌습니다.  

### 필요한 모듈만 포함시키기

이미지 크기는 여전히 어플리케이션 보다는 큰데, 이는 `jlink` 명령 사용 시
`--add-modules=ALL-MODULE-PATH` 에 의해 포함된 필요하지 않는 모듈들을 제외시켜
더 작은 이미지를 만들 수 있습니다.  

> 애플리케이션을 실행하는데 필요한 모듈이 무엇인지 어떻게 알 수 있나요?  
> JDK와 함께 제공되는 `jdeps` 도구를 사용할 수 있습니다.  

`jdeps` 이 도구는 jar 파일의 종속성을 분석하고 애플리케이션을 실행하는데 필요한 모듈 목록을 생성하는 데
사용할 수 있습니다. 다음과 같이 명령을 실행하면 됩니다.

```sh
jar xvf build/libs/spring-app-0.0.1-SNAPSHOT.jar
jdeps --ignore-missing-deps -q \
    --recursive \
    --multi-release 17 \
    --print-module-deps \
    --class-path BOOT-INF/lib/* \
    build/libs/spring-app-0.0.1-SNAPSHOT.jar
```

이제 `ALL-MODULE-PATH` 명령어 대신 위 명령 결과를 넣어 도커파일을 작성합니다.  

```Dockerfile
# 빌드 이미지 
FROM eclipse-temurin:17-jdk-alpine AS jre-builder

# Install binutils, required by jlink
RUN apk update &&  \
    apk add binutils

# Build JRE image
RUN $JAVA_HOME/bin/jlink \
         --verbose \
         --add-modules java.base,java.compiler,java.desktop,java.instrument,java.naming,java.net.http,java.prefs,java.rmi,java.scripting,java.security.jgss,java.sql,jdk.jfr,jdk.management,jdk.unsupported \
         --strip-debug \
         --no-man-pages \
         --no-header-files \
         --compress=2 \
         --output /optimized-jdk-17

# 실행 이미지 
FROM alpine:latest
ENV JAVA_HOME=/opt/jdk/jdk-17
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# JRE 복사 
COPY --from=jre-builder /optimized-jdk-17 $JAVA_HOME

# 사용자 설정  
ARG APP_USER=spring
RUN addgroup --system $APP_USER &&  adduser --system $APP_USER --ingroup $APP_USER
RUN mkdir /app && chown -R $APP_USER /app

WORKDIR /app

COPY --chown=$APP_USER:$APP_USER build/libs/*.jar /app/app.jar

USER $APP_USER

EXPOSE 8080
ENTRYPOINT [ "java", "-jar", "/app/app.jar" ]
```

그리고 필요한 모듈만 포함시켜 만든 이미지의 크기는 다음과 같습니다.

![module-customize](/assets/images/docker-image-optimize/image-04.png)

## 완료 : jdeps - jlink 자동화

매번 애플리케이션 빌드와 `jdeps` 와 `jlink`를 사용할 수 없으므로 도커파일을 수정하여
자동으로 필요한 모듈만들 포함시키도록 만듭니다.  

```Dockerfile
# 빌드 이미지
FROM gradle:jdk21-alpine AS jre-builder

RUN apk update && \
    apk add --no-cache tar binutils

WORKDIR /opt/app

# Gradle 캐시를 활용하기 위해 build.gradle 및 settings.gradle 파일만 먼저 복사
COPY build.gradle settings.gradle /opt/app/
RUN gradle build -x test --no-daemon || return 0

# 나머지 소스 코드 복사 및 빌드
COPY . /opt/app

RUN gradle build -x test --no-daemon

RUN jar xvf build/libs/spring-app-0.0.1-SNAPSHOT.jar
RUN jdeps --ignore-missing-deps -q \
    --recursive \
    --multi-release 21 \
    --print-module-deps \
    --class-path BOOT-INF/lib/* \
    build/libs/spring-app-0.0.1-SNAPSHOT.jar

# Build JRE
RUN $JAVA_HOME/bin/jlink \
         --verbose \
         --add-modules $(cat modules.txt) \
         --strip-debug \
         --no-man-pages \
         --no-header-files \
         --compress=2 \
         --output /optimized-jdk-21

# 실행 이미지
FROM alpine:latest
ENV JAVA_HOME=/opt/jdk/jdk-21
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# 빌드 이미지에서 JRE 복사
COPY --from=jre-builder /optimized-jdk-21 $JAVA_HOME

# 사용자 
ARG APP_USER=spring
RUN addgroup --system $APP_USER &&  adduser --system $APP_USER --ingroup $APP_USER
RUN mkdir /app && chown -R $APP_USER /app

WORKDIR /app

# jar 파일 복사
COPY --chown=$APP_USER:$APP_USER build/libs/*.jar /app/app.jar

USER $APP_USER

EXPOSE 8080
ENTRYPOINT [ "java", "-jar", "/app/app.jar" ]
```

## 보너스

`.dockerignore` 를 이용해 빌드 이미지에 파일이 복사되지 않도록 설정할 수 있습니다.  
이를 통해 빌드 단계에서 시간과 이미지의 크기를 줄이는 데 도움이 될 수 있습니다.

이미지 사이즈도 중요하지만 우수한 보안 정책이 적용되어 있고 애플리케이션과 호환되는지 확인해야 합니다.  
