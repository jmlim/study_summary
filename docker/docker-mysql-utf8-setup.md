## docker로 mysql 설치 (한글 깨짐 옵션 추가)

> **[2026년 추가]** 예제의 `mysql:5.6.35` 이미지는 참고용으로만 볼 것 — **MySQL 5.6은 2021년 2월에 이미 공식 지원이 종료(EOL)**됐다. 새로 띄운다면 8.0 계열 최신 태그를 쓸 것. 또한 `docker-compose.yml`의 `version: "2.2"` 키는 최신 Docker Compose(V2, `docker compose` 명령어 내장 버전)에서는 더 이상 필요 없고 무시된다 — 최신 compose 파일에서는 이 줄을 생략해도 된다.

### docker-compose.yml 생성
~~~
version: "2.2" # 기준 버전
services:
  app:
    image: mysql:5.6.35 # 사용할 이미지
    container_name: jmlim-mysql-5635-utf8 # 컨테이너 이름 설정
    ports:
      - "3002:3306" # 접근 포트 설정 (컨테이너 외부:컨테이너 내부)
    environment:
      MYSQL_ROOT_PASSWORD: "password"  # MYSQL 패스워드 설정 옵션
    command: # mysql utf-8 케릭터 셋 설정 명령어
      - --character-set-server=utf8mb4 
      - --collation-server=utf8mb4_unicode_ci
    volumes:
      - /Users/jmlim/datadir_utf8_5635:/var/lib/mysql # 디렉토리 마운트
~~~

### 실행 docker-compose up
 - 백그라운드로 실행 시 옵션 -d 붙이면 됨.
 - ex ) docker-compose up -d
 - 자세한건 옵션 참고

## 계정생성
 - jmlim이라는 사용자를 생성하고, 모든 권한을 부여한다.
 - 변경된 권한 적용

### 컨테이너 bash 쉘 접근
~~~
docker exec -it jmlim-mysql-5635-utf8 bash
~~~

### mysql 서버 접속
~~~
root@f3af78fa6428:/#mysql -u root -p

mysql>
~~~

### 계정생성
~~~
CREATE USER 'jmlim'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON *.* TO 'jmlim'@'%';
flush privileges;
quit
~~~
