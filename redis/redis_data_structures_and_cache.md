# Redis 자료구조와 캐시 전략

> `redis-select-db.md`가 "DB 번호가 여러 개라는 실수담"이었다면, 이 문서는 Redis를 캐시로 실제 활용할 때 필요한 자료구조/영속성/전략을 정리.
> 블로그의 `spring-session-redis.md`(세션 외부화)에서 이미 Redis를 "쓰기"만 했다면, 여기서는 "왜 그렇게 쓰는지"의 배경.

## 1. Redis의 핵심 자료구조

| 타입 | 설명 | 대표 명령어 |
|---|---|---|
| String | 가장 기본. 문자열/숫자/직렬화된 객체 | `SET`, `GET`, `INCR` |
| List | 순서가 있는 문자열 목록 (연결 리스트) | `LPUSH`, `RPUSH`, `LRANGE` |
| Hash | 필드-값 쌍의 집합 (객체 하나를 표현하기 좋음) | `HSET`, `HGET`, `HGETALL` |
| Set | 중복 없는 집합, 순서 없음 | `SADD`, `SISMEMBER`, `SINTER`(교집합) |
| Sorted Set (ZSet) | 각 원소에 score를 매겨 정렬된 집합 | `ZADD`, `ZRANGE`, `ZRANK` |

### 실전 활용 예

~~~
# 좋아요 수 카운터 (String + INCR : 원자적 증가, 동시성 문제 없이 카운트 가능)
INCR post:1001:likes

# 최근 조회한 상품 목록 (List, 최근 N개만 유지)
LPUSH user:42:recent_view 1001
LTRIM user:42:recent_view 0 9   # 앞에서 10개만 남기고 나머지 삭제

# 실시간 랭킹 (Sorted Set - score로 자동 정렬됨)
ZADD leaderboard 1500 "player1"
ZADD leaderboard 2300 "player2"
ZREVRANGE leaderboard 0 9 WITHSCORES   # 상위 10명 조회

# 로그인한 사용자 캐시 (Hash - 객체 하나를 필드별로)
HSET user:42 name "jmlim" email "hackerljm@gmail.com"
HGETALL user:42
~~~

- `mysql_index.md`와 연결지어 보면, Sorted Set으로 랭킹을 구현하는 건 사실상 MySQL에서 `ORDER BY score DESC LIMIT 10` 을 매번 인덱스로 스캔하는 대신, **애초에 정렬된 상태를 자료구조 레벨에서 유지**해버리는 접근이다 — 읽기가 압도적으로 빈번한 랭킹류 데이터에 잘 맞는다.

## 2. 영속성 (Persistence) — Redis도 메모리만 쓰는 게 아니다

- Redis는 인메모리 DB지만, 서버가 재시작돼도 데이터를 잃지 않도록 두 가지 영속화 방식을 제공한다.

| 방식 | 동작 | 장점 | 단점 |
|---|---|---|---|
| **RDB** (스냅샷) | 특정 시점 전체 메모리 상태를 디스크에 파일(.rdb)로 저장 | 파일이 작고 복구가 빠름, 백업하기 좋음 | 마지막 스냅샷 이후 데이터는 유실될 수 있음 |
| **AOF** (Append Only File) | 모든 쓰기 명령을 로그 파일에 순서대로 기록 | 유실 데이터를 최소화 (설정에 따라 매 명령마다 기록 가능) | 파일이 크고, 복구 시간이 RDB보다 오래 걸림 |

- 실무에서는 두 방식을 **함께** 쓰는 경우가 많다 (RDB로 주기적 스냅샷 + AOF로 세밀한 복구). MongoDB 학습 노트에서 다룬 "쓰기 속도와 내구성의 트레이드오프"(저널링)와 정확히 같은 고민이 여기도 그대로 등장한다.
- 단, **순수 캐시 용도**(원본 데이터가 MySQL/MongoDB에 이미 있고, Redis는 조회 속도만 높이는 용도)라면 영속성을 아예 꺼두는 경우도 흔하다 — 캐시가 날아가도 원본에서 다시 채우면 되기 때문(cache miss만 늘어날 뿐).

