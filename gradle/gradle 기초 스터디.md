
> 그 동안 잘 모르고 쓰던거만 썼으나.. 학습하고 제대로 써보기.
> 정리는 내가 알아볼 수 있을 정도만 ..


> 출처 :열혈강의 그레이들 
 - https://www.youtube.com/watch?v=s-XZ5B15ZJ0&list=PL7mmuO705dG2pdxCYCCJeAgOeuQN1seZz&index=1

#### 빌드 수행 단계
 - 명령어 해석/수행
 - gradle 실행
 - script 초기화
 - project settings
 - task 실행
 - 결과 출력
 

그루비 - 리스트와 맵
 - 리스트(list)

~~~
 def id = ['grade', 'Groovy']
 id[1] = 'script'
~~~

- 맵
~~~
 def id = ['a': 'grade', 'b': 'Groovy']
 assert id['a'] == 'gradle'
~~~

그레이들의 스크립트 파일 구조
 - 처리문 영역
 - 스크립트 블록
 

~~~
//처리문
def id = 'gradle'

// 스크립트 블록
repositories {
	mavenCentral()
}

task idCheck << {
	def id = 'check'
	println 'id : ' + id
}
~~~

그레이들의 주요 스크립트 블록
 - repositories : 저장소 설정
 - dependencies : 의존 관계 설정
 - buildscript : 빌드 스크립트 클래스 패스 설정
 - initscript: 초기화 스크립트 설정
 - configurations: 환경 구성 설정
 - allprojects : 서브 프로젝트 포함 전체 프로젝트 설정
 - subprojects : 서브 프로젝트 설정
 - artifacts : 빌드 결과에 대한 설정
 
gradle dsl 부분 살펴보기.
 - https://docs.gradle.org/current/dsl/
 
그레이들의 변수
 - 지역 변수 : 선언된 부분에서의 영향력 있는 변수
 - 시스템 속성 : 시스템 관련 정보를 저장하는 변수

~~~
 // 시스템 확장 속성 예
 task hello {
	println System.properties['message']
 }
~~~

 > -D 옵션 또는 --system-prop 옵션 사용. -D<속성명>=<속성값>
 
 > ex) gradle -Dmessage=hello
 
 - 확장 속성 : 도메인 객체 확장 용도로 사용되는 변수

~~~
// 확장 속성 지정 방법
 ext {
	extPro1 = 'pro1'
	extPro2 = 'pro2'
 }

 // 사용 방법
 println '속성값 1: ' + ext.extPro1
 println '속성값 2: ' + ext.extPro2
~~~

 - 프로젝트 속성 : 프로젝트에서 사용되는 변수 (사용범위 -> 빌드 스크립트) 

* gradle.properties 
~~~
msg = Hi, Gradle!
~~~

* build.grade
~~~
task hello<<{
	println msg
}
~~~

- 결과 

~~~
$ gradle hello

> Configure project :
Hi, gradle!

> Task :hello UP-TO-DATE

BUILD SUCCESSFUL in 4s
~~~


 - 명령어 인수로 프로젝트 속성 지정 방법
 
|로드 우선순위|프로젝트 속성 지정 방법|속성값 지정|
|---|---|---|
|1|프로젝트 디렉터리의 gradle.properties 지정|동일한 속성명으로 지정될 경우 로드 우선순위가 늦은 것에 대하여 지정.|
|2|홈 디렉터리의 grade.properties 지정|동일한 속성명으로 지정될 경우 로드 우선순위가 늦은 것에 대하여 지정.|
|3|환경 변수 지정|동일한 속성명으로 지정될 경우 로드 우선순위가 늦은 것에 대하여 지정.|
|4|명령어 옵션 지정 (-D 옵션)|동일한 속성명으로 지정될 경우 로드 우선순위가 늦은 것에 대하여 지정.|
|5|명령어 옵션 지정 (-P 옵션)|동일한 속성명으로 지정될 경우 로드 우선순위가 늦은 것에 대하여 지정.|



### 그레이들의 테스크
 - 테스크의 기본.
~~~
task hello<<{
	println "Hello Gradle!"
}
~~~

