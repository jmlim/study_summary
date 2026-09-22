## MySQL 트랜잭션 격리수준과 락

> `mysql_index.md`가 "조회를 어떻게 빠르게 할까"였다면, 이 문서는 "동시에 여러 트랜잭션이 같은 데이터를 건드릴 때 어떤 문제가 생기고 어떻게 막는가"에 대한 내용.
> 블로그의 `spring-transaction.md`가 트랜잭션의 "논리적 단위(commit/rollback)"를 다뤘다면, 여기서는 그 트랜잭션들이 **동시에** 실행될 때의 격리(Isolation) 문제를 다룸.

## 왜 격리수준이 필요한가

- 여러 트랜잭션이 동시에 같은 행(row)에 접근하면 다음과 같은 이상 현상(anomaly)이 생길 수 있다.

| 현상 | 설명 |
|---|---|
| Dirty Read | 다른 트랜잭션이 **아직 커밋하지 않은** 데이터를 읽어버림. 그 트랜잭션이 롤백되면 존재한 적 없는 값을 읽은 셈이 됨 |
| Non-Repeatable Read | 한 트랜잭션 안에서 같은 행을 두 번 조회했는데, 그 사이 다른 트랜잭션이 값을 바꾸고 커밋해서 결과가 달라짐 |
| Phantom Read | 한 트랜잭션 안에서 같은 조건으로 두 번 조회했는데, 그 사이 다른 트랜잭션이 행을 **추가/삭제**해서 조회되는 행의 개수가 달라짐 |

- 이 세 현상을 얼마나 허용할지에 따라 격리수준이 4단계로 나뉜다. 아래로 갈수록 격리(안전성)는 강해지고, 동시성(성능)은 떨어진다.

| 격리수준 | Dirty Read | Non-Repeatable Read | Phantom Read | 비고 |
|---|---|---|---|---|
| READ UNCOMMITTED | 발생 | 발생 | 발생 | 실무에서 거의 안 씀 |
| READ COMMITTED | 방지 | 발생 | 발생 | Oracle, PostgreSQL 기본값 |
| **REPEATABLE READ** | 방지 | 방지 | (InnoDB는 갭락으로 대부분 방지) | **MySQL(InnoDB) 기본값** |
| SERIALIZABLE | 방지 | 방지 | 방지 | 사실상 트랜잭션을 순차 실행하는 것과 동일. 가장 느림 |

~~~sql
-- 현재 세션의 격리수준 확인/변경
SELECT @@transaction_isolation;
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
~~~

## MySQL(InnoDB)이 REPEATABLE READ에서도 Phantom Read를 웬만하면 막는 이유

- 표준 SQL 정의상으로는 REPEATABLE READ가 Phantom Read를 막아주지 않는데, InnoDB는 두 가지 메커니즘으로 이걸 실질적으로 막아준다.
    1. **MVCC (Multi-Version Concurrency Control)** — SELECT(일반 읽기)는 락을 걸지 않고, 트랜잭션이 시작된 시점의 스냅샷(undo log 기반)을 읽는다. 그래서 다른 트랜잭션이 중간에 뭘 추가/수정해도, 내 트랜잭션 안에서는 계속 같은 스냅샷을 보게 됨.
        - 읽기 자체는 락 없이 동작하므로 읽기 성능이 좋다 — "읽기는 쓰기를 블로킹하지 않고, 쓰기는 읽기를 블로킹하지 않는다."
    2. **갭 락(Gap Lock) / 넥스트 키 락(Next-Key Lock)** — `SELECT ... FOR UPDATE` 처럼 락을 거는 조회의 경우, 존재하는 행뿐 아니라 행과 행 "사이의 간격(gap)"까지 잠가서 그 범위에 새 행이 삽입되는 것 자체를 막는다.

## InnoDB 락의 종류

