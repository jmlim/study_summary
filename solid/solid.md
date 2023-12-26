>  출처 : 디자인패턴의 아름다움

- SOLID, KISS, YAGNI, DRY, LoD 와 같은 고전적인 설계 원칙 몇가지 소개
- 설계 원칙에 대해 **이해**하는것도 중요하지만, 그보다는 실제 프로젝트에서 사용하는 방법을 정확하게 알고 있어야 함.
## 3.1. 단일 책임 원칙
### 3.1.1. 단일 책임 원칙의 정의 및 해석
 - 단일 책임 원칙(single responsibility principle), SRP 이란 클래스와 모듈은 하나의 책임 또는 기능만 가지고 있어야 한다는 설계 원칙이다. 
 - 주의할 점
   - 단일 책임 원칙이 설명하는 대상에는 클래스와 모듈이라는 두 가지 종류가 있다는 점.
   - 이 두 가지 개념에 대해 두 가지 이해 방식이 있음.
     - 첫 번째 방식은 모듈을 클래스보다 더 추상적인 개념으로 간주하고 클래스를 일종의 모듈로 간주하는 것.
     - 두 번째 방식은 모듈을 좀 더 포괄적인 범위의 대상으로 놓고, 여러 클래스가 하나의 모듈을 구성한다고 간주하는 것.
   - 단일 책임 원칙을 어떤 방식으로 이해하든, 클래스와 모듈에 적용할 때는 서로 의미가 동일하다.
 - 단일 책임 원칙은 클래스가 하나의 책임이나 기능만을 담당한다는 것을 의미.
   - 즉, 거대하고 포괄적인 클래스를 설계하는 대신, 작은 기능을 가진 클래스를 설계해야 한다.
   - 클래스에 비즈니스와 관련 없는 기능이 두 개 이상 포함되어 있으면 책임이 단일하지 않으므로, 단일 기능을 가진 여러 개의 작은 클래스로 분할되어야 한다고 생각할 수 있다.
   - 예를 들어 어떤 클래스에 주문 관련 코드와 사용자 관련 코드가 모두 포함되어 있다고 하자.
     - 주문과 사용자는 두 개의 독립적인 비즈니스 도메인 모델이며, 관련이 없는 두 기능을 동일한 클래스에 넣는것은 단일 책임 원칙에 위배.
     - 단일 책임 원칙을 충족하기 위해 이 클래스를 더 작게 세분화하여 단일 기능을 가진 두 개의 클래스인 주문 클래스와 사용자 클래스로 분할해야 한다.
### 3.1.2. 클래스에 단일 책임이 있는지 판단하는 방법
~~~java
public class UserInfo {
    private long userId;
    private String username;
    private String email;
    private String telephone;
    private long createTime;
    private long lastLoginTime;
    private String avatarUrl;
    private String provinceOfAddress; // 도
    private String cityOfAddress; // 시
    private String regionOfAddress; // 구
    private String detailedAddress; // 상세주소
}
~~~
- 이 질문에 대해 크게 두 가지 다른 견해가 있을 수 있음.
  - UserInfo 클래스에는 사용자와 관련된 정보가 포함되어 있고 모든 속성과 메소드가 사용자와 같은 비즈니스 모델에 속해 있어 단일 책임 원칙을 만족한다는 관점
  - UserInfo 클래스에서 주소 정보의 비율이 상대적으로 높기 때문에 주소 정보를 독립적인 UserAddress 클래스로 분할할 수 있으며 UserInfo 클래스는  주소 정보를 제외한 다른 정보만 보유하도록 하여 두 클래스의 책임을 단일화할 수 있다는 관점이다. 
- 어느 견해가 타당한거지?
  - 사실 어느 한쪽을 선택하려면 시나리오를 살펴볼 필요가 있음.
    - 만약 이 소셜 네트워크 제품에서 사용자의 주소 정보가 다른 사용자 정보와 동일하게 정보 표시에만 사용되며, 다른 정보와 함께 사용된다면 UserInfo 클래스의 현재 설계가 합리적이라고 할 수 있다.
    - 그러나 이 소셜 네트워크 상품이 발전하여 전자 상거래 기능 모듈이 제품에 추가되면 사용자의 주소 정보는 표시를 위해 사용될 뿐만 아니라 전자 상거래의 물류에 독립적으로 적용될 가능성이 생긴다.
      - 이 경우엔 주소 정보를 UserInfo 클래스에서 분리해 독립적인 물류 배송 정보를 구축하는게 좋음.
    - 이 소셜 네트워크 제품을 개발한 회사가 성장해 더 많은 제품을 개발할 수도 있음.
      - 이때 회사의 모든 제품이 통합 계정 시스템을 지원하기 원할 것이다. 이 경우에는 계속해서 UserInfo 클래스를 분할해서 본인 인증과 관련된 email, telephone과 같은 속성을 별도의 클래스로 추출해야 할 것 이다. 
  - 이런 예를 통해 동일한 클래스라 할지라도 다른 응용 시나리오나 다른 단계의 요구사항에 따라 클래스의 책임이 단일한지 아닌지를 판단하는 것이 다를 수 있다는 점을 알 수 있다.
    - 응용 시나리오를 변경하거나 요구사항이 이후 달라질 경우에는 해당 클래스의 설계가 단일 책임 원칙을 충족하지 못할 수 있음. 
      - 더 작은 클래스로 분할해야 함.
- 클래스에 단일 책임이 있는지를 평가하기 위한 명확하고 정량화할 수 있는 표준은 존재하지 않음.
  - 과도하게 너무 세분화해서 설계할 필요 없음.
  - 사업이 발전하면서 클래스에 기능이 점점 추가되고, 코드가 점점 더 복잡해지면서 거대해진 클래스를 여러개의 세분화된 클래스로 나눌 수 있을 것임.
- 단일 책임 여부를 결정하기 위해 사용되는 몇 가지 결정 원칙
  1. 클래스에 코드, 함수 또는 속성이 너무 많아 코드의 가독성과 유지 보수성에 영향을 미치는 경우 클래스 분할을 고려해야 한다.
  2. 클래스가 너무 과하게 다른 클래스에 의존한다면, 높은 응집도와 낮은 결합도의 코드 설계 사상에 부합되지 않으므로 클래스 분할을 고려해야 한다.
  3. 클래스에 private 메소드가 너무 많은 경우 이 private 메서드를 새로운 클래스로 분리하고 더 많은 클래스에서 사용할 수 있도록 public 메소드로 설정하여 코드의 재사용성을 향상시켜야 한다.
  4. 클래스의 이름을 비즈니스적으로 정확하게 지정하기 어렵거나 Manager, Context처럼 일반적인 단어가 아니면 클래스의 이름을 정의하기 어려울 경우, 클래스 책임 정의가 충분히 명확하지 않음을 의미할 수 있다.
  5. UserInfo 클래스의 많은 메서드가 주소를 위해서만 구현된 앞의 예시처럼 클래스의 많은 메서드가 여러 속성 중 일부에서만 작동하는 경우 이러한 속성과 해당 메서드를 분할하는 것을 고려할 수 있다.

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