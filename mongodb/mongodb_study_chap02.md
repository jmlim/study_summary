## 2.1. MongoDB 셸에서 CRUD 연산
 - 이러한 과정을 통해 MongoDB 쿼리 언어에 대해 친숙해지기
 - 우선 시스템에 몽고디비를 설치한다. (부록 A 참고)

### 2.1.1. 셀 시작하기.
 - mongo 명령어로 셀 시작.

### 2.1.2. 데이터베이스, 컬렉션, 도큐먼트
- MongoDB 가 RDBMS 의 테이블과 같이 도큐먼트를 묶을 수 있는 방법이 필요함을 뜻하며 이를 컬렉션이라고 부른다.
    - 사용자와 주문같이 다른 유형의 도큐먼트들을 별도의 공간에 저장하고 싶을때가 있을 것이다.
- MongoDB 는 컬렉션들을 별개의 데이터베이스에 분리한다.
- SQL 데이터베이스들과는 다르게 MongoDB 에 있는 데이터베이스들은 단지 컬렉션들을 구분하는 네임스페이스일 뿐이다.
- MongoDB에 질의하기 위해서 질의를 하기 원하는 대상 도큐먼트가 존재하는 데이터베이스와 컬렉션을 알아야한다.
- 셀을 시작할 때 데이터베이스를 지정하지 않으면 test라는 이름의 기본 설정 데이터베이스에 연결된다.

```
> use tutorial
switched to db tutorial
>
```

> 왜 몽고디비는 데이터베이스와 컬렉션 모두를 다 가지고 있을까?
 - 데이터베이스의 모든 컬렉션들은 같은 파일에 그루핑된다.
  - 이는 같은 데이터베이스 내에 관련된 컬렉션들을 보관하기 위함이며, 이는 메모리 관점에서 이차에 맞는 것이다.
 - 같은 컬렉션에 대해 서로 다른 애플리케이션 접근이 발생할 수가 있는데 이런 경우에도 데이터를 잘 조직해 놓는것이 이후에 발생할 수 있는 요구사항 변경에 대비하기에 좋다.

#### 데이터베이스와 컬렉션의 생성
 - 데이터베이스와 컬렉션이 우연히 생성될까 우려된다면 드라이버에서 지원되는 strict 모드를 통해 실수를 방지할 수 있다.


첫번째 도큐먼트 만들기.

{username: "smith"}

#### 삽입과 질의
~~~
> db.users.insert({username: "smith"})
WriteResult({ "nInserted" : 1 })
>
~~~

위 코드를 입력하고 실행하면 약간 지연되는 느낌을 가질 수도 있다.
- 처음 코드를 실행하면 tutorial 데이터베이스와 users 컬렉션이 하드디스크에 아직 생성되지 않은 상태이므로 초기 데이터 파일을 할당하느라 지연되는것이다.

#### 새로 삽입된 도큐먼트 확인
~~~
> db.users.find()
{ "_id" : ObjectId("5da73578f08222b40ebdb7c9"), "username" : "smith" }
>
~~~

#### 도큐먼트에 _id 라는 필드가 추가된 것을 주목.
 - _id 는 도큐먼트의 primary key.
 - 도큐먼트 생성 시 이 필드(_id)가 없을 경우 특별한 값을 생성해서 위와같이 자동으로 추가한다.

#### 컬렉션에 두 번째 사용자를 추가.
~~~
> db.users.insert({username: "jones"})
WriteResult({ "nInserted" : 1 })
>
~~~
 > 이제 컬렉션에 두 개의 도큐먼트가 있을 것이다.
#### count 명령어로 확인.
~~~
> db.users.count()
2
~~~

#### 질의 술어 넘겨주기.
~~~
> db.users.find()
{ "_id" : ObjectId("5da73578f08222b40ebdb7c9"), "username" : "smith" }
{ "_id" : ObjectId("5da73717f08222b40ebdb7ca"), "username" : "jones" }
>
~~~

