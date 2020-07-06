## homebrew 를 통한 rabbitmq 설치
### Homebrew 의 패키지 업데이트
~~~
brew update
~~~

### rabbitmq install
~~~
brew install rabbitmq
~~~ 

- RabbitMQ 서버는 /usr/ local/ sbin에 설치됨. 


### .bash_profile or .profile or .bashrc
- PATH에 자동으로 추가되지 않으므로 아래와 같이 추가한다.
~~~
export PATH=$PATH:/usr/local/sbin
~~~ 
 > 모든 스크립트는 사용자 계정으로 실행된다. sudo는 필요 X

### 실행
~~~
brew services start rabbitmq
~~~

### 웹 콘솔 접근 (기본 관리자 계정)
 - http://localhost:15672/
 - id: guest
 - pw: guest 