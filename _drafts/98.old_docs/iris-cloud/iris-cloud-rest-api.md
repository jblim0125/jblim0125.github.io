# IRIS-Cloud

> HOST: `http://192.168.0.70:8075/api`

IRIS-Cloud(v.0.1) 배포/삭제 API 설명.  
__중요 :: Provisioining Server, Cluster는 미리 준비된 상태__

## List [/installations{?page,per_page,include_deleted}]

```text
+ Parameters  
    + page : `0` (number, optional) - 확인하고자 하는 페이지
    + per_page : `25` (number, optional) - 하나의 페이지 당 보이고자 하는 서비스의 수 ( 전체 조회를 원하는 경우 -1 )
    + include_deleted : `false` (bool, optional) - 삭제된 서비스도 조회하고자 하는 경우 이 플래그를 설정한다.  
         + Members
            + true - 삭제된 서비스를 포함하여 조회
            + false - 삭제되지 않은 서비스만을 조회
```

### Service Lists [GET]

Cluster에 설치한 서비스들을 반환한다.  

```text
+ Response 200 (application/json)
    + Attributes ( array )
        + (Service)

## Create [/installations] 

### Create a New Service [POST]
새 서비스를 실행한다.  

```text
+ Request (application/json)
    + attributes (CreateService)

+ Response 201 (application/json)
    + attributes ( Service )
```

## Delete [/installations{id}]

### Delete Service [DELETE]

서비스를 삭제한다.

```text
+ Parameters  
    + id : `sample-service` (string, required) - 삭제할 서비스의 아이디

+ Response 200 ( application/json )
    + Attributes ( Service )
```

## CreateService (object)

```text
+ Cluster : 'my-cluster' ( string, optional ) - 서비스를 실행하고자 하는 클러스터의 이름  
    + default : `-`  
+ Namespace : `sample-service` ( string, required ) - 서비스를 실핼할 공간의 이름 ( k8s namespace )  
+ Metadata : ( array, required ) - 서비스에 포함되는 Operator, Pod의 버전 정보
    + (object) 
        + Name : `web-operator` ( enum[string], required ) - Operator의 이름
            + Members
                + `web-operator`
                + `cluster-operator`
                + `dashboard-operator`
                + `data-import-operator`
                + `data-trans-operator`
                + `db-browser-operator`
                + `dsmjhm-operator`
                + `hdfs-browser-operator`
                + `sherman-operator`
                + `sms-operator`
        + Img : `web-operator.1.0` ( string, required ) - Operator의 이미지(버전) 정보
```

## Service (object)

```text
+ ID : `sample service id` ( string ) - 서비스 고유 ID
+ ClusterID : `my-k8s-cluster` ( string ) - 서비스가 설치된 k8s 클러스터 ID
+ Namespace : `sample-service` ( string ) - 서비스가 설치된 공간의 이름( k8s의 namespace )
+ State : `Stable` ( enum[string] ) - 서비스의 상태 정보
    + Members
        + `creation-requested`
        + `creation-configuring-dns`
        + `creation-failed`
        + `creation-no-compatible-clusters`
        + `deletion-requested`
        + `deletion-in-progress`
        + `deletion-failed`
        + `deleted`
        + `upgrade-requested`
        + `upgrade-in-progress`
        + `upgrade-failed`
        + `stable`
+ Metadata : ( array ) - 서비스에 포함된 Operator, Pod의 버전 정보
    + (object) 
        + Name : `web-operator` ( enum[string], required ) - Operator의 이름
            + Members
                + `web-operator`
                + `cluster-operator`
                + `dashboard-operator`
                + `data-import-operator`
                + `data-trans-operator`
                + `db-browser-operator`
                + `dsmjhm-operator`
                + `hdfs-browser-operator`
                + `sherman-operator`
                + `sms-operator`
        + Img : `web-operator.1.0` ( string, required ) - Operator의 이미지(버전) 정보
+ CreateAt : `123123123`( number ) - 서비스 생성 시간(unix time, epoch time)  
+ DeleteAt : `123412323` ( number ) - 서비스 삭세 시간(unix time, epoch time)
+ LockAcquiredBy : `lockid` ( string ) - 서비스의 상태가 변경 중인 경우 제어하고 있는 프로세스 이름  
+ LockAcquiredAt : `12348` ( number ) - 서비스의 상태가 변경 중인 경우 제어 시작 시간
+ Port : `32010` ( number ) - 서비스 접속 포트 정보
```
