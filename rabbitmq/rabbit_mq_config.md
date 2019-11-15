

# 로컬이 아닌 외부에서도 rabbitmq 접근 가능하도록 처리
 >  rabbitmq 는 macOS 에 설치하였고 버전은 3.7 기준임.
## ip 허용 처리.
config file 경로 - /usr/local/etc/rabbitmq/rabbitmq-env.conf

 - 해당 파일 열어서 NODE_IP_ADDRESS 127.0.0.1 로 되어있던 것 허용할 아이피로 변경. (전부 허용시 0.0.0.0)
~~~
CONFIG_FILE=/usr/local/etc/rabbitmq/rabbitmq
NODE_IP_ADDRESS=0.0.0.0
NODENAME=rabbit@localhost
RABBITMQ_LOG_BASE=/usr/local/var/log/rabbitmq
~~~

## 저장 후 macOS 에서 rabbitmq 재시작
~~~
brew services stop rabbitmq
brew services start rabbitmq
~~~

## rabbitmq 관리자 페이지 접근
### 1. http://localhost:15672/#/users 접근하여 계정 생성.
 <img src="/rabbitmq_img/rabbitmq-admin-adduser.png" width="700px" height="700px"/>

### 2. 퍼미션 허용.
 <img src="/rabbitmq_img/rabbitmq-admin-set-permission.png" width="700px" height="700px"/>

### 3. 외부에서 접근되는지 테스트.


 -  참고자료
    -  https://stackoverflow.com/questions/10608950/how-do-i-stop-the-rabbitmq-server-on-localhost
