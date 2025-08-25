# Open Metadata - Ingestion 코드 분석

## 개요  

이 문서에서는 Open Metadata의 대략적인 구조와 데이터 소스 추가, 메타데이터 수집 동작에 대해서 분석한다.  
그 과정에서 추가적으로 확인된 내용을 정리하여 기록한다.  

## Platform 구조

- 다음 그림과 소스 구조를 참고하여 분석 진행  
    ![Arch](2024-04-02-13-openmetadata-arch.png)

- Source Tree  

    ```text
    .
    ├── common                          # 프로젝트 공통 사용 라이브러리(annotation, ...)
    ├── ingestion                       # Airflow에서 구동되는 Python Code( airflow-apis 에서 호출되거나, workflow 를 통해 실행 )
    ├── openmetadata-airflow-apis       # Airflow PlugIn으로 동작. open metadata server - airflow 간 통신을 위한 RestAPI 서버  
    ├── openmetadata-service            # 백엔드 서비스 (DropWizard)
    ├── openmetadata-shaded-deps        # 검색 엔진 관련  
    └── openmetadata-spec               # JSON Schema( Interface, DB Schema )
    ```

- 모듈 별 개발 언어  

    ```text
    .
    ├── common                          # Java
    ├── ingestion                       # Python 
    ├── openmetadata-airflow-apis       # Python 
    └── openmetadata-service            # Java 
    ```

- open metadata 서버의 기본 구조  
    DataModel, InterfaceModel은 대부분?(모두?) jsonschema2pojo 에 의해 생성된다.  
    3 Layer 형태의 Controller - Service - Repository 의 구조가 아님.  
    `Controller Extends EntityResource<DataModel, Repository<DataModel>>` 형태를 띔.  

## 소스 구조  

주요 모듈들의 소스 구조 설명  

### open metadata spec

데이터 원형(Interface), antlr4, json으로 이루어진 open metadata에서 사용될 데이터  

```text
openmetadata-spec/src
└─ main
   ├── antlr4
   │   └── org
   │       └── openmetadata
   │           └── schema
   ├── java
   │   └── org
   │       └── openmetadata
   │           ├── schema
   │           │   └── utils
   │           └── sdk
   │               └── exception
   └── resources
       └── json
           └── schema
               ├── analytics
               │   ├── reportDataType
               │   └── webAnalyticEventType
               ├── api
               │   ├── analytics
               │   ├── automations
               │   ├── classification
               │   ├── data
               │   ├── dataInsight
               │   │   └── kpi
               │   ├── docStore
               │   ├── domains
               │   ├── feed
               │   ├── lineage
               │   ├── policies
               │   ├── services
               │   │   └── ingestionPipelines
               │   ├── teams
               │   └── tests
               ├── auth
               ├── configuration
               │   └── ldapTrustStoreConfig
               ├── dataInsight
               │   ├── kpi
               │   └── type
               ├── email
               ├── entity
               │   ├── applications
               │   │   ├── configuration
               │   │   │   ├── external
               │   │   │   ├── internal
               │   │   │   └── private
               │   │   │       └── external
               │   │   └── marketplace
               │   ├── automations
               │   ├── classification
               │   ├── data
               │   ├── docStore
               │   ├── domains
               │   ├── events
               │   ├── feed
               │   ├── policies
               │   │   └── accessControl
               │   ├── services
               │   │   ├── connections
               │   │   │   ├── common
               │   │   │   ├── dashboard
               │   │   │   ├── database
               │   │   │   │   ├── common
               │   │   │   │   ├── datalake
               │   │   │   │   └── iceberg
               │   │   │   ├── messaging
               │   │   │   ├── metadata
               │   │   │   ├── mlmodel
               │   │   │   ├── pipeline
               │   │   │   ├── search
               │   │   │   │   └── elasticSearch
               │   │   │   └── storage
               │   │   └── ingestionPipelines
               │   ├── teams
               │   └── utils
               ├── events
               │   └── api
               ├── metadataIngestion
               │   ├── dbtconfig
               │   └── storage
               ├── monitoring
               ├── security
               │   ├── client
               │   ├── credentials
               │   ├── secrets
               │   └── ssl
               ├── settings
               ├── system
               │   └── ui
               ├── tests
               └── type
                   └── customProperties
```

### open metadata server

UI - Server - Airflow - Remote Source 구성 중 Server  
openmetadata-spec 에서 선언된 데이터를 이용해 RESTApi Server역할을 수행한다.  

```text
openmetadata-service/src/main/java/org/openmetadata/service
├── apps
│   ├── bundles
│   │   ├── changeEvent
│   │   │   ├── email
│   │   │   ├── gchat
│   │   │   ├── generic
│   │   │   ├── msteams
│   │   │   └── slack
│   │   ├── insights
│   │   ├── searchIndex
│   │   └── test
│   └── scheduler
├── auth
├── clients
│   └── pipeline
│       ├── airflow
│       └── noop
├── config
├── dataInsight
├── events
│   ├── errors
│   ├── scheduled
│   │   └── template
│   └── subscription
├── exception
├── fernet
├── formatter
│   ├── decorators
│   ├── entity
│   ├── factory
│   ├── field
│   └── util
├── jdbi3
│   └── locator
├── migration
│   ├── api
│   ├── context
│   ├── mysql
│   ├── postgres
│   └── utils
├── monitoring
├── resources
│   ├── analytics
│   ├── apps
│   ├── automations
│   ├── bots
│   ├── charts
│   ├── dashboards
│   ├── databases
│   ├── datainsight
│   ├── datamodels
│   ├── docstore
│   ├── domains
│   ├── dqtests
│   ├── events
│   │   └── subscription
│   ├── feeds
│   ├── glossary
│   ├── kpi
│   ├── lineage
│   ├── metrics
│   ├── mlmodels
│   ├── permissions
│   ├── pipelines
│   ├── policies
│   ├── query
│   ├── reports
│   ├── search
│   ├── searchindex
│   ├── services
│   │   ├── connections
│   │   ├── dashboard
│   │   ├── database
│   │   ├── ingestionpipelines
│   │   ├── messaging
│   │   ├── metadata
│   │   ├── mlmodel
│   │   ├── pipeline
│   │   ├── searchIndexes
│   │   └── storage
│   ├── settings
│   ├── storages
│   ├── system
│   ├── tags
│   ├── teams
│   ├── topics
│   ├── types
│   ├── usage
│   └── version
├── search
│   ├── elasticsearch
│   │   └── dataInsightAggregators
│   ├── indexes
│   ├── models
│   └── opensearch
│       └── dataInsightAggregator
├── secrets
│   ├── converter
│   └── masker
├── security
│   ├── auth
│   ├── jwt
│   ├── mask
│   ├── policyevaluator
│   └── saml
├── socket
├── util
│   ├── incidentSeverityClassifier
│   └── jdbi
└── workflows
    ├── interfaces
    └── searchIndex
```

### open metadata api(airflow plugin)  

