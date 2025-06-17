# IRIS Cloud CLI


0. 요구조건  
	- IRIS-Cloud가 실행 중인 서버 정보(IP, Port)  
	(ex : 설명을 위해 이 문서에서는 IRIS-Cloud가 192.168.102.114:32080으로 서비스 중 )  
	- CLI를 위해 IRIS-Cloud 바이너리가 필요하다.  
	```bash
	## 다음 파라미터는 모든 명령에 필요  
	# --server http://192.168.102.114:32080 
	```
1. Cluster  
	클러스터 정보 조회, 생성, 삭제 명령으로 "iris-cloud cluster" 로 시작한다.  
1.1. List  
	아이리스 클라우드에서 관리하는 클러스터들을 조회  
	```bash
	## 전체 데이터를 per-page로 자르고 page에 해당하는 데이터를 전달한다.  
	## page, per-page 는 생략 가능하며, per-page -1 전달 시 전체 데이터를 조회한다.  
	# iris-cloud cluster list --server http://192.168.102.114:32080 --page 0 --per-page 2
	```
1.2. Get  
	클러스터 하나의 정보를 조회  
	```bash
	# iris-cloud cluster get --server http://192.168.102.114:32080 --id [cluster id]  
	```
1.3. Create  
    신규 k8s 클러스터를 생성하거나, 미리 만들어진 k8s 클러스터 정보를 등록  
1.3.1. New Cluster  
	신규 k8s 클러스터를 생성(AWS)    
	기본 정보 외 특별히 필요한 정보는 DNS를 위한 AWS Route53ID(Parents Domain), 
	인스턴스 생성 지역을 위한 AWS에서 사용되는 존 정보가 필요하다.  
	```bash
	# iris-cloud cluster create --server http://192.168.102.114:32080 --provider aws \
	--name aws-cluster --zones 'ap-northeast-2a, ap-northeast-2c' --route53 Z23D4OTC0O0HOT 
	```
