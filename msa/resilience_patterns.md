# MSA 회복탄력성(Resilience) 패턴

> [msa_basics.md](./msa_basics.md)에서 "메서드 호출이 네트워크 호출로 바뀐다"고 했는데, 네트워크는 항상 느려지거나 실패할 수 있다는 전제를 깔고 설계해야 한다.
> 여기서는 그 실패를 어떻게 격리하고 견뎌낼지에 대한 패턴들을 정리.

## 1. API Gateway — 클라이언트와 서비스들 사이의 단일 진입점

- 클라이언트(모바일 앱, 웹)가 수십 개의 마이크로서비스 주소를 직접 다 알고 각각 호출하게 하면 관리가 불가능해진다. 게이트웨이가 그 앞을 가로막고 하나의 진입점 역할을 한다.
- 게이트웨이가 대신 처리해주는 것들
    - 라우팅 (요청 경로에 따라 알맞은 서비스로 전달)
    - 인증/인가 (매 서비스마다 인증 로직을 중복 구현하지 않도록 한 곳에서 처리)
    - Rate Limiting (특정 클라이언트의 과도한 요청 제한)
    - 응답 캐싱, 로깅, nginx 노트에서 다룬 로드밸런싱

~~~yaml
# Spring Cloud Gateway 설정 예시
spring:
  cloud:
    gateway:
      routes:
        - id: order-service
          uri: lb://ORDER-SERVICE      # 서비스 디스커버리와 연동 (아래 참고)
          predicates:
            - Path=/api/orders/**
        - id: user-service
          uri: lb://USER-SERVICE
          predicates:
            - Path=/api/users/**
~~~

- 이 구조는 결국 nginx 로드밸런싱 노트에서 다룬 `upstream` 개념의 확장판이다 — nginx가 "서버 여러 대"에 대한 진입점이었다면, API Gateway는 "서비스 여러 개"에 대한 진입점이라는 차이.

## 2. 서비스 디스커버리 (Service Discovery)

- 문제: MSA 환경에서는 서비스 인스턴스가 오토스케일링으로 계속 늘었다 줄었다 하고, IP도 계속 바뀐다. nginx 설정 파일에 `server 10.30.175.15:8180` 처럼 IP를 하드코딩해두던 방식(nginx 노트의 upstream 예시)이 더 이상 통하지 않는다.
- 해결: 서비스가 뜰 때 자신의 위치(IP:Port)를 **레지스트리(registry)**에 등록하고, 호출하는 쪽은 서비스 이름(예: `ORDER-SERVICE`)만 알면 레지스트리가 현재 살아있는 인스턴스 목록을 알려준다.
    - 대표 구현체: Netflix Eureka, HashiCorp Consul, Kubernetes의 내장 서비스 디스커버리(kube-dns + Service 오브젝트).
    - Kubernetes를 쓴다면 사실 Eureka 같은 걸 따로 안 둬도, Kubernetes의 Service/DNS 자체가 이 역할을 대신해준다 — "쿠버네티스 위에서 MSA를 하면 이 문제의 상당 부분이 인프라 레벨에서 이미 해결되어 있다"는 게 실무에서 k8s를 선호하는 이유 중 하나.

## 3. 서킷 브레이커 (Circuit Breaker)

- 문제: 서비스 A가 서비스 B를 호출하는데, B가 응답이 느려지거나 죽었다면? A가 계속 B를 호출하며 기다리면, A의 쓰레드/커넥션이 전부 B를 기다리는 데 묶여버려서 **A까지 함께 죽는 연쇄 장애(Cascading Failure)**가 발생한다.
- 해결: 가정용 전기 회로의 차단기(circuit breaker)와 같은 아이디어 — 특정 호출의 실패율이 임계치를 넘으면, 아예 회로를 "열어서"(Open) 더 이상 그 서비스를 호출하지 않고 즉시 실패(또는 대체 응답, Fallback)를 반환한다.

### 서킷 브레이커의 3가지 상태

~~~
CLOSED(정상) --[실패율 임계치 초과]--> OPEN(차단)
   ^                                        |
   |                                  [일정 시간 경과]
   |                                        v
   +----[성공]---- HALF_OPEN(일부만 시험 호출) <--+
                       |
                 [다시 실패하면 OPEN으로]
~~~

- **CLOSED**: 평소 상태. 요청이 정상적으로 통과됨.
- **OPEN**: 실패율이 임계치를 넘으면 전환. 일정 시간 동안은 호출 자체를 시도하지 않고 즉시 실패/폴백 처리 (죽어가는 서비스에 요청을 계속 던져서 상황을 더 악화시키지 않기 위함).
- **HALF_OPEN**: OPEN 상태로 일정 시간이 지나면, 일부 요청만 실제로 흘려보내서 "이제 복구됐는지" 시험. 성공하면 CLOSED로 복귀, 다시 실패하면 OPEN으로 되돌아감.

~~~java
// Resilience4j 예시
@CircuitBreaker(name = "paymentService", fallbackMethod = "fallback")
public PaymentResult charge(long amount) {
    return paymentClient.charge(amount); // 외부(결제) 서비스 호출
}

private PaymentResult fallback(long amount, Throwable t) {
    return PaymentResult.pending("결제 서비스 응답 지연 - 나중에 재처리"); // 대체 응답
}
~~~

## 4. Retry, Timeout, Bulkhead — 서킷 브레이커와 함께 쓰이는 패턴들

- **Timeout**: 응답을 무한정 기다리지 않고, 일정 시간이 지나면 포기하고 실패 처리. 모든 외부 호출에는 예외 없이 타임아웃이 설정되어 있어야 한다 — 타임아웃이 없는 호출 하나가 앞서 말한 연쇄 장애의 시작점이 되기 쉬움.
- **Retry**: 일시적인 실패(네트워크 순간 끊김 등)라면 짧게 재시도. 단, 무조건 재시도하면 이미 부하로 힘든 서비스에 요청을 더 퍼붓는 꼴이 되므로 **지수 백오프(Exponential Backoff)**(재시도 간격을 점점 늘림) + 재시도 횟수 제한을 함께 걸어야 함.
- **Bulkhead(격벽)**: 배의 방수격벽처럼, 서비스 A가 B, C, D를 호출한다면 B/C/D 호출에 쓰는 쓰레드풀/커넥션풀을 각각 분리해두는 패턴. `java_concurrency_executor.md`와 `Spring_ThreadPoolTaskExecutor_설정.md`에서 다룬 쓰레드풀 개념이 여기서 실전으로 이어진다 — 만약 A가 B, C, D 호출에 **같은** 쓰레드풀을 공유해서 쓰고 있었다면, B가 느려지는 순간 그 풀의 쓰레드가 전부 B 응답을 기다리는 데 묶여서 C, D 호출까지 처리 못 하게 된다(자원 고갈로 인한 연쇄 장애). 호출 대상별로 풀을 분리해두면, B가 죽어도 C·D 호출은 영향받지 않는다.

## 정리 — 이 패턴들이 실제로 막아주는 것

- 위 패턴들의 공통 목표는 결국 하나다: **부분 실패(하나의 서비스 장애)가 전체 시스템 장애로 번지지 않도록 격리하는 것.**
- 모놀리스에서는 이런 고민이 상대적으로 덜 필요했다(같은 프로세스 안의 메서드 호출은 "네트워크가 끊긴다"는 실패 모드가 없으므로) — MSA로 전환하면서 반드시 새로 떠안게 되는 복잡도이고, 이걸 감당할 준비 없이 MSA를 도입하면 msa_basics.md에서 경고한 대로 오히려 안정성이 떨어질 수 있다.

---

## 다음 학습 주제
- [분산 트랜잭션 / Saga 패턴](./saga_pattern.md) — 부분 실패를 "견디는" 것 다음으로, 부분 실패가 났을 때 데이터 일관성을 어떻게 되돌릴지의 문제
- [java_concurrency_executor.md](../java/java_concurrency_executor.md) — Bulkhead 패턴에서 언급한 쓰레드풀 분리를 실제 코드로 복습
- 분산 트레이싱(Zipkin/Jaeger) — 서비스를 여러 개 거치는 요청 하나를 추적해서, 어디서 병목/실패가 났는지 시각화하는 도구
