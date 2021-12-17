## Garbage Collection

- JVM 의 Garbage Collector 는 Unreachable Object를 우선적으로 메모리에서 제거하여 메모리 공간을 확보.
    - Unreachable Object 란 Stack 에서 도달할 수 없는 Heap 영역의 객체를 말함.
    - 이런경우 Garbage Collection 이 일어나면 Unreachable 오브젝트들은 메모리에서 제거됨.

- Garbage Collection 과정은 Mark and Sweep 이라고 함.
    - JVM의 Garbage Collector 가 스택의 모든 변수를 스캔하면서 각각 어떤 오브젝트를 레퍼런스 하고 있는지 찾는 과정이 "Mark" 이다.
        - Reachable 오브젝트가 레퍼런스라고 있는 Object 또한 marking 한다.
        - 첫번째 단계인 marking 작업을 위하 모든 쓰레드는 중단되는데 이를 "Stop the world" 라고 부르기도 한다.
            - System.gc()를 생각없이 호출하면 안되는 이유.
        - 그리고 "mark 되어있지 않은 모든 오브젝트들을 힙에서 제거하는 과정이 Sweep" 이다.

- Garbage Collection 이라고 하면 실제로는 garbage를 수집하여 제거하는 것이 아닌 garbage가 아닌것을 따로 mark 하고 그 외의 것은 모두 지우는 것이다.
    - 만약 힙에 garbage 만 가득하다면 제거 과정은 즉각적으로 이루어진다.

### Heap - Old & Young (Eden, Survivor)

 <img src="/java/java-memory-management_gc-6.png" />

- Heap 은 Young Generation, Old Generation 으로 크게 두개의 영역으로 나뉘어짐.
- Young Generation 은 또 다시 Eden, Survivor Space 0, 1 로 세분화 되어짐.
    - S0, S1 으로 표시되는 영역

### 가비지 컬렉션 프로세스.

1. 새로은 오브젝트는 Eden 영역에 할당된다.
2. Eden 영역이 가득차면, MinorGC 가 발생한다.
3. MinorGC 가 발생하면, Reachable 오브젝트들은 S0으로 옮겨진다. Unreachable 오브젝트들은 Eden 영역이 클리어 될 때 함께 메모리에서 사라진다.
4. 다음 MinorGC 가 발생할 때 Eden 영역에는 3번과 같은 과정이 발생한다.
    1. Unreachable 오브젝트들은 지워지고, Reachable 오브젝트들은 Survivor Space 로 이동한다.
    2. 기존에 S0에 있었던 Reachable 오브젝트들은 S1으로 옮겨지는데, 이때 age 값이 증가되어 옮겨짐.
    3. 살아남은 모든 오브젝트들이 S1으로 모두 옮겨지면, S0 와 Eden 은 클리어 된다.
    4. Survivor Space 에서 Survivor Space 로의 이동은 이동할때마다 age 값이 증가한다.
5. 다음 MinorGC 가 발생하면, 4번 과정이 반복되는데, S1이 가득차 있었으므로 S1에서 살아남은 오브젝트들은 S0으로 옮겨지면서 Eden 과 S1은 클리어된다.
    1. 이때에도 age 값이 증가되어 옮겨진다.
    2. Survivor Space 에서 Survivor 로의 이동은 이동할때마다 age 값이 증가.
6. Young Generation 에서 계속해서 살아남으며 age값이 증가하는 오브젝트들은 age 값이 특정값 이상이 되면 Old Generation 으로 옮겨지는데 이 단계를 Promotion 이라고 함.
7. MinorGC 가 계속해서 반복되면, Promotion 작업도 꾸준히 발생하게 된다.
8. Promotion 작업이 계속해서 반복되면서 Old Generation 이 가득차게 되면 MajorGC 가 발생하게 된다.

### 용어정리

- MinorGC : Young Generation 에서 발생하는 GC
- MajorGC : Old Generation (Tenured Space) 에서 발생하는 GC
- FullGC : Heap 전체를 clear 하는 작업 (Young/Old 공간 모두)

## Garbage Collector 종류

### Serial GC

~~~
-XX:+UserSerialGC
~~~

- SerialGC 는 Java SE 5, 6 에서 디폴트 가비지로 컬렉터로 사용된다.
    - MinorGC, MajorGC 모두 순차적으로 시행
    - Mark-Compact Collection Method 를 사용
        - Mark-Compact Collection Method 란, 새로운 메모리 할당을 빠르게 하기 위해서 기존의 메모리에 있던 오브젝트들을 힙의 시작위치로 옮겨놓는 방법이다.
        - 창고에서 필요없는 물건들을 버린 후, 창고에 물건을 차곡차곡 쌓기위해 창고안을 정리하는 것이라 생각할 수 있다.
- Serial GC는 서버의 CPU 코어가 1개일 때 사용하기 위해 개발되었으며, 모든 가비지 컬렉션 일을 처리하기 위해 1개의 쓰레드만을 이용한다.
    - 그렇기 때문에 CPU의 코어가 여러 개인 운영 서버에서 Serial GC를 사용하는 것은 반드시 피해야 한다.

### Parallel GC

~~~
-XX:+UseParallelGC