- 위와 출력결과는 같음.

~~~ 
 // 출력할 문자열을 def 형으로 선언 및 클로저 정의
 def strMsg = {println = 'Hello Gradle!'}

 // hello 태스크
 task hello {}

 // leftShift()를 사용한 문자열 출력
 hello.leftShift(strMsg)
~~~


- 테스크의 기본
 - build.gradle 작성.
~~~
task gradleTask1<< {
	println 'This is Gradle Task One'
}

task gradleTask2 {
	println 'This is Gradle Task Two'
}
~~~

- 실행 
   - gradleTask2는 실행단계 이전의 설정단계
   - gradleTask1은 실행단계 
   - 그래서 순서가 바뀌어서 출력 (차이는 >> 가 있느냐 없느냐..) 

~~~
$ gradle gradleTask1 gradleTask2

> Configure project :
This is Gradle Task Two

> Task :gradleTask1
This is Gradle Task One

> Task :gradleTask2 UP-TO-DATE

Deprecated Gradle features were used in this build, making it incompatible with Gradle 5.0.
See https://docs.gradle.org/4.7/userguide/command_line_interface.html#sec:command_line_warnings

BUILD SUCCESSFUL in 4s
1 actionable task: 1 executed
~~~

- build.gradle 
~~~
task goodTask<< {
println description + 'This is Good!'
}
goodTask.description = 'Task Execution -> '
~~~

- 결과

~~~
$ gradle goodTask

> Task :goodTask
Task Execution -> This is Good!

Deprecated Gradle features were used in this build, making it incompatible with Gradle 5.0.
See https://docs.gradle.org/4.7/userguide/command_line_interface.html#sec:command_line_warnings

BUILD SUCCESSFUL in 4s
1 actionable task: 1 executed

~~~


- build.gradle 
~~~
badTask.description = 'Task Execution -> '
task badTask<< {
	println description + 'This is Bad!'
}
~~~


- 결과
~~~
$ gradle badTask

FAILURE: Build failed with an exception.

* Where:
Build file 'C:\dev\gradle_test\3_1\build.gradle' line: 1

* What went wrong:
A problem occurred evaluating root project '3_1'.
> Could not get unknown property 'badTask' for root project '3_1' of type org.gradle.api.Project.

* Try:
Run with --stacktrace option to get the stack trace. Run with --info or --debug option to get more log output. Run with --scan to get full insights.

* Get more help at https://help.gradle.org

BUILD FAILED in 4s

~~~

위와 같이 에러 발생하지 않도록 하게 하려면??
- 아래와 같이 하면 된다.

grade.build

~~~
task prevTask 
prevTask.description = ' <Task Execution>'

prevTask<< {
println description + 'This is Good!'
}
~~~

결과
 - 성공
~~~
$ gradle prevTask

> Task :prevTask
 <Task Execution>This is Good!

Deprecated Gradle features were used in this build, making it incompatible with Gradle 5.0.
See https://docs.gradle.org/4.7/userguide/command_line_interface.html#sec:command_line_warnings

BUILD SUCCESSFUL in 4s
1 actionable task: 1 executed

~~~

- 태스크를 활용한 다양한 실습 1
 - groovy 언어에 대한 다양한 기능 사용 가능.

~~~groovy
task exeTask1 << {
	String strOutput = 'Have a Good Day'
	println '1. String change: ' + strOutput.toUpperCase()
	println '2. String change: ' + strOutput.toLowerCase()
}

task exeTask2 << {
	10.times {println "$it"}
}
~~~

결과 
~~~
$ gradle exeTask1 exeTask2

> Task :exeTask1
1. String change: HAVE A GOOD DAY
2. String change: have a good day

> Task :exeTask2
0
1
2
3
4
5
6
7
8
9

Deprecated Gradle features were used in this build, making it incompatible with Gradle 5.0.
See https://docs.gradle.org/4.7/userguide/command_line_interface.html#sec:command_line_warnings

BUILD SUCCESSFUL in 4s
2 actionable tasks: 2 executed
~~~

