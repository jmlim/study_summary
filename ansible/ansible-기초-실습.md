출처 : https://www.udemy.com/course/using_ansible_for_simple_configuration/

> 가상머신(virtualbox)을 통해 centos 설치 후 4개 띄운 후 아래 내용 실습
 - 1개는 ansible 명령어를 실행할 server 로 사용
 - 나머지 3개는 타겟서버 
    - 패스워드는 동일하게 설정.

~~~
yum repolist
yum install epel-release -y
yum install ansible -y
~~~
### 작성한 /etc/ansible/hosts 파일 내용.
~~~
[nginx]
192.168.219.11
192.168.219.12
192.168.219.13
~~~

## 1. 앤서블의 구성파일
 - 참조 파일들

### 1.1. /etc/ansible/ansible.cfg
 - 환경설정파일

### 1.2. /etc/ansible/hosts
 - 앤서블이 접속하는 호스트들에 대한 정보

## 2. 앤서블 실행 시 옵션 값
 - i : (--inventory-file) 적용될 호스트들에 대한 파일
 - m : (--module-name) 모듈을 선택할 수 있도록
 - k : (--ask-pass) 패스워드를 물어보도록 설정
 - K : (--ask-become-pass) 권리자로 권한 상승
 --list-hosts : 적용되는 호스트들을 확인

### 2.1. 옵션 -i 사용 예제
 - test 파일 만들어서 사용
~~~
#vi test
...
192.168.219.11
192.168.219.12

:wq 로 저장
...

[root@Ansible-Server ~]# ansible all -i ~/test -m ping -k
SSH password:
192.168.219.12 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "ping": "pong"
}
192.168.219.11 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "ping": "pong"
}

[root@Ansible-Server ~]# ansible nginx -m ping -k
SSH password:
192.168.219.11 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "ping": "pong"
}
192.168.219.12 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "ping": "pong"
}
192.168.219.13 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "ping": "pong"
}
~~~

### 2.2. 영향받는 호스트를 알 고 싶을 경우 확인 명령어
 - ansible nginx -m ping --list-hosts
 - ansible all -i test -m ping --list-hosts
~~~
[root@Ansible-Server ~]# ansible nginx -m ping --list-hosts
  hosts (3):
    192.168.219.11
    192.168.219.12
    192.168.219.13

[root@Ansible-Server ~]# ansible all -i test -m ping --list-hosts
  hosts (2):
    192.168.219.11
    192.168.219.12
~~~

## 3. 한 번의 명령어로 다수의 시스템에 작업하기.
### 3.1. uptime 확인하기.
 -  ansible all -m shell -a "uptime" -k
~~~
[root@Ansible-Server ~]#  ansible all -m shell -a "uptime" -k
[root@Ansible-Server ~]# ansible all -m shell -a "uptime" -k
SSH password:
192.168.219.13 | CHANGED | rc=0 >>
 02:00:42 up  1:40,  2 users,  load average: 0.00, 0.01, 0.02

192.168.219.12 | CHANGED | rc=0 >>
 02:00:42 up  1:40,  2 users,  load average: 0.16, 0.05, 0.06

192.168.219.11 | CHANGED | rc=0 >>
 02:00:42 up  1:40,  2 users,  load average: 0.00, 0.01, 0.03
~~~

### 3.2. 디스크 용량 확인하기.
 - ansible all -m shell -a "df -h" -k
~~~
[root@Ansible-Server ~]# ansible all -m shell -a "df -h" -k
SSH password:
192.168.219.13 | CHANGED | rc=0 >>
Filesystem               Size  Used Avail Use% Mounted on
devtmpfs                 232M     0  232M   0% /dev
tmpfs                    244M     0  244M   0% /dev/shm
tmpfs                    244M  4.6M  240M   2% /run
tmpfs                    244M     0  244M   0% /sys/fs/cgroup
/dev/mapper/centos-root   50G  1.2G   49G   3% /
/dev/sda1               1014M  136M  879M  14% /boot
/dev/mapper/centos-home   43G   33M   43G   1% /home
tmpfs                     49M     0   49M   0% /run/user/0

192.168.219.12 | CHANGED | rc=0 >>
Filesystem               Size  Used Avail Use% Mounted on
devtmpfs                 232M     0  232M   0% /dev
tmpfs                    244M     0  244M   0% /dev/shm
tmpfs                    244M  4.6M  240M   2% /run
tmpfs                    244M     0  244M   0% /sys/fs/cgroup
/dev/mapper/centos-root   50G  1.2G   49G   3% /
/dev/mapper/centos-home   43G   33M   43G   1% /home
/dev/sda1               1014M  136M  879M  14% /boot
tmpfs                     49M     0   49M   0% /run/user/0

