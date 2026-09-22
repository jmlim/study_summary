 > 자료 출처
>  - GoF 디자인 패턴 / 헤드퍼스트 디자인 패턴(부록 "그 밖의 패턴들") + 이펙티브 자바 Item 2

## 빌더 패턴 (Builder Pattern)

- 정의: 복잡한 객체를 생성하는 절차(construction)를, 그 객체의 표현(representation) 방법과 분리하는 패턴. 같은 생성 절차로도 서로 다른 표현 결과를 만들어낼 수 있게 해준다.
- 실무에서 가장 많이 마주치는 형태는 GoF의 원조 정의보다 훨씬 단순한 **"생성자 매개변수가 너무 많을 때 쓰는 플루언트(fluent) 빌더"** 다. 이 문서는 이 실용적인 형태 위주로 정리.

### 문제 상황 — 텔레스코핑 생성자(Telescoping Constructor)

~~~java
public class Pizza {
    private final int size;
    private final boolean cheese;
    private final boolean pepperoni;
    private final boolean bacon;

    // 매개변수 조합마다 생성자를 늘려가는 방식 -> 조합이 늘어날수록 폭발적으로 증가
    public Pizza(int size) { this(size, false, false, false); }
    public Pizza(int size, boolean cheese) { this(size, cheese, false, false); }
    public Pizza(int size, boolean cheese, boolean pepperoni) { this(size, cheese, pepperoni, false); }
    public Pizza(int size, boolean cheese, boolean pepperoni, boolean bacon) {
        this.size = size; this.cheese = cheese; this.pepperoni = pepperoni; this.bacon = bacon;
    }
}

// 호출부에서 뭐가 뭔지 알아보기 힘듦 - boolean 세 개의 순서를 외워야 함
Pizza pizza = new Pizza(12, true, false, true);
~~~

- 매개변수가 몇 개 안 될 땐 괜찮지만, 늘어날수록 호출부 가독성이 떨어지고, 어떤 필드가 필수(size)고 어떤 게 선택(cheese, pepperoni...)인지도 생성자만 봐서는 알기 어렵다.
    - JavaBeans 방식(기본 생성자 + setter)으로 바꾸면 가독성은 좋아지지만, 이번엔 **객체가 완전히 생성되기 전(setter 호출 중간)의 불안정한 상태**가 존재하게 되고, 불변(immutable) 객체를 만들 수 없다는 문제가 생긴다.

### 해결 — 빌더 패턴

~~~java
public class Pizza {
    private final int size;       // 필수
    private final boolean cheese;
    private final boolean pepperoni;
    private final boolean bacon;

    private Pizza(Builder builder) { // 생성자는 private - 오직 Builder를 통해서만 생성 가능
        this.size = builder.size;
        this.cheese = builder.cheese;
        this.pepperoni = builder.pepperoni;
        this.bacon = builder.bacon;
    }

    public static class Builder {
        private final int size;   // 필수값은 Builder 생성자에서 강제
        private boolean cheese = false;   // 선택값은 기본값을 갖고 시작
        private boolean pepperoni = false;
        private boolean bacon = false;

        public Builder(int size) {
            this.size = size;
        }

        public Builder cheese(boolean value) { this.cheese = value; return this; }       // 자기 자신(this) 반환
        public Builder pepperoni(boolean value) { this.pepperoni = value; return this; } // -> 메서드 체이닝 가능
        public Builder bacon(boolean value) { this.bacon = value; return this; }

        public Pizza build() {
            return new Pizza(this); // 최종적으로 불변 객체 생성
        }
    }
}

// 호출부 - 어떤 값이 무슨 옵션인지 이름으로 바로 읽힘, size는 강제로 넣어야 함
Pizza pizza = new Pizza.Builder(12)
        .cheese(true)
        .bacon(true)
        .build();
~~~

- 얻는 이점
    1. **가독성** — 메서드 이름 자체가 어떤 값을 설정하는지 알려줌(자가 설명적 API). 순서를 외울 필요 없음.
    2. **불변성** — `Pizza`의 모든 필드는 `final`이고, `build()`가 호출되기 전까지는 `Pizza` 인스턴스 자체가 존재하지 않으므로 "반쯤 생성된 상태"가 없다.
    3. **필수/선택 구분** — 필수값(size)은 `Builder` 생성자 인자로 강제하고, 선택값은 체이닝 메서드로만 설정 가능하게 해서 실수로 빠뜨릴 일이 줄어듦.
    4. **유효성 검증 지점 확보** — `build()` 안에서 "cheese와 pepperoni를 동시에 못 넣는다" 같은 조합 규칙을 검증할 수 있음.

### 실무 — Lombok `@Builder`

매번 위 보일러플레이트를 손으로 짜는 대신, 실무에서는 대부분 Lombok이 대신 만들어주게 한다.

~~~java
@Builder
public class Pizza {
    private final int size;
    private final boolean cheese;
    private final boolean pepperoni;
    private final boolean bacon;
}

// 사용법은 동일
Pizza pizza = Pizza.builder()
        .size(12)
        .cheese(true)
        .bacon(true)
        .build();
~~~

- 단, Lombok `@Builder`는 필수/선택을 구분해주지 않는다(전부 선택처럼 보임) — "필수값을 빠뜨리면 컴파일 에러가 나게" 만들고 싶다면 위의 수동 구현(생성자 인자로 필수값 강제)이 여전히 더 안전하다.
- Spring/JPA 환경에서 흔히 보는 조합: `@Getter @Builder @AllArgsConstructor` 로 DTO/엔티티를 불변에 가깝게 만들고, `@NoArgsConstructor(access = AccessLevel.PROTECTED)` 로 JPA가 요구하는 기본 생성자만 열어주는 패턴.

### 빌더 패턴 vs 팩토리 패턴

| | 빌더 패턴 | 팩토리 패턴 |
|---|---|---|
| 목적 | **하나의 복잡한 객체**를 단계별로 조립 | 조건에 맞는 **여러 타입 중 하나**를 생성 |
| 매개변수 | 많고 선택적인 경우가 많음 | 보통 타입을 결정할 몇 개의 값 |
| 결과물 | 항상 같은 클래스, 내부 값 조합이 다름 | 서로 다른 구상 클래스가 나올 수 있음 |

- 두 패턴은 종종 함께 쓰인다 — 팩토리가 어떤 종류의 `Builder`를 반환할지 결정하고, 그 `Builder`가 세부 값을 조립하는 조합도 흔하다.

---

## 다음 학습 주제
- [팩토리 패턴](../factory/factory.md) — 이번엔 "무엇을 만들지 결정"에 초점을 맞춘 패턴과 비교해서 정리
- Lombok `@Builder`, `@Value`, `@With` — 불변 객체를 실무에서 더 편하게 다루는 어노테이션들
- Effective Java Item 1~3 — 정적 팩토리 메서드, 빌더, private 생성자+enum 싱글턴을 묶어서 "객체 생성"을 주제로 다시 정리 ([싱글턴 패턴](../singleton/singleton.md)과 연결)
