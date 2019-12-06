# 8장. 인덱싱과 쿼리 최적화

## 8장 주요 내용.
 - 인덱싱의 기본 개념과 이론
 - 인덱스 관리를 위한 실용적인 조언
 - 복잡한 쿼리에 대한 복합 인덱스 사용
 - 쿼리 최적화
 - 모든 MongoDB 인덱싱 옵션
 
### 인덱싱의 이론적 고찰
 - 5천 페이지의 요리책 예
	- 인덱스 없이 로즈메리 감자 요리법 찾을 수 있을까?
		- 요리책을 처음부터 훑어나가면 됨.
		- 그 요리법이 3,973 페이지에 있다면 3,973 페이지까지 봐야 한다.
		- 최악의 경우 마지막 페이지에 요리법이 있을 수도 있음.
		- 해결책은 인덱스 생성.
 - 단순 인덱스
	- 요리법을 찾기 위해 여라가지 방법을 생각해 낼 수 있겠지만, 가장 좋은 방법은 요리법의 이름으로 찾는 것.
	- 요리책 끝에 각 요리법의 이름과 페이지 번호를 알파벳순으로 나열해 놓는다면 그 책은 요리법의 이름에 의해 인덱스가 된 것.
		- ex : 티베트 야크 수페 : 45, 구운 소금 덤플링 : 4,011 , 터키 알라팅: 943
	- 요리법의 이름을 알거나 혹은 그 이름의 처음 몇 글자만이라도 안다면 이 인덱스를 이용해서 요리법을 신속하게 찾을 수 있다.
		- 하지만 요리명에 의한 인덱스만 가지고 잇는 것은 비현실적.. 식료품 그릇에 있는 재료로 만들 수 있는 요리를 찾거나 지역에 따른 요리법을 찾을 수도 있기 때문..
			- 이 경우에는 좀 더 많은 인덱스가 필요
		- 또한 요리법의 이름에 대한 인덱스만 가지고 있는 상황에서 닭으로 만들 수 있는 모든 요리를 어떻게 찾지?
			- 여기에 적합한 인덱스가 없으므로 또다시 5,000 페이지를 다 넘기면서 닭 요리를 찾아야 함.
			- 이것은 재료나 지역에 따른 요리법을 찾을 때나 마찬가지..
			- 따라서 또 다른 인덱스를 만들어야 하는데, 이번에는 대료에 대한 인덱스다. 
				- 이 인덱스에는 재료를 알파벳 순서로 정렬하고, 그 재료가 들어가는 요리법에 대한 페이지 번호를 모두 나열한다.
				- 재료에 대한 가장 기초적인 인덱스는 다음과 같을 것이다.
					- 캣슈: 3; 20; 42; 88; 103; 1,215 ...
					- 콜리플라워: 2; 47; 88; 90; 275 ...
					- 커런트: 1,001; 1,050, 2,000; 2,133 ...
				- 이 인덱스는 여러분이 생각했던 인덱스인가? 이것은 유용할까?
 - 복합 인덱스
	- 주어진 재료에 대한 요리법의 리스트만 필요하다면 위 인덱스로 충분
	- 하지만 요리법에 관한 어떤 다른 정보를 찾고 있다면 여전히 이 리스트에 나오는 요리법을 일일이 살펴봐야 한다.
		- 일단 콜리플라워가 들어간 요리법이 나와 있는 페이지 번호를 알아낸 후 해당 페이지로 가서 요리법의 이름과 어느지역 음식인지를 알아낸다.
		- 모든 페이지를 다 넘겨보는 것보다는 낫지만 여전히 개선의 여지가 있음.
	- 지금까지 만든 두 개의 인덱스는 단일 키에 대해 생성한 인덱스.
		- 각 요리법에서 오직 하나의 데이터만으로 정렬.
		- 인덱스에 대한 한가지의 데이터 아이템만을 사용하지 않고 두 가지의 데이터를 사용할 것. 
		- 이렇게 하나 이상의 키를 사용하는 인덱스를 복합 인덱스(compound index) 라고 부름.
	- 여기서 복합 인덱스는 재료와 요리명을 재료, 요리명의 순서로 사용.
		- 이런 인덱스를 ingerdient-name이라고 표기.
		- 재료로 검색할 수 있고 이름을 앞부분밖에 기억하지 못한다고 해도 재빨리 원하는 요리법을 찾을 수 있을 것이다.
		- 주의할 사항이 한가지 있는데 복합 인덱스에서는 순서가 중요하다.
			- name-ingredient 라는 순사가 뒤바뀐 복합 인덱스를 생각해보면..
				- 이 새로운 인덱스에서는 일단 요리법 이름으로 찾고 나면 검색은 하나의 요리법, 즉 요리책에서 한 페이지에 국한됨.
				- 따라서 이 인덱스가 '캐슈 메리네이드' 라는 요리법과 '바나나' 라는 재료에 대한 검색에 사용된다면 그런 요리법은 존재하지 않는 것으로 나타난다.
				- 하지만 지금 필요한 것은 그 반대의 경우로 재료를 알고 있지만 요리 이름은 모른다.
 
 > 요리책은 이제 요리법 이름, 재료, 재료-이름, 이렇게 세개의 인덱스를 갖게 되었다. 이들 중 재료에 대한 단일키 인덱스는 없어도 된다. 재료만 지정해서 검색할 때는 재료-이름에 대한 인덱스를 사용할 수 있기 때문이다.
 재료를 알고 있다면 복합 인덱스를 탐색하면서 해당 재료를 포함하고 있는 모든 페이지 번호의 리스트를 얻을 수 있다.
 
