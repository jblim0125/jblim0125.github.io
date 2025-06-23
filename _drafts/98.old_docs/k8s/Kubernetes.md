Kubernetes  
==

### 쿠버네티스란 ?  
- 컨테이너 운영환경 중 가장 널리 사용되는 솔루션  
- GO 언어로 구현  
- 벤더나 플랫폼에 종속되지 않음  
	대부분의 퍼블릭 클라우드 (구글,아마존,애저)등에 사용이 가능하고,  
	오픈 스택과 같은 프라이빗 클라우드 구축 환경이나 또는 가상화 환경을  
    사용하지 않는 일반 서버 하드웨어에도 배포가 가능하다
- 다양한 컨테이너 런타임 지원  
    Docker, CRIO-O, containerd

### 쿠버네티스 필요성, 제공 기능

1. 필요성  
	쿠버네티스는 분산 시스템을 탄력적으로 실행하기 위한 프레임 워크  
	( 예를 들어 컨테이너가 다운되면 다른 컨테이너를 다시 시작 )  
	- 운영 정책( 자원 정책, 스케일링 등 )
	- **장애 조치**
	- **배포 패턴**  
        다양한 배포 방식을 지원( 카나리아 배포도 쉽게 가능 )  
	- 그 외..

2. 제공 기능  
    - 서비스 디스커버리와 로드 밸런싱 : 중요   
		쿠버네티스는 DNS 이름을 사용하거나 자체 IP 주소를 사용하여   
		컨테이너를 노출할 수 있다. 컨테이너에 대한 트래픽이 많으면,   
		쿠버네티스는 네트워크 트래픽을 로드밸런싱하고 배포하여   
		배포가 안정적으로 이루어질 수 있다.
 
	- 스토리지 오케스트레이션 :  
		쿠버네티스를 사용하면 로컬 저장소, 공용 클라우드 공급자 등과 같이  
		원하는 저장소 시스템을 자동으로 탑재 할 수 있다.  
		
    - 자동화된 롤아웃과 롤백 : 중요  
		쿠버네티스를 사용하여 배포된 컨테이너의 원하는 상태를 서술할 수  
		있으며 현재 상태를 원하는 상태로 설정한 속도에 따라 변경할 수 있다.  
		예를 들어 쿠버네티스를 자동화해서 배포용 새 컨테이너를 만들고,   
		기존 컨테이너를 제거하고, 모든 리소스를 새 컨테이너에 적용할 수 있다.

	- 자동화된 빈 패킹(bin packing) : 중요  
		쿠버네티스를 사용하면 각 컨테이너에 필요한 CPU 및 메모리(RAM)의  
		양을 지정할 수 있다. 컨테이너에 자원 요청이 지정되면 쿠버네티스는  
		컨테이너에 대한 자원을 관리하기 위해 더 나은 결정을 내릴 수 있다.

	- 자동화된 복구(self-healing) :  중요  
		쿠버네티스는 실패한 컨테이너를 다시 시작하고, 컨테이너를 교체하며,  
		‘사용자 정의 상태 검사’에 응답하지 않는 컨테이너를 죽이고, 서비스  
		준비가 끝날 때까지 그러한 과정을 클라이언트에 보여주지 않는다.

	- 시크릿과 구성 관리 :  
		쿠버네티스를 사용하면 암호, OAuth 토큰 및 ssh 키와 같은 중요한   
		정보를 저장하고 관리 할 수 있다. 컨테이너 이미지를 재구성하지 않고   
		스택 구성에 비밀을 노출하지 않고도 비밀 및 애플리케이션 구성을   
		배포 및 업데이트 할 수 있다.

### 쿠버네티스가 아닌 것  
쿠버네티스는 전통적인, 모든 것이 포함된 Platform as a Service (PaaS)가 아니다.   
쿠버네티스는 컨테이너 수준에서 운영되기 때문에, PaaS가 일반적으로 제공하는   
배포, 스케일링, 로드 밸런싱,  로깅 및 모니터링과 같은 기능에서 공통점이 있기도  
하다.   
**하지만, 쿠버네티스는 이런 기본 솔루션이 선택적이며 추가나 제거가 용이하다.   
사용자의 선택권과 유연성을 지켜준다.**  
( 다른 의미로 많은 기능을 제공하고 편하게 해주지만 원하는 모델에 맞게 최초 구성(설정)은 쉽지 않다. )


쿠버네티스는 단순한 오케스트레이션 시스템이 아니다.  
오케스트레이션의 기술적인 정의는 A를 먼저 한 다음, B를 하고,  
C를 하는 것과 같이 정의된 워크플로우를 수행하는 것이다.  
반면에, 쿠버네티스는 독립적이고 조합 가능한 제어 프로세스들로  
구성되어 있다. 이 프로세스는 지속적으로 현재 상태를 입력받은  
의도된 상태로 나아가도록 한다.   
A에서 C로 어떻게 갔는지는 상관이 없다. 중앙화된 제어도 필요치  
않다. 이로써 시스템이 보다 더 사용하기 쉬워지고(?), 강력해지며,  
견고하고, 회복력을 갖추게 되며, 확장 가능해진다

### 쿠버네티스의 기본 개념  
쿠버네티스에서 가장 중요한 것은 원하는 상태라는 개념입니다.  
좀 더 구체적으로는 얼마나 많은 웹서버가 몇 번 포트로 서비스하기를  
원하는지 등을 말합니다.  
쿠버네티스는 복잡하고 다양한 작업을 하지만 자세히 들여다보면  
현재 상태를 모니터링하면서 관리자가 설정한 원하는 상태를 유지하려고  
내부적으로 이런저런 작업을 하는 단순한(?) 로직을 가지고 있습니다.