192.168.219.11 | CHANGED | rc=0 >>
Filesystem               Size  Used Avail Use% Mounted on
devtmpfs                 232M     0  232M   0% /dev
tmpfs                    244M     0  244M   0% /dev/shm
tmpfs                    244M  4.5M  240M   2% /run
tmpfs                    244M     0  244M   0% /sys/fs/cgroup
/dev/mapper/centos-root   50G  1.2G   49G   3% /
/dev/mapper/centos-home   43G   33M   43G   1% /home
/dev/sda1               1014M  136M  879M  14% /boot
tmpfs                     49M     0   49M   0% /run/user/0

~~~

### 3.3. 메모리 상태 확인하기.
 - ansible all -m shell -a "free -h" -k
~~~
[root@Ansible-Server ~]# ansible all -m shell -a "free -h" -k
SSH password:
192.168.219.11 | CHANGED | rc=0 >>
              total        used        free      shared  buff/cache   available
Mem:           487M        114M        256M        4.5M        116M        354M
Swap:          2.0G          0B        2.0G

192.168.219.12 | CHANGED | rc=0 >>
              total        used        free      shared  buff/cache   available
Mem:           487M        114M        256M        4.5M        116M        354M
Swap:          2.0G          0B        2.0G

192.168.219.13 | CHANGED | rc=0 >>
              total        used        free      shared  buff/cache   available
Mem:           487M        115M        255M        4.5M        116M        354M
Swap:          2.0G          0B        2.0G
~~~

### 3.4. 새로운 유저 만들기.
 -  ansible all -m user -a "name=jmlim password=1234" -k
~~~
[root@Ansible-Server ~]#  ansible all -m user -a "name=jmlim password=1234" -k
SSH password:
[WARNING]: The input password appears not to have been hashed. The 'password'
argument must be encrypted for this module to work properly.

192.168.219.11 | CHANGED => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": true,
    "comment": "",
    "create_home": true,
    "group": 1000,
    "home": "/home/jmlim",
    "name": "jmlim",
    "password": "NOT_LOGGING_PASSWORD",
    "shell": "/bin/bash",
    "state": "present",
    "system": false,
    "uid": 1000
}
192.168.219.13 | CHANGED => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": true,
    "comment": "",
    "create_home": true,
    "group": 1000,
    "home": "/home/jmlim",
    "name": "jmlim",
    "password": "NOT_LOGGING_PASSWORD",
    "shell": "/bin/bash",
    "state": "present",
    "system": false,
    "uid": 1000
}
192.168.219.12 | CHANGED => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": true,
    "comment": "",
    "create_home": true,
    "group": 1000,
    "home": "/home/jmlim",
    "name": "jmlim",
    "password": "NOT_LOGGING_PASSWORD",
    "shell": "/bin/bash",
    "state": "present",
    "system": false,
    "uid": 1000
}
~~~

#### 3.4.1. user 가 생성된 것을 확인
 - cat /etc/passwd
~~~
[root@Ansible-Server ~]# ssh root@192.168.219.11
root@192.168.219.11's password:
Last login: Sat Feb  8 02:06:16 2020 from 192.168.219.10

[root@Ansible-node01 ~]# cat /etc/passwd
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/bin:/sbin/nologin
daemon:x:2:2:daemon:/sbin:/sbin/nologin
adm:x:3:4:adm:/var/adm:/sbin/nologin
lp:x:4:7:lp:/var/spool/lpd:/sbin/nologin
sync:x:5:0:sync:/sbin:/bin/sync
shutdown:x:6:0:shutdown:/sbin:/sbin/shutdown
halt:x:7:0:halt:/sbin:/sbin/halt
mail:x:8:12:mail:/var/spool/mail:/sbin/nologin
operator:x:11:0:operator:/root:/sbin/nologin
games:x:12:100:games:/usr/games:/sbin/nologin
ftp:x:14:50:FTP User:/var/ftp:/sbin/nologin
nobody:x:99:99:Nobody:/:/sbin/nologin
systemd-network:x:192:192:systemd Network Management:/:/sbin/nologin
dbus:x:81:81:System message bus:/:/sbin/nologin
polkitd:x:999:998:User for polkitd:/:/sbin/nologin
sshd:x:74:74:Privilege-separated SSH:/var/empty/sshd:/sbin/nologin
postfix:x:89:89::/var/spool/postfix:/sbin/nologin
chrony:x:998:996::/var/lib/chrony:/sbin/nologin
jmlim:x:1000:1000::/home/jmlim:/bin/bash <---- 생성된 것을 확인

