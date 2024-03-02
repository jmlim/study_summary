
- ThreadPoolTaskExecutor는 이름에서 알 수 있듯이 스레드 풀을 사용하는 Executor이다. 
- 상위 인터페이스를 확인해 보면 java.util.concurrent.Executor를 Spring에서 구현한 것을 확인할 수 있음.
- 이 스레드 풀을 사용할 때 설정에 몇 가지 주의점이 필요함.

### 스레드 설정
~~~
@Bean("simpleTaskExecutor")
public TaskExecutor taskExecutor() {
    ThreadPoolTaskExecutor taskExecutor = new ThreadPoolTaskExecutor();
    taskExecutor.setCorePoolSize(5);	// 기본 스레드 수
    taskExecutor.setMaxPoolSize(10);	// 최대 스레드 수
    return taskExecutor;
}
~~~
- core와 max 사이즈를 설정할 수 있다. 
- 주의할 점
  - 최초 core 사이즈만큼 동작하다가 더 이상 처리할 수 없을 경우 max 사이즈만큼 스레드가 증가할 것이라고 예상할 수 있지만 사실 그렇지 않음.
    - 이것때문에 스케일 in 이후 이벤트 시 실제로 장애 세게 맞은적이 있었음.. @Async 사용한 파드가 갯수가 줄고 위 @Async 는 기본 쓰레드 수(1) 만 사용하여 지연된 기억이....
- 내부적으로는 Integer.MAX_VALUE 사이즈의 LinkedBlockingQueue를 생성해서 core 사이즈만큼의 스레드에서 task를 처리할 수 없을 경우 queue에서 대기하게 됨.
  - queue가 꽉 차게 되면 그때 max 사이즈만큼 스레드를 생성해서 처리하게 된다.
- 
### Capacity
- core 사이즈 보다 많은 요청이 발생할 경우 Integer.MAX_VALUE 사이즈만큼의 queue를 이용한다고 했는데 이게 너무 크다고 생각된다면 queueCapacity 사이즈를 변경할 수 있음.
  - 기본값 : Integer.MAX_VALUE
- 위와 같이 설정한다면 최초 5개의 스레드에서 처리하다가 처리 속도가 밀릴 경우 100개 사이즈 queue에서 대기하고 그 보다 많은 요청이 발생할 경우 최대 10개 스레드까지 생성해서 처리하게 됨


### 옵션 요약


### corePoolSize
- 생성해서 사용할 스레드 풀에 속한 기본 스레드 갯수
  - default 값은 1 
### queueCapacity
- 이벤트 대기 큐 크기
  - default 값은 Integer.MAX_VALUE (약 21억)

### maxPoolSize
- 최대 스레드 갯수
  - default는 Integer.MAX_VALUE (약 21억)

### rejectedExecutionHandler
- 태스크 처리량이 스레드 갯수가 max로 채워지고 queue 대기수를 넘어서는 경우에 RejectExecutionException 이 발생. 
- 다음은 해당 Exception을 다양한 방식으로 처리할수있도록 제공하는 Handler 클래스의 종류.

#### AbortPolicy(default)
 - RejectExecutionHandler 예외 발생 시킴
#### DiscardOldestPolicy
 - 오래된 작업을 skip 
 - 모든 태스크가 반드시 처리될 필요가 없을때 사용
#### DiscardPolicy
 - 처리하려는 작업을 skip
 - 모든 태스크가 반드시 처리될 필요가 없을때 사용
#### CallerRunsPolicy
- shutdown 상태가 아니라면 요청한 Caller Thread에서 직접 처리함 
- 태스크 유실을 최소화하기 위해선 이 구현체를 사용해야함

설정 순서는 기존 스레드 갯수 값 까지 스레드 할당(corePoolSize) → 큐 크기 만큼 태스크 큐에서 대기(queueCapacity) → 최대 스레드 갯수 만큼 스레드 추가(maxPoolSize)


### 출처 
- https://kapentaz.github.io/spring/Spring-ThreadPoolTaskExecutor-%EC%84%A4%EC%A0%95/#
  - 좋은 자료이므로 자세히 읽어볼 것..
- https://velog.io/@think2wice/Spring-Async-Thread-Pool%EC%97%90-%EB%8C%80%ED%95%98%EC%97%AC

