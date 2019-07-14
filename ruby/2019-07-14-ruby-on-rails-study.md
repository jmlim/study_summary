# 루비 온 레일즈 설치 및 CRUD 만들어보기.

루비 -> 스프링 마이그레이션을 위한 루비 온 레일즈 스터디.

## 1. 일단 설치부터.. 

> 귀찮아서 윈도우에서 설치.

https://rubyinstaller.org/downloads/

<img src="{{ site.baseurl }}/ruby_img/ruby_install_site.png" />

 - With devkit 의 진한글씨로 선택되어 있는 버전을 설치함.
 - 레일즈 프로젝트를 위해서는 Development Kit 이 필요.
 - 예전에 jekyll 블로그 만드느라 이전 버전 깔려있었으나 그냥 재 설치함..ㅋ

## 2. 설치 후 ruby -v 로 버전 확인
```
C:\dev\study>ruby -v
ruby 2.5.5p157 (2019-03-15 revision 67260) [x64-mingw32]
```

여기서 rails를 설치해야 하는데 gem 이라는 것을 이용하여 설치 가능하다. <br/>
### 일단 gem 이란? 
 - rubygem(Gem)이란 루비에서 지원하는 패키지 시스템.
 - 리눅스의 패키지 시스템인 yum apt emerge 같은 것으로 필요 프로그램을 관리할 수 있는 프로그램이다.

명령어는 gem 으로 시작

사용예 ) 
 - 인스톨시에는 "gem install 패키지명"
 - 업데이트시에는 "gem update 패키지명"
 - 삭제시에는 "gem uninstall 패키지명"

> gem 에 대한 자세한 설명은 아래 블로그 참고
 - https://ideveloper2.tistory.com/80
 
## 3. gem 업데이트.
```
C:\dev\study> gem update --system
```

## 4. ruby on rails 설치
```
C:\dev\study> gem install rails
```
 > 설치가 다 되었으면 확인을 해보자.
```
C:\dev\study> rails -v
Rails 5.2.3
```

## 5. 프로젝트 생성
```
C:\dev\study>rails new jm_ruby_study
      create
      create  README.md
      create  Rakefile
      create  .ruby-version
      create  config.ru
      create  .gitignore
      create  Gemfile
         run  git init from "."
....
쭉쭉쭉
....

Using turbolinks 5.2.0
Using tzinfo-data 1.2019.2
Using uglifier 4.1.20
Using web-console 3.7.0
Bundle complete! 16 Gemfile dependencies, 76 gems now installed.
Use `bundle info [gemname]` to see where a bundled gem is installed.

```

프로젝트 생성이 될때 뭔가 쭉쭉쭉 만들어진다. <br/>
생성이 끝난후에 생성된 프로젝트에 들어가서 rails server를 입력하여 실행한다.

```
C:\dev\study\jm_ruby_study> rails server
=> Booting Puma
=> Rails 5.2.3 application starting in development
=> Run `rails server -h` for more startup options
*** SIGUSR2 not implemented, signal based restart unavailable!
*** SIGUSR1 not implemented, signal based restart unavailable!
*** SIGHUP not implemented, signal based logs reopening unavailable!
Puma starting in single mode...
* Version 3.12.1 (ruby 2.5.5-p157), codename: Llamas in Pajamas
* Min threads: 5, max threads: 5
* Environment: development
* Listening on tcp://localhost:3000
Use Ctrl-C to stop
```

## 6. 서버 실행 후 브라우저에 localhost:3000 실행

<img src="{{ site.baseurl }}/ruby_img/ruby_localhost.png" />

> 여기까지 했으면 설치는 완료

