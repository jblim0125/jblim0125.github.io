# How to enable docker remote access  

dockerd의 실행 인자 값 변경이 필요하다. systemd에 의해 실행되므로 /lib/systemd/system/docker.service 파일을 수정한다.  
ExecStart에 dockerd 인자 값으로 -H와 원하는 IP와 Port 정보를 입력한다. 
다수의 IP or Port로 Listen하길 원하는 경우 -H와 함께 추가한다.  
2375 : 암호화되지 않은(보안 X) 연결  
2376 : 암호화된 연결  

```bash
# vi /lib/systemd/system/docker.service
----------before
[Service]
Type=notify
ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
----------after
[Service]
Type=notify
ExecStart=/usr/bin/dockerd -H fd:// -H tcp://0.0.0.0:2375 --containerd=/run/containerd/containerd.sock
```

데몬 리로드와 docker 재시작하여 tcp listen 상태로 추가되었는지 확인한다.

```bash
# systemctl daemon-reload
# systemctl restart docker
# netstat -natp | grep dockerd
# netstat -natp | grep docker
tcp6       0      0 :::2375                 :::*                    LISTEN      30304/dockerd 
```
