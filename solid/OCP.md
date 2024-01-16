>  출처 : 디자인패턴의 아름다움
>


## 3.2. 개방 폐쇄 원칙
- **개방 폐쇄 원칙** open-closed principle OCP에 대해 살펴 봄.
    - 이 원칙은 **확장할 때는 개방, 수정할 때는 폐쇄** 원칙으로도 불리는데, 개방 폐쇄 원칙은 SOLID 원칙 중에서도 가장 이해하기 어렵고, 마스터하기 어려우면서도 가장 유용한 원칙.
        - 개방 폐쇄 원칙을 이해하기 어려운 이유
            - 코드를 변경할 때 그 결과를 **확장**으로 보아야 하는지, **수정**으로 보아야 하는지 명확하게 구분하기 어려움.
            - `확장할 때는 개방, 수정할 때는 폐쇄`라는 개념을 어떻게 달성할 것인지, 높은 확장성을 추구하면서 코드의 가독성에 영향을 미치지 않도록 이 원칙을 프로젝트에 어떻게 유연하게 적용할 것인지와 같은 문제는 대체로 이해하기 어려운 문제에 속하기 때문.
### 3.2.1. 확장할 때는 개방, 수정할 때는 폐쇄
- 모듈, 클래스, 함수와 같은 소프트웨어의 단위들은 확장을 위해 개방되어야 하지만 수정을 위해서는 폐쇄되어야 한다.
    - 새로운 기능을 추가할 때 기존의 모듈, 클래스, 함수를 수정하기보다는 기존 코드를 기반으로 모듈, 클래스, 함수 등을 추가하는 방식으로 코드를 확장해야 한다는 뜻이다.

- 다음 코드는 API 모니터링 경고 알림을 위한 코드이다. AlertRule 클래스는 경고 알림 규칙을 저장하고, Notification 클래스는 이메일이나 SMS와 같은 다양한 알림 채널을 지원하는 경고 알림을 담당한다.
    - NotificationEmergencyLevel 클래스는 SEVERE(심각), URGENCY(긴급), NORMAL(정상), TRIVIAL(관련 없음) 같이 경고 알림의 긴급한 정도를 지정
~~~java
public class Alert {
    private AlertRule rule;
    private Notification notification;
    
    public Alert(AlertRule rule, Notification notification) {
        this.rule = rule;
        this.notification = notification;
    }
    
    public void check(String api, long requestCount, long errorCount, long duration) {
        long tps = requestCount / duration;
        if(tps > rule.getMatchedRule(api).getMaxTps()) {
            notification.notify(NotificationEmergencyLevel.URGENCY,"...");
        }
        
        if(errorCount > rule.getMatchedRule(api).getMaxErrorCount()) {
            notification.notify(NotificationEmergencyLevel.SEVERE,"...");
        }
    }
} 
~~~

- 위 예제 코드의 비즈니스 논리는 주로 check() 함수에 집중되어 있음.
    - 인터페이스의 초당 트랜잭션 수가 미리 설정한 최댓값을 초과하거나 인터페이스 요청 오류 수가 최대 허용치를 초과하는 경우 경고가 발생하며, 이를 해당 인터페이스 담당자 또는 팀에 알리게 된다.
    - 만약 이때 '초당 인터페이스 요청 횟수가 미리 설정된 최댓값을 초과할 경우, 경고 알림이 설정되며 통지가 발송된다' 라는 새로운 경고 알림 규칙을 추가해야 한다면.. 코드를 어떻게 수정하는 것이 좋을까?
~~~java
public class Alert {
    private AlertRule rule;
    private Notification notification;
    
    public Alert(AlertRule rule, Notification notification) {
        this.rule = rule;
        this.notification = notification;
    }
    