#### 사용자 이름이 jones 인 모든 도큐먼트에 대해 질의하기 위해서는 다음과 같이 간단한 도큐먼트를 쿼리 셀렉터로 넘겨준다.
~~~
> db.users.find({username:"jones"})
{ "_id" : ObjectId("5da73717f08222b40ebdb7ca"), "username" : "jones" }
>
~~~

#### db.users.find({}) 와 db.users.find() 는 같다.

또한 필드 사이에 암시적인 AND 를 만들어 내기 위해 쿼리 술어에 여러 개의 필드를 명시할 수 있다.
예를 들어, 다음과 같은 셀렉터를 질의로 수행할 수 있다.

~~~
> db.users.find({ "_id" : ObjectId("5da73578f08222b40ebdb7c9"), "username" : "smith" })
{ "_id" : ObjectId("5da73578f08222b40ebdb7c9"), "username" : "smith" }
>
~~~

#### 또한 명시적으로 MongoDB의 $and 연산자를 사용할 수 있으며, 이전 질의는 다음과 같이 표현.

~~~
> db.users.find({ $and: [
...     { "_id" : ObjectId("5da73578f08222b40ebdb7c9"), "username" : "smith" }
... ]})
{ "_id" : ObjectId("5da73578f08222b40ebdb7c9"), "username" : "smith" }
>
~~~

 > or 연산자를 이용해서 도큐먼트를 선택하는 것도 비슷하며 그저 $or 연산자만 쓰면 된다.
 - 사용자 smith, jones 요청
~~~
> db.users.find({ $or: [
    {username: "smith"},
    {username: "jones"}
]})
{ "_id" : ObjectId("5da73578f08222b40ebdb7c9"), "username" : "smith" }
{ "_id" : ObjectId("5da73717f08222b40ebdb7ca"), "username" : "jones" }
>
~~~

## 2.1.4. 도큐먼트 업데이트
 - 모든 업데이트 쿼리는 최소 두개의 매개변수가 필요하다.
 - 첫 번째 매개변수는 업데이트할 도큐먼트에 대한 것이고, 두 번째 매개변수는 수정할 내용에 대한 것이다.
 - 다른 속성과 용례를 가진 두 종류의 일반적인 업데이트가 존재한다.
    도큐먼트를 수정하는 연산을 적용하는 것이 존재하고 다른 하나는 오래된 도큐먼트를 새로운 도큐먼트로 대체하는 방식의 업데이트다.

### 연산자 업데이트

- $set 연산자 사용.
    - 사용자 이름이 jones 인 도큐먼트를 찾아서 country 속성의 값을 Korea 로 수정하기.

 ~~~
>   db.users.update({username: "jones"}, {$set: {country: "Korea"}})
WriteResult({ "nMatched" : 1, "nUpserted" : 0, "nModified" : 1 })
>
....

> db.users.find({username:"jones"})
{ "_id" : ObjectId("5da73717f08222b40ebdb7ca"), "username" : "jones", "country" : "Korea" }
>
~~~

### 대체 업데이트
 - 도큐먼트의 필드값을 설정하는 것이 아니라 아예 도큐먼트를 다른 것으로 대체하는 것이다.

~~~
> db.users.update({username: "jones"}, {country: "Canada"})
WriteResult({ "nMatched" : 1, "nUpserted" : 0, "nModified" : 1 })

> db.users.find({username:"jones"})  // 결과가 나오지 않음.
>

> db.users.find({country: "Canada"})
{ "_id" : ObjectId("5da73717f08222b40ebdb7ca"), "country" : "Canada" }
~~~

 위에 연산자 업데이트 한 것이랑 비교하면 아이디는 같으나 데이터는 대체되었다.
  - 만약 전체 도큐먼트를 대체하는 것이 아니라 필드를 추가하거나 값을 설정하기를 원한다면 반드시 $set 연산자를 사용하도록 하자.

> 사용자 이름을 끝부분에 다시 추가해본다.

~~~
> db.users.update({country: "Canada"}, {$set: {username: "jones"}})
WriteResult({ "nMatched" : 1, "nUpserted" : 0, "nModified" : 1 })

