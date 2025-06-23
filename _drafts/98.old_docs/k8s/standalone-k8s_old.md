# Standalone Kubernetes

1. swap off
	스왑 메모리가 설정되어 있는 경우 쿠버네티스가 동작하지 않는다.   
	```bash
	# swapoff -a
	# sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
	```    
2. SELinux disable  
	```bash
	# setenforce 0
	# sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
	```
3. nfs util 설치   
	외부 데이터 저장소 연결 시 NFS 이용한다. NFS 패키지를 설치한다.
	```bash
	# yum install nfs-utils nfs-utils-lib
	```
4. Install Docker  
    이전 버전 관련 패키지 삭제  
    ```bash
	# yum remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
    ```

	필요한 패키지 설치.   
    ```bash
	# yum install -y yum-utils device-mapper-persistent-data lvm2
    ```
	Docker 리포지터리 추가    
    ```bash
    # yum install -y yum-utils
	# yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
	```
	Docker 설치.   
    ```bash
	# yum update -y && yum install -y docker-ce docker-ce-cli containerd.io
	```

	/etc/docker 디렉터리 생성.    
    ```bash
	# mkdir /etc/docker
    ```

	데몬 설정.  
    ```bash
	# cat > /etc/docker/daemon.json <<EOF
	{
	  "exec-opts": ["native.cgroupdriver=systemd"],
	  "log-driver": "json-file",
	  "log-opts": {
		"max-size": "100m"
	  },
	  "storage-driver": "overlay2",
	  "storage-opts": [
		"overlay2.override_kernel_check=true"
	  ]
	}
	EOF
	# mkdir -p /etc/systemd/system/docker.service.d
    ```

	Docker 재시작.    
    ```bash
	# systemctl daemon-reload
	# systemctl restart docker
    ```

2. kubelet, kubeadm, kubectl 설치  
    kubernetes 저장소 추가   
    ```bash
	# cat <<EOF > /etc/yum.repos.d/kubernetes.repo
	[kubernetes]
	name=Kubernetes
	baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
	enabled=1
	gpgcheck=1
	repo_gpgcheck=1
	gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
	exclude=kubelet kubeadm kubectl
	EOF
    ```

    kubelet, kubeadm kubectl 설치  
    ```bash
    # yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
    ```

    kubelet 동작  
    ```bash
    # systemctl daemon-reload
    # systemctl enable kubelet
    # systemctl start kubelet
    ```

 3. kubeadm init  
	```bash
	# kubeadm init
	```
	위 명령 실행 결과 중 다음 내용들을 실행한다.  
	```bash
	# mkdir -p $HOME/.kube
	# cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
	# chown $(id -u):$(id -g) $HOME/.kube/config
	```

4. install add-on(Network)  
    ```bash
    # kubectl apply -f https://docs.projectcalico.org/v3.14/manifests/calico.yaml
    ```

5. 마스터 노드의 정책 변경  
    쿠버네티스는 기본적으로 마스터(컨트롤러)에 pod이 실행되지 않는다.  
    그러나 하나의 머신으로 환경을 구성하기 위해 다음 명령으로 
    마스터에서도 POD이 실행될 수 있도록 한다.
    ```bash
    # kubectl taint nodes --all node-role.kubernetes.io/master-
    ```
	
6. Helm Install  
	```bash
	# yum install -y wget
	# wget https://get.helm.sh/helm-v3.2.1-linux-amd64.tar.gz
	# tar xvf helm-v3.2.1-linux-amd64.tar.gz
	# mv linux-amd64/helm /usr/local/bin/helm
	# helm version
	```
    
6. 확인  
    ```bash
	# kubectl get node
	NAME         STATUS   ROLES    AGE     VERSION
	single-k8s   Ready    master   3d23h   v1.18.3
	
	# kubectl get pod -A
	NAMESPACE        NAME                                                    READY   STATUS    RESTARTS   AGE
    kube-system      calico-kube-controllers-789f6df884-2h8fk                1/1     Running   0          3d23h
	kube-system      calico-node-pvwkh                                       1/1     Running   0          3d23h
	kube-system      coredns-66bff467f8-tbgrl                                1/1     Running   0          3d23h
	kube-system      coredns-66bff467f8-tg2fr                                1/1     Running   0          3d23h
	kube-system      etcd-single-k8s                                         1/1     Running   0          3d23h
	kube-system      kube-apiserver-single-k8s                               1/1     Running   0          3d23h
	kube-system      kube-controller-manager-single-k8s                      1/1     Running   0          3d23h
	kube-system      kube-proxy-kdnwj                                        1/1     Running   0          3d23h
	kube-system      kube-scheduler-single-k8s                               1/1     Running   0          3d23h
   ```