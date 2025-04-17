---
layout: post
title: ThreadPoolTaskScheduler 을 이용한 동적 스케쥴링 
author: jblim0125
date: 2025-04-17
category: 2025
tags: [SpringBoot, ThreadPoolTaskScheduler]
---

## 개요

Spring 애플리케이션에서 외부 이벤트에 따라 주기적으로 대상 상태를 확인해야 할 때, 
어떻게 동적으로 작업을 등록하고 관리할 수 있을까요?

## 🎯 목표

- 외부 이벤트로부터 작업 정보가 동적으로 변경(추가/수정/삭제) 가능
- 작업 별 개별 주기
- 스레드풀/큐/거절 정책 모니터링 및 제어

## 🛠️ 기본 설계

### 구조 개요

```text
+——————————————–+
| TargetManager |  ← 대상 변경 수신
+——————————————–+
|
▼
+—————————————————–+
| DynamicScheduler |  ← 작업 등록, 수정, 삭제
+—————————————————–+
|
▼
+—————————–———————————————————–+
| ScheduledThreadPoolExecutor  |
+————————————————————————————––+
```

## ☕ Java 코드 예제 (Spring 기반)

1. Target 클래스
    주기적으로 동작해야 하는 작업 대상 정보  

    ```java
    public class Target {
        private final String id;
        private final AtomicInteger periodSeconds;

        public Target(String id, int periodSeconds) {
            this.id = id;
            this.periodSeconds = new AtomicInteger(periodSeconds);
        }

        public String getId() {
            return id;
        }

        public int getPeriodSeconds() {
            return periodSeconds.get();
        }

        public void setPeriodSeconds(int seconds) {
            this.periodSeconds.set(seconds);
        }
    }
    ```

2. DynamicScheduler (핵심 동적 스케줄링 구현체)

    ```java
    @Component
    public class DynamicScheduler {

        private final ThreadPoolTaskScheduler taskScheduler;
        private final Map<String, ScheduledFuture<?>> scheduledTasks = new ConcurrentHashMap<>();

        public DynamicScheduler() {
            taskScheduler = new ThreadPoolTaskScheduler();
            taskScheduler.setPoolSize(10);
            taskScheduler.initialize();
        }

        public void schedule(Target target, Runnable taskLogic) {
            cancel(target.getId());

            ScheduledFuture<?> future = taskScheduler.scheduleAtFixedRate(taskLogic, target.getPeriodSeconds() * 1000L);
            scheduledTasks.put(target.getId(), future);
        }

        public void cancel(String targetId) {
            ScheduledFuture<?> future = scheduledTasks.remove(targetId);
            if (future != null) {
                future.cancel(true);
            }
        }
    }
    ```

3. TargetService (업데이트 & 등록 API 처리)

    ```java
    @Service
    public class TargetService {

        private final Map<String, Target> targets = new ConcurrentHashMap<>();
        private final DynamicScheduler scheduler;

        @Autowired
        public TargetService(DynamicScheduler scheduler) {
            this.scheduler = scheduler;
        }

        public void upsertTarget(String id, int newPeriod) {
            Target target = targets.compute(id, (k, v) -> {
                if (v == null) return new Target(id, newPeriod);
                v.setPeriodSeconds(newPeriod);
                return v;
            });

            scheduler.schedule(target, () -> {
                System.out.println("[" + LocalTime.now() + "] 상태 확인: " + target.getId());
                // 여기에 상태 확인 로직
            });
        }

        public void removeTarget(String id) {
            scheduler.cancel(id);
            targets.remove(id);
        }
    }
    ```

4. TargetController (외부에서 대상 제어용 API)

    ```java
    @RestController
    @RequestMapping("/targets")
    public class TargetController {

        @Autowired
        private TargetService targetService;

        @PostMapping("/{id}")
        public ResponseEntity<?> updateTarget(@PathVariable String id, @RequestParam int periodSeconds) {
            targetService.upsertTarget(id, periodSeconds);
            return ResponseEntity.ok("업데이트 완료: " + id);
        }

        @DeleteMapping("/{id}")
        public ResponseEntity<?> deleteTarget(@PathVariable String id) {
            targetService.removeTarget(id);
            return ResponseEntity.ok("삭제 완료: " + id);
        }
    }
    ```

## 🧠 추가 : 큐 모니터링 & 스레드풀 동적 조절

1. 큐 상태 모니터링

    ```java
    int queueSize = executor.getQueue().size();
    System.out.println("현재 대기 중인 작업 수: " + queueSize);
    ```

    활용 예시

    - 일정 수 이상이면 부하 감지 경고
    - 관리자 대시보드에 실시간 표시

2. 동적 풀 사이즈 조절

    ```java
    executor.setCorePoolSize(newCoreSize);
    executor.setMaximumPoolSize(newMaxSize); // 일반적인 ScheduledThreadPoolExecutor는 core=max여야 함
    ```

    > 주의: ScheduledThreadPoolExecutor는 기본적으로 core=max 구조이며, maximumPoolSize는 사실상 무시됩니다. 대신 corePoolSize만 조정하면 충분합니다.

3. RejectedExecutionHandler (거절 정책)
    작업이 처리 불가능한 상황(예: shutdown 후 제출 등)일 때, 어떤 동작을 할지를 지정할 수 있습니다.

    ```java
    executor.setRejectedExecutionHandler((r, exec) -> {
        System.err.println("작업 거부됨! 큐가 가득 찼거나 executor가 종료됨.");
        // 슬랙 알림, 로그 기록, 대체 로직 수행 가능
    });
    ```

4. 모니터링과 결합된 스케쥴러 서비스

    ```java
    @Component
    public class SmartScheduler {

        private final ScheduledThreadPoolExecutor executor;

        public SmartScheduler() {
            this.executor = new ScheduledThreadPoolExecutor(10);
            this.executor.setRejectedExecutionHandler((r, exec) -> {
                System.err.println("거부된 작업: " + r.toString());
            });

            // 모니터링용 스케줄링
            Executors.newSingleThreadScheduledExecutor().scheduleAtFixedRate(() -> {
                int queueSize = executor.getQueue().size();
                int active = executor.getActiveCount();
                System.out.println("[모니터링] 대기: " + queueSize + ", 활성 스레드: " + active);
            }, 0, 10, TimeUnit.SECONDS);
        }

        public void schedule(Runnable task, long periodSeconds) {
            executor.scheduleAtFixedRate(task, 0, periodSeconds, TimeUnit.SECONDS);
        }

        public void shutdown() {
            executor.shutdown();
        }
    }
    ```

## 🚀 결론

이 방식은 다음과 같은 장점이 있습니다:

- 대상 개수 제약 없음
- 작업별 개별 주기 설정 가능
- 부하 상태 감지 및 동적 풀 확장 가능
- REST, 메시지 큐 등 다양한 외부 이벤트와 연동 유연성
