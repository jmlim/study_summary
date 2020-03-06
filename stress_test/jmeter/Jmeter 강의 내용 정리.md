
> 출처 : 인프런 백기선님 강의 : 더 자바 코드를 테스트 하는 다양한 방법
>
> https://www.inflearn.com/course/the-java-application-test

# 성능 테스트 관련
## 1. JMeter 소개
 - https://jmeter.apache.org/

### 성능 측정 및 부하 (load) 테스트 기능을 제공하는 오픈 소스 자바 애플리케이션.

#### 다양한 형태의 애플리케이션 테스트 지원
- 웹 - HTTP, HTTPS
- SOAP / REST 웹 서비스
- FTP
- 데이터베이스 (JDBC 사용)
- Mail (SMTP, POP3, IMAP)
- ...

#### CLI 지원
- CI 또는 CD 툴과 연동할 때 편리함.
- UI 사용하는 것보다 메모리 등 시스템 리소스를 적게 사용.

#### 주요 개념
- Thread Group: 한 쓰레드 당 유저 한명 
  - 몇명의 유저가 동시에 요청을 보내는가? 
    - 만약 10명의 유저가 동시에 보내는 요청을 만들고 싶으면? Thread Group 을 10개로 지정하면 된다.
- Sampler: 어떤 유저가 해야 하는 액션
- Listener: 응답을 받았을 할 일 (리포팅, 검증, 그래프 그리기 등)
- Configuration: Sampler 또는 Listener가 사용할 설정 값 (쿠키, JDBC 커넥션 등)
- Assertion: 응답이 성공적인지 확인하는 방법 (응답 코드, 본문 내용 등)

#### 대체제:
- Gatling
    - https://gatling.io/
- nGrinder
    -  http://naver.github.io/ngrinder/

## 2. JMeter 설치
 - https://jmeter.apache.org/download_jmeter.cgi
    - binaries 압축 파일 받고 압축 파일 풀기. 원한다면 PATH에 bin 디렉토리를 추가.

 - bin/jmeter 실행하기
  - windows 
    - bin -> jmeter.bat 파일 실행
  - macOS
    - bin -> jmeter.sh 실행
      - ./jmeter

## 3. JMeter 사용하기

###  Thread Group 만들기
 - Plan 선택 후 오른쪽 버튼 클릭 -> Add -> Threads(Users) -> Thread Group 메뉴 선택
 - Number of Threads: 쓰레드 개수
 - Ramp-up period: 쓰레드 개수를 만드는데 소요할 시간
 - Loop Count: infinite 체크 하면 위에서 정한 쓰레드 개수로 계속 요청 보내기. 값을 입력하면 해당 쓰레드 개수 X 루프 개수 만큼 요청 보냄.

#### 10초에 10개의 요청을 한번만 보내고 싶을 때 아래와 같이 설정.

<img src="/stress_test/jmeter/img/10_thread.png" />

 - 만약 1초에 10개의 요청을 부하테스트가 종료될 때까지 보내고 싶다면? 
   - Loop Count 의 infinite 체크박스를 클릭 한 후 Ramp-up period(seconds) 값을 1초로 변경한다.

### Sampler 만들기 (요청 액션)
 - 여러 종류의 샘플러가 있지만 그 중에 우리가 사용할 샘플러는 HTTP Request 샘플러.
   - Thread Group 선택 후 오른쪽 버튼 클릭 -> Add -> Sampler -> Http Request 메뉴 선택
 - HTTP Sampler
   - 요청을 보낼 호스트, 포트, URI, 요청 본문 등을 설정
 - 여러 샘플러를 순차적으로 등록하는 것도 가능하다.

####  작성 예) 

<img src="/stress_test/jmeter/img/httpRequestSampler_example.png">


### Listener 만들기
 - 요청을 보낸 후 (위쪽 플레이 버튼) 결과를 보기 위한것이 Listener
   - Thread Group 선택 후 오른쪽 버튼 클릭 -> Add -> Listener -> ...
     - View Results Tree
     - View Results in Table
     - Summary Report
     - Aggregate Report
     - Response Time Graph
     - Graph Results
     - ...
 - 리스너들이 응답을 감시해서 각각의 해당하는 리포트를 만들어낸다.
 

 아래 리스너는 1초에 10개의 요청을 한번만 보낸 후 뽑은 결과이다.

#### View Results Tree 결과
<img src="/stress_test/jmeter/img/view_result_tree.png">
 
