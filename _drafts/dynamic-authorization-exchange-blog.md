# Spring Cloud Gateway의 Dynamic Authorization Exchange 구현하기

## 개요

Spring Cloud Gateway에서 동적 인가(Dynamic Authorization)를 구현하는 것은 마이크로서비스 아키텍처에서 매우 중요한 보안 요소입니다.
이 글에서는 Spring Security의 `SecurityWebFilterChain`을 기반으로 한 동적 인가 시스템의 구현 방법과 동작 원리를 자세히 살펴보겠습니다.

## 1. SecurityWebFilterChain이란?

### 1.1 기본 개념

`SecurityWebFilterChain`은 Spring Security WebFlux에서 사용하는 필터 체인의 핵심 구성 요소입니다.
이는 기존의 Servlet 기반 `FilterChainProxy`의 WebFlux 버전으로, 비동기 리액티브 환경에서 보안 필터들을 체인 형태로 연결하여 요청을 처리합니다.

```java
@Configuration
@EnableWebFluxSecurity
public class SecurityConfiguration {

    @Bean
    public SecurityWebFilterChain securityWebFilterChain(
            ServerHttpSecurity http,
            KeycloakRoleConverter keycloakRoleConverter,
            DynamicAuthorizationManager dynamicAuthorizationManager,
            DynamicAuthorizationService authorizationService) {

        return http
                .authorizeExchange(ex -> ex
                        .anyExchange().access(dynamicAuthorizationManager))  // 동적 인가 위임
                .oauth2ResourceServer(oauth2Resource -> oauth2Resource
                        .jwt(jwtSpec -> jwtSpec.jwtAuthenticationConverter(
                                new ReactiveJwtAuthenticationConverterAdapter(jwtAuthConv))))
                .cors(ServerHttpSecurity.CorsSpec::disable)
                .csrf(ServerHttpSecurity.CsrfSpec::disable)
                .build();
    }
}
```

### 1.2 주요 구성 요소

- **Authentication**: 사용자 인증 처리
- **Authorization**: 사용자 인가 처리
- **OAuth2 Resource Server**: JWT 토큰 기반 인증
- **CORS/CSRF**: 보안 정책 설정

## 2. 데이터 스키마 설계

### 2.1 AuthorizationRule 엔티티

동적 인가를 위한 핵심 데이터 모델입니다:

```java
@Data
@Table("authorization_rule")
public class AuthorizationRule {

    public enum Action {
        PERMIT,           // 무조건 허용
        AUTHENTICATED,    // 인증된 사용자만 허용
        DENY,             // 무조건 거부
        HAS_ANY_ROLE,     // 지정된 역할 또는 그룹 중 하나라도 있으면 허용
        HAS_ALL_ROLES     // 지정된 모든 역할과 그룹이 있어야 허용
    }

    @Id
    @Column("id")
    public Integer id;

    @Column("pattern")
    public String pattern;        // URL 패턴 (예: /api-gateway/api/**)

    @Column("methods")
    public String methods;        // HTTP 메서드 (예: GET,POST, NULL이면 모든 메서드)

    @Column("action")
    public Action action;         // 인가 액션

    @Column("roles")
    public String roles;          // 역할 목록 (콤마 구분, 예: ROLE_SYSTEM_MANAGER,ROLE_ADMIN)

    @Column("groups")
    public String groups;         // 그룹 목록 (콤마 구분, 예: GROUP_ADMIN,GROUP_USER)

    @Column("priority")
    public Integer priority;      // 우선순위 (낮을수록 먼저 평가)

    @Column("enabled")
    public Boolean enabled;       // 활성화 여부

    @Column("created_at")
    public LocalDateTime createdAt;

    @Column("updated_at")
    public LocalDateTime updatedAt;
}
```

### 2.2 데이터베이스 스키마

