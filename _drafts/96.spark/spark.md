# Spark Standalone 이미지 빌드  

## 기본 이미지와 라이브러리  
기본 이미지는 Spark on Iris 라이브러리가 포함된 이미지이다.  
Spark on Iris에 라이브러리를 추가하는 방법은 다음과 같다.    

1. 기존 라이브러리 다운로드  
   기존 이미지에 존재하는 라이브러리와 통합을 위해 컨테이너 내부에서 
   호스트로 복사한다.  
	```bash
	# mkdir base && cp Dockerfile.base base
	# cd base
	# docker pull repo.iris.tools/iris/spark-standalone-base:latest
	# docker run -itd --name spark-base repo.iris.tools/iris/spark-standalone-base:latest
	# docker cp spark-base:/mobigen .
	# ls -al
	total 8
	drwxr-xr-x   4 root root   62 Jun 23 08:37 .
	dr-xr-x---. 13 root root 4096 Jun 23 08:49 ..
	-rw-r--r--   1 root root 1001 Jun 22 13:43 Dockerfile.base
	drwxr-xr-x   3 root root   19 Jan 28 14:46 mobigen
	# tree mobigen
	mobigen
	└── tools
		└── Spark-on-IRIS
			└── lib
				├── java
				│   ├── aws-java-sdk-1.11.649.jar
				│   ├── elasticsearch-hadoop-7.4.0.jar
				│   ├── hadoop-aws-2.7.3-amzn-2-6.0.0.jar
				│   ├── iijdbc-10.0-4.0.5.jar
				│   ├── iris-spark-datasource-1.0-spark-2.1.0_2.11-bin.jar
				│   ├── iris-spark-datasource-1.6-spark-2.4.4_2.11-bin.jar
				│   ├── mobigen-iris-jdbc-1.6.0.4.jar
				│   ├── mobigen-iris-jdbc-2.1.0.1.jar
				│   ├── mongo-java-driver-3.8.0.jar
				│   ├── mongo-spark-connector_2.11-2.3.1.jar
				│   ├── mysql-connector-java-5.0.8.jar
				│   ├── mysql-connector-java-8.0.16.jar
				│   ├── ojdbc6.jar
				│   ├── postgresql-42.2.8.jar
				│   ├── scalaj-http_2.11-2.3.0.jar
				│   ├── spark-datasource-rest_2.11-2.1.0-SNAPSHOT.jar
				│   ├── sqlite-jdbc-3.13.0.jar
				│   ├── sqlite-jdbc-3.23.1.jar
				│   └── tibero6-jdbc.jar
				└── python
					├── irisspark.zip
					├── m6rpc.zip
					└── M6.zip

	5 directories, 22 files
	```
	추가하고자 하는 라이브러리를 원하는 위치에 추가한다.  

2. 이미지 빌드  
	```bash
	# docker build . -f Dockerfile.base -t repo.iris.tools/iris/spark-standalone-base:latest
	```

## 기본 이미지를 바탕으로 임시 빌드 이미지 생성  
임시 이미지는 spark 설정, python3.6 등의 설치가 진행된다.  
1. 이미지 빌드  
    ```bash
    # docker build . -f Dockerfile.tmp -t repo.iris.tools/iris/spark-standalone-tmp:latest
    ```

## 최종 이미지 생성  

1. Dockerfile  
    임시 이미지에 추가로 설치할 패키지를 위해 스크립트를 실행하고 최종적으로 spark을 실행하는 스크립트가 있다.  
	```bash
	FROM repo.iris.tools/iris/spark-standalone-tmp:latest
	COPY modules/mobigen/install-additional-pkg.sh /tmp/install-additional-pkg.sh
	RUN /tmp/install-additional-pkg.sh && rm -rf /tmp/install-additional-pkg.sh
	USER 185

	WORKDIR /tmp
	ENTRYPOINT ["/entrypoint"]
	CMD ["/launch.sh"]
	```

2. 이미지 빌드  
	```bash
	# docker build . -f Dockerfile -t repo.iris.tools/iris/spark-standalone:[tag]
	```