1.3.2. Registration Cluster  
	기존에 만들어진 k8s 클러스터를 등록   
	k8s api server연동을 위한 kubeconfig 파일, storage(NFS)서버 접속 정보가 필요하다.  
	IRIS 기준으로 스토리지 서버는 파드에 설정정보, 파드 종료 시에도 유지되어야 하는 데이터를 위해 
	사용된다.  
	```
	# iris-cloud cluster create --server http://192.168.102.114:32080 --name k8s.local \
		--provider aec --kubeconfig /root/.kube/config \
		--storage 'address=192.168.102.250, path=/IRIS, port=22, id=root, password=password`
	```
1.4. Delete  
	클러스터를 삭제  
	AWS에 클러스터를 생성한 경우 - AWS로부터 할당 받은 인스턴스와 자원들을 모두 해제  
	생성된 클러스터를 등록한 경우 - 등록 정보만을 삭제한다.  
	( 서비스가 생성되어 있는 경우 삭제 불가 )  
	```bash
	## --id = 클러스터의 아이디  
	# iris-cloud cluster delete --server http://192.168.102.114:32080 --id [cluster-id]
	```
2. Template  
	서비스 생성에 필요한 데이터 모음으로 POD를 생성하기 위한 이미지 정보(저장소,이미지이름,버전)과
	환경 설정에 사용될 파일들 그리고 기타 정보로 이루어진 데이터이다.  
2.1. List  
	등록된 템플릿들을 조회  
	```bash
	## 전체 데이터를 per-page로 자르고 page에 해당하는 데이터를 전달한다.  
	## page, per-page 는 생략 가능하며, per-page -1 전달 시 전체 데이터를 조회한다.  
	# iris-cloud template list --server http://192.168.102.114:32080 --page 0 --per-page -1
	```
2.2. Get  
	등록된 템플릿 정보 중 아이디를 이용해 하나의 템플릿 정보를 조회  
	```bash
	# iris-cloud template get --server http://192.168.102.114:32080 --id [template-id]
	```
2.3. Create  
	yaml 파일을 기준으로 템플릿을 생성  
	다음은 template을 생성하는 샘플 파일이다.(template.yaml)
	```yaml
	## service template 종류(k8s, helm)
	type: k8s

	## service type( analyzer or studio or anlayzer,studio ) 
	## 20.07.05기준 서초구청은 analyzer로 구성
	# serviceType: 
	# - "analyzer"
	# - "studio"
	serviceType:
	- "analyzer"

	## spark cluster 의 정보 
	## spark cluster를 k8s cluster 내부에 실행하는 경우
	#  sparkConn:
	#    type: internal
	#
	## spark cluster가 외부에 존재하는 경우 
	#  sparkConn:
	#    type: external
	#    host: 192.168.100.180
	#    port: 7077

	sparkConn:
	 type: internal

	## 내부에 spark cluster를 생성하는 경우 spark cluster option master, worker가 사용된다. 
	## driver의 경우 angora에서 사용할 cpu, memory에 해당 한다. 
	sparkMetadata:
	 master:
	   instances: 1
	   core: 2
	   mem: 2Gi
	 worker:
	   instances: 2
	   core: 2
	   mem: 2Gi
	## 주의: 위는 Gi 아래는 g로 메모리를 표기해야 한다.
	 driver:
	   core: 4
	   driverMem: 2g
	   executorCpu: 2
	   executorMem: 2g

	## 이미지가 저장되어 있는 registry의 정보 ( IP:PORT or DNS )
	# registry: 192.168.102.130:32500
	registry: repo.iris.tools/iris

	## registry 정보를 뺀 나머지 정보( IMAGE-NAME:TAG )
	images: 
	- "iris-entry:v2.200712.0-77834f9"
	- "angora:v2.200714.0_5c3e4c6"
	- "brick:v2.200713.0-d675da4"
	- "dashboard:test_ver.200706.0-a255369"
	- "data-trans-service:v2.5_d4fac8f"
	- "dsms:v2.200709.0-119292e"
	- "hdfs-browser:v2.200602.0-2614498"
	- "iris-web-platform:v2.20200714.0-784623e"
	- "jhms:v2.5_79a7662"
	- "osm:v2.200714.0-0000000"
	- "mariadb:v2.200714.0-3205918"
	- "memcached:latest"
	- "meta:test_ver.200702.0-2c97a9e"
	- "minio:v200622"
	- "postgres:10.6-gis"
	- "play-ground:1.3.11"
	- "service-discovery:v2.200702.0-f3ec80f"
	- "sherman:v2.200706.0-f7384b8"
	- "studio:v2.200708.0-21ca2db"
	- "spark-operator:latest"
	- "spark-standalone:v0.2"

	## 서비스 배포 시 기본이 아닌 다른 환경(b-iris/service에 해당하는 디렉토리)으로 서비스를 배포하고자 하는 경우
	## conf, dbdata, lib, logs, save로 이루어진 디렉토리
	# config: /root/b-iris/service

    ## pod하나를 생성하기 위해서 필요한 쿠버네티스 포맷의 설정 정보 파일의 저장소  
    ## deployment, service, volume, service account, role, rolebind 등을 포함하는 yaml 파일  
	# kubernetes : /root/b-iris/kubernetes  
	```
	위 파일을 이용해 템플릿을 생성하는 명령  
	```bash
	# iris-cloud template create --server http://192.168.102.114:32080 --name template-name --file ./template.yaml 
	```
2.4. Delete  
	지정한 아이디의 템플릿을 삭제  
	```bash
	# iris-cloud template delete --server http://192.168.102.114:32080 --id [template-id]  
	```
3. Service  
    서비스 조회, 생성, 삭제 명령으로 iris-cloud service로 시작한다.  
    서비스 생성은 2절에서 만들어진 템플릿을 이용해 이루어진다.  
3.1. List  
    아이리스 클라우드가 관리하고 있는 서비스들 정보  
	```bash
	## 전체 데이터를 per-page로 자르고 page에 해당하는 데이터를 전달한다.  
	## page, per-page 는 생략 가능하며, per-page -1 전달 시 전체 데이터를 조회한다.  
	# iris-cloud servcie list --server http://192.168.102.114:32080 --page 0 --per-page 2 
	```
3.2. Get  
    아이리스 클라우드 내에 관리되고 있는 하나의 서비스 조회  
	```bash
	# iris-cloud servcie get --server http://192.168.102.114:32080 --id [service-id]
	```
2.3. Create  
    서비스 템플릿을 이용해 서비스 생성  
	```bash
    ## --name : 서비스 구분을 위한 이름  
    ## --template-id : 서비스 사용에 사용 할 템플릿 아이디  
	# iris-cloud servcie create --server http://192.168.102.114:32080 --name service-name --template-id template-id
	```
2.4. Delete  
    서비스 삭제   
	```bash
    ## --id : 서비스 아이디  
	# iris-cloud servcie delete --server http://192.168.102.114:32080 --id 
	```

## Appendix.A Cluster 명령 실행 예제  
1. List  
```bash
# iris-cloud cluster list --server http://192.168.102.114:32080 --page 0 --per-page -1
[
    {
        "ID": "7x13nnmy7ty1djoajsiejb3abc",
        "Name": "k8s.local",
        "Provider": "aec",
        "Provisioner": "kops",
        "Size": "private-cluster",
        "KubeConfig": "/iris-cloud/clusters/k8s.local/kubeconfig",
        "AllowInstallations": false,
        "State": "stable",
        "Route53ID": "",
        "NodeInfo": [
            {
                "IsMaster": true,
                "Name": "platform-group-k8s-1.novalocal",
                "Address": "192.168.102.114"
            },
            {
                "IsMaster": false,
                "Name": "platform-group-k8s-2.novalocal",
                "Address": "192.168.102.243"
            },
            {
                "IsMaster": false,
                "Name": "platform-group-k8s-3.novalocal",
                "Address": "192.168.103.0"
            },
            {
                "IsMaster": false,
                "Name": "platform-group-k8s-4.novalocal",
                "Address": "192.168.102.142"
            },
            {
                "IsMaster": false,
                "Name": "platform-group-k8s-5.novalocal",
                "Address": "192.168.102.106"
            },
            {
                "IsMaster": false,
                "Name": "platform-group-k8s-6.novalocal",
                "Address": "192.168.102.215"
            }
        ],
        "StorageInfo": {
            "address": "192.168.102.250",
            "path": "/nfs",
            "port": 22,
            "id": "root",
            "password": "!ahqlwps936012#$"
        },
        "CreateAt": 1594373196989,
        "DeleteAt": 0,
        "LockAcquiredBy": null,
        "LockAcquiredAt": 0
    }
]
```
2. Get  
```bash
# iris-cloud cluster get --server http://192.168.102.114:32080 --id 7x13nnmy7ty1djoajsiejb3abc
{
	"ID": "7x13nnmy7ty1djoajsiejb3abc",
	"Name": "k8s.local",
	"Provider": "aec",
	"Provisioner": "kops",
	"Size": "private-cluster",
	"KubeConfig": "/iris-cloud/clusters/k8s.local/kubeconfig",
	"AllowInstallations": false,
	"State": "stable",
	"Route53ID": "",
	"NodeInfo": [
		{
			"IsMaster": true,
			"Name": "platform-group-k8s-1.novalocal",
			"Address": "192.168.102.114"
		},
		{
			"IsMaster": false,
			"Name": "platform-group-k8s-2.novalocal",
			"Address": "192.168.102.243"
		},
		{
			"IsMaster": false,
			"Name": "platform-group-k8s-3.novalocal",
			"Address": "192.168.103.0"
		},
		{
			"IsMaster": false,
			"Name": "platform-group-k8s-4.novalocal",
			"Address": "192.168.102.142"
		},
		{
			"IsMaster": false,
			"Name": "platform-group-k8s-5.novalocal",
			"Address": "192.168.102.106"
		},
		{
			"IsMaster": false,
			"Name": "platform-group-k8s-6.novalocal",
			"Address": "192.168.102.215"
		}
	],
	"StorageInfo": {
		"address": "192.168.102.250",
		"path": "/nfs",
		"port": 22,
		"id": "root",
		"password": "!ahqlwps936012#$"
	},
	"CreateAt": 1594373196989,
	"DeleteAt": 0,
	"LockAcquiredBy": null,
	"LockAcquiredAt": 0
}
```
3. Create  
기존에 생성되어 있는 클러스터를 등록  
```bash
# iris-cloud cluster create --server http://192.168.102.114:32080 --name k8s.test --provider aec \
--kubeconfig /root/.kube/config \
--storage 'address=192.168.102.114, port=22, path=/IRIS, id=root, password=password`

