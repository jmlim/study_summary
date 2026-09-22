# 자바 동시성 - ExecutorService와 CompletableFuture

> `sync-async-blocking-nonblocking.md` 에서 개념(동기/비동기, 블로킹/논블로킹)을 정리했다면, 여기서는 그걸 실제 자바 코드로 어떻게 다루는지 정리.
> `spring-boot/Spring_ThreadPoolTaskExecutor_설정.md` 에 있는 실전 장애 경험(스케일 in 이후 기본 쓰레드 수만 써서 지연됐던 사건)과 이어지는 내용.

## 왜 Thread를 직접 만들면 안 되는가

~~~java
// 나쁜 예 - 요청마다 새 쓰레드 생성
new Thread(() -> doSomething()).start();
~~~

- 쓰레드 생성/소멸 자체가 비용이 크다 (OS 레벨 자원 할당).
- 몇 개까지 만들지 제한이 없어서, 트래픽이 몰리면 쓰레드가 무한정 늘어나다가 `OutOfMemoryError` 로 서버가 죽을 수 있음.
- → 그래서 쓰레드를 미리 만들어두고 재사용하는 **쓰레드 풀(Thread Pool)** 이 필요하고, 자바에서는 `ExecutorService` 로 이를 추상화한다.

## ExecutorService 기본

~~~java
ExecutorService executor = Executors.newFixedThreadPool(10); // 쓰레드 10개 고정 풀

executor.submit(() -> {
    // 비동기로 실행될 작업
    System.out.println("작업 실행: " + Thread.currentThread().getName());
});

executor.shutdown(); // 더 이상 새 작업을 받지 않고, 기존 작업이 끝나면 종료
~~~

### 자주 쓰는 팩토리 메서드 (Executors)

| 메서드 | 특징 | 주의점 |
|---|---|---|
| `newFixedThreadPool(n)` | 고정 크기 n개 쓰레드 | 큐가 무제한(`LinkedBlockingQueue`) — 요청 폭주 시 큐가 무한정 쌓여 메모리 문제 가능 |
| `newCachedThreadPool()` | 필요할 때마다 쓰레드 생성, 60초 유휴 시 회수 | 상한선이 없어서 트래픽 폭주 시 쓰레드가 무한정 늘어날 수 있음 |
| `newSingleThreadExecutor()` | 쓰레드 1개, 작업을 순차 처리 | 순서 보장이 필요한 작업에 적합 |
| `newScheduledThreadPool(n)` | 지연/주기 실행 지원 | `spring-boot-schedule.md`에서 다룬 `@Scheduled`의 기반 개념 |

- 실무에서는 위 팩토리 메서드보다 `ThreadPoolExecutor` 생성자를 직접 써서 `corePoolSize`, `maximumPoolSize`, `queueCapacity`, `RejectedExecutionHandler` 를 명시적으로 지정하는 걸 권장한다.
    - 이유: `Spring_ThreadPoolTaskExecutor_설정.md`에서 이미 짚었듯, 기본값(`Integer.MAX_VALUE` 큐)을 그대로 쓰면 트래픽이 몰려도 max 쓰레드까지 안 늘어나고 큐에만 계속 쌓이는 현상이 생길 수 있다. Spring의 `ThreadPoolTaskExecutor` 도 결국 이 `ThreadPoolExecutor`를 감싼 것.

## Future — 결과를 나중에 받기

~~~java
ExecutorService executor = Executors.newFixedThreadPool(4);

Future<Integer> future = executor.submit(() -> {
    Thread.sleep(1000);
    return 42;
});

// future.get() 은 결과가 준비될 때까지 현재 쓰레드를 블로킹함 (Async지만 결과를 기다리는 부분은 Blocking)
Integer result = future.get();
~~~

- `Future` 의 한계
    - `get()` 을 호출하는 순간 블로킹된다 — 완전한 논블로킹이 아님.
    - 여러 작업을 연결(체이닝)하거나, 실패 시 콜백을 걸거나, 여러 Future를 조합하는 게 번거로움.
    - → 이 한계를 보완하기 위해 Java 8부터 `CompletableFuture`가 등장.

## CompletableFuture — 논블로킹 콜백 체이닝

~~~java
CompletableFuture<Integer> future = CompletableFuture
    .supplyAsync(() -> {          // 1. 비동기로 값을 만들어냄 (별도 쓰레드풀에서 실행)
        return fetchUserCount();
    })
    .thenApply(count -> count * 2)      // 2. 결과를 받아 가공 (콜백 - 블로킹 없이 연결)
    .thenAccept(result -> System.out.println("결과: " + result)) // 3. 최종 소비
    .exceptionally(ex -> {              // 4. 예외 처리
        System.out.println("에러 발생: " + ex.getMessage());
        return null;
    });
~~~

- `get()`으로 결과를 기다리는 대신, "결과가 나오면 이 콜백을 실행해줘"라는 방식으로 코드를 짤 수 있어서 호출 쓰레드를 블로킹하지 않는다. → `sync-async-blocking-nonblocking.md`에서 정리한 **Async + Non-Blocking** 조합이 바로 이것.
- 여러 비동기 작업을 조합하는 예
~~~java
CompletableFuture<User> userFuture = CompletableFuture.supplyAsync(() -> getUser(id));
CompletableFuture<List<Order>> ordersFuture = CompletableFuture.supplyAsync(() -> getOrders(id));

// 두 작업이 모두 끝나면 합쳐서 처리
CompletableFuture<UserDetail> combined = userFuture.thenCombine(ordersFuture,
    (user, orders) -> new UserDetail(user, orders));
~~~
- 기본적으로 `supplyAsync`, `thenApply` 등은 `ForkJoinPool.commonPool()` 이라는 공용 풀을 사용한다. 실무에서는 **반드시 전용 Executor를 두 번째 인자로 넘겨서** 다른 기능과 쓰레드풀을 공유하지 않도록 하는 게 안전하다.
~~~java
CompletableFuture.supplyAsync(() -> fetchUserCount(), myExecutor);
~~~

## Spring @Async와의 관계

- 블로그의 `spring-boot-async.md` 에서 다룬 `@Async` 는, 내부적으로 이 `ExecutorService`(스프링에서는 `ThreadPoolTaskExecutor`)에 작업을 던지는 걸 어노테이션으로 감싸놓은 것.
- `@Async` 메서드가 값을 반환해야 한다면 리턴 타입을 `CompletableFuture<T>` 로 선언하면, 호출부에서 결과를 논블로킹으로 조합할 수 있다.

---

## 다음 학습 주제
- Virtual Thread (Java 21, Project Loom) — 쓰레드풀 크기를 고민할 필요 없이 수십만 개의 경량 쓰레드를 만들 수 있는 최신 대안. 이 문서에서 다룬 쓰레드풀 튜닝 고민 자체가 상당 부분 줄어드는 계기
- Reactive Streams / Spring WebFlux — CompletableFuture의 콜백 체이닝을 한 단계 더 추상화한 리액티브 프로그래밍 모델
- `synchronized`, `volatile`, `ReentrantLock` — 여러 쓰레드가 같은 자원(공유 변수)에 접근할 때의 동기화 문제 (MongoDB 학습 노트의 "동시성, 원자성, 고립" 챕터와 개념적으로 연결됨)