- Single(단일) 필드 인덱스
	- _id에 대해 디폴트로 생성되는 인덱스가 좋은 예
	- MongoDB 드라이버가 지정하는 _id 인덱스 외에도, 사용자가 지정 할 수 있는 단일 필드 인덱스가 있음.
- Compound (복합) 필드 인덱스
	- 두개 이상의 필드를 사용하는 인덱스. 
	- ex) 제조사-가격
	- 키의 순서가 매우 중요

### 인덱스 효율
 - 쿼리 성능을 위해서는 인덱스가 반드시 필요하지만, 각 인덱스는 유지 비용이 들어감.
	- 어떤 컬렉션에 도큐먼트를 추가할 때마다 그 컬렉션에 대해 생성된 인덱스도 그 새로운 도큐먼트를 포함시키도록 수정해야함.
 - 읽기 위주의 애플리케이션에서 인덱스 비용은 인덱스로 인해 얻을 수 있는 효과로 상쇄됨.
	- 그러나 인덱스는 비용이 발생하니 조심해서 생성해야 한다.
		- 사용되지 않는 중복된 인덱스가 존재하면 안됨.
 - 모든 인덱스가 적합하게 만들어졌다고 해도 쿼리를 빠르게 처리하지 못할 가능성이 여전히 존재함.
	- 이것은 인덱스와 현재 작업중인 데이터를 램에서 다 처리하지 못할 때 발생함.
	- 데이터를 수용하지 못하면 점점 페이지 폴트가 발생하는데 이것은 OS가 디스크를 빈번하게 액세스함으로써 읽기와 쓰기 연산이 매우 느려지게 된다는 것을 뜻함.
	- 최악의 경우에는 데이터의 크기가 램의 크기보다 훨씬 커서 모른 읽기와 쓰기에 대해 디스크 액세스를 해야 하는 상황이 발생할 수도 있음.
		- 쓰레싱(thrashing)이라고 함
	- 이런 현상은 쉽게 피할 수 있는데 인덱스만큼은 램에 들어가도록 하면 된다.
		- 필요없는 인덱스를 만들지 말아야할 중요한 이유.
		- 인덱스와 현재 작업중인 데이터가 모두 램에 존재해야 이상적임.
			-stats 명령을 통해 전체 인덱스 크기 확인 가능.
### B-트리
 - 몽고디비는 내부적으로 b-tree로 인덱스를 생성함.
 - 내용 참고 : https://ko.wikipedia.org/wiki/B_%ED%8A%B8%EB%A6%AC
 
