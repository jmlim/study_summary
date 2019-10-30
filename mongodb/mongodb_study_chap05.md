

# 5. 쿼리 작성하기.
## 주요내용
    - 전자상거래 데이터 모델 질의
    - 몽고디비 쿼리 언어 상세
    - 쿼리 셀렉터와 옵션

- JSON 과 비슷한 쿼리 언어 사용.
    - MongoDB 쿼리 언어를 대약 살펴볼 텐데, 질의 연산자에 대해서 자세히 다룸.

## 5.1. 전자상거래 쿼리.
- 이전 장에서 대략 윤곽을 잡았던 전자상거래 데이터 모델을 계속해서 연구
    - 상품, 카테고리, 사용자, 주문 그리고 상품 리뷰에 대한 도큐먼트 구조를 정의.

### 5.1.1. 상품, 카테고리, 리뷰
 - 일반적인 전자상거래 사이트는 상품과 카테고리에 대해 두 가지의 기본적인 뷰를 제공.
    - 상품정보 페이지.
    - 상품 리스트 페이지.
        - 사용자가 카테고리 계층 구조를 브라우징하고 해당 카테고리에 속하는 모든 상품의 썸네일 이미지를 본다.
- 상품 페이지가 해당 상품의 슬러그로 엑세스 된다고 가정 할 때 다음과 같은 세개의 질의로 상품 페이지에 대해 필요한 모든 데이터를 얻을 수 있다.

