
본 문서는 사내에서 jupyter에 python library를 추가하고 jupyter 이미지를 생성하는 과정을 설명한다.

 
#1. Jupyter 파일 다운로드
	192.168.100.116 ( root / hello.mobigen )
	path : /root/b-iris-dist/kotra
	filename : jupyter-dist-4.3.0-a37ab83-20190721.tar.gz 
	
#2. Jupyter 다운로드 파일 압축 해제
    #tar xzf jupyter-dist-4.3.0-a37ab83-20190721.tar.gz
압축 해제 시 service 디렉토리를 확인할 수 있음
하위 디렉토리는 다음과 같은 구조를 가지고 있습니다. (몇몇 디렉토리는 다를 수 있습니다.)
    bin  common  conf  conf-template  images  install  lib  logs  save  user

이 중 주요 디렉토리는 다음과 같습니다.
- `bin`: 각 서비스의 실행 파일이 존재
- `conf`: 각 서비스의 conf 저장
- `lib`, `save`: 각 서비스에서 외부에 저장되는 데이터가 저장

#3. Jupyter 실행을 위한 파일 획득 
현재 동작 중인 180 서버에 접속하여 common 디렉토리, network.conf 파일 다운로드한다.
압축을 해제 후 service 디렉토리를 확인할 수 있다.
디렉토리(service)에서 다음 명령 실행 
	#sftp 192.168.100.180
    ( root / hello.root )
	#cd /root/b-iris/normal/service
	#get -r common
	#get conf-template/network.conf
	#exit
    
#4. Jupyter install
install 스크립트를 실행한다.
	#./install/jupyter-install.sh
스크립트 동작 설명
- docker에서 jupyter container 를 중지 및 삭제
- docker에서 jupyter image를 삭제
- docker에 패키지 내 jupyter 이미지를 적재
- 실행에 필요한 config 파일들을 복사( conf-templete => conf )

jupyter 이미지의 용량이 큰 관계로 시간이 소요되며, 스크립트 실행이 완료되면 아래와 같이 docker 명령어로 이미지가 로그된 것을 확인할 수 
있다.
	#docker images
	REPOSITORY            TAG                 IMAGE ID            CREATED             SIZE
	mobigen.com/jupyter   4.3.0-a37ab83       da244abcb476        4 weeks ago         11.2GB
	mobigen.com/jupyter   latest              da244abcb476        4 weeks ago         11.2GB

이전 단계에서 획득한 network.conf 파일을 conf 디렉토리로 복사한다.
    #mv network.conf conf-template

#5. Jupyter 실행
```
#./bin/jupyter-docker.sh start
```
스크립트 실행 시 아래와 같이 jupyter 컨테이너가 실행된 것을 확인할 수 있다.
```
#docker ps
CONTAINER ID        IMAGE                                   COMMAND                  CREATED             STATUS              PORTS                                            NAMES
065c57993da6        mobigen.com/jupyter:latest              "/attach/prepare.sh"     3 seconds ago       Up 2 seconds                                                         jupyter
```
웹브라우저를 이용한 확인은 다음과 같이 jupyter를 실행한 서버 아이피 + 8484 port로 접속 시 확인할 수 있다.
```
http://아이피:8484
```

#6. Jupyter 접속 
    #docker exec -it jupyter /bin/bash
정상적으로 들어갈 경우 아래와 같이 프롬프트가 / 로 변경 됩니다.
```
[root@test service]# docker exec -it jupyter bash
[root@test /]#
```

#7. Python 라이브러리 설치

python이 설치되어 있는 기본 경로는 다음과 같습니다.
	```
	[root@test /]# cd /opt/conda/envs/
	[root@test envs]# ls
	py27  py36
	```

2. conda, lib 업데이트 
	```
	#/opt/conda/bin/conda update conda
	#/opt/conda/bin/conda update --all
	#/opt/conda/bin/conda install -c anaconda git
	```

3. anaconda, git 설치 
	```
	#/opt/conda/bin/conda install -c anaconda git
	```

4. PyKospacing 라이브러리 설치

  dependency 로 tensorflow를 pip으로 설치 : anaconda 의 tensorflow 와  충돌 에러 발생 : linux 어쩌구 
에러 및 import abs 에러

  이 라이브러맄(PyKoSpacing)는 2.7 버전에서 설치를 진행할 수 없었습니다.

  PyKospacing 를 위한 라이브러리 설치
  ```
  #/opt/conda/envs/py36/bin/pip install tensorflow==1.4.*
  #/opt/conda/envs/py36/bin/pip install keras==2.1.*
  #/opt/conda/envs/py36/bin/pip install h5py=-2.7.*
  ```

  PyKoSpacing 설치
  ```
  #/opt/conda/envs/py36/bin/pip install git+https://github.com/haven-jeon/PyKoSpacing.git
  ```

  tensorflow 재 설치 ( 삭제 => 설치 )
  ```
  #/opt/conda/bin/conda uninstall tensorflow
  #/opt/conda/envs/py36/bin/pip uninstall tensorflow
  ```

