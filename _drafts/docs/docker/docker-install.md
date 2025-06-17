# Docker 19.03 Install For CentOS 7.7

작성일 : 19.12.11  
작성자 : 임준범  

1. System Library Update  

	```sh
	#yum update -y  
	```

2. Uninstall old version docker  

	```sh
	#yum remove docker docker-common docker-selinux docker-engine  
	```

3. Add Docker Repository

	```sh
	#yum install -y yum-utils device-mapper-persistent-data lvm2
	#yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
	```

4. Install Docker CE
	a) Lastest Version
		#yum install docker-ce -y
	b) Specific Version
		#yum list docker-ce --showduplicates | sort -r
		#yum install <FULLY-QUALIFIED-PACKAGE-NAM

5. Start Docker
	#systemctl start docker

6. Service Enable
	#systemctl enable docker

7. Docker 환경 설정
	기본 설정 외 추가로 설정을 원하는 경우 /etc/docker/daemon.json 파일을 수정하여 설정한다.
	#vi /etc/docker/daemon.json
	{
		"exec-opts": ["native.cgroupdriver=systemd"
		"log-driver": "json-file
		"log-opts":
				"max-size": "50m
				"max-file": "
		
		"storage-driver": "overlay2
		"storage-opts":
				"overlay2.override_kernel_check=tru
	
	
	
	#systemctl restart docke
	Docker 실행 과정에서 오류가 없다면 다음으로 docker 실행정보를 확인한다.

	#docker in
		Storage Driver: overla
		 Backing Filesystem: x
		 Supports d_type: tr
		 Native Overlay Diff: tr
		Logging Driver: json-fi
		Cgroup Driver: syste
	
	다음과 같은 오류 메시지가 보일 경우 sysctl 의 정보를 수정한다.
	WARNING: bridge-nf-call-iptables is disabl
	WARNING: bridge-nf-call-ip6tables is disabl

	#cat <<EOF >  /etc/sysctl.d/k8s.co
	net.bridge.bridge-nf-call-ip6tables =
	net.bridge.bridge-nf-call-iptables =
	E
	
	#sysctl --system
	#docker info
	
8. Docker 저장소 추가( private registry ( insecure type )
	특정 저장소 접속 시 SSL을 Off 상태로 접속할 수 있도록 /etc/docker/daemon.json 파일에 다음 내용을 추가 한다.
	{
		...
		"insecure-registries":["192.168.102.142:5002"
		...
	}

9.  Change Data File Path
	도커에서 사용하는 데이터 디렉토리를 변경하고자 하는 경우 /etc/docker/daemon.json 파일에 다음과 같이 경로를 설정한다.
	{
		.
		"data-root": "/mnt/docker
		.
	}
	