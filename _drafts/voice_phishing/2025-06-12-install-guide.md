<!-- filepath: /Users/jblim/Workspace/jblim0125.github.io/_drafts/voice_phishing/2025-06-12-install-guide.md -->

# 보이스피싱 테스트 환경: Docker 기반 설치 메뉴얼

이 문서는 보이스피싱 데이터 수집/공유 시스템의 테스트 환경을 Docker로 구성하는 방법을 안내합니다.

---

## 1. 사전 준비

- Linux 환경에서 Docker, Docker Compose 설치
- 터미널에서 아래 명령으로 설치 확인

```sh
docker --version

docker compose version
```

네트워크 생성

```sh
docker network create voice_phishing_net
```

---

## 2. 기본 설치

> 기본 설치의 경우 고가용성 구성을 고려하지 않고, 단일 인스턴스로 구성합니다.

먼저, 홈 디렉토리에 `voice_phishing` 디렉토리를 생성하고 이동합니다.

```sh
mkdir -p ~/voice_phishing
cd ~/voice_phishing
```

서비스들을 위한 디렉토리를 생성합니다.

```sh
mkdir -p nginx mysql/data mysql/logs keycloak jaeger gitlab
touch ./jaeger/.initialized
chown -R 10001:10001 ./jaeger
```

다음 docker compose 파일을 이용해 Nginx, MySQL, Keycloak, Jaeger를 실행합니다.

```yaml
version: '3.8'

```

