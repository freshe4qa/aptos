#!/bin/bash
exists()
{
  command -v "$1" >/dev/null 2>&1
}
if exists curl; then
echo ''
else
  sudo apt update && sudo apt install curl -y < "/dev/null"
fi
bash_profile=$HOME/.bash_profile
if [ -f "$bash_profile" ]; then
    . $HOME/.bash_profile
fi
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
if [ ! $APTOS_NODENAME ]; then
read -p "Enter node name: " APTOS_NODENAME
echo 'export APTOS_NODENAME='\"${APTOS_NODENAME}\" >> $HOME/.bash_profile
fi
echo 'source $HOME/.bashrc' >> $HOME/.bash_profile
. $HOME/.bash_profile

apt update && apt install git sudo unzip wget -y
#install docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
#install docker-compose
curl -SL https://github.com/docker/compose/releases/download/v2.5.0/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
 
#install aptos
wget -qO aptos-cli.zip https://github.com/aptos-labs/aptos-core/releases/download/aptos-cli-v0.1.1/aptos-cli-0.1.1-Ubuntu-x86_64.zip
unzip -o aptos-cli.zip
chmod +x aptos
mv aptos /usr/local/bin 
 
#create folder,download config    
IPADDR=$(curl ifconfig.me) 
sleep 2   
mkdir -p $HOME/.aptos
cd $HOME/.aptos
wget https://raw.githubusercontent.com/aptos-labs/aptos-core/main/docker/compose/aptos-node/docker-compose.yaml
wget https://raw.githubusercontent.com/aptos-labs/aptos-core/main/docker/compose/aptos-node/validator.yaml
wget https://raw.githubusercontent.com/aptos-labs/aptos-core/main/docker/compose/aptos-node/fullnode.yaml

aptos genesis generate-keys --output-dir $HOME/.aptos

aptos genesis set-validator-configuration \
    --keys-dir $HOME/.aptos --local-repository-dir $HOME/.aptos \
    --username $APTOS_NODENAME \
    --validator-host $IPADDR:6180 \
    --full-node-host $IPADDR:6182
    
aptos key generate --output-file root_key.txt
KEYTXT=$(cat ~/.aptos/root_key.txt.pub) 
KEY="0x"$KEYTXT 
echo "---
root_key: \"$KEY\"
users:
  - $APTOS_NODENAME
chain_id: 23" >layout.yaml
    
wget https://github.com/aptos-labs/aptos-core/releases/download/aptos-framework-v0.1.0/framework.zip
unzip -o framework.zip
aptos genesis generate-genesis --local-repository-dir $HOME/.aptos --output-dir $HOME/.aptos
sleep 2
docker compose up -d