    // 변경1: 매개변수 timeoutCount 추가.
    public void check(String api, long requestCount, long errorCount, long duration, long timeoutCount) {
        long tps = requestCount / duration;
        if(tps > rule.getMatchedRule(api).getMaxTps()) {
            notification.notify(NotificationEmergencyLevel.URGENCY,"...");
        }
        
        if(errorCount > rule.getMatchedRule(api).getMaxErrorCount()) {
            notification.notify(NotificationEmergencyLevel.SEVERE,"...");
        }
        
        // 변경 2: 인터페이스 요청 타임아웃 처리 추가.
        long timeoutTps = timeoutCount / duration;
        if(timeoutTps > rule.getMatchedRule(api).getMaxTimeoutTps()) {
            notification.notify(NotificationEmergencyLevel.URGENCY,"...");
        }
    }
} 
~~~
- 위 코드의 문제
    1. 인터페이스 자체를 수정하면 인터페이스를 호출하는 코드도 모두 그에 따라 수정된다는 점.
    2. check() 함수가 수정되면 해당 함수에 대한 단위 테스트 역시 수정됨.
- 개방 폐쇄 원칙, 즉 확장할 때는 개방, 수정할 때는 폐쇄라는 원칙을 따르기 위해 확장하는 방법에는 어떤것이 있을까?
    - 새로운 경고 알림을 추가하기 전에 Alert 클래스의 코드를 리팩터링하여 확장성을 높임
        - check() 함수의 여러 입력 매개변수를 ApiStatInfo 클래스로 캡슐화
        - 핸들러를 도입하여 if 판단 논리를 각 핸들러로 분배

~~~java
public class Alert {
    private List<AlertHandler> alertHandlers = new ArrayList<>();

    public void setAlertHandler(AlertHandler alertHandler) {
        this.alertHandlers.add(alertHandler);
    }

    public void check(ApiStatInfo apiStatInfo) {
        for (AlertHandler handler : alertHandlers) {
            handler.check(apiStatInfo);
        }
    }
}

// ... 

public class ApiStatInfo { // 생성자, getter, setter 메서드 생략
    private String api;
    private long requestCount;
    private long errorCount;
    private long duration;
}

// ...
public abstract class AlertHandler {
    protected AlertRule rule;
    protected Notification notification;

    public Alert(AlertRule rule, Notification notification) {
        this.rule = rule;
        this.notification = notification;
    }

    public abstract void check(ApiStatInfo apiStatInfo);
}

// .....
public class TpsAlertHandler extends AlertHandler {
    public TpsAlertHandler(AlertRule rule, Notification notification) {
        super(rule, notification);
    }

    @Override
    public void check(ApiStatInfo apiStatInfo) {
        long tps = apiStatInfo.getRequestCount() / apiStatInfo.getDuration();
        if(tps > rule.getMatchedRule(apiStatInfo.getApi()).getMaxTps()) {
            notification.notify(NotificationEmergencyLevel.URGENCY, "...");
        }
    }
}

// .....
public class ErrorAlertHandler extends AlertHandler {
    public ErrorAlertHandler(AlertRule rule, Notification notification) {
        super(rule, notification);
    }

    @Override
    public void check(ApiStatInfo apiStatInfo) {
        if(apiStatInfo.getErrorCount() > rule.getMatchedRule(apiStatInfo.getApi()).getMaxErrorCount()) {
            notification.notify(NotificationEmergencyLevel.SEVERE,"...");
        }
    }
}
~~~

- 이어서 리팩터링된 Alert 클래스의 구체적인 사용방법을 아래 코드를 통해 살펴보자.
~~~java
public class ApplicationContext {
    private AlertRule alertRule;
    private Notification notification;
    private Alert alert;
    
    public void initializeBeans() {
        alertRule = new AlertRule(/*매개변수 생략*/);
        notification = new Notification(/*매개변수 생략*/);
        alert = new Alert();
        alert.alertHandler(new TpsAlertHandler(alertRule, notification));
        alert.alertHandler(new ErrorAlertHandler(alertRule, notification));
    }
    
    public Alert getAlert() {
        return alert;
    }
    
    // 빈약한 도메인 기반의 싱글턴
    private static final ApplicationContext instance = new ApplicationContext();
    private ApplicationContext() {
        initializeBeans();
    }
    
    public static ApplicationContext getInstance() {
        return instance;
    }
}

