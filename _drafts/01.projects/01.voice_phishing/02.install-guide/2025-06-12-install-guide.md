<!-- filepath: /Users/jblim/Workspace/jblim0125.github.io/_drafts/voice_phishing/2025-06-12-install-guide.md -->

# 보이스피싱 테스트 환경: Docker 기반 설치 메뉴얼

이 문서는 보이스피싱 데이터 수집/공유 시스템의 개발 및 테스트 환경을 Docker로 구성하는 방법을 안내합니다.

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

## 2. 구성 요소

- **Nginx**: 웹 방화벽
- **Spring Cloud Gateway**: API 게이트웨이
- **Keycloak**: 인증 서버
- **Jaeger**: 모니터링(트레이싱)
- **MySQL**: 데이터베이스
- **MinIO**: 오브젝트 스토리지
- **GitLab**: 소스 코드 관리
- **GitLab-Runner**: CI/CD 파이프라인 실행
- **SonarQube**: 코드 품질 분석
- **PostgreSQL**: 데이터베이스 - SonarQube용

## 3. 기본 설치

> 기본 설치의 경우 고가용성(HA) 구성을 고려하지 않고, 단일 인스턴스로 구성합니다.

먼저, 홈 디렉토리에 `voice_phishing` 디렉토리를 생성하고 이동합니다.

```sh
mkdir -p ~/voice_phishing
cd ~/voice_phishing
```

서비스들을 위한 prepare.sh 스크립트를 작성합니다.

```sh
mkdir -p prepare
cat <<EOF > prepare/prepare.sh
#!/bin/sh
mkdir -p /voice_phishing/jaeger/data && touch /voice_phishing/jaeger/data/.initialized
chown -R 10001:10001 /voice_phishing/jaeger

mkdir -p /voice_phishing/nginx/logs /voice_phishing/nginx/conf.d /voice_phishing/nginx/includes
chown -R 101:101 /voice_phishing/nginx

mkdir -p /voice_phishing/mysql/logs /voice_phishing/mysql/datadir /voice_phishing/mysql/conf.d
chown -R 999:999 /voice_phishing/mysql

mkdir -p /voice_phishing/keycloak/themes

mkdir -p /voice_phishing/gitlab/config /voice_phishing/gitlab/logs /voice_phishing/gitlab/data
mkdir -p /voice_phishing/gitlab-runner

mkdir -p /voice_phishing/sonarqube/conf /voice_phishing/sonarqube/data /voice_phishing/sonarqube/logs /voice_phishing/sonarqube/extensions
chown -R 1000:1000 /voice_phishing/sonarqube
EOF
chmod +x prepare/prepare.sh
```

**sonarqube 를 위한 환경설정**  

SonarQube의 경우 내부적으로 검색 엔진과 다양한 데이터의 사용으로 파일 시스템과 관련된 limit 설정이 필요합니다.

```sh
sysctl -w vm.max_map_count=524288
sysctl -w fs.file-max=131072
ulimit -n 131072
ulimit -u 8192
```

다음 docker compose 파일을 이용해 인프라에 해당하는 서비스들을 실행합니다.

