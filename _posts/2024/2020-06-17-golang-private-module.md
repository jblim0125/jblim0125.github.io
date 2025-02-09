---
layout: post
title: Golang Private Module 
author: jblim0125
date: 2020-06-17
category: 2020
---

# Golang Module with Private GIT Repository
이 문서는 Golang으로 모듈을 만들고, 사용하기 위한 방법에 대해서 설명한다.  

## Create your own go module
1. 모듈 디렉토리 생성  
모듈 생성 시 규칙 : 저장될 사이트 / 저장소 / 모듈 이름 
(ex : githug.com/jblim0125/selfmodule) 
따라서 디렉토리의 이름은 모듈 이름을 따르는게 좋다.  
	```bash
	$ mkdir selfmodule
	$ cd selfmodule
	```
2. mod init  
위에서 설명한 바와 같이 사이트/저장소/모듈 이름을 이용해 go mod init을 수행한다.  
	```bash
	$ go mod init github.com/jblim0125/selfmodule
	```
3. 코드 작성  
	```go
	package selfmodule
	import "fmt"
	func PrintHello() {
	    fmt.Println("hello")
	}
	```
4. 빌드  
코드를 빌드하고 오류가 없는지 확인한다.  
	```bash
	$ go build 
	```
    
5. 저장소 업로드  
git 저장소에 소스, 태그를 업로드한다.  
태그 생성 규칙 v{major}.{minor}.{patch}을 따른다.  
	```bash
	$ git init
	$ git add .
	$ git commit -m "commit msg"
	$ git remote add origin https://github.com/jblim0125/selfmodule.git
	$ git push origin master
	$ git tag v0.0.1
	$ git push origin v0.0.1
	```
6. 다른 코드에서 go get을 이용해 모듈 다운로드 시도  
    ```bash
    $ go get github.com/jblim0125/selfmodule
    ```
    위 명령 실행 시 410 Gone 에러 메시지를 확인할 수 있다.  
    - 해결 방법  
        **GOPRIVATE** 을 이용한 사설 저장소 정보를 go에 인식 시키는 방법  
        ```bash
        $ go env -w GOPRIVATE=github.com/jblim0125  
        ```
        **Passing repository credentials to Go module during the build**  

7. 필요한 경우 go.mod 에 모듈 추가  
```go
...
require( 
    ...
    ...
    github.com/jblim0125/selfmodule v0.0.1
    ...
    ...
)
```
8. 모듈이 잘 동작하는지 확인  