---
layout: post
title: SpringBoot + Redis(pub/sub)을 이용한 채팅서버 구축
author: jblim0125
date: 2025-04-23
category: 2025
tags: [SpringBoot, Redis, Chat]
---

Spring Boot + WebSocket + Redis(Pub/Sub)를 이용한 채팅 서버 구축

## 📝 개요

이 글에서는 WebSocket과 Redis의 Pub/Sub 기능을 활용하여 실시간 채팅 서버를 구축하는 과정을 다룹니다.
Spring Boot 기반으로 구성되며, WebSocket을 통해 클라이언트-서버 간 양방향 통신을 구현하고, Redis를 통해 다중 서버 환경에서도 메시지 동기화를 실현합니다.

⸻

## 🧠 WebSocket이란?

✅ 정의

WebSocket은 HTTP와는 다르게 서버와 클라이언트가 실시간으로 양방향 통신할 수 있게 해주는 프로토콜입니다. 일반적인 HTTP 요청은 클라이언트 → 서버 방향으로만 통신하지만, WebSocket은 한 번 연결되면 서버도 클라이언트에게 자유롭게 데이터를 전송할 수 있습니다.

✅ 특징

* Persistent Connection: 초기 핸드셰이크 이후 지속적인 연결 유지
* Low Latency: 빠른 메시지 송수신
* Full-Duplex: 동시에 양방향 통신 가능

✅ 구조 예시

클라이언트 ↔ WebSocket ↔ 서버

⸻

## 🧩 Redis Pub/Sub 이란?

✅ 정의

Redis의 Pub/Sub(Publish/Subscribe)는 특정 채널에 메시지를 발행(Publish) 하고, 구독(Subscribe) 하고 있는 클라이언트가 이를 실시간으로 수신하는 메시징 시스템입니다.

✅ 작동 방식

1. 클라이언트 A가 chatroom1 채널을 구독
2. 클라이언트 B가 chatroom1 채널에 메시지를 발행
3. A는 실시간으로 해당 메시지를 수신

✅ 장점

* 서버 간 메시지 브로드캐스트 가능
* 메시지 큐 설정 없이 간단한 사용
* 실시간 반응 처리에 최적

⸻

## ⚖️ Redis Pub/Sub 장단점

| 장점                                   | 단점                                 |
| -------------------------------------- | ------------------------------------ |
| 구성 및 사용이 매우 간단함             | 메시지를 저장하지 않음 (영속성 부족) |
| 빠른 속도와 낮은 지연시간              | 메시지를 못 받은 경우 재전송 불가    |
| 서버 확장 시 유용 (멀티 인스턴스 환경) | 로드 밸런싱이 직접 구현되어야 함     |

⸻

## ⚙️ Spring Boot 설정 방법

1. 의존성 추가 (build.gradle)

    ```gradle
    dependencies {
        implementation 'org.springframework.boot:spring-boot-starter-websocket'
        implementation 'org.springframework.boot:spring-boot-starter-data-redis'
        implementation 'org.springframework.boot:spring-boot-starter'
    }
    ```

2. WebSocket 설정

    ```java
    @Configuration
    @EnableWebSocketMessageBroker
    public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

        @Override
        public void configureMessageBroker(MessageBrokerRegistry registry) {
            // Redis를 쓰는 경우, 외부 브로커 대신 핸들링
            registry.enableSimpleBroker("/topic"); 
            registry.setApplicationDestinationPrefixes("/app");
        }

        @Override
        public void registerStompEndpoints(StompEndpointRegistry registry) {
            registry.addEndpoint("/ws-chat")
                    .setAllowedOriginPatterns("*")
                    .withSockJS();
        }
    }
    ```

3. Redis 설정

    ```yaml
    # application.yml
    spring:
    redis:
        host: localhost
        port: 6379
    ```

    ```java
    @Configuration
    public class RedisConfig {
        @Bean
        public RedisConnectionFactory redisConnectionFactory() {
            return new LettuceConnectionFactory();
        }

        @Bean
        public RedisTemplate<String, Object> redisTemplate() {
            RedisTemplate<String, Object> redisTemplate = new RedisTemplate<>();
            redisTemplate.setConnectionFactory(redisConnectionFactory());
            return redisTemplate;
        }
    }
    ```

4. 채팅 메시지 처리

    ```java
    @Data
    public class ChatMessage {
        private String roomId;
        private String sender;
        private String message;
    }
    ```

5. Redis Pub/Sub 리스너 구성

    ```java
    @Service
    @RequiredArgsConstructor
    public class RedisSubscriber implements MessageListener {

        private final SimpMessageSendingOperations messagingTemplate;

        @Override
        public void onMessage(Message message, byte[] pattern) {
            String msg = new String(message.getBody());
            ChatMessage chatMessage = new Gson().fromJson(msg, ChatMessage.class);
            messagingTemplate.convertAndSend("/topic/chatroom/" + chatMessage.getRoomId(), chatMessage);
        }
    }
    ```

## 📦 아키텍처 구성

```text
[Client]
   |
[WebSocket 연결]
   |
[Spring Boot 서버] <----> [Redis Pub/Sub] <----> [다른 서버 인스턴스들]
```

## 💬 Spring Boot + Redis 기반 채팅 서버 심화편

* 채팅방(Room) 관리 방법
* 시간 정보를 포함한 메시지 포맷 설계
* 사용자 세션 추적이란? 어떻게 활용하는가?

## 🏠 채팅방(Room) 관리 방법

✅ 왜 채팅방 관리가 필요한가?

여러 명이 각기 다른 주제로 대화하는 채널을 원할 경우, 채팅방을 개별적으로 관리해야 합니다. 예를 들어:

* 채팅방 목록 조회
* 채팅방 생성 및 삭제
* 사용자 → 채팅방 입장 / 퇴장

