---
layout: post
title: OpenSearch Install
author: jblim0125
date: 2025-02-28
category: 2025
tags: [opensearch]
---

## 개요

Docker 환경에서 OpenSearch 를 구성하는 방법을 알아보고자 한다.

## 설치  

도커를 활용하여 설치하면 `OpenSearch` 클러스터를 구성하고 관리하는 과정을 크게 단순화할 수 있습니다.
도커 허브 또는 아마존 ECR을 통해 공식 이미지를 가져올 수 있습니다.
그리고 이 가이드에 포함된 `샘플 Docker Compose 파일`과 `Docker Compose`를 활용하여 클러스터를 빠르게 배포합니다.

이 가이드는 Linux 명령 인터페이스(CLI)에서 편안하게 작업할 수 있다고 가정합니다.
명령을 입력하고, 디렉토리 사이를 탐색하고, 텍스트 파일을 편집하는 방법을 이해해야 합니다.
필요하다면 Linux, Docker, Docker Compose 공식 문서를 참조하세요.

### Docker 및 Docker Compose 설치

공식 문서를 참조하세요.

### 중요한 호스트 설정 구성

Docker를 사용하여 OpenSearch를 설치하기 전에 다음 설정을 구성하십시오.
이러한 설정은 서비스 성능에 영향을 미칠 수 있는 가장 중요한 설정입니다.

**리눅스 설정**  

Linux 환경의 경우 다음 명령을 실행합니다.

성능을 향상시키기 위해 호스트에서 메모리 페이징 및 스왑 성능을 비활성화합니다.

```shell
sudo swapoff -a
```

OpenSearch에서 사용할 수 있는 메모리 맵의 수를 늘립니다.

```shell
# Edit the sysctl config file
sudo vi /etc/sysctl.conf

# Add a line to define the desired value
# or change the value if the key exists,
# and then save your changes.
vm.max_map_count=262144
```

```shell
# Reload the kernel parameters using sysctl
sudo sysctl -p
```

```shell
# Verify that the change was applied by checking the value
cat /proc/sys/vm/max_map_count
```

### 컨테이너 이미지 다운로드

Docker Hub

```shell
docker pull opensearchproject/opensearch:2
docker pull opensearchproject/opensearch-dashboards:2
```

Amazon

```shell
docker pull public.ecr.aws/opensearchproject/opensearch:2
docker pull public.ecr.aws/opensearchproject/opensearch-dashboards:2
```

#### 실행 테스트

계속하기 전에 OpenSearch를 단일 컨테이너에 배포하여 Docker가 올바르게 작동하는지 확인해야 합니다.
`OpenSearch 2.12` 이상인 경우 설치 전에 다음 명령을 사용하여 새 사용자 지정 관리자 암호를 설정하십시오.

```shell
# Password requires a minimum of 8 characters and must contain at least one uppercase letter,
# lowercase letter, one digit, and one special character. Password strength can be tested here: https://lowe.github.io/tryzxcvbn
$ docker run -d -p 9200:9200 -p 9600:9600 -e "discovery.type=single-node" \
-e "OPENSEARCH_INITIAL_ADMIN_PASSWORD=<custom-admin-password>" opensearchproject/opensearch:latest
```

`curl`을 사용하여 요청을 보냅니다. 관리자의 이름은 `admin` 입니다.

```shell
curl https://localhost:9200 -ku admin:<custom-admin-password>
```

다음과 같은 응답을 받게 됩니다.

```shell
{
  "name" : "a937e018cee5",
  "cluster_name" : "docker-cluster",
  "cluster_uuid" : "GLAjAG6bTeWErFUy_d-CLw",
  "version" : {
    "distribution" : "opensearch",
    "number" : <version>,
    "build_type" : <build-type>,
    "build_hash" : <build-hash>,
    "build_date" : <build-date>,
    "build_snapshot" : false,
    "lucene_version" : <lucene-version>,
    "minimum_wire_compatibility_version" : "7.10.0",
    "minimum_index_compatibility_version" : "7.0.0"
  },
  "tagline" : "The OpenSearch Project: https://opensearch.org/"
}
```

테스트가 정상적으로 완료되었다면 임시로 실행한 컨테이너를 종료합니다.

