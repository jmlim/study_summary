# first:
lsbom -f -l -s -pf /var/db/receipts/org.nodejs.pkg.bom | while read f; do  sudo rm /usr/local/${f}; done
sudo rm -rf /usr/local/lib/node /usr/local/lib/node_modules /var/db/receipts/org.nodejs.*

# To recap, the best way (I've found) to completely uninstall node + npm is to do the following:

# go to /usr/local/lib and delete any node and node_modules
cd /usr/local/lib
sudo rm -rf node*

# go to /usr/local/include and delete any node and node_modules directory
cd /usr/local/include
sudo rm -rf node*

# if you installed with brew install node, then run brew uninstall node in your terminal
brew uninstall node

# check your Home directory for any "local" or "lib" or "include" folders, and delete any "node" or "node_modules" from there
# go to /usr/local/bin and delete any node executable
cd /usr/local/bin
sudo rm -rf /usr/local/bin/npm
sudo rm -rf /usr/local/bin/node
ls -las

# you may need to do the additional instructions as well:
sudo rm -rf /usr/local/share/man/man1/node.1
sudo rm -rf /usr/local/lib/dtrace/node.d
sudo rm -rf ~/.npm

# nvm → node → npm 순으로 다시 설치해준다.
brew install nvm
brew install node
brew install npm

# 버전 확인 후 숫자가 나오면 설치 완료
node -v
npm -v

> **[2026년 추가]** 위 세 줄은 사실 같이 쓰면 안 되는 조합이다.
> - `nvm`(Node Version Manager)을 설치하는 목적 자체가 "Node 버전을 nvm으로 관리하겠다"는 것인데, 그 직후에 `brew install node`로 **또 다른 Node를 따로 설치**하면 두 개의 Node가 PATH에서 충돌한다.
> - `npm`은 Node를 설치하면 항상 같이 딸려온다 (brew로 깔든 nvm으로 깔든). `brew install npm`을 별도로 실행할 이유가 없고, 오히려 지금 쓰는 Node와 버전이 안 맞는 npm이 깔려서 더 꼬일 수 있다.
>
> 실제로는 아래 **둘 중 하나만** 선택해서 쓰는 게 맞다.
> ```
> # 방법 1) 여러 프로젝트마다 Node 버전을 바꿔가며 쓰고 싶다면 (추천)
> brew install nvm
> nvm install --lts   # npm은 자동으로 함께 설치됨
> nvm use --lts
>
> # 방법 2) 버전 하나만 쓸 거라면 nvm 없이 이것만
> brew install node    # npm도 함께 설치됨
> ```

### 출처
 - https://gist.github.com/TonyMtz/d75101d9bdf764c890ef
 - https://velog.io/@97godo/Node-node.js-%EC%99%84%EC%A0%84%ED%9E%88-%EC%82%AD%EC%A0%9C-%ED%9B%84-%EC%9E%AC%EC%84%A4%EC%B9%98-%ED%95%98%EA%B8%B0