Airflow Plugin 으로 Airflow Container에서 RESTApi Server 역할  
Pipeline(DAG) 관련 기능(생성, 삭제, 시작, 중지, 로그 등)  
Ingestion 모듈을 이용한 Test Connection 등 기능을 제공한다.  

```text
openmetadata-airflow-apis/openmetadata_managed_apis/
├── api                 # RESTApi Controller Layer
│   └── routes
├── operations          # 워크플로우 관리(시작, 중지)
├── resources           # DAG Base
├── utils               # 로그  
├── views               # 화면 ( extends airflow/main.html )
└── workflows           # Workflow(DAG) 생성  
    └── ingestion       # Pipeline Type 별 
```

### ingestion  

Python 으로 작성되었으며, Airflow Container 내에서 동작되는 기능들의 대부분은 이 모듈이다.  
Airflow의 DAG 구성(PythonOperator)를 따르지만 TASK 여러개가 아닌 하나의 Task 안에 자체적으로 Node[Stage[]] 구성으로 단계 별 실행된다.  

```text
ingestion/src/metadata
├── antlr
├── applications
├── automations
├── cli
├── clients                    
├── config
├── data_insight
│   ├── processor
│   │   ├── kpi
│   │   └── reports
│   ├── producer
│   └── source
├── data_quality
│   ├── api
│   ├── interface
│   │   ├── pandas
│   │   └── sqlalchemy
│   ├── processor
│   ├── runner
│   ├── source
│   └── validations
│       ├── column
│       ├── mixins
│       └── table
├── examples
│   └── workflows
├── generated                   # schema
│   ├── antlr
│   └── schema
│       ├── analytics
│       ├── api
│       ├── auth
│       ├── configuration
│       ├── dataInsight
│       ├── email
│       ├── entity
│       ├── events
│       ├── metadataIngestion
│       ├── monitoring
│       ├── security
│       ├── settings
│       ├── system
│       ├── tests
│       └── type
├── great_expectations
│   └── utils
├── ingestion
│   ├── api
│   ├── bulksink
│   ├── connections
│   ├── lineage
│   ├── models
│   ├── ometa
│   │   └── mixins
│   ├── processor
│   ├── sink
│   ├── source
│   │   ├── dashboard
│   │   ├── database
│   │   ├── messaging
│   │   ├── metadata
│   │   ├── mlmodel
│   │   ├── pipeline
│   │   ├── search
│   │   └── storage
│   └── stage
├── mixins
│   ├── pandas
│   └── sqalchemy
├── parsers
├── pii
│   └── scanners
├── profiler
│   ├── api
│   ├── interface
│   │   ├── pandas
│   │   └── sqlalchemy
│   ├── metrics
│   │   ├── composed
│   │   ├── hybrid
│   │   ├── static
│   │   ├── system
│   │   └── window
│   ├── orm
│   │   ├── converter
│   │   ├── functions
│   │   └── types
│   ├── processor
│   │   └── sampler
│   └── source
│       ├── base
│       ├── bigquery
│       ├── mariadb
│       └── single_store
├── readers
│   ├── dataframe
│   └── file
├── timer
├── utils
│   ├── datalake
│   └── secrets
└── workflow
```

## 기능 별 코드 분석  

1. 연결 테스트와 데이터 소스 추가  
2. Workflow(IngestionPipeline) 추가  
3. Workflow(IngestionPipeline) 실행  

### 1. 연결 테스트와 데이터 소스 추가

- 요약  
    1. Test Connection  
        1.1. create workflow  
        1.2. start workflow  
        1.3. get status  
        1.4. delete workflow  
    2. Add Data Source  

1. Request Test Connect : Create Workflow  
    `POST URL: http://192.168.105.33:8585/api/v1/automations/workflows`  

    ```json
    {
        "name": "test-connection-Mysql-ywrWRyxW",
        "workflowType": "TEST_CONNECTION",
        "request": {
            "connection": {
                "config": {
                    "type": "Mysql",
                    "scheme": "mysql+pymysql",
                    "supportsMetadataExtraction": true,
                    "supportsDBTExtraction": true,
                    "supportsProfiler": true,
                    "supportsQueryComment": true,
                    "sampleDataStorageConfig": {},
                    "username": "root",
                    "authType": {
                        "password": "!BigDaTa99%"
                    },
                    "hostPort": "192.168.107.19:3308"
                }
            },
            "serviceType": "Database",
            "connectionType": "Mysql"
        }
    }
    ```

2. Receive Test Connect : Create Workflow  
    소스 위치 : `/service/resources/automations/WorkflowResource.java`  
    1) 요청 정보를 바탕으로 workflow 생성  
        airflow에 작업을 시키는 목적 + airflow 에서 작업 완료 후 open metadata로 결과를 전달할 수 있도록 정보를 세팅?
    2) connection 정보 추가  
        1) botRepository  
        2) userRepository  
        3) openMetadataURL  
        4) SSL  
        5) SSLConfig  
        6) clusterName  
        7) secretsManagerLoader  
        8) secretsManagerProvider  
    3) 인증 정보 추가  
    4) workflow -> entity 변경(통신구조체에서 저장구조체)  
    5) 데이터 저장  

3. Request Test Connect Start : Workflow Trigger  
    POST URL : `/api/v1/automations/workflows/trigger/c48da2ac-12dc-4dc3-8b5a-69dcd198aceb`  

4. Receive Test Connect Start : Workflow Trigger  
    소스 위치 : `/service/resources/automations/WorkflowResource.java/runAutomationsWorkflow`  
    1) 저장소로부터 workflow 정보 로드  
    2) workflow 에 연결정보 설정  
    3) runAutomationWorkflow  
    4) workflow (POST : `/run_automation`) 전송  
        소스 위치 : `/service/clients/pipeline/airflow/AirflowRESTClient.java/runAutomationsWorkflow`  
        1) URI 빌드 ( `airflow 서버 URI + path : /api/v1/openmetadata/run_automation` )  
        2) workflow 전송 -> airflow 서버  