> db.users.find({country: "Canada"})
{ "_id" : ObjectId("5da73717f08222b40ebdb7ca"), "country" : "Canada", "username" : "jones" }
~~~

$unset 연산자를 사용하여 국가정보 지우기.
~~~
> db.users.update({username: "jones"}, {$unset: {country: 1}} )
WriteResult({ "nMatched" : 1, "nUpserted" : 0, "nModified" : 1 })

> db.users.find({username: "jones"})
{ "_id" : ObjectId("5da73717f08222b40ebdb7ca"), "username" : "jones" }
~~~


### 복잡한 데이터 업데이트
- 도큐먼트는 복잡한 구조의 데이터도 가질 수 있다.
 > 사용자 자신이 좋아하는 것의 목록을 추가로 저장할 수 있다고 가정한다면 다음에서와 같은 도큐먼트 표현이 가능하다.

~~~
> db.users.update({username: "jones"}, {
    $set: {
        favorites: {
            cities: ["Seoul","Anyang"],
            movies: ["기생충","극한직업","보헤미안 랩소디"]
        }
    }
})
WriteResult({ "nMatched" : 1, "nUpserted" : 0, "nModified" : 1 })

> db.users.find({username: "jones"})
{ "_id" : ObjectId("5da73717f08222b40ebdb7ca"), "username" : "jones", "favorites" : { "cities" : [ "Seoul", "Anyang" ], "movies" : [ "기생충", "극한직업", "보헤미안 랩소디" ] } }

~~~

#### smith 에 대해서도 비슷하게 수정을 해본다.
~~~
> db.users.find()
{ "_id" : ObjectId("5da73578f08222b40ebdb7c9"), "username" : "smith" }
{ "_id" : ObjectId("5da73717f08222b40ebdb7ca"), "username" : "jones", "favorites" : { "cities" : [ "Seoul", "Anyang" ], "movies" : [ "기생충", "극한직업", "보헤미안 랩소디" ] } }

> db.users.update({username: "smith"}, {
    $set: {
        favorites: {
            movies: ["타짜","택시운전사"]
        }
    }
})
WriteResult({ "nMatched" : 1, "nUpserted" : 0, "nModified" : 1 })
~~~

#### 업데이트가 성공적으로 되었는지 users 컬렉션에 대해 확인해본다.

~~~
> db.users.find().pretty()
{
        "_id" : ObjectId("5da73578f08222b40ebdb7c9"),
        "username" : "smith",
        "favorites" : {
                "movies" : [
                        "타짜",
                        "택시운전사"
                ]
        }
}
{
        "_id" : ObjectId("5da73717f08222b40ebdb7ca"),
        "username" : "jones",
        "favorites" : {
                "cities" : [
                        "Seoul",
                        "Anyang"
                ],
                "movies" : [
                        "기생충",
                        "극한직업",
                        "보헤미안 랩소디"
                ]
        }
}
>
~~~

 - find()  명령은 반환하는 도큐먼트에 커서(cursor) 를 반환한다.
 - pretty() 는 실제로 cursor.pretty() 이며, 이는 결과를 가독성 있는 형태로 보여주기 위해 커서를 설정하는 방법이다.

영화 기생충을 좋아하는 모든 사용자를 검색하기 위한 쿼리 예제에서 위의 개념들을 살펴볼 수 있다.
~~~
> db.users.find({"favorites.movies": "기생충"}).pretty()
{
        "_id" : ObjectId("5da73717f08222b40ebdb7ca"),
        "username" : "jones",
        "favorites" : {
                "cities" : [
                        "Seoul",
                        "Anyang"
                ],
                "movies" : [
                        "기생충",
                        "극한직업",
                        "보헤미안 랩소디"
                ]
        }
}
>
~~~