## 인덱싱의 실제
### 인덱스 타입
 - 고유 인덱스(unique index)
	- 종종 _id 또는 username과 같은 도큐먼트의 필드가 해당 도큐먼트에서 고유한지 확인하는 경우가 있음.
	- 고유 인덱스(unique index)는 이 특성을 강화하는 방법.
	- 고유 인덱스를 생성하기 위해선 인덱스 생성 시 unique 옵션을 지정한다.
	- 	ex) db.users.createIndex({username: 1}, {unique: true})
	- 고유 인덱스는 컬렉션에 데이터가 존재하지 않을 때 생성하는 것이 좋음.
	- 고유 인덱스를 걸려고 하는 컬럼에 중복 데이터 존재 시 실패한다.
	- 기존에 존재하는 컬렉션에 대해 고유 인덱스 생성시 몇가지 옵션이 있음.
		- 고유 인덱스 생성을 반복적으로 수행하고 발생하는 실패 메시지를 이용해 중복키를 없애는 방법.
		- 하지만 데이터가 그다지 둥요하지 않다면 데이터베이스로 하여금 dropDups 옵션을 이용해 중복 키를 가지고 있는 도큐먼트를 자동으로 삭제하도록 명령을 내릴 수 있음.
			- ex) user 컬렉션에 이미 데이터가 있고 중복된 키 값을 갖는 도큐먼트를 삭제해도 무방하다면 다음과 같이 인덱스 생성 명령을 수행 할 수 있다.
			- 3.x 에서 삭제됨.. 이기능에 대한 대체옵션 존재x, 새 컬렉션을 만들고 새 컬렉션에 고유 인덱스를 만들고 이전 컬렉션의 모든 도큐먼트를 복사하는 방법 또는 위 방법 권장.

 - 희소 인덱스(sprase index)
	- 인덱스는 밀집(dense) 하도록 기본 설정되어 있음.
		- 밀집 인덱스란 컬렉션 내의 한 도큐먼트가 인덱스 키를 가지고 있지 않더라도 인덱스에는 해당 엔트리가 존재한다는 것을 뜻함.
		- 예를 들어, 우리가 이미 살펴봤던 전자상거래 데이터 모델에서 상품 컬렉션에 대해 category_id 로 인덱스를 생성했는데, 카테고리가 지정되지 않은 상품이 몇개 있다고 가정 해보자. 이 카테고리가 없는 상품들에 대해 category_id 인덱스는 널 값을 갖는 엔트리를 갖게 된다.
		- ex) db.products.find({category_ids: null})
		- 카테고리를 갖지 않는 모든 상품을 검색할 때 쿼리 옵티마이저(query optimizer)는 이 상품들을 찾기 위해 category_id 인덱스를 사용할 수 있다.
	- 밀집 인덱스가 바람직하지 않은 경우..
		- 모든 도큐먼트가 다 가지고 있지는 않은 필드에 대해 고유인덱스를 생성할 때.
			- ex) sku 라는 필드에 고유 인덱스가 이미 생성되어 있는 상황에서 sku 필트를 갖지 않는 도큐먼트를 여러개 삽입하려고 하면 첫 번째 삽입은 성공하지만 그 이후의 삽입 연산은 실패한다.
			- sku 에 null인 엔트리가 이미 존재하므로.. 그 대신 희소 인덱스(sprase index) 가 필요하다.
	- 희소 인덱스가 바람직한 경우
		- 컬렉션에서 많은 수의 도큐먼트가 인덱스 키를 가지고 있지 않은 경우이다.
			- ex) 상품평을 남길 때 익명으로 할 수 있다고 가정. 이 경우 리뷰의 반이 user_id 필드를 가지고 있지 않을 수도 있다.
				- 만일 이 경우 user_id 필드에 인덱스를 생성하면 인덱스 엔트리의 절반이 null이 될 수도 있다.
				- 이것은 두가지 이유로 인해 매우 비효율적... 
					- 인덱스 크기 증가.
					- user_id 가 null값을 갖는 도큐먼트 추가 삭제 시 인덱스를 업데이트 해야함.
		- 익명으로만 된 상품평에 대한 질의를 거의 하지 않는다면 user_id에 대해 희소 인덱스를 생성할 수도 있다.
		- db.reviews.createIndex({user_id: 1}, {sprase: true, unique: false})  
  - 다중키 인덱스
	- 필드의 값이 배열인 경우 인덱스하는 것에 대한 예는 이전 장에서 이미 살펴봄. (카테고리 여러개 있는 경우)
	- 이것은 다중 키 인덱스(multikey index) 라는 것으로 가능한데, 인덱스 내의 여러개의 엔트리가 동일한 도큐먼트를 지시하게 됨.
	- ex) 여러개의 태그를 갖는 상품 도큐먼트를 가지고 있다고 가정..
		- tags 필드에 대해 인덱스를 생성하면 이 도큐먼트의 태그 배열에 있는 각 값들은 인덱스에 나타난다.
		- 이것은 이 배열의 값 중 어느 것으로도 도큐먼트를 찾을 수 있음을 뜻함.	
	~~~
		{
			name: "Wheelbarrow",
			tags: ["tools","gardening", "soil"]
		}
	~~~
 - 해쉬 인덱스
	- 해쉬 기반의 샤딩을 제공하기 위해, 몽고디비는 필드의 값의 해쉬를 인덱스하는 해쉬 인덱스 타입을 제공함.
		- 이러한 인덱스는 이들 범위 내 값에 더욱 무작위적인 분포를 가지고 있다. 
		- 하지만 단순히 동등 쿼리만 지원하고 범위 기반 쿼리를 지원하지 않음.
 - 지리공간적 인덱스
	- 각 도큐먼트에 저장된 위도값과 경도값에 따라 도큐먼트를 특정 위치에 '가까이' 배치하는 것.
	- GeoSpatial index는 2차원, 3차원에서 특정 좌표값을 잡고 그 주위 값을 어떤 모양으로 선정할 것인지를 선택하는 방법
		- '내가 있는 위치의 근처에 있는 맛집 찾기', '서울에서 부산을 가는데 가장 빠른 경로 찾기' 등에 이용되는 방법.
		- ex ) https://docs.mongodb.com/manual/core/geospatial-indexes/