5. airflow - plugin : test connect 작업 요청 수신  
    소스 위치 : `/airflow-apis/api/routes/run_automation.py/run_automation`  
    1) `metadata.automations.runner.excute` 실행  
    2) run_workflow -> @run_workflow.register : metadata/automations/runner.py  
    3) get_connection -> service-type(database), connection-type(mysql)의 경우 SQLAlchemy 의 Engine 을 리턴  
        엔진의 경우 쿼리 실행 전 open metadata 에서 쿼리를 수행했음을 알리기위해 쿼리 실행 직전 호출 될 콜백을 설정,  
        `SQL /* app = open metadata, version = x.y.z */ .. from XYZ` 로 변경함.  
    4) get_test_connection => 데이터 베이스 연결 테스트 함수 반환  
        다양한 서비스 타입과 연결 타입을 지원하는 방법으로 dynamic import 를 사용하고 있음.  
        `metadata.ingestion.source.{service-type}.{connection-type}.connection.py / {function-name}`  
        신규 서비스와 연결 타입을 위해 추가하는 경우 지정된 위치(service-type, connection-type)에 connection.py 구현 필요  
    5) test_connection_fn 설정  
        1) "CheckAccess": partial(test_connection_engine_step, engine), => SQLAlchemy.connect() And execute("select 42")  
        2) "GetSchemas": partial(execute_inspector_func, engine, "get_schema_names"), => SQLAlchemy.inspector.function()  
        3) "GetTables": partial(custom_executor, engine, "get_table_names"), => SQLAlchemy.inspector.get_schema().get_tables()  
        4) "GetViews": partial(custom_executor, engine, "get_view_names"), => SQLAlchemy.inspector.get_schema().get_views()  
    6) test_connection_steps 호출  
    7) test_connection_fn 을 차례대로 호출
        1) timer(timeout) ->  
        2) _test_connection_steps  
            metadata/ingestion/connections/test_connections.py  
        3) `_test_connection_steps_automation_workflow` or `_test_connection_steps_during_ingestion`  
            metadata/ingestion/connections/test_connections.py  
        4) Step 마다 RestAPI(PATCH Workflow)로 실행 결과를 전송 함.  
        5) Backend Server의 REST API : PATCH /automations/workflow/{id} 를 통해 정보를 수신하고 workflow 정보를 업데이트  

6. Get Result ()  
    요청 `GET /api/v1/automations/workflows/c48da2ac-12dc-4dc3-8b5a-69dcd198aceb`  
    Referer: `http://192.168.105.33:8585/databaseServices/add-service`  
    Database에 저장된 Workflow의 정보를 반환  
    5단계에서 수행된 PATCH에 의해 Step(CheckAccess, GetSchemas, GetTables, GetViews)들의 결과가 전달된다.  

7. Delete  
    요청 `DELETE /api/v1/automations/workflows/c48da2ac-12dc-4dc3-8b5a-69dcd198aceb`  
    workflow 삭제  

8. 데이터베이스 연결정보 추가 요청  
    요청 : `POST /api/v1/databases`  

    ```json
    {
        "name": "",
        "displayName": "",
        "description": "markdown",
        "tags": [
            tagLabel{
                "tagFQN":"",
                "name": "",
                "displayName": "",
                "description": "markdown",
                "style":"",
                "source":"",
                "labelType": enum["Manual", "Propagated", "Automated", "Derived"],
                "state": enum["Suggested", "Confirmed"],
                "href": "uri"
            }
        ],
        "owner": EntityReference{
            "id": "uuid",
            "type": "",
            "name": "",
            "fullQualifiedName": "",
            "description":"markdown",
            "displayName": "",
            "deleted": "boolean",
            "inherited": "boolean",
            "href": "href"
        },
        "service": "",
        "dataProducts": ["", ""],
        "default": "boolean",
        "retentionPeriod": "보존기간[ISO 8601] ex-P23DT23H", 
        "extension": "",
        "sourceUrl": "database url",
        "domain" : "",
        "lifeCycle": {
            "created": {
                "timestamp": "",
                "accessedBy": "",
                "accessedByProcess": ""
            },
            "updated": {
                "timestamp": "",
                "accessedBy": "",
                "accessedByProcess": ""
            },
            "accessed": {
                "timestamp": "",
                "accessedBy": "",
                "accessedByProcess": ""
            },
        },
        "sourceHash": "",
    }
    ```

    동작 : 데이터베이스(검색엔진)에 리소스 정보 저장  

    내부 동작 :  

    1) 권한확인(수행 명령, 리소스, 사용자 정보 전달)  
    2) 저장소 저장  
        a) 데이터 검증(태그, 확장, 도메인 등)  
        b) 데이터 저장  
        c) 검색엔진 저장소에도 저장  
    3) 데이터와 관련된 정보들의 링크정보 추가(소유자, 리뷰어 기타)  

## 2. Workflow(IngestionPipeline) 추가  

1. Write Meta Ingestion  
    이름, 필터, 옵션 설정  

