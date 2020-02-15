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

... 작성중 ...

### 배포스크립트 참고자료
 - 스프링 부트와 AWS로 혼자 구현하는 웹 서비스
