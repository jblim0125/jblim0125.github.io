# AWS에서 KOPS를 활용한 클러스터 구성  

이 문서는 CentOS 7 환경에서 작성되었습니다.  

## Requirements
1. CentOS 패키지 업데이트 및 epel-release 설치  
```
# yum update -y  
# yum -y install epel-release
```

1. pyenv, kubectl, kops 사용에 필요한 패키지 설치  
```
# yum install -y zlib-devel bzip2 bzip2-devel \
	readline-devel sqlite sqlite-devel openssl-devel jq\
	xz xz-devel curl git libffi-devel bind-utils  
```

1. pyenv-virtualenv 설치  
```
[ centos-linux ]# curl -L \ 
 https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer \
 | bash
```  
pyenv의 환경 변수 등록  
```bash
# Load pyenv automatically by adding  
# the following to ~/.bashrc:  
export PATH="/root/.pyenv/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
```
pyenv를 최신 버전으로 업데이트해야 할 경우 다음 명령을 수행합니다.  
```
# pyenv update  
```

1. pyenv를 이용한 python 설치  
다음과 같은 명령으로 python 3.7.4 을 설치할 수 있습니다.  
```bash
# pyenv install 3.7.4
```

1. 작업 폴더 생성 및 python 버전 지정  
```
# mkdir -p /kops/aws
# cd /kops/aws
# pyenv local 3.7.4
현재 위치의 버전 확인  
#pyenv versions
```

1. aws cli(version 1) 설치  
중요 : python 버전 지원과 관련    
> 2020년 1월 10일부로 AWS CLI 1.17 이상 버전은 더 이상 Python 2.6 또는 Python 3.3을 지원하지 않습니다.  
이 날짜 이후에 AWS CLI를 성공적으로 설치하려면 AWS CLI의 설치 프로그램은 Python 2.7, Python 3.4 또는 
그 이상 버전이 필요합니다. 자세한 내용은 이 설명서의 Python 2.6 또는 Python 3.3에서 AWS CLI 버전 1 
사용 및 이 블로그 게시물의 사용 중단 공지를 참조하십시오.  

```bash
# pip install awscli --upgrade
```
pip 버전과 관련 오류가 발생하는 경우 
올바르게 설치되었는지 확인합니다.  
```
# aws --version
```

1. kubectl 설치  
패키지 매니저를 이용한 설치 방법  
저장소 추가  
```bash
# cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
```
kubectl 설치  
```bash
# yum install -y kubectl  
```

1. kops 설치  
From Github:  
```bash
# export kops_lastest=`curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4`
# echo $kops_lastest
# curl -Lo kops https://github.com/kubernetes/kops/releases/download/$(kops_lastest)/kops-linux-amd64
# chmod +x ./kops
# mv ./kops /usr/local/bin/
```

1. AWS 가입과 Access Key, Access Key Password 확인  
1) 웹 환경에서 AWS에 가입하고 콘솔을 로그인한다.  
2) 우측 상단의 아이디 부분을 클릭하고, 내 보안과 자격 증명을 선택한다.  
3) 액세스 키를 선택하고 새 액세스 키 만들기를 선택  
4) csv파일로 자신의 피씨에 저장하고, 파일에서 Access Key, Access Key Password를 확인한다.   
*) 보안 상 루트 계정의 액세스 키는 다음의 사용자 생성이 끝나면 삭제해야 한다.  

1. 루트 계정으로 그룹 및 사용자 생성  
AWS CLi에 root 계정 정보 입력  
```bash  
# aws configure
AWS Access Key ID [None]: xxxx
AWS Secret Access Key [None]: xxxx
Default region name [None]: ap-northeast-2
Default output format [None]: 
```  
kops 이름의 그룹을 생성하여 권한을 부여하고 kops 사용자를 생성  
```bash  
# aws iam create-group --group-name kops
# aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess --group-name kops
# aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/IAMFullAccess --group-name kops
# aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess --group-name kops
# aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonSSMFullAccess --group-name kops
# aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonVPCFullAccess --group-name kops
# aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonDataSyncFullAccess --group-name kops
# aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonElasticFileSystemFullAccess --group-name kops
# aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonRoute53FullAccess --group-name kops
# aws iam create-user --user-name kops
# aws iam add-user-to-group --user-name kops --group-name kops  
# aws iam create-access-key --user-name kop| gs
```  
위 과정에서 마지막 명령을 통해 kops의 액세스 키와 액세스 키 패스워드가 생성된다.  
이 액세스 키와 암호를 AWS CLi에 설정한다.  
```bash  
# aws configure
AWS Access Key ID [xxxx]: xxxx
AWS Secret Access Key [xxxx]: xxxx
Default region name [ap-northeast-2]: ap-northeast-2
Default output format [None]: 
```  
루트 계정의 액세스 키는 AWS 콘솔을 이용해 삭제한다.  

