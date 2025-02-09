# Airflow - OpenMetadata Integration

1. Get Source Code
    github openmetadata source code download
    OpenMetadata tags/1.4.0-rc2-release

2. setup python venv  

    ```shell
    python3.10 -m venv venv
    source venv/bin/activate
    ```

3. open-metadata  
    move to source root of open-metadata pkg install and generate code from json  

    1) install require pkg  

        ```shell
        pip install datamodel_code_generator antlr4 psycopg2
        # and antlr4 command run
        antlr4
        # will be download ANTLR4 
        ```

    2) generate code by make  

        ```shell
        make generate
        ```

4. install pkg and set config  

    pyproject.toml, setup.py 를 통해 필요한 패키지와 plugin, ingestion 을 airflow에 등록될 수 있도록 인스톨한다.  

    1) ingestion  

        ```shell
        cd ingestion
        make install_dev
        make install_apis
        ```

    2) set env AIRFLOW_HOME  

        ```shell
        mkdir -p airflow-home
        mkdir -p airflow-home/dag_generated_configs
        export AIRFLOW_HOME={path of airflow-home}
        ```

    3) set config  

        airflow run for generate default config

        ```shell
        airflow db init
        ```

        modify airflow config : `vi {airflow-home}/airflow.cfg`  

        ```cfg
        # add
        [openmetadata_airflow_apis]
        dag_generated_configs = {AIRFLOW_HOME}/dag_generated_configs
        
        # modify 
        auth_backends = airflow.api.auth.backend.basic_auth,airflow.api.auth.backend.session
        sql_alchemy_conn = postgresql+psycopg2://airflow_user:airflow_pass@192.168.202.167:5432/airflow_db
        ```

