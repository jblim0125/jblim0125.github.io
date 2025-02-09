---
layout: post
title: iterm2 SSH 서버 자동 접속 설정
author: jblim0125
date: 2024-01-10
category: 2024
---

xShell 에 길들여진 상태라 iTerm 자동 접속 설정이 아직 익숙하지 않아 기록으로 남김.  

1. 프로파일 열기 -> 편집  
   `CMD+o` 프로파일 화면 -> `Edit Profiles...`   
   ![프로파일](/assets/images/iterm-auto-login/2024-02-16-14-06-05.png)  

2. 패스워드 설정  
   패스워드 매니저 `⌥ + CMD + f` 를 열어 서버 접속 정보와 패스워드를 추가  
   ![패스워드매니저](/assets/images/iterm-auto-login/2024-02-16-14-13-49.png)
   
3. 프로파일 기본 정보 입력  
   ![프로파일설정](/assets/images/iterm-auto-login/2024-02-16-14-07-31.png)
   - `+` 를 눌러 새로운 프로파일을 생성   
   - Name 작성   
   - Title 설정  
   - Command 를 선택하고, 접속 대상 서버에 접속 할 수 있는 커맨드를 입력  
     `ssh -p{port} {UserName}@{URL(IP)}` 
4. 프로파일 트리거 설정   
   서버 접속 시 자동으로 패스워드 매니저를 열어 패스워드를 입력할 수 있도록 트리거를 설정  
   - Advanced -> Triggers -> Edit
   - Regular Expression : 정규표현식을 이용해 패스워드 매니저를 열기위한 조건 입력  
   - Action : Open Password Manager
   - Parameters : 2번에서 설정한 AccountName 을 설정  
   - Instant : 활성화  
   - Enabled : 활성화  
   ![](/assets/images/iterm-auto-login/2024-02-16-14-18-53.png)

5. Test
   - `CMD + o` 프로파일 열기  
   ![](/assets/images/iterm-auto-login/2024-02-16-14-22-40.png)
   - 패스워드 매니저 창에서 패스워드 입력 선택  
   ![](/assets/images/iterm-auto-login/2024-02-16-14-23-37.png)
   - 접속 확인  
   ![](/assets/images/iterm-auto-login/2024-02-16-14-24-24.png)

