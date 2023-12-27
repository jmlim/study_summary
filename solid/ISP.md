>  출처 : 디자인패턴의 아름다움
>


## 3.4. 인터페이스 분리 원칙.
- 클라이언트는 필요하지 않은 인터페이스를 사용하도록 강요되어서는 안된다.
- 인터페이스 분리 원칙에서 이야기하는 인터페이스는 크게 다음 세가지 중 하나를 의미한다.
    - API 나 기능의 집합.
    - 단일 API 또는 기능.
    - 객체지향 프로그래밍의 인터페이스.
### 3.4.1. API 나 기능의 집합으로서의 인터페이스
- 이 코드의 마이크로 서비스 사용자 시스템은 등록, 로그인, 사용자 정보 획득과 같은 사용자 관련 API 집합을 제공한다.
~~~java
public interface UserService {
    boolean register(String cellphone, String password);
    boolean login(String cellphone, String password);
    UserInfo getUserInfoById(long id);
    UserInfo getUserInfoByCellphone(String cellphone);
}

public class UserServiceImpl implements UserService {
    // .... 코드 구현 생략 ...
}
~~~
- 백그라운드 관리 시스템에서는 사용자 삭제 기능이 추가되어야 한다고 판단했고, 그에 따라 사용자 시스템에서 사용자 삭제 인터페이스가 제공되기를 원함.
    - 쉽다고 느낄 수 있음. 왜냐면 UserService 인터페이스에 deleteUserByCellPhone() 인터페이스 또는 deleteUserById() 인터페이스를 추가하기만 하면 되기 때문.
    - 하지만 이 방법은 문제는 해결할 수 있으나 보안 위험이 드러나게 됨.
        - 사용자 삭제는 신중하게 수행해야 함. 백그라운드 관리 시스템(ex: 백오피스) 통해서만 수행되어야 하며 관련 인터페이스의 사용범위는 백그라운드 관리 시스템으로 제한되어야 한다.
        - 하지만 이 인터페이스를 UserService 인터페이스에 넣게 되면 UserService 인터페이스를 사용하는 모든 시스템이 사용자 섹제 인터페이스를 호출할 수 있게 되버림.
- 권장되는 솔루션
    - 아키텍쳐 설계 수준에서 인터페이스 인증을 통해 호출을 제한하는 것.
    - 현재 인증 프레임워크 지원이 없다면 코드 설계 수준에서 인터페이스의 오용을 방지하고 사용자 삭제를 위한 인터페이스를 RestrictedUserService 인터페이스에 넣고, RestrictedUserService 를 별도로 묶어 백그라운드 관리 시스템에 제공할 수 있다.
    - 이러한 방식을 통해 호출자는 필요한 인터페이스에만 의존하고 필요하지 않은 인터페이스에는 의존하지 않을 수 있으며, 결과적으로는 인터페이스의 분리 원칙에 만족할 수 있음.
~~~java
public interface UserService {
    boolean register(String cellphone, String password);
    boolean login(String cellphone, String password);
    UserInfo getUserInfoById(long id);
    UserInfo getUserInfoByCellphone(String cellphone);
}

public interface RestrictedUserService {
    boolean deleteUserByCellphone(String cellphone);
    boolean deleteUserById(long id);
}

public class UserServiceImpl implements UserService, RestrictedUserService {
    // .... 코드 구현 생략 ...
}
~~~
- 마이크로서비스의 인터페이스나 클래스 라이브러리 기능을 설계할 때,
    - 인터페이스 또는 기능의 일부가 호출자 중 일부에만 사용하거나 전혀 사용되지 않는다면
        - 불필요한 항목을 강요하는 대신, 인터페이스나 기능에서 해당 부분을 분리하여 해당 호출자에게 별도로 제공해야 하며,
        - 시용하지 않는 인터페이스나 기능에는 접근하지 못하게 해야 한다.
### 3.4.2. 단일 API나 기능으로서의 인터페이스
- 단일 API 나 기능으로서의 인터페이스를 다루는 방법
    - API 나 기능은 가능한 한 단순해야 하며 하나의 기능에 여러 다른 기능 논리를 구현하지 않아야 한다.

~~~java
public class Statistics {
    private Long max;
    private Long min;
    private Long average;
    private Long sum;
    private Long percentile99;
    private Long percentile999;
    // ... 생성자, getter, setter 메서드 생략
}

public Statistics count(Collection<Long> dataSet) {
    Statistics statistics = new Statistics();
    // ... 계산 코드 생략 ...
    return statistics;
}
~~~
- 앞의 예제 코드에서 count() 메서드는 최댓값, 최솟값 평균값과 같은 여러 다른 통계 함수를 포함하기 때문에 충분히 단일하지 않음.
    - 인터페이스 분리 원칙에 따라 count() 메서드를 여러개의 작은 단위 메서드로 분할해야 하며, 각각의 단위 메서드는 다른 함수를 포함하지 않는 독립적인 통계 기능을 제공해야 한다.