## 3. 캐시 전략 (Cache Strategy)

### Cache-Aside (Lazy Loading) — 가장 흔한 패턴
~~~
조회: 캐시 확인 -> 있으면 반환(Cache Hit) -> 없으면 DB 조회 후 캐시에 채워넣고 반환(Cache Miss)
쓰기: DB에 쓰고, 해당 캐시는 무효화(삭제)하거나 갱신
~~~
~~~java
public Product getProduct(Long id) {
    Product cached = redisTemplate.opsForValue().get("product:" + id);
    if (cached != null) return cached;              // Cache Hit

    Product product = productRepository.findById(id); // Cache Miss -> DB 조회
    redisTemplate.opsForValue().set("product:" + id, product, Duration.ofMinutes(10));
    return product;
}
~~~
- 애플리케이션이 캐시 로직을 직접 관리 — 가장 유연하고 널리 쓰임. 다만 캐시와 DB 사이에 "잠깐 다른 값을 보게 되는" 시점이 생길 수 있음(최종적 일관성).

### Write-Through — 쓸 때 캐시도 같이 갱신
- DB에 쓰는 동시에 캐시도 갱신. 캐시가 항상 최신 상태를 유지하지만, 매 쓰기마다 캐시 갱신 비용이 추가됨.

### Write-Behind (Write-Back)
- 캐시에만 먼저 쓰고, DB 반영은 나중에 비동기로 몰아서 처리. 쓰기 성능은 가장 좋지만 캐시가 죽으면 아직 DB에 반영 안 된 데이터를 잃을 위험이 있음 — 흔치 않은 방식.

## 4. 캐시 무효화 전략 (Eviction Policy)

- 메모리가 가득 찼을 때 Redis가 어떤 키를 지울지 결정하는 정책. `maxmemory-policy` 설정으로 지정.

| 정책 | 설명 |
|---|---|
| `noeviction` | 새로 못 씀 (에러 반환) — 기본값 |
| `allkeys-lru` | 가장 오랫동안 사용 안 된(Least Recently Used) 키부터 제거 — 캐시 용도로 가장 흔히 씀 |
| `allkeys-lfu` | 사용 빈도(Least Frequently Used)가 가장 낮은 키부터 제거 |
| `volatile-ttl` | TTL(만료시간)이 설정된 키 중 가장 임박한 것부터 제거 |

- "캐시 무효화(invalidation)"는 컴퓨터 과학에서 이름 짓기와 함께 제일 어려운 문제 중 하나로 자주 농담처럼 언급된다 — TTL을 너무 짧게 잡으면 캐시 효과가 없고, 너무 길게 잡으면 오래된 데이터를 보여주는 문제(stale data)가 생기기 때문에 도메인별로 균형을 잡아야 함.

## 5. 캐시 스탬피드(Cache Stampede) 문제

- 인기 있는 키 하나가 만료되는 순간, 동시에 몰린 수많은 요청이 전부 Cache Miss로 DB에 몰려가서 DB에 부하가 집중되는 현상.
- 완화 방법: 캐시 갱신을 락으로 한 번만 수행하게 하기(요청 하나만 DB를 조회해서 캐시를 채우고, 나머지는 대기), 또는 만료 시간에 약간의 랜덤값을 더해 동시에 만료되는 걸 분산.

---

## 다음 학습 주제
- [redis-select-db.md](./redis-select-db.md) — DB 번호 개념 복습 (클러스터 모드에서는 DB가 하나뿐이라는 점도 실무에서 헷갈리는 포인트)
- Kafka 기초 — Redis Pub/Sub과 비교되는, 메시지 유실 없이 순서를 보장하는 메시징 시스템 (RabbitMQ 스터디 노트와도 비교해볼 것)
- Redis Cluster / Sentinel — 단일 Redis 인스턴스의 장애에 대비한 고가용성 구성
