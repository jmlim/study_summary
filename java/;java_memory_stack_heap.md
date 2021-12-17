## Java 의 Stack 과 Heap

### Stack
 - Heap 영역에 생성된 Object 타입의 데이터의 참조값이 할당됨.
 - 원시(primitive)타입의 데이터가 값과 함께 할당됨.
 - 각 지역변수들은 scope 에 따른 visibility 를 가짐.
 - 각 Thread 는 자신만의 stack 을 가짐
 

* 스택 영역에 있는 변수들은 visibility 를 가진다.
  * 변수 스코프에 대한 개념.
* 전역변수가 아닌 지역변수가 foo() 라는 함수내에서 Stack 에 할당된 경우, 해당 지역변수는 다른 함수에서 접근할 수 없다.
  * ex) foo() 라는 함수에서 bar() 함수를 호출하고 bar() 함수의 종료되는 중괄호 } 가 실행된 경우 (함수가 종료된 경우), bar() 함수 내부에서 선언한 모든 지역변수들은 stack 에서 pop 되어 사라진다.

* Stack 메모리는 Thread 하나당 하나씩 할당된다. 
  * 즉, 쓰레드 하나가 새롭게 생성되는 순간 해당 쓰레드를 위한 stack도 함께 생성되며, 각 쓰레드에서 다른 쓰레드의 stack 영역에는 접근할 수 없다.

### Heap 

 - Heap 영역에는 주로 긴 생명주기를 가지는 데이터들이 저장된다. (대부분의 오부젝트는 크기가 크고, 서로 다른 코드블럭에서 공유되는 경우가 많음)
 - 애플리케이션의 모든 메모리 중 stack 에 있는 데이터를 제외한 부분이라고 보면 된다.
 - 모든 Object 타입(Integer, String, ArrayList.. ) 은 heap 영역에 생성된다.
 - 몇개의 쓰레드가 존재하든 상관없이 단 하나의 heap 영역만 존재한다.
 - Heap 영역에 있는 오브젝트들을 가리키는 레퍼런스 변수가 stack 에 올라가게 된다.

### immutable class
 - String 은 불변객체로써 변경하는 연산이 수행될 경우 변경하는 것 처럼 보이지만 실제 메모리에는 새로운 객체가 할당된다.
 - Wrapper class 에 해당하는 Integer, Character, Byte, Boolean, Long, Double, Float, Short 클래스는 모두 Immutable 이다. 그래서 heap 에 있는 같은 오브젝트를 레퍼런스 하고 있는 경우라도, 새로운 연산이 적용되는 순간 새로운 오브젝트가 Heap 에 새롭게 할당된다.
   - ex) Integer 클래스의 구현을 보면 클래스에 final 키워드가 분어있음. 
     - 상속을 제한하는 목적으로 해당 제어자를 붙임.
     - Wrapper Class 들도 String 처럼 Immutable 한 오브젝트가 되는 것.



### 출처 : https://yaboong.github.io/java/2018/05/26/java-memory-management/
 - 그림까지 예시로 들어서 설명한 아주 좋은 자료