이러한 개념 때문에 관리자가 서버를 배포할 때 직접적인 동작을 명령하지  
않고 상태를 선언하는 방식을 사용합니다. 

기존 ( 명령 ) : "... 설정의 nginx를 실행"
쿠버 ( 상태 ) : "... 설정의 nginx 1개"

똑같은 요청을 단어를 살짝 바꿔 말장난하는게 아닌가 싶은데,
쿠버네티스의 핵심은 상태이며 쿠버네티스를 사용하려면 어떤 상태가 있고 
어떻게 상태를 선언하는지를 알아야 합니다.

### 쿠버네티스 컴포넌트

#### 마스터 컴포넌트( 이하 마스터 )  
- 클러스터에 관한 전반적인 결정  
- 클러스터 이벤트를 감지하고 반응    
- 사용자 컨테이너를 실행 X  
- 구성  
    * kube-apiserver  
    버네티스 컨트롤 플레인에 대한 프론트엔드
    * etcd  
    key-value 이루어진 데이터  
    모든 클러스터 데이터()를 저장를 담는 쿠버네티스 뒷단의 저장소  
    etcd는 오직 API 서버와 통신하고 다른 모듈은 API 서버를 거쳐 etcd 데이터에 접근  
    * kube-scheduler  
    노드가 배정되지 않은 새로 생성된 파드를 감지하고 그것이 구동될 노드를 선택하는 마스터 상의 컴포넌트.
    스케줄링 결정을 위해서 고려되는 요소는 리소스에 대한 개별 및 총체적 요구 사항, 하드웨어/소프트웨어/정책적 제약,  
    어피니티(affinity) 및 안티-어피니티(anti-affinity) 명세, 데이터 지역성, 워크로드-간 간섭, 데드라인을 포함한다.
    

    * kube-controller-manager  
    * cloud-controller-manager  
    
- 다중구성  
    * 홀수 구성 ( 2대보다 1대가 안정적 )  
    * RAFT 알고리즘( 투표 기반 다중화 )  
    
#### 노트 컴포넌트( 이하 노드 )  

#### 애드온  


#### kubectl plugin

Examples: Creating and using plugins
Use the following set of examples to help you familiarize yourself with writing and using kubectl plugins:

# create a simple plugin in any language and name the resulting executable file
# so that it begins with the prefix "kubectl-"
cat ./kubectl-hello
#!/bin/bash

# this plugin prints the words "hello world"
echo "hello world"

# with our plugin written, let's make it executable
sudo chmod +x ./kubectl-hello

# and move it to a location in our PATH
sudo mv ./kubectl-hello /usr/local/bin

# we have now created and "installed" a kubectl plugin.
# we can begin using our plugin by invoking it from kubectl as if it were a regular command
kubectl hello
hello world
# we can "uninstall" a plugin, by simply removing it from our PATH
sudo rm /usr/local/bin/kubectl-hello
In order to view all of the plugins that are available to kubectl, we can use the kubectl plugin list subcommand:

kubectl plugin list
The following kubectl-compatible plugins are available:

/usr/local/bin/kubectl-hello
/usr/local/bin/kubectl-foo
/usr/local/bin/kubectl-bar
# this command can also warn us about plugins that are
# not executable, or that are overshadowed by other
# plugins, for example
sudo chmod -x /usr/local/bin/kubectl-foo
kubectl plugin list
The following kubectl-compatible plugins are available:

/usr/local/bin/kubectl-hello
/usr/local/bin/kubectl-foo
  - warning: /usr/local/bin/kubectl-foo identified as a plugin, but it is not executable
/usr/local/bin/kubectl-bar

error: one plugin warning was found
We can think of plugins as a means to build more complex functionality on top of the existing kubectl commands:

cat ./kubectl-whoami
#!/bin/bash

# this plugin makes use of the `kubectl config` command in order to output
# information about the current user, based on the currently selected context
kubectl config view --template='{{ range .contexts }}{{ if eq .name "'$(kubectl config current-context)'" }}Current user: {{ .context.user }}{{ end }}{{ end }}'
Running the above plugin gives us an output containing the user for the currently selected context in our KUBECONFIG file:

# make the file executable
sudo chmod +x ./kubectl-whoami

# and move it into our PATH
sudo mv ./kubectl-whoami /usr/local/bin

kubectl whoami
Current user: plugins-user

컨테이너 환경을 왜 VM에 올리는가?
--
VM(가상화 환경)을 올린 후에, 그 위에 쿠버네티스를 배포하는 구조를 갖는다.   
왜 이렇게 할까 한동안 고민을 한적이 있었는데, 나름대로 내린 결론은 하드웨어   
자원 활용의 효율성이다. 컨테이너 환경은 말그대로 하드웨어 자원을   
컨테이너화하여 isolation 하는 기능이 주다. 그에 반해 가상화 환경은   
isolation 기능도 가지고 있지만, 가상화를 통해서 자원,   
특히 CPU의 수를 늘릴 수 있다. 

예를 들어 설명하면, 8 CPU 머신을 쿠버네티스로 관리 운영하면, 8 CPU로 밖에   
사용할 수 없지만, 가상화 환경을 중간에 끼면, 8 CPU를 가상화 해서 2배일 경우   
16 CPU로, 8배일 경우 64 CPU로 가상화 하여 좀 더 자원을 잘게 나눠서 사용이   
가능하기 때문이 아닌가 하는 결론을 내렸다. 

이 이외에도 스토리지 자원의 활용 용이성이나 노드 확장등을 유연하게 할 수 있는 장점이 있다고 한다. 