## rails 애플리케이션 폴더 구조.
```
/jm_ruby_study
    /app : 애클리케이션의 메인 폴더.
        /assets : 어셋(자바스크립트, 스타일시트, 그림 등의 리소스)
            /images
            /javascripts
            /stylesheets
        /controllers : 컨트롤 클래스
            /concerns : 컨트롤 공통 모듈
            application_controller.rb : 애플리케이션 공통 컨트롤러
        /helpers : 뷰 헬퍼
            application_helper.rb : 애플리케이션 공통 뷰 헬퍼
        /mailers : 액션 메일러 구현 클래스
        /models : 모델 클래스
            /concerns
        /views : 뷰 스크립트
            /layouts : 레이아웃
                application.html.erb : 애플리케이션 공통 레이아웃
    /bin : 코드 생성 또는 개발 서버 실행에 사용되는 헬퍼 스크립트
    /config : 애플리케이션 자체와 라우팅 등의 설정
        /environments : 환경 단위의 설정파일
        /initializers : 초기화 파일
        /locales : 국제화 대응을 위한 리소스 파일
    /db : 데이터베이스 자체 또는 스키마 정보. 마이그레이션 파일 등
    /lib : 사용자 정의 라이브러리 등
    /log : 로그 출력 위치
    /public : 공개 폴더
    /test : 테스트 스크립트 등
    /tmp : 임시 파일
    /vendor : 서버 파티 코드
    config.ru : 애플리케이션 엔트리 포인트
    Gemfile : 필요한 gem 파일 정의
    Rakefile : 터미널로부터 사용가능한 작업
    README.rdoc : readme
```

## 레일즈는 하나의 페이지를 만들기 위한 3개의 스텝이 존재한다.
1. 컨트롤러 생성 및 액션
2. config/route.rb 에서 해당 컨트롤러의 액션을 uri와 매핑
3. 뷰 생성

아래 스탭으로 한번 페이지를 만들어 보자.

## 1. 우선 컨트롤러를 생성한다.
 - 컨트롤러 생성하기: rails generate controller 컨트롤러 이름 

```
C:\dev\study\jm_ruby_study> rails generate controller home
....

``` 
 > home controller 는 app-> controllers 폴더에 home_controller.rb라는 파일로 생성된다.

## 2. 생성된 컨트롤러 확인) app/controllers
```ruby
class HomeController < ApplicationController

end
```

## 3. 컨트롤러가 생성되었으니 액션을 만들어본다.
hi 라는 액션에 @show_message, @message 라는 이름의 변수를 만들고 값을 지정하였다.

```ruby
class HomeController < ApplicationController
    def hi
        @show_message = false
        @message = "도망쳐"
    end
end
```

## 4. 그 다음 config/route.rb 파일을 확인 후 컨트롤러와의 액션을 uri 와 매핑한다.
```ruby
Rails.application.routes.draw d
  ## uri(/home 으로 지정하였다.) 와 액션(hi)을 맵핑
  get '/home' => 'home#hi' 
end
```
## 5. 마지막으로 view 에 hi.erb 페이지를 생성 
 - localhost:3000/home 을 브라우저에 타이핑하면 hi.erb 에 작성된 내용이 보이도록 한다.

레일즈에선 <% %> 안에 루비 코드를 작성할 수가 있으며 <%= %> 을 통해 아까 컨트롤러에서 값을 저장한 변수의 내용을 가지고 올 수 있다.

```ruby
<center>hi hi</center>
<% if @show_message %>
<p><%= @message %> </p>
<% end %>
```

> 아래부터는 대충 CRUD 코드만 작성...

==============================================================

# CRUD 화면 만들기. 
## 1. 컨트롤러 생성하기 
```
C:\dev\study\jm_ruby_study> rails generate controller crud
```
## 2. 모델을 생성하기
```
C:\dev\study\jm_ruby_study> rails generate model Post

invoke  active_record
create    db/migrate/20190713115520_create_posts.rb
create    app/models/post.rb
invoke    test_unit
create      test/models/post_test.rb
create      test/fixtures/posts.yml
```

