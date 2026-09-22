### 1. openjdk-devel 설치
~~~
sudo yum install java-1.8.0-openjdk-devel
~~~

### 2. GIT 설치 및 spring boot + gradle project clone 후 실행권한 추가.
~~~
yum install git
mkdir ~/app
cd ~/app
git clone https://github.com/jmlim/pebbletemplate-example.git
cd pebbletemplate-example
chmod +x ./gradlew
~~~

### 3. 배포 스크립트 생성.
~~~
#!/bin/bash

REPOSITORY=/root/app
PROJECT_NAME=pebbletemplate-example

cd $REPOSITORY/$PROJECT_NAME/

echo "> Git Pull"

git pull

echo "> 프로젝트 Build 시작"

./gradlew build

echo "> Build 파일 복사"

cp ./build/libs/*.jar $REPOSITORY/

echo "> 현재 구동중인 애플리케이션 pid 확인"

CURRENT_PID=$(pgrep -f ${PROJECT_NAME}*.jar)

echo "현재 구동중인 애플리케이션 pid: $CURRENT_PID"

if [ -z $CURRENT_PID ]; then
    echo "> 현재 구동중인 애플리케이션이 없으므로 종료하지 않습니다."
else
    echo "> kill -15 $CURRENT_PID"
    kill -15 $CURRENT_PID
    sleep 5
fi

echo "> 새 어플리케이션 배포"

JAR_NAME=$(ls -tr $REPOSITORY/ | grep *.jar | tail -n 1)

echo "> JAR Name: $JAR_NAME"

nohup java -jar $REPOSITORY/$JAR_NAME 2>&1 &
~~~

### 4. 권한추가 후 실행
~~~
# chmod +x ./deploy.sh
# ./deploy.sh
~~~

### 5. 프로세스 확인
~~~
[root@Ansible-Server ~]# ps -ef | grep pebble
root      4120     1  2 11:27 pts/0    00:00:11 java -jar /root/app/pebbletemplate-example-0.0.1-SNAPSHOT.jar

~~~

### 6. log 확인
~~~
[root@Ansible-Server pebbletemplate-example]# tail -f nohup.out
2020-02-15 11:28:02.903  INFO 4120 --- [           main] o.apache.catalina.core.StandardService   : Starting service [Tomcat]
2020-02-15 11:28:02.903  INFO 4120 --- [           main] org.apache.catalina.core.StandardEngine  : Starting Servlet engine: [Apache Tomcat/9.0.29]
2020-02-15 11:28:03.087  INFO 4120 --- [           main] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring embedded WebApplicationContext
2020-02-15 11:28:03.088  INFO 4120 --- [           main] o.s.web.context.ContextLoader            : Root WebApplicationContext: initialization completed in 3765 ms
2020-02-15 11:28:04.889  INFO 4120 --- [           main] o.s.s.concurrent.ThreadPoolTaskExecutor  : Initializing ExecutorService 'applicationTaskExecutor'
2020-02-15 11:28:05.780  INFO 4120 --- [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port(s): 8080 (http) with context path ''
2020-02-15 11:28:05.785  INFO 4120 --- [           main] i.j.s.pebbletemplate.Application         : Started Application in 7.877 seconds (JVM running for 9.125)
2020-02-15 11:28:49.893  INFO 4120 --- [nio-8080-exec-1] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring DispatcherServlet 'dispatcherServlet'
2020-02-15 11:28:49.893  INFO 4120 --- [nio-8080-exec-1] o.s.web.servlet.DispatcherServlet        : Initializing Servlet 'dispatcherServlet'
2020-02-15 11:28:49.900  INFO 4120 --- [nio-8080-exec-1] o.s.web.servlet.DispatcherServlet        : Completed initialization in 7 ms
~~~

### 이 방식의 한계
 - `nohup java -jar`로 띄운 프로세스는 서버가 재부팅되면 다시 안 뜬다. `kill -15` 후 배포 스크립트가 실패하면 서비스가 완전히 내려간 채로 남을 수도 있음(무중단 배포가 아님).
 - 로그가 `nohup.out` 하나에 계속 쌓여서 로그 로테이션이 안 되면 디스크가 찬다.
 - 아래 두 가지가 지금 시점에서 더 나은 대안.

### 대안 1) systemd 서비스로 등록하기
서버 재시작 시 자동 기동, 프로세스 다운 시 자동 재시작(`Restart=always`)을 OS 레벨에서 보장받을 수 있다.

~~~ini
# /etc/systemd/system/pebbletemplate.service
[Unit]
Description=pebbletemplate-example Spring Boot Application
After=network.target

[Service]
User=appuser
ExecStart=/usr/bin/java -jar /root/app/pebbletemplate-example.jar
SuccessExitStatus=143
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
~~~
~~~
systemctl daemon-reload
systemctl enable --now pebbletemplate
systemctl status pebbletemplate
journalctl -u pebbletemplate -f   # nohup.out 대신 journalctl 로 로그 확인
~~~

### 대안 2) 컨테이너화 (요즘 기준으로는 이 방법을 우선 고려)
`git pull` → `gradlew build` → `kill -15` 로 직접 서버에 배포하는 방식은 서버 환경(JDK 버전 등)에 종속적이라는 문제도 있음. Dockerfile로 감싸면 이 문제가 사라짐.

~~~dockerfile
FROM eclipse-temurin:17-jre
COPY build/libs/*.jar app.jar
ENTRYPOINT ["java", "-jar", "/app.jar"]
~~~
~~~
docker build -t pebbletemplate-example .
docker run -d -p 8080:8080 --restart unless-stopped --name pebbletemplate pebbletemplate-example
~~~
 - `--restart unless-stopped` 옵션 하나로 systemd 없이도 재시작 정책을 확보할 수 있고, CI(GitHub Actions 등)에서 이미지를 빌드해 레지스트리에 푸시 → 서버는 `docker pull` + `docker run`만 하는 구조로 넘어가면 "빌드는 서버에서 하지 않는다"는 원칙도 지킬 수 있음.
 - 더 나아가면 Kubernetes Deployment로 옮겨서 롤링 업데이트(무중단 배포)까지 자동화 가능 — 지금 이 문서의 셸 스크립트가 손으로 하던 일(구 프로세스 종료 → 새 프로세스 기동)을 오케스트레이터가 대신 해주는 셈.

### 배포스크립트 참고자료
 - 스프링 부트와 AWS로 혼자 구현하는 웹 서비스

---

## 다음 학습 주제
- Docker 멀티 스테이지 빌드 — 위 Dockerfile은 빌드 결과물(jar)이 이미 있다고 가정했는데, 빌드 자체도 컨테이너 안에서 하려면 멀티스테이지가 필요
- GitHub Actions로 CI/CD 파이프라인 구성 — 블로그의 Jenkins pipeline 글(EB 배포)을 최신 스택으로 다시 써보기
- 무중단 배포 전략(Blue-Green, Rolling) — `kill -15` + `nohup`으로 하던 배포가 사용자 요청을 순간적으로 끊는 이유와, 이를 막는 방법