```yaml
version: "1.5"
services:
  prepare:
    # Run this step as root so that we can change the directory owner.
    container_name: prepare
    user: root
    image: busybox:stable
    command: "sh /prepare/prepare.sh"
    #/sh -c 'mkdir -p /badger/data && touch /badger/data/.initialized && chown -R 10001:10001 /badger'"
    volumes:
      - ./prepare:/prepare
      - ./jaeger:/badger
  jaeger:
    container_name: jaeger
    image: jaegertracing/all-in-one:1.60
    restart: always
    environment:
      COLLECTOR_OTLP_ENABLED: "true"
      SPAN_STORAGE_TYPE: "badger"
      BADGER_EPHEMERAL: "false"
      BADGER_DIRECTORY_VALUE: "/badger/data"
      BADGER_DIRECTORY_KEY: "/badger/key"
    ports:
      - 16686:16686
    expose:
      - 16686
      - 4317
      - 4318
      - 14250
    networks:
      - voice_phishing_net
    volumes:
      - ./jaeger:/badger
    depends_on:
      prepare:
        condition: service_completed_successfully
    healthcheck:
      test: wget -q --spider http://localhost:16686
      interval: 15s
      timeout: 10s
      retries: 10
  mysql:
    container_name: mysql
    image: mysql:8.0
    restart: always
    command: ["bash", "-c", "chown -R mysql:mysql /var/log/mysql && exec /entrypoint.sh mysqld"]
    environment:
      MYSQL_ROOT_PASSWORD: "Mobigen.07$"
      MYSQL_DATABASE: keycloak_db
      MYSQL_USER: keycloak_user
      MYSQL_PASSWORD: keycloak_password
    volumes:
      - ./mysql/logs:/var/log/mysql
      - ./mysql/datadir:/var/lib/mysql
      - ./mysql/conf.d:/etc/mysql/conf.d
    ports:
      - 13306:3306
    expose:
      - 3306
    networks:
      - voice_phishing_net
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 15s
      timeout: 10s
      retries: 10
  keycloak:
    container_name: keycloak
    image: quay.io/keycloak/keycloak:26.0.7
    restart: always
    command: ["start-dev"]
    environment:
      KC_BOOTSTRAP_ADMIN_USERNAME: "admin"
      KC_BOOTSTRAP_ADMIN_PASSWORD: "Mobigen.07$"
      KC_DB: "mysql"
      KC_DB_POOL_MAX_SIZE: 100    # 100 default
      KC_DB_POOL_MIN_SIZE: 10
      KC_DB_URL: "jdbc:mysql://mysql:3306/keycloak_db?useUnicode=true&characterEncoding=UTF-8"
      KC_DB_USERNAME: "keycloak_user"
      KC_DB_PASSWORD: "keycloak_password"
      KC_FEATURES: "opentelemetry"
      KC_TRACING_ENABLED: "true"
      KC_TRACING_ENDPOINT: "http://jaeger:4317"
      KC_TRACING_JDBC_ENABLED: "false"
    expose:
      - 8080
      - 9000
    ports:
      - 8081:8080
    networks:
      - voice_phishing_net
    volumes:
      - ./keycloak/themes:/opt/keycloak/themes
    depends_on:
      mysql:
        condition: service_healthy
      jaeger:
        condition: service_healthy
    healthcheck:
      test: wget -q --spider http://localhost:8080/auth
      interval: 15s
      timeout: 10s
      retries: 10
  gitlab:
    image: gitlab/gitlab-ce:latest
    container_name: gitlab
    restart: always
    hostname: '192.168.105.51'
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'http://192.168.105.51:8929'
        gitlab_rails['gitlab_shell_ssh_port'] = 2424
    ports:
      - '8929:8929'
      - '2424:22'
    volumes:
      - './gitlab/config:/etc/gitlab'
      - './gitlab/logs:/var/log/gitlab'
      - './gitlab/data:/var/opt/gitlab'
  gitlab-runner:
    image: gitlab/gitlab-runner:latest
    container_name: gitlab-runner
    depends_on:
      - gitlab
    restart: always
    volumes:
      - './gitlab-runner:/etc/gitlab-runner'
      - '/var/run/docker.sock:/var/run/docker.sock'
  minio:
    container_name: minio
    restart: always
    image: quay.io/minio/minio
    command: ["server", "/data", "--console-address", ":9001"]
    environment:
      MINIO_ROOT_USER: "root"
      MINIO_ROOT_PASSWORD: "Mobigen.07$"
    ports:
      - 9001:9001
    expose:
      - 9000
      - 9001
    networks:
      - voice_phishing_net
    volumes:
      - ./minio/data:/data
  nginx:
    container_name: nginx
    image: owasp/modsecurity-crs:4.15.0-nginx-alpine-202506050606
    restart: always
    ports:
      - 8080:8080
    volumes:
      - ./nginx/conf.d:/etc/nginx/conf.d
      - ./nginx/includes:/etc/nginx/includes
      - ./nginx/logs:/var/log/nginx
      - ./nginx/templates:/etc/nginx/templates
    networks:
      - voice_phishing_net
    # reference doc url : https://github.com/coreruleset/modsecurity-crs-docker
    environment:
      SERVER_NAME: 192.168.105.51
      PORT: 8080
      PROXY_SSL: off
      LOGLEVEL: warn
      MODSEC_AUDIT_LOG: /var/log/nginx/modsec_audit.log
      ACCESSLOG: /var/log/nginx/access.log
      ERRORLOG: /var/log/nginx/modsec_error.log
      MODSEC_AUDIT_ENGINE: on
      ALLOWED_METHODS: "GET POST"
      ALLOWED_REQUEST_CONTENT_TYPE: "application/json|application/x-www-form-urlencoded|multipart/form-data"
      ANOMALY_INBOUND: 10
      ANOMALY_OUTBOUND: 5
      BLOCKING_PARANOIA: 2
      DETECTION_PARANOIA: 2
      TIMEOUT: 60
      MODSEC_RULE_ENGINE: on
      MODSEC_REQ_BODY_ACCESS: on
      MODSEC_RESP_BODY_ACCESS: off
  postgres:
    image: postgres:13
    container_name: postgres
    restart: always
    environment:
      POSTGRES_USER: sonar
      POSTGRES_PASSWORD: sonar
      POSTGRES_DB: sonar
    expose:
      - 5432
    networks:
      - voice_phishing_net
    volumes:
      - ./postgresql:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U sonar"]
      interval: 15s
      timeout: 10s
      retries: 10
  sonarqube:
    image: sonarqube:community
    container_name: sonarqube
    restart: always
    ports:
      - 9000:9000
    volumes:
      - ./sonarqube/conf:/opt/sonarqube/conf
      - ./sonarqube/extensions:/opt/sonarqube/extensions
      - ./sonarqube/logs:/opt/sonarqube/logs
      - ./sonarqube/data:/opt/sonarqube/data
    environment:
      SONAR_JDBC_URL: "jdbc:postgresql://postgres:5432/sonar"
      SONAR_JDBC_USERNAME: sonar
      SONAR_JDBC_PASSWORD: sonar
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - voice_phishing_net
networks:
  voice_phishing_net:
    ipam:
      driver: default
      config:
        - subnet: "172.19.0.0/24"
```

