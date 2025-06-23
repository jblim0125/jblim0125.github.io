# Provisioning Server

## About. Provisioning Server

Provisioning Server( 이하 PS )는 aws, kops, terraform, helm, kubctl, db( sqlite ) 조합으로 동작한다.
PS는 현재 이미 구성된 K8S클러스터를 대상으로 Operator를 실행하고 helm을 이용해 Operator에
Custom Resource를 전달해 서비스를 실행하도록 개발되었다.  
목표는 AWS, Google Cloud와 같은 상용 클라우드에 k8s 클러스터를 구성하고 서비스(IRIS) 실행이다.

## 1. Prerequirement

- Install Go  
    1. Download tarball.  

            ```sh
            $ wget https://dl.google.com/go/go1.13.linux-amd64.tar.gz
            ```

    2. Extract the tarball.  

            ```sh
            $ tar -C /usr/local -xzf go1.13.linux-amd64.tar.gz  
            ```

    3. Adjust the Path Variable.  

            ```sh
            # vi ~/.bash_profile
            export PATH=$PATH:/usr/local/go/bin  
            export GOROOT=/usr/local/go  
            # Go Pkg Directory  
            export GOPATH=/root/gopath  
            # PATH Modify
            export PATH=$PATH:/root/gopath/bin
            ```

    4. Activation

            ```sh
            # source ~/.bash_profile  
            ```

    5. Check

            ```sh
            # go version  
            # go env  
            ```

- Install Terraform ( > v.0.11.14 )  
    1. Download zip

            ```sh
            # wget https://releases.hashicorp.com/terraform/0.12.9/terraform_0.12.9_linux_amd64.zip
            ```

    2. Extract the zip

            ```sh
            # unzip terraform_0.12.9_linux_amd64.zip -d /usr/local/bin/
            ```

    3. Check

            ```sh
            # terraform -v
            ```

- Install kops (  > v.1.13.X )
    1. Download Binary  

            ```sh
            # wget https://github.com/kubernetes/kops/releases/download/1.13.1/kops-linux-amd64 
            ```

    2. Change authority  

            ```sh
            # chmod +x kops-linux-amd64
            ```

    3. Move binary to bin directory

            ```sh
            # mv kops-linux-amd64 /usr/local/bin/kops
            ```

    4. Check  

            # kops version  

- Install Helm  
    1. Download file  

            ```sh
            # wget https://get.helm.sh/helm-v3.0.0-beta.3-linux-amd64.tar.gz  
            ```

    2. Extract the file  

            ```sh
            # tar zxvf helm-v3.0.0-beta.3-linux-amd64.tar.gz  
            ```

    3. Move binary to bin directory  

            ```sh
            # mv linux-amd64/helm /usr/local/bin/helm
            ```

    4. Check

            ```sh
            # helm version  
            ```

- Install kubectl  
    1. Download file ( Latest release )

           ```sh
           # curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
           ```

        specific version (example v1.16.0)

           ```sh
           # curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.16.0/bin/linux/amd64/kubectl
           ```

    2. Change authority  

            ```sh
            # chmod +x ./kubectl  
            ```

    3. Move the binary in to your PATH directory  

            ```sh
            # mv ./kubectl /usr/local/bin/kubectl  
            ```

    4. Check  

            ```sh
            # kubectl version  
            ```

### 2. 기본 구조  

    ```sh
    ├── build  
    │   └── output  
    │        └── bin  :  build dir  
    ├── cmd   
    │   └── cloud  :  사용자 명령 처리    
    ├── conf.d :  서비스 별 설정 파일  
    ├── helm-charts :  helm  
    ├── internal  
    │   ├── api : HTTP RESTApi Server, client 요청을 확인 데이터 저장, supervisor 호출  
    │   ├── provisioner  : cluster를 구성, operator, service 실행  
    │   ├── store  :  저장소 읽기/쓰기  
    │   ├── supervisor  : 테이블의 데이터를 확인하고 상태에 따라 동작  
    │   ├── testlib  
    │   ├── tools  
    │   │   ├── aws  
    │   │   ├── exechelper  
    │   │   ├── k8s 
    │   │   ├── kops 
    │   │   ├── terraform  
    │   │   └── utils  
    │   └── webhook  : Event 발생 시 등록된 서버들로 HTTP Post msg 전달
    ├── kubernetes  : PS 실행을 위한 yaml 파일들  
    └── model  :  HTTP 통신 송수신 데이터 정의  
    ```

### 3. Building

- Compile  
        # make  
- Binary Install  
        # go install ./cmd/cloud  

### 4. Running

- 이미 구성된 k8s 클러스터를 대상으로 PS를 이용해 서비스를 실행하고자 하는 경우  
k8s 클러스터의 master에서 PS를 실행하고자 하는 서버로 다음 파일을 복사한다.  
`/root/.kube/config`

- PS 서버의 실행

최초 실행 시 다음 명령 실행
        # cloud schema migrate  
실행  
        # cloud server --database sqlite://cloud.db

- PS서버에 이미 구성된 K8S 클러스터 정보 등록  
    kubeconfig에 전에 복사한 k8s config 파일 path 정보 등록, provider는 aec(Already Exist Cluster)로 등록한다.  
        # cloud cluster create --kubeconf=config --name=mobigen  --provider=aec