```sql
CREATE TABLE IF NOT EXISTS AUTHORIZATION_RULE (
     id SERIAL PRIMARY KEY,
     pattern VARCHAR(255) NOT NULL,                -- 예: /API-GATEWAY/ACTUATOR/**, /API-GATEWAY/API/**, /**
     methods VARCHAR(255) NULL,                    -- 콤마구분: GET,POST  (NULL이면 모든 메서드)
     action VARCHAR(50) NOT NULL,                  -- PERMIT, AUTHENTICATED, DENY, HAS_ANY_ROLE, HAS_ALL_ROLES
     roles VARCHAR(500) NULL,                      -- 콤마구분: ROLE_SYSTEM_MANAGER,ROLE_ADMIN ...
     groups VARCHAR(500) NULL,                     -- 콤마구분: GROUP_ADMIN,GROUP_USER (roles와 함께 사용 가능)
     priority INT NOT NULL DEFAULT 100,            -- 낮을수록 먼저 평가(첫 매칭 우선)
     enabled BOOLEAN NOT NULL DEFAULT TRUE,
     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
     updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 초기 규칙 (V2__authorization.sql)
INSERT INTO AUTHORIZATION_RULE(pattern, methods, action, roles, priority) VALUES
 ('/api-gateway/actuator/health',                     NULL, 'PERMIT',               NULL, 10),
 ('/api-gateway/api/v1/authentication/login',         NULL, 'PERMIT',               NULL, 10),
 ('/api-gateway/api/v1/authentication/refresh-token', NULL, 'PERMIT',               NULL, 10),
 ('/api-gateway/api/v1/authentication/logout',        NULL, 'AUTHENTICATED',        NULL, 10),
 ('/api-gateway/api/**',                              NULL, 'HAS_ANY_ROLE',     'ROLE_SYSTEM_MANAGER', 50),
 ('/**',                                              NULL, 'AUTHENTICATED',        NULL, 1000);
```

**참고**: 모든 경로는 `spring.webflux.base-path` 설정(`/api-gateway`)을 포함한 전체 경로를 사용합니다.

## 3. 동적 인가 시스템 구현

### 3.1 DynamicAuthorizationService

인가 규칙을 관리하고 컴파일하는 서비스입니다:

```java
@Service
public class DynamicAuthorizationService {

    public record CompiledRule(
            PathPattern pattern,
            Set<HttpMethod> methods,                 // empty = any
            AuthorizationRule.Action action,
            Set<String> roles,                       // normalized: ROLE_*
            Set<String> groups                       // normalized: GROUP_*
    ) {
        public boolean matches(String path, HttpMethod method) {
            if (!pattern.matches(PathContainerHolder.path(path))) return false;
            return methods.isEmpty() || (method != null && methods.contains(method));
        }
    }

    private final AuthorizationRepository repo;
    private final AtomicReference<List<CompiledRule>> cache = new AtomicReference<>(List.of());
    private final PathPatternParser parser;

    public DynamicAuthorizationService(AuthorizationRepository repo) {
        this.repo = repo;
        this.parser = new PathPatternParser();
    }

    public Mono<Void> reload() {
        return repo.findByEnabledTrueOrderByPriorityAsc()
                .map(this::compile)
                .collectList()
                .doOnNext(cache::set)
                .then();
    }

    public List<CompiledRule> current() {
        return cache.get();
    }

    private CompiledRule compile(AuthorizationRule r) {
        var pp = parser.parse(r.pattern);
        Set<HttpMethod> methods = parseMethods(r.methods);
        Set<String> roles = parseRoles(r.roles);
        Set<String> groups = parseGroups(r.groups);
        return new CompiledRule(pp, methods, r.action, roles, groups);
    }

    // 역할 정규화: ROLE_ 접두사 자동 추가
    private static Set<String> parseRoles(String s) {
        if (s == null || s.isBlank()) return Set.of();
        return Arrays.stream(s.split(","))
                .map(String::trim)
                .filter(v -> !v.isEmpty())
                .map(v -> v.startsWith("ROLE_") ? v : "ROLE_" + v)
                .collect(toSet());
    }

    // 그룹 정규화: GROUP_ 접두사 자동 추가, 대문자 변환
    private static Set<String> parseGroups(String s) {
        if (s == null || s.isBlank()) return Set.of();
        return Arrays.stream(s.split(","))
                .map(String::trim)
                .filter(v -> !v.isEmpty())
                .map(v -> {
                    String normalized = v.toUpperCase().replace("-", "_");
                    return normalized.startsWith("GROUP_") ? normalized : "GROUP_" + normalized;
                })
                .collect(toSet());
    }
}
```

