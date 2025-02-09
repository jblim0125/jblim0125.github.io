---
layout: post
title: 텍스트 데이터 형태 별 처리
author: jblim0125
date: 2024-10-27
category: 2024
---

Python환경에서 다양한 텍스트 데이터를 처리하기 위해 파일을 저장하고 읽어들이기 위한
기본적인 방법에 대하여 알아보자.  

### 텍스트 파일 읽기, 쓰기

```python
with open("sample.txt", 'w') as f:
    f.write('텍스트를 저장하고 읽어오기를 실습하고 있습니다.')

with open("sample.txt", 'r') as f:
    data = f.read()
print(data)
```

```text
텍스트를 저장하고 읽어오기를 실습하고 있습니다.
```

### 라인 단위로 파일 읽기, 쓰기

```python
with open("line.txt", 'w') as f:
    for i in range(1, 4):
        data = "%d번째 줄입니다.\n" % i
        f.write(data)

with open("line.txt", 'r') as f:
    while True:
        line = f.readline()
        print(line)
        if not line: break
```

```text
1번째 줄입니다.

2번째 줄입니다.

3번째 줄입니다.
```

### 텍스트 파일을 CSV 파일로 쓰고, 읽기

```python
data = {
    '이름':['김한국', '박대한', '홍길동'],
    '국어성적':[80, 75, 90],
    '영어성적':[90, 95, 75]
}
import pandas as pd
df = pd.DataFrame(data)
df.to_csv('csv.txt', sep=',')

import pandas as pd
df = pd.read_csv('csv.txt', index_col = 0)
df
```

<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>이름</th>
      <th>국어성적</th>
      <th>영어성적</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>김한국</td>
      <td>80</td>
      <td>90</td>
    </tr>
    <tr>
      <th>1</th>
      <td>박대한</td>
      <td>75</td>
      <td>95</td>
    </tr>
    <tr>
      <th>2</th>
      <td>홍길동</td>
      <td>90</td>
      <td>75</td>
    </tr>
  </tbody>
</table>
</div>

### CSV 파일 다루기

`CSV`는 구분자 콤마(,)로 데이터 필드를 구분한 데이터로서 대부분의 프로그램에서 읽거나 저장하기가 지원되는
일반적인 텍스트 파일의 형태이다. 이와 유사한 파일로 `TSV` 파일이 있는데
이것도 CSV 파일 범주에 포함되는 형태라고 할 수 있다. 파이썬에서 `CSV` 파일은 CSV 라이브러리를 이용해서
처리가 가능하다.  

무엇보다 `CSV` 형식의 파일은 데이터베이스에서 읽어들이기도 쉬울 뿐 아니라 `Excel`과도 호환이 가능하다는 점에서
많이 사용하고 있다. 이러한 형식의 문서는 확장자를 `.csv` 형식으로 저장하며 파이썬에서 처리하기 위해서는
csv 모듈을 불러들여 처리할 수 있다. 먼저 `CSV` 파일을 생성하는 방법은 다른 형태의 데이터 파일들을 전환할
수도 있고 아래와 같이 `csv.writer` 함수와 `writerow` 메소드를 이용하여 행 단위로 자료를 입력할 수 있다.  

#### 저장

```python
import csv    
with open('test.csv', 'w') as f:
    data = csv.writer(f)
    data.writerow(["김민국", 15, '남자', '서울시 서대문구 신촌동'])
    data.writerow(["박한솔", 30, '여자', '서울시 용산구 서빙고동'])
```

#### 읽기

CSV 파일을 읽어오는 방법은 `CSV`나 `pandas` 라이브러리를 사용하는 것이 편리하다. 이중에 `CSV` 라이브러리는
아래와 같이 `csv.reader` 함수를 이용하여 자료를 읽고 처리가 가능하다.  

```python
with open("test.csv", "r") as f:
  data = csv.reader(f)
  test=[]
  for row in data:
    test.append(row)
test
```

```text
[['김민국', '15', '남자', '서울시 서대문구 신촌동'], ['박한솔', '30', '여자', '서울시 용산구 서빙고동']]
```

그런데 CSV 파일을 읽어들이는 방법은 이 방법보다 다음에 설명할 `pandas`판다스의 데이터프레임으로 읽어들이는 방법이
다른 데이터 처리에 용이하기 때문에 더 많이 사용된다.  

### 데이터프레임 활용

`pandas`의 데이터프레임으로 읽어들이는 것이 좋은데 방법은 아래와 같이 `read_csv` 함수를 이용.
그리고 다시 `CSV` 파일로 전환하여 저장하고자 하는 경우 `df.to_csv` 함수를 사용.