#### View Results in Table 결과
<img src="/stress_test/jmeter/img/view_results_in_table.png">

####  Summary Report 결과 
<img src="/stress_test/jmeter/img/summary_report.png">

 - summary report 를 보면 평균적으로 448ms (0.4초)의 응답시간이 걸렸고, 가장 빠른응답은 15ms, 가장 늦은 응답은 1075ms가 걸린것을 확인할 수 있다.
 - 그리고 초당 9.3개를 처리한 것으로 확인된다.

> 하지만 정말로 어플리케이션의 한계와 정확한 수치를 알기 위해선 예제의 10개가 아닌 정말 많은 데이터를 보내야한다. (당연한거)

#### Aggregate Report 결과
<img src="/stress_test/jmeter/img/aggregate_report.png">

- summary report 와 비슷
- median은 중간 수치값
    - 만약 요청이 10개가 왔다면 5개는 333ms과 응답시간이 같거나 적게 걸린것이고 5개는 응답시간이 333ms 보다 오래 걸린것.
- 90% Line : 90% 에 해당하는 요청이 얼마만에 처리 되었는가를 보여줌
    - 해당 캡쳐화면에선 1056ms
- 95% Line : 95% 에 해당하는 요청이 얼마만에 처리 되었는가를 보여줌
    - 해당 캡쳐화면에선 1056ms
- Average, min, max, throught는 summary report 와 같음

#### Response Time Graph 보기
  - 기존 쓰레드 그룹에 Loop Count 의 infinite 체크박스를 클릭 
  - Graph settings 의 interval (ms) 값을 조정 후 (여기서는 1000ms로 주었음) 상단 Play 버튼으로 부하 실행
    - 1초간각으로 응답시간의 수치를 그래프로 볼 수 있음.
    - 주의 
      - settings 탭을 한번 다녀와야 그래프가 갱신됨 (..)

<img src="/stress_test/jmeter/img/response_time_graph.png">


### Assertion 만들기
 - 응답결과가 어떻게 오는지 확인 후 판단하여 에러를 발생시키고 싶을 때 사용.
    -  Thread Group 선택 후 오른쪽 버튼 클릭 -> Add -> Assertion -> ...
 - 응답 코드 확인 ( Response Assertion 선택 )
   - 응답코드 200이 왔을 때만 성공으로 판단하고 싶을 때 (ex: 201 안됨..)
   - 아래같이 설정하면 200이 아닐경우 에러가 발생함.

<img src="/stress_test/jmeter/img/response_assertion.png">

 - 응답 본문 확인 (Json 으로 가정하고 JSON Assertion 선택)
    - 캡쳐 화면에서는 결과로 받은 json의 name 값이 Spring이 아닐 경우 결과가 녹색불이 아닌 빨간불이 나오게 됨.

<img src="/stress_test/jmeter/img/json_assertion_spring.png">

<img src="/stress_test/jmeter/img/json_assertion_spring_test.png">

### CLI 사용하기
 - gui 사용 시 요청도 오래 걸리고 요청을 쏘는 PC 자체에 상당한 부하가 발생.
 - jmeter -n -t 설정 파일 -l 리포트 파일
   - -n : UI를 사용하지 않음.
   - -t : 설정파일 위치 지정
   - -l : 리포트 파일
 - 샘플로 작성한 파일에서 Listener 중 Aggregate Report 만 남기고 삭제 후 확인하기.

#### 실행결과

<img src="/stress_test/jmeter/img/cli_aggregate_report.png"> 

- 첫번째줄 기준으로 설명
    -  10초동안 9648개의 요청이 간것.  
    -  초당 평균적으로 981.4 개의 요청을 처리
    -  평균 9ms
    -  제일 적게 걸린게 3ms
    -  제일 오래걸린게 309 ms
- 두번째줄은 30초동안 31055의 요청이 간것... 
    - 나머지는 생략.

중간에 = 은 + 의 결과값을 합친 것.

## ETC 
웹브라우저에서 사용자가 클릭하는 액션을 녹화를 해서 jmeter 설정파일(.jmx)로 떨군 후에 jmeter 에서 읽어서 편집을 하여 사용할 수도 있다.
 - blaze meter chrome plugin 사용.
    - https://chrome.google.com/webstore/detail/blazemeter-the-continuous/mbopgmdnpcbohhpnfglgohlbhfongabi
    - 가입해야 jmx 파일 떨굴 수 있음..