✅ 채팅방 모델 정의

```java
@Data
@AllArgsConstructor
@NoArgsConstructor
public class ChatRoom {
    private String roomId;
    private String name;
}
```

✅ 채팅방 저장 및 조회

1. 컨트롤러  

    ```java
    @RestController
    @RequestMapping("/api/chatrooms")
    @RequiredArgsConstructor
    public class ChatRoomRestController {

        private final ChatRoomRepository chatRoomRepository;

        @GetMapping
        public List<ChatRoom> getAllRooms() {
            return chatRoomRepository.findAllRoom();
        }

        @GetMapping("/{roomId}")
        public ChatRoom getRoom(@PathVariable String roomId) {
            return chatRoomRepository.findRoomById(roomId);
        }
    }
    ```

2. 레파지토리

    ```java
    @Repository
    public class ChatRoomRepository {

        private Map<String, ChatRoom> chatRoomMap = new ConcurrentHashMap<>();

        public List<ChatRoom> findAllRoom() {
            return new ArrayList<>(chatRoomMap.values());
        }

        public ChatRoom findRoomById(String roomId) {
            return chatRoomMap.get(roomId);
        }

        public ChatRoom createChatRoom(String name) {
            String roomId = UUID.randomUUID().toString();
            ChatRoom chatRoom = new ChatRoom(roomId, name);
            chatRoomMap.put(roomId, chatRoom);
            return chatRoom;
        }
    }
    ```

> 실제 운영 환경에서는 Redis나 DB에 채팅방 정보를 저장하는 것이 안전합니다.

### 채팅방 조회 -> 입장 -> 메시지 송수신

```text
1. 조회
    Client -HTTP-> Server : GET /api/chatrooms
2. 구독
    Client -WebSocket-> Server : /topic/chatroom/{roomId}
3. 입장
    Client -WebSocket-> Server : /app/chat/message
4. 메시지 전송
    Client -WebSocket-> Server : /app/chat/message
```

### 생략된 부분 : STOMP 사용에 따른 숨겨진 부분

클라이언트에서 `/topic/chatroom/{roomId}` 형태로 구독 시 채팅방에 입장한 것(메시지 수신)에 대해
이 부분을 처리하는 코드를 작성할 필요가 없다.  왜냐하면 Spring WebSocket(STOMP)의 구조에서는
구독 경로(/topic/...)는 서버에서 자동으로 브로드캐스팅 처리 대상이 되기 때문입니다.

📡 /topic/chatroom/{roomId}는 누가 처리하나요?

✅ 구독 경로는 브로커가 처리한다

Spring에서 WebSocket 설정할 때 아래와 같은 설정이 있죠:

```java
@Override
public void configureMessageBroker(MessageBrokerRegistry registry) {
    registry.enableSimpleBroker("/topic"); // 메시지를 브로드캐스트할 prefix
    registry.setApplicationDestinationPrefixes("/app"); // 클라이언트 요청 prefix
}
```

* /app: 클라이언트 → 서버로 전달되는 경로 (예: @MessageMapping)
* /topic: 서버 → 클라이언트로 broadcast되는 경로 (메시지 브로커가 전담)

즉, 클라이언트가 `/topic/chatroom/{roomId}`를 구독하고 있으면,
서버에서 아래처럼 메시지를 보내는 것만으로도 자동으로 해당 경로로 브로드캐스트 됩니다.

```java
messagingTemplate.convertAndSend("/topic/chatroom/" + chatMessage.getRoomId(), chatMessage);
```

이 라인이 실질적인 처리 코드인 셈이죠.

🧠 메시지 흐름 다시 정리

1. 클라이언트가 /app/chat/message 로 메시지 전송
2. @MessageMapping("/chat/message") → ChatController 에서 처리
3. RedisPublisher → Redis에 JSON 메시지 publish
4. RedisSubscriber 가 Redis로부터 수신
5. messagingTemplate.convertAndSend("/topic/chatroom/{roomId}") 호출
6. 구독 중인 모든 클라이언트에게 브로드캐스트

즉, /topic/... 구독에 대한 직접적인 컨트롤러는 필요하지 않고,
브로커(SimpleBroker 또는 외부 메시지 브로커)가 알아서 구독 클라이언트에게 메시지를 전송합니다.

💡 추가 팁

* 브로커를 직접 구현하고 싶다면 SimpleBroker 대신 RabbitMQ, Kafka 등 외부 브로커를 설정할 수도 있습니다.
* 메시지 가공(예: 필터링, 포맷 변경 등)을 하고 싶다면 RedisSubscriber 또는 ChatController 단계에서 처리하면 됩니다.

### 🕒 시간 정보가 포함된 메시지 포맷

✅ 시간 정보는 왜 필요한가?

* 채팅 메시지를 정렬할 수 있습니다.
* 사용자에게 언제 보낸 메시지인지 직관적으로 보여줍니다.
* 로그 및 분석 용도로 활용됩니다.

✅ 메시지 모델 확장

```java
@Data
public class ChatMessage {
    private String roomId;
    private String sender;
    private String message;
    private MessageType type; // ENTER, TALK, LEAVE
    private String timestamp; // 시간 정보

    public enum MessageType {
        ENTER, TALK, LEAVE
    }
}
```

✅ 시간 포맷 예시

```java
String timestamp = LocalDateTime.now()
        .format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
```

✅ 마무리

* 채팅방을 직접 생성하고 관리함으로써 유연한 대화 기능을 제공할 수 있습니다.
* 메시지에 시간 정보를 포함하면 사용자 경험 및 분석에도 큰 도움이 됩니다.
* 사용자 세션 추적을 통해 접속 상태 및 이벤트를 정확히 관리할 수 있습니다.