~~~java
public Long max(Collection<Long> dataSet) {...}
public Long min(Collection<Long> dataSet) {...}
public Long average(Collection<Long> dataSet) {...}
// 일부 통계 메서드 생략..
~~~
- 그러나 또 다른 관점에서 보면 count() 메서드가 단일 책임이 아니라고 말하기 어려움.
    - 결국 통계와 관련된 작업만 수행하기에.. 하지만 앞에서 단일 책임 원칙을 언급할 때, 특정 기능이 단일한지 여부를 판별하는 것이 시나리오에 따라 달라질 수 있다고 언급하였음.
    - 프로젝트에서 통계와 관련된 요구 사항에 대해 Statistics 클래스에 의해 정의된 모든 통계 정보가 사용된다면 count() 메서드의 설계는 합리적이라고 할 수 있다.
    - 하지만 전체 정보가 아닌 min, max, average 의 세 가지 통계만 주로 사용하는 경우에도, count() 메소드는 메번 모든 통계를 다시 계산해야 한다.
        - 이는 불필요한 작업이 매번 실행된다는 의미.
        - count() 메서드를 보다 세분화된 통계 메서드 여러개로 분할해야 한다.
### 3.4.3. 객체지향 프로그래밍에서의 인터페이스
- 프로젝트에서 Redis, MySQL, Kafka의 3가지 시스템이 연계되어 사용된다고 가정.
    - 각 시스템은 IP 주소, 포트, 엑세스 제한 시간과 같은 설정 정보에 대응.
    - 프로젝트의 다른 모듈에서도 이 정보를 사용할 수 있도록 RedisConfig, MysqlConfig, KafkaConfig 클래스를 구현해 설정 정보를 메모리에 올릴 수 있도록 가정.
    - 그런데 Redis, Kafka의 설정 정보 핫 업데이트를 지원하라는 새로운 요구사항이 전달되었다.
        - 핫 업데이트는 설정 센터에서 설정 정보가 변경되면 시스템을 다시 시작하지 않고도 최신 설정 정보를 메모리에 다시 올릴 수 있어야 함을 의미
        - 그러나 Redis, Kafka 와 달리 모종의 이유로 MySQL 은 설정 정보를 핫 업데이트 하면 안되는 상황..
    - 이러한 요구 사항을 만족시키기 위해 RedisConfig 클래스와 KafkaConfig 클래스의 update() 메서드에서 실행 간격 정보인 periodInSeconds 속성을 호출하여 일정 시간마다 반복하여 설정 정보를 업데이트하는 ScheduledUpdater 클래스를 구현하기로 함.

~~~java
public interface Updater {
    void update();
}

public class RedisConfig implements Updater {
    // 일부 속성과 메서드 생략 ..

    @Override
    public void update() {
        // ....
    }
}

public class MysqlConfig {
    // ...
}

public class ScheduleUpdater {
    private final ScheduledExecutorService executor = Executors.newSingleThreadSeheduledExecutor();
    private long initialDelayInSeconds;
    private long periodInSeconds;
    private Updater updater;
    
    public ScheduleUpdater(Updater updater, long initialDelayInSeconds, long periodInSeconds) {
        this.updater = updater;
        this.initialDelayInSeconds = initialDelayInSeconds;
        this.periodInSeconds = periodInSeconds;
    }
    
    public void run() {
        executor.seheduleAtFixedRate(new Runnable() {
            @Override 
            public void run() {
                updater.update();
            }
        }, this.initialDelayInSeconds, this.periodInSeconds, TimeUnit.SECONDS);
    }
}

public class Application {
    ConfigSource configSource = new ZookeeperConfigSource(/* 매개변수 생략 */);
    public static final RedisConfig redisConfig = new RedisConfig(configSource);
    public static final KafkaConfig kafkaConfig = new KafkaConfig(configSource);
    public static final MysqlConfig redisConfig = new MysqlConfig(configSource);

    public static void main(String[] args) {
        ScheduleUpdater redisConfigUpdater = new ScheduleUpdater(redisConfig, 300, 300);
        redisConfigUpdater.run();
        ScheduleUpdater kafkaConfigUpdater = new ScheduleUpdater(kafkaConfig, 60, 60);
        kafkaConfigUpdater.run();
    }
}
~~~

