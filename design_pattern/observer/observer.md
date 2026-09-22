 > 자료 출처
>  - 헤드퍼스트 디자인 패턴 (Strategy 챕터에 이어서 정리)

## 옵저버 패턴 (Observer Pattern)

- 정의: 한 객체(주제, Subject)의 상태가 바뀌었을 때, 그 객체에 의존하는 다른 객체들(옵저버, Observer)에게 자동으로 알림이 가고 갱신되는, **일대다(one-to-many) 의존 관계**를 정의하는 패턴.
- 신문/잡지 구독 모델과 같다. 구독자(Observer)는 발행자(Subject)에 구독을 신청하고, 새 호가 나올 때마다 자동으로 받아본다. 구독을 취소하면 더 이상 받지 않는다.

### 문제 상황 — 날씨 스테이션 예제 (헤드퍼스트 원조 예제)

기상 스테이션에서 온도/습도/기압 데이터가 갱신될 때마다, 화면에 표시하는 여러 디스플레이(현재 상태, 통계, 예보)를 전부 갱신해야 한다.

~~~java
// 나쁜 예 - Subject가 각 Display 구현체를 직접 알고 있음 -> OCP 위반
public class WeatherData {
    private CurrentConditionsDisplay currentDisplay;
    private StatisticsDisplay statisticsDisplay;

    public void measurementsChanged() {
        float temp = getTemperature();
        currentDisplay.update(temp);      // 새 디스플레이가 추가될 때마다 이 메서드도 계속 고쳐야 함
        statisticsDisplay.update(temp);
    }
}
~~~

- 이 코드는 구체 클래스(`CurrentConditionsDisplay`, `StatisticsDisplay`)에 직접 의존하고 있어서, 디스플레이 종류가 늘어날 때마다 `WeatherData` 코드 자체를 계속 고쳐야 한다 → OCP 위반. `Duck`이 `FlyWithWings`를 직접 알면 안 됐던 것과 같은 문제.

### 해결 — Subject/Observer 인터페이스로 분리

~~~java
public interface Subject {
    void registerObserver(Observer o);
    void removeObserver(Observer o);
    void notifyObservers();
}

public interface Observer {
    void update(float temp, float humidity, float pressure);
}

public class WeatherData implements Subject {
    private List<Observer> observers = new ArrayList<>();
    private float temperature, humidity, pressure;

    public void registerObserver(Observer o) { observers.add(o); }
    public void removeObserver(Observer o) { observers.remove(o); }

    public void notifyObservers() {
        for (Observer observer : observers) {
            observer.update(temperature, humidity, pressure); // 누가 붙어있는지 몰라도 됨
        }
    }

    public void measurementsChanged() {
        notifyObservers(); // 상태 변경 시 옵저버들에게 알림만 함
    }
}

public class CurrentConditionsDisplay implements Observer {
    public void update(float temp, float humidity, float pressure) {
        System.out.println("현재 상태: " + temp + "도, 습도 " + humidity + "%");
    }
}
~~~

- 이제 `WeatherData`는 어떤 디스플레이가 몇 개 붙어있는지 전혀 모른다. 새로운 디스플레이를 추가하려면 `Observer`를 구현하고 `registerObserver()`로 등록만 하면 됨 → `WeatherData` 코드는 한 줄도 안 바뀜.

### Push 모델 vs Pull 모델

- 위 예제는 **Push 모델**: `update(temp, humidity, pressure)` 처럼 필요할 만한 데이터를 주제가 알아서 다 밀어 넣어줌. 옵저버가 실제로 쓰는 값이 일부뿐이라면 낭비.
- **Pull 모델**: `update(Subject subject)` 형태로 주제 객체 자체(또는 getter)만 넘기고, 옵저버가 필요한 값만 골라서 꺼내가게 함.
    ~~~java
    public interface Observer {
        void update(Subject subject);
    }
    // Observer 내부에서
    public void update(Subject subject) {
        if (subject instanceof WeatherData wd) {
            float temp = wd.getTemperature(); // 필요한 것만 가져옴
        }
    }
    ~~~
- 실무에서는 대부분 Pull 모델(이벤트 객체 하나를 넘기는 방식)을 선호한다 — 아래 Spring 이벤트 예시가 그 형태.

### 실무 예시 — Spring의 ApplicationEvent

Spring은 옵저버 패턴을 프레임워크 레벨로 이미 구현해 제공한다.

~~~java
// 1. 이벤트(Subject가 옵저버에게 전달하는 데이터) 정의
public class OrderCreatedEvent {
    private final String orderId;
    public OrderCreatedEvent(String orderId) { this.orderId = orderId; }
    public String getOrderId() { return orderId; }
}

// 2. 이벤트 발행 (Subject 역할)
@Service
public class OrderService {
    private final ApplicationEventPublisher publisher;

    public OrderService(ApplicationEventPublisher publisher) {
        this.publisher = publisher;
    }

    public void createOrder(String orderId) {
        // 주문 저장 로직...
        publisher.publishEvent(new OrderCreatedEvent(orderId)); // notifyObservers()에 해당
    }
}

// 3. 이벤트 구독 (Observer 역할) - 여러 개 등록 가능, OrderService는 얘네 존재를 전혀 모름
@Component
public class OrderCreatedMailListener {
    @EventListener
    public void handle(OrderCreatedEvent event) {
        System.out.println(event.getOrderId() + " 주문 메일 발송");
    }
}

@Component
public class OrderCreatedStatListener {
    @EventListener
    public void handle(OrderCreatedEvent event) {
        System.out.println(event.getOrderId() + " 통계 집계");
    }
}
~~~

- `OrderService`는 메일 발송 로직도, 통계 집계 로직도 전혀 모른다 — 옵저버 패턴 덕분에 완전히 분리됨. 새 리스너가 추가돼도 `OrderService`는 안 건드림 → 여기서도 결국 OCP.
- 참고: 자바 표준 라이브러리의 `java.util.Observer`/`Observable`은 Java 9부터 **deprecated** 됐다 (설계가 부실했음: `Observable`이 클래스라 상속을 강제, 이벤트 타입 구분이 안 됨 등). 지금은 위 Spring 이벤트 방식이나, `PropertyChangeListener`, 또는 RxJava/Reactor 같은 리액티브 스트림 라이브러리를 쓰는 게 일반적.

---

## 다음 학습 주제
- [싱글턴 패턴](../singleton/singleton.md) — Subject(발행자)가 애플리케이션 내에 단 하나만 존재해야 하는 경우가 많아 자연스럽게 함께 등장
- Reactive Streams(Project Reactor, RxJava) — 옵저버 패턴을 "배압(backpressure)까지 처리할 수 있는 스트림"으로 확장한 개념
- MVC 패턴에서 View가 Model의 변경을 감지하는 방식 — 옵저버 패턴의 대표적인 활용 사례