## 사용할 쓰레드의 갯수 -XX:ParallelGCThreads=<N> 
## 최대 지연 시간 -XX:MaxGCPauseMillis=<N>
## Old Generation 의 가비지 컬렉션에서도 멀치쓰레딩 활용 : -XX:+UseParallelOldGC
~~~

- Parallel GC는 Throughput GC로도 알려져 있으며, 기본적인 처리 과정은 Serial GC와 동일.
    - 하지만 Parallel GC는 여러 개의 쓰레드를 통해 Parallel하게 GC를 수행함으로써 GC의 오버헤드를 상당히 줄여준다.
    - Parallel GC는 멀티 프로세서 또는 멀티 쓰레드 머신에서 중간 규모부터 대규모의 데이터를 처리하는 애플리케이션을 위해 고안되었으며, 옵션을 통해 애플리케이션의 최대 지연 시간 또는 GC를 수행할
      쓰레드의 갯수 등을 설정해줄 수 있다.
- Parallel GC 가 GC의 오버헤드를 상당히 줄여주었고, Java8 까지 기본 가비지 컬렉터로 사용됨.
    - 하지만 Application 이 멈추는 것을 피할 수 없었고, 이러한 부분을 개선하기 위해 다른 알고리즘이 더 등장하게 됨.

### Concurrent Mark Sweep (CMS) Collector

~~~
-XX:+UseConcMarkSweepGC
~~~

- 대부분의 가비지 컬렉션 작업을 애플리케이션 쓰레드와 동시에 수행함으로써 가비지 컬렉션으로 인한 stop the world 시간을 최소화 하는 GC
    - CMS GC 가 수행될 때에는 자원이 GC를 위해서도 사용되므로 응답이 느려질 순 있지만 응답이 멈추지는 않게 됨.
    - 하지만 이러한 CMS GC 는 다른 GC 방식보다 메모리와 CPU를 더 많이 필요로 하며 Compaction 단계를 수행하지 않는 단점이 있음.
    - 이 때문에 시스템이 장기적으로 운영되다가 조각난 메모리들이 많이 Compaction 단계가 수행되면 오히려 Stop the world 시간이 길어지는 문제가 발생.
- young generation 에 대한 가비지 컬렉션시 Parallel GC 와 같은 알고리즘을 사용하는데, -XX:ParallelCMSThreads=<N> 옵션으로 스레드 개수를 설정 가능.
- CMS GC는 Java9 버젼부터 deprecated 되었고 결국 Java14에서는 사용이 중지되었다고 함.

### G1 Garbage Collector

~~~
 -XX:+UseG1GC
~~~

```
G1GC (Garbage First Garbage Collector)는 대용량의 메모리가 있는 멀티 프로세서 시스템을 위해 제작.
빠른 처리 속도를 달성하면서 일시 중지 시간(STW : Stop The World)의 최소화를 충족시키기는 것이 G1GC의 목표.
```

- Java 7 부터 사용가능하며, 장기적으로 CMS 컬렉터를 대체하기 위해 만들어짐.
- G1은 이름을 보면 짐작할 수 있듯, 쓰레기로 가득찬 heap 영역을 집중적으로 수집.
- G1은 큰 메모리를 가진 멀티 프로세서 시스템에서 사용하기 위해 개발된 GC.
- G1은 Java 9부터 디폴트 GC이다.
- G1은 실시간(real time) GC가 아니다. 일시 정지 시간을 최소화하긴 하지만 완전히 없애지는 못함.
- G1은 통계를 계산해가면서 GC 작업량을 조절.

### 다음 상황이라면 G1을 쓰면 도움이 된다.

- Java heap의 50% 이상이 라이브 데이터.
- 시간이 흐르면서 객체 할당 비율과 프로모션 비율이 크게 달라진다.
- GC가 너무 오래 걸린다(0.5 ~ 1초).

### 작동 방식.

- 전체 heap 을 체스판처럼 여러 영역으로 나누어 관리.
- G1은 영역의 참조를 관리할 목적으로 remember set를 만들어 사용한다. remember set은 total heap의 5% 미만 크기.
    - 비어 있는 영역에만 새로운 객체가 들어간다.
    - 쓰레기가 쌓여 꽉 찬 영역을 우선적으로 청소한다.
    - 꽉 찬 영역에서 라이브 객체를 다른 영역으로 옮기고, 꽉 찬 영역은 깨끗하게 비운다.
    - 이렇게 옮기는 과정이 조각 모음의 역할도 한다.

<img src="/java/g1gc-layout.png" />

- 빨간색은 Eden으로 쓰이고 있는 영역을 의미.
- 빨간색 S는 Survivor. Eden이 꽉 차면 라이브 객체를 S로 옮기고 Eden은 비워버린다.
- 파란색은 old gen 처럼 쓰이고 있는 영역이다.
- 파란색 H는 한 영역보다 크기가 커서 여려 영역을 차지하고 있는 커다란 객체이다(Humongous Object).
- G1GC는 일시 정지 시간을 줄이기 위해 병렬로 GC 작업을 한다. 각각의 스레드가 자신만의 영역을 잡고 작업하는 방식.

- 출처
    - https://yaboong.github.io/java/2018/06/09/java-garbage-collection/
    - https://mangkyu.tistory.com/119
    - https://johngrib.github.io/wiki/java-g1gc/