- 테스크를 활용한 다양한 실습 2
~~~
// task 3개 반복해서 생성.
3.times {
	counter-> task "exeTask$counter" << {
		println "task counter: $counter"
	}
}

// task1 실행 시 exeTask0, exeTask2 가 먼저 실행되도록 함.(의존관계)
exeTask1.dependsOn exeTask0, exeTask2
~~~

결과 
~~~
$ gradle exeTask1

> Task :exeTask0
task counter: 0

> Task :exeTask2
task counter: 2

> Task :exeTask1
task counter: 1

Deprecated Gradle features were used in this build, making it incompatible with Gradle 5.0.
See https://docs.gradle.org/4.7/userguide/command_line_interface.html#sec:command_line_warnings

BUILD SUCCESSFUL in 4s
3 actionable tasks: 3 executed

~~~

- 테스크를 이용한 다양한 실습 3
~~~
// 이 방법보단
task(exeTask, description: "This is gradle description") << {
	println description
}

// 이 방법을 선호한다.
task exeTask(description: "This is gradle description") << {
	println description
}
~~~

- 테스크를 이용한 다양한 실습 4

~~~
//2
task exeTask << {
 println 'exeTask task'
}
//1
exeTask.doFirst {
	println '>>> exeTask doFirst'
}
//3
exeTask.doLast {
	println ">>>  exeTask doLast - END : $exeTask.name"
}
~~~

- 결과

~~~
$ gradle exeTask

> Task :exeTask
>>> exeTask doFirst
exeTask task
>>>  exeTask doLast - END : exeTask

Deprecated Gradle features were used in this build, making it incompatible with Gradle 5.0.
See https://docs.gradle.org/4.7/userguide/command_line_interface.html#sec:command_line_warnings

BUILD SUCCESSFUL in 4s
1 actionable task: 1 executed

~~~

- 태스크를 이용한 다양한 실습 5

~~~
 // ext: gradle 에서 기본적으로 제공하는 객체
task userInfo {
	ext.userName = "John"
	ext.userAge = "20"
	ext.userGen = "Man"
}

task exeTask << {
	println "Name : " + userInfo.userName
	println "Age : " + userInfo.userAge
	println "Gen : " + userInfo.userGen
}
~~~

- 결과

~~~
$ gradle exeTask

> Task :exeTask
Name : John
Age : 20
Gen : Man

Deprecated Gradle features were used in this build, making it incompatible with Gradle 5.0.
See https://docs.gradle.org/4.7/userguide/command_line_interface.html#sec:command_line_warnings

BUILD SUCCESSFUL in 4s
1 actionable task: 1 executed

~~~

- 테스크를 이용한 다양한 실습 6

~~~
// default 지정: 명령어 gradle 만 수행해도 defaultTasks 가 실행된다.
defaultTasks 'exeTask1', 'exeTask2', 'exeTask3'

task exeTask1 << {
	println 'This is exeTask1 Project'
}

task exeTask2 << {
	println 'This is exeTask2 Project'
}

task exeTask3 << {
	println 'This is exeTask3 Project'
}
~~~

- 결과
~~~
$ gradle

> Task :exeTask1
This is exeTask1 Project

> Task :exeTask2
This is exeTask2 Project

> Task :exeTask3
This is exeTask3 Project

Deprecated Gradle features were used in this build, making it incompatible with Gradle 5.0.
See https://docs.gradle.org/4.7/userguide/command_line_interface.html#sec:command_line_warnings

BUILD SUCCESSFUL in 4s
3 actionable tasks: 3 executed

~~~

- 테스크를 이용한 다양한 실습 7
 - map 으로 테스크를 지정하여 each 를 통해 task를 만든 후 value 값 출력

~~~
def confMap = ["imgConf": "img.freelec.co.kr", "smsConf":"sms.freelec.co.kr"]

confMap.each{
	svDomain, domainAddr -> task "exeTask${svDomain}" << {
								println domainAddr
							}
}
~~~

결과 

~~~
$ gradle exeTaskimgConf

> Task :exeTaskimgConf
img.freelec.co.kr

Deprecated Gradle features were used in this build, making it incompatible with Gradle 5.0.
See https://docs.gradle.org/4.7/userguide/command_line_interface.html#sec:command_line_warnings

