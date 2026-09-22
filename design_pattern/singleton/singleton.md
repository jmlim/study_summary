 > 자료 출처
>  - 헤드퍼스트 디자인 패턴 + 이펙티브 자바(Effective Java) 싱글턴 챕터 내용 일부 반영

## 싱글턴 패턴 (Singleton Pattern)

- 정의: 클래스의 인스턴스를 **딱 하나만** 만들도록 보장하고, 그 인스턴스에 전역으로 접근할 수 있는 지점을 제공하는 패턴.
- 프린터 스풀러, 설정(Config) 객체, 커넥션 풀, 로그 객체처럼 "여러 개가 있으면 오히려 문제가 되는" 자원에 주로 쓰인다. (mongodb 3장 노트에서 다룬 `MongoClient`를 애플리케이션당 하나만 만들어야 한다는 것도 같은 이유.)

### 1) 가장 단순한 형태 (Lazy Initialization, 멀티쓰레드에서 위험)

~~~java
public class Singleton {
    private static Singleton uniqueInstance;

    private Singleton() {} // 생성자를 private으로 막아 외부에서 new 못하게 함

    public static Singleton getInstance() {
        if (uniqueInstance == null) {       // (1)
            uniqueInstance = new Singleton(); // (2)
        }
        return uniqueInstance;
    }
}
~~~

- 문제: 멀티쓰레드 환경에서 두 쓰레드가 동시에 (1)을 통과하면, (2)가 두 번 실행되어 인스턴스가 두 개 생길 수 있다. — java_garbage_collection1.md, java_concurrency_executor.md에서 다룬 "동시성 문제"의 전형적인 예.

### 2) synchronized로 해결 (동작하지만 느림)

~~~java
public static synchronized Singleton getInstance() {
    if (uniqueInstance == null) {
        uniqueInstance = new Singleton();
    }
    return uniqueInstance;
}
~~~

- 정확하지만, `getInstance()`가 호출될 때마다 매번 락을 거는 건 낭비 — 인스턴스가 이미 만들어진 뒤(대부분의 호출)에도 계속 동기화 비용이 든다.

### 3) 이른 초기화 (Eager Initialization)

~~~java
public class Singleton {
    private static Singleton uniqueInstance = new Singleton(); // 클래스 로딩 시점에 바로 생성

    private Singleton() {}

    public static Singleton getInstance() {
        return uniqueInstance;
    }
}
~~~

- 클래스가 로드되는 시점에 JVM이 인스턴스를 만들어준다는 걸 이용 — 클래스 로딩은 자바 명세상 스레드 안전(thread-safe)하게 보장됨.
- 단점: 애플리케이션 시작 시 무조건 인스턴스가 생성됨 (실제로 안 쓰일 수도 있는데 자원을 미리 씀 — 리소스가 무거운 객체라면 손해).

### 4) DCL (Double-Checked Locking) — 필요할 때만, 안전하게

~~~java
public class Singleton {
    private static volatile Singleton uniqueInstance; // volatile 필수!

    private Singleton() {}

    public static Singleton getInstance() {
        if (uniqueInstance == null) {           // 1차 체크 (락 없이, 대부분의 호출은 여기서 바로 리턴)
            synchronized (Singleton.class) {
                if (uniqueInstance == null) {   // 2차 체크 (락 안에서 한번 더 확인)
                    uniqueInstance = new Singleton();
                }
            }
        }
        return uniqueInstance;
    }
}
~~~

- `volatile`이 반드시 필요한 이유: `new Singleton()`은 사실 "메모리 할당 → 생성자 호출 → 참조 대입"의 세 단계로 이루어지는데, JVM/CPU가 성능 최적화를 위해 이 순서를 재배열(reorder)할 수 있다. `volatile`이 없으면 다른 쓰레드가 "생성자 호출이 덜 끝난, 반쯤 초기화된 객체"의 참조를 보게 될 수 있음. `volatile`은 이 재배열을 막아준다(happens-before 관계 보장).

### 5) enum 싱글턴 — Effective Java가 권장하는 방식

~~~java
public enum Singleton {
    INSTANCE;

    public void doSomething() { ... }
}

// 사용
Singleton.INSTANCE.doSomething();
~~~

- 장점: 코드가 제일 짧고, **직렬화(Serialization)와 리플렉션 공격에도 안전**하다.
    - 일반 클래스로 싱글턴을 구현하면, 직렬화 후 역직렬화할 때 `readObject()`가 새 인스턴스를 만들어버리거나, 리플렉션으로 private 생성자를 강제로 호출해서 두 번째 인스턴스를 만들 수 있는 허점이 있음.
    - enum은 자바 언어 차원에서 인스턴스가 하나만 존재하도록 보장하기 때문에 이런 우회가 원천 차단됨.
- 단점: 다른 클래스를 상속해야 하는 경우엔 못 씀 (enum은 이미 `java.lang.Enum`을 상속하고 있어서 다중 상속이 안 되는 자바 특성상 다른 클래스 상속 불가).

### 싱글턴 패턴에 대한 비판적 시각

- 싱글턴은 **전역 상태(global state)**를 만든다는 점에서 테스트하기 어렵게 만드는 대표적인 안티패턴으로도 자주 지적된다.
    - 싱글턴에 의존하는 코드는 단위 테스트에서 그 싱글턴을 Mock으로 바꿔치기하기 어려움 (생성자로 주입받는 게 아니라 `getInstance()`로 직접 가져다 쓰기 때문).
    - 여러 클래스가 몰래 같은 싱글턴 상태를 공유하다 보면, 숨겨진 결합(hidden coupling)이 생겨서 SRP를 은근히 위반하게 되는 경우도 많음.
- **그래서 스프링에서는 싱글턴을 직접 구현하지 않는다.** 스프링 빈의 기본 스코프가 `singleton`인데, 이건 애플리케이션 컨텍스트(`ApplicationContext`) 하나당 빈 인스턴스를 하나만 관리해준다는 뜻 — 이 글에서 배운 "private 생성자 + static getInstance()" 패턴을 직접 짤 필요 없이, 컨테이너가 대신 그 책임을 져준다.
    - 대신 의존성은 생성자 주입으로 넘겨받으므로, 테스트할 때는 Mock 객체를 손쉽게 주입할 수 있음 — 위에서 지적한 싱글턴의 테스트 문제를 DI(의존성 주입)로 해결한 셈. (DIP.md의 결론과 정확히 같은 맥락)

---

## 다음 학습 주제
- [SOLID - DIP](../../solid/DIP.md) — "직접 `getInstance()`를 부르는 대신 컨테이너가 주입해준다"는 게 왜 더 나은 설계인지 원론적으로 복습
- `synchronized`, `volatile`, `happens-before` — DCL 예제에서 나온 개념을 자바 메모리 모델(JMM) 관점에서 더 깊이 정리
- 스프링 빈 스코프(singleton/prototype/request/session) — "싱글턴"이 스프링 안에서 정확히 어떤 단위(컨텍스트 vs JVM)로 보장되는지