### 3.2 DynamicAuthorizationManager

실제 인가 결정을 수행하는 매니저입니다:

```java
@Component
public class DynamicAuthorizationManager implements ReactiveAuthorizationManager<AuthorizationContext> {

    private final DynamicAuthorizationService rules;

    @Override
    public Mono<AuthorizationResult> authorize(Mono<Authentication> authentication, AuthorizationContext ctx) {
        var req = ctx.getExchange().getRequest();
        var path = req.getPath().value();  // 전체 경로 사용
        HttpMethod method = req.getMethod();

        List<DynamicAuthorizationService.CompiledRule> list = rules.current();

        for (var r : list) {
            if (!r.matches(path, method)) continue;

            return switch (r.action()) {
                case PERMIT -> {
                    log.debug("Access granted by PERMIT rule for path: {} method: {}", path, method);
                    yield Mono.<AuthorizationResult>just(new AuthorizationDecision(true));
                }
                case DENY -> {
                    log.warn("Access denied by DENY rule for path: {} method: {}", path, method);
                    yield Mono.<AuthorizationResult>error(new AccessDeniedException("접근이 거부되었습니다"));
                }
                case AUTHENTICATED -> authentication
                        .filter(Authentication::isAuthenticated)
                        .map(auth -> {
                            log.debug("Access granted for authenticated user: {} to path: {}", auth.getName(), path);
                            return (AuthorizationResult) new AuthorizationDecision(true);
                        })
                        .switchIfEmpty(Mono.error(new ResponseStatusException(
                                HttpStatus.UNAUTHORIZED, "인증이 필요합니다")));
                case HAS_ANY_ROLE -> authentication
                        .filter(Authentication::isAuthenticated)
                        .map(auth -> {
                            boolean hasRole = hasAny(auth, r.roles(), r.groups());
                            if (hasRole) {
                                log.debug("Access granted for user: {} with roles: {} or groups: {} to path: {}",
                                        auth.getName(), r.roles(), r.groups(), path);
                                return (AuthorizationResult) new AuthorizationDecision(true);
                            } else {
                                log.warn("Access denied for user: {} - missing required roles: {} or groups: {} for path: {}",
                                        auth.getName(), r.roles(), r.groups(), path);
                                throw new AccessDeniedException("필요한 권한이 없습니다: roles=" + r.roles() + ", groups=" + r.groups());
                            }
                        })
                        .switchIfEmpty(Mono.error(new ResponseStatusException(
                                HttpStatus.UNAUTHORIZED, "인증이 필요합니다")));
                case HAS_ALL_ROLES -> authentication
                        .filter(Authentication::isAuthenticated)
                        .map(auth -> {
                            boolean hasAllRoles = hasAll(auth, r.roles(), r.groups());
                            if (hasAllRoles) {
                                log.debug("Access granted for user: {} with all roles: {} and groups: {} to path: {}",
                                        auth.getName(), r.roles(), r.groups(), path);
                                return (AuthorizationResult) new AuthorizationDecision(true);
                            } else {
                                log.warn("Access denied for user: {} - missing required roles: {} or groups: {} for path: {}",
                                        auth.getName(), r.roles(), r.groups(), path);
                                throw new AccessDeniedException("필요한 모든 권한이 없습니다: roles=" + r.roles() + ", groups=" + r.groups());
                            }
                        })
                        .switchIfEmpty(Mono.error(new ResponseStatusException(
                                HttpStatus.UNAUTHORIZED, "인증이 필요합니다")));
            };
        }

        // fallback: 인증 필요
        log.debug("No specific rule found for path: {} method: {}, requiring authentication", path, method);
        return authentication
                .filter(Authentication::isAuthenticated)
                .map(auth -> {
                    log.debug("Access granted for authenticated user: {} to path: {} (fallback)", auth.getName(), path);
                    return (AuthorizationResult) new AuthorizationDecision(true);
                })
                .switchIfEmpty(Mono.error(new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED, "인증이 필요합니다")));
    }

    // 역할 또는 그룹 중 하나라도 있으면 true
    private static boolean hasAny(Authentication auth, Collection<String> roles, Collection<String> groups) {
        boolean rolesEmpty = roles == null || roles.isEmpty();
        boolean groupsEmpty = groups == null || groups.isEmpty();
        if (rolesEmpty && groupsEmpty) return auth != null && auth.isAuthenticated();
        if (auth == null || !auth.isAuthenticated()) return false;
        var have = auth.getAuthorities().stream().map(GrantedAuthority::getAuthority).toList();
        // Check roles
        if (roles != null && !roles.isEmpty()) {
            for (String n : roles) if (have.contains(n)) return true;
        }
        // Check groups
        if (groups != null && !groups.isEmpty()) {
            for (String n : groups) if (have.contains(n)) return true;
        }
        return false;
    }

    // 모든 역할과 그룹이 있어야 true
    private static boolean hasAll(Authentication auth, Collection<String> roles, Collection<String> groups) {
        boolean rolesEmpty = roles == null || roles.isEmpty();
        boolean groupsEmpty = groups == null || groups.isEmpty();
        if (rolesEmpty && groupsEmpty) return auth != null && auth.isAuthenticated();
        if (auth == null || !auth.isAuthenticated()) return false;
        var have = auth.getAuthorities().stream().map(GrantedAuthority::getAuthority).toList();
        // Check all roles
        if (roles != null && !roles.isEmpty()) {
            for (String n : roles) if (!have.contains(n)) return false;
        }
        // Check all groups
        if (groups != null && !groups.isEmpty()) {
            for (String n : groups) if (!have.contains(n)) return false;
        }
        return true;
    }
}
```

