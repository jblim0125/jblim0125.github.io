## Issues  
[대화형분석] jupyter 에서 python2, 3버전 에서 패키지 설치 시 에러 납니다. #1559

## 원인  
jupyter-notebook을 실행하는 스크립트에서 PATH에 /opt/conda/bin 디렉토리를 추가.  
/opt/conda/bin 에는 anaconda 실행에 필요한 python3.7, pip가 존재.  
따라서 WEB환경에서 pip 명령으로 패키지 설치 시 anaconda용 python3.7에 패키지가 설치 됨.  

내부에서 shell명령으로 pip -V, python -V 확인 시 아래 와 같이 출력된다.  
```
!python -V
=> Python 3.7.3

!pip -V	
=> pip 19.0.3 from /opt/conda/lib/python3.7/site-packages/pip (python 3.7)
```

또한 패키지 경로를 조회 시 2.7, 3.6 패키지 경로가 아닌 3.7 패키지 경로가 출력된다.  
```
!python -m site

sys.path = [
	'/notebook',
	'/notebook/$PYTHONPATH',
	'/mount/lib/jupyter/IRIS_API_2.1.0.1_PYTHON3.5.zip',
	'/home/jovyan/.local/lib/python3',
	'/mount/lib/jupyter/python3.6',
	'/opt/conda/lib/python37.zip',
	'/opt/conda/lib/python3.7',
	'/opt/conda/lib/python3.7/lib-dynload',
	'/opt/conda/lib/python3.7/site-packages',
]
USER_BASE: '/root/.local' (exists)
USER_SITE: '/root/.local/lib/python3.7/site-packages' (doesn't exist)
ENABLE_USER_SITE: True
```

## 해결
jupyter-notebook 에서 관리하는 kernel 파라미터(환경변수)를 변경.  
파라미터 파일 
    /conf/jupyter/jupyter-conf/kernels/python2/kernel.json
    /conf/jupyter/jupyter-conf/kernels/python3/kernel.json

python2/kernel.json
	{
		"display_name": "Python 2.7",
		"language": "python",
		"argv": [
			"/opt/conda/envs/py27/bin/python2.7",
			"-m",
			"ipykernel",
			"-f",
			"{connection_file}"
		],
		"env": {
			"PATH":"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/conda/envs/py27/bin:/docker/tools/spark/bin:/docker/tools/jdk/bin:/docker/tools/hadoop/bin",
			"PYTHONPATH": "/mount/lib/jupyter/IRIS_API_2.1.0.1_PYTHON2.7.zip:/home/jovyan/.local/lib/python2.7:/mount/lib/jupyter/python2.7"
		}
	}

python3/kernel.json
	{
		"display_name": "Python 3.6",
		"language": "python",
		"argv": [
			"/opt/conda/envs/py36/bin/python3.6",
			"-m",
			"ipykernel",
			"-f",
			"{connection_file}"
		],
		"env": {
			"PATH":"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/conda/envs/py36/bin:/docker/tools/spark/bin:/docker/tools/jdk/bin:/docker/tools/hadoop/bin",
			"PYTHONPATH": "/mount/lib/jupyter/IRIS_API_2.1.0.1_PYTHON3.5.zip:/home/jovyan/.local/lib/python3:/mount/lib/jupyter/python3.6"
		}
	}

