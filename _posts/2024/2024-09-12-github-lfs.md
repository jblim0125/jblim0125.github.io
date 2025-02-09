---
layout: post
title: github lfs 사용하기
author: jblim0125
date: 2024-09-12
category: 2024
---

## GitHub의 대용량 파일 정보

GitHub은(는) 일반 Git 리포지토리에서 추적할 수 있는 파일의 크기를 제한합니다.

### GitHub의 크기 제한 정보

GitHub은(는) 파일 및 리포지토리 크기 조정의 하드 제한이 있지만 모든 Git 리포지토리에
풍부한 스토리지를 제공하려고 합니다. 사용자의 성능과 안정성을 보장하기 위해 전체
리포지토리 상태의 신호를 적극적으로 모니터링합니다. 리포지토리 상태는 크기,
커밋 빈도, 콘텐츠, 구조를 비롯한 다양한 상호 작용 요소의 함수입니다.  

#### 파일 크기 제한

GitHub은(는) 리포지토리에 허용되는 파일의 크기를 제한합니다. 50MiB보다 큰 파일을
추가하거나 업데이트하려고 하면 Git에서 경고가 표시됩니다.

> 참고: 브라우저를 통해 리포지토리에 파일을 추가하는 경우 파일은
> 25MiB보다 클 수 없습니다.

GitHub은(는) 100MiB보다 큰 파일을 차단합니다.  
이 제한을 초과하는 파일을 추적하려면 Git 대용량 파일 스토리지(Git LFS)을(를) 사용해야 합니다.  

## Git Large File Storage

**정보**  
Git LFS은(는) 파일에 대한 참조를 리포지토리에 저장하여 대용량 파일을 처리하지만
실제 파일 자체는 처리하지 않습니다. Git의 아키텍처를 해결하기 위해 Git LFS은(는)
실제 파일(다른 곳에 저장됨)에 대한 참조 역할을 하는 포인터 파일을 만듭니다.
GitHub은(는) 리포지토리에서 이 포인터 파일을 관리합니다. 리포지토리를 복제할
때 GitHub은(는) 포인터 파일을 맵으로 사용하여 대용량 파일을 찾습니다.

Git LFS에 대한 여러 최대 크기 한도는 GitHub 한도에 따라 적용됩니다.

|Product|최대 파일 크기|
|---|---|
|GitHub Free|2GB|
|GitHub Pro|2GB|
|GitHub Team|4GB|
|GitHub Enterprise Cloud|5GB|

5GB의 파일당 한도를 초과하면 Git LFS에서 파일이 자동으로 거부되고 오류 메시지가 표시됩니다.  

**포인터 파일 형식**  
Git LFS의 포인터 파일은 다음과 같습니다.

```shell
version https://git-lfs.github.com/spec/v1
oid sha256:4cac19622fc3ada9c0fdeadb33f88f367b541f38b89102a3f1261ac81fd5bcb5
size 84977953
```

## Git LFS 설치

Git LFS를 사용하려면 Git과 별개인 새 프로그램을 다운로드하여 설치해야 합니다.  

### MacOS 기준

* Homebrew  

```shell
brew install git-lfs
```

* MacPorts

```shell
port install git-lfs
```

**설치확인**  

```shell
$ git lfs install
> Git LFS initialized.
```

## Git LFS 구성

1. Terminal(터미널) 실행  
2. Git LFS 사용 선언  

    ```shell
    git lfs install
    ```

3. Git Track 해제  
    LFS에 올릴 파일은 Git의 Tracking에서 제외해야합니다. 아래 명령어로 Unstaging을
    수행할 수 있습니다. `--cached` 옵션을 쓰는 이유는 LFS에 올려야하기 때문에
    로컬에서는 존재해야하기 때문입니다. (매우 중요)

    ```shell
    git rm --cached (file path)
    ex) git rm --cached ./libs/big_lib.jar
    ```

4. Git LFS Track 설정  
    Git에서 Unstaging을 수행했다면, 이제 LFS에서 사용할 수 있도록 Tracking을 설정합니다.  

    ```shell
    git lfs track (file path)
    ex) git lfs track ./libs/big_lib.jar
    ```

    여기서는 아래와 같이 와일드카드도 사용할 수 있습니다.
    다음 예시는 모든 jar 파일은 lfs에 올리겠다고 설정한 것입니다.  

    ```shell
    git lfs track "*.jar"
    ```

5. Git add .gitattributes  
    Git lfs를 설정하면 `.gitattributes`라는 파일을 확인할 수 있습니다.
    이 파일에 Git LFS로 관리되는 파일 정보가 저장되기 때문에 Git에 이 변경사항을
    꼭 추가해줘야합니다.  

    ```shell
    git add .
    git commit -m "update lfs"
    ```

6. Push  
여기까지 완료했다면 Remote에 Push하면 됩니다.

```shell
git push (remote 이름) (branch 이름)
ex) git push origin main
## 파일 업로드에 대한 몇 가지 진단 정보가 표시됩니다.

> Sending big_lib.jar
> 44.74 MB / 81.04 MB  55.21 % 14s
> 64.74 MB / 81.04 MB  79.21 % 3s
```

## 주의할 점

Github에서 제공하는 LFS의 경우 무제한이 아니라는 점입니다.
따라서 LFS의 사용이 필요한 경우에만 사용해야 할 것입니다.  

> 100MB 미만의 파일은 LFS를 사용 X

## 추가 : 리포지토리의 파일을 Git Large File Storage로 이동

`git lfs track` 구성 후 일반 저장소에서 Git LFS로 파일을 이동할 수 있습니다.

* git lfs 2.0.0 이상의 경우  
Git에 파일을 푸시하려고 할 때 “Git 파일 크기 제한인 100MiB”을(를) 초과한다는
오류가 발생하면 `filter-repo` 또는 BFG 리포지토리 클리너 대신 `git lfs migrate`를
사용하여 대용량 파일을 LFS로 이동할 수 있습니다.
`git lfs migrate` 명령에 대한 자세한 내용은 Git LFS 2.2.0 릴리스 공지 사항을 참조하세요.  

1. `filter-repo` 명령 또는 BFG 리포지토리 클리너를 사용하여 리포지토리의
Git 기록에서 파일을 제거합니다. 이를 사용한 정보에 대한 자세한 정보는
`Removing sensitive data from a repository(리포지토리에서 중요한 데이터 제거)`
를 참조하세요.  
2. 파일에 대한 추적(`git lfs track ...`)을 구성하고 Git LFS에 푸시합니다.