### 인덱스 관리
- 인덱스 생성과 삭제
	- createIndex() 사용하여 생성.
	- db.system.indexes 에 직접 삽입도 가능.
	- getIndexes() 메서드로 인덱스에 대한 사항 확인 가능. ex) db.users.getIndexes()
	- dropIndex()를 사용하여 인덱스 삭제. ex) db.users.dropIndex("zip_1")
- 인덱스 구축
	- 인덱스 선언 시 주의사항
		- 실제 서비스 상황에서 데이터가 대량일 경우 인덱스 구축은 오랜 시간이 걸리는데 이것은 악몽과도 같음. 인덱스 구축을 중지시키기가 쉽지 않으므로..
		- 만일 이런일이 발생한다면 백업 또는 세컨더리 노드로 서비스를 해야할 것임.
		- 인덱스 구축은 일종의 데이터베이스 마이그레이션으로 간주하는것이 현명함.
	- 인덱스 구축은 두 단계로 이루어짐
		- 첫번째 단계에서는 인덱스할 값을 정렬, 두번째 단계에서 정렬된 값들이 인덱스로 삽입됨.
		- db.currentOp() 메서드로 인덱스 생성의 진척 상황을 확인해 볼 수 있음.
		- 생성되는 동안 데이터베이스에 읽거나 쓰기를 할 수 없다.

### 백그라운드 인덱싱
 - 인덱스가 백그라운드에서 구축되도록 지정할 수 있음.
	- 쓰기 잠금은 되지반, 데이터베이스에 대한 다른 읽기나 쓰기를 허용하기 위해 잠시 멈춤.
	- 애플리케이션이 MongoDB를 많이 사용하는 경우라면 성능을 떨어뜨리긴 하겠지만 어떤 상황에서는 받아들일 만한 성능을 가질 수 있음.
	- 선언 예 ) db.values.createIndex({open: 1, close:1}, {background: true})

### 오프라인 인덱싱
 - 백그라운드 인덱스를 생성하면 여전히 상용 서버에 허용할 수 없는 많은 양의 로드를 발생시킬 수 있음.
	- 이 경우 데이터를 오프라인으로 인덱스화해야 할 수도 있다.
		- 복제 노드를 오프라인 상태로 변경 후 그 노드에 대해 인덱스 구축 한 다음 마스터 노드로부터 업데이트를 받음.
		- 업데이트 완료 후에 이 노드를 프라이머리 노드로 변경하고, 다른 세컨더리 노드들은 오프라인 상태로 바꾼 후에 각자 인덱스 구축을 함.

### 백업
 - 인덱스는 구축하기 어려우므로 백업을 해놓아야 함.
	 - 백업이 인덱스를 포함하길 원한다면 MongoDB의 데이터 파일 자체를 백업해야 한다.

### DEFRAGMENTING
 - 재인덱싱을 할 때는 주의해야 함.
	- 재구축하는 동안 쓰기 잠금을 하므로 MongoDB를 일시적으로 사용할 수 없게 됨.
	- 재인덱싱은 오프라인일 때 최적으로 수행함.

## 쿼리 최적화
 - 쿼리 최적화는 느린 쿼리를 찾아서 원인을 발견하고, 속도를 개선하기 위한 조치를 취하는 과정.

### 느린 쿼리 참지.
 - 데이터 양이 많은 일일 단위의 나스닥 데이터로 구성된 데이터 세트를 사용하여 실습
	- http://mng.bz/ii49 에서 데이터 다운로드 (stocks.zip)
	- 압축을 푼 후 mongod 프로세스를 시작한 후에 덤프를 다음과 같이 복구한다.
		- mongorestore -d stocks -c values 압축을 푼 경로(ex : dump/stocks)
