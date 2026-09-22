# 3장. 프로그램을 이용한 MongoDB 활용

> 원래 이 시리즈(1, 2, 4~8장)는 『MongoDB in Action』 정리인데, 3장(드라이버를 이용한 프로그래밍) 노트가 비어 있어서 뒤늦게 채워 넣음.
> 셸(mongo shell) 명령어는 2장에서 다뤘으니, 이번엔 애플리케이션 코드에서 드라이버를 통해 접근하는 관점.

## 3.1. 드라이버란?

- MongoDB는 각 언어(Java, Node.js, Python, ...)마다 공식 드라이버를 제공하며, 셸에서 쓰던 `db.collection.find(...)` 같은 문법을 각 언어의 API 형태로 감싸서 제공한다.
- 드라이버가 하는 일
    1. 애플리케이션 객체 ↔ BSON 문서 간의 직렬화/역직렬화
    2. 커넥션 풀 관리 (매 요청마다 새로 연결하지 않고 재사용)
    3. 쓰기 시맨틱스(write concern) 처리 — 몇 대의 서버에 복제된 걸 확인하고 응답할지
    4. 장애 시 재시도, 읽기 대상 노드 선택(read preference) 등

## 3.2. 커넥션 관리 (Java 드라이버 기준 예시)

~~~java
MongoClient mongoClient = MongoClients.create("mongodb://localhost:27017");
MongoDatabase database = mongoClient.getDatabase("tutorial");
MongoCollection<Document> users = database.getCollection("users");
~~~

- `MongoClient`는 애플리케이션 생명주기 동안 **하나만** 생성해서 재사용해야 한다. 내부적으로 커넥션 풀을 들고 있기 때문에, 요청마다 새로 만들면 커넥션 풀이 계속 생성/폐기되면서 성능 저하 + 커넥션 고갈이 발생할 수 있다.
    - Spring Boot를 쓴다면 `spring-boot-starter-data-mongodb` 가 이 `MongoClient` 빈 생성을 대신 관리해준다.
- 커넥션 풀 관련 주요 옵션
    - `maxPoolSize` — 풀에 유지할 최대 커넥션 수
    - `connectTimeout` / `socketTimeout` — 연결 및 응답 대기 타임아웃
    - 이 개념은 MySQL의 HikariCP(블로그의 `spring-boot-logback-sql-pretty.md`에서 다룬 hikari 설정)와 사실상 같은 이야기다 — DB 종류가 달라도 "커넥션은 비싸니까 풀로 재사용한다"는 원리는 동일.

## 3.3. Write Concern (쓰기 시맨틱스)

- 1장에서 "쓰기 속도와 내구성은 트레이드오프 관계"라고 짚었던 부분을 실제로 제어하는 옵션이 write concern이다.
- MongoDB는 복제셋(replica set) 구조이므로, "쓰기가 완료됐다"의 기준을 다음 중에서 선택할 수 있다.

| Write Concern | 의미 | 특징 |
|---|---|---|
| `w: 0` (Unacknowledged) | 서버에 요청만 보내고 응답을 기다리지 않음 | 가장 빠르지만 쓰기 실패를 알 수 없음. 거의 안 씀 |
| `w: 1` (기본값) | Primary 노드에 쓰기가 반영되면 응답 | 기본 설정. Primary가 죽으면 아직 복제 안 된 데이터는 유실 가능 |
| `w: "majority"` | 복제셋 과반수 노드에 반영되어야 응답 | 내구성이 가장 강함. 응답 속도는 그만큼 느려짐 |
| `j: true` (Journaled) | 저널(journal, 일종의 WAL)에 기록된 후 응답 | 서버가 강제 종료돼도 저널 기반 복구가 가능함을 보장 |

~~~java
// Java 드라이버 예시 - 과반수 확인 + 저널 기록까지 기다리는 안전한 쓰기
WriteConcern wc = WriteConcern.MAJORITY.withJournal(true);
database.getCollection("orders").withWriteConcern(wc)
        .insertOne(new Document("orderId", "1001"));
~~~

- 실전 기준
    - 로그성 데이터, 유실돼도 큰 문제 없는 데이터 → `w: 1` (기본값)로도 충분.
    - 결제, 주문처럼 유실되면 안 되는 데이터 → `w: "majority"` (+ 필요하면 `j: true`) 고려.
    - 관계형 DB의 트랜잭션 격리수준/커밋 방식(MySQL의 `innodb_flush_log_at_trx_commit` 등)과 비슷한 결의 트레이드오프라고 생각하면 이해하기 쉬움.

## 3.4. 문서 ↔ 객체 매핑

- 1장 노트에서 "MongoDB에서는 ORM에 대한 필요성이 상대적으로 낮다"고 언급했었는데, 그 이유가 3장에서 조금 더 명확해진다.
    - 문서 자체가 이미 JSON 구조라서, 애플리케이션의 객체(POJO/DTO)와 구조적으로 거의 1:1로 대응됨.
    - Java 드라이버는 `MongoCollection<Document>` 대신 `MongoCollection<MyClass>` 처럼 POJO 타입을 바로 지정해서, `Codec` 을 통해 자동 매핑을 지원한다.
~~~java
MongoCollection<User> users = database.getCollection("users", User.class);
User user = users.find(eq("username", "smith")).first();  // 자동으로 User 객체로 역직렬화
~~~
- 다만 완전한 매핑을 위해서는 별도의 라이브러리(Spring Data MongoDB의 `@Document`, `MongoTemplate` 등)를 얹는 경우가 많다.

---

## 다음 학습 주제
- [mongodb_study_chap04](./mongodb_study_chap04.md) — 이어서 스키마 설계(도큐먼트 지향 데이터 모델링)
- Spring Data MongoDB의 `MongoRepository`, `@Document`, `@DBRef` — 이 장의 "드라이버 직접 사용" 대신 실무에서 훨씬 자주 쓰는 추상화 계층
- MongoDB 트랜잭션(4.0+에서 지원되는 멀티 도큐먼트 트랜잭션) — write concern과 별개로, 여러 문서에 걸친 원자성이 필요할 때
