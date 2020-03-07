
임정묵 <hackerljm@gmail.com>
오전 2:52 (0분 전)
나에게
 - 192.168.219.108 은 개인 리눅스 서버 사설 아이피
 - web은 8081
 - ssh 는 2202로 설치
 - 개인 홈 폴더에 /home/jmlim/dev/gitlab_compose/gitlab 폴더 생성.
 
명령어 : 
~~~
sudo docker run --detach \
  --hostname '192.168.219.108' \
  --env GITLAB_OMNIBUS_CONFIG="external_url 'http://192.168.219.108:8081'; gitlab_rails['gitlab_shell_ssh_port'] = 2202;" \
  --publish 443:443 --publish 8081:8081 --publish 2202:22 \
  --name gitlab \
  --restart always \
  --volume /home/jmlim/dev/gitlab_compose/gitlab/config:/etc/gitlab \
  --volume /home/jmlim/dev/gitlab_compose/gitlab/logs:/var/log/gitlab \
  --volume /home/jmlim/dev/gitlab_compose/gitlab/data:/var/opt/gitlab \
  gitlab/gitlab-ce:latest
~~~

docker-compose.yml 파일로 설치 시 
~~~yaml
web:
  image: 'gitlab/gitlab-ce:latest'
  restart: always
  container_name: 'gitlab'
  hostname: '192.168.219.108'
  environment:
    GITLAB_OMNIBUS_CONFIG: |
      external_url 'http://192.168.219.108:8081'
      gitlab_rails['gitlab_shell_ssh_port'] = 2202
  ports:
    - '8081:8081'
    - '2202:22'
  volumes:
    - '/home/jmlim/dev/gitlab_compose/gitlab/config:/etc/gitlab'
    - '/home/jmlim/dev/gitlab_compose/gitlab/logs:/var/log/gitlab'
    - '/home/jmlim/dev/gitlab_compose/gitlab/data:/var/opt/gitlab'
~~~

docker log -f gitlab 에서 로그 확인

로드 완료 시 웹 페이지 접근(http://192.168.219.108:8081) 후 root 비번 설정
 - 계정 root 
 
> 계정생성 후 ssh key 등록 후에 프로젝트 업로드 정상 확인완료.