~~~
	F:\mongodb>mongorestore -d stocks -c values F:\mongodb\dump\stocks\values.bson
	2019-12-06T13:21:50.360+0900    checking for collection data in F:\mongodb\dump\stocks\values.bson
	2019-12-06T13:21:50.549+0900    restoring stocks.values from F:\mongodb\dump\stocks\values.bson
	2019-12-06T13:21:53.361+0900    [#.......................]  stocks.values  41.1MB/715MB  (5.7%)
	2019-12-06T13:21:56.360+0900    [##......................]  stocks.values  86.2MB/715MB  (12.0%)
	2019-12-06T13:21:59.360+0900    [####....................]  stocks.values  131MB/715MB  (18.4%)
	2019-12-06T13:22:02.360+0900    [#####...................]  stocks.values  177MB/715MB  (24.7%)
	2019-12-06T13:22:05.360+0900    [#######.................]  stocks.values  217MB/715MB  (30.3%)
	2019-12-06T13:22:08.360+0900    [########................]  stocks.values  261MB/715MB  (36.5%)
	2019-12-06T13:22:11.360+0900    [##########..............]  stocks.values  306MB/715MB  (42.8%)
	2019-12-06T13:22:14.360+0900    [###########.............]  stocks.values  351MB/715MB  (49.0%)
	2019-12-06T13:22:17.360+0900    [#############...........]  stocks.values  395MB/715MB  (55.3%)
	2019-12-06T13:22:20.360+0900    [##############..........]  stocks.values  442MB/715MB  (61.7%)
	2019-12-06T13:22:23.361+0900    [################........]  stocks.values  486MB/715MB  (68.0%)
	2019-12-06T13:22:26.360+0900    [#################.......]  stocks.values  529MB/715MB  (73.9%)
	2019-12-06T13:22:29.361+0900    [###################.....]  stocks.values  574MB/715MB  (80.2%)
	2019-12-06T13:22:32.360+0900    [####################....]  stocks.values  619MB/715MB  (86.5%)
	2019-12-06T13:22:35.360+0900    [######################..]  stocks.values  661MB/715MB  (92.4%)
	2019-12-06T13:22:38.361+0900    [#######################.]  stocks.values  704MB/715MB  (98.4%)
	2019-12-06T13:22:39.580+0900    [########################]  stocks.values  715MB/715MB  (100.0%)
~~~

- 최초의 구글 주식에 대한 쿼리 조회.
	 - 시간이 어느정도 걸리며 MongoDB 로그를 확인해 보면 역시 예상했던 대로 느린 쿼리 경고 메시지를 볼 수 있다.
	 - 기본은 어떤 연산이라도 100밀리초를 넘어서면 경고메세지를 프린트한다.
~~~
> use stocks
> db.values.find({"stock_symbol": "GOOG"}).sort({date: -1}).limit(1)
... 2초정도 위에.. 아래 결과 조회됨.
{ "_id" : ObjectId("4d094f7ec96767d7a02a0af6"), "exchange" : "NASDAQ", "stock_symbol" : "GOOG", "date" : "2008-03-07", "open" : 428.88, "high" : 440, "low" : 426.24, "close" : 433.35, "volume" : 8071800, "adj close" : 433.35 }
~~~ 

 - 로그 출력 내용
~~~
2019-12-06T13:24:31.316+0900 I  COMMAND  [conn12] command stocks.values appName: "MongoDB Shell" command: find { find: "values", filter: { stock_symbol: "GOOG" }, limit: 1.0, singleBatch: false, sort: { date: -1.0 }, lsid: { id: UUID("c0071e13-474f-449a-8eca-d15f368a2852") }, $db: "stocks" } planSummary: COLLSCAN keysExamined:0 docsExamined:4308304 hasSortStage:1 cursorExhausted:1 numYields:33658 nreturned:1 queryHash:47C37128 planCacheKey:47C37128 reslen:279 locks:{ ReplicationStateTransition: { acquireCount: { w: 33659 } }, Global: { acquireCount: { r: 33659 } }, Database: { acquireCount: { r: 33659 } }, Collection: { acquireCount: { r: 33659 } }, Mutex: { acquireCount: { r: 1 } } } storage:{} protocol:op_msg 2040ms
~~~
 - 책에선 4초가 걸렸다고 나왔으나 로컬에서 실행해보니 2초정도 나왔음.
 - 이런 경고는 매우 중요하므로 로그 메세지를 자주 확인해 봐야 함.
	- 리눅스에서 grep -E '[0-9]+ms' mongod.log 같은 명령어로..
	- 100 밀리초가 임계값으로 너무 높거나 낮으면 MongoDB 시작 시 --showms 서버 옵션으로 조정 할 수 있다.
		- ex) mongod --showms 50

#### 프로파일러 사용하여 느린 쿼리 찾기
 - 프로파일링은 디폴트 false 이므로 사용 가능 상태로 바꿔야 함
 - MongoDB 셀에서 아래와 같이 입력
~~~
	> use stocks
	> db.setProfilingLevel(2)
	{ "was" : 0, "slowms" : 100, "sampleRate" : 1, "ok" : 1 }
~~~
 - 프로파일링 하려는 데이터베이스를 먼저 선택. (프로파일링은 항상 특정 데이터베이스에 국한됨)
 - 데이터베이스를 선택한 다음에는 프로파일링 수준을 2로 지정.
	- 모든 읽기와 쓰기를 로그에 기록함.
	- 몇가지 다른 옵션도 가능. 
		- 느린 연산만을 로그로 남기기 위해서는 프로파일링 수준을 1로 지정하면됨.
		- 프로파일러를 사용하지 않으려면 0으로 지정하면 됨.
		- 어떤 임계값을 넘어서는 연산만을 로그로 기록하려면 아래 예제처럼 두 번째 옵션에 그 값을 지정한다.

~~~
	use stocks
	db.setProfilingLevel(1, 50)
~~~

 - 프로파일러를 사용 가능 상태로 바꿨으면 쿼리를 실행해본다. 

#### 주식 데이터에서 최고 종가를 찾기.
~~~
	> db.values.find({}).sort({close: -1}).limit(1)
	{ "_id" : ObjectId("4d094f69c96767d7a01a110d"), "exchange" : "NASDAQ", "stock_symbol" : "BORD", "date" : "2000-09-25", "open" : 7500, "high" : 7500, "low" : 7500, "close" : 7500, "volume" : 0, "adj close" : 6679.94 }
~~~

#### 프로파일링 결과
 - 명령을 실행한 데이터베이스에 system.profile 이라고 부르는 특수한 캡드(capped) 컬렉션에 저장된다.
 - 128kb 바ㄸ에 할당이 되지 않아 프로파일러가 리소스를 많이 사용하지 못한다.

> 쿼리 실행
~~~
	> db.system.profile.find().sort({$natural: -1}).limit(5).pretty()
 ... 대략적인 항목은 아래와 같음.
{
        "op" : "query",
        "ns" : "stocks.values",
        "command" : {
        ..... 생략
        },
        "keysExamined" : 0,
        "docsExamined" : 4308304, // 스캔된 도큐먼트 수 
        "hasSortStage" : true,
        "cursorExhausted" : true,
        "numYield" : 33658,
        "nreturned" : 1, // 반환된 도큐먼트 수 
        "queryHash" : "B0F07751",
        "planCacheKey" : "B0F07751",
        "locks" : {
			..... 생략
        },
        "flowControl" : {

        },
        "storage" : {

        },
        "responseLength" : 279, 
        "protocol" : "op_msg",
        "millis" : 7029, // 응답속도 (밀리초 단위)
        "planSummary" : "COLLSCAN",
        "execStats" : {
              ..... 생략
        },
        "ts" : ISODate("2019-12-06T07:56:17.274Z"),
        "client" : "127.0.0.1",
        "appName" : "MongoDB Shell",
        "allUsers" : [ ],
        "user" : ""
}

~~~
 - 위 쿼리는 실행시간이 7초나 됨. 
 - 프로파일링 전략에 대한 논의
	- 적당히 높은 값으로 시작해서 값을 점점 줄여 가면서 수행하는 방법. 처음에는 100밀리초보다 오래 걸리는 쿼리가 없는 것을 확인하고, 그 다음에는 75 밀리초로 낮추는 식.
	- 프로파일러가 사용 가능 상태로 있는 동안에도 애플리케이션이 원래대로 작동해야 함.
	- 애플리케이션이 제대로 작동하기 위해서는 데이터의 크기와 쿼리 로드, 하드웨어가 애플리케이션의 실제 서비스 환경과 동일한 실제 조건하에서 그러한 읽기와 쓰기가 수행되어야 함.
	
### 느린 쿼리 분석
 - 프로파일러를 사용하면 느린 쿼리를 쉽게 찾을 수 있으나 느린 이유를 발견하는 것은 까다롭고 몇 가지 추리력이 필요함.
 - 느린 쿼리의 이유는 다양함.
	- 운이 좋으면 인덱스만 추가해도 해결 가능.
	- 좀 더 어려운 경우는 인덱스를 재구성해야 한다던지 하드웨어를 업ㄷ그레이드 해야할지도 모름.
 - 가장 간단한 경우는 인덱스가 없거나 적합하지 않은 인덱스 문제임.
 - explain()을 실행해 봄으로써 확실한 것을 발견할 수 있음.

#### EXPLAIN() 의 사용과 이해

~~~
> db.values.find({}).sort({"close": -1}).limit(1).explain("executionStats")
{
        "queryPlanner" : {
                "plannerVersion" : 1,
                "namespace" : "stocks.values",
                "indexFilterSet" : false,
                "parsedQuery" : {

                },
                "queryHash" : "B0F07751",
                "planCacheKey" : "B0F07751",
                "winningPlan" : {
                        "stage" : "SORT",
                        "sortPattern" : {
                                "close" : -1
                        },
                        "limitAmount" : 1,
                        "inputStage" : {
                                "stage" : "SORT_KEY_GENERATOR",
                                "inputStage" : {
                                        "stage" : "COLLSCAN",
                                        "direction" : "forward"
                                }
                        }
                },
                "rejectedPlans" : [ ]
        },
        "executionStats" : {
                "executionSuccess" : true,
                "nReturned" : 1,
                "executionTimeMillis" : 5682,
                "totalKeysExamined" : 0,
                "totalDocsExamined" : 4308304, // 스캔된 수 
                "executionStages" : {
                        "stage" : "SORT",
                        "nReturned" : 1,
                        "executionTimeMillisEstimate" : 58,
                        "works" : 4308309,
                        "advanced" : 1,
                        "needTime" : 4308307,
                        "needYield" : 0,
                        "saveState" : 33658,
                        "restoreState" : 33658,
                        "isEOF" : 1,
                        "sortPattern" : {
                                "close" : -1
                        },
                        "memUsage" : 182,
                        "memLimit" : 33554432,
                        "limitAmount" : 1,
                        "inputStage" : {
                                "stage" : "SORT_KEY_GENERATOR",
                                "nReturned" : 4308304,
                                "executionTimeMillisEstimate" : 46,
                                "works" : 4308307,
                                "advanced" : 4308304,
                                "needTime" : 2,
                                "needYield" : 0,
                                "saveState" : 33658,
                                "restoreState" : 33658,
                                "isEOF" : 1,
                                "inputStage" : {
                                        "stage" : "COLLSCAN",
                                        "nReturned" : 4308304,
                                        "executionTimeMillisEstimate" : 7,
                                        "works" : 4308306,
                                        "advanced" : 4308304,
                                        "needTime" : 1,
                                        "needYield" : 0,
                                        "saveState" : 33658,
                                        "restoreState" : 33658,
                                        "isEOF" : 1,
                                        "direction" : "forward",
                                        "docsExamined" : 4308304
                                }
                        }
                }
        },
        "serverInfo" : {
                "host" : "gms-jmlim",
                "port" : 27017,
                "version" : "4.2.0",
                "gitVersion" : "a4b751dcf51dd249c5865812b390cfd1c0129c30"
        },
        "ok" : 1
}
~~~

#### 인덱스 추가 후 재시도
 - close 에 대한 인덱스를 만들고 다시 실행

~~~
	> db.values.createIndex({close: 1})
	{
			"createdCollectionAutomatically" : false,
			"numIndexesBefore" : 1,
			"numIndexesAfter" : 2,
			"ok" : 1
	}
	>
~~~
 - 쿼리 다시 수행
	- 1밀리초도 채 걸리지 않음을 확인 할 수 있음
	- 위에 결과와 비교해보면 확인히 차이가 남을 확인할 수 있음
~~~
> db.values.find({}).sort({"close": -1}).limit(1).explain("executionStats")
{
        "queryPlanner" : {
                "plannerVersion" : 1,
                "namespace" : "stocks.values",
                "indexFilterSet" : false,
                "parsedQuery" : {

                },
                "queryHash" : "B0F07751",
                "planCacheKey" : "B0F07751",
                "winningPlan" : {
                        "stage" : "LIMIT",
                        "limitAmount" : 1,
                        "inputStage" : {
                                "stage" : "FETCH",
                                "inputStage" : {
                                        "stage" : "IXSCAN",
                                        "keyPattern" : {
                                                "close" : 1
                                        },
                                        "indexName" : "close_1",
                                        "isMultiKey" : false,
                                        "multiKeyPaths" : {
                                                "close" : [ ]
                                        },
                                        "isUnique" : false,
                                        "isSparse" : false,
                                        "isPartial" : false,
                                        "indexVersion" : 2,
                                        "direction" : "backward",
                                        "indexBounds" : {
                                                "close" : [
                                                        "[MaxKey, MinKey]"
                                                ]
                                        }
                                }
                        }
                },
                "rejectedPlans" : [ ]
        },
        "executionStats" : {
                "executionSuccess" : true,
                "nReturned" : 1,
                "executionTimeMillis" : 2,
                "totalKeysExamined" : 1,
                "totalDocsExamined" : 1,
                "executionStages" : {
                        "stage" : "LIMIT",
                        "nReturned" : 1,
                        "executionTimeMillisEstimate" : 0,
                        "works" : 2,
                        "advanced" : 1,
                        "needTime" : 0,
                        "needYield" : 0,
                        "saveState" : 0,
                        "restoreState" : 0,
                        "isEOF" : 1,
                        "limitAmount" : 1,
                        "inputStage" : {
                                "stage" : "FETCH",
                                "nReturned" : 1,
                                "executionTimeMillisEstimate" : 0,
                                "works" : 1,
                                "advanced" : 1,
                                "needTime" : 0,
                                "needYield" : 0,
                                "saveState" : 0,
                                "restoreState" : 0,
                                "isEOF" : 0,
                                "docsExamined" : 1,
                                "alreadyHasObj" : 0,
                                "inputStage" : {
                                        "stage" : "IXSCAN",
                                        "nReturned" : 1,
                                        "executionTimeMillisEstimate" : 0,
                                        "works" : 1,
                                        "advanced" : 1,
                                        "needTime" : 0,
                                        "needYield" : 0,
                                        "saveState" : 0,
                                        "restoreState" : 0,
                                        "isEOF" : 0,
                                        "keyPattern" : {
                                                "close" : 1
                                        },
                                        "indexName" : "close_1",
                                        "isMultiKey" : false,
                                        "multiKeyPaths" : {
                                                "close" : [ ]
                                        },
                                        "isUnique" : false,
                                        "isSparse" : false,
                                        "isPartial" : false,
                                        "indexVersion" : 2,
                                        "direction" : "backward",
                                        "indexBounds" : {
                                                "close" : [
                                                        "[MaxKey, MinKey]"
                                                ]
                                        },
                                        "keysExamined" : 1,
                                        "seeks" : 1,
                                        "dupsTested" : 0,
                                        "dupsDropped" : 0
                                }
                        }
                }
        },
        "serverInfo" : {
                "host" : "gms-jmlim",
                "port" : 27017,
                "version" : "4.2.0",
                "gitVersion" : "a4b751dcf51dd249c5865812b390cfd1c0129c30"
        },
        "ok" : 1
}
>
~~~

#### MongoDB 쿼리 옵티마이저
 - 해당 쿼리를 가장 효율적으로 실행하기 위해 어떤 인덱스를 사용할지 결정하는 소프트웨어
 - 다음과 같이 아주 간단한 규칙 사용.
	 - scanAndOrder를 피함. 즉 쿼리가 정렬을 포함하고 있으면 인덱스를 사용한 정렬을 시도.
	 - 유용한 인덱스 제한 조건으로 모든 필드를 만족시킴. 즉, 쿼리 셀렉터에 지정된 필드에 대한 인덱스를 사용하려고 노력함.
	 - 쿼리가 범위를 내포하거나 정렬을 포함하면 마지막 키에 대해 범위나 정렬에 도움이 되는 인덱스를 선택.

## 요약
 - 인덱스는 매우 유용하지만 많은 비용을 수반하므로 쓰기가 느려짐.
 - 일반적으로 MongoDB는 쿼리에서 하나의 인덱스만 사용하므로 여러 필드의 쿼리는 복합 인덱스가 효율적일 것을 요구.
 - 복합 인덱스를 선언할 때 순서가 중요함.
 - 비용이 많이 드는 쿼리를 계획하되 피하는 것이 좋음. 
	- MongoDB의 explain 명령, 비용이 많이 드는 쿼리 로그 및 프로파일러를 사용하여 최적화된 쿼리를 찾는다.
 - MongoDB는 인덱스를 작성하는 몇 가지 명령을 제공하지만, 항상 비용이 들며 애플리케이션을 방해할 수 있음. 이는 프래픽이나 데이터가 많아지기 전에 쿼리를 최적화하고 인덱스를 조기에 만들어야 함을 뜻함.
 - 스캔한 도큐먼트 수를 줄임으로써 쿼리를 최적화한다. explain 명령은 쿼리가 하는 일을 발견하는데 매우 유용하다. 최적화를 지침으로 이를 사용하도록 하자.

 