```python
import pandas as pd
colnames=['Name', 'Age', 'Gender', 'Add'] 
df = pd.read_csv('test.csv', names=colnames, header=None)
df.to_csv('a.csv',header=None, index = False)
df
```

<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>Name</th>
      <th>Age</th>
      <th>Gender</th>
      <th>Add</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>김민국</td>
      <td>15</td>
      <td>남자</td>
      <td>서울시 서대문구 신촌동</td>
    </tr>
    <tr>
      <th>1</th>
      <td>박한솔</td>
      <td>30</td>
      <td>여자</td>
      <td>서울시 용산구 서빙고동</td>
    </tr>
  </tbody>
</table>
</div>

### JSON 파일 다루기

임의 `JSON` 파일 생성하기

```python
import json
import os

my_path = "~/data"
if not os.path.exists(my_path):
    os.makedirs(my_path)

admin={
    '1.name' : "hong gildong",
    '2.mysql' : { "id" :"mysql", "pass" : "12345" },
    '3.naver_api':{
        'id' : 'gildong',
        'api_key': 'my_naver_6789',
        'api_secret': "12345" },
    }
with open(os.path.join(my_path, 'admin_ex.json'), 'w') as f:
    json.dump(admin, f)
```

#### JSON 읽고 활용하기  

```python
with open('~/data/admin_ex.json','r') as f:
    s=f.read()
    admin = json.loads(s)
    admin1= json.loads(s)['3.naver_api']

print(s)
print(json.dumps(admin, indent= 4)) 
print(admin['3.naver_api']['api_key'])
print(admin1['api_key'], admin1['api_secret'])
```

```text
{"1.name": "hong gildong", "2.mysql": {"id": "mysql", "pass": "12345"}, "3.naver_api": {"id": "gildong", "api_key": "my_naver_6789", "api_secret": "12345"}}
{
    "1.name": "hong gildong",
    "2.mysql": {
        "id": "mysql",
        "pass": "12345"
    },
    "3.naver_api": {
        "id": "gildong",
        "api_key": "my_naver_6789",
        "api_secret": "12345"
    }
}
my_naver_6789
my_naver_6789 12345
```

#### JSON 데이터를 데이터프레임으로 변환 저장하기

```python
import json
import pandas as pd

df = pd.json_normalize(admin['2.mysql'])
json_csv = df.to_csv()
print(json_csv)
df
```

<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>id</th>
      <th>pass</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>mysql</td>
      <td>12345</td>
    </tr>
  </tbody>
</table>
</div>

### PDF, HWP 파일을 텍스트 파일로 변환하기

라이브러리를 설치하고 변환시키고자하는 PDF 파일을 다운로드

```python
!pip install PyPDF2
!wget https://github.com/byungjooyoo/Dataset/raw/main/DR2020_1.pdf
```

PyPDF2의 경우 아래와 같이 PdfFileReader함수를 이용해서 텍스트를 추출할 수 있는데 우선
한 페이지만 시범적으로 추출하여 문제가 없는지 확인한 후 전체 내용을 추출하는 방법으로 접근하도록 하겠다.

```python
import PyPDF2
pdfReader = PyPDF2.PdfReader("DR2020_1.pdf")
print(" No. Of Pages :", len(pdfReader.pages))
pageObject = pdfReader.pages[2]
print(pageObject.extract_text())
```

