Kubernetes - Service
==

### Service Yaml  
다음은 여러개의 Port를 서비스하는 서비스 yaml 파일 예시이다.  
```
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  selector:
    app: MyApp
  ports:
    - name: http
      protocol: TCP
      port: 80
      targetPort: 9376
    - name: https
      protocol: TCP
      port: 443
      targetPort: 9377
```

### Discovering services  
2가지 방법으로 서비스 검색 가능
Environment variables, DNS  환경 변수는 기본으로 제공되고, DNS는 DNS를 활성화해야 가능하다.   

- Environment variables  
	아래와 같은 형태로 다른 서비스 정보를 POD 내부에서 확인이 가능하다.  
	{SVC_NAME}_SERVICE_HOST  
	{SVC_NAME}_SERVICE_PORT  

	다음은 직접 확인한 결과  
	```
	# kubectl exec -it jhms-7f776fb847-jh92q -n iris -- /bin/bash
	# printenv | grep SERVICE
	# printenv | grep -i SERVICE
	DATA_TRANS_SERVICE_SVC_PORT_5002_TCP_ADDR=10.110.74.23
	DASHBOARD_SVC_SERVICE_HOST=10.108.18.81
	DATA_TRANS_SERVICE_SVC_PORT_5002_TCP=tcp://10.110.74.23:5002
	BRICK_SVC_SERVICE_PORT=80
	DATA_TRANS_SERVICE_SVC_PORT_5002_TCP_PROTO=tcp
	STUDIO_SVC_SERVICE_PORT=8080
	BRICK_SVC_SERVICE_HOST=10.103.199.200
	CLUSTER_SVC_SERVICE_HOST=10.110.235.37
	KUBERNETES_SERVICE_PORT=443
	KUBERNETES_SERVICE_HOST=10.96.0.1
	HDFS_BROWSER_SVC_SERVICE_HOST=10.103.133.63
	IRIS_HIVE_SVC_SERVICE_PORT=10017
	```

- DNS  
	DNS를 활성화 한 경우 POD에서 모든 서비스를 검색할 수 있다.  
	
    예시 > 서비스 이름(name) : my-service, 네임스페이스 이름(name) : my-ns  
	동일 네임스페이스의 Pod Service : my-service  
	다른 네임스페이스의 Pod Service : my-service.my-ns  
	
    DNS SRV 기능( 서비스의 포트 정보 획득 가능 )을 제공  
    
    예시 >   
    서비스 이름(name) : my-service, 네임스페이스 이름(name) : my-ns 
    포트 이름 : http, 프로토콜 : TCP  
    
    아래와 같이 DNS 쿼리 시 조회 가능  
	```
	_http._tcp.my-service.my-ns  
	```

### Headless Services  
잘 모르겠음...  

### Publishing Services ( Service Types )  
클러스터 내부의 Pod으로 외부에서 접근할 수 있도록 다양한 방법을 제공한다.  
Cluster IP, NodePort, LoadBalancer, ExternalName  

- Cluster IP  
    서비스 기본 타입으로 클러스터 내부에서만 접근이 가능  
- NodePort  
    모든 노드의 IP를 통해서 외부에서 접근 가능  
    예 > Pod이 Node01에서 동작 중이고 NodePort 타입의 서비스를 생성   
    실제 Node02에서 Pod이 실행 중이라도 아래와 같이 접근 가능하다.  
    
		Client -- Node01 -- Pod, Client -- Node02 -- Pod  

- LoadBalancer  
    
- ExternalName   