## Cluster 네트워크 환경 별 아키텍쳐  
### Public Network  
1. 모든 노드를 public 환경에서 동작하도록 한다.  
![all-node-public](./img/all_node_public.png)  

### Private Network  
1. 모든 노드를 private 환경에서 동작하도록 한다.  
![all-node-private](./img/all_node_private.png)  

## Cluster 구성 전 요구 사항  
1. S3 Bucket 생성  
test.iris.cloud 이름의 bucket을 ap-northeast-2에 생성   
```bash
# aws s3api create-bucket --bucket test.iris.cloud \
--create-bucket-configuration LocationConstraint=ap-northeast-2
```
추가 설정 : Versioning 활성화  
```bash
# aws s3api put-bucket-versioning --bucket test.iris.cloud\
  --versioning-configuration Status=Enabled
```
추가 설정 : 암호화 활성화  
```bash
# aws s3api put-bucket-encryption --bucket test.iris.cloud\ 
 --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
```

2. 도메인 설정(AWS Route53)  
도메인이 없는 경우 도메인을 구매하고 아마존에 등록하는 
과정이 필요하다. 이 문서 상에서는 도메인이 이미 등록되어 
있는 상태이며, Sub-domain을 루트 도메인(부모 도메인)에 
추가하고 진행하는 방법에 대해서 설명한다.  
다음은 서브도메인을 생성하고 NS 서버 정보를 출력하는 명령이다.  
(생성에 성공하고 출력되는 NS(Name Server)정보를 기록한다)  
```bash
# ID=$(uuidgen) && aws route53 create-hosted-zone\ 
    --name subdomain.iris.com --caller-reference $ID | \
    jq .DelegationSet.NameServers
```
부모 도메인의 Hostzone 정보를 확인한다. (실행 결과 값(hostzone)을 기록한다)  
```bash
# aws route53 list-hosted-zones | jq '.HostedZones[] | select(.Name=="iris.com") | .Id'
```  
다음 내용 중 Name과 ResourceRecords 부분을 위 명령 처리 결과들로 변경하고 subdomain.json으로 저장한다.  
```text/json  
{
  "Comment": "Create a subdomain NS record in the parent domain",
  "Changes": [
    {
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "subdomain.iris.com",
        "Type": "NS",
        "TTL": 300,
        "ResourceRecords": [
          {
            "Value": "ns-1.awsdns-1.co.uk"
          },
          {
            "Value": "ns-2.awsdns-2.org"
          },
          {
            "Value": "ns-3.awsdns-3.com"
          },
          {
            "Value": "ns-4.awsdns-4.net"
          }
        ]
      }
    }
  ]
}
```  
서브도메인의 NS정보를 부모 호스트 존에 저장한다.  
```bash
# aws route53 change-resource-record-sets \
 --hosted-zone-id <parent-zone-id> \
 --change-batch file://subdomain.json
```  
반영 결과를 확인한다.(서버 반영은 몇분이 소요될 수도 있다)  
```bash
# dig ns subdomain.iris.com
```
실행 결과는 다음과 유사해야 한다.  
```bash
;; ANSWER SECTION:
subdomain.iris.com.        172800  IN  NS  ns-1.awsdns-1.net.
subdomain.iris.com.        172800  IN  NS  ns-2.awsdns-2.org.
subdomain.iris.com.        172800  IN  NS  ns-3.awsdns-3.com.
subdomain.iris.com.        172800  IN  NS  ns-4.awsdns-4.co.uk.
```
이 서브 도메인을 생성하고 연결하는 과정에서 문제가 되기 쉽다.
(문제를 만드는 가장 큰 이유이다!) dig 툴을 실행해서 클러스터 설정이 
정확한지 한번 더 확인 한다. 당신의 hosted zone용으로 할당된 3~4개의 
NS 레코드를 Route53에서 확인할 수 있어야 한다.  
이제 subdomain.iris.com의 하위에 해당하는 *.subdomain.iris.com은 
여기서 생성한 hostzone으로 라우팅된다.     

3. SSH 접속을 위한 인증서 생성  
```bash
# ssh-keygen -t rsa -f id_rsa -N ''
# chmod 400 id_rsa.pub
```

## Cluster 환경 별 구성 방법  
> 중요  
kops 옵션 중 ami(EC2 이미지), networking(쿠버네티스 클러스터 네트워크) 의 경우 
제한이 있다. ami의 경우 kops에서 ami를 검색하여 선호하는 이미지를 선택해야 한다. 
일반 ami를 이용할 경우 클러스터 구성에 문제가 생기거나 ssh 접속 설정을 수동으로 
진행해야 한다.  

