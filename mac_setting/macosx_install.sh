#!/usr/bin/env bash

mkdir -p ~/workspace ~/dev

if [ ! -f /opt/homebrew/bin/brew ]; then
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

brew tap homebrew/cask-versions
brew list cask &>/dev/null || brew install cask
brew list wget &>/dev/null || brew install wget
brew list git &>/dev/null || brew install git
brew list git-duet &>/dev/null || brew install git-duet/tap/git-duet
brew list graphviz &>/dev/null || brew install graphviz
brew list curl &>/dev/null || brew install curl
brew list nvm &>/dev/null || brew install nvm
brew list yarn &>/dev/null || brew install yarn
brew list fzf &>/dev/null || brew install fzf

brew list iterm2 &>/dev/null || brew install iterm2
brew list rectangle &>/dev/null || brew install rectangle
brew list postman &>/dev/null || brew install postman
brew list switchhosts &>/dev/null || brew install switchhosts
brew list jetbrains-toolbox &>/dev/null || brew install jetbrains-toolbox
brew list docker &>/dev/null || brew install docker
brew list openlens &>/dev/null || brew install openlens
brew list kubectx &>/dev/null || brew install kubectx
brew list warp &>/dev/null || brew install warp
brew list another-redis-desktop-manager &>/dev/null || brew install --cask another-redis-desktop-manager

if [ ! -f /usr/local/bin/aws ]; then
   /usr/bin/ruby -e "$(curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg")"
fi
sudo installer -pkg ./AWSCLIV2.pkg -target /

curl -s "https://get.sdkman.io" | bash
source ~/.zshrc
sdk install java 8.0.332-zulu

mkdir -p ~/.nvm
export NVM_DIR="$HOME/.nvm"
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion
source ~/.zshrc
nvm install 14.19.0
nvm install 16.15.1

mkdir -p ~/.ssh

if [ ! -f ~/.zshrc ]; then
   echo "export PATH=$PATH:$HOME/bin" >> ~/.zshrc
   echo "export GIT_DUET_AUTHORS_FILE=$HOME/.git-authors" >> ~/.zshrc
fi

PATH_GREP_RESULT=`grep "/dev:" ~/.zshrc; echo $?`
if [ "$PATH_GREP_RESULT" == "1" ]; then
   echo "export PATH=\$PATH:\$HOME/dev" >> ~/.zshrc
fi

ssh-keygen -t rsa