5. 추가 Lib 설치
   
	```
	#/opt/conda/bin/conda install tensorflow
	#/opt/conda/bin/conda install keras
	#/opt/conda/bin/conda install gensim
	#/opt/conda/bin/conda install pytorch
	#/opt/conda/bin/conda install Scrapy
	#/opt/conda/bin/conda install geopandas
    #/opt/conda/envs/py36/bin/pip install Tika Konlpy ole-py watchdog datetime mglearn
    ```

6. Python3.6 Library 추가
    
    ```
    #/opt/conda/envs/py36/bin/pip install tensorflow
    #/opt/conda/envs/py36/bin/pip install gensim 
    #/opt/conda/envs/py36/bin/pip install torch
    #/opt/conda/envs/py36/bin/pip install Scrapy
    #/opt/conda/envs/py36/bin/pip install geopandas
    #bash <(curl -s https://raw.githubusercontent.com/konlpy/konlpy/master/scripts/mecab.sh)
    ```
7. Static library path 추가

  jupyter 실행 스크립트에 static library(mecab) 환경 변수를 추가한다.
	```
	#vim /attach/jupyter-start.sh
	
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib
    ```

8. Test

  터미널 상에서 테스트 방법
	```
	#export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/conda/envs/py36/lib:/usr/local/lib
	#/opt/conda/envs/py36/bin/python
	>>import tensorflow
	>>import keras
	>>import gensim
	>>import torch
	>>import scrapy
	>>from pykospacing import spacing
	>>import tika
	>>import konlpy
	>>import ole
	>>import watchdog
	>>import datetime
	>>import mglearn
	>>import sklearn
	>>import urllib
	>>from bs4 import BeautifulSoup
	>>import requests
	>>import MeCab
	>>import matplotlib
	>>import numpy
	>>import pandas
	>>import geopandas as gpd
	>>from konlpy.tag import Mecab
	```

#8. 이미지 생성

1. 프로세스 종료
	
    ```
	# ps -ef | grep jupyter
	root        42     1  0 15:07 ?        00:00:00 su -c /attach/jupyter-start.sh
	root        43    42  0 15:07 ?        00:00:00 /bin/bash /attach/jupyter-start.sh
	root        49    43  4 15:07 ?        00:00:01 /opt/conda/bin/python /opt/conda/bin/jupyter-notebook --config=/root/.jupyter/jupyter_notebook_config.py --allow-root --no-browser
	#kill -9 42 43 49
    ```
  프로세스가 종료되면 컨테이너 내부에서 빠져 나오게 된다.  
  또한 도커가 아래와 같이 Exited 상태인 것을 볼 수 있습니다.
	```
	[root@docker-test ~]# docker ps -a
	CONTAINER ID        IMAGE                        COMMAND                CREATED             STATUS                       PORTS               NAMES
	f933c220953e        mobigen.com/jupyter:latest   "/attach/prepare.sh"   10 minutes ago      Exited (137) 7 seconds ago                       jupyter
	[root@docker-test ~]# 
	```
2. 컨테이너로 부터 이미지 생성

  cmd : docker commit [options] <container id or name> [image name:[:tag name]]  
  container id는 위에서 종료된 container의 id를 사용한다.  
	```
	#docker commit f933c220953e mobigen.com/jupyter:latest
	```
  위 명령을 실행하면 완료 후 아래와 같이 이미지 정보가 출력된다.?
	```
	sha256:5c7e9120d545b75df15535f942c4bf2bd9bec35482f7cd752dae3a041faf963d
	```

3. Container 종료

  생성한 이미지를 이용해 Web상에서 테스트를 진행하기 위해  
  컨테이너를 완전히 종료 시키고 생성한 이미지를 실행한다.
    ```
    #docker rm jupyter 
    #docker ps -a
    
    ```

4. Jupyter 재 실행
  5장의 Jupyter 실행을 참고

#9. 테스트

Web 브라우저를 이용해 Jupyter가 실행된 서버 IP:8484로 접속한다.
Python3.6을 이용해 문서를 생성하고 다음 내용을 입력하여 실행한다.
	import tensorflow
	import keras
	import gensim
	import torch
	import scrapy
	from pykospacing import spacing
	import tika
	import konlpy
	import ole
	import watchdog
	import datetime
	import mglearn
	import sklearn
	import urllib
	from bs4 import BeautifulSoup
	import requests
	import MeCab
	import matplotlib
	import numpy
	import pandas
	import geopandas as gpd
	from konlpy.tag import Mecab

#10. 이미지 저장

테스트를 완료하였다면 Image를 tar 파일로 저장한다.
	```
	#docker save mobigen.com/jupyter:latest -o jupyter_base_images.tar.gz
    ```