## 4. 필터 체인과 동작 순서

### 4.1 전체 필터 체인 구조

Spring Cloud Gateway에서 요청이 처리되는 순서는 다음과 같습니다:

```text
1. TracingLoggingFilter (Order: HIGHEST_PRECEDENCE) -> 커스텀으로 추가한 필터
   ↓
2. TokenRefreshFilter (Order: HIGHEST_PRECEDENCE) -> 커스텀으로 추가한 필터
   ↓
3. Spring Security Filters
   - AuthenticationWebFilter (-100)
   - AuthorizationWebFilter (-1)
   ↓
4. UserProfileRelayFilter (Order: LOWEST_PRECEDENCE) -> 커스텀으로 추가한 필터
   ↓
5. Gateway Filters
   ↓
6. Backend Service
```

### 4.2 각 필터의 역할

#### 4.2.1 TracingLoggingFilter

```java
@Component
public class TracingLoggingFilter implements GlobalFilter, Ordered {

    @Override
    public int getOrder() {
        return Ordered.HIGHEST_PRECEDENCE; // 가장 먼저 실행
    }

    // 요청 추적 및 로깅
}
```

#### 4.2.2 TokenRefreshFilter

```java
@Component
public class TokenRefreshFilter implements WebFilter, Ordered {

    @Override
    public int getOrder() {
        return -101; // Spring Security의 AuthenticationWebFilter(-100)보다 먼저 실행
    }

    // JWT 토큰 자동 갱신 처리
}
```

#### 4.2.3 AuthorizationWebFilter

Spring Security의 인가 필터로, `DynamicAuthorizationManager`를 통해 동적 인가를 수행합니다.

#### 4.2.4 UserProfileRelayFilter

```java
@Component
public class UserProfileRelayFilter implements GlobalFilter, Ordered {

    @Override
    public int getOrder() {
        return Ordered.LOWEST_PRECEDENCE; // 가장 나중에 실행
    }

    // 인증된 사용자 정보를 헤더에 주입
}
```

### 4.3 인가 처리 흐름

1. **요청 수신**: 클라이언트로부터 HTTP 요청 수신
2. **토큰 갱신**: `TokenRefreshFilter`에서 JWT 토큰 자동 갱신
3. **인증 처리**: Spring Security에서 JWT 토큰 검증 및 사용자 인증
4. **인가 처리**: `DynamicAuthorizationManager`에서 동적 인가 규칙 적용
5. **사용자 정보 주입**: `UserProfileRelayFilter`에서 사용자 정보를 헤더에 추가
6. **백엔드 호출**: 인가된 요청을 백엔드 서비스로 전달

## 5. JWT 토큰과 권한 변환

### 5.1 KeycloakRoleConverter