favorites 와 movies 사이의 점(dot)은 쿼리 엔진으로 하여금 favorites 라는 이름의 키를 찾고,
이 키의 값인 객체의 내부에서 다시 movies라는 이름의 키의 값이 되는 객체를 찾도록 지시한다.
따라서 배열 내의 어떤 요소든 원래 쿼리와 일치하는 부분이 있다면 배열상의 쿼리는 매칭이 되므로 이 쿼리는 두 사용자를 다 찾아주게 된다.
( 위 예시에서는 기생충이 jones 사용자에만 있어서 하나만 출력됨.)

### 더 발전된 업데이트

$set 연산자를 다시 사용할 수도 있겠으나 이것은 영화 배열 전체에 대해 다시 쓰기를 해야한다.
영화 리스트에 하나의 값만을 추가하는 것으므로 $push 나 $addToSet 을 사용하는 것이 더 낫다.
두 가지 연산자 모두 배열에 아이템을 추가하는데 여기서 $addToSet은 값을 추가할 때 중복되지 않도록 확인한다.

~~~
> db.users.update({"favorites.movies": "기생충"},
                {
                    $addToSet: { "favorites.movies": "택시운전사" }
                }, false, true)
WriteResult({ "nMatched" : 1, "nUpserted" : 0, "nModified" : 1 })

> db.users.find().pretty()
{
        "_id" : ObjectId("5da73578f08222b40ebdb7c9"),
        "username" : "smith",
        "favorites" : {
                "movies" : [
                        "타짜",
                        "택시운전사"
                ]
        }
}
{
        "_id" : ObjectId("5da73717f08222b40ebdb7ca"),
        "username" : "jones",
        "favorites" : {
                "cities" : [
                        "Seoul",
                        "Anyang"
                ],
                "movies" : [
                        "기생충",
                        "극한직업",
                        "보헤미안 랩소디",
                        "택시운전사"   // 추가됨
                ]
        }
}
>
~~~

 - 첫번째 매개변수 : 쿼리 셀렉터. (검색조건)
 - 두번째 매개변수 : 택시운전사 텍스트를 $addToSet 연산자를 이용해서 리스트에 추가한다.
 - 세번째 매개변수 : false -> upsert (update & insert) 가 허용되는지 아닌지를 조절한다.
 - 네번째 매개변수 : true -> 다중 업데이트, 즉 하나 이상의 도큐먼트에 대해 업데이트가 이루어져야 함을 뜻한다.
    - 몽고디비에서는 쿼리 셀렉터의 조건에 맞는 첫 번째 도큐먼트에 대해서만 업데이트를 하는 것이 기본 설정으로 되어있음.
    - 조건에 일치하는 모든 도큐먼트에 대해 업데이트 연산을 수행하려면 이것을 명시적으로 지정해야 한다.

~~~
> db.users.update({"favorites.movies": "택시운전사"}, {
          $addToSet: { "favorites.movies": "신과함께" }
    }, false, true )
WriteResult({ "nMatched" : 2, "nUpserted" : 0, "nModified" : 2 })
>

> db.users.find().pretty()
{
        "_id" : ObjectId("5da73578f08222b40ebdb7c9"),
        "username" : "smith",
        "favorites" : {
                "movies" : [
                        "타짜",
                        "택시운전사",
                        "신과함께" // 추가됨
                ]
        }
}
{
        "_id" : ObjectId("5da73717f08222b40ebdb7ca"),
        "username" : "jones",
        "favorites" : {
                "cities" : [
                        "Seoul",
                        "Anyang"
                ],
                "movies" : [
                        "기생충",
                        "극한직업",
                        "보헤미안 랩소디",
                        "택시운전사",
                        "신과함께" // 추가됨
                ]
        }
}
>
~~~


## 데이터 삭제
 - 컬렉션의 모든 도큐먼트 삭제

~~~
> db.foo.remove({})
~~~

좋아하는 도시 리스트에 Seoul이 들어가 있는 사용자를 모두 삭제하는 쿼리

~~~
> db.users.remove({"favorites.cities": "Seoul"})
WriteResult({ "nRemoved" : 1 })
>

