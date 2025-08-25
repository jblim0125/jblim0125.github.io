R Studio Pkg 설치 
=

## 1. R Studio 다운로드

192.168.100.116 ( root / hello.mobigen )  
path : /root/b-iris-dist/kotra  
filename : rstudio-dist-1.1.463-a37ab83-20190721.tar.gz  

## 2. R Studio 압축 해제
    #tar xzf rstudio-dist-1.1.463-a37ab83-20190721.tar.gz
압축 해제 시 service 디렉토리를 확인할 수 있음  
최초 압축 해제 시 하위 디렉토리는 다음과 같은 구조를 가지고 있습니다.  
(디렉토리는 다를 수 있습니다.)
    bin  conf-template  images  install  logs  save

주요 디렉토리는 다음과 같습니다.
- `bin`: 각 서비스의 실행 파일이 존재
- `conf-template`: conf
- `save`: 각 서비스에서 외부에 저장되는 데이터가 저장

## 3. R Studio 실행을 위한 파일 획득 
현재 동작 중인 180 서버에 접속하여 common 디렉토리, network.conf 파일 다운로드한다.
압축을 해제 후 service 디렉토리를 확인할 수 있다.
디렉토리(service)에서 다음 명령 실행 
```
#sftp 192.168.100.180
( root / hello.root )
#cd /root/b-iris/normal/service
#get -r common
#get conf-template/network.conf
#exit
```
    
## 4. R Studio install
install 스크립트를 실행한다.
    #./install/rstudio-install.sh
스크립트 동작 설명
- docker에서 rstudio container 를 중지 및 삭제
- docker에서 rstudio image를 삭제
- docker에 패키지 내 rstudio 이미지를 적재
- 실행에 필요한 config 파일들을 복사( conf-templete => conf )

스크립트 실행이 완료되면 아래와 같이 docker 명령어로 이미지가 로그된 것을 확인할 수 
있다.
    #docker images
    REPOSITORY            TAG                 IMAGE ID            CREATED             SIZE
	mobigen.com/rstudio   1.1.463-a37ab83     446b6a36954c        4 weeks ago         3.89GB
	mobigen.com/rstudio   latest              446b6a36954c        4 weeks ago         3.89GB

이전 단계에서 획득한 network.conf 파일을 conf 디렉토리로 복사한다.
    #mv network.conf conf-template

## 5. R Studio 실행

```
#./bin/rstudio-docker.sh start
```

스크립트 실행 시 아래와 같이 R Studio 컨테이너가 실행된 것을 확인할 수 있다.

```
# docker ps
CONTAINER ID        IMAGE                        COMMAND             CREATED             STATUS              PORTS               NAMES
13f6f3df51eb        mobigen.com/rstudio:latest   "/usr/sbin/init"    About an hour ago   Up About an hour                        rstudio

```
웹브라우저를 이용한 확인은 다음과 같이 R Studio를 실행한 서버 아이피 + 8787 port로 접속 시 확인할 수 있다.
```
http://아이피:8484
```

## 6. R Studio 접속 

    #docker exec -it rstudio /bin/bash
정상적으로 들어갈 경우 아래와 같이 프롬프트가 / 로 변경 됩니다.
	[root@test service]# docker exec -it rstudio /bin/bash
	[root@test /]#

## 7. Locale 오류 수정

Docker file에는 설정되어 있으나 터미널로 R Studio 내부 접속 시 아래와 같은 오류가 발생한다.
	# docker exec -it rstudio /bin/bash
	bash: warning: setlocale: LC_ALL: cannot change locale (ko_KR.UTF-8)
	/bin/sh: warning: setlocale: LC_ALL: cannot change locale (ko_KR.UTF-8)

localedef 명령을 이용해 ko_KR.UTF-8 을 추가한다.
	# localedef -f UTF-8 -i ko_KR ko_KR.UTF-8

## 8. GCC 버전 업그레이드