## 3. 마이그레이션 파일작성.
 - 마이그레이션 파일은 실제 데이터를 넣을 형식을 결정하는 파일.
 - db/migrate 폴더의 migration 파일을 수정한다.
 - rails generate model Post 를 실행할 시 위 경로에 생성일_create_posts.rb 파일이 생성된다.


#### db 마이그레이션 시 참고자료 
 - 짧은 문자열 => string
 - 긴 문자열 => text
 - 숫자 => integer
 - 참/거짓 => boolean

## 4. 마이그레이션 파일을 아래와 같이 변경해본다.
```ruby
class CreatePosts < ActiveRecord::Migration[5.2]
  def change
    create_table :posts do |t|
      t.string :title
      t.text   :content
      t.timestamps
    end
  end
end
```

## 5. 변경한 후 모델과 db 마이그레이션 하기. 
```ruby
C:\dev\study\jm_ruby_study> rake db:migrate

== 20190713115520 CreatePosts: migrating ======================================
-- create_table(:posts)
   -> 0.0048s
== 20190713115520 CreatePosts: migrated (0.0097s) =============================
```

> 여기까지 했으면 코드를 작성해본다.

## 1. 컨트롤러 작성 (app/crud_controller.rb)
```ruby
class CrudController < ApplicationController
    def read
        ## 모델에서 모든 정보를 @posts 라는 인스턴스 변수에 저장해주세요.
        @posts = Post.all
    end

    # form
    def write
    end

    # action
    def create
        ## 정보를 저장하는 명령어, 페이지 필요 없음
        post = Post.new
        post.title = params[:title]
        post.content = params[:content]
        post.save
        
        ## 글을 쓰고난 후 리드 페이지로 가거라..
        redirect_to '/read'
    end

    #form
    def modify
        @post = Post.find(params[:post_id])
    end

    #action
    def update
        post = Post.find(params[:post_id])
        post.title = params[:title]
        post.content = params[:content]
        post.save
        redirect_to '/read'
    end

    #action
    def delete
        post = Post.destroy(params[:id])
        redirect_to :back
    end
end

```
## 2. config/route.rb 작성.

```ruby
Rails.application.routes.draw do
  get '/read' => 'crud#read'
  get '/write' => 'crud#write'
  post '/create' => 'crud#create'
  get '/modify/:post_id' => 'crud#modify'
  post '/update/:post_id' => 'crud#update'
  get '/delete/:id' => 'crud#delete'
end

```

## 3. view 페이지 생성 
 - app/views/crud/modify
```ruby
    Modify 페이지
    <form action="/update/<%= @post.id %>" method="post">
        제목: <input type="text" name="title" value="<%= @post.title %>"/></br>
        내용: <input type="text" name="content" value="<%= @post.content %>"/>
        <input type="submit"/>
    </form>
    <a href="/read">뒤로 돌아가기.</a>
```
 - app/views/crud/read
```ruby
리드페이지
db  migrate 에서 지정하였다.
<br/>
<%= @posts.each do |p| %>
    제목 : <%= p.title %> <a href="/modify/<%= p.id %>">수정하기</a><br/>
    내용 : <%= p.content %>  <a href="/delete/<%= p.id %>">삭제하기</a> 
    <br/> <hr/>
<% end %>

<br/>
<a href="/write">글쓰기</a>
```
- app/views/crud/write
```
Write 페이지
<form action="/create" method="post">
    제목: <input type="text" name="title"/></br>
    내용: <input type="text" name="content"/>
    <input type="submit"/>
</form>
<a href="/read">뒤로 돌아가기.</a>
```

## 4. index 액션이 DB를 읽어와서 변수에 저장하게 한다.
def index
 @posts = Post.all
end

## 기타 추가로 해볼것..
 - gem 의 Scaffolding 라이브러리 써서 페이지 만들기.
   > rails g scaffold Post content:string title:string

출처
 - https://www.inflearn.com/course/ruby-coin/dashboard
 - https://ideveloper2.tistory.com/80
-  https://hmjo.tistory.com/454