2. 메타데이터 수집 워크플로우 생성 요청( UI -> Backend Server )  
    요청 : `POST /api/v1/services/ingestionPipelines`  
    Content-Type: application/json  
    Message :  

    ```json
    {
        "airflowConfig": {
            "scheduleInterval": "0 * * * *",
            "startDate": "2024-04-01T00:00:00.000Z",
            "retries": "3"
        },
        "loggerLevel": "INFO",
        "name": "mysql_5_7_metadata_ONXMvIHm",
        "displayName": "mysql metadata ingestion",
        "owner": {
            "id": "03f1c929-2d1d-44ab-bac1-459b712fcbb1",
            "type": "user"
        },
        "pipelineType": "metadata",
        "service": {
            "id": "c0eaae79-e421-44cf-8e31-40eef4bf4940",
            "type": "databaseService"
        },
        "sourceConfig": {
            "config": {
                "type": "DatabaseMetadata",
                "markDeletedTables": true,
                "markDeletedStoredProcedures": true,
                "includeTables": true,
                "includeViews": true,
                "includeTags": true,
                "includeOwners": true,
                "includeStoredProcedures": true,
                "queryLogDuration": 10,
                "queryParsingTimeoutLimit": 300,
                "useFqnForFiltering": true
            }
        }
    }
    ```

    위치 : `org.metadata/service/resources/services/ingestionPipelines.java`  

    1) 데이터 구조 변경 : 통신 -> 저장  
    2) 권한 확인과 저장  
    3) 응답메시지  
    응답 : 201 Created  
    Content-Type: application/json  
    Location: `/api/v1/services/ingestionPipelines/8419a84e-78f1-463c-9b99-43ae434fac72`  
    메시지  

    ```json
    {
        "id": "8419a84e-78f1-463c-9b99-43ae434fac72",
        "name": "mysql_5_7_metadata_ONXMvIHm",
        "displayName": "mysql metadata ingestion",
        "pipelineType": "metadata",
        "owner": {
            "id": "03f1c929-2d1d-44ab-bac1-459b712fcbb1",
            "type": "user",
            "name": "admin",
            "fullyQualifiedName": "admin",
            "deleted": false,
            "href": "http://192.168.105.33:8585/api/v1/users/03f1c929-2d1d-44ab-bac1-459b712fcbb1"
        },
        "fullyQualifiedName": "\"mysql 5.7\".mysql_5_7_metadata_ONXMvIHm",
        "sourceConfig": {
            "config": {
                "type": "DatabaseMetadata",
                "markDeletedTables": true,
                "markDeletedStoredProcedures": true,
                "includeTables": true,
                "includeViews": true,
                "includeTags": true,
                "includeOwners": true,
                "includeStoredProcedures": true,
                "queryLogDuration": 10,
                "queryParsingTimeoutLimit": 300,
                "useFqnForFiltering": true
            }
        },
        "openMetadataServerConnection": {
            "clusterName": "openmetadata",
            "type": "OpenMetadata",
            "hostPort": "http://openmetadata-server:8585/api",
            "authProvider": "openmetadata",
            "verifySSL": "no-ssl",
            "securityConfig": {
                "jwtToken": "eyJraWQiOiJHYjM4OWEtOWY3Ni1nZGpzLWE5MmotMDI0MmJrOTQzNTYiLCJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJvcGVuLW1ldGFkYXRhLm9yZyIsInN1YiI6ImluZ2VzdGlvbi1ib3QiLCJlbWFpbCI6ImluZ2VzdGlvbi1ib3RAb3Blbm1ldGFkYXRhLm9yZyIsImlzQm90Ijp0cnVlLCJ0b2tlblR5cGUiOiJCT1QiLCJpYXQiOjE3MTEzNTg2MTYsImV4cCI6bnVsbH0.X8MQNUwaGpSnyGSxZMfvmgPWjALk3HMZHjxc4U0sQcQPiPeJ5PTp9xrDLtOkJhy7ToNi8T6pVj8tOwoANChoaQOhuXltE1o_TYUjmERX2TyD-EWHtpLIug0yQgeidOc3w5gQFQIiI84u8joLFsfJpYrbP8Uwx3YfHcQn7zoFlyb4rlqRQvaqh2ll0xHi7a18b-IQGKHvqhUld0s5Y0XjhsIcrNhA2KkZo5ZnCcRS1J1r9wtL8NUBFlQCGMVHnl0ugSdurvrOSCvaKi1Jcd12vuaF4by0NEUUjl9Zso1r6nBsU8jQRLiQNBA7T_x6DHkTICePV2FxD3PcdIZDm9bL5w"
            },
            "secretsManagerProvider": "db",
            "secretsManagerLoader": "noop",
            "apiVersion": "v1",
            "includeTopics": true,
            "includeTables": true,
            "includeDashboards": true,
            "includePipelines": true,
            "includeMlModels": true,
            "includeUsers": true,
            "includeTeams": true,
            "includeGlossaryTerms": true,
            "includeTags": true,
            "includePolicy": true,
            "includeMessagingServices": true,
            "enableVersionValidation": true,
            "includeDatabaseServices": true,
            "includePipelineServices": true,
            "limitRecords": 1000,
            "forceEntityOverwriting": false,
            "storeServiceConnection": true,
            "supportsDataInsightExtraction": true,
            "supportsElasticSearchReindexingExtraction": true
        },
        "airflowConfig": {
            "pausePipeline": false,
            "concurrency": 1,
            "startDate": 1711929600000,
            "pipelineTimezone": "UTC",
            "retries": 3,
            "retryDelay": 300,
            "pipelineCatchup": false,
            "scheduleInterval": "0 * * * *",
            "maxActiveRuns": 1,
            "workflowDefaultView": "tree",
            "workflowDefaultViewOrientation": "LR"
        },
        "service": {
            "id": "c0eaae79-e421-44cf-8e31-40eef4bf4940",
            "type": "databaseService",
            "name": "mysql 5.7",
            "fullyQualifiedName": "\"mysql 5.7\"",
            "description": "플랫폼팀 mysql 5.7",
            "deleted": false,
            "href": "http://192.168.105.33:8585/api/v1/services/databaseServices/c0eaae79-e421-44cf-8e31-40eef4bf4940"
        },
        "loggerLevel": "INFO",
        "deployed": false,
        "enabled": true,
        "href": "http://192.168.105.33:8585/api/v1/services/ingestionPipelines/8419a84e-78f1-463c-9b99-43ae434fac72",
        "version": 0.1,
        "updatedAt": 1712040832307,
        "updatedBy": "admin",
        "deleted": false,
        "provider": "user"
    }
    ```

3. Deploy 요청  
    1. Create IngestionPipeline 응답으로 전달한 링크와 Auth Token을 이용해 Ingestion Pipeline Deploy 요청  
    요청 : POST `/api/v1/services/ingestionPipelines/deploy/8419a84e-78f1-463c-9b99-43ae434fac72` HTTP/1.1  
    Authorization: Bearer eyJraWQiOiJHYjM4OWEtOWY3Ni1nZGpzLWE5MmotMDI0MmJrOTQzNTYiLCJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJvcGVuLW1ldGFkYXRhLm9yZyIsInN1YiI6ImFkbWluIiwiZW1haWwiOiJhZG1pbkBvcGVubWV0YWRhdGEub3JnIiwiaXNCb3QiOmZhbHNlLCJ0b2tlblR5cGUiOiJPTV9VU0VSIiwiaWF0IjoxNzEyMDM5NjEzLCJleHAiOjE3MTIwNDMyMTN9.V6SuZzE75pvTXFu5tcVxGwhHCjf1QtimxAPP0cyx4TjxIIMtm1U1meMNeHDMdJdf7PBOlZRlmibr_Jx07-uYHIIOVxNpWZYb5EjFr2foCBSmp436C60byaHyr_QKJVguUGuXLxbl5LqXZ07BAHKLSRipzdeBFXgD_E6qCCMNc8NVgOoir3P_Aub3c59AicmGKgql7nIG-YLTsMThr9eHvXScb8viL0Mf8MXFo5NzKKtoXXni5bkYZl_-Wa4FgW0RKVW2YUZ4bSPhS1_HKgwveg2r7-fZ5CwH-1qzOVECpSWSqQIogy71OjDLK5FWuo3shluCPomGaQeWP1P5nsQ2BA  
    Referer: `http://192.168.105.33:8585/databaseServices/add-service`  
    2. IngestionPipeline 정보 로드  
        Owner, ID를 이용해 저장소로부터 IngestionPipeline 데이터 로드.  
    3. pipelineClient 를 이용해 airflow 서버로 ingestionPipeline 전송 -> 4번단계 수행  
    4. 정상적으로 deploy 된 경우 createorupdate 를 호출하여 ingestionPipeline의 상태를 업데이트(저장)  

