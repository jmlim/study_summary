### AMQP

- 프로그래밍에서 MQ는 프로세스 또는 프로그램 인스턴스가 데이터를 서로 교환할 때 사용하는 방법을 말한다. 
- 이러한 MQ를 오픈 소스에 기반한 표준 프로토콜이 AMQP(Advanced Message Queuing Protocol)이다. 
- AMQP 자체가 프로토콜을 의미하기 때문에 이 프로토콜을 구현한 MQ제품들은 여러가지가 있으며 그 중 하나가 RabbitMQ이다.

### AMQP의 라우팅 모델은 Exchange와 Queue 그리고 Binding으로 구성된다. 
   <img src="/rabbitmq_img/rabbitmq-binding-img.png" />

- Exchange는 Publisher(Producer)로부터 수신한 메시지를 큐에 분배하는 라우터의 역할을 하며, Queue는 메시지를 메모리나 디스크에 저장했다가 Consumer에게 메시지를 전달하는 역할을 한다. Binding은 Exchange와 Queue의 관계를 정의한 것을 말한다.
- Exchange Type은 메시지를 어떠한 방법으로 라우팅할지 결정하는 일종의 알고리즘을 말하며 AMQP에서는 다음과 같이 Exchange Type을 정의하고 있다.

### Exchange Type
- Direct exchange
	- Exchange에 바인딩 된 Queue 중에서 메시지의 라우팅 키와 매핑되어 있는 Queue로 메시지를 전달한다. 
	- 1:1 관계로 Unicast 방식에 적합하며, 주로 라운드 로빈 방식으로 여러 workers(Consumer)간 task를 분리에 사용된다.
- Fanout exchange
	- 메시지의 라우팅 키를 무시하고 Exchange에 바인딩 된 모든 Queue에 메시지를 전달한다. 
	- 1:N 관계로 메시지를 브로드캐스트하는 용도로 사용된다.
- Topic exchange
	- Exchange에 바인딩 된 Queue 중에서 메시지의 라우팅 키가 패턴에 맞는 Queue에게 모두 메시지를 전달한다.
	- Multicast 방식에 적합하다.
- Headers exchange
	- 라우팅 키 대신 메시지 헤더에 여러 속성들을 더해 속성들이 매칭되는 큐에 메시지를 전달한다.

### RabbitMQ
RabbitMQ는 AMQP를 구현한 오픈 소스 메시지 브로커 소프트웨어로 Publisher(Producer)로부터 메시지를 받아 Consumer에게 라우트하는 것이 주된 역할이다. 이를 이용하면 작업 큐, 발행 및 구독, 라우팅, 주제, 원격 프로시저 호출 등의 모델을 구현할 수 있다.

### Rabbit MQ Exchange Type

- Direct Exchange	
    - (Empty string) and amq.direct
- Fanout Exchange	
    - anq.fanout
- Topic Exchange	
    - amq.topic
- Header Exchange	
    - amq.match(and amq.headers in RabbitMQ)

<img src="/rabbitmq_img/rabbitmq-tutorial-img.png" />

[출처] RabbitMQ와 Spring AMQP를 이용한 간단한 작업 큐 만들기 | 작성자 개발몬스터
- https://blog.naver.com/PostView.nhn?blogId=tmondev&logNo=220419853534&parentCategoryNo=&categoryNo=6&viewDate=&isShowPopularPosts=false&from=postView