
# 맥에서 nginx 설치 및 설정 그리고 로드밸런싱

- setup : brew install nginx 
- 시작 : nginx
- 중지 : nginx -s stop
- 재시작 : nginx -s reload
- 환경 설정 : vi /usr/local/etc/nginx/nginx.conf

### 설치
~~~
adminui-iMac:~ jmlim$ brew install nginx
Updating Homebrew...
==> Auto-updated Homebrew!
Updated 3 taps (homebrew/core, homebrew/cask and homebrew/services).
==> New Formulae
...
...
...

==> Installing dependencies for nginx: openssl@1.1 and pcre
==> Installing nginx dependency: openssl@1.1
==> Downloading https://homebrew.bintray.com/bottles/openssl@1.1-1.1.1d.mojave.bottle.tar.gz
==> Downloading from https://akamai.bintray.com/10/104ef018b7bb8fcc49f57e5a60359a28a02d480d85a959e6141394b0571cbb28?__gda__=exp=1581986035~hmac=557c3f22b0e566639c0c13b0553a7c7c9807ffb6287f3ebccf8e2f5b2c076dfd&response-content-dispositi
######################################################################## 100.0%
.....
.....
==> nginx
Docroot is: /usr/local/var/www

The default port has been set in /usr/local/etc/nginx/nginx.conf to 8080 so that
nginx can run without sudo.

nginx will load all files in /usr/local/etc/nginx/servers/.

To have launchd start nginx now and restart at login:
  brew services start nginx
Or, if you don't want/need a background service you can just run:
  nginx
adminui-iMac:~ jmlim$
~~~

#### 맥에서 nginx 실행 시 기본 포트 8080으로 설정 됨

### 로드밸런싱 설정

사용자가 늘어서 서버 두대 이상을 사용해야 할 경우 필요
 - nginx를 앞에 두고 서버를 nginx에 연결하는 방식으로 만들어볼 수 있음.
    - 즉 nginx는 요청을 받아 WAS 에 중계해주는 역할을 할 수 있음.
    - 로드밸런서

### vi /usr/local/etc/nginx/nginx.conf 열기
 - http 그룹 안의 설정 추가 및 수정.

~~~
http {
    ...생략 ...
    ## 추가 
    upstream myserver {
        server 10.30.175.15:8180;
        server 10.30.175.15:8280;
        server 10.30.175.15:8380;
    }
    ...

    server {
        ...
            listen       80;
            server_name  localhost;
            ## 수정 (서버의 location에서 로드밸런싱할 url을 선택. 그 후 proxy_pass에 붙여주면 됨.)
            location / {
                proxy_pass http://myserver;
            }
            ...
            생략
            ...
    }
}
~~~

> 수정 후 nginx -s reload 로 재시작.

### upstream 
 - 예시 
~~~

upstream <업스트림 이름> {
    <로드밸런스 타입: defulat는 round-robin>
    server <host1>:<port1>
    ...
    server <host2>:<port2>
}
~~~

#### upstream은 강의 상류를 의미.
 - 즉 위에서 아래로 뿌려주는 것을 의미한다. 반대는 downstream.
 - 위에서는 해당 nginx가 여러 서버에 분배해 주므로 upstream 서버라고 부를 수 있다.


#### 로드밸런스는 부하(Load)를, 즉 접속자를 분산해서 고루고루 보내주는데 어떻게 분배할지 규칙을 알아야 함.

~~~
Load balancing methods(부하 부산 규칙)

round-robin(디폴트) - 돌아가면서 분배.
hash - 해시한 값으로 분배한다 쓰려면 hash <키> 형태로 씀. ex)hash $remote_addr <- 이는 ip_hash와 같음.
ip_hash - 아이피로 해싱해서 분배.
random - 랜덤으로 분배.
least_conn - 연결수가 가장 적은 서버를 선택해서 분배, 가중치 고려.
least_time - 연결수가 가장 적으면서 평균 응답시간이 가장 적은 쪽을 선택해서 분배.
~~~

#### 아래와 같이 파라미터를 사용하여 가중치를 줄 수 있음
~~~
    upstream myserver {
        server 10.30.175.15:8180 weight=2;
        server 10.30.175.15:8280;
        server 10.30.175.15:8380;
    }
~~~

~~~
Parameter

weight - 가중치를 둬서 더많이 가게 함.
max_conns - 최대 연결 한계를 정함.
max_fails - 최대 실패 한계를 정함. 최대 실패횟수에 도달하면 서버가 죽은것으로 간주.
fail_timeout - 시간을 정함. 이 시간을 넘어서도 응답하지 않으면 서버가 죽은것으로 간주.
backup - 이 서버는 백업서버로 간주하고 다른 메인 서버가 죽었을때 동작. load balancing methods가 hash나 random 일때는 무의미.
down - 표시한 서버는 사용치 않는다.
~~~

작성중..

출처 : https://kamang-it.tistory.com/m/entry/WebServernginxnginx%EB%A1%9C-%EB%A1%9C%EB%93%9C%EB%B0%B8%EB%9F%B0%EC%8B%B1-%ED%95%98%EA%B8%B0
