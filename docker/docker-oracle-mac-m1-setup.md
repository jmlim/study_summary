## docker로 oracle 설치 (apple M1)

- 기본적으로, Apple Silicon(ARM 아키텍처를 사용해 애플이 설계한 프로세서)이 적용된 M1 맥북(M1 pro 포함)의 경우 oracle database 설치가 불가능하다.
- 따라서, M1 맥북 사용자라면 로컬이 아닌 외부에 ORACLE 데이터베이스를 구성하여 사용하는데,mac OS에서는 오라클DB를 바로 사용할 수 없어서 Docker를 통해 이용한다.
- 또한 Docker DeskTop은 무겁기 때문에 이를 대신하는 Colima는 간단한 CLI 환경에서 도커 컨테이너들을 실행 할 수 있는 오픈 소스 소프트웨어이다.


### Colima 설치
~~~
brew install colima
~~~

### Docker 설치
docker가 아직 설치되어 있지 않았다면 본 항목을 확인하며 설치하고, 기존에 이미 설치했다면 실행중인 Docker desktop을 종료만 하고 아래의 Colima 실행으로 넘어간다.
도커를 아직 설치 한 적이 없다면 도커 설치가 필요한데,

도커 데스크탑을 설치할 수도 있고, 도커 엔진만 설치해서 할 수도 있는데.
데스크탑을 설치를 원하면 아래의 링크에서 우측 Mac with Apple chip을 선택 해서 다운한다.

~~~
brew install --cask docker
~~~

참고로, m1 맥북은 Apple Silicon 칩셋으로
기존 Intel(x86-64 기반)에서 (ARM 64 기반)으로 변경되어,
설치 프로그램을 받을때 Intel 버전이 아닌 apple(Arm 64)를 받으면 된다.

### Colima 실행
~~~
colima start --memory 4 --arch x86_64
~~~
- Colima와 Docker를 모두 설치했다면 Colima를 x86_64 환경으로 창을 띄워준다.
- 정상적으로 가상 환경이 준비되면 docker 명령어들이 정상적으로 작동한다. (좀 오래 걸리니 기다리자)
- docker ps 명령어 실행 후 확인해본다.

### Oracle Database 11gR2 XE (11.2.0.2) 설치
~~~
docker search oracle-xe-11g
~~~
명령어를 통해 받을 수 있는 docker image를 확인한다.
저 중에 하나를 설치하면 된다.
- 설치 명령어
~~~
docker pull jaspeen/oracle-xe-11g
~~~

- 설치된 이미지 확인
~~~
docker images
~~~
- 서버 띄우기
~~~
docker run --name oracle -d -p 1521:1521 jaspeen/oracle-xe-11g
~~~

- 컨테이너 로그 확인
~~~
docker ps
명령어를 통해 컨테이너명을 확인한다.

docker logs -f 컨테이너명
확인한 컨테이너명을 입력하고 기다리다 보면,
~~~
- 연결 테스트
  - id: system, pw: oracle
~~~
docker exec -it 컨테이너명 sqlplus
~~~

### 계정생성
~~~
CREATE USER jmlim IDENTIFIED BY jmlimpass;
grant connect, resource, dba to jmlim;
commit ;
~~~

### 계정 확인
~~~
select * from all_users;
~~~

### 접근하기

### 설치 이후 실행 및 중지
- 실행
~~~
colima start --memory 4 --arch x86_64
docker start 컨테이너명
~~~

- 중지
~~~
colima stop
docker start 컨테이너명
~~~

### 출처
 - https://velog.io/@xangj0ng/M1-Oracle-DB-%EC%84%A4%EC%B9%98