4. airflow 서버  
    1. `routes/deploy.py` : 수신 메시지 `IngestionPipeline` 를 JSON 파일로 떨굼.
    2. `dag_id.json` 이름의 `IngestionPipeline`과 `dag_runner.j2`을 이용해 DAG 생성용 Python 파일을 만듬  

        ```python
        """
        This file has been generated from dag_runner.j2
        """
        from airflow import DAG
        from openmetadata_managed_apis.workflows import workflow_factory

        workflow = workflow_factory.WorkflowFactory.create("{{ workflow_config_file }}")
        workflow.generate_dag(globals())
        dag = workflow.get_dag()
        ```

        DAG 생성을 위해 Service 정보를 포함한 몇가지 정보를 요청하여 Config를 작성
        (OpenMetadata Server와 통신)

    3. 저장된 DAG 파일(python)을 DAG 리스트에 등록  
        DAG 리스트에서 동기화 수행(DB 저장)  
        스케쥴러 등록  
    4. 모두 정상적으로 완료된 경우 DAG_ID 정보를 리턴  
    5. `dag_runner.j2`에 의해 생성된 DAG 형태는 다음 참조  

        ```text
        DAG {
            task_id: task_name
            python_callable:  workflow/ingestion/common.py:metadata_ingestion_workflow(OpenMetadataWorkflowConfig)
            op_kwargs: {"workflow_config": 
                OpenMetadataWorkflowConfig
                    source : WorkflowSource
                        serviceName: str
                        serviceConnection : ServiceConnection
                            __root__: Union[ DatabaseConnection, ... ]
                                config: Union[ MysqlConnection, ... ]
                                    username
                                    password
                                    hostPort
                                    ...
                        sourceConfig: SourceConfig
                            config: Union[ databaseServiceMetadataPipeline, ...]
                                includeTables
                                includeViews
                                includeTags
                    sink: Sink
                    workflowConfig: 
                        openMetadataServerConfig : OpenMetadataConnection
                            clusterName
                            hostPort
                            sslConfig
                            ...
            }
            ...
        }
        ```

## 3. Workflow(IngestionPipeline) 실행  

워크 플로우 실행 과정을 살펴보기 전 다음 그림을 확인  
![alt text](omd-func-arch.png)

1. Trigger  
    정상적인 경우 스케줄러에 의해 정해진 시간(규칙)에 따라 동작하며, Trigger는 수동 실행 명령  
    pipelineClient를 이용해 airflow 서버로 POST `/trigger` 전송  

    ```json
    {
        "dag_id" : "ingestionPipelineName"
    }
    ```

2. DAG에 등록된  PythonOperator 에 의해 동작  
    python_callback = common.py:metadata_ingestion_workflow(OpenMetadataWorkflowConfig)  

    ```python
    def metadata_ingestion_workflow(config: OpenMetadataWorkflowConfig):
        set_operator_logger(workflow_config)

        config = json.loads(workflow_config.json(encoder=show_secrets_encoder))
        workflow = MetadataWorkflow.create(config)

        workflow.execute()
        workflow.raise_from_status()
        print_status(workflow)
        workflow.stop()
    ```

    여기서 호출되는 MetadataWorkflow 의 상속관계 정보  

    ```text
    MetadataWorkflow <- IngestionWorkflow <- BaseWorkflow <- WorkflowStatusMixin
    ```

3. create(config) -> IngestionWorkflow.create()  
    1. Workflow을 위한 Config를 설정하기 위해 받은 Config를 Parsing
    2. cls.__init__()  
        1. Get Config( OpenMetadataWorkflowConfig )  
        2. Get Service Type From Config  
        3. Get OpenMetadataServerConfig From Config  
        4. BaseWorkflow.__init__()  
           1. Config  
           2. ServiceType  
           3. Timer  
           4. Ingestion_Pipeline  
           5. StartTime  
           6. Init ExecutionTimeTracker  
           7. set logger level  
           8. `create_ometa_client()`: metadata/ingestion/ometa/client_utils.py  
                1. metadata = `OpenMetadata()`  
                    1. Open Metadata Server와 통신용 Rest Client 초기화 ( 버전 체크 )  
                2. metadata.health_check()  
                3. return metadata  
           9. post_init() -> IngestionWorkflow.post_init()  
                1. _retrieve_service_connection_if_needed(service_type)  
                    1. 데이터 저장소 정보를 요청 -> 수신받아 Source Config 설정  
                2. set_steps(): -> MetadataWorkflow.set_steps()
                    1. source = _get_source()  
                        1. source_class = import_from_module( service connection sourcePythonClass)  
                        이 예제에서는 mysql+pymysql ( metadata/ingestion/source/database/mysql/metadata.py )
                        2. source_class.create()
                            1. metadata/ingestion/source/database/common_db_source.py : __init__  ( WorkflowSource, OpenMetadata(서버 연결용))  
                                1. metadata = 서버 연결 용  
                                2. service_connection = 서비스 연결 정보 config  
                                3. connection_obj = engine = 실제 디비 연결 용  
                                4. test_connection() 연결 테스트  
                                5. super.__init()  : `metadata/ingestion/source/database/common_db_source.py`  
                                    DatabaseServiceSource, SqlColumnHandlerMixin, SqlAlchemySource, ABC 를 상속  
                        3. source_class.prepare() : DatabaseService : pass  
                    2. sink = _get_sink()  
                        1. set sink_type : metadata-rest  
                        2. import_sink_class() : metadata/utils/importer.py  
                        module : metadata/ingestion/sink/metadata_rest.py  
                        3. set sink_config  
                        4. sink_class(metadata_rest.py).create()  
                    3. steps(sink, )  
4. execute() -> BaseWorkflow.execute()
    1. start timer : thread  
    2. set_ingestion_pipeline_status :  
        1. open metadata server로 pipeline 상태 정보 전송(`PUT CreateOrUpdate ingestion/{name}/pipelineStatus`)
    3. execute_internal() : IngestionWorkflow.execute_internal()  

        ```python
        # IngestionWorkflow Loop
        def execute_internal():
            for record in self.source.run():
                processed_record = record
                for step in self.steps:
                    # We only process the records for these Step types
                    if processed_record is not None and isinstance(
                        step, (Processor, Stage, Sink)
                    ):
                        processed_record = step.run(processed_record)

            # Try to pick up the BulkSink and execute it, if needed
            bulk_sink = next(
                (step for step in self.steps if isinstance(step, BulkSink)), None
            )
            if bulk_sink:
                bulk_sink.run()
        
        # class Source(IterStep) 
        def run(self) -> Iterable[Optional[Entity]]:
            yield from super().run()

        # class IterStep(Step) -> Step._iter() {abstract} -> TopologyRunnerMixin._iter()
        def run() -> Iterable[Optional[Entity]]:
             for result in self._iter():
                if result.left is not None:
                    self.status.failed(result.left)
                    yield None

                if result.right is not None:
                    self.status.scanned(result.right)
                    yield result.right
        
        # class TopologyRunner() 
        # 여기서 사용되는 topology 는 class DatabaseServiceTopology(ServiceTopology) 를 사용  
        # DatabaseServiceTopology 는 다음장 참고  
        def _iter(self) -> Iterable[Either]:
            yield from self.process_nodes(get_topology_root(self.topology))
        
        def process_nodes(get_topology_root(self.topology)) -> Iterable[Entity]:
            for node in nodes:
                logger.debug(f"Processing node {node}")
                node_producer = getattr(self, node.producer)
                child_nodes = self._get_child_nodes(node)

                # Each node producer will give us a list of entities that we need
                # to process. Each of the internal stages will sink result to OM API.
                # E.g., in the DB topology, at the Table TopologyNode, the node_entity
                # will be each `table`
                for node_entity in node_producer() or []:
                    for stage in node.stages:
                        yield from self._process_stage(
                            stage=stage, node_entity=node_entity, child_nodes=child_nodes
                        )

                    # Once we are done processing all the stages,
                    for stage in node.stages:
                        if stage.clear_context:
                            self.context.clear_stage(stage=stage)

                    # process all children from the node being run
                    yield from self.process_nodes(child_nodes)

                yield from self._run_node_post_process(node=node)
        
        def _process_stage(...) -> Iterable[Entity]:
            logger.debug(f"Processing stage: {stage}")

            stage_fn = getattr(self, stage.processor)
            for entity_request in stage_fn(node_entity) or []:
                try:
                    # yield and make sure the data is updated
                    yield from self.sink_request(stage=stage, entity_request=entity_request)
                except ValueError as err:
                    logger.debug(traceback.format_exc())
                    logger.warning(
                        f"Unexpected value error when processing stage: [{stage}]: {err}"
                    )

            if stage.cache_entities:
                self._init_cache_dict(stage=stage, child_nodes=child_nodes)

        ```

        ```text
        for node in topology.nodes():
            for node_entity in node.producer():
                for stage in node.stages():
                    for stage_fn(node_stage_function()
                        yield from self.sink_request()

        ```

    4. 성공으로 판단하는 기준을 넘어서면 부분 성공으로 pipeline status 를 변경  
    5. build_ingestion_status() : step 에서 수집된 결과를 서버로 전송  
    6. set_ingestion_pipeline_status
    7. stop()