Keycloak에서 발급한 JWT 토큰의 클레임을 Spring Security의 권한으로 변환합니다:

```java
@Component
public class KeycloakRoleConverter implements Converter<Jwt, Collection<GrantedAuthority>> {

    @Override
    public Collection<GrantedAuthority> convert(Jwt jwt) {
        var authorities = new ArrayList<GrantedAuthority>();

        // 1. Keycloak user-roles 클레임
        List<String> userRoles = jwt.getClaimAsStringList("user-roles");
        if (userRoles != null) {
            userRoles.forEach(role -> {
                String authority = "ROLE_" + role.toUpperCase().replace("-", "_");
                authorities.add(new SimpleGrantedAuthority(authority));
            });
        }

        // 2. Keycloak groups 클레임
        List<String> groups = jwt.getClaimAsStringList("groups");
        if (groups != null) {
            groups.forEach(group -> {
                String groupName = group.startsWith("/") ? group.substring(1) : group;
                String authority = "GROUP_" + groupName.toUpperCase().replace("-", "_");
                authorities.add(new SimpleGrantedAuthority(authority));
            });
        }

        return authorities;
    }
}
```

### 5.2 JWT 클레임 구조

Keycloak JWT 토큰의 주요 클레임들:

```json
{
  "sub": "user-uuid",
  "email": "user@example.com",
  "user-roles": ["system-manager", "admin"],
  "groups": ["/managers", "/developers"],
  "realm_access": {
    "roles": ["offline_access", "uma_authorization"]
  },
  "resource_access": {
    "client-id": {
      "roles": ["view-profile", "manage-account"]
    }
  }
}
```

### 5.3 역할과 그룹 정규화

`KeycloakRoleConverter`와 `DynamicAuthorizationService`에서 역할과 그룹을 자동으로 정규화합니다:

- **역할(Roles)**: `ROLE_` 접두사 자동 추가
  - 입력: `system-manager` → 변환: `ROLE_SYSTEM_MANAGER`
  - 입력: `ROLE_ADMIN` → 그대로 유지: `ROLE_ADMIN`

- **그룹(Groups)**: `GROUP_` 접두사 자동 추가, 대문자 변환
  - 입력: `/managers` → 변환: `GROUP_MANAGERS`
  - 입력: `admin-group` → 변환: `GROUP_ADMIN_GROUP`
  - 입력: `GROUP_USER` → 그대로 유지: `GROUP_USER`

이 정규화를 통해 인가 규칙에서 일관된 형식으로 역할과 그룹을 비교할 수 있습니다.

## 6. 성능 최적화

### 6.1 규칙 캐싱

인가 규칙을 메모리에 캐싱하여 데이터베이스 조회를 최소화합니다:

```java
private final AtomicReference<List<CompiledRule>> cache = new AtomicReference<>(List.of());

public List<CompiledRule> current() {
    return cache.get(); // 메모리에서 즉시 반환
}

public Mono<Void> reload() {
    return repo.findByEnabledTrueOrderByPriorityAsc()
            .map(this::compile)
            .collectList()
            .doOnNext(cache::set) // 캐시 업데이트
            .then();
}
```

### 6.2 PathPattern 컴파일

URL 패턴을 미리 컴파일하여 매칭 성능을 향상시킵니다:

```java
private CompiledRule compile(AuthorizationRule r) {
    var pp = parser.parse(r.pattern); // 패턴 컴파일
    Set<HttpMethod> methods = parseMethods(r.methods);
    Set<String> roles = parseRoles(r.roles);
    return new CompiledRule(pp, methods, r.action, roles);
}
```

## 7. 관리 API

### 7.1 AuthorizationController

동적 인가 규칙을 관리하기 위한 REST API를 제공합니다:

