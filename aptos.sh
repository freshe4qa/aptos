#!/bin/bash
echo -e '\e[40m\e[91m'
echo -e '  ____                  _                    '
echo -e ' / ___|_ __ _   _ _ __ | |_ ___  _ __        '
echo -e '| |   |  __| | | |  _ \| __/ _ \|  _ \       '
echo -e '| |___| |  | |_| | |_) | || (_) | | | |      '
echo -e ' \____|_|   \__  |  __/ \__\___/|_| |_|      '
echo -e '            |___/|_|                         '
echo -e '    _                 _                      '
echo -e '   / \   ___ __ _  __| | ___ _ __ ___  _   _ '
echo -e '  / _ \ / __/ _  |/ _  |/ _ \  _   _ \| | | |'
echo -e ' / ___ \ (_| (_| | (_| |  __/ | | | | | |_| |'
echo -e '/_/   \_\___\__ _|\__ _|\___|_| |_| |_|\__  |'
echo -e '                                       |___/ '
echo -e '\e[0m'
sleep 2

#set vars
echo "export WORKSPACE=testnet" >> $HOME/.bash_profile
echo "export PUBLIC_IP=$(curl -s ifconfig.me)" >> $HOME/.bash_profile
source $HOME/.bash_profile

#update package
sudo apt update && sudo apt upgrade -y

#install dependencies
sudo apt-get install jq unzip -y

#install docker
sudo apt-get install ca-certificates curl gnupg lsb-release -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io -y

#install docker compose
mkdir -p ~/.docker/cli-plugins/
curl -SL https://github.com/docker/compose/releases/download/v2.2.3/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose
chmod +x ~/.docker/cli-plugins/docker-compose
sudo chown $USER /var/run/docker.sock

#download aptos cli
wget -qO aptos-cli.zip https://github.com/aptos-labs/aptos-core/releases/download/aptos-cli-v0.1.1/aptos-cli-0.1.1-Ubuntu-x86_64.zip
unzip aptos-cli.zip -d /usr/local/bin
chmod +x /usr/local/bin/aptos
rm aptos-cli.zip

#create directory
mkdir ~/$WORKSPACE && cd ~/$WORKSPACE

#download config files
wget -qO docker-compose.yaml https://raw.githubusercontent.com/aptos-labs/aptos-core/main/docker/compose/aptos-node/docker-compose.yaml
wget -qO validator.yaml https://raw.githubusercontent.com/aptos-labs/aptos-core/main/docker/compose/aptos-node/validator.yaml
wget -qO fullnode.yaml https://raw.githubusercontent.com/aptos-labs/aptos-core/main/docker/compose/aptos-node/fullnode.yaml

#generate keys
aptos genesis generate-keys --output-dir ~/$WORKSPACE

#configure validator
aptos genesis set-validator-configuration \
  --keys-dir ~/$WORKSPACE --local-repository-dir ~/$WORKSPACE \
  --username aptosbot \
  --validator-host $PUBLIC_IP:6180 \
  --full-node-host $PUBLIC_IP:6182
  
  #generate root keys
mkdir keys
aptos key generate --output-file keys/root

#create layot files
tee layout.yaml > /dev/null <<EOF
---
root_key: "0x5243ca72b0766d9e9cbf2debf6153443b01a1e0e6d086c7ea206eaf6f8043956"
users:
  - aptosbot
chain_id: 23
EOF

#download aptos framework
wget -qO framework.zip https://github.com/aptos-labs/aptos-core/releases/download/aptos-framework-v0.1.0/framework.zip
unzip framework.zip
rm framework.zip

#compile genesis blob and waypoint
aptos genesis generate-genesis --local-repository-dir ~/$WORKSPACE --output-dir ~/$WORKSPACE

#run docker compose
docker compose up -d
