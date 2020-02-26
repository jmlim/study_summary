## docker로 mysql 설치 (한글 깨짐 옵션 추가)

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
