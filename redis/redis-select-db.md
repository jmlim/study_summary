레디스 초보가 겪은 실수..?

## redis-cli 에서 데이터 조회시 나오지 않을 경우 확인해봐야할것.
대충 어떤 상황이냐면.. 스프링부트를 통해 레디스에 데이터 저장 후 redis-cli통해서 조회해 봤는데 나오지 않음.
~~~
redis-cli -h 레디스아이피 -p 포트(6379)
redis 레디스아이피:포트> get “키값”
... 결과 안나옴...
~~~
### 레디스 서버는 여러개의 데이터베이스를 가질 수 있다.
 - 기본 값은 16 임
 - DB 번호 0부터 15까지 16개의 데이터베이스를 가짐.
 - 레디스에서 데이터베이스는 서로 다른 키 공간이다.
     - 키 AAA는 데이터베이스 내에서는 유일하지만 다른 데이터베이스에는 또 존재할 수 있다.
     - 접속하면 기본으로 0번 데이터베이스로 접속.
        - 데이터베이스 선택은 select 문으로 한다.
            - select 5 는 5번 데이터베이스에 접속한다.
            - redis-cli 에서 무작정 데이터 조회 후 (ex : get "키값") 조회가 되지 않은 이유가 데이터베이스가 달라서 ...그랬던 것.
            - INFO 의 #keySpace에서 db(번호) 확인 후 select 디비번호 로 접근. 그 후에 키값 조회하니 정상적으로 됨.
 - 클러스터 모드에서는 데이터베이스가 하나만 존재한다.
~~~
redis-cli -h 레디스아이피 -p 포트(6379)
redis 레디스아이피:포트> get “키값”
... 결과 안나옴...
redis 레디스아이피:포트> INFO
.....
....
#Keyspace
db1:key=갯수, expires=0,avg_ttl=0
redis 레디스아이피:포트> select 1
redis 레디스아이피:포트[1]> get “키값”
결과가 나온다
~~~
### 출처:
 - http://redisgate.kr/redis/configuration/param_databases.php
 - http://redisgate.kr/redis/command/select.php