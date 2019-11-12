# 6. 집계
### 6장 주요 내용
 - 전자상거래 데이터 모델 집계
 - 집계 프레임워크 상세
 - 성능 및 제한사항
 - 기타 집계 기능

이번 장에서는 MongoDB 집계 프레임워크(aggregation framework)를 사용하여 보다 복잡한 쿼리를 포함하도록 주제를 확장.
 - MongoDB의 고급 쿼리 언어.
 - 여러 도큐먼트의 데이터를 변환하고 결합하여 단일 도큐먼트에서 사용할 수 없는 새로운 정보를 생성할 수 있음.
	- ex) 월별 매출, 제품별 매출, 사용자별 주문 합계와 같은 것을 알아낼 수 있다.
	- 관계형 데이터베이스에 익숙한 사용자는 SQL의 GROUP BY 절과 동일하다고 생각할 수 있을 것임. 
 - 한번의 호출로 일련의 도큐먼트 작업을 정의한 다음 MongoDB에 배열의 형태로 보낼 수 있으므로 작업을 훨씬 쉽고 효율적으로 수행 가능.
 
## 6.1. 집계 프레임워크 개요
 - 집계 프레임워크에 대한 호출은 파이프라인 각 단계에서의 출력이 다음 단계로의 입력으로 제공되는 파이프라인, 즉 집계 파이프라인(aggregation pipeline)을 정의함.
 - 각 단계는 입력을 변환하고 출력 도튜먼트를 생성하기 위해 입력 도큐먼트에 대해 단일 작업을 실행.
 - 집계 파이프라인 작업에는 다음이 포함된다.
	- $project - 출력 도큐먼트 상에 배치할 필드를 지정. (projected)
	- $match - 처리될 도큐먼트를 선택하는 것. find()와 비슷한 역할을 수행.
	- $limit - 다음 단계에 전달될 도큐먼트의 수를 제한.
	- $skip - 지정된 수의 도큐먼트를 건너뜀.
	- $unwind - 배열을 확장하여 각 배열 항목에 대해 하나의 출력 도큐먼트를 생성.
	- $group - 지정된 키로 도큐먼트를 그룹화.
	    - SQL GROUP BY 절과 동일
	- $sort - 도큐먼트를 정렬한다.
	- $geoNear - 지리 공간위치 근처의 도큐먼트를 선택.
	- $out - 파이프라인의 결과(출력)를 컬렉션에 쓴다.
	- $redact - 특정 데이터에 대한 접근을 제어.

#### 그림 6.1. 
<img src="/mongodb_img/mongodbinaction-image-6.1.png" />

> 대부분의 연산자는 익숙해 보이겠지만 집계 프레임워크 연산자는 MongoDB 쿼리에 사용되는 함수와 비슷하게 작동하므로 쿼리 언어를 잘 이해해야 한다.

- 코드 예제 : match, group, 및 sort로 구성된 집계 프레임워크 파이프라인 정의

~~~
db.products.aggregate([ {$match: ...}, {$group: ...}, {$sort: ...} ] )
~~~

#### 그림 6.2. 
<img src="/mongodb_img/mongodbinaction-image-6.2.png" />

그림에서 알 수 있듯이 코드는 파이프라인을 정의
 - 전체 제품(products) 컬렉션은 $match 작업으로 전달되고, 입력된 컬렉션으로부터 오직 특정 도큐먼트만 선택한다.
 - $match의 출력은 $group 연산자로 전달되며, $group 연산자는 출력을 측정 키로 그룹화하여 합계 및 평균과 같은 새로운 정보를 제공한다.
 - $group 연산자의 출력은 마지막 단계인 $sort 연산자로 전달되어 정렬이 수행되고 그 뒤에 최종 결과로 반환된다.
 
> 표 6.1. SQL vs. 집계 프레임워크 비교

 |SQL 명령어|집계 프레임워크 연산자|
 |------|---|
 |SELECT| $project, $group 함수: $sum, $min, $avg 등|
 |FROM | db.collectionName.aggregate(...)|
 |JOIN | $unwind|
 |WHERE|$match|
 |GROUP BY|$group|
 |HAVING| $match|
 
 
## 6.2. 전자상거래 집계 예제
 - 아래 그림 6.3. 은 전자상거래 데이터 모델의 데이터 모델 다이어그램을 보여 줌. 
 - 각각의 큰 박스는 데이터 모델의 컬렉션 중 하나인 제품(products), 리뷰(reviews), 카테고리(categories), 주문(orders) 및 사용자(users) 를 나타낸다.

