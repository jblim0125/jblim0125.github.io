---
layout: post
title: 한글 형태소 분석기 활용
author: jblim0125
date: 2024-10-20
category: 2024
---

## 인터넷보고 따라하기

데이터 전처리는 어떠한 문제를 해결하기 전에 자료를 사전에 잘 다듬는 것을 말한다. 특히 텍스트 데이터의 경우 수집 방법에 따라서
사전에 손질을 해야할 사항이 많은데, 예를 들면 맞춤법이 틀려서 의미 전달이 잘못되는 경우를 방지하기 위해 일괄적으로 맞춤법을
수정하거나, 띄어쓰기를 수정하는 등의 작업이 필요한 경우도 있고, 필요에 따라서는 분석 대상을 축소하여 명사만을 찾아서 추출해야할
경우도 있을 것이다. 어떤 경우 불필요한 특수기호들을 일괄적으로 제거해야할 경우도 있고, 때로는 문장을 검색, 수정, 삭제, 자르기,
붙이기 등의 추가적인 작업이 필요할 경우가 있다. 이를 위해 사용하는 대표적인 도구가 형태소분석기와 정규표현식 라이브러리가 있다.

형태소분석기는 일반적으로 단어 자체 또는 단어보다 작은 최소단위의 어절로 자연어를 분해하여 품사를 식별해줄 수 있는 도구를 말한다.
이는 인간의 언어 현상을 컴퓨터와 같은 기계를 이용해서 묘사할 수 있도록 연구하는 자연어 처리의 중요한 분야이며 최근 인공지능을
구현하기 위해 필수적으로 활용해야 하는 도구이기도 하다. 특히 영어권의 언어적 특성과 다른 특징을 가지고 있는 한글 텍스트 분석을
위홰서는 한글 특성에 맞게 개발된 한글 형태소분석기를 사용해야할 필요가 있을 것이다.

정규 표현식 또는 정규식은 특정한 규칙을 가진 문자열의 집합을 표현하는 데 사용하는 형식 언어를 말한다. 이는 단지 파이썬 뿐만이
아니라 대부분의 프로그래밍 언어에서 라이브러리 형태로 제공하고 있는데 Meta 문자들을 이용해서 지정된 문자열을 검색, 수정, 삭제,
대체 등을 용이하게 하도록 개발된 패키지 이다. 이러한 툴들을 이용해서 텍스트 데이터를 전처리하는 구체적인 라이브러리 활용 방법들에
대하여 알아보도록 한다.  

## Jupyter 사용하기  

Docker - Jupyter 활용에 대해서는 레퍼런스를 참고한다.

1. 다운로드  
    ![alt text](/assets/images/nltk/jupyter-download.png)

2. 실행  

    ```shell
    docker run -itd --name jupyter \
        -p 8888:8888 \
        --user root \
        -e NB_USER="jblim" \
        -e CHOWN_HOME=yes \
        -e GRANT_SUDO=yes \
        -v /Users/jblim/workspace/jupyter:/home/jblim \
        jupyter/tensorflow-notebook:latest
    ```

3. 쥬피터 환경 접속  
    ![alt text](/assets/images/nltk/jupyter-log.png)
    ![alt text](/assets/images/nltk/jupyter-web.png)

## 참고 사이트 코드 따라하기

