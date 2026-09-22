
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

- upstream은 강의 상류를 의미.
     - 즉 위에서 아래로 뿌려주는 것을 의미한다. 반대는 downstream.
     - 위에서는 해당 nginx가 여러 서버에 분배해 주므로 upstream 서버라고 부를 수 있다.


#### 로드밸런스는 부하(Load)를, 즉 접속자를 분산해서 고루고루 보내주는데 어떻게 분배할지 규칙을 알아야 함.
 - Load balancing methods(부하 부산 규칙)
~~~
round-robin(디폴트) - 돌아가면서 분배.
hash - 해시한 값으로 분배한다 쓰려면 hash <키> 형태로 씀. ex)hash $remote_addr <- 이는 ip_hash와 같음.
ip_hash - 아이피로 해싱해서 분배.
random - 랜덤으로 분배.
least_conn - 연결수가 가장 적은 서버를 선택해서 분배, 가중치 고려.
least_time - 연결수가 가장 적으면서 평균 응답시간이 가장 적은 쪽을 선택해서 분배.
~~~

#### 아래와 같이 파라미터를 사용하여 가중치를 줄 수도 있음
~~~
upstream myserver {
    server 10.30.175.15:8180 weight=2;
    server 10.30.175.15:8280;
    server 10.30.175.15:8380;
}
~~~

- Parameter
~~~
weight - 가중치를 둬서 더많이 가게 함.
max_conns - 최대 연결 한계를 정함.
max_fails - 최대 실패 한계를 정함. 최대 실패횟수에 도달하면 서버가 죽은것으로 간주.
fail_timeout - 시간을 정함. 이 시간을 넘어서도 응답하지 않으면 서버가 죽은것으로 간주.
backup - 이 서버는 백업서버로 간주하고 다른 메인 서버가 죽었을때 동작. load balancing methods가 hash나 random 일때는 무의미.
down - 표시한 서버는 사용치 않는다.
~~~

### 헬스 체크 (죽은 서버 자동 제외)
- nginx 오픈소스 버전은 별도 모듈 없이도 `max_fails` / `fail_timeout` 조합으로 **수동적(passive) 헬스체크**가 가능하다 (위에서 다룬 파라미터가 바로 이것).
    - 요청이 실제로 실패해야 감지하는 방식이라, 트래픽이 뜸한 서버는 죽어도 늦게 감지될 수 있음.
- 진짜 "능동적(active) 헬스체크"(주기적으로 ping 날려서 살았는지 확인)는 nginx **plus**(유료) 또는 오픈소스 nginx에서는 `nginx_upstream_check_module` 같은 서드파티 모듈을 컴파일해 넣어야 한다.
- 쿠버네티스/ALB 환경으로 넘어가면 이 역할은 보통 nginx 대신 로드밸런서나 오케스트레이터의 livenessProbe/healthcheck 가 담당하게 됨 — 최신 인프라에서는 nginx를 직접 이렇게 쓰는 대신 Ingress Controller로 감싸는 경우가 많다.

### 세션 유지 (Sticky session)
- 라운드로빈으로 요청을 분산하면 같은 사용자의 요청이 매번 다른 서버로 갈 수 있음. 서버가 세션을 메모리에 들고 있는 구조(WAS 세션)라면 로그인이 풀리는 등 문제가 생김.
- 해결 방법
    1. **ip_hash** — 같은 클라이언트 IP는 항상 같은 서버로 보냄. 간단하지만 NAT 뒤에 여러 사용자가 몰려있으면 분산이 안 될 수 있음.
    2. **세션을 외부 저장소로 분리** — 근본적인 해결책. WAS 자체 세션 대신 Redis 같은 외부 스토어에 세션을 저장하면 어느 서버로 가든 상관없어짐. (블로그의 `spring-session-redis.md` 글이 바로 이 방식.)
    3. `sticky` 지시자 — nginx **plus** 전용 기능(오픈소스에는 없음).
- 실무에서는 대부분 **2번(세션 외부화)**을 정답으로 취급한다. 로드밸런서에 sticky 로직을 넣는 건 임시방편에 가깝고, 서버를 무중단으로 늘리거나 줄이는(오토스케일링) 순간 다시 문제가 됨.

### HTTPS 종료(TLS Termination)
- 여러 대의 WAS 각각에 인증서를 넣는 대신, nginx(로드밸런서) 한 곳에서만 HTTPS를 처리하고 내부적으로는 HTTP로 WAS와 통신하는 구조가 일반적.
~~~
server {
    listen 443 ssl;
    server_name example.com;

    ssl_certificate     /etc/nginx/ssl/example.com.crt;
    ssl_certificate_key /etc/nginx/ssl/example.com.key;

    location / {
        proxy_pass http://myserver;              # 내부는 http
        proxy_set_header X-Forwarded-Proto https; # WAS 쪽에서 원래 요청이 https였음을 알 수 있도록
        proxy_set_header X-Real-IP $remote_addr;  # 블로그의 X-Forwarded-For 글과 연결되는 부분
    }
}
~~~
- 이렇게 하면 인증서 관리 지점이 하나로 줄고, WAS는 TLS 부담 없이 순수 애플리케이션 로직에만 집중할 수 있음.

### 정적 리소스 캐싱
~~~
location ~* \.(jpg|jpeg|png|gif|css|js)$ {
    expires 30d;
    add_header Cache-Control "public, immutable";
}
~~~
- 이미지/CSS/JS 처럼 자주 안 바뀌는 정적 파일은 nginx 단에서 캐시 헤더를 붙여 브라우저/CDN이 재요청하지 않도록 하는 것이 트래픽 절감에 큰 영향을 준다.

출처 : https://kamang-it.tistory.com/m/entry/WebServernginxnginx%EB%A1%9C-%EB%A1%9C%EB%93%9C%EB%B0%B8%EB%9F%B0%EC%8B%B1-%ED%95%98%EA%B8%B0

---

## 다음 학습 주제
- Spring Session + Redis (블로그 [spring-session-redis](http://jmlim.github.io/spring/2018/11/30/spring-session-redis/)) — sticky session 대신 세션을 외부화하는 실전 구현
- Kubernetes Ingress / Service — nginx로 직접 하던 로드밸런싱·헬스체크가 클러스터 환경에서는 어떻게 대체되는지
- TLS 핸드셰이크 동작 원리 — HTTPS 종료를 그냥 설정으로만 알고 넘어가지 않고, 왜 종료 지점을 하나로 모으는 게 성능에 유리한지 원리 이해