> db.users.find().pretty()
{
        "_id" : ObjectId("5da73578f08222b40ebdb7c9"),
        "username" : "smith",
        "favorites" : {
                "movies" : [
                        "타짜",
                        "택시운전사",
                        "신과함께"
                ]
        }
}
>
~~~

remove() 연산은 컬렉션을 지우지 않음. (sql 에서 DELETE 와 흡사)
 - 어느 한 컬렉션을 모든 인덱스와 함께 지우려고 한다면 drop() 명령어를 사용하면 된다.

~~~
> db.users.drop()
true
> db.users.find()
>
~~~

기타 셀 특징
~~~
> help
        db.help()                    help on db methods
        db.mycoll.help()             help on collection methods
        sh.help()                    sharding helpers
        rs.help()                    replica set helpers
        help admin                   administrative help
      ..... 생략...
>
~~~

C:\Users\hacke>mongo --help
~~~
C:\Users\hacke>mongo --help
MongoDB shell version v4.2.0
usage: mongo [options] [db address] [file names (ending in .js)]
db address can be:
  foo                   foo database on local machine
  192.168.0.5/foo       foo database on 192.168.0.5 machine
  192.168.0.5:9999/foo  foo database on 192.168.0.5 machine on port 9999
  mongodb://192.168.0.5:9999/foo  connection string URI can also be used
Options:
  --ipv6                               enable IPv6 support (disabled by
                                       default)
  --host arg                           server to connect to
  --port arg                           port to connect to
  -h [ --help ]                        show this usage information
  --version                            show version information
  --verbose                            increase verbosity
  --shell                              run the shell after executing files
  --nodb                               don't connect to mongod on startup - no
 .... 생략,,,
C:\Users\hacke>
~~~


## 2.2 인덱스 생성과 질의
### 2.2.1. 대용량 컬렉션 생성.
    > numbers 라는 컬렉션에 20000개의 간단한 도큐먼트를 추가.
~~~
 > for(i = 0; i < 20000; i++) {
         db.numbers.save({num: i});
 }
 WriteResult({ "nInserted" : 1 })
~~~

 - 제대로 들어갔는지 카운트 조회
~~~
 db.numbers.count()
20000
~~~

~~~
 db.numbers.find()
{ "_id" : ObjectId("5da8d261d1cf27157bc4742e"), "num" : 0 }
{ "_id" : ObjectId("5da8d261d1cf27157bc4742f"), "num" : 1 }
{ "_id" : ObjectId("5da8d261d1cf27157bc47430"), "num" : 2 }
{ "_id" : ObjectId("5da8d261d1cf27157bc47431"), "num" : 3 }
{ "_id" : ObjectId("5da8d261d1cf27157bc47432"), "num" : 4 }
{ "_id" : ObjectId("5da8d261d1cf27157bc47433"), "num" : 5 }
{ "_id" : ObjectId("5da8d261d1cf27157bc47434"), "num" : 6 }
{ "_id" : ObjectId("5da8d261d1cf27157bc47435"), "num" : 7 }
{ "_id" : ObjectId("5da8d261d1cf27157bc47436"), "num" : 8 }
{ "_id" : ObjectId("5da8d261d1cf27157bc47437"), "num" : 9 }
{ "_id" : ObjectId("5da8d261d1cf27157bc47438"), "num" : 10 }
{ "_id" : ObjectId("5da8d261d1cf27157bc47439"), "num" : 11 }
{ "_id" : ObjectId("5da8d261d1cf27157bc4743a"), "num" : 12 }
{ "_id" : ObjectId("5da8d261d1cf27157bc4743b"), "num" : 13 }
{ "_id" : ObjectId("5da8d261d1cf27157bc4743c"), "num" : 14 }
{ "_id" : ObjectId("5da8d261d1cf27157bc4743d"), "num" : 15 }
{ "_id" : ObjectId("5da8d261d1cf27157bc4743e"), "num" : 16 }
{ "_id" : ObjectId("5da8d261d1cf27157bc4743f"), "num" : 17 }
{ "_id" : ObjectId("5da8d261d1cf27157bc47440"), "num" : 18 }
{ "_id" : ObjectId("5da8d261d1cf27157bc47441"), "num" : 19 }
Type "it" for more