5. run open-metadata server(server, postgresl, elastic-search)  

    ```docker-compose
    #  Copyright 2021 Collate
    #  Licensed under the Apache License, Version 2.0 (the "License");
    #  you may not use this file except in compliance with the License.
    #  You may obtain a copy of the License at
    #  http://www.apache.org/licenses/LICENSE-2.0
    #  Unless required by applicable law or agreed to in writing, software
    #  distributed under the License is distributed on an "AS IS" BASIS,
    #  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    #  See the License for the specific language governing permissions and
    #  limitations under the License.

    version: "3.9"
    services:
    postgresql:
        container_name: openmetadata_postgresql
        image: docker.getcollate.io/openmetadata/postgresql:1.4.0-rc2
        restart: always
        command: "--work_mem=10MB"
        environment:
        POSTGRES_USER: postgres
        POSTGRES_PASSWORD: password
        expose:
        - 5432
        ports:
        - "5432:5432"
        volumes:
        - /Users/jblim/Workspace/open-metadata/local-test/postgres:/var/lib/postgresql/data

        networks:
        - app_net
        healthcheck:
        test: psql -U postgres -tAc 'select 1' -d openmetadata_db
        interval: 15s
        timeout: 10s
        retries: 10

    elasticsearch:
        container_name: openmetadata_elasticsearch
        image: docker.elastic.co/elasticsearch/elasticsearch:8.10.2
        environment:
        - discovery.type=single-node
        - ES_JAVA_OPTS=-Xms1024m -Xmx1024m
        - xpack.security.enabled=false
        networks:
        - app_net
        ports:
        - "9200:9200"
        - "9300:9300"
        healthcheck:
        test: "curl -s http://localhost:9200/_cluster/health?pretty | grep status | grep -qE 'green|yellow' || exit 1"
        interval: 15s
        timeout: 10s
        retries: 10
        volumes:
        - /Users/jblim/Workspace/open-metadata/local-test/es-data:/usr/share/elasticsearch/data

    execute-migrate-all:
        container_name: execute_migrate_all
        image: docker.getcollate.io/openmetadata/server:1.4.0-rc2
        command: "./bootstrap/openmetadata-ops.sh migrate"
        environment:
        OPENMETADATA_CLUSTER_NAME: ${OPENMETADATA_CLUSTER_NAME:-openmetadata}
        SERVER_PORT: ${SERVER_PORT:-8585}
        SERVER_ADMIN_PORT: ${SERVER_ADMIN_PORT:-8586}
        LOG_LEVEL: ${LOG_LEVEL:-INFO}

        # Migration
        MIGRATION_LIMIT_PARAM: ${MIGRATION_LIMIT_PARAM:-1200}

        # OpenMetadata Server Authentication Configuration
        AUTHORIZER_CLASS_NAME: ${AUTHORIZER_CLASS_NAME:-org.openmetadata.service.security.DefaultAuthorizer}
        AUTHORIZER_REQUEST_FILTER: ${AUTHORIZER_REQUEST_FILTER:-org.openmetadata.service.security.JwtFilter}
        AUTHORIZER_ADMIN_PRINCIPALS: ${AUTHORIZER_ADMIN_PRINCIPALS:-[admin]}
        AUTHORIZER_ALLOWED_REGISTRATION_DOMAIN: ${AUTHORIZER_ALLOWED_REGISTRATION_DOMAIN:-["all"]}
        AUTHORIZER_INGESTION_PRINCIPALS: ${AUTHORIZER_INGESTION_PRINCIPALS:-[ingestion-bot]}
        AUTHORIZER_PRINCIPAL_DOMAIN: ${AUTHORIZER_PRINCIPAL_DOMAIN:-"openmetadata.org"}
        AUTHORIZER_ENFORCE_PRINCIPAL_DOMAIN: ${AUTHORIZER_ENFORCE_PRINCIPAL_DOMAIN:-false}
        AUTHORIZER_ENABLE_SECURE_SOCKET: ${AUTHORIZER_ENABLE_SECURE_SOCKET:-false}
        AUTHENTICATION_PROVIDER: ${AUTHENTICATION_PROVIDER:-basic}
        AUTHENTICATION_RESPONSE_TYPE: ${AUTHENTICATION_RESPONSE_TYPE:-id_token}
        CUSTOM_OIDC_AUTHENTICATION_PROVIDER_NAME: ${CUSTOM_OIDC_AUTHENTICATION_PROVIDER_NAME:-""}
        AUTHENTICATION_PUBLIC_KEYS: ${AUTHENTICATION_PUBLIC_KEYS:-[http://localhost:8585/api/v1/system/config/jwks]}
        AUTHENTICATION_AUTHORITY: ${AUTHENTICATION_AUTHORITY:-https://accounts.google.com}
        AUTHENTICATION_CLIENT_ID: ${AUTHENTICATION_CLIENT_ID:-""}
        AUTHENTICATION_CALLBACK_URL: ${AUTHENTICATION_CALLBACK_URL:-""}
        AUTHENTICATION_JWT_PRINCIPAL_CLAIMS: ${AUTHENTICATION_JWT_PRINCIPAL_CLAIMS:-[email,preferred_username,sub]}
        AUTHENTICATION_ENABLE_SELF_SIGNUP: ${AUTHENTICATION_ENABLE_SELF_SIGNUP:-true}
        AUTHENTICATION_CLIENT_TYPE: ${AUTHENTICATION_CLIENT_TYPE:-public}
        #For OIDC Authentication, when client is confidential
        OIDC_CLIENT_ID: ${OIDC_CLIENT_ID:-""}
        OIDC_TYPE: ${OIDC_TYPE:-""} # google, azure etc.
        OIDC_CLIENT_SECRET: ${OIDC_CLIENT_SECRET:-""}
        OIDC_SCOPE: ${OIDC_SCOPE:-"openid email profile"}
        OIDC_DISCOVERY_URI: ${OIDC_DISCOVERY_URI:-""}
        OIDC_USE_NONCE: ${OIDC_USE_NONCE:-true}
        OIDC_PREFERRED_JWS: ${OIDC_PREFERRED_JWS:-"RS256"}
        OIDC_RESPONSE_TYPE: ${OIDC_RESPONSE_TYPE:-"code"}
        OIDC_DISABLE_PKCE: ${OIDC_DISABLE_PKCE:-true}
        OIDC_CALLBACK: ${OIDC_CALLBACK:-"http://localhost:8585/callback"}
        OIDC_SERVER_URL: ${OIDC_SERVER_URL:-"http://localhost:8585"}
        OIDC_CLIENT_AUTH_METHOD: ${OIDC_CLIENT_AUTH_METHOD:-"client_secret_post"}
        OIDC_TENANT: ${OIDC_TENANT:-""}
        OIDC_MAX_CLOCK_SKEW: ${OIDC_MAX_CLOCK_SKEW:-""}
        OIDC_CUSTOM_PARAMS: ${OIDC_CUSTOM_PARAMS:-{}}
        # For SAML Authentication
        # SAML_DEBUG_MODE: ${SAML_DEBUG_MODE:-false}
        # SAML_IDP_ENTITY_ID: ${SAML_IDP_ENTITY_ID:-""}
        # SAML_IDP_SSO_LOGIN_URL: ${SAML_IDP_SSO_LOGIN_URL:-""}
        # SAML_IDP_CERTIFICATE: ${SAML_IDP_CERTIFICATE:-""}
        # SAML_AUTHORITY_URL: ${SAML_AUTHORITY_URL:-"http://localhost:8585/api/v1/saml/login"}
        # SAML_IDP_NAME_ID: ${SAML_IDP_NAME_ID:-"urn:oasis:names:tc:SAML:2.0:nameid-format:emailAddress"}
        # SAML_SP_ENTITY_ID: ${SAML_SP_ENTITY_ID:-"http://localhost:8585/api/v1/saml/metadata"}
        # SAML_SP_ACS: ${SAML_SP_ACS:-"http://localhost:8585/api/v1/saml/acs"}
        # SAML_SP_CERTIFICATE: ${SAML_SP_CERTIFICATE:-""}
        # SAML_SP_CALLBACK: ${SAML_SP_CALLBACK:-"http://localhost:8585/saml/callback"}
        # SAML_STRICT_MODE: ${SAML_STRICT_MODE:-false}
        # SAML_SP_TOKEN_VALIDITY: ${SAML_SP_TOKEN_VALIDITY:-"3600"}
        # SAML_SEND_ENCRYPTED_NAME_ID: ${SAML_SEND_ENCRYPTED_NAME_ID:-false}
        # SAML_SEND_SIGNED_AUTH_REQUEST: ${SAML_SEND_SIGNED_AUTH_REQUEST:-false}
        # SAML_SIGNED_SP_METADATA: ${SAML_SIGNED_SP_METADATA:-false}
        # SAML_WANT_MESSAGE_SIGNED: ${SAML_WANT_MESSAGE_SIGNED:-false}
        # SAML_WANT_ASSERTION_SIGNED: ${SAML_WANT_ASSERTION_SIGNED:-false}
        # SAML_WANT_ASSERTION_ENCRYPTED: ${SAML_WANT_ASSERTION_ENCRYPTED:-false}
        # SAML_WANT_NAME_ID_ENCRYPTED: ${SAML_WANT_NAME_ID_ENCRYPTED:-false}
        # SAML_KEYSTORE_FILE_PATH: ${SAML_KEYSTORE_FILE_PATH:-""}
        # SAML_KEYSTORE_ALIAS: ${SAML_KEYSTORE_ALIAS:-""}
        # SAML_KEYSTORE_PASSWORD: ${SAML_KEYSTORE_PASSWORD:-""}
        # For LDAP Authentication
        # AUTHENTICATION_LDAP_HOST: ${AUTHENTICATION_LDAP_HOST:-}
        # AUTHENTICATION_LDAP_PORT: ${AUTHENTICATION_LDAP_PORT:-}
        # AUTHENTICATION_LOOKUP_ADMIN_DN: ${AUTHENTICATION_LOOKUP_ADMIN_DN:-""}
        # AUTHENTICATION_LOOKUP_ADMIN_PWD: ${AUTHENTICATION_LOOKUP_ADMIN_PWD:-""}
        # AUTHENTICATION_USER_LOOKUP_BASEDN: ${AUTHENTICATION_USER_LOOKUP_BASEDN:-""}
        # AUTHENTICATION_USER_MAIL_ATTR: ${AUTHENTICATION_USER_MAIL_ATTR:-}
        # AUTHENTICATION_LDAP_POOL_SIZE: ${AUTHENTICATION_LDAP_POOL_SIZE:-3}
        # AUTHENTICATION_LDAP_SSL_ENABLED: ${AUTHENTICATION_LDAP_SSL_ENABLED:-}
        # AUTHENTICATION_LDAP_TRUSTSTORE_TYPE: ${AUTHENTICATION_LDAP_TRUSTSTORE_TYPE:-TrustAll}
        # AUTHENTICATION_LDAP_TRUSTSTORE_PATH: ${AUTHENTICATION_LDAP_TRUSTSTORE_PATH:-}
        # AUTHENTICATION_LDAP_KEYSTORE_PASSWORD: ${AUTHENTICATION_LDAP_KEYSTORE_PASSWORD:-}
        # AUTHENTICATION_LDAP_SSL_KEY_FORMAT: ${AUTHENTICATION_LDAP_SSL_KEY_FORMAT:-}
        # AUTHENTICATION_LDAP_ALLOW_WILDCARDS: ${AUTHENTICATION_LDAP_ALLOW_WILDCARDS:-}
        # AUTHENTICATION_LDAP_ALLOWED_HOSTNAMES: ${AUTHENTICATION_LDAP_ALLOWED_HOSTNAMES:-[]}
        # AUTHENTICATION_LDAP_SSL_VERIFY_CERT_HOST: ${AUTHENTICATION_LDAP_SSL_VERIFY_CERT_HOST:-}
        # AUTHENTICATION_LDAP_EXAMINE_VALIDITY_DATES: ${AUTHENTICATION_LDAP_EXAMINE_VALIDITY_DATES:-true}

        # JWT Configuration
        RSA_PUBLIC_KEY_FILE_PATH: ${RSA_PUBLIC_KEY_FILE_PATH:-"./conf/public_key.der"}
        RSA_PRIVATE_KEY_FILE_PATH: ${RSA_PRIVATE_KEY_FILE_PATH:-"./conf/private_key.der"}
        JWT_ISSUER: ${JWT_ISSUER:-"open-metadata.org"}
        JWT_KEY_ID: ${JWT_KEY_ID:-"Gb389a-9f76-gdjs-a92j-0242bk94356"}
        # OpenMetadata Server Pipeline Service Client Configuration
        PIPELINE_SERVICE_CLIENT_ENDPOINT: ${PIPELINE_SERVICE_CLIENT_ENDPOINT:-http://192.168.202.167:8080}
        PIPELINE_SERVICE_CLIENT_HEALTH_CHECK_INTERVAL: ${PIPELINE_SERVICE_CLIENT_HEALTH_CHECK_INTERVAL:-300}
        SERVER_HOST_API_URL: ${SERVER_HOST_API_URL:-http://192.168.202.167:8585/api}
        PIPELINE_SERVICE_CLIENT_VERIFY_SSL: ${PIPELINE_SERVICE_CLIENT_VERIFY_SSL:-"no-ssl"}
        PIPELINE_SERVICE_CLIENT_SSL_CERT_PATH: ${PIPELINE_SERVICE_CLIENT_SSL_CERT_PATH:-""}
        #Database configuration for postgresql
        DB_DRIVER_CLASS: ${DB_DRIVER_CLASS:-org.postgresql.Driver}
        DB_SCHEME: ${DB_SCHEME:-postgresql}
        DB_PARAMS: ${DB_PARAMS:-allowPublicKeyRetrieval=true&useSSL=false&serverTimezone=UTC}
        DB_USER: ${DB_USER:-openmetadata_user}
        DB_USER_PASSWORD: ${DB_USER_PASSWORD:-openmetadata_password}
        DB_HOST: ${DB_HOST:-postgresql}
        DB_PORT: ${DB_PORT:-5432}
        OM_DATABASE: ${OM_DATABASE:-openmetadata_db}
        # ElasticSearch Configurations
        ELASTICSEARCH_HOST: ${ELASTICSEARCH_HOST:- elasticsearch}
        ELASTICSEARCH_PORT: ${ELASTICSEARCH_PORT:-9200}
        ELASTICSEARCH_SCHEME: ${ELASTICSEARCH_SCHEME:-http}
        ELASTICSEARCH_USER: ${ELASTICSEARCH_USER:-""}
        ELASTICSEARCH_PASSWORD: ${ELASTICSEARCH_PASSWORD:-""}
        SEARCH_TYPE: ${SEARCH_TYPE:- "elasticsearch"}
        ELASTICSEARCH_TRUST_STORE_PATH: ${ELASTICSEARCH_TRUST_STORE_PATH:-""}
        ELASTICSEARCH_TRUST_STORE_PASSWORD: ${ELASTICSEARCH_TRUST_STORE_PASSWORD:-""}
        ELASTICSEARCH_CONNECTION_TIMEOUT_SECS: ${ELASTICSEARCH_CONNECTION_TIMEOUT_SECS:-5}
        ELASTICSEARCH_SOCKET_TIMEOUT_SECS: ${ELASTICSEARCH_SOCKET_TIMEOUT_SECS:-60}
        ELASTICSEARCH_KEEP_ALIVE_TIMEOUT_SECS: ${ELASTICSEARCH_KEEP_ALIVE_TIMEOUT_SECS:-600}
        ELASTICSEARCH_BATCH_SIZE: ${ELASTICSEARCH_BATCH_SIZE:-10}
        ELASTICSEARCH_PAYLOAD_BYTES_SIZE: ${ELASTICSEARCH_PAYLOAD_BYTES_SIZE:-10485760}   #max payLoadSize in Bytes
        ELASTICSEARCH_INDEX_MAPPING_LANG: ${ELASTICSEARCH_INDEX_MAPPING_LANG:-EN}

        #eventMonitoringConfiguration
        EVENT_MONITOR: ${EVENT_MONITOR:-prometheus}
        EVENT_MONITOR_BATCH_SIZE: ${EVENT_MONITOR_BATCH_SIZE:-10}
        EVENT_MONITOR_PATH_PATTERN: ${EVENT_MONITOR_PATH_PATTERN:-["/api/v1/tables/*", "/api/v1/health-check"]}
        EVENT_MONITOR_LATENCY: ${EVENT_MONITOR_LATENCY:-[]}

        #pipelineServiceClientConfiguration
        PIPELINE_SERVICE_CLIENT_ENABLED: ${PIPELINE_SERVICE_CLIENT_ENABLED:-true}
        PIPELINE_SERVICE_CLIENT_CLASS_NAME: ${PIPELINE_SERVICE_CLIENT_CLASS_NAME:-"org.openmetadata.service.clients.pipeline.airflow.AirflowRESTClient"}
        PIPELINE_SERVICE_IP_INFO_ENABLED: ${PIPELINE_SERVICE_IP_INFO_ENABLED:-false}
        PIPELINE_SERVICE_CLIENT_HOST_IP: ${PIPELINE_SERVICE_CLIENT_HOST_IP:-""}
        PIPELINE_SERVICE_CLIENT_SECRETS_MANAGER_LOADER: ${PIPELINE_SERVICE_CLIENT_SECRETS_MANAGER_LOADER:-"noop"}
        #airflow parameters
        AIRFLOW_USERNAME: ${AIRFLOW_USERNAME:-admin}
        AIRFLOW_PASSWORD: ${AIRFLOW_PASSWORD:-admin}
        AIRFLOW_TIMEOUT: ${AIRFLOW_TIMEOUT:-10}
        AIRFLOW_TRUST_STORE_PATH: ${AIRFLOW_TRUST_STORE_PATH:-""}
        AIRFLOW_TRUST_STORE_PASSWORD: ${AIRFLOW_TRUST_STORE_PASSWORD:-""}
        FERNET_KEY: ${FERNET_KEY:-jJ/9sz0g0OHxsfxOoSfdFdmk3ysNmPRnH3TUAbz3IHA=}

        #secretsManagerConfiguration
        SECRET_MANAGER: ${SECRET_MANAGER:-db}
        # AWS:
        OM_SM_REGION: ${OM_SM_REGION:-""}
        OM_SM_ACCESS_KEY_ID: ${OM_SM_ACCESS_KEY_ID:-""}
        OM_SM_ACCESS_KEY: ${OM_SM_ACCESS_KEY:-""}
        # Azure:
        OM_SM_VAULT_NAME: ${OM_SM_VAULT_NAME:-""}
        OM_SM_CLIENT_ID: ${OM_SM_CLIENT_ID:-""}
        OM_SM_CLIENT_SECRET: ${OM_SM_CLIENT_SECRET:-""}
        OM_SM_TENANT_ID: ${OM_SM_TENANT_ID:-""}

        #email configuration:
        OM_EMAIL_ENTITY: ${OM_EMAIL_ENTITY:-"OpenMetadata"}
        OM_SUPPORT_URL: ${OM_SUPPORT_URL:-"https://slack.open-metadata.org"}
        AUTHORIZER_ENABLE_SMTP : ${AUTHORIZER_ENABLE_SMTP:-false}
        OPENMETADATA_SERVER_URL: ${OPENMETADATA_SERVER_URL:-""}
        OPENMETADATA_SMTP_SENDER_MAIL: ${OPENMETADATA_SMTP_SENDER_MAIL:-""}
        SMTP_SERVER_ENDPOINT: ${SMTP_SERVER_ENDPOINT:-""}
        SMTP_SERVER_PORT: ${SMTP_SERVER_PORT:-""}
        SMTP_SERVER_USERNAME: ${SMTP_SERVER_USERNAME:-""}
        SMTP_SERVER_PWD: ${SMTP_SERVER_PWD:-""}
        SMTP_SERVER_STRATEGY: ${SMTP_SERVER_STRATEGY:-"SMTP_TLS"}

        # Heap OPTS Configurations
        OPENMETADATA_HEAP_OPTS: ${OPENMETADATA_HEAP_OPTS:--Xmx1G -Xms1G}
        # Mask passwords values in UI
        MASK_PASSWORDS_API: ${MASK_PASSWORDS_API:-false}

        #OpenMetadata Web Configuration
        WEB_CONF_URI_PATH: ${WEB_CONF_URI_PATH:-"/api"}
        #HSTS
        WEB_CONF_HSTS_ENABLED: ${WEB_CONF_HSTS_ENABLED:-false}
        WEB_CONF_HSTS_MAX_AGE: ${WEB_CONF_HSTS_MAX_AGE:-"365 days"}
        WEB_CONF_HSTS_INCLUDE_SUBDOMAINS: ${WEB_CONF_HSTS_INCLUDE_SUBDOMAINS:-"true"}
        WEB_CONF_HSTS_PRELOAD: ${WEB_CONF_HSTS_PRELOAD:-"true"}
        #Frame Options
        WEB_CONF_FRAME_OPTION_ENABLED: ${WEB_CONF_FRAME_OPTION_ENABLED:-false}
        WEB_CONF_FRAME_OPTION: ${WEB_CONF_FRAME_OPTION:-"SAMEORIGIN"}
        WEB_CONF_FRAME_ORIGIN: ${WEB_CONF_FRAME_ORIGIN:-""}
        #Content Type
        WEB_CONF_CONTENT_TYPE_OPTIONS_ENABLED: ${WEB_CONF_CONTENT_TYPE_OPTIONS_ENABLED:-false}
        #XSS-Protection
        WEB_CONF_XSS_PROTECTION_ENABLED: ${WEB_CONF_XSS_PROTECTION_ENABLED:-false}
        WEB_CONF_XSS_PROTECTION_ON: ${WEB_CONF_XSS_PROTECTION_ON:-true}
        WEB_CONF_XSS_PROTECTION_BLOCK: ${WEB_CONF_XSS_PROTECTION_BLOCK:-true}
        #CSP
        WEB_CONF_XSS_CSP_ENABLED: ${WEB_CONF_XSS_CSP_ENABLED:-false}
        WEB_CONF_XSS_CSP_POLICY: ${WEB_CONF_XSS_CSP_POLICY:-"default-src 'self'"}
        WEB_CONF_XSS_CSP_REPORT_ONLY_POLICY: ${WEB_CONF_XSS_CSP_REPORT_ONLY_POLICY:-""}
        #Referrer-Policy
        WEB_CONF_REFERRER_POLICY_ENABLED: ${WEB_CONF_REFERRER_POLICY_ENABLED:-false}
        WEB_CONF_REFERRER_POLICY_OPTION: ${WEB_CONF_REFERRER_POLICY_OPTION:-"SAME_ORIGIN"}
        #Permission-Policy
        WEB_CONF_PERMISSION_POLICY_ENABLED: ${WEB_CONF_PERMISSION_POLICY_ENABLED:-false}
        WEB_CONF_PERMISSION_POLICY_OPTION: ${WEB_CONF_PERMISSION_POLICY_OPTION:-""}
        depends_on:
        elasticsearch:
            condition: service_healthy
        postgresql:
            condition: service_healthy
        networks:
        - app_net

    openmetadata-server:
        container_name: openmetadata_server
        restart: always
        image: docker.getcollate.io/openmetadata/server:1.4.0-rc2
        environment:
        OPENMETADATA_CLUSTER_NAME: ${OPENMETADATA_CLUSTER_NAME:-openmetadata}
        SERVER_PORT: ${SERVER_PORT:-8585}
        SERVER_ADMIN_PORT: ${SERVER_ADMIN_PORT:-8586}
        LOG_LEVEL: ${LOG_LEVEL:-INFO}

        # OpenMetadata Server Authentication Configuration
        AUTHORIZER_CLASS_NAME: ${AUTHORIZER_CLASS_NAME:-org.openmetadata.service.security.DefaultAuthorizer}
        AUTHORIZER_REQUEST_FILTER: ${AUTHORIZER_REQUEST_FILTER:-org.openmetadata.service.security.JwtFilter}
        AUTHORIZER_ADMIN_PRINCIPALS: ${AUTHORIZER_ADMIN_PRINCIPALS:-[admin]}
        AUTHORIZER_ALLOWED_REGISTRATION_DOMAIN: ${AUTHORIZER_ALLOWED_REGISTRATION_DOMAIN:-["all"]}
        AUTHORIZER_INGESTION_PRINCIPALS: ${AUTHORIZER_INGESTION_PRINCIPALS:-[ingestion-bot]}
        AUTHORIZER_PRINCIPAL_DOMAIN: ${AUTHORIZER_PRINCIPAL_DOMAIN:-"openmetadata.org"}
        AUTHORIZER_ENFORCE_PRINCIPAL_DOMAIN: ${AUTHORIZER_ENFORCE_PRINCIPAL_DOMAIN:-false}
        AUTHORIZER_ENABLE_SECURE_SOCKET: ${AUTHORIZER_ENABLE_SECURE_SOCKET:-false}
        AUTHENTICATION_PROVIDER: ${AUTHENTICATION_PROVIDER:-basic}
        AUTHENTICATION_RESPONSE_TYPE: ${AUTHENTICATION_RESPONSE_TYPE:-id_token}
        CUSTOM_OIDC_AUTHENTICATION_PROVIDER_NAME: ${CUSTOM_OIDC_AUTHENTICATION_PROVIDER_NAME:-""}
        AUTHENTICATION_PUBLIC_KEYS: ${AUTHENTICATION_PUBLIC_KEYS:-[http://localhost:8585/api/v1/system/config/jwks]}
        AUTHENTICATION_AUTHORITY: ${AUTHENTICATION_AUTHORITY:-https://accounts.google.com}
        AUTHENTICATION_CLIENT_ID: ${AUTHENTICATION_CLIENT_ID:-""}
        AUTHENTICATION_CALLBACK_URL: ${AUTHENTICATION_CALLBACK_URL:-""}
        AUTHENTICATION_JWT_PRINCIPAL_CLAIMS: ${AUTHENTICATION_JWT_PRINCIPAL_CLAIMS:-[email,preferred_username,sub]}
        AUTHENTICATION_ENABLE_SELF_SIGNUP: ${AUTHENTICATION_ENABLE_SELF_SIGNUP:-true}
        AUTHENTICATION_CLIENT_TYPE: ${AUTHENTICATION_CLIENT_TYPE:-public}
        #For OIDC Authentication, when client is confidential
        OIDC_CLIENT_ID: ${OIDC_CLIENT_ID:-""}
        OIDC_TYPE: ${OIDC_TYPE:-""} # google, azure etc.
        OIDC_CLIENT_SECRET: ${OIDC_CLIENT_SECRET:-""}
        OIDC_SCOPE: ${OIDC_SCOPE:-"openid email profile"}
        OIDC_DISCOVERY_URI: ${OIDC_DISCOVERY_URI:-""}
        OIDC_USE_NONCE: ${OIDC_USE_NONCE:-true}
        OIDC_PREFERRED_JWS: ${OIDC_PREFERRED_JWS:-"RS256"}
        OIDC_RESPONSE_TYPE: ${OIDC_RESPONSE_TYPE:-"code"}
        OIDC_DISABLE_PKCE: ${OIDC_DISABLE_PKCE:-true}
        OIDC_CALLBACK: ${OIDC_CALLBACK:-"http://localhost:8585/callback"}
        OIDC_SERVER_URL: ${OIDC_SERVER_URL:-"http://localhost:8585"}
        OIDC_CLIENT_AUTH_METHOD: ${OIDC_CLIENT_AUTH_METHOD:-"client_secret_post"}
        OIDC_TENANT: ${OIDC_TENANT:-""}
        OIDC_MAX_CLOCK_SKEW: ${OIDC_MAX_CLOCK_SKEW:-""}
        OIDC_CUSTOM_PARAMS: ${OIDC_CUSTOM_PARAMS:-{}}
        # For SAML Authentication
        # SAML_DEBUG_MODE: ${SAML_DEBUG_MODE:-false}
        # SAML_IDP_ENTITY_ID: ${SAML_IDP_ENTITY_ID:-""}
        # SAML_IDP_SSO_LOGIN_URL: ${SAML_IDP_SSO_LOGIN_URL:-""}
        # SAML_IDP_CERTIFICATE: ${SAML_IDP_CERTIFICATE:-""}
        # SAML_AUTHORITY_URL: ${SAML_AUTHORITY_URL:-"http://localhost:8585/api/v1/saml/login"}
        # SAML_IDP_NAME_ID: ${SAML_IDP_NAME_ID:-"urn:oasis:names:tc:SAML:2.0:nameid-format:emailAddress"}
        # SAML_SP_ENTITY_ID: ${SAML_SP_ENTITY_ID:-"http://localhost:8585/api/v1/saml/metadata"}
        # SAML_SP_ACS: ${SAML_SP_ACS:-"http://localhost:8585/api/v1/saml/acs"}
        # SAML_SP_CERTIFICATE: ${SAML_SP_CERTIFICATE:-""}
        # SAML_SP_CALLBACK: ${SAML_SP_CALLBACK:-"http://localhost:8585/saml/callback"}
        # SAML_STRICT_MODE: ${SAML_STRICT_MODE:-false}
        # SAML_SP_TOKEN_VALIDITY: ${SAML_SP_TOKEN_VALIDITY:-"3600"}
        # SAML_SEND_ENCRYPTED_NAME_ID: ${SAML_SEND_ENCRYPTED_NAME_ID:-false}
        # SAML_SEND_SIGNED_AUTH_REQUEST: ${SAML_SEND_SIGNED_AUTH_REQUEST:-false}
        # SAML_SIGNED_SP_METADATA: ${SAML_SIGNED_SP_METADATA:-false}
        # SAML_WANT_MESSAGE_SIGNED: ${SAML_WANT_MESSAGE_SIGNED:-false}
        # SAML_WANT_ASSERTION_SIGNED: ${SAML_WANT_ASSERTION_SIGNED:-false}
        # SAML_WANT_ASSERTION_ENCRYPTED: ${SAML_WANT_ASSERTION_ENCRYPTED:-false}
        # SAML_WANT_NAME_ID_ENCRYPTED: ${SAML_WANT_NAME_ID_ENCRYPTED:-false}
        # SAML_KEYSTORE_FILE_PATH: ${SAML_KEYSTORE_FILE_PATH:-""}
        # SAML_KEYSTORE_ALIAS: ${SAML_KEYSTORE_ALIAS:-""}
        # SAML_KEYSTORE_PASSWORD: ${SAML_KEYSTORE_PASSWORD:-""}
        # For LDAP Authentication
        # AUTHENTICATION_LDAP_HOST: ${AUTHENTICATION_LDAP_HOST:-}
        # AUTHENTICATION_LDAP_PORT: ${AUTHENTICATION_LDAP_PORT:-}
        # AUTHENTICATION_LOOKUP_ADMIN_DN: ${AUTHENTICATION_LOOKUP_ADMIN_DN:-""}
        # AUTHENTICATION_LOOKUP_ADMIN_PWD: ${AUTHENTICATION_LOOKUP_ADMIN_PWD:-""}
        # AUTHENTICATION_USER_LOOKUP_BASEDN: ${AUTHENTICATION_USER_LOOKUP_BASEDN:-""}
        # AUTHENTICATION_USER_MAIL_ATTR: ${AUTHENTICATION_USER_MAIL_ATTR:-}
        # AUTHENTICATION_LDAP_POOL_SIZE: ${AUTHENTICATION_LDAP_POOL_SIZE:-3}
        # AUTHENTICATION_LDAP_SSL_ENABLED: ${AUTHENTICATION_LDAP_SSL_ENABLED:-}
        # AUTHENTICATION_LDAP_TRUSTSTORE_TYPE: ${AUTHENTICATION_LDAP_TRUSTSTORE_TYPE:-TrustAll}
        # AUTHENTICATION_LDAP_TRUSTSTORE_PATH: ${AUTHENTICATION_LDAP_TRUSTSTORE_PATH:-}
        # AUTHENTICATION_LDAP_KEYSTORE_PASSWORD: ${AUTHENTICATION_LDAP_KEYSTORE_PASSWORD:-}
        # AUTHENTICATION_LDAP_SSL_KEY_FORMAT: ${AUTHENTICATION_LDAP_SSL_KEY_FORMAT:-}
        # AUTHENTICATION_LDAP_ALLOW_WILDCARDS: ${AUTHENTICATION_LDAP_ALLOW_WILDCARDS:-}
        # AUTHENTICATION_LDAP_ALLOWED_HOSTNAMES: ${AUTHENTICATION_LDAP_ALLOWED_HOSTNAMES:-[]}
        # AUTHENTICATION_LDAP_SSL_VERIFY_CERT_HOST: ${AUTHENTICATION_LDAP_SSL_VERIFY_CERT_HOST:-}
        # AUTHENTICATION_LDAP_EXAMINE_VALIDITY_DATES: ${AUTHENTICATION_LDAP_EXAMINE_VALIDITY_DATES:-true}

        # JWT Configuration
        RSA_PUBLIC_KEY_FILE_PATH: ${RSA_PUBLIC_KEY_FILE_PATH:-"./conf/public_key.der"}
        RSA_PRIVATE_KEY_FILE_PATH: ${RSA_PRIVATE_KEY_FILE_PATH:-"./conf/private_key.der"}
        JWT_ISSUER: ${JWT_ISSUER:-"open-metadata.org"}
        JWT_KEY_ID: ${JWT_KEY_ID:-"Gb389a-9f76-gdjs-a92j-0242bk94356"}
        # OpenMetadata Server Pipeline Service Client Configuration
        PIPELINE_SERVICE_CLIENT_ENDPOINT: ${PIPELINE_SERVICE_CLIENT_ENDPOINT:-http://192.168.202.167:8080}
        PIPELINE_SERVICE_CLIENT_HEALTH_CHECK_INTERVAL: ${PIPELINE_SERVICE_CLIENT_HEALTH_CHECK_INTERVAL:-300}
        SERVER_HOST_API_URL: ${SERVER_HOST_API_URL:-http://192.168.202.167:8585/api}
        PIPELINE_SERVICE_CLIENT_VERIFY_SSL: ${PIPELINE_SERVICE_CLIENT_VERIFY_SSL:-"no-ssl"}
        PIPELINE_SERVICE_CLIENT_SSL_CERT_PATH: ${PIPELINE_SERVICE_CLIENT_SSL_CERT_PATH:-""}
        #Database configuration for postgresql
        DB_DRIVER_CLASS: ${DB_DRIVER_CLASS:-org.postgresql.Driver}
        DB_SCHEME: ${DB_SCHEME:-postgresql}
        DB_PARAMS: ${DB_PARAMS:-allowPublicKeyRetrieval=true&useSSL=false&serverTimezone=UTC}
        DB_USER: ${DB_USER:-openmetadata_user}
        DB_USER_PASSWORD: ${DB_USER_PASSWORD:-openmetadata_password}
        DB_HOST: ${DB_HOST:-postgresql}
        DB_PORT: ${DB_PORT:-5432}
        OM_DATABASE: ${OM_DATABASE:-openmetadata_db}
        # ElasticSearch Configurations
        ELASTICSEARCH_HOST: ${ELASTICSEARCH_HOST:- elasticsearch}
        ELASTICSEARCH_PORT: ${ELASTICSEARCH_PORT:-9200}
        ELASTICSEARCH_SCHEME: ${ELASTICSEARCH_SCHEME:-http}
        ELASTICSEARCH_USER: ${ELASTICSEARCH_USER:-""}
        ELASTICSEARCH_PASSWORD: ${ELASTICSEARCH_PASSWORD:-""}
        SEARCH_TYPE: ${SEARCH_TYPE:- "elasticsearch"}
        ELASTICSEARCH_TRUST_STORE_PATH: ${ELASTICSEARCH_TRUST_STORE_PATH:-""}
        ELASTICSEARCH_TRUST_STORE_PASSWORD: ${ELASTICSEARCH_TRUST_STORE_PASSWORD:-""}
        ELASTICSEARCH_CONNECTION_TIMEOUT_SECS: ${ELASTICSEARCH_CONNECTION_TIMEOUT_SECS:-5}
        ELASTICSEARCH_SOCKET_TIMEOUT_SECS: ${ELASTICSEARCH_SOCKET_TIMEOUT_SECS:-60}
        ELASTICSEARCH_KEEP_ALIVE_TIMEOUT_SECS: ${ELASTICSEARCH_KEEP_ALIVE_TIMEOUT_SECS:-600}
        ELASTICSEARCH_BATCH_SIZE: ${ELASTICSEARCH_BATCH_SIZE:-10}
        ELASTICSEARCH_PAYLOAD_BYTES_SIZE: ${ELASTICSEARCH_PAYLOAD_BYTES_SIZE:-10485760}   #max payLoadSize in Bytes
        ELASTICSEARCH_INDEX_MAPPING_LANG: ${ELASTICSEARCH_INDEX_MAPPING_LANG:-EN}

        #eventMonitoringConfiguration
        EVENT_MONITOR: ${EVENT_MONITOR:-prometheus}
        EVENT_MONITOR_BATCH_SIZE: ${EVENT_MONITOR_BATCH_SIZE:-10}
        EVENT_MONITOR_PATH_PATTERN: ${EVENT_MONITOR_PATH_PATTERN:-["/api/v1/tables/*", "/api/v1/health-check"]}
        EVENT_MONITOR_LATENCY: ${EVENT_MONITOR_LATENCY:-[]}

        #pipelineServiceClientConfiguration
        PIPELINE_SERVICE_CLIENT_ENABLED: ${PIPELINE_SERVICE_CLIENT_ENABLED:-true}
        PIPELINE_SERVICE_CLIENT_CLASS_NAME: ${PIPELINE_SERVICE_CLIENT_CLASS_NAME:-"org.openmetadata.service.clients.pipeline.airflow.AirflowRESTClient"}
        PIPELINE_SERVICE_IP_INFO_ENABLED: ${PIPELINE_SERVICE_IP_INFO_ENABLED:-false}
        PIPELINE_SERVICE_CLIENT_HOST_IP: ${PIPELINE_SERVICE_CLIENT_HOST_IP:-""}
        PIPELINE_SERVICE_CLIENT_SECRETS_MANAGER_LOADER: ${PIPELINE_SERVICE_CLIENT_SECRETS_MANAGER_LOADER:-"noop"}
        #airflow parameters
        AIRFLOW_USERNAME: ${AIRFLOW_USERNAME:-admin}
        AIRFLOW_PASSWORD: ${AIRFLOW_PASSWORD:-admin}
        AIRFLOW_TIMEOUT: ${AIRFLOW_TIMEOUT:-10}
        AIRFLOW_TRUST_STORE_PATH: ${AIRFLOW_TRUST_STORE_PATH:-""}
        AIRFLOW_TRUST_STORE_PASSWORD: ${AIRFLOW_TRUST_STORE_PASSWORD:-""}
        FERNET_KEY: ${FERNET_KEY:-jJ/9sz0g0OHxsfxOoSfdFdmk3ysNmPRnH3TUAbz3IHA=}

        #secretsManagerConfiguration
        SECRET_MANAGER: ${SECRET_MANAGER:-db}
        #parameters:
        OM_SM_REGION: ${OM_SM_REGION:-""}
        OM_SM_ACCESS_KEY_ID: ${OM_SM_ACCESS_KEY_ID:-""}
        OM_SM_ACCESS_KEY: ${OM_SM_ACCESS_KEY:-""}

        #email configuration:
        OM_EMAIL_ENTITY: ${OM_EMAIL_ENTITY:-"OpenMetadata"}
        OM_SUPPORT_URL: ${OM_SUPPORT_URL:-"https://slack.open-metadata.org"}
        AUTHORIZER_ENABLE_SMTP : ${AUTHORIZER_ENABLE_SMTP:-false}
        OPENMETADATA_SERVER_URL: ${OPENMETADATA_SERVER_URL:-""}
        OPENMETADATA_SMTP_SENDER_MAIL: ${OPENMETADATA_SMTP_SENDER_MAIL:-""}
        SMTP_SERVER_ENDPOINT: ${SMTP_SERVER_ENDPOINT:-""}
        SMTP_SERVER_PORT: ${SMTP_SERVER_PORT:-""}
        SMTP_SERVER_USERNAME: ${SMTP_SERVER_USERNAME:-""}
        SMTP_SERVER_PWD: ${SMTP_SERVER_PWD:-""}
        SMTP_SERVER_STRATEGY: ${SMTP_SERVER_STRATEGY:-"SMTP_TLS"}

        # Heap OPTS Configurations
        OPENMETADATA_HEAP_OPTS: ${OPENMETADATA_HEAP_OPTS:--Xmx1G -Xms1G}
        # Mask passwords values in UI
        MASK_PASSWORDS_API: ${MASK_PASSWORDS_API:-false}

        #OpenMetadata Web Configuration
        WEB_CONF_URI_PATH: ${WEB_CONF_URI_PATH:-"/api"}
        #HSTS
        WEB_CONF_HSTS_ENABLED: ${WEB_CONF_HSTS_ENABLED:-false}
        WEB_CONF_HSTS_MAX_AGE: ${WEB_CONF_HSTS_MAX_AGE:-"365 days"}
        WEB_CONF_HSTS_INCLUDE_SUBDOMAINS: ${WEB_CONF_HSTS_INCLUDE_SUBDOMAINS:-"true"}
        WEB_CONF_HSTS_PRELOAD: ${WEB_CONF_HSTS_PRELOAD:-"true"}
        #Frame Options
        WEB_CONF_FRAME_OPTION_ENABLED: ${WEB_CONF_FRAME_OPTION_ENABLED:-false}
        WEB_CONF_FRAME_OPTION: ${WEB_CONF_FRAME_OPTION:-"SAMEORIGIN"}
        WEB_CONF_FRAME_ORIGIN: ${WEB_CONF_FRAME_ORIGIN:-""}
        #Content Type
        WEB_CONF_CONTENT_TYPE_OPTIONS_ENABLED: ${WEB_CONF_CONTENT_TYPE_OPTIONS_ENABLED:-false}
        #XSS-Protection
        WEB_CONF_XSS_PROTECTION_ENABLED: ${WEB_CONF_XSS_PROTECTION_ENABLED:-false}
        WEB_CONF_XSS_PROTECTION_ON: ${WEB_CONF_XSS_PROTECTION_ON:-true}
        WEB_CONF_XSS_PROTECTION_BLOCK: ${WEB_CONF_XSS_PROTECTION_BLOCK:-true}
        #CSP
        WEB_CONF_XSS_CSP_ENABLED: ${WEB_CONF_XSS_CSP_ENABLED:-false}
        WEB_CONF_XSS_CSP_POLICY: ${WEB_CONF_XSS_CSP_POLICY:-"default-src 'self'"}
        WEB_CONF_XSS_CSP_REPORT_ONLY_POLICY: ${WEB_CONF_XSS_CSP_REPORT_ONLY_POLICY:-""}

        expose:
        - 8585
        - 8586
        ports:
        - "8585:8585"
        - "8586:8586"
        depends_on:
        elasticsearch:
            condition: service_healthy
        postgresql:
            condition: service_healthy
        execute-migrate-all:
            condition: service_completed_successfully
        networks:
        - app_net
        healthcheck:
        test: [ "CMD", "wget", "-q", "--spider",  "http://localhost:8586/healthcheck" ]

        # ingestion:
        #   container_name: openmetadata_ingestion
        #   image: docker.getcollate.io/openmetadata/ingestion:1.4.0-rc2
        #   depends_on:
        #     elasticsearch:
        #       condition: service_started
        #     postgresql:
        #       condition: service_healthy
        #     openmetadata-server:
        #       condition: service_started
        #   environment:
        #     AIRFLOW__API__AUTH_BACKENDS: "airflow.api.auth.backend.basic_auth,airflow.api.auth.backend.session"
        #     AIRFLOW__CORE__EXECUTOR: LocalExecutor
        #     AIRFLOW__OPENMETADATA_AIRFLOW_APIS__DAG_GENERATED_CONFIGS: "/opt/airflow/dag_generated_configs"
        #     DB_HOST: ${AIRFLOW_DB_HOST:-postgresql}
        #     DB_PORT: ${AIRFLOW_DB_PORT:-5432}
        #     AIRFLOW_DB: ${AIRFLOW_DB:-airflow_db}
        #     DB_USER: ${AIRFLOW_DB_USER:-airflow_user}
        #     DB_SCHEME: ${AIRFLOW_DB_SCHEME:-postgresql+psycopg2}
        #     DB_PASSWORD: ${AIRFLOW_DB_PASSWORD:-airflow_pass}
        #     # extra connection-string properties for the database
        #     # EXAMPLE
        #     # require SSL (only for Postgres)
        #     # properties: "?sslmode=require"
        #     DB_PROPERTIES: ${AIRFLOW_DB_PROPERTIES:-}
        #     # To test the lineage backend
        #     # AIRFLOW__LINEAGE__BACKEND: airflow_provider_openmetadata.lineage.backend.OpenMetadataLineageBackend
        #     # AIRFLOW__LINEAGE__AIRFLOW_SERVICE_NAME: local_airflow
        #     # AIRFLOW__LINEAGE__OPENMETADATA_API_ENDPOINT: http://openmetadata-server:8585/api
        #     # AIRFLOW__LINEAGE__JWT_TOKEN: ...
        #   entrypoint: /bin/bash
        #   command:
        #     - "/opt/airflow/ingestion_dependency.sh"
        #   expose:
        #     - 8080
        #   ports:
        #     - "8080:8080"
        #   networks:
        #     - app_net

    networks:
    app_net:
        ipam:
        driver: default
        config:
            - subnet: "172.16.240.0/24"
    ```

    Run  

    ```shell
    docker-compose -f {compose-file} up -d
    ```