- 핫 업데이트 요구 사항이 구현되었지만 이제 모니터링에 대한 요구 사항이 추가된다.
    - ZooKeeper에서 명령 줄을 통해 설정 정보를 보는 것은 번거롭기 때문에, 보다 편리한 방법으로 설정 정보를 볼 수 있도록 개선해야 한다.
- 프로젝트에 SimpleHttpServer 클래스를 내재화하면 http://127.0.0.1:2309/config 처럼 HTTP 주소로 설정 정보를 출력할 수 있다.
    - 그러나 모종의 이유로 이번엔 Kafka를 제외한 MySQL과 Redis의 설정 정보만 보여줘야 한다.

~~~java
public interface Updater {
    void update();
}

public interface Viewer {
    String outputPlainText();

    Map<String, String> output();
}

public class RedisConfig implements Updater, Viewer {
    // 일부 속성과 메서드 생략
    @java.lang.Override
    public void update() {
        // ...
    }

    @java.lang.Override
    public String outputPlainText() {
        // ....
    }

    @java.lang.Override
    public Map<String, String> output() {
        // ....
    }
}

public class KafkaConfig implements Updater {
    // 일부 속성과 메서드 생략.. 

    @java.lang.Override
    public void update() {
        // ....
    }
}

public class MysqlConfig implements Viewer {
    // 일부 속성과 메서드 생략.. 

    @java.lang.Override
    public String outputPlainText() {
        // ....
    }

    @java.lang.Override
    public Map<String, String> output() {
        // ....
    }
}

// ....

public class SimpleHttpServer {
    private String host;
    private int port;
    private Map<String, List<Viewer>> viewers = new HashMap<>();
    
    public SimpleHttpServer(String host, int port) {
        /// ...
    }
    
    public void addViewers(String urlDirectory, Viewer viewer) {
        if(!viewers.containsKey(urlDirectory)) {
            viewers.put(urlDirectory, new ArrayList<Viewer>());
        }
        this.viewers.get(urlDirectory).add(viewer);
    }
    
    public void run() {
        // ....
    }
}

// ....
public class Application {
    ConfigSource configSource = new ZookeeperConfigSource(/* 매개변수 생략 */);
    public static final RedisConfig redisConfig = new RedisConfig(configSource);
    public static final KafkaConfig kafkaConfig = new KafkaConfig(configSource);
    public static final MysqlConfig redisConfig = new MysqlConfig(configSource);

    public static void main(String[] args) {
        ScheduleUpdater redisConfigUpdater = new ScheduleUpdater(redisConfig, 300, 300);
        redisConfigUpdater.run();
        ScheduleUpdater kafkaConfigUpdater = new ScheduleUpdater(kafkaConfig, 60, 60);
        kafkaConfigUpdater.run();
        
        SimpleHttpServer simpleHttpServer = new SimpleHttpServer("127.0.0.1", 2309);
        simpleHttpServer.addViewers("/config", redisConfig);
        simpleHttpServer.addViewers("/config", mysqlConfig);
        simpleHttpServer.run();
    }
}
~~~
- 이 코드에서 업데이트에 관련된 Updater 인터페이스와 Viewer 인터페이스를 설계했고, 각각의 인터페이스는 단일 기능을 가지도록 했다.
- 핫 업데이트에 관련된 ScheduledUpdater 클래스는 Updater 인터페이스에만 의존, 불필요한 Viewer 인터페이스에 의존하지 않기 때문에 인터페이스 분리 원칙을 만족한다.
- 또한 SimpleHttpServer 클래스는 모니터링에 관련된 Viewer 인터페이스에만 의존하고 불필요한 Updater 인터페이스에 의존하지 않으며 마찬가지로 인터페이스 분리 원칙도 만족한다.



- 만약 인터페이스 분리 원칙을 따르지 않는다면?
    - 먼저 Updater 인터페이스와 Viewer 인터페이스를 설계하는 대신에 크고 포괄적인 Config 인터페이스를 설계하고.. RedisConfig, KafkaConfig, MysqlConfig 클래스가 이 설정 인터페이스를 구현할 것.
    - 그리고.. ScheduledUpdater의 Updater 객체와 SimpleHttpServer의 Viewer 객체는 Config 객체로 대체된다.
    - 그럼 어떤결과를 가져올까? 아래 코드 참고

~~~java
public interface Config {
    void update();
    String outputPlainText();
    Map<String, String> output();
}

public class RedisConfig implements Config {
// Config 인터페이스 update, outputInPlainText, output을 구현해야 한다.
}

public class KafkaConfig implements Config {
// Config 인터페이스 update, outputInPlainText, output을 구현해야 한다.
}

public class MysqlConfig implements Config {
// Config 인터페이스 update, outputInPlainText, output을 구현해야 한다.
}


