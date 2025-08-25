# Metadata Ingestion 인수인계

## 1. Schema

### S3 Type을 이용해 MinIO 역시 연결이 가능하나, 타입을 추가하여 처리할 수 있도록 함

1. schema.entity.services.storageservice
MinIO 타입 추가
2. schema.entity.services.connections.storage.minioConnection
MinIO 타입을 위한 연결정보 스키마
3. schema.security.credentials.minioCredentials
MinIO 타입을 위한 인증정보 스키마

### 오브젝트 스토리지 데이터로부터 메타데이터 및 프로파일링 정보를 수집하기 위한 수정

1. schema.entity.services.ingestionPipeline 의 pipelineType 추가
2. schema.metadataIngestion.workflow 에서 storageProfiler 추가
3. schema.metadataIngestion.storageServiceProfilerPipeline 추가
4. schema.metadataIngestion.storageServiceMetadataPipeline

### xlsx, doc, hwp 를 위한 타입 추가

1. schema.entity.data.Container 에서 fileformat 변경

### 비정형 메타데이터 저장을 위한 변경

1. schema.entity.data.Container 에서 rdf 추가

RDF Properties 는 key - value 형태로 구성하여 메타데이터를 처리할 수 있도록 함.
예) 작성자 - 임준범, 작성일 - 2025년06월24일

## 2. Metadata 수집

MinIO Connection Type 추가에 따른 MinIO 메타데이터, 프로파일링 코드 추가

1. src.metadata.ingestion.source.storage.minio.connection.py
2. src.metadata.ingestion.source.storage.minio.metadata.py
3. src.metadata.ingestion.source.storage.minio.models.py

4. src.metadata.readers.models.py - minioCredentials 처리 추가

Excel 파일(xls, xlsx)을 처리하기 위한 변경

1. src.metadata.readers.dataframe.reader_factory.py - xls, xlsx 파일 타입 추가
2. src.metadata.readers.dataframe.excel.py - xls 파일을(다운로드) 읽고 pandas를 이용해  dataframe 으로 변환

Encoding 오류 처리를 위해 다양한 Encoding 으로(for loop) 처리하도록 함.

1. src.metadata.readers.dataframe.common.py - euc-kr, cp949, iso-8859-1

## 3. Profiler - 기술통계(min, max, avg, ...), 샘플 데이터 수집

1. src.metadata.profiler.source.profiler_source_interface.py - minio 추가
2. src.metadata.profiler.source.storage.minio.profiler_source.py - minio 데이터(csv, xlsx, word, 한글) 파일의 프로파일(통계, 샘플) 
3. src.metadata.profiler.processor.document_core.py - 문서 처리
4. src.metadata.utils.word.hwp_extractor.py - 한글 문서
5. src.metadata.utils.word.ms_word_extractor.py - 워드 문서

## 4. Local Test

### Build

Antlr4, datamodel_generate 설치 후 다음 커맨드 실행

```sh
$make generate
```

### Metadata 테스트

MinIO 연결 및 수집 설정 정보가 포함된 yaml 파일을 이용해 로컬에서 수행 가능

1. src.metadata.cli.ingest.py
2. tests.cli_e2e.storage.minio.minio.yaml

### Profiler 테스트

1. tests.integration.profiler.test_minio_profiler.py

## 5. 개발 서버 정보(Kubernates 환경)

서버 : 192.168.109.254
네임스페이스 : datafabric

### 컨테이너 정보

```sh
$ kubectl get pod -n datafabric
NAME                               READY   STATUS    RESTARTS        AGE
dolphin-767c4fd477-hzpdt           1/1     Running   0               18h            - 데이터 융합/정제
elasticsearch-697f49f9f9-zhrmj     1/1     Running   6               235d           - OpenMetadata 검색
fabric-server-7f9cb49ffc-q782g     1/1     Running   0               209d           - OpenMetadata 서버 
hive-metastore-76b9b85d79-mcw96    1/1     Running   0               170d           - 데이터 융합/정제 모델 저장소
ingestion-6bbc78f78d-bvm9k         1/1     Running   0               77d            - OpenMetadata 메타데이터 수집
jaeger-7bbc6575c-nknlr             1/1     Running   1               170d           - 트레이싱데이터 저장소 
mariadb-storage-5c7895d687-8dp5v   1/1     Running   0               63d            - 테스트용 데이터 저장소
monitoring-6644f6f4d5-7z4fm        1/1     Running   0               99d            - 모니터링
mysql-5449967dbc-sfvh2             1/1     Running   0               186d           - OpenMetadata 저장소 
mysql-storage-7ff59788c9-fdzgw     1/1     Running   2               235d           - 테스트용 데이터 저장소
oracle-storage-56444578bb-6pwxh    1/1     Running   0               73d            - 테스트용 데이터 저장소 
ovp-67c9ff5559-tcwrg               1/1     Running   2 (100d ago)    166d           - 데이터패브릭 UI 
ovp-db-7df964d79-4rssq             1/1     Running   0               63d            - 데이터패브릭 UI 용 저장소 
recommender-6d46878cb9-pr4mk       1/1     Running   0               140d           - 데이터 추천 
trino-coord-57ff8db6bb-9fcb8       1/1     Running   33 (2d5h ago)   158d           - 데이터 융합/정제를 위한 Trino
trino-worker-0                     1/1     Running   2 (57d ago)     158d           - Trino
trino-worker-1                     1/1     Running   0               48d            - Trino
```

## 테스트 저장소 접속 정보

1. MySQL
    - HOST/PORT : 192.168.109.254:30570
    - Database : datafabric
    - ID : fabric
    - PW : fabric12#$
2. PostgreSQL
    - HOST/PORT : 192.168.106.12:5432
    - Database : fabric
    - Database Schema : public
    - ID : postgres
    - PW : fabric12#$
3. MinIO
    - HOST/PORT : 192.168.106.12:9001
    - Bucket : 2024-fabric
    - ID : fabric
    - PW : fabric12##
4. MariaDB
    - HOST/PORT : 192.168.109.254:30475
    - Database : datafabric
    - ID : fabric
    - PW : fabric12#$
