---
layout: post
title: Setting Korean Locale in Alpine Linux
author: jblim0125
date: 2025-02-28
category: 2025
tags: [alpine, korean locale]
---

## 개요

이 문서에서는 도커환경에서 `Alpine Linux 3.21` 에 한국어 설정을 설명한다.  

기존 우분투 환경에서 한국어 설정을 하고 잘 사용하고 있었는데 버전 업데이트를 지원하지 않아 이 참에 alpine 으로 변경하고자 한다.

## Dockerfile

다음은 문제가 된 `Dockerfile`이다.  
`temurin jdk 11` 을 실행용 이미지로 사용하고 있었고, locale 설정 부분에서 오류가 발생하였다.

```dockerfile
# 빌드 이미지와 실행 이미지를 다른 이미지로 대체하길 원하는 경우를 위한 이미지 변수
ARG BUILD_IMAGE=maven:3.8.3-eclipse-temurin-11
ARG RUNTIME_IMAGE=eclipse-temurin:11

###############################################################
###                      Stage : Build                      ###
###############################################################
FROM ${BUILD_IMAGE} as build

#...

###############################################################
###             Stage : Make Product Image                  ###
###############################################################
FROM ${RUNTIME_IMAGE} as product

#...

## Install Locale(ko_KR.UTF-8)
RUN apt-get update && apt-get install -y locales \
    && localedef -f UTF-8 -i ko_KR ko_KR.UTF-8 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

#...

ENTRYPOINT ["java", "-jar", "/app/service.jar"]
```

## 수정 시작  

1. 실행 이미지 변경

    JDK 버전은 동일하게 11로 가져가고 OS를 `alpine`으로 변경하여
    `eclipse-temurin:11.0.26_4-jre-alpine-3.21` 를 사용하기로 결정.  

    ```dockerfile
    # 빌드 이미지와 실행 이미지를 다른 이미지로 대체하길 원하는 경우를 위한 이미지 변수
    ARG BUILD_IMAGE=maven:3.8.3-eclipse-temurin-11
    ARG RUNTIME_IMAGE=eclipse-temurin:11.0.26_4-jre-alpine-3.21
    ```

2. 실행 이미지 locale 설정 추가  

    > 아래 방법은 잘못된 방법임.

    ```Dockerfile
    ###############################################################
    ###             Stage : Make Product Image                  ###
    ###############################################################
    FROM ${RUNTIME_IMAGE} as product

    #...

    # glibc 설치
    RUN apk add --no-cache wget ca-certificates \
        && wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub \
        && wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.35-r1/glibc-2.35-r1.apk \
        && wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.35-r1/glibc-bin-2.35-r1.apk \
        && wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.35-r1/glibc-i18n-2.35-r1.apk \
        && apk add --no-cache glibc-2.35-r1.apk glibc-bin-2.35-r1.apk glibc-i18n-2.35-r1.apk \
        && rm -f glibc-*.apk

    # 설치 후 한글 로케일을 활성화
    RUN /usr/glibc-compat/bin/localedef -i ko_KR -f UTF-8 ko_KR.UTF-8 \
        && echo "export LANG=ko_KR.UTF-8" >> /etc/profile \
        && echo "export LANGUAGE=ko_KR.UTF-8" >> /etc/profile \
        && echo "export LC_ALL=ko_KR.UTF-8" >> /etc/profile

    #...
    ```

3. 환경 변수를 이용한 Locale 설정

    실행 이미지로 선택한 `eclipse-temurin:11.0.26_4-jre-alpine-3.21` 에는 이미 Locale을 환경변수로 설정하면 가능하도록 되어 있음.
    `/etc/profile.d/20locale.sh` 파일을 열어보면 아래와 같은 스크립트가 존재함.

    ```shell
    export CHARSET=${CHARSET:-UTF-8}
    export LANG=${LANG:-C.UTF-8}
    export LC_COLLATE=${LC_COLLATE:-C}
    ```

    따라서 복잡하게 설치하는 과정이 필요 없이 `ENV` 를 이용해 환경변수만 설정하면 동작가능하다.  

    ```Dockerfile
    ###############################################################
    ###             Stage : Make Product Image                  ###
    ###############################################################
    FROM ${RUNTIME_IMAGE} as product

    #...

    ENV LANG=ko_KR.UTF-8 \
        LC_ALL=ko_KR.UTF-8
    
    #...

    ```

4. 확인

    빌드한 도커 이미지에 접근(shell)하여 `locale` 명령을 실행

    ```shell
    $ locale
    LANG=ko_KR.UTF-8
    LC_CTYPE=ko_KR.UTF-8
    LC_NUMERIC=ko_KR.UTF-8
    LC_TIME=ko_KR.UTF-8
    LC_COLLATE=ko_KR.UTF-8
    LC_MONETARY=ko_KR.UTF-8
    LC_MESSAGES=ko_KR.UTF-8
    LC_ALL=ko_KR.UTF-8
    ```