```shell
# 실행 중인 모든 컨테이너 목록을 표시하고 테스트 중인 OpenSearch 노드의 컨테이너 ID를 복사합니다. 
$ docker container ls
CONTAINER ID   IMAGE                                 COMMAND                  CREATED          STATUS          PORTS                                                                NAMES
a937e018cee5   opensearchproject/opensearch:latest   "./opensearch-docker…"   19 minutes ago   Up 19 minutes   0.0.0.0:9200->9200/tcp, 9300/tcp, 0.0.0.0:9600->9600/tcp, 9650/tcp   wonderful_boyd
# 컨테이너 ID를 docker stop 전달하여 실행 중인 컨테이너를 중지합니다.
$ docker stop <containerId>
```

### Docker Compose를 사용하여 OpenSearch 클러스터 배포

한 번에 하나의 컨테이너씩 실행하여 `OpenSearch 클러스터`를 구축하는 것은 기술적으로 가능하지만,
YAML 파일을 이용해 환경을 정의하고 `Docker Compose` 명령을 이용해 클러스터를 관리하도록 하는 것이 훨씬 쉽습니다.
다음에는 클러스터를 실행하는 데 사용할 수 있는 예제 YAML 파일이 포함되어 있습니다.
*다만, 예제 파일의 경우 테스트 및 개발에 유용하지만 프로덕션 환경에는 적합하지 않습니다.*

샘플 docker-compose.yml
```yaml
services:
  opensearch-node1: # This is also the hostname of the container within the Docker network (i.e. https://opensearch-node1/)
    image: opensearchproject/opensearch:latest # Specifying the latest available image - modify if you want a specific version
    container_name: opensearch-node1
    environment:
      - cluster.name=opensearch-cluster # Name the cluster
      - node.name=opensearch-node1 # Name the node that will run in this container
      - discovery.seed_hosts=opensearch-node1,opensearch-node2 # Nodes to look for when discovering the cluster
      - cluster.initial_cluster_manager_nodes=opensearch-node1,opensearch-node2 # Nodes eligible to serve as cluster manager
      - bootstrap.memory_lock=true # Disable JVM heap memory swapping
      - "OPENSEARCH_JAVA_OPTS=-Xms512m -Xmx512m" # Set min and max JVM heap sizes to at least 50% of system RAM
      - OPENSEARCH_INITIAL_ADMIN_PASSWORD=${OPENSEARCH_INITIAL_ADMIN_PASSWORD}    # Sets the demo admin user password when using demo configuration, required for OpenSearch 2.12 and later
    ulimits:
      memlock:
        soft: -1 # Set memlock to unlimited (no soft or hard limit)
        hard: -1
      nofile:
        soft: 65536 # Maximum number of open files for the opensearch user - set to at least 65536
        hard: 65536
    volumes:
      - opensearch-data1:/usr/share/opensearch/data # Creates volume called opensearch-data1 and mounts it to the container
    ports:
      - 9200:9200 # REST API
      - 9600:9600 # Performance Analyzer
    networks:
      - opensearch-net # All of the containers will join the same Docker bridge network
  opensearch-node2:
    image: opensearchproject/opensearch:latest # This should be the same image used for opensearch-node1 to avoid issues
    container_name: opensearch-node2
    environment:
      - cluster.name=opensearch-cluster
      - node.name=opensearch-node2
      - discovery.seed_hosts=opensearch-node1,opensearch-node2
      - cluster.initial_cluster_manager_nodes=opensearch-node1,opensearch-node2
      - bootstrap.memory_lock=true
      - "OPENSEARCH_JAVA_OPTS=-Xms512m -Xmx512m"
      - OPENSEARCH_INITIAL_ADMIN_PASSWORD=${OPENSEARCH_INITIAL_ADMIN_PASSWORD}
    ulimits:
      memlock:
        soft: -1
        hard: -1
      nofile:
        soft: 65536
        hard: 65536
    volumes:
      - opensearch-data2:/usr/share/opensearch/data
    networks:
      - opensearch-net
  opensearch-dashboards:
    image: opensearchproject/opensearch-dashboards:latest # Make sure the version of opensearch-dashboards matches the version of opensearch installed on other nodes
    container_name: opensearch-dashboards
    ports:
      - 5601:5601 # Map host port 5601 to container port 5601
    expose:
      - "5601" # Expose port 5601 for web access to OpenSearch Dashboards
    environment:
      OPENSEARCH_HOSTS: '["https://opensearch-node1:9200","https://opensearch-node2:9200"]' # Define the OpenSearch nodes that OpenSearch Dashboards will query
    networks:
      - opensearch-net

volumes:
  opensearch-data1:
  opensearch-data2:

networks:
  opensearch-net:
```

실행  

```shell
docker compose up -d
```

서비스 컨테이너가 올바르게 시작되었는지 확인합니다.

```shell
docker compose ps
```