5. raise_from_status()  
6. print_status(workflow)  
7. workflow.stop()  

## Database Metadata Topology  

```python
class DatabaseServiceTopology(ServiceTopology):
    """
    Defines the hierarchy in Database Services.
    service -> db -> schema -> table.

    We could have a topology validator. We can only consume
    data that has been produced by any parent node.
    """

    root = TopologyNode(
        producer="get_services",
        stages=[
            NodeStage(
                type_=DatabaseService,
                context="database_service",
                processor="yield_create_request_database_service",
                overwrite=False,
                must_return=True,
                cache_entities=True,
            ),
        ],
        children=["database"],
        # Note how we have `yield_view_lineage` and `yield_stored_procedure_lineage`
        # as post_processed. This is because we cannot ensure proper lineage processing
        # until we have finished ingesting all the metadata from the source.
        post_process=["yield_view_lineage", "yield_procedure_lineage_and_queries"],
    )
    database = TopologyNode(
        producer="get_database_names",
        stages=[
            NodeStage(
                type_=OMetaTagAndClassification,
                context="tags",
                processor="yield_database_tag_details",
                nullable=True,
                store_all_in_context=True,
            ),
            NodeStage(
                type_=Database,
                context="database",
                processor="yield_database",
                consumer=["database_service"],
                cache_entities=True,
                use_cache=True,
            ),
        ],
        children=["databaseSchema"],
    )
    databaseSchema = TopologyNode(
        producer="get_database_schema_names",
        stages=[
            NodeStage(
                type_=OMetaTagAndClassification,
                context="tags",
                processor="yield_database_schema_tag_details",
                nullable=True,
                store_all_in_context=True,
            ),
            NodeStage(
                type_=DatabaseSchema,
                context="database_schema",
                processor="yield_database_schema",
                consumer=["database_service", "database"],
                cache_entities=True,
                use_cache=True,
            ),
        ],
        children=["table", "stored_procedure"],
        post_process=["mark_tables_as_deleted", "mark_stored_procedures_as_deleted"],
    )
    table = TopologyNode(
        producer="get_tables_name_and_type",
        stages=[
            NodeStage(
                type_=OMetaTagAndClassification,
                context="tags",
                processor="yield_table_tag_details",
                nullable=True,
                store_all_in_context=True,
            ),
            NodeStage(
                type_=Table,
                context="table",
                processor="yield_table",
                consumer=["database_service", "database", "database_schema"],
                use_cache=True,
            ),
            NodeStage(
                type_=OMetaLifeCycleData,
                processor="yield_life_cycle_data",
                nullable=True,
            ),
        ],
    )
    stored_procedure = TopologyNode(
        producer="get_stored_procedures",
        stages=[
            NodeStage(
                type_=StoredProcedure,
                context="stored_procedures",
                processor="yield_stored_procedure",
                consumer=["database_service", "database", "database_schema"],
                store_all_in_context=True,
                store_fqn=True,
                use_cache=True,
            ),
        ],
    )
```

## Interface/Repository Format

openmetadata-spec/resources/json.schema 참조  

### 1. CreateIngestionPipeline

UI -> Server  

