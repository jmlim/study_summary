### 1. 터미널에서 Homebrew 설치
~~~
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
~~~
- brew help 명령어를 쳤을 때 다음과 같은 오류가 뜰 경우,
~~~
zsh: command not found: brew
~~~ 
### 2. 환경 변수 설정
1. vi 명령어를 통해 .zshrc 파일을 열어준다. 
   2. vi ~/.zshrc
2. 해당 파일에 다음 코드를 작성한다.
   3. i를 누르면 입력, esc를 누르면 명령어를 입력할 수 있다.

~~~
export PATH=/opt/homebrew/bin:$PATH
~~~
- :wq 명령어를 입력하여 저장 후 파일을 나간다.
3. source 명령어를 통해 .zshrc 파일에 썼던 코드를 적용한다.
~~~
source ~/.zshrc
~~~

출처 : https://velog.io/@kimgwon/%EA%B0%9C%EB%B0%9C-%ED%99%98%EA%B2%BD-Homebrew-%EC%84%A4%EC%B9%98-Mac-M3-Pro