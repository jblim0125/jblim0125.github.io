---
layout: post
title: Hive Metastore/MySQL On Docker
author: jblim0125
date: 2024-02-28
category: 2024
---

## Hive Metastore

## 1. MySQL Install On Docker

1. 데이터 저장용 디렉토리 / 도커 볼륨 생성  

    ```shell
    mkdir data
    # or 
    docker volume create hive-mysql-data
    ```

2. Start MySQL

    ```shell
    docker run -d --name hive-mysql \
    -p 3306:3306 \
    -e TZ=Asia/Seoul \
    -e MYSQL_DATABASE=metastore \
    -e MYSQL_USER=hive \
    -e MYSQL_PASSWORD=secret-password \
    -e MYSQL_ROOT_PASSWORD=secret-password \
    -v $PWD/data:/var/lib/mysql \
    mysql:8.3.0 --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci

    # OR

    docker run -d --name hive-mysql \
    -p 3306:3306 \
    -e TZ=Asia/Seoul \
    -e MYSQL_DATABASE=metastore \
    -e MYSQL_USER=hive \
    -e MYSQL_PASSWORD=secret-password \
    -e MYSQL_ROOT_PASSWORD=secret-password \
    -v hive-mysql-data:/var/lib/mysql \
    mysql:8.3.0 --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci
    ```

## 2. Get JDBC Driver

1. Download JDBC Driver - MySQL 8  
    MySQL의 경우 Oracle 에서 OS 별 패키지 파일을 제공.
    패키지 설치 시 jar 파일을 얻을 수 있음.  
    [Oracle Download Link](https://downloads.mysql.com/archives/c-j/)

    - CentOS 7 기준  

        ```shell
        # rpm을 이용해 오라클 페이지에서 다운받은 rpm 파일 설치  
        rpm -ivh mysql-connector-j-8.2.0-1.el7.noarch.rpm
        # 설치 디렉토리 
        cd /usr/share/java
        # 파일 확인 
        ls -al
        total 2428
        drwxr-xr-x    2 root root      67 Feb 28 18:59 .
        drwxr-xr-x. 120 root root    4096 Sep 20 16:22 ..
        lrwxrwxrwx    1 root root      21 Feb 28 18:59 mysql-connector-java.jar -> mysql-connector-j.jar
        -rw-r--r--    1 root root 2482094 Sep 19 04:13 mysql-connector-j.jar
        ```

2. Download JDBC Driver - PostgreSQL  
    [Download Link](https://jdbc.postgresql.org/download/)

## 3. Run Hive Metastore Service

1. JAR 파일을 포함한 Hive 컨테이너 실행  
    다음 내용을 참고하여 `ConnectionURL`, `ConnectionUserName`, `ConnectionPassword` 을 수정.  

    ```shell
    docker run -d -p 9083:9083 \
    --env SERVICE_NAME=metastore \
    --env DB_DRIVER=mysql \
    --env SERVICE_OPTS="-Djavax.jdo.option.ConnectionDriverName=com.mysql.cj.jdbc.Driver \
    -Djavax.jdo.option.ConnectionURL=jdbc:mysql://{localhost}/metastore \
    -Djavax.jdo.option.ConnectionUserName=hive -Djavax.jdo.option.ConnectionPassword=secret-password" \
    -v $PWD/warehouse:/opt/hive/data/warehouse \
    --mount type=bind,source=$PWD/mysql-connector-j.jar,target=/opt/hive/lib/mysql-connector-j.jar \
    --name metastore apache/hive:3.1.3
    ```

## 3. 확인

...

## 1. 추가 - 삭제  

```shell
# Container Stop
docker stop hive-mysql
# Container Remove 
docker rm hive-mysql
# Data Directory Remove 
rm -rf {mysql}/data
docker volume rm hive-mysql-data
```