```json
{
    "name": "pipeline name(id)",
    "displayName": "display name",
    "description": "description of th pipeline. can use markdown format",
    "pipelineType": {
      "type": "string",
      "enum": ["metadata", "usage", "lineage", "profiler", "TestSuite", "dataInsight", "elasticSearchReindex", "dbt", "application"],
      "설명": "파이프라인 타입에 따라 airflow에서 동작이 달라짐(상이함)"
    },
    "sourceConfig": {
      "description": "Additional connection configuration.",
      "javaType": "org.openmetadata.schema.metadataIngestion.SourceConfig",
      "type": "object",
      "properties": {
        "config": {
          "oneOf": [
            {
                "설명": "메타데이터 수집 대상과 수집할 정보"
                "$ref": "databaseServiceMetadataPipeline.json",
                "type": {
                    "description": "Pipeline type",
                    "$ref": "#/definitions/databaseMetadataConfigType",
                    "default": "DatabaseMetadata"
                },
                "markDeletedTables": {
                    "description": "This is an optional configuration for enabling soft deletion of tables. When this option is enabled, only tables that have been deleted from the source will be soft deleted, and this will apply solely to the schema that is currently being ingested via the pipeline. Any related entities such as test suites or lineage information that were associated with those tables will also be deleted.",
                    "type": "boolean",
                    "default": true,
                    "title": "Mark Deleted Tables"
                },
                "markDeletedStoredProcedures": {
                    "description": "Optional configuration to soft delete stored procedures in OpenMetadata if the source stored procedures are deleted. Also, if the stored procedures is deleted, all the associated entities like lineage, etc., with that stored procedures will be deleted",
                    "type": "boolean",
                    "default": true,
                    "title": "Mark Deleted Stored Procedures"
                },
                "includeTables": {
                    "description": "Optional configuration to turn off fetching metadata for tables.",
                    "type": "boolean",
                    "default": true,
                    "title": "Include Tables"
                },
                "includeViews": {
                    "description": "Optional configuration to turn off fetching metadata for views.",
                    "type": "boolean",
                    "default": true,
                    "title": "Include Views"
                },
                "includeTags": {
                    "description": "Optional configuration to toggle the tags ingestion.",
                    "type": "boolean",
                    "default": true,
                    "title": "Include Tags"
                },
                "includeOwners":{
                    "title": "Include Owners",
                    "description": "Set the 'Include Owners' toggle to control whether to include owners to the ingested entity if the owner email matches with a user stored in the OM server as part of metadata ingestion. If the ingested entity already exists and has an owner, the owner will not be overwritten.",
                    "type": "boolean",
                    "default": false
                },
                "includeStoredProcedures": {
                    "description": "Optional configuration to toggle the Stored Procedures ingestion.",
                    "type": "boolean",
                    "default": true,
                    "title": "Include Stored Procedures"
                },
                "queryLogDuration": {
                    "description": "Configuration to tune how far we want to look back in query logs to process Stored Procedures results.",
                    "type": "integer",
                    "default": 1,
                    "title": "Query Log Duration"
                },
                "queryParsingTimeoutLimit": {
                    "description": "Configuration to set the timeout for parsing the query in seconds.",
                    "type": "integer",
                    "default": 300,
                    "title": "Query Parsing Timeout Limit"
                },
                "useFqnForFiltering": {
                    "description": "Regex will be applied on fully qualified name (e.g service_name.db_name.schema_name.table_name) instead of raw name (e.g. table_name)",
                    "type": "boolean",
                    "default": false,
                    "title": "Use FQN For Filtering"
                },
                "schemaFilterPattern": {
                    "description": "Regex to only fetch tables or databases that matches the pattern.",
                    "$ref": "../type/filterPattern.json#/definitions/filterPattern",
                    "title": "Schema Filter Pattern"
                },
                "tableFilterPattern": {
                    "description": "Regex exclude tables or databases that matches the pattern.",
                    "$ref": "../type/filterPattern.json#/definitions/filterPattern",
                    "title": "Table Filter Pattern"
                },
                "databaseFilterPattern": {
                    "description": "Regex to only fetch databases that matches the pattern.",
                    "$ref": "../type/filterPattern.json#/definitions/filterPattern",
                    "title": "Database Filter Pattern"
                }
            },
            {
              "$ref": "databaseServiceQueryUsagePipeline.json"
            },
            {
              "$ref": "databaseServiceQueryLineagePipeline.json"
            },
            {
              "$ref": "dashboardServiceMetadataPipeline.json"
            },
            {
              "$ref": "messagingServiceMetadataPipeline.json"
            },
            {
              "$ref": "databaseServiceProfilerPipeline.json"
            },
            {
              "$ref": "pipelineServiceMetadataPipeline.json"
            },
            {
              "$ref": "mlmodelServiceMetadataPipeline.json"
            },
            {
              "$ref": "storageServiceMetadataPipeline.json"
            },
            {
              "$ref": "searchServiceMetadataPipeline.json"
            },
            {
              "$ref": "testSuitePipeline.json"
            },
            {
              "$ref": "metadataToElasticSearchPipeline.json"
            },
            {
              "$ref": "dataInsightPipeline.json"
            },
            {
              "$ref": "dbtPipeline.json"
            },
            {
              "$ref": "applicationPipeline.json"
            }
          ]
        }

    },
    "airflowConfig": {
        "$ref": "../../../entity/services/ingestionPipelines/ingestionPipeline.json#/definitions/airflowConfig",
        "설명": "airflow 동작 조건과 airflow 옵션",
        "description": "Properties to configure the Airflow pipeline that will run the workflow.",
        "type": "object",
        "javaType": "org.openmetadata.schema.entity.services.ingestionPipelines.AirflowConfig",
        "properties": {
        "pausePipeline": {
            "description": "pause the pipeline from running once the deploy is finished successfully.",
            "type": "boolean",
            "default": false
        },
        "concurrency": {
            "description": "Concurrency of the Pipeline.",
            "type": "integer",
            "default": 1
        },
        "startDate": {
            "description": "Start date of the pipeline.",
            "$ref": "../../../type/basic.json#/definitions/dateTime"
        },
        "endDate": {
            "description": "End Date of the pipeline.",
            "$ref": "../../../type/basic.json#/definitions/dateTime"
        },
        "pipelineTimezone": {
            "description": "Timezone in which pipeline going to be scheduled.",
            "type": "string",
            "default": "UTC"
        },
        "retries": {
            "description": "Retry pipeline in case of failure.",
            "type": "integer",
            "default": 0
        },
        "retryDelay": {
            "description": "Delay between retries in seconds.",
            "type": "integer",
            "default": 300
        },
        "pipelineCatchup": {
            "description": "Run past executions if the start date is in the past.",
            "type": "boolean",
            "default": false
        },
        "scheduleInterval": {
            "description": "Scheduler Interval for the pipeline in cron format.",
            "type": "string"
        },
        "maxActiveRuns": {
            "description": "Maximum Number of active runs.",
            "type": "integer",
            "default": 1
        },
        "workflowTimeout": {
            "description": "Timeout for the workflow in seconds.",
            "type": "integer",
            "default": null
        },
        "workflowDefaultView": {
            "description": "Default view in Airflow.",
            "type": "string",
            "default": "tree"
        },
        "workflowDefaultViewOrientation": {
            "description": "Default view Orientation in Airflow.",
            "type": "string",
            "default": "LR"
        },
        "email": {
            "description": "Email to notify workflow status.",
            "$ref": "../../../type/basic.json#/definitions/email"
        }
    },
    "loggerLevel": {
      "description": "Set the logging level for the workflow.",
      "$ref": "../../../metadataIngestion/workflow.json#/definitions/logLevels"
    },
    "service": {
        "description": "Link to the service for which ingestion pipeline is ingesting the metadata.",
        "$ref": "../../../type/entityReference.json",
        "설명": "수집 대상 서비스 정보",
        "id": {
            "description": "Unique identifier that identifies an entity instance.",
            "$ref": "basic.json#/definitions/uuid"
        },
        "type": {
            "description": "Entity type/class name - Examples: `database`, `table`, `metrics`, `databaseService`, `dashboardService`...",
            "type": "string"
        },
        "name": {
            "description": "Name of the entity instance.",
            "type": "string"
        },
        "fullyQualifiedName": {
            "description": "Fully qualified name of the entity instance. For entities such as tables, databases fullyQualifiedName is returned in this field. For entities that don't have name hierarchy such as `user` and `team` this will be same as the `name` field.",
            "type": "string"
        },
        "description": {
            "description": "Optional description of entity.",
            "$ref": "basic.json#/definitions/markdown"
        },
        "displayName": {
            "description": "Display Name that identifies this entity.",
            "type": "string"
        },
        "deleted": {
            "description": "If true the entity referred to has been soft-deleted.",
            "type": "boolean"
        },
        "inherited": {
            "description": "If true the relationship indicated by this entity reference is inherited from the parent entity.",
            "type": "boolean"
        },
        "href": {
            "description": "Link to the entity resource.",
        "$ref": "basic.json#/definitions/href"
        }
    },
    "owner": {
      "description": "Owner of this Pipeline.",
      "$ref": "../../../type/entityReference.json"
    }
  }
}
```

### 2. Store IngestionPipeline

