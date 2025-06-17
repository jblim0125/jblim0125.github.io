# 보이스피싱 데이터베이스 설계서

## 개요

보이스피싱 데이터 저장소 설계서

## 1. 데이터베이스 구조

```planturml
@startuml
!define table(x) class x << (T,#FFAAAA) >>
!define primary_key(x) <u>x</u>

table(reports) {
  primary_key(id): BIGINT
  reporter_name: VARCHAR(100)
  contact_type: ENUM('음성','문자')
  reporter_phone: VARCHAR(20)
  reporter_email: VARCHAR(100)
  received_at: DATETIME
  spammer_phone: VARCHAR(20)
  report_type: VARCHAR(100)
  report_content: TEXT
  created_at: TIMESTAMP
}

table(attachments) {
  primary_key(id): BIGINT
  report_id: BIGINT
  file_type: ENUM('통화기록','녹음파일')
  file_name: VARCHAR(255)
  bucket_name: VARCHAR(100)
  object_key: VARCHAR(255)
  content_type: VARCHAR(100)
  file_size: BIGINT
  uploaded_at: TIMESTAMP
}

table(report_categories) {
  primary_key(id): INT
  category: VARCHAR(100)
  parent_category: VARCHAR(100)
}

'relations
reports ||--o{ attachments : contains
@enduml
```

## 2. SQL 스크립트

```SQL
CREATE TABLE report_categories (
  id INT PRIMARY KEY AUTO_INCREMENT,
  category VARCHAR(100) UNIQUE NOT NULL,
  parent_category VARCHAR(100)
);

CREATE TABLE reports (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  reporter_name VARCHAR(100) NOT NULL,
  contact_type ENUM('음성', '문자') NOT NULL,
  reporter_phone VARCHAR(20) NOT NULL,
  reporter_email VARCHAR(100),
  received_at DATETIME NOT NULL,
  spammer_phone VARCHAR(20),
  report_type VARCHAR(100),
  report_content TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE attachments (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  report_id BIGINT NOT NULL,
  file_type ENUM('통화기록', '녹음파일') NOT NULL,
  file_name VARCHAR(255) NOT NULL,
  bucket_name VARCHAR(100) NOT NULL,
  object_key VARCHAR(255) NOT NULL,
  content_type VARCHAR(100),
  file_size BIGINT,
  uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (report_id) REFERENCES reports(id) ON DELETE CASCADE
);
```

## 3. 오브젝트 데이터 저장 프로세스 설계

### 고려사항

1. 데이터 중복 방지  
    동일한 파일(내용 기반)이 여러 번 저장되지 않도록 해시(SHA256 등) 를 사용해 고유성을 판별  
2. 하나의 디렉토리(버킷 내 prefix)당 최대 파일 수 제한  
    예: /media/YYYY/MM/DD/NNNN/처럼 경로를 분산시켜 파일 수 제한 회피 (NNNN은 인덱스 혹은 해시 prefix 등)
3. 파일 경로 재사용 방지
    기존 경로 존재 시 저장하지 않거나, 별도로 관리

### 슈도 코드

```text
function upload_to_minio(file):
    1. 해시 = SHA256(file content)
    2. 파일 확장자 = extract_extension(file.name)

    3. 날짜 기반 prefix = /media/YYYY/MM/DD/
    4. 해시 prefix 디렉토리 = 해시 앞 4자리 (예: ab12)

    5. full_path = prefix + hash_prefix + "/" + hash + "." + 확장자

    6. MinIO에 해당 path 존재 여부 확인
        → 존재하면: 중복으로 간주, 업로드하지 않음
        → 없으면: 업로드 진행

    7. 업로드 후 full_path를 DB에 저장
```
