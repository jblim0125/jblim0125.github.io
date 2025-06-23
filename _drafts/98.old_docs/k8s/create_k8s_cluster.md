# k8s cluster install ( For CentOS 7.7 )

## 1. Requirements(모든 노드)

1. Docker Install 문서의 내용을 참고하여 Docker를 설치 후 다음을 진행한다.  
2. IPVS 설치  
    네트워크 속도 향상을 위해 IPVS를 설치한다.  

	```sh
	#yum install -y ipvsadm  
	#sysctl -w net.ipv4.ip_forward=1  
	```

    재시작 후에도 sysctl이 설정되도록 다음 파일(/etc/sysctl.conf)을 열어 다음 내용을 추가한다.  

    ```sh
    ...
    net.ipv4.ip_forward=1
    ...
    ```
c. 모든 사용자를 위한 환경 변수 등록 ( kube-proxy ipvs 모드 동작 )  
    다음과 같이 /etc/profile.d 디렉토리에 스크립트 파일을 추가한다.   
    ```bash
    #vi /etc/profile.d/ipvs.sh
    ```
    ```
    # /etc/profile.d/ipvs.sh - set kube-proxy ipvs mode
    export KUBE_PROXY_MODE=ipvs
    ```
    ```bash
    #chmod 0755 /etc/profile.d/ipvs.sh
    ```
    재시작 후 환경 변수에 등록이 잘 되었는지 확인한다.  
    
2. Add k8s repository(모든 노드)  
    /etc/yum.repos.d/kubernetes.repo 파일을 vim 편집기를 이용해 다음 내용을 입력하고 저장한다.  
    ```bash
    #vi /etc/yum.repos.d/kubernetes.repo  
    ```
    ```
    [kubernetes]  
    name=Kubernetes  
    baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64  
    enabled=1  
    gpgcheck=1  
    repo_gpgcheck=1  
    gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
    ```

3. selinux disable(모든 노드)  
    만약 selinux 가 켜져 있는 상태일 경우 다음 명령으로 selinux를 disable 상태로 변경한다.  
    ```bash
    #setenforce 0
    ```

4. Install kubelet, kubeadm, kubectl(모든 노드)  
    ```bash
    #yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes  
    ```
    
