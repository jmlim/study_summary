>  출처 : 디자인패턴의 아름다움

- SOLID, KISS, YAGNI, DRY, LoD 와 같은 고전적인 설계 원칙 몇가지 소개
- 설계 원칙에 대해 **이해**하는것도 중요하지만, 그보다는 실제 프로젝트에서 사용하는 방법을 정확하게 알고 있어야 함.

## 3.5. 의존 역전 원칙
### 3.5.1. 제어 반전
~~~java
public class UserServiceTest {
    public static boolean doTest() {
        // ...
    }

    // 이 코드는 프레임워크에 넣을 수 있음.
    public static void main(String[] args) {
        if(doTest()) {
            System.out.println("Test succeed.");
        } else {
            System.out.println("Test failed.");
        }
    }
}
~~~
 - 위 코드는 어떠한 테스트 프레임워크에도 의존하지 않는 테스트 코드.
   - 테스트 코드의 실행 과정을 외부에서 직접 작성하고 제외할 수 있는 코드
   - 하지만 이 코드에서 테스트 프레임워크를 추상화할 수 있기 때문에 다음 예제 코드처럼 변경 할 수 있음.
~~~java
public abstract class TestCase {
    public void run() {
        if(doTest()) {
            System.out.println("Test succeed.");
        } else {
            System.out.println("Test failed.");
        }
    }
    
    public abstract boolean doTest();
}

public class JunitApplication {
    private static final List<TestCase> testCases = new ArrayList<>();
    
    public static void register(TestCase testCase) {
        testCases.add(testCase);
    }

    public static void main(String[] args) {
        for(TestCase testCase: testCases) {
            testCase.run();
        }
    }
}
~~~
 - 이 코드는 테스트 프레임워크를 단순화한 것.
   - 특정 클래스를 테스트하려면 TestCase 클래스의 실행 흐름을 담당하는 main() 함수를 직접 작성할 필요 없이 프레임워크에서 제공하는 확장 포인트인 doTest() 추상 메서드에 테스트 코드를 채우기만 하면 됨.
~~~java
public class UserServiceTest extends TestCase {
    @Override
    public boolean doTest() {
        //.... 
    }
}

// 명시적으로 register() 를 호출하여 등록하는 대신 설정을 통해 구현할 수도 있다.
// JunitApplication.register(new UserServiceTest());
~~~
 - 위의 예제 코드는 프레임워크를 통해 구현된 제어 반전의 일반적인 형태.
   - 프레임워크는 객체를 조합하고 전체 실행 흐름을 관리하기 위한 확장 가능한 코드 골격을 제공.
 - 여기서 제어는 프로그램의 실행 흐름을 제어하는 것을 의미
 - 역전이 되는 대상은 프레임워크를 사용하기 전에 직접 작성했던 전체 프로그램 흐름의 실행을 제어하는 코드.
 - 프레임워크를 사용한 후 전체 프로그램의 실행 흐름은 프레임워크에 의해 제어되고, 흐름의 제어는 프로그래머에서 프레임워크로 역전되는 것.
### 3.5.2. 의존성 주입
 - 제어 반전과 달리 의존성 주입은 특정한 프로그래밍 기술.
 - 한문장으로 요약.
   - new 예약어를 사용하여 클래스 내부에 종속되는 클래스의 객체를 생성하는 대신, 외부에서 종속 클래스의 객체를 생성한 후 생성자, 함수의 매개변수 등을 통해 클래스에 주입하는 것을 의미 함.
### 3.5.3. 의존성 주입 프레임워크
 - 실제 소프트웨어 개발 시에는 수십, 수백 개의 클래스가 필요할 수 있으며, 이에 따라 클래스 객체의 생성과 의존성 주입은 매우 복잡해짐.
 - 이 작업을 프로그래머가 직접 코드를 작성하는 방식으로 진행한다면 오류가 발생하기 쉽고 개발 리소스도 많이 듬.
 - 객체 생성과 의존성 주입은 비즈니스 논리에 속하지 않기 때문에 프레임워크에 의해 자동으로 완성되는 코드 형태로 완전히 추상화될 수 있다.
   - 이러한 프레임워크를 의존성 주입 프레임워크라고 함.
### 3.5.4. 의존 역전 원칙
 - 상위 모듈은 하위 모듈에 의존하지 않아야 하며, 추상화에 의존해야만 한다.
   - 또한 추상화가 세부 사항에 의존하는 것이 아니라, 세부 사항이 추상화에 의존해야 한다.
 - 상위 모듈과 하의 모듈을 어떻게 구분?
   - 호출자는 상위 모듈에 속하고, 수신자는 하위 모듈에 속함.
   - 의존 역전 원칙은 앞에서 언급했던 제어 반전과 유사하게 프레임워크의 설계를 사용하도록 하는 데 주로 사용된다.