BUILD SUCCESSFUL in 4s
1 actionable task: 1 executed
~~~

- 조건에 따른 빌드 1

~~~
task exeTask << {
	println 'Gradle Build Success !!!'
}

exeTask.onlyIf { // 특정 조건데 맞을 경우 빌드 수행.
	buildType == 'partial-build'
}
~~~

결과

~~~
$ gradle -PbuildType=partial-build exeTask

> Task :exeTask
Gradle Build Success !!!

Deprecated Gradle features were used in this build, making it incompatible with Gradle 5.0.
See https://docs.gradle.org/4.7/userguide/command_line_interface.html#sec:command_line_warnings

BUILD SUCCESSFUL in 4s
1 actionable task: 1 executed
~~~

- 조건에 따른 빌드 2

~~~
task exeTask << {
	println 'exeTask Build Success'
}

exeTask << {
	// 에러일 경우 예외 던지기
	if(process == 'error') { 
		throw new StopExecutionException()
	}
}

exeTask << {
	println '-- Build END --'
}
~~~

결과 1
~~~
$ gradle -Pprocess=ok exeTask

> Task :exeTask
exeTask Build Success
-- Build END --

Deprecated Gradle features were used in this build, making it incompatible with Gradle 5.0.
See https://docs.gradle.org/4.7/userguide/command_line_interface.html#sec:command_line_warnings

BUILD SUCCESSFUL in 5s
1 actionable task: 1 executed

~~~

결과 2(에러 발생 시키기)
~~~
$ gradle -Pprocess=error exeTask

> Task :exeTask
exeTask Build Success

Deprecated Gradle features were used in this build, making it incompatible with Gradle 5.0.
See https://docs.gradle.org/4.7/userguide/command_line_interface.html#sec:command_line_warnings

BUILD SUCCESSFUL in 4s
1 actionable task: 1 executed
~~~

- 실행 순서 제어 1
 
~~~
task exeTaskBefore << {
	println 'exeTaskBefore ----- 1'
}
task exeTaskAfter << {
	println 'exeTaskAfter ----- 2'
}

// exeTaskAfter 는 exeTaskBefore 가 수행한 후 수행한다.
exeTaskAfter.mustRunAfter exeTaskBefore
~~~

결과
~~~
$ gradle exeTaskAfter exeTaskBefore // 요청은 after 를 먼저했으나 실행은 before 가 먼저됨 (강제했으므로)

> Task :exeTaskBefore
exeTaskBefore ----- 1

> Task :exeTaskAfter
exeTaskAfter ----- 2

Deprecated Gradle features were used in this build, making it incompatible with Gradle 5.0.
See https://docs.gradle.org/4.7/userguide/command_line_interface.html#sec:command_line_warnings

BUILD SUCCESSFUL in 4s
2 actionable tasks: 2 executed

~~~

- 실행 순서 제어 2
	- exeTaskAfter.mustRunAfter를 exeTaskAfter.shouldRunAfter 로 변경
~~~
task exeTaskBefore << {
	println 'exeTaskBefore ----- 1'
}
task exeTaskAfter << {
	println 'exeTaskAfter ----- 2'
}

// exeTaskAfter 는 exeTaskBefore 가 수행한 후 수행한다.
exeTaskAfter.shouldRunAfter exeTaskBefore
~~~

결과 (mustRunAfter 로 했을 때와 동일)
~~~
$ gradle exeTaskAfter exeTaskBefore

> Task :exeTaskBefore
exeTaskBefore ----- 1

> Task :exeTaskAfter
exeTaskAfter ----- 2

Deprecated Gradle features were used in this build, making it incompatible with Gradle 5.0.
See https://docs.gradle.org/4.7/userguide/command_line_interface.html#sec:command_line_warnings

BUILD SUCCESSFUL in 4s
2 actionable tasks: 2 executed
~~~

그레이들의 태스크 그래프
 - 방향성 비순환 그래프 (Directed Acyclic Graph)
 - 태스크 간의 의존 관계를 시각적으로 표현

 
 ... 작성중 ...
 