public class Demo {
    public static void main(String[] args) {
        ApiStatInfo apiStatInfo = new ApiStatInfo();
        // apiStatInfo 데이터 값 설정 코드 생략
        ApplicationContext.getInstance().getAlert().check(apiStatInfo);
    }
}
~~~
- 리팩토링된 코드를 기반으로 앞의 경우와 같이 '초당 인터페이스 요청 횟수가 미리 설정된 최대값을 초과할 경우, 경고 알림이 설정되며 통지가 발송된다' 는 규칙을 적용하려면 어떻게 할까?
- 기본적으로 다음과 같이 네 부분을 변경해야 한다.
    1. ApiStatInfo 클래스에 새로운 timeoutCount 속성을 추가.
    2. 새로운 핸들러인 TimeoutAlertHandler 클래스 추가.
    3. ApplicationContext 클래스의 initializeBeans() 메서드에 alert 객체를 대상으로 TimeoutAlertHandler를 등록한다.
    4. Alert 클래스를 사용할 때 check() 함수의 입력 매개변수 apiStatInfo 객체에 대한 timeoutCount 속성값을 설정한다.
- 수정된 코드
~~~java
public class Alert {
    // 코드 변경 없음.
}

// ... 

public class ApiStatInfo { // 생성자, getter, setter 메서드 생략
    private String api;
    private long requestCount;
    private long errorCount;
    private long duration;
    //변경 1: timeoutCount 속성 추가.
    private long timeoutCount;
}

// ...
public abstract class AlertHandler {
    // 코드 변경 없음.
}

// .....
public class TpsAlertHandler extends AlertHandler {
  // 코드 변경 없음
}

// .....
public class ErrorAlertHandler extends AlertHandler {
   // 코드 변경 없음
}
// 변경 2: TimeoutAlertHandler 클래스 추가. 
public class TimeoutAlertHandler extends AlertHandler {
    public TimeoutAlertHandler(AlertRule rule, Notification notification) {
        super(rule, notification);
    }

    @Override
    public void check(ApiStatInfo apiStatInfo) {
        long timeoutTps = apiStatInfo.getTimeoutCount() / apiStatInfo.getDuration();
        if(timeoutTps > rule.getMatchedRule(apiStatInfo.getApi()).getMaxTimeoutTps()) {
            notification.notify(NotificationEmergencyLevel.URGENCY,"...");
        }
    }
}
~~~

~~~java
public class ApplicationContext {
    private AlertRule alertRule;
    private Notification notification;
    private Alert alert;
    
    public void initializeBeans() {
        alertRule = new AlertRule(/*매개변수 생략*/);
        notification = new Notification(/*매개변수 생략*/);
        alert = new Alert();
        alert.alertHandler(new TpsAlertHandler(alertRule, notification));
        alert.alertHandler(new ErrorAlertHandler(alertRule, notification));
        // 변경 3: TimeoutAlertHandler 등록
        alert.alertHandler(new TimeoutAlertHandler(alertRule, notification));
    }
    
    
    public Alert getAlert() {
        return alert;
    }
    
    // 빈약한 도메인 기반의 싱글턴
    private static final ApplicationContext instance = new ApplicationContext();
    private ApplicationContext() {
        initializeBeans();
    }
    
    public static ApplicationContext getInstance() {
        return instance;
    }
}

public class Demo {
    public static void main(String[] args) {
        ApiStatInfo apiStatInfo = new ApiStatInfo();
        // apiStatInfo 데이터 값 설정 코드 생략
        apiStatInfo.setTimeoutCount(289); // 변경 4: timeoutCount 값 설정
        ApplicationContext.getInstance().getAlert().check(apiStatInfo);
    }
}
~~~
- 이와 같이 리팩터링된 코드는 더 유연하고 확장하기 쉽다는 것을 한눈에 알 수 있다.
    - check() 메서드 변경 안해도 됨.
    - 기존의 클래스에 대한 단위 테스트를 매번 수정할 필요 없음. 새로 추가된 핸들러 클래스에 대한 테스트를 추가하는 것으로도 충분하다.
### 3.2.2. 코드를 수정하는 것은 개방 폐쇄 원칙을 위반하는 것일까?
- 첫번째 변경사항
    - timeoutCount 속성을 ApiStatInfo 클래스에 추가.
        - 클래스 입장에서 보면 이 변경 사항들은 수정으로 간주될 수 있으나 이 변경 사항이 기존 속성을 변경하거나 메소드를 수정하지 않았음.
            - 속성이나 메서드 입장에서 보면 확장으로 간주.
            - 개방 폐쇄 원칙의 기본적인 목적을 다시 떠올려 보면.. 코드의 수정이 기존에 작성되었던 코드와 단위 테스트를 깨트리지 않는 한, 이는 개방 폐쇄 원칙을 위반하지 않는다고 판단해도 무방하다.