> it
{ "_id" : ObjectId("5da8d261d1cf27157bc47442"), "num" : 20 }
{ "_id" : ObjectId("5da8d261d1cf27157bc47443"), "num" : 21 }
{ "_id" : ObjectId("5da8d261d1cf27157bc47444"), "num" : 22 }
{ "_id" : ObjectId("5da8d261d1cf27157bc47445"), "num" : 23 }
{ "_id" : ObjectId("5da8d261d1cf27157bc47446"), "num" : 24 }
{ "_id" : ObjectId("5da8d261d1cf27157bc47447"), "num" : 25 }
{ "_id" : ObjectId("5da8d261d1cf27157bc47448"), "num" : 26 }
{ "_id" : ObjectId("5da8d261d1cf27157bc47449"), "num" : 27 }
{ "_id" : ObjectId("5da8d261d1cf27157bc4744a"), "num" : 28 }
{ "_id" : ObjectId("5da8d261d1cf27157bc4744b"), "num" : 29 }
{ "_id" : ObjectId("5da8d261d1cf27157bc4744c"), "num" : 30 }
{ "_id" : ObjectId("5da8d261d1cf27157bc4744d"), "num" : 31 }
{ "_id" : ObjectId("5da8d261d1cf27157bc4744e"), "num" : 32 }
{ "_id" : ObjectId("5da8d261d1cf27157bc4744f"), "num" : 33 }
{ "_id" : ObjectId("5da8d261d1cf27157bc47450"), "num" : 34 }
{ "_id" : ObjectId("5da8d261d1cf27157bc47451"), "num" : 35 }
{ "_id" : ObjectId("5da8d261d1cf27157bc47452"), "num" : 36 }
{ "_id" : ObjectId("5da8d261d1cf27157bc47453"), "num" : 37 }
{ "_id" : ObjectId("5da8d261d1cf27157bc47454"), "num" : 38 }
{ "_id" : ObjectId("5da8d261d1cf27157bc47455"), "num" : 39 }
Type "it" for more
~~~

count() 명령은 20000개의 도큐먼트를 성공적으로 추가했음을 보여주며 it 명령어를 통해 더 많은 결과를 볼 수 있다.
충분한 양의 도큐먼트를 만들었으니 이제 몇가지 쿼리를 실행해본다.

#### num 속성에 조건에 일치하는 쿼리
~~~
> db.numbers.find({num:500})
{ "_id" : ObjectId("5da8d262d1cf27157bc47622"), "num" : 500 }
~~~

#### 범위 쿼리
~~~
db.numbers.find( {num: {$gt: 19995}} )
{ "_id" : ObjectId("5da8d278d1cf27157bc4c24a"), "num" : 19996 }
{ "_id" : ObjectId("5da8d278d1cf27157bc4c24b"), "num" : 19997 }
{ "_id" : ObjectId("5da8d278d1cf27157bc4c24c"), "num" : 19998 }
{ "_id" : ObjectId("5da8d278d1cf27157bc4c24d"), "num" : 19999 }
~~~

#### 두 연산자를 같이 사용
~~~
db.numbers.find( {num: {$gt: 20, $lt: 25 } } )
{ "_id" : ObjectId("5da8d261d1cf27157bc47443"), "num" : 21 }
{ "_id" : ObjectId("5da8d261d1cf27157bc47444"), "num" : 22 }
{ "_id" : ObjectId("5da8d261d1cf27157bc47445"), "num" : 23 }
{ "_id" : ObjectId("5da8d261d1cf27157bc47446"), "num" : 24 }
~~~
 > 간단한 JSON 도큐먼트를 사용하여 SQL 과 같은 방식으로 정교한 범위 쿼리 언어를 만들 수 있다.
 - 그 밖에 greator than or equal to (크거나 같은) 을 뜻하는 $gte
 - less than or equal to (작거나 같은)을 뜻하는 $lte
 - 같지 않은을 뜻하는 $ne 도 있다.

