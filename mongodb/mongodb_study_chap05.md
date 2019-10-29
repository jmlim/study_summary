

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


### findOne vs find 쿼리

- findOne은 도큐먼트를 반환하는 반면에 find는 커서 객체를 반환.
- 위의 예제에서 첫 번째 쿼리의 findOne은 비록 제한을 적용해도 커서가 반환되기는 하지만 다음의 쿼리와 동일

~~~
db.products.find({'slug':'wheel-barrow-9092'}).limit(1)
~~~

- 만약 데이터베이스에 findOne 쿼리에 매칭되는 항목이 여러 개라면 컬렉션에 존재하는 도큐먼트 중 자연 정렬상으로 가장 첫 번째 항목을 반환한다.
    - 여러 개의 결과 도큐먼트가 필요하다면 find 쿼리를 사용하거나 명시적으로 결과를 정렬해야 한다.

###  skip, limit 그리고 쿼리 옵션.
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


작성중...