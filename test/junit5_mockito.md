# 테스트 - JUnit5와 Mockito

> 블로그의 `intellij-junit5-display-name-did-not-show-issue.md` 에서 JUnit5 트러블슈팅만 다뤘었는데, JUnit5/Mockito 자체를 정리한 노트가 없어서 이번에 채워 넣음.

## JUnit5의 구조

JUnit5는 세 개의 서브프로젝트로 이루어져 있다.

| 모듈 | 역할 |
|---|---|
| JUnit Platform | 테스트를 실행하는 하부 엔진(런처). IDE/Gradle/Maven이 이 위에서 동작 |
| JUnit Jupiter | JUnit5의 새로운 프로그래밍 모델·확장 모델 (`@Test`, `@BeforeEach` 등 우리가 실제로 쓰는 어노테이션들) |
| JUnit Vintage | JUnit3/4로 작성된 기존 테스트를 JUnit5 플랫폼에서 그대로 실행할 수 있게 해주는 호환 레이어 |

## 기본 어노테이션

~~~java
class OrderServiceTest {

    @BeforeAll
    static void setUpAll() { /* 클래스 전체에서 딱 한 번, 모든 테스트 시작 전에 실행 */ }

    @BeforeEach
    void setUp() { /* 각 테스트 메서드 실행 직전마다 실행 - 테스트 간 상태 초기화 용도 */ }

    @Test
    @DisplayName("주문 금액이 0원이면 예외가 발생한다")
    void throwsWhenAmountIsZero() {
        assertThrows(IllegalArgumentException.class, () -> new Order(0));
    }

    @AfterEach
    void tearDown() { /* 각 테스트 후 정리 */ }

    @AfterAll
    static void tearDownAll() { /* 클래스 전체 테스트가 끝난 뒤 한 번 */ }
}
~~~

- `@DisplayName` — 블로그에서 다뤘던 그 어노테이션. Gradle로 테스트를 돌릴 때 인텔리제이 실행 탭에 이 이름이 안 뜨는 문제가 있었는데, 원인은 Gradle 테스트 러너를 쓰느냐 IDE 러너를 쓰느냐의 차이였음 — 근본적으로는 "누가 테스트를 실행하고 그 결과를 어떻게 보여주는지"가 다르기 때문에 생기는 문제.

## 자주 쓰는 Assertion

~~~java
assertEquals(expected, actual);
assertTrue(condition);
assertNull(value);
assertThrows(IllegalArgumentException.class, () -> someMethod());

// 여러 검증을 한 번에 - 하나가 실패해도 나머지 검증까지 다 실행하고 한꺼번에 실패 결과를 보여줌
assertAll(
    () -> assertEquals("jmlim", user.getName()),
    () -> assertEquals(30, user.getAge())
);
~~~

- `assertAll`이 중요한 이유: 그냥 `assertEquals`를 여러 줄 나열하면, 첫 줄에서 실패하는 순간 예외가 던져져서 그 아래 검증들은 실행조차 안 됨. 어떤 필드가 잘못됐는지 한 번에 알기 어려움.

## 파라미터화 테스트 (같은 로직, 여러 입력값)

~~~java
@ParameterizedTest
@ValueSource(ints = {-1, 0, -100})
void throwsWhenAmountIsNotPositive(int amount) {
    assertThrows(IllegalArgumentException.class, () -> new Order(amount));
}

@ParameterizedTest
@CsvSource({"1, 1, 2", "2, 3, 5"})
void sum(int a, int b, int expected) {
    assertEquals(expected, a + b);
}
~~~

- 같은 검증 로직을 입력값만 바꿔가며 여러 번 반복하고 싶을 때, `@Test`를 여러 개 복붙하는 대신 이렇게 쓴다.

## Mockito - 가짜 객체로 의존성 격리하기

- 단위 테스트(Unit Test)의 핵심은 **테스트 대상 하나만 검증하고, 그게 의존하는 나머지는 가짜(Mock)로 대체**하는 것. (여기서 DIP.md/singleton.md에서 언급했던 "생성자 주입 방식이 테스트하기 쉬운 이유"가 실제로 확인된다 — 의존성을 주입받는 구조여야 Mock으로 갈아끼울 수 있음.)

~~~java
@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock
    private PaymentGateway paymentGateway; // 진짜 결제 API를 호출하지 않는 가짜 객체

    @InjectMocks
    private OrderService orderService; // @Mock들을 자동으로 생성자/필드에 주입해서 만들어줌

    @Test
    void checkoutCallsPaymentGateway() {
        // given - 가짜 객체의 행동을 미리 정의
        when(paymentGateway.charge(anyLong())).thenReturn(true);

        // when
        boolean result = orderService.checkout(10000L);

        // then - 결과 검증
        assertTrue(result);
        // 상호작용 검증 - paymentGateway.charge(10000L)가 정확히 한 번 호출됐는지
        verify(paymentGateway, times(1)).charge(10000L);
    }
}
~~~

### Mock vs Stub vs Spy (테스트 더블, Test Double 용어 정리)

| 용어 | 설명 |
|---|---|
| Stub | 미리 정해진 값만 반환하는 가짜 (호출 여부/횟수는 검증하지 않음) |
| Mock | Stub처럼 값도 반환하지만, **"호출됐는지, 몇 번 됐는지, 어떤 인자로"** 까지 검증(`verify`)하는 용도 |
| Spy | 진짜 객체를 감싸서, 대부분은 실제 로직을 그대로 타되 일부 메서드만 가짜로 대체 (`@Spy`) |

## given-when-then / BDD 스타일

~~~java
@Test
void example() {
    // given: 테스트 조건/상황 준비
    long amount = 10000L;

    // when: 실제 테스트 대상 동작 실행
    boolean result = orderService.checkout(amount);

    // then: 결과 검증
    assertTrue(result);
}
~~~

- 세 구간을 주석으로라도 나눠 적는 습관을 들이면, 테스트가 무엇을 검증하는지 코드만 읽어도 파악하기 쉬워짐.

## 테스트 전략 - 어디까지 테스트할까

- 단위 테스트(Unit Test): 클래스/메서드 하나. Mock으로 의존성을 완전히 격리. 빠르고 많이 돌릴 수 있음.
- 통합 테스트(Integration Test): 여러 컴포넌트(DB, 외부 API 등)를 실제로 연동해서 검증. 느리지만 실제 동작에 더 가까움.
    - `@SpringBootTest` — 스프링 컨텍스트 전체를 띄워서 테스트 (무거움, 필요한 곳에만 제한적으로 사용 권장).
    - **TestContainers** — 실제 MySQL/Redis/MongoDB를 Docker 컨테이너로 띄워서 진짜 DB에 대고 통합 테스트하는 라이브러리. mongodb 스터디 노트의 로컬 mongod 대신, 테스트에서는 이런 방식이 표준적으로 쓰인다.
- 테스트 피라미드: 단위 테스트를 가장 많이, 통합 테스트는 그보다 적게, E2E(전체 흐름) 테스트는 가장 적게 — 위로 갈수록 느리고 깨지기 쉬우므로.

---

## 다음 학습 주제
- [SOLID - DIP](../solid/DIP.md) — "생성자 주입이라 Mock을 갈아끼우기 쉽다"는 이 문서의 전제를 원론으로 복습
- TestContainers — Mock으로는 검증 못 하는 실제 쿼리/인덱스 동작까지 통합 테스트로 확인하는 방법
- 테스트 커버리지 도구(Jacoco) — 커버리지 수치 자체보다, "어떤 분기가 테스트되지 않았는지"를 찾는 용도로 쓰는 법