CentOS 7.6( Kernel 3.10 ) 이미지의 GCC 버전은 4.8.5로 C++ 11을 지원하고, C++14를 지원하지 않는다. 따라서 C++14를 
이용하는 패키지(ex : rstan, prophet, streamR 등 ) 설치를 위해서 보다 상위 버전의 GCC가 필요하다.
이 문서에서는 GCC 4.9.4 버전을 설치하고 설정한다.

*모든 과정은 컨테이너 내부에서의 과정이다.*

- bzip2 설치  
  prerequisites pkg 설치를 진행하기 위해 bzip2가 설치되어 있지 않다면 설치를 진행한다.
        # yum install bzip2   

- 소스 다운로드  
  다른 버전을 사용하기 원한다면 gcc 오피셜 사이트에서 원하는 소스를 다운 받고 다음 과정을 그에 맞게 진행하면 된다.
        #wget http://ftp.tsukuba.wide.ad.jp/software/gcc/releases/gcc-4.9.4/gcc-4.9.4.tar.gz

- 압축 해제  
        # tar xf gcc-4.9.4.tar.gz
        # ls
        gcc-4.9.4

- prerequisites 실행  
        # ./gcc-4.9.4/contrib/download_prerequisites

- 빌드 디렉토리를 외부에 설정  
  소스 코드와 빌드한 파일을 분리하여 관리하기 위해 빌드 디렉토리를 외부에 설정
        # mkdir gcc-build
  디렉토리는 다음과 같다.
        # ls
        gcc-build   gcc-4.9.4
  빌드 디렉토리로 이동한다.
        # cd gcc-build
  
- prefix 설정  
  R studio에 마운트되는 공용 라이브러리 디렉토리에 GCC 4.9.4 가 설치 될 수 있도록 설정한다.
        # ../gcc-4.9.4/configure --prefix /lib64/R/library/gcc-4.9.4 --enable-languages=c,c++ --disable-multilib

- 빌드  
  -j 옵션 뒤의 숫자는 병렬 컴파일을 수행할 CPU의 수 이다. 빌드하는 시스템의 CPU에 맞게 조절한다.
        # make -j 4 

- 설치
        # make install
        # ls /lib64/R/library/gcc-4.9.4
        bin  include  lib  lib64  libexec  share


- R config 설정  
  기존에 사용되던 GCC가 아닌 GCC-4.9.4 사용을 위해 다음의 config 파일들을 수정한다.  
        
        # cd /lib64/R/etc/

    - ldpaths  
            # vi ldpaths

			# For GCC_4.9.4
			: ${GCC_4_9_4_LD_LIBRARY_PATH=/lib64/R/library/gcc-4.9.4/lib64}
			...
			if test -n "${GCC_4_9_4_LD_LIBRARY_PATH}"; then
			  R_LD_LIBRARY_PATH="${R_LD_LIBRARY_PATH}:${GCC_4_9_4_LD_LIBRARY_PATH}"
			fi
			...
            
    - Makeconf 
            
			CXX14 = /lib64/R/library/gcc-4.9.4/bin/g++ -m64
			CXX14FLAGS =  $(LTO) -std=gnu++14 -fPIC -O2 -g
			CXX14PICFLAGS =
			CXX14STD = -std=gnu++14
  
## 9. R Pkg 설치

Command 를 이용한 패키지 설치  
---
R 실행
	# R

설치된 패키지 확인
	> installed.packeage( )

하나의 패키지 설치
	> install.packages( "pkg name", dependencies=TRUE )

여러개의 패키지 설치
	> install.packages( c("pkg name 1", "pkg name 2", "pkg name 3"), dependencies=TRUE )

설치가 완료되면 아래 명령들을 이용해 확인한다.  
	설치된 패키지 리스트
	> installed.packages()
	
	패키지 로드 
	> library( pkg name )
 
패키지 로드에 실패할 경우 아래와 같은 에러 메시지가 발생한다.
	Error in library(pkg name) : there is no package called 'pkg name'

