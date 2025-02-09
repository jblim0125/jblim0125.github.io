---
layout: post
title: iptable을 이용한 포트포워딩
author: jblim0125
date: 2024-08-25
category: 2024
---

## 포트포워딩

Linux의 iptable을 이용해 포트 포워딩을 설정하는 방법은 다음과 같습니다.  
이 과정에서는 NAT(Network Address Translation) 기능을 사용하여 특정 포트로 들어오는 트래픽을 다른 IP 주소와 포트로 전달합니다.  

예를 들어, 외부에서 서버의 8080 포트로 들어오는 트래픽을 내부 네트워크의 192.168.1.100 서버의 80 포트로 포워딩한다고 가정하겠습니다.

### 1. 기본 전제

- **서버의 외부 IP 주소:** `192.168.1.120`
- **내부 네트워크의 서버 IP 주소:** `192.168.1.100`
- **외부에서 접근할 포트:** `8080`
- **내부 서버에서 서비스할 포트:** `80`

### 2. 포트 포워딩 설정

#### 2.1 IP 포워딩 활성화

포트 포워딩을 설정하기 전에, Linux 커널에서 IP 포워딩을 활성화해야 합니다.

```bash
echo 1 > /proc/sys/net/ipv4/ip_forward
```

또는 영구적으로 설정하려면 `/etc/sysctl.conf` 파일을 편집하여 다음 라인을 추가하거나 주석을 해제합니다.

```bash
net.ipv4.ip_forward = 1
```

그리고 다음 명령어로 적용합니다.

```bash
sysctl -p
```

#### 2.2 IPTables 규칙 추가

이제 IPTables를 사용하여 포트 포워딩 규칙을 추가할 수 있습니다.

```bash
# 외부에서 8080 포트로 들어오는 트래픽을 192.168.1.100의 80 포트로 포워딩
iptables -t nat -A PREROUTING -p tcp --dport 8080 -j DNAT --to-destination 192.168.1.100:80

# 포워딩된 패킷이 서버에서 정상적으로 응답할 수 있도록 MASQUERADE 설정
iptables -t nat -A POSTROUTING -j MASQUERADE
```

위의 명령어들은 다음을 수행합니다:

- `-t nat -A PREROUTING`: NAT 테이블의 PREROUTING 체인에 규칙을 추가합니다. 이 체인은 패킷이 목적지에 도달하기 전에 처리됩니다.
- `-p tcp --dport 8080`: 프로토콜이 TCP이며, 목적지 포트가 8080인 패킷을 선택합니다.
- `-j DNAT --to-destination 192.168.1.100:80`: 선택된 패킷의 목적지 IP 주소와 포트를 192.168.1.100의 80 포트로 변경합니다.
- `-t nat -A POSTROUTING -j MASQUERADE`: 패킷이 NAT 후에 외부 네트워크로 나갈 때, 출발지 주소를 포워딩 규칙에 맞게 변경하여 응답 패킷이 다시 원래 서버로 돌아올 수 있도록 합니다.

### 3. 규칙 저장

이 규칙은 시스템을 재부팅하면 사라지기 때문에, 설정을 영구적으로 유지하려면 다음과 같이 규칙을 저장합니다.

- **Ubuntu/Debian:**

  ```bash
  apt-get install iptables-persistent
  netfilter-persistent save
  ```

- **CentOS/RHEL:**

  ```bash
  service iptables save
  ```

### 4. 포트 포워딩 테스트

포트 포워딩이 올바르게 설정되었는지 테스트하려면 외부 네트워크에서 `192.168.1.120:8080`에 접속하여 `192.168.1.100:80`에 연결되는지 확인합니다.
