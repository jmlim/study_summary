

# 5. 쿼리 작성하기.
## 주요내용
    - 전자상거래 데이터 모델 질의
    - 몽고디비 쿼리 언어 상세
    - 쿼리 셀렉터와 옵션

- JSON 과 비슷한 쿼리 언어 사용.
    - MongoDB 쿼리 언어를 대략 살펴볼 텐데, 질의 연산자에 대해서 자세히 다룸.

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
 - 전자상거래 데이터 모델에서 어떤 개체들은 임베디드 객체를 가리키는 키를 가짐.
	- products 에서 details 속성이 좋은 예
	- 아래는 JSON 으로 표현된 상품 도큐먼트의 일부분
~~~
{
	_id: ObjectId("4c4b1476238d3b4dd5003981"), // 1. 고유 객체 ID
	slug: "wheelbarrow-9092", // 2. 고유 슬러그
	sku: "9092",
	name: "Extra Large Wheelbarrow",
	description: "Heavy duty wheelbarrow...",
	details: {  // 3. 중첩 도큐먼트
		weight: 47,
		weight_units: "lbs",
		model_num: 4039283402,
		manufacturer: "Acme",
		color: "Green",
	},
	....
}
~~~

- 임베디드된 객체에 대한 쿼리는 키를 마침표(.)로 구분
	- Acme가 제조한 모든 상품 조회시 아래와 같이 조회
	
~~~
db.products.find({'details.manufacturer'})
~~~

- 위의 도큐먼트가 다음과 같이 수정 되었을 경우엔?

~~~
{
	_id: ObjectId("4c4b1476238d3b4dd5003981"), // 1. 고유 객체 ID
	slug: "wheelbarrow-9092", // 2. 고유 슬러그
	sku: "9092",
	name: "Extra Large Wheelbarrow",
	description: "Heavy duty wheelbarrow...",
	details: {  // 3. 중첩 도큐먼트
		model_num: 4039283402,
		manufacturer: {
			name: "Acme",
			id: 432
		},
		color: "Green"
	},
	....
}
~~~

 - 아래와 같이 쿼리 셀렉터에서 두 개의 점으로 구분된 키가 가능함.
~~~
db.products.find({'details.manufacturer.id': 432});
~~~

 - 하나의 서브 도큐먼트 말고 객체 전체에 대한 질의도 가능.
	- ex) MongoDB로 주식 시장 동향 데이터를 저장한다고 생각할 때
		- 저장공간을 절약하기 위해 일반적인 객체 ID를 사용하는 대신에 주식 기호와 타임스탬프로 이루어진 복합적인 키를 사용
~~~
{
	_id: {
		sym: 'GOOG',
		date: 20101005
	},
	open: 40.23,
	high: 45.50,
	low: 38.81,
	close: 41.22
}
~~~
 
 - 2010년 10월 5일의 GOOG에 대한 정보를 다음과 같이 _id 쿼리로 찾을 수 있다.
~~~
db.tick.find({'_id': {'sym': 'GOOG', 'date': 20101005})
~~~

 - 이 쿼리는 바이트 단위로 엄격하게 비교하여 키의 순서가 중요하다.
	- 아래 쿼리는 못찾음.
	- 자신이 사용하는 언어에서 ordered dictionary 데이터 구조를 지원하는지 꼭 확인할 것.
~~~
db.tick.find({'_id': {'date': 20101005, 'sym': 'GOOG'})
~~~

#### 배열
 - 도큐먼트 모델은 배열로 인해 매우 강력해짐.
 - 배열은 문자열이나 객체 ID 그리고 심지어는 다른 도큐먼트의 리스트를 저장하는 데 사용.
 - MongoDB에서 배열 타임에 대해 질의하거나 인덱스를 만드는 것이 쉽다는 점은 명백하다.
 - 배열 연산자: 
	- $elemMatch : 제공된 모든 조건이 동일한 하위 도큐먼트에 있는 경우 일치
	- $size : 배열 하위 도큐먼트의 크기가 제공된 리터럴 값과 같으면 일치

> ex) 상품태그
~~~
{
	id: ObjectId("4c4b1476238d3b4dd5003981"),
	slug: "wheel-barrow-9092",
	sku: 9092,
	tags: ["tools", "equipment", "soil"]
}
~~~
 - soil 이라는 태그를 갖는 상품에 대해 질의하는 것은 간단하며, 하나의 도큐먼트 값에 대해 질의하는 것과 동일한 문법을 사용
~~~
db.products.find({tags: "soil"})
~~~
 
 - 이 쿼리는 tag 필드에 대한 인덱스를 이용할 수 있다는 점이 중요.
	- 필요한 인덱스를 생성하고 explain() 으로 쿼리를 실행하면 B-트리 커서가 사용된다.
~~~
db.products.ensureIndex({tags: 1})
db.products.find({tags: "soil"}).explain()
~~~

 - 배열 쿼리를 좀 더 많이 제어할 필요가 있으면 닷(dot) 표기법을 써서 배열 내의 특정 위치에 있는 값에 대해서 질의할 수 있음.
 - 상품의 첫번째 태그로 제한하여 보기.

~~~
db.products.find({'tags.0', "soil"})
~~~

- 태그를 이런 방식으로 질의하는 것이 의미가 없을 수도 있지만, 사용자의 주소를 다루고 있다고 가정하면 다음과 같이 서브도큐먼트의 배열로 이 주소들을 표현할 수 있다.
	- ex) 첫번 째 주소를 사용자의 기본 배송 주소로 정할 때