### 3.1. 서비스 별 추가 설정

**GitLab**  

1. gitlab admin 계정
    초기 패스워드 확인

    ```sh
    docker exec -it gitlab grep 'Password:' /etc/gitlab/initial_root_password
    ```

    위 패스워드를 이용해 GitLab에 접속합니다. 이후 admin 계정의 패스워드를 변경합니다.

2. gitlab-runner 등록

    ```sh
    docker exec -it gitlab-runner gitlab-runner register
    ```

    - GitLab URL: <http://{host_ip}:8929>
    - Token: GitLab에서 생성한 Runner 토큰 입력
    - Description: Runner 설명 입력
    - Tags: Runner 태그 입력 (예: `voice_phishing`)
    - Executor: `docker` 선택

---

**KeyCloak**  

1. 브라우저에서 <http://host_ip:8081> 접속, admin/Mobigen.07$ 로그인
2. Realm 생성 - `voice_phishing`
3. Client 생성 - API GATEWAY를 위한 client 생성

    - Client ID: `api-gateway`
    - Root URL: <http://{host_ip}:8080/api>
    - Valid Redirect URIs: <http://{host_ip}:8080/api/*>
    - Web Origins: <http://{host_ip}:8080/api/*>

4. User 생성
    - Username: `voice_phishing_user`
    - Password: `test1234!`

---

**SonarQube**  

1. 브라우저에서 <http://host_ip:9000> 접속, admin/admin 로그인
2. 초기 비밀번호 변경 후, 사용자 생성
    -> 변경된 패스워드 : Hello.Mobigen12#$
3. GitLab 연동 설정
   1. GitLab에서 Personal Access Token 생성
      - Name: `sonarqube-gitlab-token`
      - Scopes: `api, read_user, read_repository, write_repository`
   2. SonarQube에서 GitLab 연동 설정
      - Administration > Configuration > DevOps Platform > GitLab
      - GitLab URL: <http://{host_ip}:8929/api/v4>
      - Token: 위에서 생성한 Personal Access Token 입력

---

**MinIO**  

1. 브라우저에서 <http://host_ip:9001> 접속
2. 로그인 정보
   - Access Key: `root`
   - Secret Key: `Mobigen.07$`
3. 버킷 생성
   - Bucket Name: `voice_phishing`

---

**CI/CD 파이프라인 설정**  

1. SonarQube 에서 Token 생성
    - Administration > Security > Users > Tokens
    - Name: `sonarqube-token`
    - Scope: `Execute Analysis`
    - Token: 생성된 토큰을 복사
    > SONAR_TOKEN : sqp_e3c361b5dc70028135c34cf7f8c061b660025c25

## 4. 고가용성 구성

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

### 2. keepalived with nginx

rocky linux 8 이상에서 keepalived와 docker nginx 를 이용한 고가용성 구성 방법입니다.

1. **keepalived 설치**

   ```sh
    sudo dnf install -y keepalived
    ```

2. **keepalived 설정 파일 작성**

    `/etc/keepalived/keepalived.conf` 파일을 아래와 같이 작성합니다.
  
    ```conf
    vrrp_instance VI_1 {
        state MASTER
        interface eth0
        virtual_router_id 51
        priority 100
        advert_int 1
        authentication {
            auth_type PASS
            auth_pass your_password_here
        }
        virtual_ipaddress { 192.168.1.100 }

        track_script {
            chk_nginx
        }
    }

    vrrp_script chk_nginx {
        script "docker ps | grep nginx | grep -i running"
        interval 2
        weight 2
    }
    ```
  
3. **keepalived 서비스 시작**

    ```sh
    sudo systemctl enable keepalived
    sudo systemctl start keepalived
    ```

## 5. 참고 사항

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