### 2.2.2 인덱싱과 explain()
  - 사용한 인덱스가 있을 경우에 어떤 인덱스를 사용했는지를 찾아서 쿼리 경로에 대한 정보를 제공해 줌으로써 개발자로 하여금 시간이 많이 소요되는 연산을 찾아내도록 도와준다.
  - 아래의 쿼리를 실행

#### 인덱스되지 않은 쿼리에 대한 .explain("executionStats")의 일반적인 결과
~~~
 db.numbers.find({num: {$gt: 19995}}).explain("executionStats")
{
        "queryPlanner" : {
                "plannerVersion" : 1,
                "namespace" : "tutorial.numbers",
                "indexFilterSet" : false,
                "parsedQuery" : {
                        "num" : {
                                "$gt" : 19995
                        }
                },
                "queryHash" : "C5C3B4DA",
                "planCacheKey" : "C5C3B4DA",
                "winningPlan" : {
                        "stage" : "COLLSCAN",
                        "filter" : {
                                "num" : {
                                        "$gt" : 19995
                                }
                        },
                        "direction" : "forward"
                },
                "rejectedPlans" : [ ]
        },
        "executionStats" : {
                "executionSuccess" : true,
                "nReturned" : 4,
                "executionTimeMillis" : 20,
                "totalKeysExamined" : 0,
                "totalDocsExamined" : 20000,
                "executionStages" : {
                        "stage" : "COLLSCAN",
                        "filter" : {
                                "num" : {
                                        "$gt" : 19995
                                }
                        },
                        "nReturned" : 4,
                        "executionTimeMillisEstimate" : 0,
                        "works" : 20002,
                        "advanced" : 4,
                        "needTime" : 19997,
                        "needYield" : 0,
                        "saveState" : 156,
                        "restoreState" : 156,
                        "isEOF" : 1,
                        "direction" : "forward",
                        "docsExamined" : 20000
                }
        },
        "serverInfo" : {
                "host" : "LAPTOP-N9VJ5GCQ",
                "port" : 27017,
                "version" : "4.2.0",
                "gitVersion" : "a4b751dcf51dd249c5865812b390cfd1c0129c30"
        },
        "ok" : 1
}
~~~

explain() 의 결과를 자세히 들여다보면 놀랍게도 쿼리 엔진이 단지 네개의 결과를 반환하기 위해 컬렉션의 전부인 20000개의 도큐먼트를 스캔한 것을 알 수 있음.
 - "totalKeysExamined" : 0,
 - "totalDocsExamined" : 20000,

스캔한 도큐먼트의 수과 결괏값의 큰 차이는 이 쿼리가 비효율적으로 실행됨을 보여줌.

- 이 컬럼에 인덱스를 추가하여 다시 조회
~~~
> db.numbers.createIndex({num: 1})
{
        "createdCollectionAutomatically" : false,
        "numIndexesBefore" : 1,
        "numIndexesAfter" : 2,
        "ok" : 1
}

// 성공적으로 생성되었는지 getIndexes()로 확인
>  db.numbers.getIndexes()
[
        {
                "v" : 2,
                "key" : {
                        "_id" : 1
                },
                "name" : "_id_",
                "ns" : "tutorial.numbers"
        },
        {
                "v" : 2,
                "key" : {
                        "num" : 1
                },
                "name" : "num_1",
                "ns" : "tutorial.numbers"
        }
]
~~~

 인덱스 쿼리에 대한 explain 의 결과
