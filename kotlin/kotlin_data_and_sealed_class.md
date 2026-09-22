# 코틀린 - data class와 sealed class

> `2019-08-18-코틀린5-1~5-6` 시리즈에서 일반 클래스/상속/캡슐화/클래스 관계까지 다뤘었는데, 실무에서 정말 자주 쓰는 `data class`와 `sealed class`가 빠져 있어서 이어서 정리.

## data class — 값을 표현하는 클래스의 보일러플레이트 제거

- 일반 클래스로 "값을 담는 객체"(자바의 DTO/VO에 해당)를 만들면, `equals()`, `hashCode()`, `toString()` 을 전부 손으로 오버라이드해야 한다. `data` 키워드 하나로 이걸 컴파일러가 대신 만들어준다.

~~~kotlin
data class User(val name: String, val age: Int)
~~~

컴파일러가 자동으로 생성해주는 것들:

~~~kotlin
val u1 = User("jmlim", 30)
val u2 = User("jmlim", 30)

u1 == u2          // true - equals()가 필드값 기준으로 비교 (자바 기본 equals는 참조 비교라 false였을 것)
println(u1)       // User(name=jmlim, age=30) - toString() 자동 생성

// copy() - 일부 필드만 바꾼 새 객체를 만들 때 (불변 객체를 유지하면서 값만 바꾸고 싶을 때)
val u3 = u1.copy(age = 31)  // User(name=jmlim, age=31)

// 구조 분해 선언(destructuring declaration) - componentN() 함수가 자동 생성되어 있어서 가능
val (name, age) = u1
println("$name, $age") // jmlim, 30
~~~

- `builder.md`에서 다룬 빌더 패턴과 비교: 필드가 몇 개 안 되고 전부 필수값이라면 `data class`의 기본 생성자만으로 충분하다. 필드가 많고 선택값 위주라면 여전히 빌더(또는 코틀린의 default parameter, named argument)가 더 적합.
    ~~~kotlin
    data class Pizza(val size: Int, val cheese: Boolean = false, val bacon: Boolean = false)
    val pizza = Pizza(size = 12, bacon = true) // named argument로 순서 걱정 없이 생성 가능
    // -> 텔레스코핑 생성자 문제(builder.md 참고)를 코틀린은 default parameter + named argument로도 상당 부분 해결
    ~~~

## sealed class — "가능한 하위 타입이 이것뿐"임을 컴파일러에게 보장

- 일반적인 상속에서는 어떤 클래스든 자유롭게 상속받아 새로운 하위 타입을 추가할 수 있다. `sealed`를 붙이면 **하위 타입을 같은 파일(또는 같은 모듈) 안에서만** 정의할 수 있도록 제한한다.
- 왜 이게 유용한가? — `when`으로 분기 처리할 때, 컴파일러가 **"가능한 모든 경우를 다 처리했는지"를 검증**해줄 수 있게 된다.

~~~kotlin
sealed class PaymentResult
data class Success(val transactionId: String) : PaymentResult()
data class Failure(val reason: String) : PaymentResult()
object Pending : PaymentResult()  // 값이 없는 경우는 object로 (싱글턴)

fun handle(result: PaymentResult): String = when (result) {
    is Success -> "성공: ${result.transactionId}"
    is Failure -> "실패: ${result.reason}"
    Pending -> "대기중"
    // else 분기가 없어도 컴파일 에러가 안 남 - sealed class라 컴파일러가 "이 세 개가 전부"라는 걸 앎.
    // 만약 나중에 PaymentResult의 새 하위 타입(예: Cancelled)이 추가되면,
    // 이 when문은 그 즉시 "분기 처리 안 됨" 컴파일 에러를 내서 놓치지 않게 해줌.
}
~~~

- 자바로 치면 `enum` 으로는 표현할 수 없는(각 케이스가 서로 다른 필드를 가져야 하는) 상황을 안전하게 표현하는 방법. Java 17의 `sealed interface` + `record` + `switch` 패턴 매칭이 정확히 이 코틀린 sealed class 개념을 뒤늦게 들여온 것이다.
- 실전 활용: API 응답을 `Loading` / `Success<T>` / `Error` 3가지 sealed class로 표현해서, 화면(또는 컨트롤러)에서 `when`으로 분기 처리하면 "처리 안 한 상태"가 생기는 걸 컴파일 타임에 막을 수 있다 — 예외 처리 로직을 실수로 빠뜨리는 걸 방지하는 실용적인 패턴.

## sealed interface (Kotlin 1.5+)

~~~kotlin
sealed interface Shape
data class Circle(val radius: Double) : Shape
data class Rectangle(val width: Double, val height: Double) : Shape

fun area(shape: Shape): Double = when (shape) {
    is Circle -> Math.PI * shape.radius * shape.radius
    is Rectangle -> shape.width * shape.height
}
~~~
- `sealed class`와 거의 같은 목적이지만, 클래스가 아니라 인터페이스라서 **다중 구현**이 가능하다는 차이 — 이미 다른 클래스를 상속하고 있는 타입도 `Shape`를 구현할 수 있음.

## enum class와의 차이 정리

| | `enum class` | `sealed class` |
|---|---|---|
| 인스턴스 개수 | 정해진 상수 목록 (각 값은 싱글턴) | 하위 클래스마다 여러 인스턴스 생성 가능 |
| 각 케이스가 다른 필드/데이터를 가짐 | 어렵다 (모든 enum 상수가 같은 필드 집합을 공유) | 자유로움 (하위 클래스마다 다른 필드 정의 가능) |
| `when` 완전성 검사 | 지원 | 지원 |
| 대표 용도 | 상태 코드, 종류가 고정된 옵션 값 | 서로 다른 데이터를 갖는 여러 케이스를 표현 (API 결과, 이벤트 등) |

---

## 다음 학습 주제
- [코루틴 기초](./kotlin_coroutine_basics.md) — data class로 표현한 응답 타입을 비동기로 다루는 법
- [MSA - Saga 패턴](../msa/saga_pattern.md) — sealed class로 표현한 `PaymentResult`(Success/Failure/Pending)가 실제로 Saga의 각 단계 결과를 표현하는 데 그대로 쓰일 수 있음
- Java 17 `sealed interface` + `record` + pattern matching switch — 코틀린의 이 개념이 자바에 어떻게 들어왔는지 비교
