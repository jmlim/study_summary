
### Mac OS 에서 python3를 설치하는 방법은 아래와 같다.
~~~
brew update
brew install python3
~~~

#### 이렇게하면 python3 가 설치 완료되나 간혹 이렇게해도 pip3 가 설치 안되는 경우가 있다.
이럴땐.. 아래 명령어 실행
~~~
brew postinstall python3
~~~

old version의 brew 를 사용하여 install 할 경우, brew install python3 와 brew postinstall python3 를 모두 실행해야 한다.


출처 : https://blog.naver.com/PostView.naver?blogId=writer0713&logNo=221483661952