```text
 No. Of Pages : 6
발간사
최근 우리의 대내외 안보상황은 매우 복잡하고 엄중합니다. 한반도의 주변국들은 
자국 우선주의를 내세우며 첨단 군사력을 지속적으로 확충해 나가고 있으며, 해상과 
공중은 물론 우주· 사이버 등으로 군사영역을 확장하고 있습니다. 또한 코로나19, 재
난, 테러 등 초국가적 · 비군사적 위협들이 국가안보의 도전 요인으로 대두되고 있습니
다. 특히 코로나19의 확산, 미중 간 전략적 경쟁 등으로 역내 안보구도의 유동성과 불
확실성은 더욱 증대되고 있습니다.
한편 북한은 2018년 「9· 19 군사합의」를 체결한 이후 남북관계 개선 의지를 보이면서
도 우리 정부와 국제사회의 평화정착 노력에 적극적으로 호응하지 않고 있습니다. 
이러한 안보상황의 도전 속에서 우리 군은 ‘강한 힘’과 굳건한 한미동맹을 기반으로 확
고한 군사대비태세를 유지한 가운데, ‘국민을 위한 군’으로서 역할과 책임을 다하여 ‘강
한 안보, 자랑스러운 군, 함께하는 국방’을 건설할 수 있도록 최선을 다하고 있습니다.
우리 군은 국지도발 및 전면전에 대응할 수 있는 연합방위태세와 군사대비태세를 
유지하고 있으며, 전투임무 위주의 실전적 교육훈련을 강화하고 있습니다. 또한 코로
나19에 선제적이고 적극적으로 대응함으로써 국민의 생명과 안전을 지키는 군 본연의 
임무를 충실히 수행해 왔습니다. 
한미동맹은 한반도 및 역내 평화· 번영의 핵심축으로, 공동의 가치를 공유하는 포괄
적 전략동맹으로 지속 발전해 나가고 있습니다. 양국 군은 앞으로도 전시작전통제권 
전환과 새로운 연합방위체제 구축을 추진하면서 한미동맹의 한 단계 더 높은 도약을 
준비해 나갈 것입니다. 그리고 우리 군은 주변국과의 전략적 국방교류협력과 국방외교 
대상의 다변화를 통해 국방교류협력의 내실화와 외연 확대를 추진하고 있으며, 향후
에도 적극적 국방외교 활동을 통해 세계 평화에 이바지할 것입니다.
우리 군은 미래 전장환경에 맞는 국방역량을 구축하고 있습니다. 다양한 핵 · 대량
살상무기 위협에 대한 우리 군 및 한미연합의 능력을 강화하고 있으며, 핵심군사능력
을 중심으로 주요 전력을 증강하고 있습니다. 그리고 「국방개혁 2.0」과 스마트 국방혁
신 추진을 통해 첨단과학 기술군으로 거듭나기 위해 노력하고 있습니다. 우리 군의 구
```

전체 내용을 추출하기 위해서 for 루프를 이용하여 모든 페이지를 하나의 텍스트 자료로 통합한다.

```python
total = ''
for i in range(len(pdfReader.pages)):
    data = pdfReader.pages[i].extract_text()
    total += data
print(total[:1000])
```

```text
발간등록번호 
11-1290000-000440-11발간사
최근 우리의 대내외 안보상황은 매우 복잡하고 엄중합니다. 한반도의 주변국들은 
자국 우선주의를 내세우며 첨단 군사력을 지속적으로 확충해 나가고 있으며, 해상과 
공중은 물론 우주· 사이버 등으로 군사영역을 확장하고 있습니다. 또한 코로나19, 재
난, 테러 등 초국가적 · 비군사적 위협들이 국가안보의 도전 요인으로 대두되고 있습니
다. 특히 코로나19의 확산, 미중 간 전략적 경쟁 등으로 역내 안보구도의 유동성과 불
확실성은 더욱 증대되고 있습니다.
한편 북한은 2018년 「9· 19 군사합의」를 체결한 이후 남북관계 개선 의지를 보이면서
도 우리 정부와 국제사회의 평화정착 노력에 적극적으로 호응하지 않고 있습니다. 
이러한 안보상황의 도전 속에서 우리 군은 ‘강한 힘’과 굳건한 한미동맹을 기반으로 확
고한 군사대비태세를 유지한 가운데, ‘국민을 위한 군’으로서 역할과 책임을 다하여 ‘강
한 안보, 자랑스러운 군, 함께하는 국방’을 건설할 수 있도록 최선을 다하고 있습니다.
우리 군은 국지도발 및 전면전에 대응할 수 있는 연합방위태세와 군사대비태세를 
유지하고 있으며, 전투임무 위주의 실전적 교육훈련을 강화하고 있습니다. 또한 코로
나19에 선제적이고 적극적으로 대응함으로써 국민의 생명과 안전을 지키는 군 본연의 
임무를 충실히 수행해 왔습니다. 
한미동맹은 한반도 및 역내 평화· 번영의 핵심축으로, 공동의 가치를 공유하는 포괄
적 전략동맹으로 지속 발전해 나가고 있습니다. 양국 군은 앞으로도 전시작전통제권 
전환과 새로운 연합방위체제 구축을 추진하면서 한미동맹의 한 단계 더 높은 도약을 
준비해 나갈 것입니다. 그리고 우리 군은 주변국과의 전략적 국방교류협력과 국방외교 
대상의 다변화를 통해 국방교류협력의 내실화와 외연 확대를 추진하고 있으며, 향후
에도 적극적 국방외교 활동을 통해 세계 평화에 이바지할 것입니다.
우리 군은 미래 전장환경에 맞는 국방역량을 구축하고 있습니다. 다양한 핵 · 대량
살상무
```

텍스트 자료로 통합된 거을 파일로 아래와 같이 저장한다.

```python
with open('DR2020_1.txt', 'w') as f:
    f.write(total)
```