~~~
{
	_id: ObjectId("4c4b1476238d3b4dd5000001"),
	username: "kbanker",
	addresses: [
		{
			name: "home",
			street: "588 5th Street",
			city: "Brooklyn",
			state: "NY",
			zip: 11215
		},
		{
			name: "work",
			street: "1 E. 23rd Street",
			city: "New York",
			state: "NY",
			zip: 10010
		}
	]
~~~

- 뉴욕이 기본 배송 주소인 모든 사용자를 찾으려면 다음에서처럼 위치를 0으로 정하고 점(.) 기호를 써서 state 필드를 지정할 수 있다.
~~~
db.users.find{'addresses.0.state': "NY")
~~~

- 다음의 쿼리는 여러 주소 중에 어느 것이라도 주(state)가 뉴욕이면 그 도큐먼트를 반환한다.
~~~
db.users.find({'addresses.state': "NY"})
~~~

- 필드에 대한 인덱스를 같이 만들기
~~~
db.ensureIndex({'addresses.state': 1})
~~~


- 필드가 하나의 서브 도큐먼트를 가리키든지 서브 도큐먼트의 배열을 가리키든지 간에 같은 닷 표기법을 사용.
	- 강력하고 일관성이 보장.
	- 하지만 서브 객체의 배열 내에서 하나 이상의 속성으로 질의할 때? 모호하다.
		- ex) 거주지 주소가 뉴욕주인 모든 사용자를 찾으려 할때?
~~~
db.users.find({'addresses.name': 'home', 'addresses.state': 'NY'})
// 이 쿼리의 문제점은 필드 지시자가 같은 주소에 대해 국한되지 않는다는 점. 
// 즉, 이 쿼리는 어떤 한 주소가 이름이 home 이라고 지정되어 있고 또 다른 주소는 주가 NY이면 두 주소가 서로 다른 주소임에도 불수하고 해당 도큐먼트를 반환.
// 여러개의 조건을 하나의 서브 도큐먼트에 대해 제한하려면 $elemMatch 연산자를 쓰면 된다.

db.users.find({
	'addresses': {
		'$elemMatch': {
			'name': 'home',
			'state': 'NY'
		}
	}
})

// $elemMatch는 서브도큐먼트에서 두 개 이상의 속성이 매치되는 것을 찾는 경우에만 사용.
~~~

#### 배열 크기별 질의
 - 정확히 세 개의 주소를 가지고 있는 모든 사용자를 검색하려면 다음과 같이 $size 연산자를 사용할 수 있다.
~~~
db.users.find({'addresses': {$size: 3})
~~~
 - size 연산자는 인덱스 사용 불가. 정확히 일치하는 쿼리에만 제한됨. (크기나 범위 지정 불가능)

#### 자바스크립트 쿼리 연산자
 - $where - 도큐먼트를 선택하기 위해 임의의 자바스크립트를 수행.

~~~
db.reviews.find({
	'$where': "function() {return this.helpful_votes > 3; }"
})
~~~
- 위의 쿼리를 더 간단하게 표현
~~~
db.reviews.find({
	'$where': "this.helpful_votes > 3;"
})
~~~
 - 다른 쿼리 연산자로도 쉽게 표현이 가능하며 인덱스를 사용할 수 없다.
 - 오버헤드가 많이 발생한다.(single thread)
	- 표준 쿼리 언어로 표현할 수 없는 경우에만 사용해야 한다.
	- 인젝션 공격에 노출되는 위험성에 대해서도 알고 있어야 함.

#### 정규표현식
 - $regex - 요소를 정규표현식과 맞춰 본다.
> ex) 상품평 중에 best나 worst라는 단어가 들어간 것을 감색.
~~~
db.reviews.find({
	'user_id': ObjectId("4c4b1476238d3b4dd5000001"}),
	'text': /best|worst/i
})
~~~

 - 정규 표현식을 지원하지 않는 환경에서는 $regex와 $options 라는 특수한 연산자를 사용.
	- 셸에서 이 연산자를 사용해서 위의 쿼리를 다음과 같이 표현할 수 있다.
