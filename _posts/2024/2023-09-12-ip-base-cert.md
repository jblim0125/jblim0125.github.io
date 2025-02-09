---
layout: post
title: IP 기반 사설 인증서 생성 방법
author: jblim0125
date: 2023-09-12
category: 2023
---

인증서에 필요한 정보 설정 파일 `csr.conf`, `cert.conf` 2개를 작성  
파일 내 `192.168.0.100` 를 인증서를 사용할 서버의 IP 주소로 변경  

1. 파일명 : `csr.conf`  

    ```text
    [ req ]
    default_bits = 2048
    prompt = no
    default_md = sha256
    req_extensions = req_ext
    distinguished_name = dn

    [ dn ]
    C = KR
    ST = Seoul
    L = SongPa
    O = Mobigen
    OU = Dev
    CN = 192.168.0.100

    [ req_ext ]
    basicConstraints = CA:TRUE
    subjectAltName = @alt_names

    [ alt_names ]
    IP.1 = 192.168.0.100
    ```

2. 파일명 : `cert.conf`  

    ```text
    authorityKeyIdentifier=keyid,issuer
    basicConstraints=CA:FALSE
    keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
    subjectAltName = @alt_names

    [alt_names]
    IP.1 = 192.168.0.100
    ```

3. openssl 명령을 이용해 인증서 생성  

    ```shell
    ## 암호키와 루트 인증서 생성 
    $ openssl genrsa -aes256 -out rootca.key 2048
    $ openssl rsa -in rootca.key  -out rootca_dec.key
    $ openssl req -x509 -sha256 -days 356 -nodes -newkey rsa:2048 -subj "/CN=mobigen.com/C=KR/L=Seoul" -keyout rootCA.key -out rootCA.crt 

    ## 서버키와 서버 인증서 생성  
    $ openssl genrsa -out server.key 2048
    $ openssl req -new -key server.key -out server.csr -config csr.conf
    $ openssl x509 -req -in server.csr -CA rootCA.crt -CAkey rootCA.key -CAcreateserial -out server.crt -days 365 -sha256 -extfile cert.conf
    ## 루트 인증서와 서버 인증서를 묶어 풀체인 인증서를 생성  
    $ cat server.crt rootCA.crt > chain.crt
    ```