~~~


### 3.5. 파일 전송하기.
 - touch jmlim.file // 파일 생성.
 - ansible nginx -m copy -a "src=./jmlim.file dest=/tmp/" -k
~~~
[root@Ansible-Server ~]# touch jmlim.file // 파일 생성.
[root@Ansible-Server ~]# ansible nginx -m copy -a "src=./jmlim.file dest=/tmp/" -k
SSH password:
192.168.219.13 | CHANGED => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": true,
    "checksum": "da39a3ee5e6b4b0d3255bfef95601890afd80709",
    "dest": "/tmp/jmlim.file",
    "gid": 0,
    "group": "root",
    "md5sum": "d41d8cd98f00b204e9800998ecf8427e",
    "mode": "0644",
    "owner": "root",
    "secontext": "unconfined_u:object_r:admin_home_t:s0",
    "size": 0,
    "src": "/root/.ansible/tmp/ansible-tmp-1581145973.76-70475437766578/source",
    "state": "file",
    "uid": 0
}
192.168.219.11 | CHANGED => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": true,
    "checksum": "da39a3ee5e6b4b0d3255bfef95601890afd80709",
    "dest": "/tmp/jmlim.file",
    "gid": 0,
    "group": "root",
    "md5sum": "d41d8cd98f00b204e9800998ecf8427e",
    "mode": "0644",
    "owner": "root",
    "secontext": "unconfined_u:object_r:admin_home_t:s0",
    "size": 0,
    "src": "/root/.ansible/tmp/ansible-tmp-1581145973.75-94621080027194/source",
    "state": "file",
    "uid": 0
}
192.168.219.12 | CHANGED => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": true,
    "checksum": "da39a3ee5e6b4b0d3255bfef95601890afd80709",
    "dest": "/tmp/jmlim.file",
    "gid": 0,
    "group": "root",
    "md5sum": "d41d8cd98f00b204e9800998ecf8427e",
    "mode": "0644",
    "owner": "root",
    "secontext": "unconfined_u:object_r:admin_home_t:s0",
    "size": 0,
    "src": "/root/.ansible/tmp/ansible-tmp-1581145973.75-882534426965/source",
    "state": "file",
    "uid": 0
}
~~~

#### 3.5.1. 파일 확인.
 - ls -rlt /tmp
~~~
# ssh root@192.168.219.11
root@192.168.219.11's password:
Last login: Sat Feb  8 02:06:16 2020 from 192.168.219.10

[root@Ansible-node01 ~]# ls -rlt /tmp
total 4
-rw-------. 1 root root   0 Feb  8 00:09 yum.log
-rwx------. 1 root root 836 Feb  8 00:14 ks-script-c1GqRK
drwx------. 3 root root  17 Feb  8 00:20 systemd-private-02254e02a5684898becb9c603444a898-chronyd.service-0IEn7Z
-rw-r--r--. 1 root root   0 Feb  8 02:12 jmlim.file
~~~

### 3.6. 서비스 설치.
 - 타겟 서버에 dns namespace 가 없다고 가정하고 파일부터 복사.
~~~
# ansible nginx -m copy -a "src=/etc/resolv.conf dest=/etc/resolv.conf" -k
SSH password: 
# ansible nginx -m yum -a "name=httpd state=present" -k
~~~



### 4. 플레이북 (PlayBook)
- 각본, 작전, 계획

- 예) 대량의 서버에 웹 서비스를 설치 및 기동해야 할 때?
    - nginx 플레이 북으로 설치
        1. 설치
        2. 파일전송
        3. 서비스 재시작
    - 이 모든 과정을 하나의 앤서블 플레이북으로 설치 가능
    - 한번 실행하면 위 과정 모두 실행
        - 플레이북은 멱등성이 있어 여러번 적용하더라도 결과가 달라지지 않는다.
- 예 
~~~
[root@Ansible-Server ~]# echo -e "[jmlim]\n192.168.219.13" >> /etc/ansible/hosts
~~~
- 이렇게 할 경우 실행하는 만큼 계속 적용됨.
- 하지만 플레이북으로 적용한다면 여러번 적용해도 한번만 실행한 것 처럼 결과가 달라지지 않음.

