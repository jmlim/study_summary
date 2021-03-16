### 프로시저 호출 예제 (맨날 까먹어서 남김..ㅡ.ㅡ)

ex) 
~~~mysql
SET @aaa         = 1; // in
SET @bbb         = 1; // in
SET @ccc   = -1; // in
SET @ddd    = 1; // in
SET @eee      = 1; // in
SET @result      = 0; //out
SET @message     = '0'; //out

CALL 프로시저 ( @aaa  , @bbb , @ccc ,@ddd  , @eee ,@result  ,@message ) ;
SELECT @result , @message ;
~~~