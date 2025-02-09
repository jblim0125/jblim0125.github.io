---
layout: post
title: modsecurity + nginx
author: jblim0125
date: 2024-09-18
category: 2024
---

## What is the OWASP CRS

OWASP CRS는 ModSecurity + 웹 애플리케이션과 함께 사용할 수 있는 일반적인 공격 탐지 규칙 세트이다.
ModSecurity는 Apache, IIS 및 Nginx를 위한 오픈 소스, 크로스 플랫폼 웹 애플리케이션 방화벽(WAF) 엔진입니다.

## 엔진 별 버전 정보

* nginx  
    Nginx 1.27.1 + ModSecurity v3 / OWASP CRS 4.6.0  
    [nginx-alpine](https://github.com/coreruleset/modsecurity-crs-docker/blob/master/nginx/Dockerfile-alpine)
* Apache  
    httpd – Apache 2.4.62 + ModSecurity v2 / OWASP CRS 4.6.0  
    [apache-alpine](https://github.com/coreruleset/modsecurity-crs-docker/blob/master/apache/Dockerfile-alpine)

## 지원되는 아키텍처

공식 Apache httpd, nginx 및 Openresty 이미지를 기반으로 하기 때문에 해당 이미지에서 지원하는 아키텍처만 지원 가능  

현재 다음 아키텍처에 대한 이미지를 제공하고 있습니다.
linux/amd64
linux/arm/v7
linux/arm64/v8
linux/i386

## 빌드

`buildx` v0.9.1 이상 버전이 필요. 설치 및 업그레이드에 대한 지침은 공식 문서(docker)를 참조.

다음은 `buildx` 의 버전을 확인하는 방법이다.  

```shell
docker buildx version
github.com/docker/buildx v0.9.1 ed00243a0ce2a0aee75311b06e32d33b44729689
```

빌드 대상을 확인하려면 다음을 사용하세요.

docker buildx bake -f ./docker-bake.hcl --print
원하는 플랫폼을 위해 빌드하려면 다음 예를 사용하세요.

docker buildx create --use --platform linux/amd64,linux/i386,linux/arm64,linux/arm/v7
docker buildx bake -f docker-bake.hcl
단일 플랫폼에 대한 특정 타겟만 빌드하려면(예시의 타겟 및 플랫폼 문자열을 원하는 대로 바꾸세요):

docker buildx bake -f docker-bake.hcl --set "*.platform=linux/amd64" nginx-alpine



프록시를 이용한 웹 보안 강화(modsecurity + nginx)

### Get Docker Image

도커 허브와 깃허브를 참고하여 이미지 다운로드  
`https://hub.docker.com/r/owasp/modsecurity-crs/tags?page=&page_size=&ordering=&name=alpine`  
`https://github.com/coreruleset/modsecurity-crs-docker.git`  

```shell
docker pull owasp/modsecurity-crs:4.5.0-nginx-alpine-202407300107
```

### 참고용 환경설정 파일을 이용한 Nginx 환경 설정  

다운로드 받은 이미지 내 참고용 환경 설정 파일을 이용할 계획  
> 깃허브으로부터 받아서 이용할 수도 있다.  

1. 이미지 실행  

    ```shell
    docker run -itd --name nginx --rm owasp/modsecurity-crs:4.5.0-nginx-alpine-202407300107 /bin/sh
    ```

2. 참고용 환경설정 파일 복사  

    ```shell
    mkdir -p modsecurity
    docker cp nginx:/etc/nginx/templates .
    ```

3. 현재 환경 구성
    인증서
        certs/server_cert.pem
        certs/key.pem
    백앤드 서비스
        /v1/service -> localhost:8080
        /v1/setting -> localhost:8081

4. nginx.conf.template


### 실행

### 테스트

### 참고 사이트

modsecurity : https://github.com/coreruleset/modsecurity-crs-docker?tab=readme-ov-file