~~~
product = db.products.findOne({'slug':'wheel-barrow-9092'})
db.categories.findOne({'_id:product['main_cat_id']})
db.reviews.find({'product_id': product['_id']})
~~~


#### findOne vs find 쿼리

- findOne은 도큐먼트를 반환하는 반면에 find는 커서 객체를 반환.
- 위의 예제에서 첫 번째 쿼리의 findOne은 비록 제한을 적용해도 커서가 반환되기는 하지만 다음의 쿼리와 동일

~~~
db.products.find({'slug':'wheel-barrow-9092'}).limit(1)
~~~

- 만약 데이터베이스에 findOne 쿼리에 매칭되는 항목이 여러 개라면 컬렉션에 존재하는 도큐먼트 중 자연 정렬상으로 가장 첫 번째 항목을 반환한다.
    - 여러 개의 결과 도큐먼트가 필요하다면 find 쿼리를 사용하거나 명시적으로 결과를 정렬해야 한다.

####  skip, limit 그리고 쿼리 옵션.
 - 대부분의 애플리케이션에서는 리뷰를 페이지로 나누게 되는데, 이를 위해서 MongoDB는 skip과 limit 옵션을 제공함.

ex) 
~~~
db.reviews.find({'product_id': product['_id']}).skip(0).limit(12)
~~~

- 이는 평소 볼 수 있었던 패턴과 다르고, 심지어 다른 몽고DB 드라이버에서도 볼 수 없었던 패턴이므로 혼란을 불러일으킬 수 있다.
    - skip과 limit 는 질의 뒤에 호출된 것처럼 보이지만, 정렬과 제한(limiting) 매개변수는 질의와 함께 전달되고 MongoDB 서버에서 처리하게 된다.
         - Method chaining

- 리뷰를 일관된 순서로 보여 주길 원함.
    - 이때는 쿼리 결괏값을 정렬해야 한다.
    - 각 리뷰에 대해 추천수의 개수가 많은 순서대로 정렬하기.
~~~
db.reviews.find({'product_id': product['_id']})
    .sort({'helpful_votes': -1})
    .limit(12)
~~~

> 위 쿼리는 MongoDB에게 추천수가 많은 순서대로 정렬해서 처음 12개의 리뷰를 반환할 것을 요청.
 - skip, limit, sort를 가지고 여러 페이지로 나눌 것인지에 대한 여부를 결정하기만 하면 됨.
 - 아래 쿼리에 그것을 위해서 카운트(count) 쿼리를 실행.

~~~
page_number = 1
product = db.products.findOne({'slug': 'wheel-barrow-9092'})
category = db.categories.findOne({'_id': product['main_cat_id']})
reviews_count = db.reviews.count({'product_id': product['_id']})
reviews = db.reviews.find({'product_id': product['_id']})
            .skip((page_number - 1) * 12)
            .limit(12)
            .sort({'helpful_votes': -1})
~~~

- skip, limit, sort를 호출하는 순서는 중요하지 않음.
- 위의 쿼리는 인덱스를 이용해야 한다.
    - 슬러그는 또 다른 프라이머리 키로 사용.
    - 참고 역할을 하는 어떤 필드라도 인덱스를 갖는 것이 중요.
        - 위 예제에서는 리뷰 컬렉션에 대해 user_id와 product_id가 해당된다.


#### 상품 리스트 페이지
 - 해당 카테고리와 여기에 속해 있는 상품 리스트를 브라우징이 가능한 형태로 보여 줄 것이다.
     - 상위 카테고리와 이웃한 카테고리도 이 페이지에서 보여줌.
     - 상품 리스트 페이지는 카테고리로 정의
     - 슬러그 이용
~~~
page_number = 1
category = db.categories.findOne({'slug': 'gardening-tools'})
siblings = db.categories.find({'parent_id': 'category['_id'})
products = db.products.find({'category_id': category['_id']})
            .skip((page_number - 1) * 12)
            .limit(12)
            .sort({'helpful_votes': -1})
~~~

- 이웃 카테고리(siblings)는 상위 카테고리가 같은 카테고리들
    - 상품은 모두 카테고리ID의 배열을 가지고 있으므로 해당 카테고리에 속해 있는 모든 상품을 찾는 것도 역시 아주 간단하다.

- 루트에 있는 카테고리를 상품 리스트 없이 볼 때 
    - 부모 카테고리 ID가 null 인 카테고리를 전부 불러오면 된다.
~~~
categories = db.categories.find({'parent_id': null})
~~~

### 5.1.2. 사용자와 주문
 - 사용자 이름과 패스워드로 사이트에 로그인
~~~
db.users.findOne({
    'username': 'kbanker',
    'hashed_password': 'bd1cfa194c4a603e7186780824b04419'
})
~~~
 - 해당 사용자가 존재하고 패스워드가 맞다면 도큐먼트를 결과값으로 받음.
    - 그렇지 않을경우 반환 X
 - 원하는 필드만 받기위해 아래와 같은 방법을 사용할 수 있다. 
    - ex) '_id'
~~~
db.users.findOne({
    'username': 'kbanker',
    'hashed_password': 'bd1cfa194c4a603e7186780824b04419',
    {'_id': 1}
})
~~~
- 원하는 필드의 해시값을 1로 설정하므로써 id값만 반환하게끔 한다.
- SQL 에서 select * from 과 select id from 의 차이
##### 결과값
~~~
 {"_id": ObjectId("4c4b1476238d3b4dd5000001")}
~~~

#### 사용자에서의 부분 매칭 쿼리
~~~
db.users.find({'last_name': 'Banker'})
~~~
 - 위와 같이 사용자 정보를 찾을 때에는 이름이 정확히 일치해야 한다는 제한이 있음.
 - 부분 매칭을 해주는 쿼리가 필요할 때
    - 정규표현식을 이용
~~~
db.users.find({'last_name': /^Ba/})
~~~
 - 정규표현식 /^Ba/는 "한줄의 처음 시작에 B가 오고 그 다음 a가 온디" 와 같이 읽을 수 있다.

#### 특정 범위 질의
 - ex) 사용자의 우편번호에 대해 범위 질의를 할 경우
~~~
db.users.find({'addresses.zip': {'$gt': 10019, '$lt': 10040}})
~~~
 - $gt(~보다 큰) $lt(보다 작은)
 - 위 경우 인덱스 정의하면 더 효율적

## 5.2. MongoDB의 쿼리 언어
### 5.2.1. 질의 조건과 셀렉터 
 - AND
~~~
db.users.find({'last_name': 'Banker'})
db.users.find({'first_name': 'Smith', birth_year: 1975})
~~~

#### 범위
- $gt(~보다 큰), $lt(보다 작은), $lte(~보다 작거나 같은), $gte(~보다 크거나 같은)
~~~
db.users.find({'birth_year': {'$gte': 1985, '$lte': 2015}})
~~~

- 조건 넣을 때 문자열도 가능.
- 같은 타입에 대해서만 비교.
    - 숫자는 숫자타입만 비교해서 출력, 문자는 문자타입만 비교해서 출력.
    - 하나의 키에 여러가지 서로 다른 타입의 데이터를 저장하지 않는것이 좋다.
        - 최대한 지키기.

#### 집합 연산자
 - $in (하나라도 있을 경우), $all (모든 인수가 있을 경우), $nin (어떤 인수도 있지 않을 경우)
 - $in 연산자 예제(메인 카테고리중에 어느 하나라도 속해있는 상품 전부 조회)
~~~
db.products.find({
    main_cat_id: {
        '$in': [
            ObjectId("6a5b1476238d3b4dd500048"),
            ObjectId("6a5b1476238d3b4dd500051"),
            ObjectId("6a5b1476238d3b4dd500057")
        ]
    }
})
~~~

#### 부울 연산자
 - $ne : 같지 않을 경우 일치
 - $not : 일치 결과를 반전 (!)
 - $or : 제공된 검색어 집합 중 하나라도 true 일 경우 일치
 - $nor : 제공된 검색어 집합 중 그 어떤것도 true가 아닐경우 일치
 - $and : 제공된 검색어 집합이 모두 true일 경우 일치
 - $exist : 요소가 도큐먼트 안에 존재할 경우 일치

>  사용예
 ~~~
 db.products.find({
     '$or': [
         {'details.color': 'blue'},
         {'details.manufacturer': 'Acme'}
     ]
 })
 ~~~

 #### 특정 키로 도큐먼트에 질의
  - products 중에 색상 속성을 가지고 있지 않은 도큐먼트를 찾는 쿼리
~~~
db.products.find({'details.color': {$exist: false}})
~~~
  - 그 반대의 경우
~~~
db.products.find({'details.color': {$exist: true}})
~~~

#### 서브 도큐먼트 매칭
 ...