```json
{
    "id": {
        "description": "Unique identifier that identifies this pipeline.",
        "$ref": "../../../type/basic.json#/definitions/uuid"
    },
    "name": {
        "description": "Name that identifies this pipeline instance uniquely.",
        "$ref": "../../../type/basic.json#/definitions/entityName"
    },
    "displayName": {
        "description": "Display Name that identifies this Pipeline.",
        "type": "string"
    },
    "description": {
        "description": "Description of the Pipeline.",
        "$ref": "../../../type/basic.json#/definitions/markdown"
    },
    "pipelineType": {
        "$ref": "#/definitions/pipelineType",
        "pipelineType": {
            "description": "Type of Pipeline - metadata, usage",
            "type": "string",
            "javaType": "org.openmetadata.schema.entity.services.ingestionPipelines.PipelineType",
            "enum": ["metadata", "usage", "lineage", "profiler", "TestSuite", "dataInsight", "elasticSearchReindex", "dbt", "application"]
        }
    },
    "owner": {
      "description": "Owner of this Pipeline.",
      "$ref": "../../../type/entityReference.json",
      "default": null
    },
    "fullyQualifiedName": {
        "description": "Name that uniquely identifies a Pipeline.",
        "$ref": "../../../type/basic.json#/definitions/fullyQualifiedEntityName"
    },
    "sourceConfig": {
        "$ref": "../../../metadataIngestion/workflow.json#/definitions/sourceConfig",
        "설명": "메타데이터 수집 대상과 수집할 데이터 정보"
    },
    "openMetadataServerConnection": {
        "$ref": "../connections/metadata/openMetadataConnection.json",
        "설명": "openmetadata 서버 연결 정보"
    },
    "airflowConfig": {
        "$ref": "#/definitions/airflowConfig",
        "설명": "에어플로우에서 실행될 워크플로우의 실행 설정정보"
    },
    "service": {
        "description": "Link to the service (such as database, messaging, storage services, etc. for which this ingestion pipeline ingests the metadata from.",
        "$ref": "../../../type/entityReference.json",
        "설명": "workflow 가 동작할 대상 서비스 정보"
    },
    "pipelineStatuses": {
        "description": "Last of executions and status for the Pipeline.",
        "$ref": {
            "runId": {
                "description": "Pipeline unique run ID.",
                "type": "string"
            },
            "pipelineState": {
                "description": "Pipeline status denotes if its failed or succeeded.",
                "type": "string",
                "javaType": "org.openmetadata.schema.entity.services.ingestionPipelines.PipelineStatusType",
                "enum": ["queued","success","failed","running","partialSuccess"]
            },
            "startDate": {
                "description": "startDate of the pipeline run for this particular execution.",
                "$ref": "../../../type/basic.json#/definitions/timestamp"
            },
            "timestamp": {
                "description": "executionDate of the pipeline run for this particular execution.",
                "$ref": "../../../type/basic.json#/definitions/timestamp"
            },
            "endDate": {
                "description": "endDate of the pipeline run for this particular execution.",
                "$ref": "../../../type/basic.json#/definitions/timestamp"
            },
            "status": {
                "description": "Ingestion Pipeline summary status. Informed at the end of the execution.",
                "$ref": {
                    "title": "IngestionStatus",
                    "description": "Summary for each step of the ingestion pipeline",
                    "type": "array",
                    "items": {
                        "$ref": {
                            "name": {
                                "description": "Step name",
                                "type": "string"
                            },
                            "records": {
                                "description": "Number of successfully processed records.",
                                "type": "integer",
                                "default": 0
                            },
                            "updated_records": {
                                "description": "Number of successfully updated records.",
                                "type": "integer",
                                "default": 0
                            },
                            "warnings": {
                                "description": "Number of records raising warnings.",
                                "type": "integer",
                                "default": 0
                            },
                            "errors": {
                                "description": "Number of records with errors.",
                                "type": "integer",
                                "default": 0
                            },
                            "filtered": {
                                "description": "Number of filtered records.",
                                "type": "integer",
                                "default": 0
                            },
                            "failures": {
                                "description": "Sample of errors encountered in the step",
                                "type": "array",
                                "items": {
                                    "$ref": "#/definitions/stackTraceError"
                                }
                            }
                        }
                    }
                }
            }
        }
    },
    "loggerLevel": {
        "description": "Set the logging level for the workflow.",
        "$ref": "../../../metadataIngestion/workflow.json#/definitions/logLevels"
    },
    "deployed": {
        "description": "Indicates if the workflow has been successfully deployed to Airflow.",
        "type": "boolean",
        "default": false
    },
    "enabled": {
        "description": "True if the pipeline is ready to be run in the next schedule. False if it is paused.",
        "type": "boolean",
        "default": true
    },
    "href": {
        "description": "Link to this ingestion pipeline resource.",
        "$ref": "../../../type/basic.json#/definitions/href"
    },
    "version": {
        "description": "Metadata version of the entity.",
        "$ref": {
            "entityType": {
                "description": "Entity type, such as `database`, `table`, `dashboard`, for which this version history is produced.",
                "type": "string"
            },
            "versions": {
                "descriptions": "All the versions of the entity ordered from the latest to the oldest version. Note the array element object has schema that corresponds to schema of the entity from the `entityType` attribute. For example, if `entityType` is `table`, then the schema of the object in the array is `table.json`.",
                "type": "array"
            }
        }
    },
    "updatedAt": {
        "description": "Last update time corresponding to the new version of the entity in Unix epoch time milliseconds.",
        "$ref": "../../../type/basic.json#/definitions/timestamp"
    },
    "updatedBy": {
        "description": "User who made the update.",
        "type": "string"
    },
    "changeDescription": {
        "description": "Change that led to this version of the entity.",
        "$ref": {
            "changeDescription": {
                "fieldsAdded": {
                    "description": "Names of fields added during the version changes.",
                    "type": "array",
                    "items": {
                        "$ref": "#/definitions/fieldChange"
                    }
            },
            "fieldsUpdated": {
                "description": "Fields modified during the version changes with old and new values.",
                "type": "array",
                "items": {
                    "$ref": "#/definitions/fieldChange"
                }
            },
            "fieldsDeleted": {
                "description": "Fields deleted during the version changes with old value before deleted.",
                "type": "array",
                "items": {
                    "$ref": "#/definitions/fieldChange"
                }
            },
            "previousVersion": {
                "description": "When a change did not result in change, this could be same as the current version.",
                "$ref": "#/definitions/entityVersion"
            }
        }
    },
    "deleted": {
        "description": "When `true` indicates the entity has been soft deleted.",
        "type": "boolean",
        "default": false
    },
    "provider" : {
        "$ref": "../../../type/basic.json#/definitions/providerType",
        "providerType": {
            "javaType": "org.openmetadata.schema.type.ProviderType",
            "description": "Type of provider of an entity. Some entities are provided by the `system`. Some are entities created and provided by the `user`. Typically `system` provide entities can't be deleted and can only be disabled.",
            "type": "string",
            "enum": ["system", "user"],
            "default": "user"
        },
    }
}
```