```java
@RestController
@RequestMapping("/api/v1/authorization")
public class AuthorizationController {

    public record UpsertReq(
            @NotBlank String pattern,
            String methods,
            @NotNull AuthorizationRule.Action action,
            String roles,
            String groups,
            @NotNull Integer priority,
            @NotNull Boolean enabled
    ) {}

    private final AuthorizationRepository repo;
    private final DynamicAuthorizationService rules;

    // 규칙 목록 조회
    @GetMapping("/rules")
    public Flux<AuthorizationRule> list() {
        return repo.findByEnabledTrueOrderByPriorityAsc();
    }

    // 규칙 조회 (ID로)
    @GetMapping("/rules/{id}")
    public Mono<AuthorizationRule> getById(@PathVariable Integer id) {
        return repo.findById(id)
                .switchIfEmpty(Mono.error(new IllegalArgumentException("Rule not found with id: " + id)));
    }

    // 새 규칙 생성
    @PostMapping("/rules")
    public Mono<AuthorizationRule> create(@RequestBody @Valid UpsertReq r) {
        var e = new AuthorizationRule();
        e.pattern = r.pattern();
        e.methods = emptyToNull(r.methods());
        e.action = r.action();
        e.roles = emptyToNull(r.roles());
        e.groups = emptyToNull(r.groups());
        e.priority = r.priority();
        e.enabled = r.enabled();
        return repo.save(e)
                .flatMap(saved -> rules.reload().thenReturn(saved));
    }

    // 규칙 수정
    @PostMapping("/rules/{id}/update")
    public Mono<AuthorizationRule> update(@PathVariable Integer id, @RequestBody @Valid UpsertReq r) {
        return repo.findById(id)
                .switchIfEmpty(Mono.error(new IllegalArgumentException("Rule not found with id: " + id)))
                .flatMap(e -> {
                    e.pattern = r.pattern();
                    e.methods = emptyToNull(r.methods());
                    e.action = r.action();
                    e.roles = emptyToNull(r.roles());
                    e.groups = emptyToNull(r.groups());
                    e.priority = r.priority();
                    e.enabled = r.enabled();
                    return repo.save(e);
                })
                .then(rules.reload())
                .then(repo.findById(id));
    }

    // 규칙 삭제
    @PostMapping("/rules/{id}/delete")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public Mono<Void> delete(@PathVariable Integer id) {
        return repo.deleteById(id).then(rules.reload());
    }

    // 규칙 활성화/비활성화 토글
    @PostMapping("/rules/{id}/toggle-status")
    public Mono<AuthorizationRule> toggleStatus(@PathVariable Integer id,
                                                @RequestBody Map<String, Boolean> status) {
        return repo.findById(id)
                .switchIfEmpty(Mono.error(new IllegalArgumentException("Rule not found with id: " + id)))
                .flatMap(e -> {
                    e.enabled = status.get("enabled");
                    return repo.save(e);
                })
                .then(rules.reload())
                .then(repo.findById(id));
    }

    // 규칙 테스트
    @PostMapping("/test")
    public Mono<Map<String, Object>> testRule(@RequestBody TestRequest request) {
        // 특정 경로와 사용자 정보로 규칙 평가 결과 반환
        // ...
    }

    // 규칙 수동 리로드
    @PostMapping("/_reload")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public Mono<Void> reload() {
        return rules.reload();
    }
}
```

**참고**: 모든 API는 `/api-gateway` 베이스 경로를 포함합니다. 예: `/api-gateway/api/v1/authorization/rules`

## 8. 실제 사용 예시

### 8.1 인가 규칙 설정 예시

```sql
-- 관리자만 접근 가능한 API (역할 기반)
INSERT INTO AUTHORIZATION_RULE(pattern, methods, action, roles, priority) VALUES
('/api-gateway/api/admin/**', NULL, 'HAS_ANY_ROLE', 'ROLE_ADMIN', 10);

-- 특정 역할과 그룹이 모두 필요한 API
INSERT INTO AUTHORIZATION_RULE(pattern, methods, action, roles, groups, priority) VALUES
('/api-gateway/api/sensitive/**', NULL, 'HAS_ALL_ROLES', 'ROLE_MANAGER,ROLE_APPROVER', 'GROUP_EXECUTIVES', 20);

-- 역할 또는 그룹 중 하나라도 있으면 접근 가능
INSERT INTO AUTHORIZATION_RULE(pattern, methods, action, roles, groups, priority) VALUES
('/api-gateway/api/team/**', NULL, 'HAS_ANY_ROLE', 'ROLE_TEAM_LEAD', 'GROUP_MANAGERS', 30);

-- 인증된 사용자만 접근 가능
INSERT INTO AUTHORIZATION_RULE(pattern, methods, action, priority) VALUES
('/api-gateway/api/user/**', NULL, 'AUTHENTICATED', 40);

-- 공개 API
INSERT INTO AUTHORIZATION_RULE(pattern, methods, action, priority) VALUES
('/api-gateway/api/public/**', NULL, 'PERMIT', 50);
```

