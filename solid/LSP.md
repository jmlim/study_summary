>  출처 : 디자인패턴의 아름다움
>


## 3.3. 리스코프 치환 원칙
- 리스코프 치환 원칙의 정의를 소개.
- 리스코프 치환 원칙과 다형성의 차이점.
### 3.3.1. 리스코프 치환 원칙의 정의
- 만약 S가 T의 하위 유형인 경우, T유형의 객체는 프로그램을 중단하지 않고도 S유형의 객체로 대체될 수 있다.
- 리스코프 치환 원칙은 앞의 리스코프와 마틴의 설명을 조합하여 다음과 같이 정의할 수 있다.
    - 하위 유형 또는 파생 클래스의 객체는 프로그램 내에서 상위 클래스가 나타나는 모든 상황에 대체 가능하며, 프로그램이 원래 가지는 논리적인 동작이 변경되지 않으며 정확성도 유지된다.
- 리스코프 치환 원칙의 정의는 상대적으로 추상적이므로 코드를 통해 설명.
    - 상위 클래스인 Transporter 클래스는 org.apache.http 라이브러리의 HttpClient 클래스를 사용하여 네트워크 데이터를 전송.
    - 하위 클래스인 SecurityTransporter 클래스는 상위 클래스인 Transporter 클래스를 상속받아 보안 인증 정보인 appId와 appToken을 데이터 전송 시 추가한다.

~~~java
public class Transporter {
    private HttpClient httpClient;

    public Transporter(HttpClient httpClient) {
        this.httpClient = httpClient;
    }

    public Response sendRequest(Request request) {
        // HttpClient 를 통해 발송 요청하는 코드 생략
    }
}

// ....

public class SecurityTransporter extends Transporter {
    private String appId;
    private String appToken;

    public SecurityTransporter(HttpClient httpClient, String appId, String appToken) {
        super(httpClient);
        this.appId = appId;
        this.appToken = appToken;
    }

    @Override
    public Response sendRequest(Request request) {
        if (StringUtils.isNotBlank(appId) && StringUtils.isNotBlank(appToken)) {
            request.addPayload("app-id", appId);
            request.addPayload("app-token", appToken);
        }

        return super.sendRequest(request);
    }
}

// ...
public class Demo {
    public static void main(String[] args) {
        Request request = new Request();
        // ..request 객체에 값을 설정하는 코드 생략...
        Response response = transPorter.sendRequest(request);
        // 일부 코드 생략...
    }
}

