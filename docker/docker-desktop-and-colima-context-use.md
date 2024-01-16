colima와 docker desktop을 번갈아가며 사용 시 변경하며 사용할 때가 많은데 그때 어떤걸 사용하는지 확인하는 명령어이다. 

- 이렇게 도커 데스크탑이 켜져있는데도 기본 설정이 colima 로 잡혀있어 컨테이너가 나오지 않음.
~~~
% docker ps -a
Cannot connect to the Docker daemon at unix:///Users/jmlim/.colima/default/docker.sock. Is the docker daemon running?
~~~

- 아래와 같이 어떤 도커를 쓰고 있는지 확인
~~~
 % ~ % docker context ls
NAME                TYPE                DESCRIPTION                               DOCKER ENDPOINT                                      KUBERNETES ENDPOINT                                                                       ORCHESTRATOR
colima *            moby                colima                                    unix:///Users/jmlim/.colima/default/docker.sock
default             moby                Current DOCKER_HOST based configuration   unix:///var/run/docker.sock                          https://냠냠냠.eks.amazonaws.com (default)   swarm
desktop-linux       moby                                                          unix:///Users/jmlim/.docker/run/docker.sock
~~~

- 아래와 같이 도커 설정을 desktop-linux로 바꾸고 다시 조회해본가. 
~~~
$ docker context use desktop-linux
~~~

~~~
% ~ % docker context ls
NAME                TYPE                DESCRIPTION                               DOCKER ENDPOINT                                      KUBERNETES ENDPOINT                                                                       ORCHESTRATOR
colima *            moby                colima                                    unix:///Users/jmlim/.colima/default/docker.sock
default             moby                Current DOCKER_HOST based configuration   unix:///var/run/docker.sock                          https://냠냠냠.eks.amazonaws.com (default)   swarm
desktop-linux       moby                                                          unix:///Users/jmlim/.docker/run/docker.sock

➜  ~ docker ps -a
CONTAINER ID   IMAGE          COMMAND                  CREATED         STATUS                      PORTS                                      NAMES
5bdec0a28589   nginx          "/docker-entrypoint.…"   5 months ago    Exited (255) 2 months ago   0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp   local-docker-jmlim
c6954c6df827   redis:latest   "docker-entrypoint.s…"   5 months ago    Up About a minute           0.0.0.0:6379->6379/tcp                     redis_test
~~~

- 출처 : https://velog.io/@oamullu/docker-desktop-and-colima