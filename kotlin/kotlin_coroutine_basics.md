# 코틀린 코루틴(Coroutine) 기초

> `java_concurrency_executor.md`에서 자바의 `ExecutorService`/`CompletableFuture`를 다뤘는데, 코틀린 코루틴은 같은 문제(비동기 작업)를 완전히 다른 방식으로 접근한다.
> "코틀린은 함수형+객체지향 다중 패러다임 언어"라고 `2019-08-01-코틀린1.md`에서 소개했었는데, 코루틴은 그 위에서 동시성까지 언어 차원의 문법으로 지원하는 기능.

## 왜 코루틴인가 — 콜백/Future의 한계

- `java_concurrency_executor.md`에서 본 `CompletableFuture` 체이닝은 강력하지만, 코드가 "콜백의 연속"이라 로직이 복잡해지면 읽기 어려워진다(이른바 콜백 지옥까지는 아니어도 흐름이 끊어져 보임).
- 코루틴은 비동기 코드를 **마치 동기 코드처럼 순차적으로 작성**할 수 있게 해준다 — 실제로는 특정 지점에서 실행을 "일시 중단(suspend)"했다가 나중에 재개하는 방식으로 동작하지만, 코드 모양은 평범한 순차 코드와 거의 같다.

## suspend 함수 — 코루틴의 핵심 키워드

~~~kotlin
suspend fun fetchUser(id: Long): User {
    delay(1000) // Thread.sleep()과 달리, 쓰레드를 블로킹하지 않고 "일시 중단"만 함
    return userApi.getUser(id)
}
~~~

- `suspend` 가 붙은 함수는 **다른 코루틴(또는 다른 suspend 함수) 안에서만** 호출할 수 있다 — 일반 함수에서 그냥 호출하면 컴파일 에러.
- `delay(1000)` 은 `Thread.sleep(1000)` 과 결과적으로 "1초 기다린다"는 점은 같아 보이지만, 결정적 차이가 있다.
    - `Thread.sleep()` — 그 쓰레드를 그대로 블로킹(점유)한 채로 1초를 낭비함. `java_concurrency_executor.md`에서 경고한 "쓰레드는 비싼 자원"이라는 문제가 그대로 발생.
    - `delay()` — 실행을 일시 중단하고, 그 쓰레드를 **다른 코루틴에게 양보**한다. 1초 뒤에 재개될 때 원래 쓰레드가 아니어도 상관없다. 그래서 **적은 수의 쓰레드로 수만 개의 코루틴을 동시에 띄울 수 있다** — 이게 코루틴을 "경량 쓰레드"라고 부르는 이유.

## launch와 async — 코루틴을 시작하는 두 방법

~~~kotlin
fun main() = runBlocking { // 코루틴 스코프를 만드는 진입점 (메인 함수에서 코루틴을 시작하기 위함)

    // launch - 결과값이 필요 없는 작업 (fire-and-forget에 가까움, Job을 반환)
    val job = launch {
        delay(500)
        println("launch 작업 완료")
    }

    // async - 결과값이 필요한 작업 (Deferred<T>를 반환, Future와 비슷한 개념)
    val deferred: Deferred<Int> = async {
        delay(500)
        42
    }

    val result = deferred.await() // 결과를 기다림 (블로킹이 아니라 suspend - 다른 작업에 쓰레드 양보 가능)
    println("async 결과: $result")

    job.join() // launch 작업이 끝날 때까지 대기
}
~~~

- `async`는 자바의 `CompletableFuture.supplyAsync()`와 개념적으로 대응된다. `.await()`가 `.get()`에 대응되지만, `await()`는 쓰레드를 블로킹하지 않는 suspend 함수라는 차이.

## 구조화된 동시성 (Structured Concurrency)