// 리스코프 치환 원칙
Demo demo = new Demo();
demo.demofunction(new SecurityTransporter(/* 매개변수 생략* ));
~~~
- 위 코드에서 하위 클래스인 SecurityTransporter 클래스의 설계는 리스코프 치환 원칙을 따르기 때문에, 해당 객체는 상위 클래스 객체가 나타나는 모든 위치에서 대체될 수 있음.

### 3.3.2. 리스코프 치환 원칙과 다형성의 차이점.
- 앞에서 작성한 코드의 설계는 사실상 객체지향의 특성인 다형성을 단순하게 이용한 것이 아닐까 하는 의구심이 들 수 있음.
    - 그럼 다형성과 리스코프 치환 원칙은 같은것이라고 봐도 되는 것일까?
    - 보기에는 비슷하지만 실제로는 완전히 다른 의미를 담음.
- 위 코드를 약간 수정해보자.

~~~java
// 수정 전:
public class SecurityTransporter extends Transporter {
    private String appId;
    private String appToken;

    public SecurityTransporter(HttpClient httpClient, String appId, String appToken) {
        super(httpClient);
        this.appId = appId;
        this.appToken = appToken;
    }

    @Override
    public Response sendRequest(Request request) {
        if (StringUtils.isNotBlank(appId) && StringUtils.isNotBlank(appToken)) {
            request.addPayload("app-id", appId);
            request.addPayload("app-token", appToken);
        }

        return super.sendRequest(request);
    }
}

// 수정 후
public class SecurityTransporter extends Transporter {
    private String appId;
    private String appToken;

    public SecurityTransporter(HttpClient httpClient, String appId, String appToken) {
        super(httpClient);
        this.appId = appId;
        this.appToken = appToken;
    }

    @Override
    public Response sendRequest(Request request) {
        if (StringUtils.isBlank(appId) || StringUtils.isBlank(appToken)) {
           throw new NoAuthorizationRuntimeException(...);
        }
        request.addPayload("app-id", appId);
        request.addPayload("app-token", appToken);
        return super.sendRequest(request);
    }
}

// 리스코프 치환 원칙
Demo demo = new Demo();
demo.demofunction(new SecurityTransporter(/* 매개변수 생략* ));
~~~

- 수정된 코드에서는 appId 속성이나 appToken이 설정되지 않으면 NoAuthorizationRuntimeException 발생.
    - 하위 클래스인 SecurityTransporter 클래스의 객체가 demoFunction() 메서드로 전달되면 예외를 발생시킬 수 있음.
- 수정된 코드는 여전히 java의 다형성 구문을 통해 동적으로 상위 클래스인 Transporter 클래스를 하위 클래스인 SecurityTransporter 클래스로 대체할 수 있으며, 오류가 발생하지 않음.
    - 그러나 설계 관점에서 살펴보면 SecurityTransporter 클래스의 설계는 리스코프 치환 원칙을 따르지 않음.
        - 다형성은 코드를 구현하는 방식에 해당되지만.. 리스코프 치환 원칙은 상속 관계에서 하위 클래스의 설계 방식을 설명하는 설계 원칙에 해당한다.
    - 상위 클래스를 대체할 때 프로그램의 원래 논리적 동작이 변경되지 않고 프로그램의 정확성이 손상되지 않도록 해야 한다.

### 3.3.3. 리스코프 치환 원칙을 위반하는 안티패턴
- 계약에 따른 설계
    - 하위 클래스를 설계할 때는 상위 클래스의 동작 규칙을 따라야 한다.
        - 상위 클래스는 함수의 동작 규칙을 정의하고 하위 클래스는 함수의 내부 구현 논리를 변경할 수 있지만 함수의 원래 동작 규칙을 변경할 수 없다.
        - 여기서 언급된 상위 클래스와 하위 클래스간의 관계는 인터페이스와 구현 클래스 간의 관계로 대체될 수도 있다.
#### 하위 클래스가 구현하려는 상위 클래스에서 선언한 기능을 위반하는 경우.
- 예를 들어 상위 클래스가 주문 정렬을 위한 sortOrdersByAmount() 함수를 정의하여 금액에 따라 작은 것부터 큰 것 순서대로 주문을 정렬하게 구성되어 있을 때..
    - 하위 클래스에서 생성 날짜에 따라 주문을 정렬하도록 sortOrdersByAmount() 함수를 재정의하는 경우
        - 리스코프 치환 원칙 위반
#### 하위 클래스가 입력, 출력, 및 예외에 대한 상위 클래스의 계약을 위반하는 경우
- 어떤 함수의 계약에 따르면 상위 클래스에서 작업 시 오류가 발생하면 null을 반환하며, 값을 얻을 수 없을 때는 빈 컬렉션을 반환하지만..
    - 하위 클래스에서 이 함수를 재정의하면서 구성이 변경되어 작업 시 오류가 발생하면 null 대신에 예외를 발생시키고, 값을 얻을 수 없을 때는 null 을 반환한다면
        - 이 하위 클래스의 설계는 리스코프 치환 원칙을 위반하는 것이다.
- 다른예로.. 상위 클래스에서는 입력 시 모든 정수를 받아들일 수 있지만, 하위 클래스에서 이 함수를 재정의하면서 양의 정수만 받아들일 수 있도록 변경되고, 음의 정수가 입력될 경우 예외를 발생시킨다면?
    - 하위 클래스의 유효성 검사가 상위 클래스의 유효성 검사보다 훨씬 엄격하게 변경된 것이며, 결과적으로 이 하위 클래스의 설계는 리스코프 치환 원칙을 위배한 것.
- 또한 상위클래스에서 던지는 예외가 ArgumentNullException 예외 하나뿐이라면?
    - 하위 클래스에서 이 함수를 재정의 하더라도 여전히 ArgumentNullException 예외만 발생시킬 수 있다.
#### 하위 클래스가 상위 클래스의 주석에 나열된 특별 지침을 위반하는 경우.
- 상위 클래스에 예금을 인출하는 함수인 withdraw() 함수가 정의되어 있으며, 주석에 사용자의 출금 금액이 계정 잔액을 초과해서는 안된다고 명시되어 있는 경우와 VIP 계정에 대한 처리를 담당하는 하위 클래스에서 재정의된 withdraw() 함수가 당좌 인출 기능을 지원하는 경우는
    - 인출 금액이 현재 계정 잔액보다 클 수 있는데, 이 하위 클래스의 설계는 리스코프 치환 원칙을 위반한다.
- 이런 경우에 하위 클래스의 설계가 리스코프 치환 원칙을 만족하게 하려면, 상위 클래스의 주석을 수정하는 것이 훨씬 간단한 방법이다.

> 앞에서 설명한 세 가지 패턴은 리스코프 치환 원칙을 위반하는 전형적인 안티 패턴.
> 또한 원칙 위반 여부 판단 방법 중에는 상위클래스의 단위 테스트를 통해 하위 클래스의 코드를 확인하는 방법도 있음.
