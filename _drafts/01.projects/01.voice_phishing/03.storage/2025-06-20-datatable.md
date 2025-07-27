
## 5. 데이터 설계

```SQL
-- 카테고리 테이블 (자기참조 계층형 구조)
CREATE TABLE category (
    category_id BIGSERIAL PRIMARY KEY,
    parent_id BIGINT REFERENCES category(category_id) ON DELETE SET NULL,
    category_name VARCHAR(50) NOT NULL,
    description TEXT
);

-- 보이스피싱 데이터 테이블
CREATE TABLE voice_phishing_data (
    id BIGSERIAL PRIMARY KEY,
    category_id BIGINT REFERENCES category(category_id) ON DELETE SET NULL,
    data_type VARCHAR(20) NOT NULL,
    received_at TIMESTAMP NOT NULL,
    sender_number VARCHAR(20),
    receiver_number VARCHAR(20),
    reply_number VARCHAR(20),
    content TEXT,
    telecom VARCHAR(50)
);

-- 파일 첨부 테이블
CREATE TABLE file_attachment (
    file_id BIGSERIAL PRIMARY KEY,
    vpd_id BIGINT NOT NULL REFERENCES voice_phishing_data(id) ON DELETE CASCADE,
    file_path TEXT NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_type VARCHAR(20),
    file_size INT,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

인덱스 추가 (계층형 탐색 및 검색 속도 향상)

```SQL
-- 카테고리 계층 탐색용 인덱스
CREATE INDEX idx_category_parent_id ON category(parent_id);

-- 보이스 피싱 데이터 검색 최적화용 인덱스
CREATE INDEX idx_vpd_received_at ON vpd_message(received_at);
CREATE INDEX idx_vpd_message_type ON vpd_message(message_type);
CREATE INDEX idx_vpd_telecom ON vpd_message(telecom);
CREATE INDEX idx_vpd_category_id ON vpd_message(category_id);
CREATE INDEX idx_vpd_sender_number ON vpd_message(sender_number);
CREATE INDEX idx_vpd_receiver_number ON vpd_message(receiver_number);

-- 파일 첨부 인덱스
CREATE INDEX idx_file_vpd_id ON file_attachment(vpd);
CREATE INDEX idx_file_type ON file_attachment(file_type);
CREATE INDEX idx_file_size ON file_attachment(file_size);
```
