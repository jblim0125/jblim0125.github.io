---
layout: post
title: GitLab CI CD 구성
author: jblim0125
date: 2025-06-27
category: 2025
tags: [GitLab, GitLab Runner, CI/CD]
---

## GitLab, GitLab Runner를 이용한 CI/CD 구성

GitLab과 GitLab Runner를 사용하여 CI/CD 파이프라인을 구성하는 방법을 소개합니다. 이 가이드는 GitLab 프로젝트에 CI/CD를 설정하고, GitLab Runner를 설치하여 자동화된 빌드 및 배포 프로세스를 구현하는 데 중점을 둡니다.

## 목표

- GitLab, GitLab Runner 설치 및 구성
- GitLab 프로젝트에 CI/CD 파이프라인 설정
- 자동화된 빌드 및 테스트 프로세스 구현

## Docker Compose 를 활용한 설치

### GitLab

다음 명령어를 사용하여 GitLab을 Docker Compose로 설치합니다. 먼저 `docker-compose.yml` 파일을 생성하고 다음 내용을 추가합니다.
> 주의 : 도메인을 사용할 수 없는 로컬 망 설치로 hostname 은 실제 IP 주소로 변경해야 합니다.

```yaml
services:
  gitlab:
    image: gitlab/gitlab-ce:latest
    container_name: gitlab
    restart: always
    hostname: 'gitlab.example.com'
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'http://gitlab.example.com:8929'
        gitlab_rails['gitlab_shell_ssh_port'] = 2424
    ports:
      - '8929:8929'
      - '2424:22'
    volumes:
      - '$GITLAB_HOME/config:/etc/gitlab'
      - '$GITLAB_HOME/logs:/var/log/gitlab'
      - '$GITLAB_HOME/data:/var/opt/gitlab'
    shm_size: '256m'
```

1. `docker-compose.yml` 파일을 저장한 후, 다음 명령어로 GitLab을 시작합니다.

    ```sh
    docker-compose up -d
    ```

2. GitLab이 시작되면, 웹 브라우저에서 `host_ip:8929`에 접속하여 GitLab에 접근할 수 있습니다.
    초기 패스워드는 `docker exec -it gitlab grep 'Password:' /etc/gitlab/initial_root_password` 명령어로 확인할 수 있습니다.
    접속 후 root 계정의 패스워드를 변경합니다.

3. 그룹 및 프로젝트를 생성합니다.

### GitLab Runner

CI/CD 파이프라인 실행(Docker Executor)을 위한 GitLab Runner를 설치합니다. `docker-compose.yml` 파일에 다음 내용을 추가합니다.

```yaml
services:
  gitlab-runner:
    image: gitlab/gitlab-runner:latest
    container_name: gitlab-runner
    depends_on:
      - gitlab
    restart: always
    volumes:
      - './gitlab-runner:/etc/gitlab-runner'
      - '/var/run/docker.sock:/var/run/docker.sock'
```

1. `docker-compose.yml` 파일을 저장한 후, 다음 명령어로 GitLab Runner를 시작합니다.

    ```sh
    docker-compose -f docker-compose.yml up -d
    ```

2. GitLab Runner가 시작되면, 다음 명령어로 Runner를 등록합니다.

    ```sh
    docker exec -it gitlab-runner gitlab-runner register
    ```

    - GitLab URL: <http://{host_ip}:8929>
    - Token: GitLab에서 생성한 Runner 토큰 입력
    - Description: Runner 설명 입력
    - Tags: Runner 태그 입력 (예: `voice_phishing`)
    - Executor: `docker` 선택

## GitLab CI/CD 파이프라인 설정

GitLab 프로젝트의 루트 디렉토리에 `.gitlab-ci.yml` 파일을 생성하여 CI/CD 파이프라인을 정의합니다. 다음은 간단한 예제입니다.

```yaml
stages:
  - build
  - test
  - deploy

build:
  stage: build
  script:
    - echo "Building the project..."

test:
  stage: test
  script:
    - echo "Running tests..."

deploy:
  stage: deploy
  script:
    - echo "Deploying the project..."
```

### Spring Boot - Gradle 프로젝트 예제

다음은 Spring Boot Gradle 프로젝트를 위한 `.gitlab-ci.yml` 예제입니다.

```yaml
image: gradle:7.5-jdk11
stages:
  - build
  - test
  - deploy

cache:
  key: "$CI_COMMIT_REF_SLUG"
  paths:
    - .gradle/

build:
    stage: build
    script:
        - gradle clean build --no-daemon -x test
test:
    stage: test
    script:
        - gradle test --no-daemon

deploy:
    stage: deploy
    script:
        - echo "Deploying the application..."
    only:
        - master
```