[참고사이트](https://github.com/byungjooyoo/Text_Bigdata_Book/blob/main/06%EC%9E%A5_%ED%95%9C%EA%B8%80%ED%98%95%ED%83%9C%EC%86%8C%EB%B6%84%EC%84%9D%EA%B8%B0_%ED%99%9C%EC%9A%A9.ipynb)

1. 필요한 패키지들 설치  

    1. java 설치  

        ```shell
        ## Eclipse Temurin JDK 17 다운로드  
        wget https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.7%2B7/OpenJDK17U-jdk_x64_linux_hotspot_17.0.7_7.tar.gz

        ## 압축해제  
        tar xzvf OpenJDK17U-jdk_x64_linux_hotspot_17.0.7_7.tar.gz

        ## 환경 변수 설정  
        vim ~/.bashrc

        export JAVA_HOME=/home/jblim/jdk-17.0.7+7
        export PATH=$PATH:$JAVA_HOME/bin
        ```

    2. nltk 설치  

        ```shell
        pip instlal nltk
    
        Collecting nltk
        Downloading nltk-3.9.1-py3-none-any.whl.metadata (2.9 kB)
        Requirement already satisfied: click in /opt/conda/lib/python3.11/site-packages (from nltk) (8.1.7)
        Requirement already satisfied: joblib in /opt/conda/lib/python3.11/site-packages (from nltk) (1.3.2)
        Collecting regex>=2021.8.3 (from nltk)
        Downloading regex-2024.9.11-cp311-cp311-manylinux_2_17_aarch64.manylinux2014_aarch64.whl.metadata (40 kB)
            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 40.5/40.5 kB 3.6 MB/s eta 0:00:00
        Requirement already satisfied: tqdm in /opt/conda/lib/python3.11/site-packages (from nltk) (4.66.1)
        Downloading nltk-3.9.1-py3-none-any.whl (1.5 MB)
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 1.5/1.5 MB 8.6 MB/s eta 0:00:00a 0:00:01
        Downloading regex-2024.9.11-cp311-cp311-manylinux_2_17_aarch64.manylinux2014_aarch64.whl (791 kB)
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 791.8/791.8 kB 9.9 MB/s eta 0:00:00:00:0100:01
        Installing collected packages: regex, nltk
        Successfully installed nltk-3.9.1 regex-2024.9.11
        Note: you may need to restart the kernel to use updated packages.
        ```

    3. stanford nlp 다운로드  

        ```shell
        wget https://nlp.stanford.edu/software/stanford-tagger-4.2.0.zip

        ## 압축해제  
        unzip ...
        ```

2. 영문 형태소분석기 활용  

    ```python
    import nltk

    sentence = '''
    beautiful Emma refused to permit us to obtain the refuse permit.
    At eight o'clock on Thursday morning Arthur didn't feel very good'''

    tokens = nltk.word_tokenize(sentence)
    print('1', tokens)
    tagged = nltk.tag.pos_tag(tokens)
    print('2',tagged)

    nouns_list = [t[0] for t in tagged if t[1] == "NN"]
    nouns_list
    ```

    따라했는데... 오류 발생  

    ```text
    ---------------------------------------------------------------------------
    LookupError                               Traceback (most recent call last)
    Cell In[2], line 7
        1 import nltk
        3 sentence = '''
        4 beautiful Emma refused to permit us to obtain the refuse permit.
        5 At eight o'clock on Thursday morning Arthur didn't feel very good'''
    ----> 7 tokens = nltk.word_tokenize(sentence)
        8 print('1', tokens)
        9 tagged = nltk.tag.pos_tag(tokens)

    File /opt/conda/lib/python3.11/site-packages/nltk/tokenize/__init__.py:142, in word_tokenize(text, language, preserve_line)
        127 def word_tokenize(text, language="english", preserve_line=False):
        128     """
        129     Return a tokenized copy of *text*,
        130     using NLTK's recommended word tokenizer
    (...)
        140     :type preserve_line: bool
        141     """
    --> 142     sentences = [text] if preserve_line else sent_tokenize(text, language)
        143     return [
        144         token for sent in sentences for token in _treebank_word_tokenizer.tokenize(sent)
        145     ]
    ```

3. 코드 수정  

    ```python
    import os
    from nltk.tag import StanfordPOSTagger as POSTagger
    from nltk.tokenize import word_tokenize

    os.environ['JAVA_HOME'] = '/home/jblim/jdk-17.0.13+11'

    FOLDER = 'stanford-postagger-full-2020-11-17'
    POS_MODEL_PATH = os.path.join(FOLDER, 'models/english-bidirectional-distsim.tagger')
    POS_JAR_PATH = os.path.join(FOLDER, 'stanford-postagger-4.2.0.jar')

    pos_tagger = POSTagger(POS_MODEL_PATH, POS_JAR_PATH)

    text = """beautiful Emma refused to permit us to obtain the refuse permit.
    At eight o'clock on Thursday morning Arthur didn't feel very good"""

    tokens = word_tokenize(text)
    print('1', tokens)

    tags = pos_tagger.tag(tokens)
    print('2', tags)

    nouns_list = [t[0] for t in tags if t[1] == "NN"]
    nouns_list
    ```

    ```text
    1 ['beautiful', 'Emma', 'refused', 'to', 'permit', 'us', 'to', 'obtain', 'the', 'refuse', 'permit', '.', 'At', 'eight', "o'clock", 'on', 'Thursday', 'morning', 'Arthur', 'did', "n't", 'feel', 'very', 'good']
    2 [('beautiful', 'JJ'), ('Emma', 'NNP'), ('refused', 'VBD'), ('to', 'TO'), ('permit', 'VB'), ('us', 'PRP'), ('to', 'TO'), ('obtain', 'VB'), ('the', 'DT'), ('refuse', 'NN'), ('permit', 'NN'), ('.', ','), ('At', 'IN'), ('eight', 'CD'), ("o'clock", 'NN'), ('on', 'IN'), ('Thursday', 'NNP'), ('morning', 'NN'), ('Arthur', 'NNP'), ('did', 'VBD'), ("n't", 'RB'), ('feel', 'VB'), ('very', 'RB'), ('good', 'JJ')]
    ['refuse', 'permit', "o'clock", 'morning']
    ```

4. 한글 텍스트 분석 환경 설정과 한글 형태소 분석기 설치  

    1. 폰트 설치  

        ```shell
        !apt install fonts-nanum fonts-nanum-extra
        !ls /usr/share/fonts/truetype/nanum
        ```

        ```text
        Reading package lists... Done
        Building dependency tree... Done
        Reading state information... Done
        fonts-nanum is already the newest version (20200506-1).
        fonts-nanum-extra is already the newest version (20200506-1).
        0 upgraded, 0 newly installed, 0 to remove and 103 not upgraded.
        NanumBarunGothicBold.ttf	NanumMyeongjoExtraBold.ttf
        NanumBarunGothicLight.ttf	NanumMyeongjo.ttf
        NanumBarunGothic.ttf		NanumMyeongjo-YetHangul.ttf
        NanumBarunGothicUltraLight.ttf	NanumPen.ttf
        NanumBarunGothic-YetHangul.ttf	NanumSquare_acB.ttf
        NanumBarunpenB.ttf		NanumSquare_acEB.ttf
        NanumBarunpenR.ttf		NanumSquare_acL.ttf
        NanumBrush.ttf			NanumSquare_acR.ttf
        NanumGothicBold.ttf		NanumSquareB.ttf
        NanumGothicCodingBold.ttf	NanumSquareEB.ttf
        NanumGothicCoding.ttf		NanumSquareL.ttf
        NanumGothicEcoR.ttf		NanumSquareRoundB.ttf
        NanumGothicExtraBold.ttf	NanumSquareRoundEB.ttf
        NanumGothicLight.ttf		NanumSquareRoundL.ttf
        NanumGothic.ttf			NanumSquareRoundR.ttf
        NanumMyeongjoBold.ttf		NanumSquareR.ttf
        NanumMyeongjoEcoR.ttf
        ```

    2. matplotlib 설치  

        ```shell
        pip install matplotlib
        ```

        ```python
        import matplotlib as mpl
        import matplotlib.pyplot as plt
        mpl.font_manager.fontManager.addfont('/usr/share/fonts/truetype/nanum/NanumGothic.ttf')
        mpl.rc('font', family='NanumGothic')
        plt.rc("axes", unicode_minus=False)
        ```

    3. pandas 설치  

        ```shell
        pip install pandas
        ```

        ```python
        import pandas as pd
        pd.Series([0,2,-4,6]).plot(title="한글", figsize=(12, 2))
        ```

        ![alt text](/assets/images/nltk/pandas-result.png)

    4. 한국어 nlp 설치  

        KoNLPy.tag로 제공하는 형태소 분석기에는 Hannanum Class(한나눔), Kkma Class(꼬꼬마), Komoran Class(코모란), Mecab Class(메캅), Okt Class(Open Korean Text) 형태소 분석기 들이 있다.

        ```python
        !pip install konlpy
        !git clone https://github.com/SOMJANG/Mecab-ko-for-Google-Colab.git
        %cd Mecab-ko-for-Google-Colab
        !bash install_mecab-ko_on_colab_light_220429.sh
        %cd
        ```

    5. mecab 설치 에러 발생  

        위 스크립트 실행할 경우 정상적으로 실행되지 않을 수 있음.  
        m1 mac 의 jupyter notebook (docker) 환경에서 mecab 설치 시 에러 발생...

        ```shell
        ./configure

        ...
        ...
        checking build system type... ./config.guess: unable to guess system type

        This script, last modified 2011-05-11, has failed to recognize
        the operating system you are using. It is advised that you
        download the most up to date version of the config scripts from

        http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD
        and
        http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD

        If the version you run (./config.guess) is already up to date, please
        send the following data and any information you think might be
        pertinent to <config-patches@gnu.org> in order to provide the needed
        information to handle your system.

        config.guess timestamp = 2011-05-11

        uname -m = aarch64
        uname -r = 6.10.4-linuxkit
        uname -s = Linux
        uname -v = #1 SMP Wed Oct  2 16:38:00 UTC 2024

        /usr/bin/uname -p = aarch64
        /bin/uname -X     = 

        hostinfo               = 
        /bin/universe          = 
        /usr/bin/arch -k       = 
        /bin/arch              = aarch64
        /usr/bin/oslevel       = 
        /usr/convex/getsysinfo = 

        UNAME_MACHINE = aarch64
        UNAME_RELEASE = 6.10.4-linuxkit
        UNAME_SYSTEM  = Linux
        UNAME_VERSION = #1 SMP Wed Oct  2 16:38:00 UTC 2024
        configure: error: cannot guess build type; you must specify one
        ```

        다음과 같이 입력하여 환경설정을 수행한다.  

        ```shell
        ./configure --build=aarch64-unknown-linux-gnu
        ```

    6. fix  

        4번 단계에서 실행하는 script 의 다음 부분들을 수정한다.  

        ```shell
        echo "installing mecab-0.996-ko-0.9.2.tar.gz........"
        echo 'configure'
        --- before ---
        ! ./configure > /dev/null 2>&1
        --- after ---
        ! ./configure --build=aarch64-unknown-linux-gnu > /dev/null 2>&1
        --- end ---
        echo 'make'
        ! make > /dev/null 2>&1
        echo 'make check'
        ! make check > /dev/null 2>&1
        ...

        echo "installing........"
        echo 'configure'
        --- before ---
        ! ./configure > /dev/null 2>&1
        --- after ---
        ! ./configure --build=aarch64-unknown-linux-gnu > /dev/null 2>&1
        --- end ---
        echo 'make'
        ! make > /dev/null 2>&1
        ```

    7. 샘플 코드 실행  

        ```python
        # 한글 형태소분석기 클래스 불러오기
        from konlpy.tag import Hannanum, Komoran, Kkma, Okt, Mecab
        text = '홍길동 전화번호는 Kt 1234-5678번 입니까?'

        komoran = Komoran()
        print(komoran.pos(text))

        okt = Okt()
        print(okt.pos(text))

        mecab = Mecab()
        print(mecab.pos(text))
        ```

        ```text
        [('홍길동', 'NNP'), ('전화번호', 'NNP'), ('는', 'JX'), ('Kt', 'SL'), ('1234', 'SN'), ('-', 'SW'), ('5678', 'SN'), ('번', 'NNB'), ('입', 'VV'), ('니까', 'EF'), ('?', 'SF')]
        [('홍길동', 'Noun'), ('전화번호', 'Noun'), ('는', 'Josa'), ('Kt', 'Alpha'), ('1234-5678', 'Number'), ('번', 'Noun'), ('입', 'Noun'), ('니까', 'Josa'), ('?', 'Punctuation')]
        [('홍길동', 'NNG'), ('전화', 'NNG'), ('번호', 'NNG'), ('는', 'JX'), ('Kt', 'SL'), ('1234', 'SN'), ('-', 'SY'), ('5678', 'SN'), ('번', 'NNBC'), ('입니까', 'VCP+EF'), ('?', 'SF')]
        ```

### 한글 형태소 분석기 활용

1. 한글형태소분석기 불러오기

    ```python
    from konlpy.tag import Mecab
    text = '홍길동 전화번호는 Kt 1234-5678번 입니까?'

    mecab = Mecab()
    print(mecab.morphs(text))
    print(mecab.nouns(text))
    print(mecab.pos(text))
    ```

    ```text
    ['홍길동', '전화', '번호', '는', 'Kt', '1234', '-', '5678', '번', '입니까', '?']
    ['홍길동', '전화', '번호', '번']
    [('홍길동', 'NNG'), ('전화', 'NNG'), ('번호', 'NNG'), ('는', 'JX'), ('Kt', 'SL'), ('1234', 'SN'), ('-', 'SY'), ('5678', 'SN'), ('번', 'NNBC'), ('입니까', 'VCP+EF'), ('?', 'SF')]
    ```

    ```python
    # tagset 보기
    print(mecab.tagset)
    ```

    ```text
    {'EC': '연결 어미', 'EF': '종결 어미', 'EP': '선어말어미', 'ETM': '관형형 전성 어미', 'ETN': '명사형 전성 어미', 'IC': '감탄사', 'JC': '접속 조사', 'JKB': '부사격 조사', 'JKC': '보격 조사', 'JKG': '관형격 조사', 'JKO': '목적격 조사', 'JKQ': '인용격 조사', 'JKS': '주격 조사', 'JKV': '호격 조사', 'JX': '보조사', 'MAG': '일반 부사', 'MAJ': '접속 부사', 'MM': '관형사', 'NNB': '의존 명사', 'NNBC': '단위를 나타내는 명사', 'NNG': '일반 명사', 'NNP': '고유 명사', 'NP': '대명사', 'NR': '수사', 'SC': '구분자 , · / :', 'SE': '줄임표 …', 'SF': '마침표, 물음표, 느낌표', 'SH': '한자', 'SL': '외국어', 'SN': '숫자', 'SSC': '닫는 괄호 ), ]', 'SSO': '여는 괄호 (, [', 'SY': '기타 기호', 'VA': '형용사', 'VCN': '부정 지정사', 'VCP': '긍정 지정사', 'VV': '동사', 'VX': '보조 용언', 'XPN': '체언 접두사', 'XR': '어근', 'XSA': '형용사 파생 접미사', 'XSN': '명사파생 접미사', 'XSV': '동사 파생 접미사'}
    ```

2. 명사추출과 빈도 분석  

    ```python
    #헌법전문을 읽어들이고 문장별로 분리해서 리스트로 정리
    from konlpy.corpus import kolaw
    from collections import Counter
    kolaw.fileids()
    con_para = kolaw.open('constitution.txt').read()
    nouns = mecab.nouns(con_para)
    nouns = [n for n in nouns if len(n) > 1]
    count = Counter(nouns)
    top = count.most_common(20)
    print(top)
    ```

    ```text
    [('법률', 121), ('대통령', 84), ('국가', 73), ('헌법', 69), ('국민', 69), ('국회', 69), ('필요', 31), ('위원', 30), ('기타', 26), ('법원', 25), ('보장', 24), ('정부', 23), ('사항', 23), ('국무', 23), ('자유', 21), ('권리', 21), ('선거', 21), ('의원', 21), ('회의', 21), ('경제', 20)]
    ```

3. 빈도분석과 시각화  

    ```python
    import nltk
    key_words = nltk.Text(nouns)
    plt.figure(figsize=(12,6))
    key_words.plot(20)
    ```

    ![alt text](/assets/images/nltk/line-graph.png)

    ```python
    # 히스토그램 그리기
    import matplotlib.pyplot as plt
    import numpy as np

    plt.rc('font', family='NanumGothic')

    x = np.arange(len(top))
    keys = [x[0] for x in top]
    values = [x[1] for x in top]
    plt.figure(figsize=(12,6))
    plt.bar(x, values)
    plt.xticks(x, keys)

    plt.show()
    ```

    ![alt text](/assets/images/nltk/histogran.png)


### 영어 분용어 사전 활용과 한글 불용어 처리

1. 영어 불용어 사전과 불용어 처리  

```python
# 영어 불용어 처리
import nltk
from nltk.corpus import stopwords
nltk.download('stopwords')
nltk.download('punkt')
stop_words = list(stopwords.words('english'))
print(len(stop_words), stop_words[:10])
```

```text
[nltk_data] Downloading package stopwords to /home/jblim/nltk_data...
179 ['i', 'me', 'my', 'myself', 'we', 'our', 'ours', 'ourselves', 'you', "you're"]
[nltk_data]   Unzipping corpora/stopwords.zip.
[nltk_data] Downloading package punkt to /home/jblim/nltk_data...
[nltk_data]   Package punkt is already up-to-date!]
```

```python
text = "I am a student. you're a teacher."
tokens = nltk.word_tokenize(text)
result = [word for word in tokens if not word in stop_words]
print('불용어 제거 전 :',tokens)
print('불용어 제거 후 :',result)
```

```text
불용어 제거 전 : ['I', 'am', 'a', 'student', '.', 'you', "'re", 'a', 'teacher', '.']
불용어 제거 후 : ['I', 'student', '.', "'re", 'teacher', '.']
```

2. 한글 불용어 처리 방법  

```python
!wget https://raw.githubusercontent.com/byungjooyoo/Dataset/main/korean_stopwords.txt
with open('korean_stopwords.txt', 'r') as f:
    stop_words = f.read().split("\n")
print(len(stop_words), stop_words[:10])
stop_words = ['는', '두']+stop_words
print(len(stop_words), stop_words[:10])
```

```text
--2024-10-20 10:39:28--  https://raw.githubusercontent.com/byungjooyoo/Dataset/main/korean_stopwords.txt
Resolving raw.githubusercontent.com (raw.githubusercontent.com)... 185.199.111.133, 185.199.110.133, 185.199.108.133, ...
Connecting to raw.githubusercontent.com (raw.githubusercontent.com)|185.199.111.133|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 7007 (6.8K) [text/plain]
Saving to: ‘korean_stopwords.txt’

korean_stopwords.tx 100%[===================>]   6.84K  --.-KB/s    in 0.001s  

2024-10-20 10:39:29 (6.56 MB/s) - ‘korean_stopwords.txt’ saved [7007/7007]

675 ['아', '휴', '아이구', '아이쿠', '아이고', '어', '나', '우리', '저희', '따라']
677 ['는', '두', '아', '휴', '아이구', '아이쿠', '아이고', '어', '나', '우리']
```

```python
# 처리 전후 비교
tokens = ['아', '아이쿠', '김철수', '는', '극중', '두', '인격', '의', '사나이', '이광수', '역', '을', '맡았다']
result = [word for word in tokens if not word in stop_words]
print('불용어 제거 전 :',tokens)
print('불용어 제거 후 :',result)
```

```text
불용어 제거 전 : ['아', '아이쿠', '김철수', '는', '극중', '두', '인격', '의', '사나이', '이광수', '역', '을', '맡았다']
불용어 제거 후 : ['김철수', '극중', '인격', '사나이', '이광수', '역', '맡았다']
```

### 키워드 빈도분석 사례  

```python
# 대통령 취임사 파일
!wget https://raw.githubusercontent.com/byungjooyoo/Dataset/main/president_message.txt
para = open('president_message.txt', 'r').read()
print(para[:100])
```

```text
--2024-10-20 10:40:38--  https://raw.githubusercontent.com/byungjooyoo/Dataset/main/president_message.txt
Resolving raw.githubusercontent.com (raw.githubusercontent.com)... 185.199.111.133, 185.199.110.133, 185.199.108.133, ...
Connecting to raw.githubusercontent.com (raw.githubusercontent.com)|185.199.111.133|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 8497 (8.3K) [text/plain]
Saving to: ‘president_message.txt’

president_message.t 100%[===================>]   8.30K  --.-KB/s    in 0.001s  

2024-10-20 10:40:39 (5.93 MB/s) - ‘president_message.txt’ saved [8497/8497]

존경하고 사랑하는 국민 여러분, 750만 재외동포 여러분 그리고 자유를 사랑하는 세계 시민 여러분, 저는 이 나라를 자유민주주의와 시장경제 체제를 기반으로 국민이 진정한 주인인 나
```

```python
#Collections 라이브러리 이용
nouns = mecab.nouns(para)
nouns = [n for n in nouns if len(n) > 1]

# 3. 단어 숫자 세기
count = Counter(nouns)
top = count.most_common(20)
print(top)
```

```text
[('자유', 32), ('우리', 19), ('여러분', 16), ('국민', 15), ('시민', 15), ('나라', 14), ('세계', 13), ('사회', 12), ('평화', 12), ('국제', 9), ('해결', 9), ('위기', 8), ('존경', 7), ('문제', 7), ('가치', 7), ('연대', 6), ('경제', 5), ('감사', 5), ('국가', 5), ('민주주의', 5)]
```

```python
import matplotlib.pyplot as plt
import numpy as np

plt.rc('font', family='NanumGothic')

x = np.arange(len(top))
keys = [x[0] for x in top]
values = [x[1] for x in top]
plt.figure(figsize=(12,6))
plt.bar(x, values)
plt.xticks(x, keys)

plt.show()
```

![alt text](/assets/images/nltk/nlp-result.png)