| 락 종류 | 잠그는 대상 | 예시 |
|---|---|---|
| 레코드 락 (Record Lock) | 인덱스에 존재하는 특정 레코드 하나 | `id = 10` 조건으로 `FOR UPDATE` |
| 갭 락 (Gap Lock) | 레코드와 레코드 "사이"의 빈 공간 | `id BETWEEN 10 AND 20` 범위에 새 행 INSERT 방지 |
| 넥스트 키 락 (Next-Key Lock) | 레코드 락 + 그 직전 갭 락을 합친 것 (InnoDB의 기본 락 방식) | REPEATABLE READ에서 범위 조건 조회 시 |

- `mysql_index.md`와 연결되는 부분: **락은 인덱스를 기준으로 걸린다.** 조건절에 걸리는 컬럼에 인덱스가 없으면, MySQL은 어쩔 수 없이 스캔하는 모든 행(사실상 테이블 전체)에 락을 걸게 되어 동시성이 크게 떨어진다. "인덱스 없는 UPDATE/DELETE가 위험한" 진짜 이유가 여기 있다 — 느린 것뿐 아니라, 락 범위 자체가 넓어져서 다른 트랜잭션들을 오래 기다리게 만듦.

## 데드락 (Deadlock)

~~~sql
-- 트랜잭션 A
UPDATE accounts SET balance = balance - 100 WHERE id = 1; -- id=1 락 획득
-- (여기서 트랜잭션 B가 끼어듦)
UPDATE accounts SET balance = balance + 100 WHERE id = 2; -- id=2 락을 기다림 (B가 갖고 있음)

-- 트랜잭션 B (A와 동시에)
UPDATE accounts SET balance = balance - 50 WHERE id = 2; -- id=2 락 획득
UPDATE accounts SET balance = balance + 50 WHERE id = 1;  -- id=1 락을 기다림 (A가 갖고 있음)
~~~

- A는 B가 가진 락을, B는 A가 가진 락을 서로 기다리며 영원히 대기 → 데드락. InnoDB는 이를 감지해서 둘 중 하나(대개 되돌릴 비용이 더 적은 쪽)를 강제로 롤백시켜 에러를 던진다.
- 예방법: **여러 테이블/행을 건드릴 때는 항상 같은 순서로 접근**하도록 애플리케이션 코드를 짜는 것이 가장 기본적인 예방책. (위 예제에서 A, B 둘 다 "id 오름차순"으로 락을 걸었다면 데드락이 발생하지 않았을 것)

## 실무에서 격리수준을 고려한 판단 기준

- 대부분의 웹 서비스: 기본값(REPEATABLE READ) 그대로 두고, 정말 필요한 특정 쿼리에만 `SELECT ... FOR UPDATE` 나 낙관적 잠금(mongodb_study_chap07.md에서 다룬 개념과 동일한 원리)을 적용하는 것이 일반적.
- 격리수준을 낮추는(READ COMMITTED로 내리는) 경우: 갭 락으로 인한 동시성 저하가 심할 때, 애플리케이션 레벨에서 이미 동시성 제어를 하고 있을 때.
- 격리수준을 SERIALIZABLE로 올리는 경우: 금융/정산처럼 절대 이상 현상이 있으면 안 되는 특수한 로직에 국한 — 성능 저하가 크므로 전체 트랜잭션에 걸지 않고 최소 범위로.

---

## 다음 학습 주제
- [mysql_index.md](./mysql_index.md) — 락 범위가 왜 인덱스에 좌우되는지 복습
- MVCC의 내부 구조 (undo log, read view) — "스냅샷을 어떻게 유지하는지"를 더 깊이
- 실행계획(EXPLAIN) 읽는 법 — 쿼리가 어떤 락 전략(레인지 스캔 등)을 타는지 실제로 확인하는 방법
- 분산 트랜잭션 / Saga 패턴 — MSA 환경에서는 이 문서의 "트랜잭션"이 하나의 DB 안에서 끝나지 않는 경우가 많아짐
