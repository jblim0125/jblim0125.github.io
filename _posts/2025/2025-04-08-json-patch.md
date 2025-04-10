---
layout: post
title: JSON Patch 를 이용한 데이터 수정
author: jblim0125
date: 2025-04-08
category: 2025
tags: [JSONPatch]
---

## 개요

클라이언트 - 서버 간 데이터 변경 시 리스트 형태의 데이터 중 일부를
변경하는 경우, 전체 데이터를 주고 받는 것은 비효율적이므로 변경 정보만을 송수신하여 데이터를 변경할 수 있도록 한다.

## 예제

- 샘플 데이터  

```JSON
// 샘플 데이터 (User JSON)
{
  "id": 1,
  "name": "Alice",
  "email": "alice@example.com",
  "profile": {
    "bio": "Hello!",
    "href": "/user/1"
  }
}
```

- 의존성

```gradle
dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-web'
    implementation 'com.github.fge:json-patch:1.9'
    implementation 'com.fasterxml.jackson.core:jackson-databind'
}
```

- User 도메인 모델

```java
@Data
@NoArgsConstructor
@AllArgsConstructor
public class User {
    private int id;
    private String name;
    private String email;
    private Profile profile;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Profile {
        private String bio;
        private String href;
    }
}
```

조건 : 위 데이터 중 id, href 는 변경될 수 없다.

- UserController

```java
@RestController
@RequestMapping("/api/users")
public class UserController {

    private final ObjectMapper objectMapper = new ObjectMapper();
    private User storedUser = new User(
        1, "Alice", "alice@example.com", new User.Profile("Hello!", "/user/1")
    );

    @GetMapping("/{id}")
    public ResponseEntity<User> getUser(@PathVariable int id) {
        return ResponseEntity.ok(storedUser);
    }

    @PatchMapping(path = "/{id}", consumes = "application/json-patch+json")
    public ResponseEntity<User> patchUser(@PathVariable int id,
                                          @RequestBody JsonPatch patch) throws Exception {
        // 필터링 (id, href 관련 patch 제거)
        List<JsonNode> filteredOps = new ArrayList<>();
         String patchString = objectMapper.writeValueAsString(patch);
        JsonNode patchNode = objectMapper.readTree(patchString);
        for (JsonNode op : patchNode) {
            String path = op.get("path").asText();
            if (!path.equals("id") && !path.matches(".*/href$") ) {
                filteredOps.add(op);
            }
        }

        JsonNode filteredPatch = objectMapper.valueToTree(filteredOps);
        JsonPatch patch = JsonPatch.fromJson(filteredPatch);

        JsonNode original = objectMapper.valueToTree(storedUser);
        JsonNode patched = patch.apply(original);
        storedUser = objectMapper.treeToValue(patched, User.class);

        return ResponseEntity.ok(storedUser);
    }
}
```

- 클라이언트 샘플

다음 JSONPatch 내용은 `/name` 을 Alice -> Bob 으로 변경하고,
`/profile/href` 를 변경하는 JSONPatch 이다.

```json
[
  { "op": "replace", "path": "/name", "value": "Bob" },
  { "op": "replace", "path": "/profile/href", "value": "/new/href" }
]
```

```java
WebClient client = WebClient.create();

JsonNode patchBody = objectMapper.readTree("""
[
  { "op": "replace", "path": "/name", "value": "Bob" },
  { "op": "replace", "path": "/profile/href", "value": "/new/href" }
]
""");

User result = client.patch()
    .uri("http://localhost:8080/api/users/1")
    .header(HttpHeaders.CONTENT_TYPE, "application/json-patch+json")
    .bodyValue(patchBody)
    .retrieve()
    .bodyToMono(User.class)
    .block();

System.out.println("Patched user: " + result);
```

## 참고사항

1. application/json-patch+json 은 표준 MIME 타입입니다.
2. JSONPatch 시 Filtering 을 이용하면 서버 쪽에서 읽기 전용 필드를 보호할 수 있어 안전합니다.