/// .... 
public class ScheduledUpdater {
    // .. 일부 속성과 메서드 생략 ...
    private Config config; 
    public ScheduledUpdater(Config config, long initialDelayInSeconds, long periodInSeconds) {
        this.config = config;
        // ,.,....
    }
}
// ...
public class SimpleHttpServer {
    private String host;
    private int port;
    private Map<String, List<Viewer>> viewers = new HashMap<>();

    public SimpleHttpServer(String host, int port) {
        /// ...
    }

    public void addViewers(String urlDirectory, Viewer viewer) {
        if(!viewers.containsKey(urlDirectory)) {
            viewers.put(urlDirectory, new ArrayList<Viewer>());
        }
        this.viewers.get(urlDirectory).add(viewer);
    }

    public void run() {
        // ....
    }
}

~~~
- 두 가지 설계에 따른 코드가 코드 크기, 구현 복잡성, 가독성이 모두 엇비슷하다고 가정할 때 첫번째 설계가 두 번째 설계보다 우수하다고 할 수 있다.
    - 왜? 다음 두가지 측면 때문..
#### 첫 번째 설계는 더 유연하기 때문에 확장성이 높고 재사용하기 쉽다.
- Updater 인터페이스와 Viewer 인터페이스는 공통성과 높은 재사용성을 의미하는 단일 책임을 가지고 있다.
    - 이 코드에 추가로 성능 통계 모듈을 개발하고 사용자의 편의를 위해 SimpleHttpServer를 통해 웹 페이지에 통계 결과를 표시해야 하는 요구 사항이 추가되었을 경우,
        - 성능 통계 클래스에서 공통 인터페이스인 Viewer를 구현하고 SimpleHttpServer의 코드 구현을 재사용 할 수 있다.
~~~java
public class ApiMetrics implements Viewer {
    // 일부 속성과 메서드 생략.. 

    @java.lang.Override
    public String outputPlainText() {
        // ....
    }

    @java.lang.Override
    public Map<String, String> output() {
        // ....
    }
}

public class DbMetrics implements Viewer {
    // 일부 속성과 메서드 생략.. 

    @java.lang.Override
    public String outputPlainText() {
        // ....
    }

    @java.lang.Override
    public Map<String, String> output() {
        // ....
    }
}


// ....
public class Application {
    ConfigSource configSource = new ZookeeperConfigSource(/* 매개변수 생략 */);
    public static final RedisConfig redisConfig = new RedisConfig(configSource);
    public static final KafkaConfig kafkaConfig = new KafkaConfig(configSource);
    public static final MysqlConfig redisConfig = new MysqlConfig(configSource);
    public static final ApiMetrics apiMetrics = new ApiMetrics();
    public static final DbMetrics dbMetrics = new DbMetrics();

    public static void main(String[] args) {
        ScheduleUpdater redisConfigUpdater = new ScheduleUpdater(redisConfig, 300, 300);
        redisConfigUpdater.run();
        ScheduleUpdater kafkaConfigUpdater = new ScheduleUpdater(kafkaConfig, 60, 60);
        kafkaConfigUpdater.run();

        SimpleHttpServer simpleHttpServer = new SimpleHttpServer("127.0.0.1", 2309);
        simpleHttpServer.addViewers("/config", redisConfig);
        simpleHttpServer.addViewers("/config", mysqlConfig);
        simpleHttpServer.addViewers("/metrics", apiMetrics);
        simpleHttpServer.addViewers("/metrics", dbMetrics);
        simpleHttpServer.run();
    }
}
~~~

#### 두 번째 설계는 코드에서 쓸모없는 작업을 수행함.
- Config 인터페이스는 서로 관련이 없는 두 종류의 인터페이스가 포함되어 있음.
    - 즉 update() 와 output(), outputInPlainText()는 서로 전혀 관계가 없다.
    - KafkaConfig 클래스는 세 가지 중 update() 인터페이스 한 가지만 필요로 하며 output() 관련 인터페이스는 필요 없다.
    - 마찬가지로 MysqlConfig 클래스는 output() 관련 인터페이스만 필요. update() 는 필요하지 않다.
        - 그러나 두 번째 설계에서는 RedisConfig 클래스, KafkaConfig 클래스, MysqlConfig 클래스가 사용하지 않을 수도 있는 update(), output(), outputInPlainText()를 모두 다 구현해야 한다.
        - 뿐만 아니라 Config에 새 인터페이스가 추가될 때마다, 모든 구현 클래스도 해당 인터페이스를 모두 구현해야 한다.
            - 반대로.. 인터페이스 밀도가 상대적으로 작은 경우 인터페이스 변경에 따라 수정해야 하는 클래스도 그만큼 줄어든다.