~~~
db.reviews.find({
	'user_id': ObjectId("4c4b1476238d3b4dd5000001"}),
	'text': {
		'$regex': "best|worst",
		'$options': "i"
	}
})
~~~
 - 정규표현식 사용시 /i를 사용하지 않으면 그 검색은 검색되는 필드의 대소문자와 정확히 일치해야함.
 - 정규표현식 사용 시 /i 를 사용하면 인덱스 사용할 수 없음.
	- 대소문자를 구분하지 않는 색인화 검색을 하기 원한다면 특밸히 검색을 위해 강제로 내용을 소문자로 만든 중복 필드를 저장하는 것을 고려.
	- 다른 쿼리와 결함되어 인덱싱된 대소문자 구분 없는 검색이 가능한 MongoDB의 텍스트 검색 기능을 사용할 것을 고려.

#### 그 밖의 쿼리 연산자
 - $mod [몫, 결과] : 몫으로 나눈 결과가 요소와 일치할 경우
 - $type: 요소의 타입이 명시된 BSON 타입과 일치할 경우
 - $text: 텍스트 인덱스로 인덱싱된 필드의 내용에 대해 텍스트 검색을 수행

### 5.2.2. 쿼리 옵션
 - 모든 쿼리에는 셀렉터가 필요
	- 빈 셀렉터일지라도 쿼리 셀렉터는 본질적으로 쿼리를 정의
	- 하지만 결과값을 좀 더 제한하기 위해 다양한 쿼리 옵션을 사용할 수 있다.

#### 프로젝션
 - 결과값 도큐먼트에 대해 반환할 필드를 지정하는 데 사용.
	- $slice -- 반환되는 도큐먼트의 부분집합을 선택한다.
 
~~~
db.users.find({}, {'username' : 1})
~~~
 - username  필드와 _id 필드만을 반환.
~~~
db.users.find({},{'addresses': 0, 'payment_methods': 0})
~~~

~~~
db.products.find({}, {'reviews': {$slice: 12}}) // 1. 처음 12개의 리뷰를 가져옴.
db.products.find({}, {'reviews': {$slice: -5}}) // 2. 마지막 5개의 리뷰를 가져옴.
~~~

- 1번째 argument: skip, 2번째 argument: limit
- 처음 24개의 리뷰를 제외하고 난 후 가져올 리뷰를 12개로 제한.
~~~
db.products.find((),{'reviews': {$slice: [24,12]}})
~~~

 
- 리뷰의 평점만 포함시키도록 수정.
~~~
db.products.find({}, {'reviews': {$slice: [24,12]}, 'reviews.rating': 1})
~~~


#### 정렬
 - 리뷰를 평점이 높은 것부터 낮은 것까지 내림차순으로 정렬
~~~
db.reviews.find({}).sort({'rating': -1})
~~~
 - 혹은 다음과 같이 추천수와 평점순으로 정렬하는 것이 더 유용할 수 있다.
~~~
db.reviews.find({}).sort({'helpful_votes': -1, 'rating': -1})
~~~

#### skip과 limit
 - 별다른 것은 없음. 항상 예상대로 동작.
 - 하지만 데이터가 대량일 경우 skip에 큰 값을 념겨주게 되면(가령: 10000), skip 의 값 만큼 도큐먼트를 스캔해야 하므로 비효율 적임.
	- ex) 100만개의 도큐먼트를 날짜의 내림차순으로 해서 페이지를 나눈다면 5만번째 페이지를 보여주기 위해서는 skip의 값이 500,000이 되어야 하는데, 이것은 매우 비효율 적임.
	- 좀 더 나은 방법은 skip을 생략하고 대신 쿼리에 다음 결과값이 시작되는 범위 조건을 추가하는 것임.

~~~
// 아래와 같은 쿼리를 

db.docs.find({}).skip(500000).limit(10).sort({date: -1})

// 아래와 같이 수정한다.

previous_page_date = new Date(2013, 05, 05)
db.docs.find({'date': {'$gt': previous_page_date}}).limit(10).sort({'date': -1})
~~~
- 두 번째 쿼리는 첫 번째 것보다 훨씬 더 적은 수의 아이템을 스캔
	- 유일한 문제는 date가 각 도큐먼트에 대해 고유하지 않다면 같은 도큐먼트가 한 번 이상 보여질 수 있다는 점.
	- 위 방법 말고도 여러가지 방법들이 있는데 생각해보자.