5. swap off(모든 노드)  
    kubeadm init 명령으로 kubernetes를 설정 시 다음과 같은 에러가 발생한다.  
    ```
    [preflight] Some fatal errors occurred:  
        [ERROR Swap]: running with swap on is not supported. Please disable swap  
    ```
    공식 문서에서는 내용을 확인할 수 없었으나, 
    swap이 활성화된 상태에서 pod의 안정적(성능까지 고려한)인 상태를 보장할 수 없다는 의견이 지배적이다.  
    
    swap은 다음 명령으로 종료할 수 있다.
    ```bash
    #swapoff -a
    ```
    
    재시작 후에도 swap이 동작하지 않도록 하기 위해서는 다음 명령을 실행하여 fstab을 변경한다.  
    swap 이 있는 라인을 주석처리 한다.(주석 : #)  
    ```bash
    #vi /etc/fstab
    ```
    
6. 초기화 설정(마스터 노드)  
    ```bash
    #kubeadm  init --config=init_config.yaml
    ```
    network add-on으로 calico를 사용하는 경우 192.168.0.0/16 대역 기본으로 사용한다.  
    기존 네트워크(장비)와 겹치는 경우 podSubnet, calico의 설정을 변경한다.  
    변경하지 않는 경우 pod - pod, pod - host, pod - svc 등 다양한 네트워크 부분에서 통신이
    불가능한 상태가 발생한다.  
    
    kubeadm 초기화 config 예제  
    ```
    apiVersion: kubeadm.k8s.io/v1beta2
    kind: InitConfiguration
    localAPIEndpoint:
      bindPort: 6443
    nodeRegistration:
      criSocket: /var/run/dockershim.sock
      name: k8s-master
      taints:
      - effect: NoSchedule
        key: node-role.kubernetes.io/master
    ---
    apiVersion: kubeadm.k8s.io/v1beta2
    kind: ClusterConfiguration
    apiServer:
      timeoutForControlPlane: 4m0s
    certificatesDir: /etc/kubernetes/pki
    clusterName: mobigen-k8s-cluster
    controllerManagekuberneter: {}
    dns:
      type: CoreDNS
    etcd:
      local:
        dataDir: /var/lib/etcd
    imageRepository: k8s.gcr.io
    kubernetesVersion: v1.17.0
    networking:
      dnsDomain: cluster.local
      serviceSubnet: 10.96.0.0/16
      podSubnet: 10.100.0.1/16
    scheduler: {}
    ---
    apiVersion: kubeproxy.config.k8s.io/v1alpha1
    kind: KubeProxyConfiguration
    featureGates:
      SupportIPVSProxyMode: true
    mode: ipvs
    ---
    ```

7. 사용자 CLI 환경에서 kubernetes를 사용하기 위한 파일 복사(마스터 노드)  
    ```bash
    #mkdir -p $HOME/.kube
    #cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    #chown $(id -u):$(id -g) $HOME/.kube/config
    ```

8. Install Network add-on(마스터 노드)  
    Kubernetes 환경에서 Pod들이 통신하려면 pod network add-on이 있어야 합니다. 
    pod network add-on이 설치되기 전에는 CoreDNS가 시작되지 않습니다. 
    'kubeadm init' 이후에 'kubectl get pods -A' 명령어로 확인해보면 
    CoreDNS가 아직 시작되지 않은 상태를 확인할 수 있습니다. 
    ```bash
    #kubectl get pods -A
    NAMESPACE     NAME                                 READY   STATUS    RESTARTS   AGE
    kube-system   coredns-6955765f44-hh7dz             0/1     Pending   0          6m3s
    kube-system   coredns-6955765f44-qm76w             0/1     Pending   0          6m3s
    kube-system   etcd-k8s-master                      1/1     Running   0          6m6s
    kube-system   kube-apiserver-k8s-master            1/1     Running   0          6m6s
    kube-system   kube-controller-manager-k8s-master   1/1     Running   0          6m6s
    kube-system   kube-proxy-mw56z                     1/1     Running   0          6m3s
    kube-system   kube-scheduler-k8s-master            1/1     Running   0          6m6s
    ```

    다양한 Network add-on 중 Calico 설치를 진행한다.( v3.10 )
    위 kubeadm init 과정에서 설정한 podSubnet 을 calico에도 설정해 주어야 한다.  
    ```bash
    #wget https://docs.projectcalico.org/v3.10/manifests/calico.yaml
    #kubectl create -f calico.yaml
    ```
    
    설치가 완료된 후 CoreDNS를 포함한 Pod들의 상태를 확인하면 모두 running 상태가 된 것을 확인할 수 있다.  
    ```bash
    # kubectl get pod -A
    NAMESPACE     NAME                                       READY   STATUS    RESTARTS   AGE
    kube-system   calico-kube-controllers-74c9747c46-vj9wv   1/1     Running   0          52s
    kube-system   calico-node-jtlf4                          1/1     Running   0          52s
    kube-system   coredns-6955765f44-hh7dz                   1/1     Running   0          15m
    kube-system   coredns-6955765f44-qm76w                   1/1     Running   0          15m
    kube-system   etcd-k8s-master                            1/1     Running   0          15m
    kube-system   kube-apiserver-k8s-master                  1/1     Running   0          15m
    kube-system   kube-controller-manager-k8s-master         1/1     Running   0          15m
    kube-system   kube-proxy-mw56z                           1/1     Running   0          15m
    kube-system   kube-scheduler-k8s-master                  1/1     Running   0          15m
    ```

9. 마스터에 Node를 추가하여 클러스터 구성(Node)  
    마스터 노드에서 kubeadm init 과정에서 다음과 같은 출력을 확인할 수 있다.  
    ```
    Your Kubernetes control-plane has initialized successfully!

    To start using your cluster, you need to run the following as a regular user:

      mkdir -p $HOME/.kube
      sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
      sudo chown $(id -u):$(id -g) $HOME/.kube/config

    You should now deploy a pod network to the cluster.
    Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
      https://kubernetes.io/docs/concepts/cluster-administration/addons/

    Then you can join any number of worker nodes by running the following on each as root:

    kubeadm join 192.168.50.67:6443 --token 2twzbc.d4xkeaw849dws8nq \
        --discovery-token-ca-cert-hash sha256:6fee696b5085b1a3e89b3a33310011974271ba731c6022b87b7571b4bb15978b 
    ```
    위 내용 중 kubeadm join 부분을 복사하여 각 노드에서 실행한다.  
    ```bash
    #kubeadm join 192.168.50.67:6443 --token 2twzbc.d4xkeaw849dws8nq \
        --discovery-token-ca-cert-hash sha256:6fee696b5085b1a3e89b3a33310011974271ba731c6022b87b7571b4bb15978b
    ```

10. Node 상태 확인(마스터 노드)  
    ```bash
    #kubectl get node
    ```

11. 각 노드에서 kubectl 명령 사용 방법  
    노드에서는 /etc/kubernetes/admin.conf 파일이 존재하지 않는다.  
    따라서 마스터 노드에서 복사하여 사용해야 한다.  
    명령을 사용할 수 있도록 허용할 사용자 디렉토리에 .kube 디렉토리를 생성하고 마스터 노드에서 파일을 복사한다.  

    !주의 : user_name 부분은 변경 필요!!!
    ```bash
    #mkdir -p $HOME/.kube
    #scp master:/user_name/.kube/config $HOME/.kube/config
    ```

12. 자동 완성 활성화  
    ```bash
    #yum install bash-completion -y
    #echo "source <(kubectl completion bash)" >> ~/.bashrc
    ```

