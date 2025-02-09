
# 모니터링

각종 필터 조건을 이용하여 모니터링 대상을 지정하고 상태를 조회할 수 있는 기능 개발

## 설계

1. 요구사항
2. Usecase
usecase : 화면 기획서와 비교해서 필요한 usecase 정리  
actor : func(list)
actor : func(search)
actor : func(add)
3. Sequence diagram
service - interface : fabric server and another(모니터링 확장)  
actor : ...
service A -> Monitoring : ...
service A <- Monitoring : ..
4. Interface  
RestAPI
RestAPI - UI : 대시보드  
5. ERD : Data(Class)
DB Schema

## 기능 설명  

**저장소에 대한 모니터링**  

1. 저장소 가상화 시 모니터링 기본 설정 필요
    trigger : Server -> Monitoring : Noti(저장소 추가/삭제)
    1. 저장소 정보 로드
    2. 저장소 모니터링 기본 설정
    3. 저장소 모니터링 시작
2. 저장소 모니터링 설정  
    설정에는 다음과 같은 부분들이 필요
    Protocol : SQL, HTTP(TCP), ICMP
    Detail Set : Query/URI
    Schedule : 1분, 1시간, .... ( crontab 양식으로 처리할 수 있도록 )
    Timeout : 30sec
    Threshold : Success, Error
3. 모니터링 결과 저장

**데이터 모니터링**  
모니터링 주기는 위에서 설정한 저장소 모니터링 주기로 동작한다.(Default)
필요한 경우 데이터 모니터링을 위한 설정에서 주기를 설정할 수 있도록 한다.

- Filter 필요(regex 로 동작, multi 허용)
  - Database
    - include  
      - ["iris", "stg-iris", "^product"]
    - exclude
      - ["test"]
  - Database Schema
  - Table
  - Path
  - File(*.md, *.docx)

1. 데이터베이스 데이터베이스/데이터베이스 스키마/테이블 모니터링
    - 마지막 상태 정보 : from fabric server에서 상태 정보 득.
        - Metadata 관리되고 있는 것과 추가해야 할 부분이 있음.
            - Database  
            - Database Schema  
            - Table  
    - 상태 정보 조회 후 변경된 경우 Fabric 서버로 Noti 전송

2. 파일(MinIO/Hadoop) 대상 모니터링
    - 마지막 상태 정보 : from fabric server에서 상태 정보 득.
      - 파일 마지막 변경 시간, 소유자, 등
    - 상태 정보 조회 후 변경된 경우 Fabric 서버로 Noti 전송

---

**UI - interface(RestAPI)**

1. 저장소 상태  
   1. Connected : 정상  
   2. Disconnected : Network 에러  
   3. Error : 인증 오류를 포함한 연결(네트워크적)은 가능하나 데이터 조회가 되지 않는 경우  

2. 저장소 내 데이터
3. ...
4. Status
    1. 연결상태  
    2. 데이터 업데이트 상태
    | time | id | name | status |
5. Stat
    1. 데이터 수  
    | time | storage_c | fabric에 등록된 데이터 수 | .... | ... |
    | time | storage_a | data_ss_count | data_xx_count | ... |
    | time | storage_b | data_ss_count | data_xx_count | ... |
    | time | storage_c | data_ss_count | data_xx_count | ... |
    | time | storage_a | data_ss_count | data_xx_count | ... |
    | time | storage_b | data_ss_count | data_xx_count | ... |
    2. 데이터 업데이트 감지 히스토리
    | time | storage_c | data_id |
    | time | storage_b | data_id |
    | time | storage_b | data_id |
    select .. from data_update_history old<time<cur
6. History
   1. 모니터링은 언제 수행했는지, 데이터 수집은 어떻게 되었는지  
7. 데이터 보관 ( 데이터 정책 )  
   1. 데이터 보관 주기  
      1. 사이즈  
      2. 시간  

---

- 작업히스토리
  - 내 작업 상태  
    - 모니터링은 작업 정보를 수신하여 관리해주면 됨.
    - Job Create : service A : Monitoring
    - Job Success : service A : Monitoring
    - Job Error : service A : Monitoring
  - 상태 조회
    - UI <- Monitoring
  - 명령 수행  
    - start, restart, stop, remove  