### 4.1. playbook 예제 
 - jmlim-playbook.yml
~~~
 - name: Ansible_vim
   hosts: localhost

   tasks:
    - name: Add ansible hosts
      blockinfile:
          path: /etc/ansible/hosts
          block: |
             [jmlim-node-ip]
             192.168.219.13
~~~
- 저장 후 위 플레이북 파일 실행
    -  ansible-playbook jmlim-playbook.yml
~~~
[root@Ansible-Server ~]#  ansible-playbook jmlim-playbook.yml

PLAY [Ansible_vim] *************************************************************

TASK [Gathering Facts] *********************************************************
ok: [localhost]

TASK [Add ansible hosts] *******************************************************
changed: [localhost]

PLAY RECAP *********************************************************************
localhost                  : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

....
~~~

- 실행 후 /etc/ansible/hosts 파일 확인
~~~
....

## db-[99:101]-node.example.com
[nginx]
192.168.219.11
192.168.219.12
192.168.219.13
# BEGIN ANSIBLE MANAGED BLOCK
[jmlim-node-ip]
192.168.219.13
# END ANSIBLE MANAGED BLOCK

~~~
 - 재 실행 시 맨 마지막 changed=0 으로 확인되고  /etc/ansible/hosts 파일은 바뀌지 않음
~~~

PLAY [Ansible_vim] *************************************************************

TASK [Gathering Facts] *********************************************************
ok: [localhost]

TASK [Add ansible hosts] *******************************************************
ok: [localhost]

PLAY RECAP *********************************************************************
localhost                  : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
~~~

 - jmlim-playbook.yml 구문 분석
~~~
 - name: Ansible_vim # 파일에 대한 이름
   hosts: localhost  # 실행될 곳( localhost 즉 자기 자신)

   tasks:
    - name: Add ansible hosts # 작업의 이름
      blockinfile: # 모듈의 이름 ( 특정 파일의 블럭을 등록할 시 사용. )
          path: /etc/ansible/hosts
          block: |  # 블럭을 기록하는 시작 포인트. 시작은 | 에서부터, 끝은 지정하지 않음.
             [jmlim-node-ip]
             192.168.219.13
~~~

### 4.2 데모 : 플레이북을 통해 3대의 노드들에 웹 서비스를 설치 및 기동

#### 4.2.1. jmlim-nginx.yml 작성.

~~~

--- 
- hosts: nginx
  remote_user: root
  tasks: 
    - name: install epel-release
      yum: name=epel-release state=latest
    - name: install nginx web server
      yum: name=nginx state=present
    - name: Start nginx web server
      service: name=nginx state=started
~~~

#### 4.2.2.  저장 후 플레이북 파일 실행
 - ansible-playbook jmlim-nginx.yml -k
~~~
[root@Ansible-Server ~]# ansible-playbook jmlim-nginx.yml -k
SSH password:
[DEPRECATION WARNING]: The TRANSFORM_INVALID_GROUP_CHARS settings is set to
allow bad characters in group names by default, this will change, but still be
user configurable on deprecation. This feature will be removed in version 2.10.
 Deprecation warnings can be disabled by setting deprecation_warnings=False in
ansible.cfg.
[WARNING]: Invalid characters were found in group names but not replaced, use
-vvvv to see details


PLAY [nginx] *******************************************************************

TASK [Gathering Facts] *********************************************************
ok: [192.168.219.11]
ok: [192.168.219.13]
ok: [192.168.219.12]

TASK [install epel-release] ****************************************************
changed: [192.168.219.11]
changed: [192.168.219.12]
changed: [192.168.219.13]

TASK [install nginx web server] ************************************************
changed: [192.168.219.13]
changed: [192.168.219.11]
changed: [192.168.219.12]

TASK [Start nginx web server] **************************************************
changed: [192.168.219.11]
changed: [192.168.219.12]
changed: [192.168.219.13]

PLAY RECAP *********************************************************************
192.168.219.11             : ok=4    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
192.168.219.12             : ok=4    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
192.168.219.13             : ok=4    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

~~~

#### 4.2.3. 서비스가 올라왔는지 확인하기.
 - systemctl status nginx
~~~
[root@Ansible-Server ~]# ssh root@192.168.219.11
root@192.168.219.11's password:
Last login: Sat Feb 15 08:11:52 2020 from 192.168.219.10
[root@ansible-node01 ~]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Sat 2020-02-15 08:11:53 EST; 4min 9s ago
  Process: 1595 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 1592 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 1591 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
   CGroup: /system.slice/nginx.service
           ├─1597 nginx: master process /usr/sbin/nginx
           └─1599 nginx: worker process