#### HWP 파일을 텍스트 파일로 변환 저장

라이브러리 설치와 한글 파일 다운로드  

```python
!pip install olefile
!wget https://github.com/byungjooyoo/Dataset/raw/main/%EB%85%BC%EB%AC%B8%EC%9A%94%EC%95%BD.hwp

```

```bash
Collecting olefile
  Downloading olefile-0.47-py2.py3-none-any.whl.metadata (9.7 kB)
Downloading olefile-0.47-py2.py3-none-any.whl (114 kB)
[2K   [90m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━[0m [32m114.6/114.6 kB[0m [31m8.4 MB/s[0m eta [36m0:00:00[0m
[?25hInstalling collected packages: olefile
Successfully installed olefile-0.47
--2024-10-27 04:31:17--  https://github.com/byungjooyoo/Dataset/raw/main/%EB%85%BC%EB%AC%B8%EC%9A%94%EC%95%BD.hwp
Resolving github.com (github.com)... 20.200.245.247
Connecting to github.com (github.com)|20.200.245.247|:443... connected.
HTTP request sent, awaiting response... 302 Found
Location: https://raw.githubusercontent.com/byungjooyoo/Dataset/main/%EB%85%BC%EB%AC%B8%EC%9A%94%EC%95%BD.hwp [following]
--2024-10-27 04:31:17--  https://raw.githubusercontent.com/byungjooyoo/Dataset/main/%EB%85%BC%EB%AC%B8%EC%9A%94%EC%95%BD.hwp
Resolving raw.githubusercontent.com (raw.githubusercontent.com)... 185.199.109.133, 185.199.111.133, 185.199.108.133, ...
Connecting to raw.githubusercontent.com (raw.githubusercontent.com)|185.199.109.133|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 110080 (108K) [application/octet-stream]
Saving to: ‘논문요약.hwp’

논문요약.hwp        100%[===================>] 107.50K   557KB/s    in 0.2s    

2024-10-27 04:31:18 (557 KB/s) - ‘논문요약.hwp’ saved [110080/110080]
```

설치된 라이브러리를 이용하여 아래와 같이 인코딩 및 디코딩 과정을 거쳐서 파일을 텍스트 자료로 변환할 수 있다.
이 경우 표나 그림형식에 대한 데이터 손실이 있기 때문에 변환된 자료를 잘 확인해볼 필요가 있다.

```python
import olefile
f = olefile.OleFileIO('논문요약.hwp')  
encoded_text = f.openstream('PrvText').read() 
decoded_text = encoded_text.decode('utf-16')  
decoded_text
```

```text
'MCMC를 이용한 선형전투모형의 베이지안 추론 사례\r\n(Bayesian Inference for the Linear Combat Model by using MCMC)\r\n유병주1†\r\n(Byung Joo Yoo)\r\n\r\nABSTRACT\r\n  As a way of predicting the future combat by analyzing past combat data, a method of fitting and analyzing the linear combat model may be considered. If two kinds of data differ historically from each other, it is difficult to fit into a single linear combat model due to violation of model assumptions. Two data of the same time can be applied to one model such as by using the dummy variable. but in this case, it is difficult to construct one model because it is two heterogeneous data with different ages. To solve this problem, Bayesian inference method using MCMC is proposed. After deriving the posterior distribution based on the noninformative prior and the previous period data, it is used as an informative prior for obtaining the final posterior distribution based on the next period data, then can predict the future combat by generating the posterior predictive distribution. I'
```

텍스트로 변환된 자료는 아래와 같이 파일로 저장해서 차후에 활용할 수 있다.

```python
with open("result.txt", 'w') as f:
    f.write(decoded_text)
```

다음은 `pyhwp`라는 라이브러리의 내부 명려어 `hwp5txt`를 이용하여 리눅스 명령으로 한글 파일을 텍스트 파일로
변환하는 방법이다. 이때 입력 파일과 출력 파일의 위치를 잘 확인할 필요가 있다.

```python
!pip install pyhwp
!hwp5txt --version
!hwp5txt --output "result1.txt" "논문요약.hwp"
```