- 코루틴의 핵심 설계 철학: **자식 코루틴은 항상 부모의 스코프 안에서 실행되고, 부모가 끝나기 전에 자식들이 모두 끝나야 한다.**
- 왜 중요한가 — 자바에서 쓰레드를 직접 다루면, 만들어놓은 쓰레드가 다 끝났는지 추적하기 어렵고, 부모 작업이 취소되거나 예외가 나도 자식 쓰레드가 계속 살아있는(누수되는) 경우가 흔했다. 코루틴은 이걸 언어/라이브러리 차원에서 막아준다.

~~~kotlin
suspend fun processOrder() = coroutineScope {  // 이 스코프의 모든 자식이 끝나야 함수가 리턴됨
    val userDeferred = async { fetchUser() }
    val ordersDeferred = async { fetchOrders() }

    // 둘 다 병렬로 실행되고, 여기서 결과를 함께 기다림 (java의 thenCombine과 유사한 효과)
    val user = userDeferred.await()
    val orders = ordersDeferred.await()

    OrderDetail(user, orders)
}
~~~
- 만약 `fetchUser()`에서 예외가 발생하면, `coroutineScope`는 자동으로 `fetchOrders()` 쪽 코루틴도 취소시키고 예외를 위로 전파한다 — 한쪽이 실패했는데 다른 쪽 작업은 계속 살아서 자원을 낭비하는 상황을 막아줌.

## Dispatcher — 코루틴이 어느 쓰레드(풀)에서 실행될지

~~~kotlin
launch(Dispatchers.IO) {       // I/O 바운드 작업(네트워크, 파일)에 최적화된 쓰레드풀
    val data = readFromFile()
}

launch(Dispatchers.Default) {  // CPU 바운드 작업(연산)에 최적화, 코어 수만큼의 쓰레드풀
    val result = heavyComputation()
}

launch(Dispatchers.Main) {     // 안드로이드/UI 프레임워크의 메인(UI) 쓰레드
    updateUI(result)
}
~~~
- 결국 내부적으로는 `java_concurrency_executor.md`에서 다룬 `ExecutorService`(쓰레드풀)를 그대로 쓰고 있다 — 코루틴은 "그 위에 얹혀서, 쓰레드를 아껴 쓰는 스케줄링 방식을 추가한 것"이라고 이해하면 자바 쪽 지식과 잘 연결된다.

## 코루틴 vs 자바 CompletableFuture — 언제 뭘 쓰나

| | CompletableFuture (Java) | Coroutine (Kotlin) |
|---|---|---|
| 코드 형태 | 콜백 체이닝(`.thenApply`, `.thenAccept`) | 순차 코드처럼 보이는 suspend 함수 |
| 취소/구조화 | 직접 관리해야 함 | 구조화된 동시성으로 자동 전파 |
| 언어 지원 | 라이브러리(java.util.concurrent) | 코틀린 언어 문법 자체(suspend 키워드) + 라이브러리(kotlinx.coroutines) |
| Spring 사용 | `CompletableFuture<T>` 반환 타입 | Spring WebFlux/코루틴 컨트롤러에서 `suspend fun` 직접 사용 가능 |
| Java 21의 Virtual Thread와 비교 | Virtual Thread는 "동기 코드 그대로 쓰면서" 경량 쓰레드 효과를 주는 다른 접근 | 코루틴은 코드 자체를 suspend 문법으로 명시 |

---

## 다음 학습 주제
- [java_concurrency_executor.md](../java/java_concurrency_executor.md) — Dispatcher가 내부적으로 기대는 쓰레드풀 개념 복습
- Java 21 Virtual Thread(Project Loom) — 코루틴과 목표는 비슷하지만 접근 방식이 다른 최신 자바의 대안, 두 모델의 철학 차이 비교
- Spring WebFlux + 코틀린 코루틴 조합 — 리액티브 스트림(Mono/Flux)을 코루틴의 suspend 함수로 감싸서 쓰는 실전 패턴
- Flow — 코루틴에서 여러 값을 순차적으로(스트림처럼) 방출하는 비동기 시퀀스, Reactive Streams의 코틀린식 대응물