Feb 15 08:11:53 ansible-node01 systemd[1]: Starting The nginx HTTP and rever....
Feb 15 08:11:53 ansible-node01 nginx[1592]: nginx: the configuration file /e...k
Feb 15 08:11:53 ansible-node01 nginx[1592]: nginx: configuration file /etc/n...l
Feb 15 08:11:53 ansible-node01 systemd[1]: Failed to parse PID from file /ru...s
Feb 15 08:11:53 ansible-node01 systemd[1]: Started The nginx HTTP and revers....
Hint: Some lines were ellipsized, use -l to show in full.

~~~

#### 4.2.4. 방화벽 해제
 - 방화벽 살아있는지 확인
    - systemctl status firewalld
~~~
[root@ansible-node01 ~]# systemctl status firewalld
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; vendor preset: enabled)
   Active: active (running) since Sat 2020-02-15 07:27:38 EST; 49min ago
     Docs: man:firewalld(1)
 Main PID: 694 (firewalld)
   CGroup: /system.slice/firewalld.service
           └─694 /usr/bin/python2 -Es /usr/sbin/firewalld --nofork --nopid

Feb 15 07:27:37 ansible-node01 systemd[1]: Starting firewalld - dynamic fire....
Feb 15 07:27:38 ansible-node01 systemd[1]: Started firewalld - dynamic firew....
Hint: Some lines were ellipsized, use -l to show in full.
~~~
 - 기본적으로 방화벽 정책을 세밀하게 수정해야 하지만 일단 테스트를 하기위해 방화벽을 내림.
 - 직접들어가서 하는것은 이 강의와 맞지 않으므로 Ansible-Server로 이동하여 앤서블 명령어로 실행

~~~
[root@Ansible-Server ~]# ansible nginx -m shell -a "systemctl stop firewalld" -k
SSH password:
[DEPRECATION WARNING]: The TRANSFORM_INVALID_GROUP_CHARS settings is set to
allow bad characters in group names by default, this will change, but still be
user configurable on deprecation. This feature will be removed in version 2.10.
 Deprecation warnings can be disabled by setting deprecation_warnings=False in
ansible.cfg.
[WARNING]: Invalid characters were found in group names but not replaced, use
-vvvv to see details

192.168.219.11 | CHANGED | rc=0 >>


192.168.219.12 | CHANGED | rc=0 >>


192.168.219.13 | CHANGED | rc=0 >>
~~~

#### 4.2.5. 페이지 교체
 - 메인페이지 인덱스 파일로 다운로드
    - curl -o index.html https://www.nginx.com

~~~
[root@Ansible-Server ~]# curl -o index.html https://www.nginx.com
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 74441    0 74441    0     0  48616      0 --:--:--  0:00:01 --:--:-- 48590

~~~

 - jmlim-nginx.yml 파일 수정.
~~~

---
- hosts: nginx
  remote_user: root
  tasks: 
    - name: install epel-release
      yum: name=epel-release state=latest
    - name: install nginx web server
      yum: name=nginx state=present
    - name: Upload default index.html for web server
      copy: src=index.html dest=/usr/share/nginx/html/ mode=0644
    - name: Start nginx web server
      service: name=nginx state=started
~~~

 - ansible-playbook 으로 수정한 파일 실행
    - ansible-playbook jmlim-nginx.yml
~~~
[root@Ansible-Server ~]# ansible-playbook jmlim-nginx.yml

.....
.....

~~~

 - jmlim-nginx.yml  코드 분석
~~~

---
- hosts: nginx # 실행할 호스트의 블록 # (블록명 nginx 에 아이피 3개 등록함.)
  remote_user: root
  tasks: 
    - name: install epel-release
      yum: name=epel-release state=latest
    - name: install nginx web server
      yum: name=nginx state=present
    - name: Upload default index.html for web server
      copy: src=index.html dest=/usr/share/nginx/html/ mode=0644 # 보안을 위해서 0644로 잡음
    - name: Start nginx web server
      service: name=nginx state=started # nginx 실행
~~~


> 이건 강의와는 별도로 메모 .. netstat 가 안깔려있어 설치. 
~~~
[root@Ansible-Server ~]# ansible nginx -m yum -a "name=net-tools state=installed" -k
~~~