```bash
Collecting pyhwp
  Downloading pyhwp-0.1b15.tar.gz (218 kB)
[2K     [90m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━[0m [32m218.1/218.1 kB[0m [31m8.3 MB/s[0m eta [36m0:00:00[0m
[?25h  Preparing metadata (setup.py) ... [?25ldone
[?25hRequirement already satisfied: cryptography in /opt/conda/lib/python3.11/site-packages (from pyhwp) (41.0.4)
Requirement already satisfied: lxml in /opt/conda/lib/python3.11/site-packages (from pyhwp) (5.3.0)
Requirement already satisfied: olefile>=0.43 in /opt/conda/lib/python3.11/site-packages (from pyhwp) (0.47)
Requirement already satisfied: cffi>=1.12 in /opt/conda/lib/python3.11/site-packages (from cryptography->pyhwp) (1.16.0)
Requirement already satisfied: pycparser in /opt/conda/lib/python3.11/site-packages (from cffi>=1.12->cryptography->pyhwp) (2.21)
Building wheels for collected packages: pyhwp
  Building wheel for pyhwp (setup.py) ... [?25ldone
[?25h  Created wheel for pyhwp: filename=pyhwp-0.1b15-py3-none-any.whl size=315454 sha256=86203b33daedb6f70c09edb60abebab963cfdd462de5d5ee2c9df6e42a727ab2
  Stored in directory: /home/jblim/.cache/pip/wheels/40/8f/bc/ee817a8f49aa1bb89def14968347a62538ebda6c19daa6a2b5
Successfully built pyhwp
Installing collected packages: pyhwp
Successfully installed pyhwp-0.1b15
hwp5txt 0.1b15
```

위에서 변환결과를 확인해보면 아래와 같이 데이터를 읽어들여 확인해 볼수 있다.

```python
with open("result1.txt", 'r') as f:
    data = f.read()
print(data)
```

```text
MCMC를 이용한 선형전투모형의 베이지안 추론 사례1) (주)심네트 R&D 및 V&V연구소
교신저자 : bjyoo@korea.ac.kr

(Bayesian Inference for the Linear Combat Model by using MCMC)
유병주1†
(Byung Joo Yoo)

ABSTRACT
  As a way of predicting the future combat by analyzing past combat data, a method of fitting and analyzing the linear combat model may be considered. If two kinds of data differ historically from each other, it is difficult to fit into a single linear combat model due to violation of model assumptions. Two data of the same time can be applied to one model such as by using the dummy variable. but in this case, it is difficult to construct one model because it is two heterogeneous data with different ages. To solve this problem, Bayesian inference method using MCMC is proposed. After deriving the posterior distribution based on the noninformative prior and the previous period data, it is used as an informative prior for obtaining the final posterior distribution based on the next period data, then can predict the future combat by generating the posterior predictive distribution. In particular, it is important to use the results of simulation sampling data under special conditions using the MCMC method to infer the posterior or posterior predictive distribution. In this case, it is possible to utilize various information rather than analyzing it with the classic linear combat model, and also has the advantage of continuously updating the model by reflecting additionally acquired data in the future.


Key Words : MCMC(Markov Chain Monte Carlo), Bayesian Inference, Linear Combat Model, 
            Posterior Distribution, Posterior Predictive Distribution

요  약   
  과거의 전투결과를 분석하여 미래에 있을 전투를 예측하기 위한 방법으로 선형전투모형을 적용하는 방법이 고려될 수 있다. 그러나 역사적으로 시대가 다른 두 유형의 자료들이라면 모형의 가정사항 위반으로 하나의 선형전투모형으로 적합하기는 어렵다. 동시대의 2가지 자료라면 Dummy 변수를 적용하는 등의 방법으로 하나의 모형으로 적합시킬 수 있지만 이 논문에서 다루는 자료의 경우에는 서로 시대가 다른 이질적인 두 가지 자료이기 때문에 하나의 모형으로 통합하기는 어렵다. 이러한 문제를 해결하기 위해 MCMC를 이용한 베이지안 추론 방법을 제안하였다. 제안한 방법은 앞선 시대에 있는 자료를 비정보적 사전분포를 가정하여 사후분포를 구하고 이를 다음 시대에 얻은 자료를 분석하기 위한 사전분포로 활용하여 최종 사후분포를 추론하고, 이를 이용하여 사후예측분포를 얻어 미래를 예측하는 방법이다. 특히 MCMC 방법을 사용하여 특별한 조건 하에 시뮬레이션하여 샘플링한 결과를 이용하여 사후분포나 사후예측분포를 몬테칼를로 방법으로 추론할 수 있다는 점이 중요하다. 이렇게 했을 때 고전적인 선형전투모형으로 분석하는 것보다 다양한 정보를 활용할 수 있을 뿐만 아니라 향후 추가적으로 획득되는 자료도 모형에 반영하여 모형을 계속 업데이트시킬 수 있는 장점이 있다. 

주요어 : 베이지안 추론, 마코프 체인 몬테 칼로, 선형전투모형, 사후분포, 사후예측분포
```

한글 문서를 텍스트로 변환하였으니, 다음 시간엔 `워드 클라우딩` 을 해보고자 한다.