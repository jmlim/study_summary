
## 몽고디비 설치 (도커)
~~~
mkdir /홈폴더/계정/data/docker/db/mongodb
docker run -d -p 27017:27017 -v /홈폴더/계정/data/docker/db/mongodb:/data/db --name mongodb mongo
docker exec -it mongodb /bin/bash
~~~

## 참고(도커 옵션)
~~~
--name : image 이름
-p, --publish : port {내부포트}:{외부포트} (tcp/udp 적지 않으면 기본은 tcp)
-d, --detach : detach의 약자로 백그라운드로 컨테이너를 실행
-v, --volume : 볼륨 바인드.
-i, --interactive : 입력이 된다. (상호작용)
-t, --tty : 로그 볼 때 사용(tty 사용)
~~~

참고자료링크 
 - https://qvil.github.io/docker/docker-mongo/