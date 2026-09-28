# Slack 메시지 전송 방식 가이드: 동기 vs 비동기 vs Queue (Java/Spring)

Slack Web API `chat.postMessage`를 Java(Spring) 애플리케이션에서 어떤 방식으로 호출해야 하는지 정리한 문서다. 동기 호출이 괜찮은지, 언제 비동기나 Queue로 바꿔야 하는지, 트래픽이 어느 정도일 때 어떤 방식을 써야 하는지, 장애 알림으로 쓸 때 무엇을 조심해야 하는지를 다룬다.

## 목차

0. [이 문서에 대해](#0-이-문서에-대해)
1. [요약](#1-요약)
2. [Slack이 정한 규칙](#2-slack이-정한-규칙)
3. [동기 호출은 언제 위험해지는가](#3-동기-호출은-언제-위험해지는가)
4. [SDK 동작에서 꼭 알아야 할 것](#4-sdk-동작에서-꼭-알아야-할-것)
5. [방식 고르기](#5-방식-고르기)
6. [구현](#6-구현)
7. [장애 알림으로 쓸 때](#7-장애-알림으로-쓸-때)
8. [운영: 흔한 실수와 방식을 바꿔야 할 신호](#8-운영-흔한-실수와-방식을-바꿔야-할-신호)
9. [구현 체크리스트](#9-구현-체크리스트)
10. [참고 자료](#10-참고-자료)
- [부록 A. 용어 풀이](#부록-a-용어-풀이)

---

## 0. 이 문서에 대해

- **대상**: Spring 애플리케이션에서 Slack 알림을 보내는 개발자. Slack API를 처음 다뤄 보는 사람도 읽을 수 있도록 예시와 용어 풀이를 넣었다.
- **읽는 순서**: 바쁘면 [1장](#1-요약) → [5장](#5-방식-고르기) → [6장](#6-구현) 순서로 읽는다. 장애 알림 용도라면 [7장](#7-장애-알림으로-쓸-때)을 함께 본다. 모르는 용어는 [부록 A](#부록-a-용어-풀이)에 있다.
- **사실과 판단의 구분**: 2~4장은 Slack 공식 문서, Slack Engineering 글, Slack Status 장애 보고, SDK 소스코드에서 **확인한 사실**이다. 5~8장의 기준값(트래픽 구간 경계, thread 점유율 10%, 억제 시간 5분 등)은 그 사실을 바탕으로 한 **이 문서의 설계 판단**이며 Slack이 권장한 값이 아니다. 서비스 상황에 맞게 조정한다.

---

## 1. 요약

### 핵심 결론

1. **동기 호출은 정식 방식이다.** Slack 공식 Java SDK의 기본 client(`MethodsClient`)는 동기 방식이다. 동기로 운영해도 대부분 문제가 없다.
2. **다만 Slack이 항상 빠르고 항상 성공한다고 가정하면 안 된다.** Slack은 몇 분에서 십수 시간짜리 장애를 실제로 겪었다. 동기 호출의 위험은 **Slack이 느려지는 순간**과 **호출이 한꺼번에 몰리는 순간**에만 드러난다.
3. **보낼 수 있는 양의 상한은 Slack이 정한다.** 같은 채널에는 초당 약 1건, workspace 전체에는 분당 수백 건이다. 비동기나 Queue로 바꿔도 이 상한은 늘어나지 않는다. 상한을 넘으면 **메시지를 묶어서(요약) 줄이는 것**이 유일한 해법이다.
4. **방식은 두 가지 기준으로 고른다.**
   - **중요도**: 메시지 한 건이 사라지면 피해가 생기는가?
   - **트래픽**: 실제로 Slack으로 나가는 양이 얼마인가? (같은 채널의 피크 기준)
5. **장애 알림은 방식보다 양 조절이 먼저다.** 같은 알림을 묶기만 해도 대부분 동기 호출로 충분해진다.

### 세 가지 방식

| 방식 | 구현 | 언제 쓰는가 | 대표 예시 |
|---|---|---|---|
| **Tier 1** 동기 호출 | `MethodsClient` + `AFTER_COMMIT` 이벤트 | 양이 적고, Slack 응답을 기다려도 되는 경우 | 배치 결과, 관리자 작업 알림, 배포 알림, 1분 요약 알림 |
| **Tier 2** 비동기 호출 | `@Async` + 전용 bounded Executor | 고객 API의 응답 시간을 보호해야 하고, 일부 유실은 괜찮은 경우 | 회원가입·주문 시 운영 채널 참고 알림 |
| **Tier 3** 영속 Queue | Outbox 테이블(또는 MQ) + 전용 Worker | 메시지가 절대 사라지면 안 되는 경우 | CS 문의 접수 알림, 결제·정산 이상 알림, 전 직원 DM 공지 |

### 트래픽별 권장 방식 (자세한 기준은 5장)

| 구간 | 같은 채널 피크 | 참고용 알림 | 유실되면 안 되는 알림 |
|---|---|---|---|
| **A** 저빈도 | 분당 10건 이하 | Tier 1 | Tier 3 |
| **B** 중빈도 | 분당 10~60건 | 요청 경로 밖이면 Tier 1, 고객 요청 경로 안이면 Tier 2 | Tier 3 |
| **C** 한도 근접·초과 | 분당 60건 이상 | 요약·억제로 A/B까지 줄인 뒤 해당 방식 | Tier 3 + 채널별 속도 제한 |
| **D** 대량 | 분당 수천 건 이상 | Slack 건별 전송 부적합. 로그·모니터링 도구로 보내고 Slack에는 요약만 | 동일 |

### 비유로 이해하기

| 개념 | 비유 | 배울 점 |
|---|---|---|
| Tier 1 (동기) | **전화 걸기**. 상대가 받을 때까지 다른 일을 못 한다. | 상대가 안 받으면(Slack 장애) 계속 기다리게 된다. "3초까지만 기다린다"는 규칙(timeout)이 반드시 필요하다. |
| Tier 2 (`@Async`) | **옆자리 동료에게 메모로 전달 부탁**. 나는 바로 내 일로 돌아온다. | 메모가 너무 쌓이면 버려지고, 동료가 퇴근하면(서버 재시작) 메모도 사라진다. |
| Tier 3 (Outbox) | **우체국 등기 우편**. 접수 기록이 남아 배달에 실패하면 다시 배달한다. | 잃어버리지 않는 대신 접수 절차(테이블, worker)가 번거롭다. |
| Rate limit | **1초에 한 명만 처리하는 은행 창구**. | 줄을 아무리 잘 세워도(비동기, Queue) 창구 속도는 그대로다. 여러 용건을 한 번에 묶어 처리해야 한다(요약). |

---

## 2. Slack이 정한 규칙

### 2.1 공식 Java SDK는 동기/비동기 client를 모두 제공한다

```java
Slack slack = Slack.getInstance();

MethodsClient syncClient = slack.methods(token);            // 동기
AsyncMethodsClient asyncClient = slack.methodsAsync(token); // 비동기 (CompletableFuture 반환)
```

| Client | 방식 | 특징 |
|---|---|---|
| `MethodsClient` | 동기 | 요청을 "blindly" 전송한다. rate limit 상태를 고려하지 않고 바로 보낸다는 뜻이다. |
| `AsyncMethodsClient` | 비동기 | 내부 queue로 burst를 피하고 rate limit을 고려한다. 요청이 몰리면 전송을 의도적으로 늦출 수 있다. |
| `SocketModeClient` | WebSocket | Socket Mode 이벤트 **수신**용이다. 메시지 전송과는 관계없다. |

### 2.2 기본 client는 왜 동기 방식인가

Slack이 이유를 공식적으로 밝힌 적은 없다. 아래는 Web API 구조와 SDK 구성에서 읽을 수 있는 해석이다.

**(1) Web API 자체가 "요청하고 응답을 받는" 구조다.**
`chat.postMessage`는 HTTP 요청을 보내면 `{"ok": true, "ts": "...", ...}` 같은 JSON 응답을 바로 돌려준다. 이것을 코드로 가장 그대로 옮기면 "메서드를 호출하고 반환값을 받는" 동기 메서드가 된다. SDK는 HTTP API를 1:1로 감싼 얇은 계층이다.

**(2) 호출 결과가 바로 필요한 경우가 많다.**

```java
// 메시지를 올리고, 그 메시지의 ts(메시지 ID)로 thread 답글을 다는 흔한 흐름
ChatPostMessageResponse parent = slack.chatPostMessage(r -> r.channel(channelId).text("배포 시작"));
slack.chatPostMessage(r -> r.channel(channelId).threadTs(parent.getTs()).text("배포 완료"));
```

동기 방식이면 위처럼 순서대로 읽히는 코드가 된다. 비동기 방식이었다면 `CompletableFuture`를 이어 붙여야 한다.

**(3) Java 서버의 전통적인 실행 모델과 맞다.**
Spring MVC는 요청 하나를 thread 하나가 처음부터 끝까지 처리한다. JDBC, `RestTemplate`도 결과가 올 때까지 기다리는(blocking) 방식이다. 언어 관례의 차이이기도 하다. Python `slack_sdk`도 기본 `WebClient`는 동기이고 `AsyncWebClient`를 따로 두지만, Node.js SDK는 언어 특성상 Promise(비동기)를 기본으로 반환한다.

**(4) "어떤 비동기가 맞는지"는 SDK가 대신 정할 수 없다.**
유실을 허용할지, 재시도할지, DB에 보관할지는 앱마다 다르다. SDK의 `AsyncMethodsClient`도 메모리 queue와 rate limit 고려까지만 해 준다(4.4). 그 이상은 애플리케이션이 정할 정책이다.

**(5) 평소에는 충분히 빠르다.**
Slack이 정상이면 호출 한 번은 보통 수백 ms 안에 끝난다. 양이 적으면 기다려도 비용이 작다.

### 2.3 Rate limit

| 대상 | 한도 | 비고 |
|---|---|---|
| 같은 채널 (`chat.postMessage`) | 일반적으로 **초당 1건** | 짧은 burst는 허용하지만 정확한 burst 한도는 공개하지 않는다 |
| workspace 전체 | **분당 수백(several hundred) 건** | 채널 한도와 별도로 적용된다 |
| Incoming Webhook | 초당 1건 (짧은 burst 허용) | |

- 한도를 넘으면 **HTTP 429**와 `Retry-After` 헤더(초 단위)를 돌려준다. 그 시간만큼 기다린 뒤 재시도해야 한다.
- burst가 한도를 넘으면 사용자에게 "일부 앱 메시지가 표시되지 않는다"는 안내가 뜰 수 있다.
- 더 많이 보내야 한다면 Slack은 한도를 올리는 대신 로그·집계 서비스(Papertrail, Loggly, Splunk, LogStash 등)를 쓰라고 안내한다.

> **비동기화나 Queue는 Slack의 한도를 늘려 주지 않는다.** 한도는 Slack 쪽 규칙이고, 우리 쪽 구조를 바꿔도 창구 속도는 그대로다.

### 2.4 오류의 형태와 메시지 길이

`chat.postMessage`가 정의한 서버 측 오류는 다음과 같다.

| error | 의미 |
|---|---|
| `service_unavailable` | 서비스를 일시적으로 사용할 수 없음 |
| `internal_error` | Slack 측 일시적 문제로 작업을 완료하지 못함. **일부 작업은 이미 성공했을 수 있음** |
| `fatal_error` | catastrophic error로 작업을 완료하지 못함. **일부 작업은 이미 성공했을 수 있음** |
| `ratelimited` | 요청이 rate limit에 걸림. `Retry-After` 확인 필요 |
| `rate_limited` | 앱이 메시지를 너무 많이 게시함 |

Java SDK에서 실패는 세 가지 경로로 온다. **세 가지를 모두 처리해야 한다.**

1. HTTP 200이지만 body가 `ok:false`인 API 오류 (`channel_not_found`, `not_in_channel`, `invalid_auth` 등 대부분)
2. 네트워크 오류·timeout으로 인한 `IOException`
3. HTTP 200번대가 아닌 응답(429, 5xx 등)으로 인한 `SlackApiException`

`text`는 4,000자 이내를 권장하고, 40,000자를 넘으면 잘린다.

---

## 3. 동기 호출은 언제 위험해지는가

### 3.1 실제 Slack 장애 사례

| 일시 | 원인 | 영향 범위 | 지속 | 시사점 |
|---|---|---|---|---|
| 2020-10-05 | database memory cache server 과부하가 service discovery system 장애로 번진 연쇄 장애 ("slow API performance") | 메시지 전송·로딩, 파일, 알림, 검색, Apps/Integrations/APIs 등 거의 전 기능 | 약 16시간 (05:58~22:30 PDT) | 동기 호출 thread가 Slack 지연 시간만큼 묶일 수 있다 |
| 2022-03-08~09 | Job Processing Queue가 일부 job을 처리하지 못함. 일부 요청은 queue에 들어가지도 못함 | 파일 업로드, 메시지 수정, reaction, webhook, Workflow Builder, 검색 등 | 약 11시간 (22:00~08:57 PST) | Queue 구조도 장애는 난다. 비동기는 장애를 없애는 게 아니라 격리할 뿐이다 |
| 2025-08-07 | backend caching system 트래픽 급증으로 timeout | 검색, 메시징, 파일, Apps/Integrations/APIs (주로 Enterprise Grid) | 약 19분 (07:09~07:28 PDT) | 짧은 장애라도 timeout이 없으면 그동안 thread가 묶인다 |

### 3.2 장애가 우리 서버로 번지는 과정

```text
Slack 응답이 느려짐
  -> Slack을 호출한 thread가 오래 묶임
  -> 묶인 thread가 늘어남
  -> thread pool이 가득 참
  -> 우리 API까지 느려지거나 멈춤 (연쇄 장애, cascading failure)
```

얼마나 묶이는지는 다음 식으로 어림한다(Little's Law).

```text
동시에 묶이는 thread 수 ≈ 초당 Slack 호출 수 × 호출 1건이 걸리는 시간(초)
```

Spring Boot 내장 Tomcat의 기본 최대 thread 수는 200이다(`server.tomcat.threads.max`). 요청 처리 중에 초당 5건을 동기로 보낸다고 하자.

| 상황 | 호출 1건 시간 | 묶이는 thread | 200개 중 비율 |
|---|---|---|---|
| 평소 | 0.3초 | 5 × 0.3 = 1.5개 | 약 1% |
| Slack 장애, 전체 timeout 3초 설정 | 3초 | 5 × 3 = 15개 | 약 8% |
| Slack 장애, timeout 설정 안 함 | 10초 이상 (read timeout 기본값) | 50개 이상 | 25% 이상, 계속 증가 가능 |

같은 트래픽에서 **timeout 하나로 피해 규모가 몇 배 달라진다.** 이 계산이 5장 트래픽 구간의 근거가 된다.

### 3.3 Slack 내부 설계에서 얻는 힌트

**Slack도 오래 걸리는 작업은 Job Queue로 분리한다.** 메시지 게시, push notification, URL unfurl, calendar reminder, billing 계산을 Job Queue로 처리한다. 공개 당시(2017-12 게시, 2020-06 갱신) 규모는 하루 14억 건 이상, 피크 초당 33,000건이었다.

**chat.postMessage의 내부 흐름** (Slack Engineering의 Koi Pond 글 기준. 현재 구현의 세부 순서까지 공개된 것은 아니다)

1. backend가 real-time service에서 timestamp를 받는다.
2. 메시지를 Vitess의 `messages` table에 기록한다.
3. link·attachment preview 같은 후속 작업을 비동기 job으로 만든다.
4. 채널의 client들에게 websocket 이벤트를 보낸다.

**Slack도 "무조건 비동기"로 설계하지 않는다.** job을 Kafka에 넣는 Kafkagate는 **동기 write**를 쓴다. job이 실제로 queue에 들어갔는지 확인해 주기 위해서다(단, 가용성을 위해 leader의 확인만 기다리고 복제까지는 기다리지 않는다).

- 성공 여부를 반드시 확인해야 하는 짧은 작업 → 동기
- 오래 걸리거나 분리해도 되는 후속 작업 → 비동기

우리 시스템에도 같은 기준이 적용된다. Slack 전송 성공이 요청의 성공 조건이면 동기가 맞고, 알림이 요청과 별개의 부가 기능이면 분리할 수 있다.

### 3.4 동기 호출을 안전하게 쓰는 세 가지 원칙

**(1) timeout을 반드시 건다.**
SDK 기본값은 connect·read·write 각 10초이고 **호출 전체 상한은 없다**(4.2). 값은 우리 API의 응답 시간 목표, 평소 Slack 응답 시간, 호출량, thread pool 크기를 보고 정한다. 이 문서는 전체 3초를 예로 든다.

**(2) DB transaction 안에서 호출하지 않는다.**
`@Transactional` 안에서 Slack을 호출하면 Slack 응답을 기다리는 동안 DB connection을 계속 잡고 있다. Slack 장애가 DB connection pool 고갈로 번진다. 게다가 전송 뒤 rollback되면 "없는 주문" 알림이 나간다. `@TransactionalEventListener(phase = AFTER_COMMIT)`로 commit 뒤에 보낸다(6.3).

**(3) 실패했다고 바로 다시 보내지 않는다.**
- 장애 중에 즉시 재시도하면 트래픽이 몇 배로 는다. 100건에 재시도 3회를 붙이면 최대 400건이다.
- `chat.postMessage`에는 **중복 방지 키(idempotency key)가 없다.**
- read timeout은 "실패"가 아니라 **"결과를 모름"** 이다. Slack은 이미 게시했는데 응답만 늦었을 수 있다. `internal_error`·`fatal_error`도 "일부는 성공했을 수 있음"이다. 이때 다시 보내면 같은 메시지가 두 번 올라갈 수 있다.
- 참고용 알림이라면 "한 번 보내고, 실패하면 로그 남기고, 업무는 계속"이 합리적이다.
- 재시도는 **확실히 안 보내진 경우**(연결 실패, `ratelimited`, `service_unavailable` 등)에만 한다. 429는 `Retry-After`만큼 기다린 뒤 보낸다. 재시도가 꼭 필요한 메시지라면 Tier 3로 보낸다.

---

## 4. SDK 동작에서 꼭 알아야 할 것

`slackapi/java-slack-sdk` 소스코드를 직접 확인한 내용이다. 공식 문서에는 자세히 나오지 않는다.

### 4.1 HTTP 200 + `ok:false`는 예외가 아니다

`MethodsClientImpl`은 HTTP 200번대 응답이면 응답 객체를 그대로 반환하고, `SlackApiException`은 200번대가 아닐 때만 던진다. 대부분의 API 오류는 HTTP 200 + `ok:false`로 오므로, **예외가 나지 않았다고 성공한 것이 아니다.** 반드시 `response.isOk()`를 확인한다.

### 4.2 Timeout 기본값과 설정

| 구분 | `SlackConfig` 설정 | 기본값 |
|---|---|---|
| read timeout | `httpClientReadTimeoutMillis` | 10초 (OkHttp 기본) |
| write timeout | `httpClientWriteTimeoutMillis` | 10초 (OkHttp 기본) |
| call timeout (호출 전체 상한) | `httpClientCallTimeoutMillis` | **없음** |
| connect timeout | `SlackConfig`에 없음. 직접 만든 `OkHttpClient`를 `SlackHttpClient`로 넘겨야 바꿀 수 있다 | 10초 (OkHttp 기본) |

호출 전체 상한은 `httpClientCallTimeoutMillis` 하나로 거는 것이 가장 간단하다.

### 4.3 동기 client는 429를 자동으로 처리하지 않는다

429를 받으면 `Retry-After` 값을 내부 metrics 저장소에 기록만 하고 바로 `SlackApiException`을 던진다. 이 기록은 `AsyncMethodsClient`가 참고하는 용도다. **동기 호출에서 기다렸다 다시 보내는 것은 애플리케이션 책임이다.**

### 4.4 `AsyncMethodsClient`는 "전달 보장 Queue"가 아니다

- 기본 thread pool은 고정 5개이고(`MethodsConfig.defaultThreadPoolSize = 5`), 기본적으로 모든 workspace(team)가 **함께 쓴다**. team별 전용 pool은 `customThreadPoolSizes`에 team을 따로 지정했을 때만 만들어진다.
- `Executors.newFixedThreadPool`로 만들므로 대기열 크기에 **제한이 없는 메모리 queue**다.
- thread는 daemon thread다.

따라서 서버가 재시작하면 대기 중인 요청은 사라지고, 장애가 길어지면 요청이 메모리에 계속 쌓인다. 유실 측면에서는 `@Async`와 같은 등급이다.

### 4.5 Incoming Webhook(`slack.send`)은 429에도 예외를 던지지 않는다

`slack.send(url, payload)`는 HTTP 응답 코드를 `WebhookResponse.code`에 담아 반환할 뿐, 429나 500이 와도 예외를 던지지 않는다. **응답 코드를 확인하지 않으면 유실 사실 자체를 모른다.**

```java
WebhookResponse res = slack.send(webhookUrl, payload);
if (res.getCode() != 200) { // 429 포함
    log.warn("[Slack] webhook failed. code={}, body={}", res.getCode(), res.getBody());
}
```

그 밖에 Incoming Webhook의 제약:

- 설치할 때 연결한 채널로만 보낼 수 있다(채널 변경 불가).
- webhook으로 올린 메시지는 webhook으로 삭제할 수 없다.
- `thread_ts`로 thread 답글은 달 수 있지만, 응답이 게시된 메시지의 `ts`를 돌려주지 않는다. 방금 보낸 메시지에 답글을 달려면 `chat.postMessage`(bot token)를 써야 한다.

---

## 5. 방식 고르기

### 5.1 세 방식 비교

| 항목 | Tier 1 동기 | Tier 2 `@Async` + bounded Executor | (참고) `AsyncMethodsClient` | Tier 3 Outbox/MQ + Worker |
|---|---|---|---|---|
| 구현 난이도 | 가장 낮음 | 중간 | 낮음~중간 | 높음 |
| 고객 요청 응답 시간 보호 | X | O | O | O |
| rate limit 대응 | X | X (직접 구현) | O (전송 지연) | Worker에서 제어 |
| Slack 장애 중 메시지 보관 | X | 제한적 (bounded 메모리) | 제한적 (무제한 메모리) | O (DB·MQ) |
| 서버 재시작 시 | 해당 없음 | 유실 | 유실 | 보존 |
| 재시도 / DLQ | 직접 구현 | 직접 구현 | 직접 구현 | 구조적으로 쉬움 |
| 성공 여부 즉시 확인 | O (`ok` 확인. timeout이면 모름) | X | X | X |
| 운영 복잡도 | 낮음 | 중간 | 낮음 | 높음 |

### 5.2 트래픽 구간

#### 무엇을 재는가

트래픽은 **두 가지**로 잰다. 둘 다 **요약·중복 억제를 거친 뒤 실제로 Slack으로 나가는 양**이다.

| 측정값 | 무엇과 비교하나 | 왜 |
|---|---|---|
| ① **같은 채널로 나가는 양의 피크** (분당 건수) | Slack 채널 한도 (분당 60건 = 초당 1건) | Slack이 받아 줄 수 있는가 |
| ② **서버 1대가 요청 처리 중에 Slack을 부르는 양** (초당 건수) | 우리 thread pool (Tomcat 기본 200개) | 동기로 기다려도 우리 서버가 버티는가 |

평균이 아니라 **가장 몰리는 시간대(피크)** 로 잰다. 하루 평균은 괜찮아 보여도 점심 시간이나 장애 순간에 한도를 넘는 경우가 많다.

#### 구간 정의

①과 ② 중 **더 높은 구간**을 따른다.

| 구간 | ① 같은 채널 피크 | ② 서버 1대당 호출 | 경계를 이렇게 잡은 이유 |
|---|---|---|---|
| **A** 저빈도 | 분당 10건 이하 | 초당 1건 미만 | 채널 한도의 1/6 이하라 burst 여유가 크다. Slack 장애 때 묶이는 thread가 3개 미만이다(1건 × 3초) |
| **B** 중빈도 | 분당 10~60건 | 초당 1~6건 | 채널 한도 이내다. Slack 장애 때 묶이는 thread가 3~18개로, 200개의 약 10%까지다 |
| **C** 한도 근접·초과 | 분당 60건 이상인 시간대가 있다, 또는 workspace 전체가 분당 100건 이상 | 초당 6건 이상 | 채널 한도를 넘는다. workspace 한도(분당 수백 건)에도 가까워진다 |
| **D** 대량 | 발생 이벤트가 분당 수천 건 이상 | - | 한도의 수십 배다. 어떤 구조로도 전부 보낼 수 없다 |

- ② 기준은 전체 timeout 3초, Tomcat thread 200개를 가정한 값이다. 설정이 다르면 3.2의 식으로 다시 계산한다.
- ②는 **고객 요청을 처리하는 thread**에서 보내는 경우에만 따진다. 스케줄러·배치 thread에서 보낸다면 ①만 본다.

#### 구간별 권장 방식

| | 구간 A | 구간 B | 구간 C | 구간 D |
|---|---|---|---|---|
| **참고용 알림** (같은 정보가 DB·관리 화면에도 있음) | Tier 1 | 요청 경로 밖: Tier 1 / 고객 요청 경로 안: Tier 2 | 먼저 요약·억제(6.6)로 A/B까지 줄인다 | 로그·모니터링 도구로 보내고 Slack에는 요약만 |
| **업무 알림** (사라지면 업무 누락·금전 문제) | Tier 3 | Tier 3 | Tier 3 + 채널별 속도 제한. 가능하면 요약도 | 건별 전달은 Slack이 아닌 수단(업무 시스템, 이메일 등). Slack에는 요약만 |
| **장애 알림** (7장) | 중복 억제 + Tier 1 | 중복 억제 → 대부분 A로 떨어진다 | 중복 억제 + 상태 변화 알림 → A로 줄인다 | 모니터링 도구에 맡긴다 |

- **Tier 2와 `AsyncMethodsClient`**: 구간 B에서 같은 채널로 짧은 burst가 잦다면 Tier 2의 `SlackSender` 안에서 `MethodsClient` 대신 `AsyncMethodsClient`를 쓰면 전송을 알아서 늦춰 준다. 유실 특성은 같다.
- **고객 API는 구간 A여도 Tier 2를 검토한다.** Slack 장애 때 응답이 최대 timeout(3초)만큼 늘어나는 것을 받아들일 수 없다면 구간과 관계없이 Tier 2다(5.3의 Q4).
- **Tier 3는 속도를 올려 주지 않는다.** 구간 C에서 Tier 3를 쓰면 메시지를 잃지는 않지만, 채널 한도(초당 1건)를 넘게 들어오는 만큼 queue가 계속 쌓인다. 피크가 끝나면 따라잡을 수 있는 수준인지 확인하고, 아니면 요약해야 한다.

#### 하루 건수로 어림하기

지표가 하루 건수밖에 없다면 다음처럼 어림한다. 한 채널로 모두 보내고, **피크가 평균의 5배**라고 가정한 값이다.

| 하루 건수 | 평균 (분당) | 추정 피크 (분당) | 구간 |
|---|---|---|---|
| 1,000 | 0.7 | 약 3.5 | A |
| 3,000 | 2.1 | 약 10 | A~B 경계 |
| 10,000 | 6.9 | 약 35 | B |
| 20,000 | 13.9 | 약 69 | C |
| 100,000 | 69 | 약 350 | C (workspace 한도 수준) |
| 1,000,000 | 694 | 약 3,500 | D |

장애 알림처럼 **평소 0건이다가 한꺼번에 몰리는** 알림은 이 표로 계산하면 안 된다. 장애가 났을 때의 발생 속도(예: 실패한 요청 수)로 계산한다.

#### 실제 피크 재는 법

알림의 원인이 되는 데이터가 DB에 있다면 분 단위로 묶어 가장 많았던 시간을 찾는다(MySQL 예).

```sql
-- 최근 7일 동안 주문이 가장 많았던 1분 구간 상위 10개
SELECT DATE_FORMAT(created_at, '%Y-%m-%d %H:%i') AS minute_bucket,
       COUNT(*)                                  AS cnt
FROM orders
WHERE created_at >= NOW() - INTERVAL 7 DAY
GROUP BY minute_bucket
ORDER BY cnt DESC
LIMIT 10;
```

이미 Slack을 보내고 있다면 `SlackSender`에 붙인 지표(6.2)나 전송 로그를 분 단위로 세어 본다. 이벤트·세일·월말처럼 평소보다 몰리는 날의 데이터도 함께 본다.

### 5.3 질문으로 고르기

트래픽 구간과 함께 아래 질문에 위에서부터 답한다. **처음 YES가 나온 곳에서 멈춘다.**

```text
Q0. 이 메시지를 Slack으로 보내는 게 맞는가? (구간 D, 에러 로그 전부 등)
    └─ 아니오 -> 로그·모니터링 도구로 보낸다. Slack에는 요약만.

Q1. Slack 전송 성공이 현재 요청의 성공 조건인가?
    (예: Slack에 승인 요청을 올리고 그 ts를 저장해야 하는 기능)
    └─ YES -> 동기 호출. 실패하면 요청도 실패 처리한다.

Q2. 이 메시지가 한 건 사라지면, 누가 언제 알아차리고 어떤 피해가 생기는가?
    └─ "아무도 모른 채 해야 할 일이 누락된다 / 돈·고객 문제로 이어진다" -> Tier 3
       (장애 알림이라면 Tier 3 대신 7.5의 두 번째 경로)

Q3. 트래픽이 구간 C 이상인가?
    └─ YES -> 먼저 요약·억제한다. 줄인 양으로 Q4부터 다시 판단한다.

Q4. 고객이 호출하는 API(주문, 결제, 가입 등) 안에서 보내는가? 또는 구간 B 이상인가?
    └─ YES -> Tier 2 (스케줄러·배치 thread에서 보내는 구간 B라면 Tier 1도 가능)

Q5. 모두 NO -> Tier 1
```

**Q2가 가장 중요하다.** 방식은 양보다 **중요도**로 먼저 갈린다. 하루 3건뿐인 결제 이상 알림은 Tier 3이고, 하루 1,000건인 가입 알림은 Tier 2다. Q2가 헷갈리면 이렇게 묻는다.

- 같은 정보가 DB나 관리 화면에도 남는가? → 남는다면 Slack은 "빨리 알려 주는 보조 수단"이다. 유실을 허용할 수 있다.
- 담당자가 Slack 메시지만 보고 일을 시작하는가? → 그렇다면 Slack이 유일한 전달 수단이다. 유실이 곧 업무 누락이다.

### 5.4 상황별 예시

| # | 상황 | 트래픽 | 한 건이 사라지면? | 권장 |
|---|---|---|---|---|
| 1 | 매일 새벽 배치 성공/실패 알림 | 하루 수십 건 (A) | 배치 이력으로 확인 가능 | **Tier 1** |
| 2 | 관리자가 프로모션을 승인하면 알림 | 하루 수십 건 (A) | 관리 화면에서 확인 가능 | **Tier 1**. 관리 화면은 수백 ms 지연을 허용한다 |
| 3 | 배포 시작/완료 알림 | 하루 수 건 (A) | 무시 가능 | **Tier 1** |
| 4 | 회원가입 시 운영 채널 알림 | 하루 수백 건 (A) | 가입 정보는 DB에 있다 | **Tier 2**. 고객 API 응답 시간을 보호한다 |
| 5 | 주문 완료 알림 (운영 참고용) | 하루 3만 건, 점심 피크 분당 100건 (C) | 주문은 DB에 있다 | **1분 요약 + Tier 1** (6.6-1). 건별 전송을 포기한다 |
| 6 | 외부 PG·API 연동 오류 알림 | 평소 0, 장애 시 초당 수십 건 (D) | 같은 오류가 곧 다시 난다 | **중복 억제 + Tier 1** (6.6-2). 억제 후 5분에 약 2건 (A) |
| 7 | CS 문의 접수 알림 (상담사가 Slack만 보고 응대) | 하루 수백 건 (A) | 문의가 방치된다 | **Tier 3** (6.5) |
| 8 | 결제 실패·정산 불일치 알림 | 하루 수 건 (A) | 금전 사고를 늦게 안다 | **Tier 3**. 양이 적어도 중요도가 높다 |
| 9 | 사내 툴에서 전 직원 1,000명에게 DM 공지 | 한 번에 1,000건 (C, workspace 한도) | 일부 직원이 못 받는다 | **Tier 3**. workspace 한도 안에서 천천히 나눠 보낸다 |
| 10 | Slack에 승인 요청을 올리고 그 `ts`를 저장하는 기능 | 적음 (A) | 기능 자체가 실패한다 | **동기 호출, 실패 시 요청 실패** (Q1) |
| 11 | 애플리케이션 ERROR 로그마다 Slack 전송 | 장애 시 초당 수백 건 (D) | - | **Slack 부적합**. 로그·모니터링 도구로 보내고 요약만 Slack으로 (Q0) |

---

## 6. 구현

### 6.1 라이브러리 선택

| 선택지 | 판단 | 이유 |
|---|---|---|
| Slack Java SDK (`com.slack.api:slack-api-client`) | **채택** | Slack 공식이고 계속 관리된다. 동기·비동기 client, timeout 설정, 타입이 있는 request/response를 모두 제공한다. Incoming Webhook 전송(`slack.send`)도 같은 라이브러리로 된다. |
| Bolt for Java (`com.slack.api:bolt`) | 전송만 하면 불필요 | 이벤트, slash command, 버튼 클릭 등을 **받는** Slack App용 framework다. 내부적으로 위 SDK를 쓴다. |
| Incoming Webhook | 조건부 | 채널 하나로 고정된 단순 알림이면 간단하다. 제약은 4.5 참고. |
| `WebClient`/`RestClient`로 직접 HTTP 호출 | 비권장 | `ok` 필드 파싱, 429 처리, 오류 모델을 다시 만들어야 한다. |
| jslack, allbegray/slack-api, simple-slack-api 등 | 사용 금지 | jslack은 공식 SDK의 옛 이름이다. 나머지는 관리가 중단된 비공식 라이브러리다. |

```groovy
// build.gradle (버전은 최신 릴리스를 확인해서 지정)
implementation "com.slack.api:slack-api-client:1.x.x"
```

### 6.2 공통 기반: 설정과 전송 컴포넌트

`Slack` 인스턴스와 `MethodsClient`는 **Bean 하나로 만들어 재사용**한다. 호출할 때마다 새로 만들면 HTTP connection을 재사용하지 못한다.

```java
@Configuration
public class SlackClientConfig {

    @Bean
    public Slack slack() {
        SlackConfig config = new SlackConfig();
        config.setHttpClientReadTimeoutMillis(2_000);
        config.setHttpClientWriteTimeoutMillis(2_000);
        config.setHttpClientCallTimeoutMillis(3_000); // 호출 전체 상한 (기본값: 없음)
        return Slack.getInstance(config);
    }

    @Bean
    public MethodsClient slackMethodsClient(Slack slack,
                                            @Value("${slack.bot-token}") String botToken) {
        return slack.methods(botToken); // token은 코드가 아니라 환경 변수·secret 저장소에서 읽는다
    }
}
```

전송 결과는 네 가지로 나눈다. Tier 3 worker가 이 구분으로 재시도 여부를 정한다.

```java
public enum SlackSendResult {
    SUCCESS,        // 게시 성공
    RETRYABLE,      // 게시되지 않았음이 확실하고, 다시 보내면 성공할 수 있음
    NON_RETRYABLE,  // 설정 오류 등. 다시 보내도 실패
    UNKNOWN         // 게시 여부를 알 수 없음. 다시 보내면 중복될 수 있음
}
```

```java
@Slf4j
@Component
@RequiredArgsConstructor
public class SlackSender {

    private static final Set<String> RETRYABLE_ERRORS =
            Set.of("ratelimited", "rate_limited", "service_unavailable");

    // Slack 문서상 "일부 작업은 이미 성공했을 수 있음" -> 결과를 모르는 것으로 취급
    private static final Set<String> UNKNOWN_ERRORS =
            Set.of("internal_error", "fatal_error");

    private final MethodsClient slack;

    public SlackSendResult send(String channelId, String text) {
        try {
            ChatPostMessageResponse res = slack.chatPostMessage(r -> r.channel(channelId).text(text));
            if (res.isOk()) {
                return SlackSendResult.SUCCESS;
            }
            // HTTP 200 + ok:false -> 예외가 아니므로 직접 확인해야 한다
            log.warn("[Slack] post failed. channel={}, error={}", channelId, res.getError());
            if (RETRYABLE_ERRORS.contains(res.getError())) {
                return SlackSendResult.RETRYABLE;
            }
            if (UNKNOWN_ERRORS.contains(res.getError())) {
                return SlackSendResult.UNKNOWN;
            }
            return SlackSendResult.NON_RETRYABLE;

        } catch (SlackApiException e) { // HTTP 200번대가 아닌 응답 (예: 429)
            log.warn("[Slack] http error. channel={}, status={}, retryAfter={}",
                    channelId, e.getResponse().code(), e.getResponse().header("Retry-After"));
            return e.getResponse().code() == 429 || e.getResponse().code() >= 500
                    ? SlackSendResult.RETRYABLE : SlackSendResult.NON_RETRYABLE;

        } catch (ConnectException | UnknownHostException e) { // 연결 자체 실패 -> 게시되지 않았음이 확실
            log.warn("[Slack] connect failed. channel={}", channelId, e);
            return SlackSendResult.RETRYABLE;

        } catch (IOException e) { // read timeout 등 -> 게시 여부를 알 수 없음
            log.warn("[Slack] io error, outcome unknown. channel={}", channelId, e);
            return SlackSendResult.UNKNOWN;

        } catch (RuntimeException e) { // Slack 오류가 비즈니스 로직으로 번지지 않게 막는다
            log.error("[Slack] unexpected error. channel={}", channelId, e);
            return SlackSendResult.NON_RETRYABLE;
        }
    }
}
```

- OkHttp의 connect timeout은 `ConnectException`이 아니라 `SocketTimeoutException`으로 와서 `UNKNOWN`으로 분류된다. 실제로는 보내지지 않은 경우지만, 중복보다 누락을 택하는 보수적인 분류라 그대로 둬도 된다.
- 운영을 위해 Micrometer `Timer`(호출 시간)와 결과별 `Counter`(SUCCESS, RETRYABLE, NON_RETRYABLE, UNKNOWN)를 붙인다. 5.2의 피크 측정과 8.2의 신호 감지에 쓴다.

### 6.3 Tier 1 — 동기 호출 + AFTER_COMMIT

**대상**: 구간 A 또는 스케줄러·배치에서 보내는 구간 B. 기다려도 되는 알림.

```java
// 업무 서비스: Slack을 직접 호출하지 않고 이벤트만 발행한다
@Transactional
public void approvePromotion(Long promotionId) {
    promotion.approve();
    eventPublisher.publishEvent(new PromotionApprovedEvent(promotionId));
}
```

```java
// 리스너: commit 뒤에 동기로 보낸다 (rollback되면 보내지 않는다)
@Component
@RequiredArgsConstructor
public class PromotionSlackNotifier {

    private final SlackSender slackSender;

    @Value("${slack.channel.promotion}")
    private String channelId;

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void on(PromotionApprovedEvent event) {
        slackSender.send(channelId, "프로모션 승인: " + event.promotionId());
        // 실패해도 로그만 남기고 재시도하지 않는다
    }
}
```

- `AFTER_COMMIT` 리스너도 기본으로는 **같은 요청 thread에서 동기로** 실행된다. 요청 응답 시간에 Slack 호출 시간(보통 수백 ms, 최악이면 timeout 3초)이 더해진다.
- 이벤트를 발행할 때 진행 중인 transaction이 없으면 `@TransactionalEventListener`는 기본적으로 **이벤트를 무시한다**. transaction 밖에서도 발행될 수 있다면 `fallbackExecution = true`를 검토한다.

### 6.4 Tier 2 — `@Async` + 전용 bounded Executor

**대상**: 고객 요청 경로에서 보내는 알림, 또는 구간 B. 일부 유실은 괜찮은 경우.

```java
@Slf4j
@EnableAsync
@Configuration
public class SlackAsyncConfig {

    @Bean(name = "slackExecutor")
    public ThreadPoolTaskExecutor slackExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(2);
        executor.setMaxPoolSize(4);
        executor.setQueueCapacity(500);             // 반드시 크기를 제한한다
        executor.setThreadNamePrefix("slack-");
        executor.setRejectedExecutionHandler((r, ex) ->
                log.warn("[Slack] executor saturated, message dropped")); // 넘치면 버리고 기록한다
        executor.setWaitForTasksToCompleteOnShutdown(true);
        executor.setAwaitTerminationSeconds(10);
        executor.initialize();
        return executor;
    }
}
```

```java
@Component
@RequiredArgsConstructor
public class PromotionSlackNotifier {

    private final SlackSender slackSender;

    @Value("${slack.channel.promotion}")
    private String channelId;

    @Async("slackExecutor")
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void on(PromotionApprovedEvent event) {
        slackSender.send(channelId, "프로모션 승인: " + event.promotionId());
    }
}
```

- **executor 이름을 반드시 지정한다.** 이름 없는 `@Async`는 다른 비동기 작업과 기본 executor를 함께 쓰고, Spring Boot 기본 executor(`applicationTaskExecutor`)는 queue 크기가 사실상 무제한이다.
- **반대 방향도 조심한다.** `slackExecutor`처럼 `Executor` Bean을 직접 등록하면 Spring Boot는 기본 executor를 만들지 않는다. 그러면 다른 곳의 이름 없는 `@Async`까지 `slackExecutor`에서 실행될 수 있다. 앱에 다른 `@Async` 작업이 있다면 일반 작업용 executor를 `taskExecutor`라는 이름이나 `@Primary`로 따로 등록한다.
- 같은 class 안에서 `@Async` 메서드를 부르면(self-invocation) proxy를 거치지 않아 동기로 실행된다. 위처럼 리스너를 별도 class로 둔다.
- `void`를 반환하는 `@Async`의 예외는 호출한 쪽에 전달되지 않는다. `SlackSender`가 예외를 모두 잡고, `AsyncUncaughtExceptionHandler`도 설정한다.

**Tier 2가 막아 주는 것과 못 막는 것**

```text
처리 속도 ≈ thread 수 ÷ 호출 1건 시간 = 2 ÷ 0.3초 ≈ 초당 7건
```

(core 2, max 4로 설정해도 `ThreadPoolTaskExecutor`는 **queue가 가득 찬 뒤에야** thread를 core 이상으로 늘린다. 그래서 평소 처리 속도는 core 2개로 계산한다.)

- **짧은 burst는 막아 준다.** 10초 동안 50건이 몰려도 queue에 담겼다가 곧 처리된다. 구간 B의 상한(초당 6건)도 처리할 수 있다.
- **Slack 장애는 막아 주지 못한다.** 장애 중에는 호출이 timeout으로 실패하고, Tier 2는 실패를 로그로 남기고 버린다. **장애 중 메시지는 사라진다.**
- **같은 채널 burst도 막아 주지 못한다.** 같은 채널로 50건을 한꺼번에 보내면 한도를 넘은 만큼 429로 버려진다. 이런 burst가 잦다면 `SlackSender` 안에서 `AsyncMethodsClient`를 쓰거나(전송을 늦춰 준다) 중복 억제(6.6-2)를 넣는다.

### 6.5 Tier 3 — Outbox + 전용 Worker

**대상**: 사라지면 안 되는 업무 알림, 또는 구간 C에서 모두 보내야 하는 경우. 예: 상담사가 Slack 알림을 보고 응대를 시작하는 CS 문의 접수 알림. Slack 장애가 몇 시간 이어져도 복구된 뒤에는 반드시 전달돼야 한다.

**구조**

```text
[업무 transaction]  문의 저장 + slack_outbox INSERT (같은 transaction)
      |
      v
[Worker]  1초마다 outbox 조회 -> 채널별 1건씩 SlackSender.send()
      |
      +-- SUCCESS        -> SENT
      +-- RETRYABLE      -> 간격을 늘려 재시도, N회 넘으면 FAILED
      +-- NON_RETRYABLE  -> FAILED (channel_not_found 등 설정 오류. 사람이 확인)
      +-- UNKNOWN        -> 중복 허용 여부에 따라 재시도 또는 SENT
```

"문의 저장"과 "Slack·MQ 전송"은 하나의 transaction으로 묶을 수 없다(dual write 문제). 그래서 **보낼 메시지를 업무 데이터와 같은 DB, 같은 transaction에 저장**하고, 전송은 별도 worker가 맡는다. 이것이 Transactional Outbox 패턴이다.

**1단계 — outbox 테이블**

```sql
CREATE TABLE slack_outbox (
    id              BIGINT       AUTO_INCREMENT PRIMARY KEY,
    channel_id      VARCHAR(20)  NOT NULL,
    text            TEXT         NOT NULL,
    status          VARCHAR(20)  NOT NULL,          -- PENDING, SENT, FAILED
    retry_count     INT          NOT NULL DEFAULT 0,
    next_attempt_at DATETIME     NOT NULL,          -- 이 시각 이후에 전송 시도
    created_at      DATETIME     NOT NULL,
    INDEX idx_status_next_attempt (status, next_attempt_at)
);
```

**2단계 — 업무 로직: Slack을 호출하지 않고 outbox에 기록만 한다**

```java
@Transactional
public void createInquiry(InquiryRequest request) {
    Inquiry inquiry = inquiryRepository.save(Inquiry.from(request));
    // 문의 저장과 같은 transaction -> 문의가 저장되면 알림도 반드시 저장된다 (rollback되면 둘 다 없음)
    slackOutboxRepository.save(
            SlackOutbox.pending(csChannelId, "새 문의 #" + inquiry.getId() + ": " + inquiry.getTitle()));
}
```

**3단계 — Worker: 1초마다 채널별로 1건씩 보낸다**

```java
@Component
@RequiredArgsConstructor
public class SlackOutboxWorker {

    private static final int MAX_RETRY = 10;

    private final SlackOutboxRepository outboxRepository;
    private final SlackSender slackSender;

    // 이 메서드에는 @Transactional을 붙이지 않는다 (Slack 호출 동안 DB connection을 잡지 않도록)
    @Scheduled(fixedDelay = 1_000) // @EnableScheduling 필요
    public void relay() {
        List<SlackOutbox> targets = outboxRepository
                .findTop20ByStatusAndNextAttemptAtLessThanEqualOrderByIdAsc(OutboxStatus.PENDING, LocalDateTime.now());

        Set<String> sentChannels = new HashSet<>();
        for (SlackOutbox message : targets) {
            if (!sentChannels.add(message.getChannelId())) {
                continue; // 채널당 1초에 1건만 보낸다. 나머지는 다음 실행에서 보낸다
            }

            SlackSendResult result = slackSender.send(message.getChannelId(), message.getText());
            switch (result) {
                case SUCCESS -> message.markSent();
                case RETRYABLE -> message.retryLater(MAX_RETRY);
                case NON_RETRYABLE -> message.markFailed();
                case UNKNOWN -> message.retryLater(MAX_RETRY); // CS 문의는 누락보다 중복이 낫다고 판단
            }
            outboxRepository.save(message);
        }
    }
}
```

```java
// SlackOutbox 엔티티: 재시도할수록 간격을 늘린다 (10초, 20초, 40초 ... 최대 10분)
public void retryLater(int maxRetry) {
    this.retryCount++;
    if (this.retryCount > maxRetry) {
        this.status = OutboxStatus.FAILED;
        return;
    }
    long delaySeconds = Math.min(10L * (1L << (retryCount - 1)), 600L);
    this.nextAttemptAt = LocalDateTime.now().plusSeconds(delaySeconds);
}
```

- **`FAILED` 상태가 DLQ 역할**을 한다. `FAILED` 건수를 모니터링하고, 생기면 원인(채널 삭제, token 만료 등)을 고친 뒤 `PENDING`으로 되돌린다.
- **서버가 여러 대**면 모든 서버의 worker가 같은 행을 동시에 보낼 수 있다. ShedLock 같은 분산 lock으로 worker를 한 대에서만 돌리거나, `SELECT ... FOR UPDATE SKIP LOCKED`로 행을 나눠 가져간다. 여러 worker가 같은 채널로 보내면 채널 한도를 나눠 쓰게 된다는 점도 기억한다.
- 이 예시는 이해를 돕기 위해 고정 간격으로 재시도한다. 실제로는 `SlackSendResult`에 `Retry-After` 값을 담아, 그 시간 동안 해당 채널 전송을 멈추도록 확장한다.
- **중복**: 이 구조는 "최소 한 번 전달(at-least-once)"이라 드물게 같은 메시지가 두 번 갈 수 있다. 문제가 된다면 메시지에 문의 번호 같은 업무 key를 넣어 사람이 알아볼 수 있게 한다.
- 사내 표준 MQ(Kafka 등)가 있다면 worker가 MQ로 발행하고 Slack 전송은 MQ consumer가 맡도록 확장할 수 있다.

### 6.6 양 줄이기 패턴

구간 C·D를 A·B로 내리는 방법이다. **어떤 Tier를 쓰든 가장 효과가 크다.**

#### (1) 건별 알림 대신 주기적 요약

주문 완료 알림을 건별로 보내면 점심 피크에 채널 한도를 넘는다(5.4의 #5). 채널이 너무 시끄러워 아무도 읽지 않게 되는 문제(알림 피로)도 생긴다. 주문 API에서는 Slack을 전혀 호출하지 않고, 스케줄러가 1분마다 집계해 **1건**만 보낸다. 분당 1건이므로 구간 A이고, 스케줄러 thread에서 도므로 고객 요청에도 영향이 없다.

```java
@Component
@RequiredArgsConstructor
public class OrderSummaryNotifier {

    private final OrderRepository orderRepository;
    private final SlackSender slackSender;

    @Value("${slack.channel.order}")
    private String channelId;

    @Scheduled(cron = "0 * * * * *") // 매분 0초
    public void sendLastMinuteSummary() {
        LocalDateTime to = LocalDateTime.now().truncatedTo(ChronoUnit.MINUTES);
        LocalDateTime from = to.minusMinutes(1);

        // Between은 양 끝을 포함해 경계 시각의 주문이 두 번 집계될 수 있으므로 [from, to)로 조회한다
        long count = orderRepository.countByCreatedAtGreaterThanEqualAndCreatedAtLessThan(from, to);
        if (count == 0) {
            return;
        }
        slackSender.send(channelId,
                String.format("[%s ~ %s] 신규 주문 %d건", from.toLocalTime(), to.toLocalTime(), count));
    }
}
```

- 서버가 여러 대면 모든 서버에서 스케줄러가 돌아 같은 요약이 여러 번 나간다. ShedLock 등으로 한 대에서만 실행한다.

#### (2) 같은 알림 묶기: "첫 알림은 즉시, 나머지는 요약"

외부 API 장애처럼 같은 오류가 요청마다 반복되는 경우에 쓴다.

- 같은 종류의 알림이 처음 발생하면 **즉시** 보낸다. 장애는 빨리 알아야 하므로 첫 알림은 늦추지 않는다.
- 이후 5분 동안 같은 알림은 보내지 않고 **개수만 센다**.
- 5분이 지나면 "5분간 N건 추가 발생" 요약을 1건 보낸다.

오류가 초당 100건씩 나도 Slack 호출은 **5분에 약 2건**(구간 A)이다. 이 정도면 요청 thread에서 동기로 호출해도 부담이 거의 없다.

```java
@Component
@RequiredArgsConstructor
public class IncidentAlertNotifier {

    private static final Duration WINDOW = Duration.ofMinutes(5);

    private final ConcurrentHashMap<String, AlertWindow> windows = new ConcurrentHashMap<>();
    private final SlackSender slackSender;

    @Value("${slack.channel.alert}")
    private String channelId;

    /**
     * 요청 thread에서 호출해도 된다.
     * Slack 호출은 key별로 5분에 한 번만 일어나고, 나머지 호출은 Map 연산 한 번으로 끝난다.
     *
     * @param alertKey 알림 "종류" (예: "PG_TIMEOUT"). 주문 번호처럼 매번 바뀌는 값은 넣지 않는다.
     */
    public void alert(String alertKey, String message) {
        AtomicBoolean isFirst = new AtomicBoolean(false);
        // 여러 thread가 동시에 들어와도 한 thread만 "처음"이 되도록 compute로 원자적으로 처리한다
        windows.compute(alertKey, (key, window) -> {
            if (window == null) {
                isFirst.set(true);
                return new AlertWindow(Instant.now(), new AtomicLong(0));
            }
            window.suppressed().incrementAndGet(); // 이미 알린 알림 -> 개수만 센다
            return window;
        });

        if (isFirst.get()) {
            slackSender.send(channelId, "[발생] [" + alertKey + "] " + message);
        }
    }

    /** 1분마다 5분이 지난 key를 정리하고, 생략된 알림이 있었다면 요약을 보낸다 */
    @Scheduled(fixedDelay = 60_000)
    public void flushExpiredWindows() {
        Instant now = Instant.now();
        windows.forEach((key, window) -> {
            if (now.isAfter(window.startedAt().plus(WINDOW)) && windows.remove(key, window)) {
                long suppressed = window.suppressed().get();
                if (suppressed > 0) {
                    slackSender.send(channelId, "[요약] [" + key + "] 최근 5분간 같은 알림 " + suppressed + "건 추가 발생");
                }
            }
        });
    }

    private record AlertWindow(Instant startedAt, AtomicLong suppressed) {}
}
```

```java
// 호출하는 쪽
try {
    pgClient.approve(payment);
} catch (PgTimeoutException e) {
    incidentAlertNotifier.alert("PG_TIMEOUT", "PG 승인 요청 timeout");
    throw e;
}
```

- 오류가 계속되면 5분마다 `[발생]`이 다시 나가므로 "아직 진행 중"임을 알 수 있다.
- 요약을 보내는 순간과 `alert()`가 겹치면 1~2건이 세어지지 않을 수 있다. 알림 용도로는 무시해도 되는 오차다.
- `alertKey`는 **종류** 단위로 정한다. 요청 ID나 사용자 ID를 넣으면 억제되지 않고 Map도 계속 커진다.

#### (3) 서버가 여러 대일 때: Redis로 억제 공유

(2)는 서버마다 Map이 따로 있어서 서버가 10대면 같은 알림이 10건 나간다. 이것이 부담스러우면 Redis로 "5분 안에 보낸 적이 있는지"를 공유한다.

```java
public void alert(String alertKey, String message) {
    boolean isFirst;
    try {
        // key가 없을 때만 저장 -> 처음 저장한 서버 한 대만 true를 받는다. 5분 뒤 자동 삭제
        isFirst = Boolean.TRUE.equals(
                redisTemplate.opsForValue().setIfAbsent("slack-alert:" + alertKey, "1", Duration.ofMinutes(5)));
    } catch (RuntimeException e) {
        // Redis 자체가 장애 원인일 수 있다. 억제 장치가 고장 나도 알림은 나가야 한다 (fail-open)
        isFirst = true;
    }
    if (isFirst) {
        slackSender.send(channelId, "[발생] [" + alertKey + "] " + message);
    }
}
```

**알림 경로에 새 의존성(Redis, DB)을 넣을 때는 "그게 고장 나면 알림은 어떻게 되는가"를 먼저 생각한다.**

---

## 7. 장애 알림으로 쓸 때

Slack을 가장 많이 쓰는 용도는 "우리 시스템에 문제가 생겼을 때 알려주는" 장애 알림이다. 장애 알림은 다른 알림과 성격이 달라서 따로 정리한다.

### 7.1 "동기로 써 왔는데 문제가 없었다"면

대부분 맞는 경험이다. 다만 **문제가 없었던 이유**와 **보이지 않았던 문제**를 나눠서 봐야 한다.

**문제가 없었던 이유**

- Slack이 정상이면 호출이 수백 ms로 짧아서 thread를 오래 잡지 않는다(3.2).
- Slack 장애와 우리 장애가 **같은 시간에** 겹친 적이 없었을 가능성이 크다. 동기 호출의 위험은 두 장애가 겹칠 때 드러난다.

**보이지 않았을 수 있는 문제**

- **"알림이 너무 많이 온다"는 이미 드러난 문제다.** 이것은 동기/비동기 문제가 아니라 **양 조절** 문제다. 비동기로 바꿔도 알림 수는 그대로다. 해결은 6.6이다.
- **말없이 사라진 알림이 있었을 수 있다.** 같은 채널로 초당 1건을 넘기면 429로 게시되지 않는다. 폭주 중 어떤 알림이 사라졌는지는 채널만 봐서는 모른다.
  - `MethodsClient`라면 로그에서 `429`나 `ratelimited`를 검색해 본다.
  - Incoming Webhook이라면 429에도 예외가 나지 않는다(4.5). 응답 코드를 확인하지 않았다면 기록조차 없다.

### 7.2 장애 알림이 특별한 이유

| 특성 | 설명 | 결과 |
|---|---|---|
| 평소 0건, 장애 시 폭증 | 오류 하나가 모든 요청에서 반복된다 | 순식간에 구간 C·D가 되어 채널 한도를 넘는다 |
| 우리 시스템이 가장 약할 때 발생 | 이미 DB나 외부 API를 기다리느라 thread가 부족하다 | 알림 전송까지 thread를 쓰면 장애가 더 빨리 번진다 |
| 가장 중요한 순간에 가장 시끄럽다 | 같은 메시지 수백 건이 채널을 덮는다 | 첫 알림과 복구 알림이 묻히고, 사람들이 채널을 음소거한다 |

```text
DB 장애로 모든 요청이 실패하고, 실패마다 catch 블록에서 동기로 Slack을 호출하는 경우
- 초당 요청 100건 -> 초당 Slack 호출 100건 (구간 D)
- 채널 한도는 초당 1건 -> 나머지 99건은 429로 버려진다
- 요청 thread는 이미 DB connection을 기다리며 묶여 있다 (HikariCP connectionTimeout 기본 30초)
- 여기에 Slack 호출 시간(정상 0.3초, Slack도 느리면 최대 timeout)이 더해진다
```

알림 100건 중 1건만 전달되고, 그 대가로 우리 thread는 더 오래 묶인다. **양을 줄이면 이 문제가 한꺼번에 풀린다.** 6.6-2를 적용하면 같은 상황에서 Slack 호출은 5분에 약 2건이다.

### 7.3 알림 양 줄이기

1. **같은 알림 묶기** — 6.6-2 (서버 여러 대면 6.6-3). 가장 먼저 적용한다.
2. **건별 알림 대신 상태 변화 알림**

   | 방식 | 예 | 양 |
   |---|---|---|
   | 건별 | "PG 승인 실패 (주문 #1234)" × 수백 건 | 오류 수만큼 |
   | 상태 변화 | "[발생] PG 오류율 5% 초과" → "[해소] PG 오류율 정상화" | 장애 1건당 2건 |

   오류율·응답 시간 같은 지표가 **정상 → 이상**, **이상 → 정상**으로 바뀔 때만 알린다. Resilience4j 같은 circuit breaker를 쓴다면 상태가 OPEN·CLOSED로 바뀌는 시점이 좋은 알림 시점이다. `[해소]`는 `[발생]` 메시지의 thread 답글로 달면 채널이 깔끔하다(2.2의 예시 코드. `ts`가 필요하므로 `chat.postMessage` 사용).

3. **심각도별 채널 분리**

   | 채널 예시 | 심각도 | 내용 | 멘션 |
   |---|---|---|---|
   | `#alert-critical` | 즉시 대응 | 결제 불가, 전체 서비스 오류 | 온콜 그룹(`<!subteam^ID>`) 또는 `<!here>` |
   | `#alert-warning` | 업무 시간 내 확인 | 오류율 증가, 외부 API 지연 | 없음 |
   | `#alert-info` | 참고 | 배치 결과, 배포 알림 | 없음 |

   채널 한도는 채널마다 따로 적용되므로, 사소한 알림 폭주가 중요한 알림을 429로 밀어내는 일을 막을 수 있다(workspace 한도는 공유한다). 모든 알림에 `<!channel>`을 붙이면 금방 아무도 반응하지 않는다. 멘션은 critical에만 쓴다.

### 7.4 알림 전송이 장애를 키우지 않게

- **timeout은 필수다**(6.2). 우리 장애와 Slack 지연이 겹칠 때 timeout 없는 동기 호출이 thread를 가장 오래 잡는다.
- **알림 코드의 예외가 새어 나가지 않게 한다.** 알림이 실패했다고 원래 요청이 다른 오류로 바뀌면 안 된다. `SlackSender`처럼 모든 예외를 잡는다.
- **Logback appender로 Slack에 보낸다면** `log.error()`를 호출한 thread가 곧 Slack을 호출하는 thread가 된다. 반드시 `AsyncAppender`로 감싸고 `neverBlock`을 `true`로 둔다. 기본값(`false`)에서는 queue가 가득 차면 **로그를 쓰려던 요청 thread가 멈춰서 기다린다.** appender 쪽에도 중복 억제가 필요하다.

```xml
<appender name="ASYNC_SLACK" class="ch.qos.logback.classic.AsyncAppender">
    <appender-ref ref="SLACK" />
    <queueSize>256</queueSize>
    <neverBlock>true</neverBlock> <!-- queue가 가득 차면 기다리지 않고 버린다 -->
</appender>
```

- 양이 구간 A로 줄었다면 동기 호출을 유지해도 된다. 줄일 수 없는 구조라면 Tier 2로 요청 thread와 분리한다.

### 7.5 Slack만 믿지 않기

장애 알림은 **Slack이 정상이어야** 도착한다. 3.1처럼 Slack 장애는 몇 시간씩 이어진 적이 있다. 우리 서버의 외부 통신(NAT gateway, proxy 등)이 끊겨도 앱에서 보내는 알림은 나가지 못한다.

- **즉시 대응이 필요한 critical 알림은 두 번째 경로를 둔다.** 온콜 도구(PagerDuty, Opsgenie 등의 전화·SMS·앱 푸시)나 이메일을 함께 쓴다.
- **장애 알림에는 Tier 3(Outbox)가 잘 맞지 않을 수 있다.** outbox는 우리 DB에 저장하는데, DB 장애라면 알림 저장부터 실패한다. 장애 알림의 전달 보장은 "우리 DB에 보관"보다 **"독립된 두 번째 경로"** 로 확보하는 편이 현실적이다.
- **알림 경로 자체를 감시한다.** Slack 전송 실패와 429 건수를 지표로 남긴다. 알림이 오지 않는 것이 "평온해서"인지 "알림이 고장 나서"인지 구분할 수 있어야 한다.

### 7.6 좋은 장애 알림 메시지

받는 사람이 **메시지만 보고 첫 행동을 정할 수 있어야** 한다.

```text
🚨 [PROD][CRITICAL] [발생] 결제 PG 승인 오류 급증
• 서비스: order-api (host: order-api-7f9c2)
• 발생 시각: 2026-09-29 14:03:12 KST
• 내용: PG_TIMEOUT, 최근 1분 오류 132건 / 요청 2,410건 (5.5%)
• 영향: 카드 결제 실패
• 대시보드: https://grafana.example.com/d/payment
• 로그: https://kibana.example.com/app/discover#/?traceId=abc123
```

| 넣을 것 | 넣지 말 것 |
|---|---|
| 환경(PROD/STAGE)과 심각도 | 전체 stack trace (길면 잘리고 채널을 덮는다. 첫 몇 줄 + 로그 링크로 대신) |
| 서비스명, host | 개인정보, 카드번호, token, 비밀번호 (Slack에 그대로 남는다) |
| 발생 시각 (시간대 포함) | 매번 다른 값이 들어간 제목 (같은 장애인지 알아보기 어렵다) |
| 건수·비율 같은 규모 | |
| 대시보드·로그 링크, trace ID | |

STAGE·개발 환경 알림은 운영 채널과 **다른 채널**로 보낸다. profile별 설정으로 채널 ID를 나눈다.

### 7.7 규모가 커지면 모니터링 도구에 맡긴다

6.6의 중복 억제, 묶기, 해소 알림은 모니터링 도구가 기본 기능으로 제공한다. 알림 종류가 많아지면 앱에서 Slack을 직접 부르기보다 **지표·로그를 모니터링 도구로 보내고, 그 도구가 Slack으로 알리게** 하는 편이 낫다.

| 도구 | 제공 기능 예 |
|---|---|
| Prometheus Alertmanager | `group_by`·`group_wait`·`group_interval`(묶기), `repeat_interval`(반복 간격), inhibition(상위 장애 시 하위 알림 억제), silence(점검 중 음소거), 해소 알림 |
| Grafana Alerting | 조건 기반 알림, 알림 묶기, 해소 알림 |
| Sentry | 같은 오류를 issue 하나로 묶기, 새 오류·급증 시에만 알림 |
| CloudWatch Alarm 등 클라우드 도구 | 지표 기준 상태 변화(OK → ALARM) 알림 |

앱에서 직접 보내는 방식(6.6)은 작은 서비스나 도구를 들이기 전 단계에 알맞다.

### 7.8 장애 알림 권장 구성

| 알림을 보내는 곳 | 권장 방식 |
|---|---|
| 모니터링 도구 (Alertmanager, Sentry 등) | 앱 구현 불필요. 도구의 묶기·반복 간격을 설정한다 |
| 스케줄러·배치에서 상태를 점검한 뒤 발송 | Tier 1 + timeout |
| 요청 처리 중 `catch`에서 발송 | 동기 호출 가능. 단, **중복 억제(6.6-2)와 timeout은 필수**. 억제 후에도 구간 B 이상이면 Tier 2 |
| Logback appender | `AsyncAppender` + `neverBlock=true` + 중복 억제 |
| 즉시 대응해야 하는 critical 알림 | 위 방식 + **온콜 도구·이메일 등 두 번째 경로** |

---

## 8. 운영: 흔한 실수와 방식을 바꿔야 할 신호

### 8.1 흔한 실수

**실수 1 — `@Transactional` 안에서 Slack 호출**

```java
// ❌ Slack이 느려지면 DB connection도 함께 묶인다. 전송 후 rollback되면 "없는 주문" 알림이 나간다
@Transactional
public void placeOrder(OrderRequest request) {
    orderRepository.save(Order.from(request));
    slackSender.send(channelId, "새 주문");
}

// ✅ 이벤트만 발행하고, commit 뒤에 리스너가 보낸다 (6.3)
@Transactional
public void placeOrder(OrderRequest request) {
    Order order = orderRepository.save(Order.from(request));
    eventPublisher.publishEvent(new OrderPlacedEvent(order.getId()));
}
```

**실수 2 — 실패하면 바로 반복 재시도**

```java
// ❌ read timeout 뒤 재시도하면 같은 메시지가 두 번 올라갈 수 있다. 장애 중에는 Slack 트래픽만 늘린다
for (int i = 0; i < 3; i++) {
    if (slackSender.send(channelId, text) == SlackSendResult.SUCCESS) break;
}

// ✅ Tier 1/2는 한 번만 보내고 결과를 로그로 남긴다. 재시도가 꼭 필요하면 Tier 3로 옮긴다
slackSender.send(channelId, text);
```

**실수 3 — timeout 없이 `Slack.getInstance()`를 그대로 사용**: 호출 전체 상한이 없어 장애 때 thread가 계속 묶인다(3.2 표 3행). 6.2의 설정을 쓴다.

**실수 4 — 이름 없는 `@Async`**: 기본 executor를 다른 작업과 함께 쓰고 queue도 사실상 무제한이다. `@Async("slackExecutor")`처럼 전용 executor를 지정한다. 반대로 `slackExecutor`를 등록하면 다른 이름 없는 `@Async`가 여기로 몰릴 수 있으니 일반 작업용 executor도 따로 둔다(6.4).

**실수 5 — 하루 평균으로 트래픽 판단**: 평균 분당 7건이어도 점심 피크에 분당 100건일 수 있다. 피크로 판단한다(5.2).

**실수 6 — 모든 알림을 처음부터 Tier 3로 구현**: 하루 10건짜리 참고용 알림에 outbox 테이블, worker, 모니터링까지 붙이면 관리할 코드만 늘어난다. 5.3의 질문으로 필요한 만큼만 만든다.

**실수 7 — 에러 로그마다 Slack 전송**: 장애 때 초당 수백 건이 몰려 채널 한도를 즉시 넘고, 중요한 알림이 묻힌다. 로그·모니터링 도구로 보내고 Slack에는 요약만 보낸다.

**실수 8 — Incoming Webhook 응답 코드 무시**: 429에도 예외가 나지 않아 유실을 모른다(4.5).

### 8.2 방식을 바꿔야 한다는 신호

| 현재 | 이런 현상이 보이면 | 바꿀 방향 |
|---|---|---|
| Tier 1 | Slack이 느려질 때 우리 API 응답 시간(p99)도 함께 튄다 | → Tier 2 |
| Tier 1 | thread dump에서 요청 thread 다수가 Slack(OkHttp) 응답을 기다리고 있다 | → Tier 2 |
| Tier 2 | `executor saturated, message dropped` 로그가 찍힌다 | → 먼저 요약·억제. 그래도 필요하면 Tier 3 |
| Tier 2 | "알림을 못 받았다"는 문의가 온다 | → Q2를 다시 판단한다. 중요한 알림이면 Tier 3 |
| Tier 3 | outbox의 `PENDING`이 피크가 끝나도 줄지 않는다 | → 채널 한도보다 많이 들어오고 있다. 요약·채널 분리 |
| 모든 Tier | 429 / `ratelimited` 로그가 반복된다 | → 구간 C 이상이다. 요약, 중복 억제, 채널 분리 |
| 모든 Tier | 채널에 메시지가 너무 많아 아무도 읽지 않는다 | → 요약 알림으로 바꾼다 (6.6-1) |
| Tier 3 | 하루 몇 건짜리 참고용 알림인데 outbox 관리 비용만 든다 | → Tier 1/2로 낮춘다 |

---

## 9. 구현 체크리스트

**방식 선택**

- [ ] 5.3의 질문(특히 "한 건이 사라지면 어떤 피해가 생기는가?")에 답하고 선택 근거를 남겼는가?
- [ ] 같은 채널의 **피크** 전송량을 재서 트래픽 구간을 확인했는가? (하루 평균이 아니라)
- [ ] 구간 C 이상이라면 요약·억제를 먼저 설계했는가?

**공통 구현**

- [ ] `Slack` 인스턴스와 `MethodsClient`를 Bean으로 재사용하는가?
- [ ] read, write, call timeout을 명시했는가? (기본 call timeout은 없다)
- [ ] 응답의 `ok` 필드를 확인하는가? (HTTP 200 + `ok:false`는 예외가 아니다)
- [ ] `IOException`, `SlackApiException`, `RuntimeException`을 모두 잡아 업무 로직으로 번지지 않게 했는가?
- [ ] `@Transactional` 안에서 Slack을 호출하지 않는가? (`AFTER_COMMIT` 사용)
- [ ] read timeout이나 `internal_error` 뒤에 무조건 재시도하지 않는가? (중복 게시 위험)
- [ ] 429에는 `Retry-After`를 따르는가?
- [ ] `@Async`를 쓴다면 전용 bounded executor와 rejection 정책을 지정했는가?
- [ ] Slack 호출 시간과 결과별 건수를 모니터링하는가?
- [ ] bot token을 코드가 아니라 secret 저장소나 환경 변수에서 읽는가?

**장애 알림이라면 추가로**

- [ ] 같은 종류의 알림을 묶는가? (첫 알림은 즉시, 나머지는 요약)
- [ ] Incoming Webhook을 쓴다면 응답 `code`를 확인하는가?
- [ ] 심각도별로 채널을 나누고, 멘션은 critical에만 쓰는가?
- [ ] Logback appender라면 `AsyncAppender` + `neverBlock=true`인가?
- [ ] 억제 장치(Redis 등)가 고장 나도 알림이 나가는가? (fail-open)
- [ ] critical 알림에 Slack 외 두 번째 경로가 있는가?
- [ ] 메시지에 환경, 심각도, 시각, 규모, 대시보드·로그 링크가 있고 개인정보는 없는가?

---

## 10. 참고 자료

### Slack 공식 개발 문서

- [Using the Web API (Java SDK)](https://docs.slack.dev/tools/java-slack-sdk/guides/web-api-basics/)
- [Incoming Webhooks (Java SDK)](https://docs.slack.dev/tools/java-slack-sdk/guides/incoming-webhooks/)
- [Sending messages using incoming webhooks](https://docs.slack.dev/messaging/sending-messages-using-incoming-webhooks/)
- [chat.postMessage](https://docs.slack.dev/reference/methods/chat.postMessage/)
- [Rate limits](https://docs.slack.dev/apis/web-api/rate-limits/)

### Slack Engineering

- [Scaling Slack's Job Queue](https://slack.engineering/scaling-slacks-job-queue/) (2017-12, 2020-06 갱신)
- [Load Testing with Koi Pond](https://slack.engineering/load-testing-with-koi-pond/) (2021-04)

### Slack Status 장애 보고

- [2020-10-05 Degraded performance / slow API performance](https://slack-status.com/2020-10/e8c094cc99aabf64)
- [2022-03-08 Job processing queue incident](https://slack-status.com/2022-03/8a9e98bfaa32ef5f)
- [2025-08-07 Backend cache timeout](https://slack-status.com/2025-08/2ece93bd6dccd4b5)

### Slack Java SDK 소스 (4장 근거)

- [SlackConfig.java](https://github.com/slackapi/java-slack-sdk/blob/main/slack-api-client/src/main/java/com/slack/api/SlackConfig.java) — timeout 설정과 기본값
- [MethodsClientImpl.java](https://github.com/slackapi/java-slack-sdk/blob/main/slack-api-client/src/main/java/com/slack/api/methods/impl/MethodsClientImpl.java) — 200번대/그 외 응답 처리, 429 처리
- [Slack.java](https://github.com/slackapi/java-slack-sdk/blob/main/slack-api-client/src/main/java/com/slack/api/Slack.java) — Incoming Webhook 전송(`send`)
- [MethodsConfig.java](https://github.com/slackapi/java-slack-sdk/blob/main/slack-api-client/src/main/java/com/slack/api/methods/MethodsConfig.java) / [ThreadPools.java](https://github.com/slackapi/java-slack-sdk/blob/main/slack-api-client/src/main/java/com/slack/api/methods/impl/ThreadPools.java) / [DaemonThreadExecutorServiceFactory.java](https://github.com/slackapi/java-slack-sdk/blob/main/slack-api-model/src/main/java/com/slack/api/util/thread/DaemonThreadExecutorServiceFactory.java) — `AsyncMethodsClient` thread pool

---

## 부록 A. 용어 풀이

| 용어 | 뜻 | 이 문서에서의 예 |
|---|---|---|
| 동기(synchronous) 호출 | 결과가 올 때까지 기다린 뒤 다음 코드로 넘어가는 호출 | `slack.chatPostMessage(...)`가 끝나야 API 응답이 나간다 |
| 비동기(asynchronous) 호출 | 요청만 맡겨 두고 결과를 기다리지 않고 다음 코드로 넘어가는 호출 | `@Async` 메서드 호출 |
| latency | 요청을 보내고 응답을 받기까지 걸리는 시간 | Slack 호출이 평소 0.3초, 장애 시 3초 |
| p99 | 가장 느린 1%를 뺀 나머지 요청이 이 시간 안에 끝난다는 지표 | "p99 응답 시간이 200ms에서 3초로 튀었다" |
| timeout | 이 시간이 지나면 기다리기를 포기하는 설정 | call timeout 3초 |
| thread pool | 작업을 처리할 thread를 미리 만들어 두고 재사용하는 묶음 | Tomcat 요청 thread 200개, `slackExecutor` |
| cascading failure (연쇄 장애) | 한 시스템의 장애가 그 시스템을 호출하는 쪽으로 번지는 현상 | Slack 지연 → 우리 thread 고갈 → 우리 API 장애 |
| rate limit | 일정 시간 동안 보낼 수 있는 요청 수의 상한 | 채널당 초당 1건 |
| burst | 짧은 시간에 요청이 몰리는 것 | 배포 직후 10초 동안 50건 |
| 피크(peak) | 가장 많이 몰리는 시간대의 양 | 점심 12시대 분당 100건 |
| HTTP 429 | "요청이 너무 많다"는 HTTP 응답 코드 | `Retry-After: 30`이면 30초 뒤 재시도 |
| idempotency (멱등성) | 같은 요청을 여러 번 보내도 결과가 한 번 보낸 것과 같은 성질 | `chat.postMessage`는 멱등하지 않아 재시도하면 두 번 게시될 수 있다 |
| 요약 / digest | 여러 이벤트를 모아 메시지 하나로 합치는 것 | "최근 1분 신규 주문 12건" |
| 중복 억제 | 같은 알림을 일정 시간 동안 다시 보내지 않는 것 | 같은 오류는 5분에 1번 |
| `AFTER_COMMIT` | DB transaction이 commit된 뒤에 이벤트 리스너를 실행하는 옵션 | 주문 저장이 확정된 뒤에만 알림 전송 |
| Transactional Outbox | 업무 데이터와 "보낼 메시지"를 같은 transaction으로 저장하고, 별도 프로세스가 전송하는 패턴 | `slack_outbox` 테이블 + worker |
| dual write 문제 | DB와 MQ처럼 서로 다른 두 곳에 쓸 때 한쪽만 성공할 수 있는 문제 | 주문은 저장됐는데 MQ 발행은 실패 |
| DLQ (Dead Letter Queue) | 여러 번 재시도해도 실패한 메시지를 따로 모아 두는 곳 | outbox의 `FAILED` 상태 |
| at-least-once | "최소 한 번은 전달한다". 대신 중복 전달될 수 있다 | Tier 3의 전달 보장 수준 |
| backoff | 재시도할 때마다 대기 시간을 점점 늘리는 방식 | 10초 → 20초 → 40초 |
| throttle | 보내는 속도를 일부러 제한하는 것 | 채널당 1초에 1건만 전송 |
| fail-open | 보조 장치가 고장 나면 "막기" 대신 "통과"를 택하는 설계 | Redis가 죽으면 중복 억제를 포기하고 알림은 보낸다 |
| 온콜(on-call) | 장애 때 즉시 대응하도록 당번을 정해 두는 체계. 전화·SMS로 호출하는 도구를 함께 쓴다 | PagerDuty, Opsgenie |