#### 그림 6.3. 
<img src="/mongodb_img/mongodbinaction-image-6.3.png" />

 - 그림의 중앙에 있는 제품과 리뷰 사이의 선은 제품이 많은 리뷰를 가질 수 있고, 리뷰는 하나의 제품에 대한 것임을 보여준다.
 - 또한, 리뷰는 리뷰에 도움이 된다고 투표한 사람이 누구인지 표시해 주는 voter_id 객체를 가질 수 있다.

### 6.2.1. 상품, 카테고리, 리뷰
 - 제품에 대한 정보를 요약하는 데 집계 프레임워크가 어떻게 사용될 수 있는지에 대한 간단한 예를 살펴보기.
 - 5장에서 아래 쿼리를 사용하여 주어진 제품의 리뷰수를 계산하였음.

~~~
product = db.products.findOne({'slug': 'wheelbarrow-9092'})
reviews_count = db.reviews.count({'product_id': product['_id']})
~~~
 - 이걸 집계 프레임워크를 사용하여 수행하는 방법
    - 먼저 모든 제품의 총 리뷰수를 계산하는 쿼리를 만들어보자.

~~~

db.reviews.aggregate([
    {
        $group: {_id: '$product_id', // product_id 로 입력 도큐먼트를 그룹화
        count: {$sum: 1} }
    }   // 각 제품에 대한 리뷰수를 카운트
]);
~~~

 - 다음에 확인할 수 있는 것처럼 이 단일 연산자 파이프라인은 리뷰가 있는 데이터베이스의 각 제품에 대해 하나의 도큐먼트를 반환 함.

~~~
{ "_id" : ObjectId("4c4b1476238d3b4dd5003982"), "count" : 2 } // 각 제품에 대해 하나의 도큐먼트를 출력한다.
{ "_id" : ObjectId("4c4b1476238d3b4dd5003981"), "count" : 3 }
~~~

 - 이 예에서는 $group 연산자에 대한 입력으로 많은 도큐먼트를 갖지만, 각 고유한 _id 값(이 경우 고유한 product_id)마다 하나의 출력 도큐먼트만 갖음.
 - $group 연산자는 실제로 각 product_id에 대한 입력 도큐먼트의 수를 계산하여 제품(proudcts)에 대한 각 입력 도큐먼트에 대해 1을 추가한다.
 - 이 예제는 또한 $sum 함수를 사용하여 주어진 product_id에 대한 각 입력 도큐먼트의 count 필드에 1을 더하여 각 제품의 리뷰 입력 도큐먼트 수를 계산한다.
    - $group 연산자는 평균, 최소 및 최대뿐만 아니라 합계 등을 포함한 다양한 집계 결과를 계산할 수 있는 많은 함수를 지원함.
 - 아래는 계산할 하나의 제품만 선택하기 위해 파이프라인에 연산자를 하나 더 추가한 것이다.
~~~
product = db.products.findOne({'slug': 'wheelbarrow-9092'})

ratingSummary = db.reviews.aggregate([
      {$match: {product_id:  product['_id'] }} , // 오직 하나의 상품만 선택
      {$group: {_id: '$product_id', count: {$sum: 1} }} 
]).next()
~~~

 - 위 예제는 관심있는 하나의 제품을 반환하고 이를 ratingSummary 변수에 할당한다.
    - 집계 파이프라인의 결과는 커서(cursor)라고 하며, 커서는 한 번에 한 도큐먼트씩 거의 모든 크기의 결과를 처리할 수 있는 결과에 대한 포인터.
    - 단일 도큐먼트를 회수하기 위해 next() 함수를 이용하여 커서의 첫 번째 도큐먼트를 반환할 수 있음.
 
~~~
{ "_id" : ObjectId("4c4b1476238d3b4dd5003981"), "count" : 3 }
~~~
 - $match 연산자로 전달된 매개변수들은 이제 익숙할 것이다.
 - 제품에 대한 리뷰수를 계산하기 위해 5장에서 가져온 쿼리에 사용된 것과 동일하다.
~~~
db.reviews.count({'product_id': product['_id' ]})
~~~

#### 평균 리뷰 계산하기
 - 제품의 평균 리뷰를 계산하려면 앞의 예제와 동일한 파이프라인을 사용하고 하나이상의 필드를 추가하면 된다.

~~~

product = db.products.findOne({'slug': 'wheelbarrow-9092'})

ratingSummary = db.reviews.aggregate([
      {$match: {product_id:  product['_id'] }} , // 오직 하나의 상품만 선택
      {$group: {_id: '$product_id', average: {$avg: '$rating'},
                count: {$sum: 1} }} 
]).next()