INFO[2020-07-17T17:51:29.838425][cluster.go:133 / func1] address address, 192.168.102.114             
INFO[2020-07-17T17:51:29.838620][cluster.go:139 / func1] port  port, 22                               
INFO[2020-07-17T17:51:29.838655][cluster.go:136 / func1] path  path, /IRIS                            
{
    "ID": "urtqz3b8apgdtb4emfea8thttw",
    "Name": "k8s.test",
    "Provider": "aec",
    "Provisioner": "kops",
    "Size": "private-cluster",
    "KubeConfig": "/iris-cloud/clusters/k8s.test/kubeconfig",
    "AllowInstallations": false,
    "State": "creation-requested",
    "Route53ID": "",
    "StorageInfo": {
        "address": "192.168.102.114",
        "path": "/IRIS",
        "port": 22,
        "id": "root",
        "password": "password"
    },
    "CreateAt": 1594975889875,
    "DeleteAt": 0,
    "LockAcquiredBy": null,
    "LockAcquiredAt": 0
}

```
4. Delete  
```bash
# iris-cloud cluster delete --server http://192.168.102.114:32080 --id urtqz3b8apgdtb4emfea8thttw
```
## Appendix.B Template 명령 실행 예제  
1. List  
2. Get  
3. Create  
4. Delete  
## Appendix.C Service 명령 실행 예제  
1. List  
2. Get  
3. Create  
4. Delete  