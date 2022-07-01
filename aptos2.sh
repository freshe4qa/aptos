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

sleep 2

if [ ! $NODENAME ]; then
	read -p "Enter node name: " NODENAME
	echo 'export NODENAME='$NODENAME >> $HOME/.bash_profile
fi
echo "export WORKSPACE=testnet" >> $HOME/.bash_profile
echo "export PUBLIC_IP=$(curl -s ifconfig.me)" >> $HOME/.bash_profile
source $HOME/.bash_profile

sudo apt update && sudo apt upgrade -y

sudo apt-get install jq unzip -y
sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/v4.23.1/yq_linux_amd64 && chmod +x /usr/local/bin/yq

if ! command -v docker &> /dev/null
then
    sudo apt-get install ca-certificates curl gnupg lsb-release -y
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install docker-ce docker-ce-cli containerd.io -y
fi

docker compose version
if [ $? -ne 0 ]
then
	mkdir -p ~/.docker/cli-plugins/
	curl -SL https://github.com/docker/compose/releases/download/v2.6.1/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose
	chmod +x ~/.docker/cli-plugins/docker-compose
	sudo chown $USER /var/run/docker.sock
fi

wget -qO aptos-cli.zip https://github.com/aptos-labs/aptos-core/releases/download/aptos-cli-0.2.0/aptos-cli-0.2.0-Ubuntu-x86_64.zip
unzip -o aptos-cli.zip -d /usr/local/bin
chmod +x /usr/local/bin/aptos
rm aptos-cli.zip

mkdir ~/$WORKSPACE && cd ~/$WORKSPACE

wget -qO docker-compose.yaml https://raw.githubusercontent.com/aptos-labs/aptos-core/main/docker/compose/aptos-node/docker-compose.yaml
wget -qO validator.yaml https://raw.githubusercontent.com/aptos-labs/aptos-core/main/docker/compose/aptos-node/validator.yaml

aptos genesis generate-keys --output-dir ~/$WORKSPACE

aptos genesis set-validator-configuration \
  --keys-dir ~/$WORKSPACE --local-repository-dir ~/$WORKSPACE \
  --username $NODENAME \
  --validator-host $PUBLIC_IP:6180
  
mkdir keys
aptos key generate --assume-yes --output-file keys/root
ROOT_KEY="0x"$(cat ~/$WORKSPACE/keys/root.pub)

sudo tee layout.yaml > /dev/null <<EOF
---
root_key: "$ROOT_KEY"
users:
  - $NODENAME
chain_id: 40
min_stake: 0
max_stake: 100000
min_lockup_duration_secs: 0
max_lockup_duration_secs: 2592000
epoch_duration_secs: 86400
initial_lockup_timestamp: 1656615600
min_price_per_gas_unit: 1
allow_new_validators: true
EOF

wget -qO framework.zip https://github.com/aptos-labs/aptos-core/releases/download/aptos-framework-v0.2.0/framework.zip
unzip -o framework.zip
rm framework.zip

aptos genesis generate-genesis --local-repository-dir ~/$WORKSPACE --output-dir ~/$WORKSPACE

docker compose up -d