![NGINX-Modsecurity-CRS Image Page](https://github.com/coreruleset/modsecurity-crs-docker)

### 2. KeyCloak 설정

- 브라우저에서 <http://localhost:11080> 접속, admin/admin으로 로그인
- Realm, Client, User 등은 Keycloak Admin 콘솔에서 설정

### 3. GitLab 설치 (Docker)

```sh
mkdir -p ~/gitlab/config ~/gitlab/logs ~/gitlab/data

docker run --detach \
  --hostname gitlab.local \
  --publish 10080:80 --publish 10022:22 \
  --name gitlab \
  --restart always \
  --volume $HOME/gitlab/config:/etc/gitlab \
  --volume $HOME/gitlab/logs:/var/log/gitlab \
  --volume $HOME/gitlab/data:/var/opt/gitlab \
  gitlab/gitlab-ce:latest
```

### 4. API Gateway (Spring Cloud Gateway) 설치

```sh
docker run -d --name scg --network voice_phishing_net \
  -p 8080:8080 \
  -e SPRING_PROFILES_ACTIVE=prod \
  -e DATABASE_URL=jdbc:mysql://mysql1:3306,mysql2:3306,mysql3:3306/gateway?loadBalanceHosts=true \
  -e DATABASE_USERNAME=gateway \
  -e DATABASE_PASSWORD=hello.mobigen12#$ \
  springcloud/spring-cloud-gateway:latest
```

### 5. Jaeger 설치 (Docker)

```sh
mkdir -p ./jaeger/badger/data
touch ./jaeger/badger/data/.initialized
chown -R 10001:10001 ./jaeger
docker run -d --name jaeger --network voice_phishing_net \
    -e COLLECTOR_OTLP_ENABLED="true" \
    -e SPAN_STORAGE_TYPE="badger" \
    -e BADGER_EPHEMERAL="false" \
    -e BADGER_DIRECTORY_VALUE="/badger/data" \
    -e BADGER_DIRECTORY_KEY="/badger/key" \
    jaegertracing/all-in-one:1.70
```

## 3. 고가용성 구성

### 1. MySQL 설치 (Docker, InnoDB Cluster)

1. MySQL 서버 3개 실행

    ```sh
    docker run -d --name mysql1 --network voice_phishing_net \
    -e MYSQL_ROOT_PASSWORD=biris.manse \
    -e MYSQL_USER=keycloak \
    -e MYSQL_PASSWORD=hello.mobigen12#$ \
    -e MYSQL_DATABASE=keycloak \
    -p 3307:3306 \
    mysql:8.0 --default-authentication-plugin=mysql_native_password --server-id=1 --gtid-mode=ON --enforce-gtid-consistency=ON --master-info-repository=TABLE --relay-log-info-repository=TABLE --binlog-checksum=NONE --log-bin=binlog --log-slave-updates=ON --plugin-load-add=group_replication.so --group-replication-start-on-boot=off --transaction-write-set-extraction=XXHASH64 --group-replication-group-name=\"aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee\" --group-replication-local-address=\"mysql1:33061\" --group-replication-group-seeds=\"mysql1:33061,mysql2:33061,mysql3:33061\" --group-replication-single-primary-mode=ON --group-replication-enforce-update-everywhere-checks=OFF

    docker run -d --name mysql2 --network voice_phishing_net \
    -e MYSQL_ROOT_PASSWORD=biris.manse \
    -e MYSQL_USER=keycloak \
    -e MYSQL_PASSWORD=hello.mobigen12#$ \
    -e MYSQL_DATABASE=keycloak \
    -p 3308:3306 \
    mysql:8.0 --default-authentication-plugin=mysql_native_password --server-id=2 --gtid-mode=ON --enforce-gtid-consistency=ON --master-info-repository=TABLE --relay-log-info-repository=TABLE --binlog-checksum=NONE --log-bin=binlog --log-slave-updates=ON --plugin-load-add=group_replication.so --group-replication-start-on-boot=off --transaction-write-set-extraction=XXHASH64 --group-replication-group-name=\"aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee\" --group-replication-local-address=\"mysql2:33061\" --group-replication-group-seeds=\"mysql1:33061,mysql2:33061,mysql3:33061\" --group-replication-single-primary-mode=ON --group-replication-enforce-update-everywhere-checks=OFF

    docker run -d --name mysql3 --network voice_phishing_net \
    -e MYSQL_ROOT_PASSWORD=biris.manse \
    -e MYSQL_USER=keycloak \
    -e MYSQL_PASSWORD=hello.mobigen12#$ \
    -e MYSQL_DATABASE=keycloak \
    -p 3309:3306 \
    mysql:8.0 --default-authentication-plugin=mysql_native_password --server-id=3 --gtid-mode=ON --enforce-gtid-consistency=ON --master-info-repository=TABLE --relay-log-info-repository=TABLE --binlog-checksum=NONE --log-bin=binlog --log-slave-updates=ON --plugin-load-add=group_replication.so --group-replication-start-on-boot=off --transaction-write-set-extraction=XXHASH64 --group-replication-group-name=\"aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee\" --group-replication-local-address=\"mysql3:33061\" --group-replication-group-seeds=\"mysql1:33061,mysql2:33061,mysql3:33061\" --group-replication-single-primary-mode=ON --group-replication-enforce-update-everywhere-checks=OFF
    ```

2. MySQL Shell을 이용한 InnoDB Cluster 설정

    ```sh
    docker run -it --rm --network voice_phishing_net mysql/mysql-shell:8.0 \
        --uri root:biris.manse@mysql1:3306
    ```

    MySQL Shell 프롬프트에서 아래 명령 실행:

    ```sh
    dba.configureInstance('root@mysql1:3306')
    dba.configureInstance('root@mysql2:3306')
    dba.configureInstance('root@mysql3:3306')

    cluster = dba.createCluster('myCluster')
    cluster.addInstance('root@mysql2:3306')
    cluster.addInstance('root@mysql3:3306')
    cluster.status()
    ```

### 2. Keycloak 과 MySQL Cloud 연동

```sh
docker run -d --name keycloak --network voice_phishing_net \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD=mobigen12#$ \
  -e KC_DB=mysql \
  -e KC_DB_URL_HOST="jdbc:mysql://mysql1:3306,mysql2:3306,mysql3:3306/keycloak?loadBalanceHosts=true" \
  -e KC_DB_SCHEMA=keycloak \
  -e KC_DB_USERNAME=keycloak \
  -e KC_DB_PASSWORD=hello.mobigen12#$ \
  -e KC_TRACING_ENABLED=true \
  -e KC_TRACING_ENDPOINT=opentelemetry \
  --link keycloak-mysql:keycloak-mysql \
  quay.io/keycloak/keycloak:26.0.7 start-dev
```

## 3. 참고 사항

### 1. Keycloak - MySQL 연동 관련

**경고 메시지 요약**  

```text
NATIONAL/NCHAR/NVARCHAR implies the character set UTF8MB3,
which will be replaced by UTF8MB4 in a future release.
Please consider using CHAR(x) CHARACTER SET UTF8MB4 in order to be unambiguous.
```

**의미**  

- NATIONAL CHAR, NCHAR, NVARCHAR는 UTF8MB3를 사용함.
- 그러나 MySQL은 점차 UTF8MB4로 전환 중.
- 명시적으로 CHAR(x) CHARACTER SET utf8mb4 또는 VARCHAR(x) CHARACTER SET utf8mb4를 쓰라는 의미.

**원인**  

Keycloak은 내부적으로 Liquibase를 사용해 데이터베이스 스키마를 관리합니다. 이때 기본적으로 NVARCHAR, NCHAR 등의 타입을 사용하며, 이는 MySQL에서 암시적으로 UTF8MB3를 적용하게 되어 위와 같은 경고가 출력됩니다.

**해결 방법**  

1. 경고 무시
2. MySQL의 기본 문자셋 변경
3. Keycloak 또는 Liquibase 커스텀

**권장**  

이 경고는 무시하고, 추후 MySQL이 utf8mb3를 deprecated할 경우 Keycloak 또는 Liquibase에서
수정이 이루어질 가능성이 높으므로 기다리는 것이 안정적입니다.

**결론**  

- 현재 경고는 기능에 영향을 주지 않으며 무시해도 괜찮습니다.