6. airflow user create  

    ```shell
    airflow users create -uadmin -padmin -rAdmin -f firstname -l lastname -e email@email.com
    ```

7. run airflow  

    ```shell
    airflow webserver -p 8080 -w 2
    ```

8. run airflow in pycharm  
    in mac(arm processor(m1, m2, m3)) pycharm will error gunicorn worker sigsegv...  

    ```text
    airflow webserver -p 8080 -w 2
    ```

9. For Debuging Mode  
    IDE Tool을 활용한 디버깅 모드 실행 시 소스 연결을 쉽게하기 위함.  

    1) Change Name Of OpenMetadata Directories  
        `pip install` 명령으로 설치된 managed_api, metadata 의 이름 변경

        ```shell
        mv openmetadata_managed_apis openmetadata_managed_apis_old
        mv metadata metadata_old
        ```

    2) Create Link From Source  
        ln 을 이용한 소스디렉토리 연결  

        ```shell
        ln -s {OPEN_METADATA}/openmetadata-airflow-apis/openmetadata_managed_apis {PYTHON_PKG}/openmetadata_managed_apis
        ln -s {OPEN_METADATA}/ingestion/src/metadata {PYTHON_PKG}/metadata
        ```


The necessary bits to build these optional modules were not found:
_bz2                  _gdbm                 _sqlite3
_tkinter              _uuid                 readline
To find the necessary bits, look in setup.py in detect_modules() for the module's name.


The following modules found by detect_modules() in setup.py, have been
built by the Makefile instead, as configured by the Setup files:
_abc                  pwd                   time


Failed to build these modules:
_ctypes               _hashlib              _ssl