### Public Network  
다음은 위에서 생성한 서브 도메인, S3버켓, SSH키를 이용해 서울의 Zone 3개에 클러스터를 생성한다.(dry-run)  
```bash  
# kops create cluster --cloud=aws \
    --zones="ap-northeast-2a,ap-northeast-2b,ap-northeast-2c" \
    --ssh-public-key="./id_rsa.pub" \
    --master-size=t3.large \
    --master-count=1 \
    --node-size=t3.large \
    --node-count=2 \
    --network-cidr="100.0.0.0/16" \
    --state=s3://iris-cloud-provisioning \
    --dns-zone=Z23D4OTC0O0HOT \
    --networking=calico \
    --name=public.iris01.iris.tools
```
변경하고자 하는 정보가 있다면 다음 명령들을 이용해 변경한다.  
```bash
* edit this cluster with: kops edit cluster public.iris01.iris.tools
* edit your node instance group: kops edit ig --name=public.iris01.iris.tools nodes
* edit your master instance group: kops edit ig --name=public.iris01.iris.tools master-ap-northeast-2a
```  
실제 AWS에 생성을 시작한다.  
```bash
# kops update cluster --name public.iris01.iris.tools --yes
```  
'--yes'가 없이 실행 시 dry-run으로 진행된다.   
생성은 5-10 분이 소요될 수 있으며, 다음 명령들을 이용해 생성이 완료되었는지 확인할 수 있다.  
```bash
# kops validate cluster
# kubectl get nodes
```
생성이 완료되면 ssh 접속 가능하며, 다음과 같이 생성한 키, admin, dns를 이용해 접속한다.  
```bash
# ssh -i id_rsa admin@api.public.iris01.iris.tools
```
쿠버네티스 config 에 클러스터 정보가 추가되어 kubectl 명령으로도 상태를 확인할 수 있다.  
```bash  
# kubectl get nodes  
```  


### Private Network  
Private Network는 외부에서 다이렉트로 접근이 불가능한 형태로 구성되는 클러스터이다.  
직접 접속은 불가하고 bastion을 이용해 클러스터에 접속이 가능한 형태이다.  

> 중요  
Private Network를 사용한 클러스터를 생성할 경우 쿠버네티스에 사용할 수 있는 
네트워크 addon은 다음과 같다.  
```
kopeio-vxlan
weave
calico
cni
```  

다은은 Private Subnet을 기반으로하는 클러스터 생성한다. 
```bash
# kops create cluster --cloud=aws \
    --zones="ap-northeast-2a,ap-northeast-2b,ap-northeast-2c" \
    --ssh-public-key=./id_rsa.pub \
    --master-size=t3.large \
    --master-count=1 \
    --node-size=t3.large \
    --node-count=2 \
    --network-cidr="100.0.0.0/16" \
    --state=s3://iris-cloud-provisioning \
    --dns-zone=ZA5LXOTGHLJPL \
    --networking=calico \
    --out=/root/kops/aws \
    --topology=private \
    --bastion \ 
    --name=private.iris01.iris.tools  
```  
kops edit cluster 명령을 이용해 로드밸런서의 type을 변경해 외부와 차단되도록 한다.  
```bash
# kops edit cluster private.iris01.iris.tools
spec: 
  loadBalancer:
    type: Internal
```  
kops update cluster 명령을 이용해 클러스터를 생성한다.  
```bash
# kops update cluster private.iris01.iris.tools --yes  
```
bastion에서 master로 접속하기 위해서는 ssh-agent를 이용해야 한다. 
다음은 ssh-agent 를 실행하고 위에서 생성한 클러스터의 ssh private key를 등록하는 명령이다.  
```bash
# eval $(ssh-agent)
# ssh-add ./id_rsa
```
5-10분 경과 후 bastion -> 클러스터 마스터로 접속하여 상태를 확인한다. 
bastion의 주소는 bastion.<cluster name(dns)> 이다.    
```bash
# ssh -A admin@bsastion.private.iris01.iris.tools  
//마스터의 IP는 AWS console 에서 확인하거나 다음 명령으로 확인할 수 있다.  
# aws ec2 describe-instances --filters "Name=tag-value,Values=private.iris01.iris.tools","Name=tag-key,Values=k8s.io/role/master"
# ssh <master private ip>  
```  

## Network 구성 별 서비스 외부 공개 방법  
### Public Network  
### Route53 Sub-domain을 이용한 서비스 방식  
1. 직접 Route53 설정  
2. External DNS 활용  
### AWS Ingress(ELB)를 이용한 서비스 방식  
1. 직접 Route53 설정  

## 그 외 정보(kops)  
### kops AMI  
### kops addon  
