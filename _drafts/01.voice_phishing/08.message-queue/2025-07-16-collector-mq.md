# 메시지큐를 이용한 분산 처리

## 개요

Collector는 클라이언트로부터 REST API(Multipart/formdata)를 통해 보이스 피싱 데이터를 전달받아
MinIO에 파일을 저장하고, 데이터베이스 저장 및 기타 처리를 다른 서비스로 요청합니다.

## Collector - Exchange - Queue 관계

아래와 같이 exchange와 queue를 정의하여, 업로드 수신 서비스(Collector)와 데이터 처리 서비스가 N:N 관계로 자유롭게 확장되고, 메시지가 고르게 분산 처리될 수 있도록 설계합니다.

- vhost는 `voice-phishing`으로 설정합니다.
- 모든 Collector는 동일한 exchange로 메시지를 발행합니다.
- 데이터 처리 서비스(Worker)는 각자 별도의 queue를 생성하고, 해당 queue를 동일한 exchange에 바인딩합니다.
- 라우팅 키(routing key)는 단순하게 설정하거나, 필요에 따라 고정값을 사용합니다.
- exchange 타입은 direct 또는 fanout을 사용할 수 있으며, 일반적으로 direct 타입을 사용하여 여러 queue에 메시지를 분산시킵니다.

**예시 설계:**  

- Exchange 이름: `process.exchange`
- Queue 이름: `process.queue.<worker>` (예: process.queue.worker1, process.queue.worker2)
- 라우팅 키: `process` (모든 메시지에 동일하게 사용)

```text
Collector1 ──┐
             ├──► process.exchange ──► process.queue.worker1 - worker1
Collector2 ──┘                        └──► process.queue.worker2 - worker2
```

**설계의 핵심 포인트:**  

1. 모든 Collector는 동일한 exchange 사용
    - Exchange 이름: process.exchange
    - Collector1, Collector2 모두 이 exchange로 메시지 발행
2. 메시지 분산 처리
    - 각 Worker는 자신만의 queue를 가짐 (process.queue.worker1, process.queue.worker2)
    - 모든 queue가 동일한 exchange에 바인딩됨
    - 라우팅 키가 동일하므로 (process) 메시지가 모든 queue로 분산됨
3. 확장성
    - Collector를 추가해도 동일한 exchange 사용
    - Worker를 추가해도 새로운 queue만 생성하여 exchange에 바인딩

이 구조를 통해 Collector와 데이터 처리 서비스(Worker)가 자유롭게 추가/확장될 수 있으며, 각 queue로 메시지가 분산되어 병렬로 처리됩니다.