R Studio에 설치된 패키지는 컨테이너에 마운트된 디렉토리에 설치되며, 
이 디렉토리는 save/rstudio 디렉토리에서 확인이 가능하다.  
디렉토리를 이동하여 find 명령을 이용해 확인한다.
	# cd save/rstudio
    검색하고자 하는 pkg name과 '*'을 이용해 검색한다.
    
    하나의 패키지만 검색하는 경우
	# find . -name "pkg name*"
    
    여러개의 패키지를 검색하는 경우 ( -o 옵션을 이용 )
	# find . -name "pkg1*" -o -name "pkg2*" 

Github ISSUE.md 패키지 설치
--
참고 : 
116 서버에서 다운로드한 배포판의 경우 GitHub ISSUE에 포함된 패키지를 찾을 수 없어 설치를 진행하였다.  

    install.packages(c("rJava", "RJDBC", "Rcpp", "RJSONIO", "bitops", "digest", 
"functional", "stringr", "plyr", "reshape2", "dplyr", "R.methodsS3", "caTools", "Hmisc", 
"memoise", "rjson", "stringi", "ggplot2", "Metrics", "bit", "bit64", 
"extrafont", "devtools", "rPython", "sqldf"))

콘솔에서 rJava 설치 시 오류가 발생하므로 웹 상에서 설치를 진행한다.  
( R CMD javareconf 명령을 이용해 설정이 가능하나 웹 환경과 콘솔 간 변수 혼용을 방지하기 위함 )  

에러 메시지 일부
    Unable to run a simple JNI program.....

환경 변수를 확인하고, 없는 경우 추가한다.  
	# rhdfs 설치시 필요. 해당 경로에 hadoop이 없어도 변수가 선언되어 있어야 패키지가 정상 설치된다.  
	# SEE: https://github.com/RevolutionAnalytics/RHadoop/wiki/user-rhdfs-Home  
	Sys.setenv(HADOOP_CMD = '/docker/tools/hadoop/bin/hadoop')  
	# rhbase 설치시 필요. thrift 관련  
	Sys.setenv(PKG_CONFIG_PATH = '/usr/lib64/pkgconfig:/usr/share/pkgconfig:/usr/local/lib/pkgconfig')  

다운로드 패키지의 설치  
	# 각 tar.gz 파일을 웹에서 다운로드(or wget)하고 <path>부분을 수정해줘야 한다.
	# 다운로드 위치: https://github.com/RevolutionAnalytics/RHadoop/wiki/Downloads
	# ex) 압축 해제한 폴더의 service/lib/rstudio 위치에 파일을 다운로드하고, <path>를 '/mount/lib/rstudio'로 수정

	install.packages("<path>/ravro_1.0.4.tar.gz", repos=NULL, type="source") # dep bit, bit64
	install.packages("<path>/rmr2_3.3.1.tar.gz", repos=NULL, type="source")
	install.packages("<path>/plyrmr_0.6.0.tar.gz", repos=NULL, type="source") # dep rmr2
	install.packages("<path>/rhdfs_1.0.8.tar.gz", repos=NULL, type="source")
	install.packages("<path>/rhbase_1.2.1.tar.gz", repos=NULL, type="source") # dep thrift (env PKG_CONFIG_PATH)

Pkg 설치 리스트
--

	ada, arules, arulesSequences, arulesViz, base64enc,
	ca, caret, caretEnsmble, class, clValid, corrgram,
	corrplot, data.table, dbscan, devtools, DiagrammeR, DMwR,
	doMC, doParallel, dplyr, DT, e1071, earth,
	ElemStatLearn, ellipse, extrafont, fmsb, FNN, forecast,
	FSelector, GA, gbm, gcookbook, GGally, ggExtra,
	ggplot2, ggvis, glmnet, gmodels, h2o, httr,
	igraph, IsolationForest, kknn, klaR, knit,
	kohonen, KoNLP, LDAvis, lime, lmtest, lubridate,
	markdown, MASS, Metrics, mxnet, NbClust, network,
	neuralnet, NLP4kec, nnet, openNLP, party, plotly,
	plotrix, png, pROC, prophet, proxy, psych,
	qcc, randomForest, rattle, RColorBrewer, RCurl, readr,
	readxl, recommenderlab, reshape2, rgl, rio, rJava,
	rjson, rmarkdown, ROAuth, ROCR, rpart, rpart.plot,
	rvest, RWeka, scatterplot3d, servr, slam, sna,
	streamR, stringi, tidyr, tidyverse, tm,
	topicmodels, treemap, tseries, tsne, twitteR,
	wordcloud, wordcloud2, wordVectors, xgboost, XML,
	

