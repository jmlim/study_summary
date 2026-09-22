# 코틀린 - Null 안전성 심화 & 스코프 함수

> `2019-08-01-코틀린2.md`에서 `?.`(세이프 콜), `!!`(non-null 단정), `?:`(엘비스 연산자)의 기초만 다뤘었는데, 실무에서 자주 쓰는 나머지 null 처리 패턴과 스코프 함수를 이어서 정리.

## 1. Null 안전성 심화

### 엘비스 연산자로 조기 반환/예외 던지기
- 기존 노트의 `str1?.length ?: -1` 은 "null이면 대체값"이었는데, 엘비스 연산자 오른쪽에는 `return`, `throw` 도 올 수 있다.

~~~kotlin
fun getLength(str: String?): Int {
    val s = str ?: return 0            // null이면 함수를 즉시 빠져나가며 0 반환
    return s.length
}

fun process(user: User?) {
    val u = user ?: throw IllegalArgumentException("user는 null일 수 없음")
    println(u.name) // 이 지점부터는 u가 non-null로 스마트 캐스트됨
}
~~~

### `lateinit` vs `lazy` — "나중에 초기화"의 두 방식

| | `lateinit var` | `by lazy { }` |
|---|---|---|
| 대상 | `var`만 가능, non-null 타입만 | `val`만 가능 |
| 초기화 시점 | 개발자가 원하는 시점에 직접 대입 | 처음 접근(get)하는 시점에 자동으로 1회 계산 |
| 초기화 전 접근 시 | `UninitializedPropertyAccessException` | 발생 안 함 (그 시점에 계산되므로) |
| 흔한 용도 | 스프링 `@Autowired` 필드, 안드로이드 뷰 바인딩처럼 프레임워크가 나중에 값을 넣어주는 경우 | 값 계산 비용이 크고, 실제 쓰일 때까지 미루고 싶은 경우 |

~~~kotlin
class OrderService {
    @Autowired
    lateinit var paymentClient: PaymentClient // 스프링이 빈 생성 이후 주입해줌

    val heavyConfig: Config by lazy {
        println("실제로 처음 쓰일 때만 이 로그가 찍힘")
        loadConfigFromFile() // 비용이 큰 초기화를 진짜 필요할 때까지 미룸
    }
}
~~~

### 안전한 타입 캐스팅 — `as?`
~~~kotlin
val obj: Any = "문자열"
val str: String? = obj as? String   // 캐스팅 실패 시 예외 대신 null 반환
val num: Int? = obj as? Int         // 실패 -> null
~~~
- `as` 는 실패하면 `ClassCastException`을 던지지만, `as?` 는 실패하면 그냥 `null`을 반환한다 — 엘비스 연산자와 자주 함께 쓰인다: `(obj as? String) ?: "기본값"`.

## 2. 스코프 함수 (Scope Functions) — `let`, `run`, `with`, `apply`, `also`

- 다섯 개 모두 "객체에 대해 코드 블록을 실행한다"는 점은 같지만, **블록 안에서 객체를 어떻게 참조하는지(`it` vs `this`)**와 **블록의 반환값이 무엇인지(객체 자신 vs 블록의 결과)**가 다르다.

| 함수 | 객체 참조 | 반환값 | 주 용도 |
|---|---|---|---|
| `let` | `it` | 람다 결과 | null 체크와 함께 값을 변환/사용 |
| `run` | `this` | 람다 결과 | 객체 설정 + 결과 계산을 한 블록에서 |
| `with` | `this` | 람다 결과 | 이미 non-null인 객체에 대해 여러 작업을 묶어서 실행 (확장함수 아님, 인자로 받음) |
| `apply` | `this` | **객체 자신** | 객체를 설정(초기화)하고 그 객체 자체를 리턴 (빌더처럼 체이닝) |
| `also` | `it` | **객체 자신** | 객체는 그대로 두고, 부수 작업(로깅 등)만 추가로 하고 싶을 때 |

### `let` — null 체크와 함께 안전하게 사용
~~~kotlin
val name: String? = getName()

name?.let {
    println("이름: $it") // name이 null이 아닐 때만 이 블록이 실행됨
    sendWelcomeEmail(it)
}
~~~

### `apply` — 객체를 구성(configure)하고 그 객체를 반환
~~~kotlin
val person = Person().apply {
    name = "jmlim"      // this.name 생략 가능 (this가 Person 인스턴스)
    age = 30
}
// person은 위에서 설정한 Person 객체 자체 - builder.md의 빌더 패턴과 목적이 비슷함
~~~

### `also` — 원래 흐름은 그대로, 중간에 부수 효과만 끼워넣기
~~~kotlin
val numbers = mutableListOf(1, 2, 3)
    .also { println("추가 전: $it") } // 로깅만 하고, numbers 자체는 그대로 다음 줄로 전달
    .apply { add(4) }
~~~

### `run` / `with` — 여러 작업을 묶고 최종 결과를 반환
~~~kotlin
val result = run {
    val a = fetchA()
    val b = fetchB()
    a + b // 이 블록의 마지막 식이 result에 대입됨
}

val description = with(person) {
    "$name, $age" // with는 person을 인자로 받고, this로 접근
}
~~~

### 실전 선택 기준 (자주 헷갈리는 부분 정리)
1. **null 체크가 목적**이면 → `let` (`?.let { }` 조합)
2. **객체를 만들고 설정한 뒤, 그 객체 자체가 필요**하면 → `apply`
3. **원래 값/흐름은 유지하면서, 로깅 등 부수 작업만 끼워넣고** 싶으면 → `also`
4. **여러 계산을 묶어서 최종 결과값(다른 타입)을 얻고** 싶으면 → `run` 또는 `with`

---

## 다음 학습 주제
- [코틀린 데이터 클래스와 sealed class](./kotlin_data_and_sealed_class.md) — null 안전성과 함께 코틀린이 자바보다 "표현하기 쉬운" 대표적인 부분
- [2019-08-18-코틀린5-6 클래스와 클래스와의 관계.md](./2019-08-18-코틀린5-6%20클래스와%20클래스와의%20관계.md) — 기존 시리즈에서 다룬 클래스 관계 개념 복습
- [코루틴 기초](./kotlin_coroutine_basics.md) — 스코프 함수와는 다른 개념이지만, 코틀린이 언어 차원에서 지원하는 또 다른 "문법 설탕"