~~~
- 이전 예제는 단일 도큐먼트를 반환하고 다음에 표시된 내용으로 ratingSummary 변수에 할당 한다.

~~~
{ "_id" : ObjectId("4c4b1476238d3b4dd5003981"), "average" : 4, "count" : 1 }
~~~

 - 이 예제서는 $avg 함수를 사용하여 제품의 평균을 계산함.
 - 또한, 평균화된 필드인 rating은 $avg 함수에서 '$rating'을 사용하여 지정.
    - 이는 $group _id값의 필드를 지정하는 데 사용된 규칙과 동일하다.
~~~
_id: '$product_id'
~~~

#### 등급별 리뷰 계산하기
 - 제품 요약을 더 확장하고 각 등급에 대한 리뷰 횟수의 내역을 보여 줄 때
    - 집계 프레임워크를 사용하면 단일 명령을 사용하여 이 요약을 계산할 수 있음.
~~~
countByRating = db.reviews.aggregate([
    {$match: {'product_id': product['_id'] }}, // 제품 선택
    {$group: {_id: '$rating', count:{$sum: 1}}}, // rating(등급) 값 별로 그룹화, 각 등급별 리뷰수 계산
]).toArray()  // 결과 커서를 배열로 반환
~~~

> SQL 쿼리에 익숙한 사용자의 경우 이와 동등한 SQL 쿼리는 다음과 같으므로 참고할 것.
~~~
SELECT RATING, COUNT(*) AS COUNT
FROM REVIEWS
WHERE PRODUCT_ID = '4c4b1476238d3b4dd5003981'
GROUP BY RATING
~~~
 - 결과
~~~
[ { "_id" :5, "count" : 5 }.
 { "_id" : 4, "count" : 2 }.
 { "_id" : 3, "count" : 1 }]
~~~

#### 컬렉션 조인
 - 데이터베이스의 내용을 검토하고 각각의 주요 카테고리의 제품 수를 계산한다고 가정.
    - 하나의 제품은 오직 하나의 주 카테고리만 가진다는 것을 기억하기
~~~
db.products.aggregate([
    {$group: {_id: '$main_cat_id', count: {$sum: 1}}}
])
~~~
 - 위 명령은 출력 도큐먼트 목록을 생성한다. 
~~~
{ "_id" : ObjectId("6a5b1476238d3b4dd500048"), "count" : 2 }
~~~
 - MongoDB의 한계중 하나는 컬렉션간의 조인을 허용하지 않음.
    - 이런 경우 일반적으로 데이터 모델을 비정규화 하여 그룹화 또는 중복을 통해 전자상거래 애플리케이션이 일반적으로 표시할 것으로 예상되는 특성을 포함하도록 하는 방법을 사용할 수 있음.
        - ex) 주문(orders) 컬렉션에서 각 항목은 제품 이름도 포함하고 있으므로 주문을 표시할 때 각 항목의 제품 이름을 읽기 위해 다른 호출은 하지 않아도 됨.  
 - MongoDB는 자동 조인을 허용하진 않지만 2.6 버전부터 SQL 조인과 동등한 기능을 제공하는 데 사용할 수 있는 몇가지 옵션 존재.
    - 옵션 중 하나는 forEach 함수를 사용하여 집계 명령에서 반환된 커서를 처리하고 의사 조인(pseudo-join)을 사용하여 이름을 추가하는 것임.
    - 아래는 예제
~~~
db.mainCategorySummary.remove({}); // mainCategorySummary 컬렉션에서 기존 도큐먼트를 제거.

db.products.aggregate([
    {$group: { _id: '$main_cat_id', count: {$sum: 1}}}
]).forEach(function(doc) {
    var category = db.categories.findOne({_id: doc._id}); // 결과에 대한 카테고리 읽기.
    if(category !== null) { // 카테고리가 실제로 존재한다는 보장은 없으므로
        doc.category_name = category.name;
    } else {
        doc.category_name = 'not found';
    }
    db.mainCategorySummary.insert(doc); // 결합된 결과를 요약 컬렉션에 삽입
})
~~~

 - 실행 후 mainCategorySummary 상에서의 find()는 각 카테고리에 대한 결과를 제공.
 - 다음에 나오는 findOne() 명령은 첫 번째 결과의 속성을 표시
~~~
{
        "_id" : ObjectId("6a5b1476238d3b4dd500048"),
        "count" : 2,
        "category_name" : "Gardening Tools"
}
~~~
 > 의사 조인은 사용 시 느려질 수 있으므로 주의해야 한다.
 