## 설치 에러 처리
다음은 패키지 설치에서 오류가 발생하는 경우 대처 방법이다.  
설치 오류가 발생한 패키지 이름으로 검색하여 확인한다.  

### 외부 라이브러리 설치

특정 패키지의 경우 외부 라이브러리가 필요하다.  

- sqldf  
yum install 명령을 이용해 다음을 설치한다.
        # yum install postgresql-devel -y
        

### Github, 외부 Repo를 이용한 설치

 github로부터 패키지를 다운 받아 설치 할 수 있도록 githubinstall 패키지를 설치한다.  
- githubinstall pkg 설치
        > install.packages("githubinstall", dependencies=TRUE)

- IsolationForest
        > install.packages("IsolationForest", repos="http://R-Forge.R-project.org")

- NLP4kec
        > library("githubinstall")
        > githubinstall("NLP4kec")

- wordVectors
        > library("githubinstall")
        > githubinstall("wordVectors")

- vctrs
        > library("githubinstall")
        > install.package("vctrs")

### 검색할 수 없는 패키지  
R repo, github에서 동일한 이름을 찾을 수 없는 패키지 리스트 
- knit  
- caretEnsmble => caretEnsemble  
- translations  
- mxnet  


## 10. Docker 이미지 만들기

1) 컨테이너 내부에서 종료
    # shutdown -h now

2) 컨테이너로 부터 이미지 생성  

  cmd : docker commit [options] <container id or name> [image name:[:tag name]]  
	# docker ps -a
	  CONTAINER ID        IMAGE                        COMMAND             CREATED             STATUS              PORTS               NAMES
	  0717b37d6e77        mobigen.com/rstudio:latest   "/usr/sbin/init"    45 minutes ago      Up 45 minutes                           rstudio
	
    # docker commit 0717b37d6e77 mobigen.com/rstudio:latest

3) Container 종료  

  생성한 이미지를 이용해 Web상에서 테스트를 진행하기 위해  
  컨테이너를 완전히 종료 시키고 생성한 이미지를 실행한다.
	#docker rm rstudio 
	#docker ps -a

4) R Studio 재 실행
  상위 단락의 R Studio 실행을 참고

## 11. 테스트

Web 브라우저를 이용해 R Studio가 실행된 서버 IP:8787로 접속한다.  
ID : app, PW : hello.app

다음 명령을 이용해 설치된 패키지를 확인한다.
    > installed.packages()
실제 패키지를 로드하여 확인한다.
    > library( "pkg name" )

## 12. 이미지, 패키지 저장

테스트를 완료하였다면 Image를 tar 파일로 저장한다.  
    #docker save mobigen.com/rstudio:latest -o rstudio_base_images.tar.gz

설치한 패키지가 포함 될 수 있도록 save 디렉토리의 rstudio_common_lib를 압축한다.
    # cd save/rstudio/
    # tar czf rstudio_common_lib.tar.gz rstudio_common_lib


## R-Studio CUDA Example code 
```
library(gpuR)
ORDER = 1024
 
A = matrix(rnorm(ORDER^2), nrow=ORDER)
B = matrix(rnorm(ORDER^2), nrow=ORDER)
gpuA = gpuMatrix(A, type="double")
gpuB = gpuMatrix(B, type="double")
 
C = A %*% B
gpuC = gpuA %*% gpuB
 
all.equal(C, gpuC[])
```
result ( [1] TRUE )




