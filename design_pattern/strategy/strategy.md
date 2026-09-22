 > 자료 출처
>  - 헤드퍼스트 디자인 패턴 (Factory 챕터에 이어서 정리)

## 전략 패턴 (Strategy Pattern)

- 정의: 여러 알고리즘(행동)을 각각 캡슐화하고, 서로 교환해서 쓸 수 있도록(interchangeable) 만드는 패턴. 클라이언트와 알고리즘을 분리시켜 독립적으로 변경할 수 있게 한다.
- OCP.md에서 다룬 "Alert 클래스의 if 분기를 AlertHandler로 분리한 리팩터링"이 사실 전략 패턴 그 자체다. 패턴 이름을 붙이고 나면 훨씬 재사용하기 쉬워진다.

### 문제 상황 (오리 시뮬레이션 게임 예제)

~~~java
public abstract class Duck {
    void quack() { System.out.println("꽥꽥"); }
    void swim() { System.out.println("헤엄!"); }

    // 문제: fly()를 상위 클래스에 넣으면, 날지 못하는 오리(RubberDuck)까지 날게 됨.
    void fly() { System.out.println("날고 있어요!"); }
}

public class RubberDuck extends Duck {
    // RubberDuck은 날 수 없는데, 상속 때문에 fly()가 그대로 상속됨.
    // fly()를 오버라이드해서 아무것도 안 하게 막을 수는 있지만,
    // 오리 종류가 늘어날수록 예외 처리가 기하급수적으로 늘어남 -> OCP, LSP 둘 다 위반.
}
~~~

- 상속으로 "행동"을 물려주면, 서브클래스마다 그 행동이 맞을 수도 안 맞을 수도 있다는 문제가 생긴다. (LSP.md에서 다룬 "하위 클래스가 상위 클래스의 계약을 깨는 경우"와 같은 맥락)

### 해결: "바뀌는 부분"을 캡슐화해서 구성(composition)으로 갖기

~~~java
// 1. 나는 행동을 인터페이스로 분리 (전략 인터페이스)
public interface FlyBehavior {
    void fly();
}

public class FlyWithWings implements FlyBehavior {
    public void fly() { System.out.println("날고 있어요!"); }
}

public class FlyNoWay implements FlyBehavior {
    public void fly() { System.out.println("저는 못 날아요."); }
}

// 2. Duck은 행동 인터페이스에만 의존 (상속이 아니라 has-a 관계)
public abstract class Duck {
    protected FlyBehavior flyBehavior;

    public void performFly() {
        flyBehavior.fly();  // 실제 행동은 위임
    }

    public void setFlyBehavior(FlyBehavior fb) { // 3. 런타임에 행동 교체 가능
        this.flyBehavior = fb;
    }
}

public class RubberDuck extends Duck {
    public RubberDuck() {
        flyBehavior = new FlyNoWay();  // 못 나는 행동을 조립
    }
}

public class MallardDuck extends Duck {
    public MallardDuck() {
        flyBehavior = new FlyWithWings();  // 나는 행동을 조립
    }
}
~~~

- 핵심 원칙: **"바뀌는 부분을 찾아서, 바뀌지 않는 부분과 분리한다."** (factory.md에서도 나왔던 문장 — 팩토리 패턴과 전략 패턴은 결국 같은 문제의식에서 출발함)
- 원칙 하나 더: **"구현이 아닌 인터페이스에 맞춰서 프로그래밍한다."** — `Duck`은 `FlyWithWings`라는 구체 클래스가 아니라 `FlyBehavior`라는 인터페이스만 알면 됨.
- 원칙 하나 더: **"상속보다 구성을 사용한다."** — `is-a`(상속) 대신 `has-a`(구성)로 관계를 맺으면, `setFlyBehavior()`처럼 **런타임에 행동을 바꿀 수 있는 유연성**까지 덤으로 얻는다. 상속으로는 불가능한 부분.

### 실무 예시 — 결제 수단 전략

~~~java
public interface PaymentStrategy {
    void pay(long amount);
}

public class CardPayment implements PaymentStrategy {
    public void pay(long amount) { System.out.println(amount + "원 카드 결제"); }
}

public class KakaoPayPayment implements PaymentStrategy {
    public void pay(long amount) { System.out.println(amount + "원 카카오페이 결제"); }
}

public class Order {
    private PaymentStrategy paymentStrategy;

    public Order(PaymentStrategy paymentStrategy) {
        this.paymentStrategy = paymentStrategy; // 생성자 주입 - Spring의 DI와 원리가 같다
    }

    public void checkout(long amount) {
        paymentStrategy.pay(amount);
    }
}
~~~

- 이렇게 짜두면 새 결제 수단(토스페이 등)이 추가돼도 `Order` 클래스는 전혀 안 건드리고, `PaymentStrategy` 구현체 하나만 추가하면 된다 → OCP.
- Spring에서는 이 패턴이 `@Autowired` + 인터페이스 여러 구현체 + `@Qualifier`/`Map<String, PaymentStrategy>` 주입 조합으로 아주 흔하게 쓰인다.

### 전략 패턴 vs 팩토리 패턴

| | 전략 패턴 | 팩토리 패턴 |
|---|---|---|
| 캡슐화 대상 | **행동(알고리즘)**을 캡슐화 | **객체 생성**을 캡슐화 |
| 관계 | 클라이언트가 전략 객체를 갖고 위임(has-a) | 클라이언트가 팩토리에게 생성을 요청 |
| 같이 쓰이는 경우 | 팩토리가 상황에 맞는 전략 객체를 만들어 주입해주는 조합도 흔함 | - |

---

## 다음 학습 주제
- [OCP](../../solid/OCP.md) — 이 패턴이 실제로 어떤 원칙을 만족시키는지 원론으로 되짚기
- 옵저버 패턴 — "상태 변화를 감지해서 알림"을 캡슐화하는 패턴. 전략 패턴과 함께 헤드퍼스트 디자인 패턴의 다음 챕터
- 스프링에서의 전략 패턴 실전 사례: `PlatformTransactionManager`(트랜잭션 전략), `PasswordEncoder`(암호화 전략) 구현체가 여러 개인 이유
