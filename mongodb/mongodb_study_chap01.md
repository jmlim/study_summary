### 몽고디비의 특징 및 기능

- MongoDB는 database > collections > documents 구조로 document는 BSON(Binary JSON)으로 되어있다.
- 스키마가 없음.
   - 먼저, 데이터베이스가 아닌 애플리케이션이 데이터 구조를 정한다는 것이다. 이것은 데이터의 구조가 빈번히 변경되는 개발 초기 단계에서 개발 속도를 단축시켜 준다.
   - 더 중요한 것으로는 스키마가 없는 데이터 모델을 통해 가변적인 속성을 갖는 데이터를 표현할 수 있다는 것이다.  예를 들어, 전자상거래 상품 카탈로그를 만든다고 해보자. 하나의 상품이 어떤 속성을 갖게 될지 미리 알 수 없으므로 애플리케이션에서는 이러한 가변적인 속성을 처리할 수 있어야 한다. 고정된 스키마를 갖는 데이터베이스에서 이 문제를 해결하기 위한 전통적인 방법은 개체 - 속성 - 값 패턴을 이용하는 것이다.
- 인덱스
  - B-Tree 로 구현되어 있음.
  - primary key는 자동으로 인덱스.
  - MongoDB에서는 한 컬렉션에 64개까지 세컨더리 인덱스를 만들 수 있음.
    - 오름차순, 내림차순, 고유(unique), 복합 키(compound-key), 해시, 텍스트, 심지어 지리공간적 인덱스와 같이 관계 데이터베이스 시스템에서 볼 수 있는 모든 인덱스가 가능
- 복제
    - 몽고디비는 복제세트(replica set) 라고 부르는 구성을 통해 데이터베이스 복제 기능을 제공.
    - 서버와 네트워크 장애가 발생할 경우를 대비해 중복성과 장애조치 자동화를 위해 데이터를 여러대의 서버에 분산.
    - 하나의 노드는 primary node 로 존재하며 하나 또는 그 이상의 세컨더리 노드가 존재. 세컨더리 노드는 읽기만 가능.
 - 속도와 내구성.
    - MongoDB에서 내구성에 대한 접근 방식을 이해하기 위해서는 먼저 몇 가지 아이디어를 고려해 봐야 함. 데이터베이스 시스템에서는 쓰기 속도와 내구성 사이에 역관계가 존재한다.
    - 쓰기 속도는 미리 정해진 시간 내에 데이터베이스가 얼마나 많은 수의 삽입, 수정, 삭제 명령을 처리할 수 있는가를 뜻한다.
    - 내구성(durability)은 이 쓰기 연산이 디스크에 제대로 이루어졌다는 것을 확신할 수 있는 정도를 뜻한다.
    - 항로를 저장하는 애플리케이션 같은 경우 데이터를 손실하는 위험을 감수하더라도 데이터를 빠르게 기록하는 것이 더 낫다.
        - 여기서 문제는 마그네틱 하드디스크에 대한 쓰기 연산이 램에 쓰는 것보다 열 배 이상으로 느리다는 것.. 멤캐시디(Memcached) 같은 데이터베이스에서는 쓰기가 램에 대해서만 이루어져 속도는 매우 빠르지만 전원이 꺼지면 사라져 버린다. 반면에 디스크에만 쓰기를 하는 데이터베이스는 속도가 너무 느리기 때문에 거의 없다. 따라서 데이터베이스를 설계할 때 속도와 내구성 사이에서 최적의 균형을 이루기 위해 포기할 것은 과감하게 포기해야 한다.
    - MongoDB의 경우에는 쓰기 시맨틱스(Write semantics)와 저널링(journaling)을 통해 속도와 내구성 사이에서 타협을 이룰 수 있다.
        - 저널링은 MongoDB v2.0에서 기본적으로 활성화되어 있다. 2012년 11월 이후에 배포된 MongoDB 드라이버에서는 비록 설정이 필요하긴 하지만, 사용자에게 응답을 주기 전에 쓰기를 램에 안전하게 쓰는 것을 보장해준다. MongoDB를 fire-and-forgot(명령하고 잊기)모드로 설정하면 확인을 기다릴 필요 없이 서버에 write 작업을 전송할 수 있다. 또한 commit이 되었는지 확인하기 전에 다수의 복제 서버들에 대한 write를 보장하도록 설정할 수도 있다.
  - 확장
    - 수평적 확장이 용이하도록 설계. 샤딩으로 알려진 범위 기반 파티션 메커니즘을 통해 데이터를 여러 노드에 걸쳐 분산하는 것을 자동으로 관리.

### 팁과 한계
 - 64비트 시스템에서 실행되어야 함.
 - 메모리 스와핑이 발생하는 데이터에 대해선 자주 디스크 접근을 요구.
    - 성능이 떨어짐.
    - CPU & Memory는 가능하면 높은 사양으로 구성할 것
 - 데이터 구조가 크기 관점에서는 그렇게 효율적이지 않음.
 - SQL 만큼 친숙하거나 쉽지 않다.
 - 대규모의 클러스터를 운영하기 위한 유지비용이 발생.

### Primary Key (ObjectId)
 > 3장 드라이버 작동원리에서 언급
 - ObjectId는 12bytes의 16진수 값으로서, 각 document의 유일성을 보장한다. 첫 4bytes 는 현재 timestamp, 다음 3bytes는 machine id, 다음 2bytes는 MongoDB 서버의 프로세스id, 마지막 3bytes는 순차번호이다.