컨테이너가 시작되지 않은 경우 로그를 확인한다.  

```shell
docker compose logs <serviceName>
```

브라우저에서 `http://localhost:5601`에 연결하여 OpenSearch 대시보드에 대한 액세스를 확인합니다.
기본 사용자 이름과 암호는 admin. 배포의 보안 구성을 사용자 정의할 때까지 공용 인터넷에서
액세스할 수 있는 호스트에서 이 구성을 사용하지 않는 것이 좋습니다.

클러스터에서 실행 중인 컨테이너를 중지합니다.

```shell
docker compose down
```

> 많은 양의 사후 설치 구성이 필요한 `OpenSearch`의 `RPM 배포판`과 달리 `Docker`로 `OpenSearch 클러스터`를 실행하면 컨테이너가 생성되기 전에 환경을 정의할 수 있습니다.

개발을 위한 샘플 Docker Compose 파일

```yaml
services:
  opensearch-node1:
    image: opensearchproject/opensearch:latest
    container_name: opensearch-node1
    environment:
      - cluster.name=opensearch-cluster # Name the cluster
      - node.name=opensearch-node1 # Name the node that will run in this container
      - discovery.seed_hosts=opensearch-node1,opensearch-node2 # Nodes to look for when discovering the cluster
      - cluster.initial_cluster_manager_nodes=opensearch-node1,opensearch-node2 # Nodes eligibile to serve as cluster manager
      - bootstrap.memory_lock=true # Disable JVM heap memory swapping
      - "OPENSEARCH_JAVA_OPTS=-Xms512m -Xmx512m" # Set min and max JVM heap sizes to at least 50% of system RAM
      - "DISABLE_INSTALL_DEMO_CONFIG=true" # Prevents execution of bundled demo script which installs demo certificates and security configurations to OpenSearch
      - "DISABLE_SECURITY_PLUGIN=true" # Disables Security plugin
    ulimits:
      memlock:
        soft: -1 # Set memlock to unlimited (no soft or hard limit)
        hard: -1
      nofile:
        soft: 65536 # Maximum number of open files for the opensearch user - set to at least 65536
        hard: 65536
    volumes:
      - opensearch-data1:/usr/share/opensearch/data # Creates volume called opensearch-data1 and mounts it to the container
    ports:
      - 9200:9200 # REST API
      - 9600:9600 # Performance Analyzer
    networks:
      - opensearch-net # All of the containers will join the same Docker bridge network
  opensearch-node2:
    image: opensearchproject/opensearch:latest
    container_name: opensearch-node2
    environment:
      - cluster.name=opensearch-cluster # Name the cluster
      - node.name=opensearch-node2 # Name the node that will run in this container
      - discovery.seed_hosts=opensearch-node1,opensearch-node2 # Nodes to look for when discovering the cluster
      - cluster.initial_cluster_manager_nodes=opensearch-node1,opensearch-node2 # Nodes eligibile to serve as cluster manager
      - bootstrap.memory_lock=true # Disable JVM heap memory swapping
      - "OPENSEARCH_JAVA_OPTS=-Xms512m -Xmx512m" # Set min and max JVM heap sizes to at least 50% of system RAM
      - "DISABLE_INSTALL_DEMO_CONFIG=true" # Prevents execution of bundled demo script which installs demo certificates and security configurations to OpenSearch
      - "DISABLE_SECURITY_PLUGIN=true" # Disables Security plugin
    ulimits:
      memlock:
        soft: -1 # Set memlock to unlimited (no soft or hard limit)
        hard: -1
      nofile:
        soft: 65536 # Maximum number of open files for the opensearch user - set to at least 65536
        hard: 65536
    volumes:
      - opensearch-data2:/usr/share/opensearch/data # Creates volume called opensearch-data2 and mounts it to the container
    networks:
      - opensearch-net # All of the containers will join the same Docker bridge network
  opensearch-dashboards:
    image: opensearchproject/opensearch-dashboards:latest
    container_name: opensearch-dashboards
    ports:
      - 5601:5601 # Map host port 5601 to container port 5601
    expose:
      - "5601" # Expose port 5601 for web access to OpenSearch Dashboards
    environment:
      - 'OPENSEARCH_HOSTS=["http://opensearch-node1:9200","http://opensearch-node2:9200"]'
      - "DISABLE_SECURITY_DASHBOARDS_PLUGIN=true" # disables security dashboards plugin in OpenSearch Dashboards
    networks:
      - opensearch-net

volumes:
  opensearch-data1:
  opensearch-data2:

networks:
  opensearch-net:
```