### 8.2 동적 규칙 변경

```bash
# 새로운 규칙 추가
curl -X POST http://localhost:8080/api-gateway/api/v1/authorization/rules \
  -H "Content-Type: application/json" \
  -d '{
    "pattern": "/api-gateway/api/new-feature/**",
    "methods": "GET,POST",
    "action": "HAS_ANY_ROLE",
    "roles": "ROLE_DEVELOPER",
    "groups": "GROUP_DEVELOPERS",
    "priority": 25,
    "enabled": true
  }'

# 규칙 수정
curl -X POST http://localhost:8080/api-gateway/api/v1/authorization/rules/1/update \
  -H "Content-Type: application/json" \
  -d '{
    "pattern": "/api-gateway/api/new-feature/**",
    "methods": "GET,POST,PUT",
    "action": "HAS_ANY_ROLE",
    "roles": "ROLE_DEVELOPER,ROLE_ADMIN",
    "groups": null,
    "priority": 25,
    "enabled": true
  }'

# 규칙 삭제
curl -X POST http://localhost:8080/api-gateway/api/v1/authorization/rules/1/delete

# 규칙 활성화/비활성화
curl -X POST http://localhost:8080/api-gateway/api/v1/authorization/rules/1/toggle-status \
  -H "Content-Type: application/json" \
  -d '{"enabled": false}'

# 규칙 테스트
curl -X POST http://localhost:8080/api-gateway/api/v1/authorization/test \
  -H "Content-Type: application/json" \
  -d '{
    "path": "/api-gateway/api/v1/users",
    "method": "GET",
    "userRoles": ["ROLE_SYSTEM_MANAGER"],
    "userGroups": ["GROUP_ADMIN"]
  }'

# 규칙 리로드
curl -X POST http://localhost:8080/api-gateway/api/v1/authorization/_reload
```

## 9. 모니터링과 로깅

### 9.1 인가 실패 로깅

```java
@Override
public Mono<AuthorizationResult> authorize(Mono<Authentication> authentication, AuthorizationContext ctx) {
    var req = ctx.getExchange().getRequest();
    var path = req.getPath().pathWithinApplication().value();
    HttpMethod method = req.getMethod();

    return authentication
            .flatMap(auth -> {
                // 인가 로직 수행
                return performAuthorization(auth, path, method);
            })
            .doOnNext(result -> {
                if (!result.isGranted()) {
                    log.warn("Authorization denied for path: {}, method: {}, user: {}",
                            path, method, authentication.block()?.getName());
                }
            });
}
```

### 9.2 메트릭 수집

```java
@Component
public class AuthorizationMetrics {

    private final MeterRegistry meterRegistry;
    private final Counter authorizationSuccessCounter;
    private final Counter authorizationFailureCounter;

    public AuthorizationMetrics(MeterRegistry meterRegistry) {
        this.meterRegistry = meterRegistry;
        this.authorizationSuccessCounter = Counter.builder("authorization.success")
                .description("Number of successful authorizations")
                .register(meterRegistry);
        this.authorizationFailureCounter = Counter.builder("authorization.failure")
                .description("Number of failed authorizations")
                .register(meterRegistry);
    }
}
```

## 10. 보안 고려사항

### 10.1 규칙 우선순위

- 낮은 priority 값이 먼저 평가됩니다
- 첫 번째로 매칭되는 규칙이 적용됩니다
- 명시적인 DENY 규칙을 높은 우선순위로 설정해야 합니다

### 10.2 토큰 보안

- JWT 토큰의 만료 시간을 적절히 설정
- Refresh Token을 통한 자동 갱신
- 토큰 탈취 시 즉시 무효화 가능한 메커니즘

### 10.3 규칙 검증