#### $out과 $project 
 - $out 연산자를 사용하면 파이프라인 출력을 자동으로 컬렉션에 저장할 수 있다.
    - $out  연산자는 컬렉션이 존재하지 않으면 컬렉션을 생성하고, 컬렉션이 존재하면 컬렉션을 완전히 대체한다.
    - 어떠한 이유로 컬렉션 생성 실패 시 MongoDB는 이전 컬렉션을 변경하지 않고 남김.

> ex ) 다음 파이프라인의 결과를 mainCategorySummary 컬렉션에 저장  
~~~
db.products.aggregate([
   {$group: {_id: '$main_cat_id', count: {$sum: 1}}},
   {$out: 'mainCategorySummary'} // 파이프라인 결과를 mainCategorySummary 에 저장
])
~~~

 - $project 연산자를 사용하면 파이프라인의 다음 단계로 전달할 필드를 필터링 가능.
    - $match 를 사용하면 전달되는 도큐먼트 수를 제한하여 데이터가 다음 단계로 전달되는 양을 제한할 수 있지만, $project는 다음 단계로 전달되는 각 도큐먼트의 크기를 제한하는 데 사용 할 수 있음.
        - 큰 도큐먼트 처리 후 각 도큐먼트의 일부만 필요로 하는 경우에는 각 도큐먼트의 크기를 제한하면 성능이 향상 될 수 있음.

> ex) 출력 도큐먼트를 각 제품에 사용되는 카테고리 ID  목록으로 제한하는 $project  연산자의 예
~~~
 db.products.aggregate([ {$project: {category_ids: 1}} ])
 
{ "_id" : ObjectId("4c4b1476238d3b4dd5003981"), 
"category_ids" : [ ObjectId("6a5b1476238d3b4dd500048"),
                    ObjectId("6a5b1476238d3b4dd500049") ] }.
{ "_id" : ObjectId("4c4b1476238d3b4dd5003982"), 
"category_ids" : [ ObjectId("6a5b1476238d3b4dd500048"),
                    ObjectId("6a5b1476238d3b4dd500049") ] }
~~~

#### $unwind 로 더 빨라진 조인
 - 이전에는 각 주요 카테고리에 대한 제품 수를 세었고, 이 경우에 하나의 제품은 오직 하나의 주요 카테고리만 가짐.
 - 이번에는 주요 카테고리인지 아닌지 여부에 관계없이 각 카테고리의 제품 수를 계산한다고 가정.

> 리스트 6.1. $unwind: 각 제품을 카테고리 ID 배열과 조인한다.
~~~
db.products.aggregate([ 
    {$project: {category_ids: 1}}, // 카테고리 ID 배열만 다음 단계로 전달, _id 속성은 기본적으로 전달됨.
    {$unwind: '$category_ids'}, // 카테고리 아이디의  모든 배열 항목에 대한 출력 도큐먼트를 생성.
    {$group: {_id: '$category_ids', count: {$sum: 1}}}, 
    {$out: 'countsByCategory'}  // $out은 집계 결과를 countsByCategory 컬렉션에 쓴다.
])
~~~
 - conuntByCategory에 저장된 출력의 예
~~~
{ "_id" : ObjectId("6a5b1476238d3b4dd500049"), "count" : 2 }
~~~

- $out 은 컬렉션에 결과를 저장.

> 뒤의 내용들 중 반복되는 내용 및 다양한 함수에 대한 내용은 생략하였음.

### 집계 파이프라인 성능에 영향을 미칠 수 있는 몇가지 주요 고려사항
 - 파이프라인에서 가능한 한 빨리 도큐먼트의 수와 크기를 줄인다.
 - 인젝스는 $match, $sort 작업에서만 사용할 수 있고, 이러한 작업을 크게 가속화할 수 있다.
 - $match 또는 $sort 이외의 연산자를 파이프라인에서 사용한 후에는 인덱스를 사용할 수 없다.
 - sharding을 사용하는 경우 $match 및 $project 연산자는 개별 샤드에서 실행된다.
 
### 요약
 - $group 연산자는 집계 프레임워크의 핵심 기능인 여러 도큐먼트의 데이터를 단일 도큐먼트로 집계하는 기능 제공.
 - $unwind 및 $project와 함께 집계 프레임워크는 분당 최대 요약 데이터를 생성하거나 대량의 데이터를 오프라인으로 처리할 수 있는 기능 제공.
 - $out 명령을 사용하여 결과를 새 컬렉션으로 저장 가능.