#### kops_provisioner.go

kops, helm, terraform, k8s client를 이용해 클러스터를 관리하는 부분  

- methods  
  PrepareCluster : 프로비져닝을 위한 클러스터 오브젝트( kops data ) 준비  
  CreateCluster : 클러스터 생성, Helm 이용 관리용 Pods( 프로메테우스, 네트워크 등 ) 설치  
  ProvisionCluster : Operator 실행  
  UpgradeCluster :  클러스터 구성요소 업데이트( kops, terraform )  
  DeleteCluster :  이전에 설치한 클러스터 삭제( kops, terraform )  
  CreateClusterInstallation : 서비스 실행 ( Operator에 실행할 정보 전달 )  
  DeleteClusterInstallation : 서비스 중지  
  UpdateClusterInstallation : 서비스 버전 변경  
  GetClusterInstallationResource : 서비스를 실행하기 전 클러스터의 자원() 상태를 확인  

#### internal/api

- api.go  
    /api - HTTP Server의 RestAPI 최상위  
- cluster.go  
    /api/clusters - GET or POST  
        GET : return Clusters ( Global Filter 규칙에 따라 )  
        POST : create Cluster  
    /api/cluster/{cluster:clusterid} - GET or POST  
        GET : Get Cluster  
        POST : Retry Create  Cluster  
    /api/  
- cluster_installation.go  
- common.go  
- context.go  

#### Local Cluster 를 위한 변경

Add Clounm To Cluster Table : KubeConfig  
Add Type For Provider : Already Exist Cluster  
KubeConfig - k8s cluster config file path()  

#### 실행을 위한 변경  

#### For Operator Start / Stop / List  

CRD(CustomResourceDefine)와 Operator의 실행

1. CMD 추가  
    1.1. main.go  
        rootCmd.AddCommand 를 이용 operator를 제어할 명령 추가  
    1.2. operator.go  
        start, stop, list 추가  
2. Model 추가  
    2.1. client.go  
        api/operator/start, api/operator/stop, api/operator/list 추가  
    2.2. operator.go  
        송수신 데이터 및 json 데이터 구성, struct to json ( Vice versa )  
3. Client Func 추가  
4. Store  
    4.1. add operator table ( store/migrations.go )  
    4.2. add interface for operator Table ( context.go )  
    4.3. real func make ( store/operator.go )  
5. Supervisor ( supervisor/operator.go )
    각 상태 별 동작 구현  
6. Provisioning( kops_provisioner.go )
    k8s cluster 연동 ( corev1, appv1... )

#### For Service Start / Stop

installation - clusterinstallation 으로 연결 됨.

installation

1) 서비스를 올릴 수 있는 cluster를 검색  
2) cluster resource 확인  
3) cluster installation 을 생성  
4) polling cluster installation status  
5) fail? => install failed / success? => DNS Setup
6) finish.  

cluster_installation

1) installation으로부터 store에 저장된 데이터로부터 시작  

## 2. Building

...

## 3. Schema  

### Goal.1. 사내 k8s에 Operator를 실행  

시작  
    # cd provision_test/clusters/
    # cloud schema migrate [--database=sqlite://cloud.db]
    # cloud server --database=sqlite://cloud.db
    # cloud cluster create --kubeconfig=/root/provision_test/clusters/config --name=priv-cluster --provider=already_exist_cluster
    # cloud operator start --name=matter-operator --cluster=priv-cluster  
종료  
    # cloud operator stop --name=matter-operator  

서비스 시작
    # cloud installation create --owner=jblim --size=100users

서비스 실행 시  
installation option, Affinity 를 통해 하나의 Cluster에 하나만 실행할 것인지, 주어진 자원을 모두 활용할 때 까지 서비스를
올릴지 정할 수 있다.  
if installation.Affinity == model.InstallationAffinityIsolated  

args:  
    test1: opt1  
    test2: opt2

create, remove, list ( svc ), component type( a, b, c )
Namespace 이름을 자동이 아닌 주어진 이름으로 시작될 수 있도록..  wnrk  

pv, pvc를 위한 NFS 디렉토리 생성 ( /nfs/mariadb/'NS' )
label, label selector ( 'name' = 'NS'.'podname')
pvc, metadata의 namespace 변경 필요  

PS 서비스 기준으로 동작하도록 변경  
PS 에서 Helm으로 Operator, Pod 실행될 수 있도록 변경  

PS DB Schema 변경
PS Link

operator의 버전관리 필요  
installation cmd 에서 upgrade 수정 필요  
Operator의 버전과 구동되고 있는 Pod들의 버전을 관리해야 함.  

kops 특성 : aws, google, azure, openstack 을 지원 ( baremetal 지원 X )  
VM을 준비한 상태로 k8s 클러스터를 구성하고자 하는 경우 kops를 사용할 수 없다.  
VM을 준비한 상태로 k8s 클러스터를 구성하고자 하는 경우 kubespray를 사용할 수 있다.  
kubespray는 node ip와 계정 정보를 이용해 해당 node가 클러스터에 포함되도록 하는 기능을 제공한다.  