```java
@Service
public class AuthorizationRuleValidator {

    public void validateRule(AuthorizationRule rule) {
        if (rule.getPattern() == null || rule.getPattern().isEmpty()) {
            throw new IllegalArgumentException("Pattern cannot be empty");
        }

        if (rule.getAction() == null) {
            throw new IllegalArgumentException("Action cannot be null");
        }

        // HAS_ANY_ROLE 또는 HAS_ALL_ROLES의 경우 roles 또는 groups 중 하나는 필요
        if ((rule.getAction() == Action.HAS_ANY_ROLE || rule.getAction() == Action.HAS_ALL_ROLES)
            && ((rule.getRoles() == null || rule.getRoles().isEmpty())
                && (rule.getGroups() == null || rule.getGroups().isEmpty()))) {
            throw new IllegalArgumentException("Roles or groups required for role-based actions");
        }

        // 경로 패턴이 base-path를 포함하는지 확인 (권장)
        if (!rule.getPattern().startsWith("/api-gateway")) {
            log.warn("Pattern '{}' does not include base-path '/api-gateway'", rule.getPattern());
        }
    }
}
```

### 10.4 경로 패턴 주의사항

- 모든 경로는 `spring.webflux.base-path` 설정값(`/api-gateway`)을 포함한 전체 경로를 사용해야 합니다
- 예: `/api-gateway/api/**`, `/api-gateway/actuator/health`
- 경로는 대소문자를 구분합니다
- Spring PathPattern 문법을 사용합니다 (`**`는 하위 경로 모두 매칭)

## 11. 역할과 그룹 기반 인가

### 11.1 역할과 그룹의 조합

동적 인가 시스템은 역할(Roles)과 그룹(Groups)을 모두 지원하며, 다음과 같이 조합하여 사용할 수 있습니다:

- **HAS_ANY_ROLE**: 지정된 역할 또는 그룹 중 하나라도 있으면 허용
  - 예: `roles="ROLE_ADMIN"`, `groups="GROUP_MANAGERS"` → 역할 또는 그룹 중 하나만 있으면 접근 가능

- **HAS_ALL_ROLES**: 지정된 모든 역할과 그룹이 있어야 허용
  - 예: `roles="ROLE_MANAGER,ROLE_APPROVER"`, `groups="GROUP_EXECUTIVES"` → 모든 역할과 그룹이 있어야 접근 가능

### 11.2 사용 예시

```sql
-- 역할 또는 그룹 중 하나만 있으면 접근 가능
INSERT INTO AUTHORIZATION_RULE(pattern, methods, action, roles, groups, priority) VALUES
('/api-gateway/api/team/**', NULL, 'HAS_ANY_ROLE', 'ROLE_TEAM_LEAD', 'GROUP_MANAGERS', 30);

-- 모든 역할과 그룹이 있어야 접근 가능
INSERT INTO AUTHORIZATION_RULE(pattern, methods, action, roles, groups, priority) VALUES
('/api-gateway/api/sensitive/**', NULL, 'HAS_ALL_ROLES', 'ROLE_MANAGER,ROLE_APPROVER', 'GROUP_EXECUTIVES', 20);
```

## 12. 결론

Spring Cloud Gateway의 Dynamic Authorization Exchange는 다음과 같은 장점을 제공합니다:

1. **유연성**: 런타임에 인가 규칙을 동적으로 변경 가능
2. **성능**: 메모리 캐싱과 패턴 컴파일을 통한 최적화
3. **확장성**: 새로운 인가 정책을 쉽게 추가 가능
4. **관리성**: REST API를 통한 규칙 관리 및 테스트 기능
5. **보안**: 세밀한 권한 제어(역할 및 그룹 기반)와 감사 로깅
6. **통합성**: Keycloak과의 완벽한 통합으로 역할과 그룹 자동 변환

이러한 동적 인가 시스템을 통해 마이크로서비스 환경에서 효과적인 보안 정책을 구현할 수 있으며, 비즈니스 요구사항의 변화에 빠르게 대응할 수 있습니다.

## 참고 자료

- [Spring Security WebFlux Documentation](https://docs.spring.io/spring-security/reference/reactive/index.html)
- [Spring Cloud Gateway Documentation](https://docs.spring.io/spring-cloud-gateway/docs/current/reference/html/)
- [Keycloak Documentation](https://www.keycloak.org/documentation)
- [Spring WebFlux Security](https://spring.io/guides/gs/securing-webflux/)
