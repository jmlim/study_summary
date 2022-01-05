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

### 출처
 - https://gist.github.com/TonyMtz/d75101d9bdf764c890ef
 - https://velog.io/@97godo/Node-node.js-%EC%99%84%EC%A0%84%ED%9E%88-%EC%82%AD%EC%A0%9C-%ED%9B%84-%EC%9E%AC%EC%84%A4%EC%B9%98-%ED%95%98%EA%B8%B0