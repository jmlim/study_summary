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

# ansible all -i ~/test -m ping -k
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

# ansible nginx -m ping -k
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
~~~
# ansible nginx -m ping --list-hosts
  hosts (3):
    192.168.219.11
    192.168.219.12
    192.168.219.13

# ansible all -i test -m ping --list-hosts
  hosts (2):
    192.168.219.11
    192.168.219.12
~~~

## 3. 한 번의 명령어로 다수의 시스템에 작업하기.
### 3.1. uptime 확인하기.
~~~
 # ansible all -m shell -a "uptime" -k
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
~~~
# ansible all -m shell -a "free -h" -k
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
~~~
# ansible all -m user -a "name=jmlim password=1234" -k
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
~~~
# ssh root@192.168.219.11
root@192.168.219.11's password:
Last login: Sat Feb  8 02:06:16 2020 from 192.168.219.10

# cat /etc/passwd
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
~~~
# touch jmlim.file // 파일 생성.
# ansible nginx -m copy -a "src=./jmlim.file dest=/tmp/" -k
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
~~~
# ssh root@192.168.219.11
root@192.168.219.11's password:
Last login: Sat Feb  8 02:06:16 2020 from 192.168.219.10

(node1번 서버) # ls -rlt /tmp
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

... 작성중 ..