~~~
> db.numbers.find({num: {$gt: 19995}}).explain("executionStats")
{
        "queryPlanner" : {
                "plannerVersion" : 1,
                "namespace" : "tutorial.numbers",
                "indexFilterSet" : false,
              ...  생략...
        },
        "executionStats" : {
                "executionSuccess" : true,
                "nReturned" : 4,
                "executionTimeMillis" : 16,
                "totalKeysExamined" : 4, // 오직 4개의 도큐먼트만 스캔, 밑에 결과를 보면 속도도 훨씬 더 빨라짐
                "totalDocsExamined" : 4, //
                "executionStages" : {
                    ... 생략....
                }
        },
        "serverInfo" : {
                   ... 생략....
        },
        "ok" : 1
}
>

~~~

num에 해한 인덱스 num_1을 사용하므로 쿼리에 해당하는 네개의 도큐먼트를 스캔하고 따라서 쿼리 실행 시간도 8 밀리초에서 0 밀리초로 줄어듬을 확인하였다.

## 2.3.  기본적인 관리
### 2.3.1. 데이터베이스 정보 얻기.

~~~
> show dbs
admin     0.000GB
config    0.000GB
local     0.000GB
test      0.001GB
tutorial  0.001GB
>
~~~

 - 현재 사용중인 데이터베이스에서 정의된 모든 컬렉션을 보여줌
~~~
> show collections
numbers
~~~

- 데이터베이스와 컬렉션에 대해서 좀 더 하위 계층의 정보를 얻기 위해서는 stats() 명령이 유용하다.
~~~
> db.stats()
{
        "db" : "tutorial",
        "collections" : 1,
        "views" : 0,
        "objects" : 20000,
        "avgObjSize" : 35,
        "dataSize" : 700000,
        "storageSize" : 262144,
        "numExtents" : 0,
        "indexes" : 2,
        "indexSize" : 434176,
        "scaleFactor" : 1,
        "fsUsedSize" : 117420519424,
        "fsTotalSize" : 237627224064,
        "ok" : 1
}
~~~

- 각 컬렉션에 대해서도 stats() 를 실행할 수 있다.
~~~
> db.numbers.stats()
{
        "ns" : "tutorial.numbers",
        "size" : 700000,
        "count" : 20000,
        "avgObjSize" : 35,
        "storageSize" : 262144,
        "capped" : false,
        "wiredTiger" : {
                ..... 생략 ...
        },
        "nindexes" : 2,
        "indexBuilds" : [ ],
        "totalIndexSize" : 434176,
        "indexSizes" : {
                "_id_" : 196608,
                "num_1" : 237568
        },
        "scaleFactor" : 1,
        "ok" : 1
}
>
~~~

## 2.3.2. 명령어가 작동하는 방식.
 - 데이터베이스 명령어는 각 명령어의 기능과 상관없이 공통적인 것이 있음.
 - $cmd 라고 부르는 특별한 종류의 가상 컬렉션에 대한 쿼리로 구현된다.

 ~~~
 > db.runCommand
function(obj, extra, queryOptions) {
    "use strict";

    // Support users who call this function with a string commandName, e.g.
    // db.runCommand("commandName", {arg1: "value", arg2: "value"}).
    var mergedObj = this._mergeCommandOptions(obj, extra);

    // if options were passed (i.e. because they were overridden on a collection), use them.
    // Otherwise use getQueryOptions.
    var options = (typeof (queryOptions) !== "undefined") ? queryOptions : this.getQueryOptions();

    try {
        return this._runCommandImpl(this._name, mergedObj, options);
    } catch (ex) {
        // When runCommand flowed through query, a connection error resulted in the message
        // "error doing query: failed". Even though this message is arguably incorrect
        // for a command failing due to a connection failure, we preserve it for backwards
        // compatibility. See SERVER-18334 for details.
        if (ex.message.indexOf("network error") >= 0) {
            throw new Error("error doing query: failed: " + ex.message);
        }
        throw ex;
    }
}
 ~~~

 - 함수의 마지막 라인은 $cmd 컬렉션에 대해 쿼리를 수행하는 것에 불가.
 - 데이터베이스 명령어를 바르게 정의해 보면 명령어 자체를 쿼리 셀렉터로 가지면서 $cmd 라는 특수한 컬렉션에 대해 실행하는 쿼리라고 할 수 있다.