- 세번째, 네번째 변경사항
    - ApplicationContext 클래스의 initializeBeans() 메서드에서 alert 객체에 TimeoutAlertHandler를 등록
    - Alert 클래스를 사용할 때 check() 함수의 apiStatInfo 객체에 timeoutCount 속성값을 설정.
    - 이 변경사항은 기본적으로 메서드 단위 내에서 변경이 이루어지기 때문에 확장이 아닌 수정으로 간주.
        - 그러나 이와 같은 수정은 불가피하며 개방 폐쇄 원칙에서도 허용.
            - 새 경고 알림을 추가할 때 Alert 클래스의 논리를 수정할 필요가 없음.
                - 새로운 기능이 담긴 핸들러 클래스만 추가하면 됨.
                - 따라서 Alert 클래스와 그 핸들러 클래스의 모듈로 간주하면 모듈 수준에서 새 기능을 추가하기 위해 논리를 수정할 필요 없이 확장만 이루어진 것이라고 볼 수 있음.

### 3.2.3. 확장할 때는 개방, 수정할 때는 폐쇄를 달성하는 방법.
- 확장 가능한 코드를 작성하려면 확장, 추상화, 캡슐화에 대해 인식하고 있는 것이 매우 중요함.
    - 이는 개발 기술 자체보다 훨씬 중요할 수 있음.
- 코드의 변경 가능한 부분과 변경할 수 없는 부분을 잘 식별해야 함.
- 변경되는 사항을 기존 코드와 분리할 수 있도록 변수 부분을 캡슐화하고, 상위 시스템에서 사용되는 변경되지 않을 추상 인터페이스를 제공.
- 코드 확장성을 개선하기 위해 설계 원칙과 디자인 패턴에서 많이 사용되고 있는 방법
    - 다형성, 의존성 주입, 구현이 아닌 인터페이스 기반의 프로그래밍.
        - 이는 전략 패턴, 템플릿 메서드, 책임 연쇄 패턴과 같은 대부분의 디자인 패턴에서 볼 수 있음.

### 3.2.4. 프로젝트에 개방 폐쇄 원칙을 유연하게 적용하는 방법
- 확장 포인트를 미리 준비해두는 것.
    - 확정 포인트가 어디인지 어떻게 알 수 있을까?
        - 비즈니스에 대한 충분한 이해
        - 그렇지 않으면 추후 추가될 가능성이 있는 비즈니스 요구 사항을 예측하기 힘들어짐.
    - 하지만 비즈니스와 시스템에 대해 충분히 알고 있더라도 모든 확장 포인트를 미리 준비하는 건 불가.
        - 해당 포인트를 전부 개발하는 데 드는 리소스가 과할 때가 대부분.
- 일반적으로 추천하는 방법은 단기간 내에 진행할 수 있는 확장, 코드 구조 변경에 미치는 영향이 비교적 큰 확장, 구현 비용이 많이 들지 않는 확장에 대해 확장 포인트를 미리 준비하는 것.
    - 반면에 향후 지원해야 하는지 여부가 확실하지 않은 요구 사항이니 확장이 오히려 코드 개발에 부하를 주는 경우에는 해당 작업이 실제로 필요할 때 리팩터링 하는것이 더 나을 수 있음.
- 코드의 확장성과 가독성 사이에서 적절한 균형이 필요
    - 만약 위의 Alert 클래스에서 경고 알림 규칙이 서너개에 불과하다면 check() 메서드의 구현 역시 간단할 것이기 때문에 굳이 추후의 요구사항 변동을 걱정하며 리팩토링 할 필요 없음.
    - 나중에 경고 알림이 대량으로 추가되는 상황이 발생한다면 check() 메서드에서 if 분기가 기하급수적으로 늘어날 것이고 그에 따라 코드 논리가 복잡해질 뿐만 아니라 코드의 크기도 늘어나기 때문에, 그 때 코드를 리팩터링 하면 될 것 이다. 
