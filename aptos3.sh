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
sleep 1 

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

sleep 1
if grep -q avx2 /proc/cpuinfo; then
	echo ""
else
	echo -e "\e[31mInstallation is not possible, your server does not support AVX2, change your server and try again.\e[39m"
	exit
fi
if ss -tulpen | awk '{print $5}' | grep -q ":80$" ; then
	echo -e "\e[31mInstallation is not possible, port 80 already in use.\e[39m"
	exit
else
	echo ""
fi
if ss -tulpen | awk '{print $5}' | grep -q ":6180$" ; then
	echo -e "\e[31mInstallation is not possible, port 6180 already in use.\e[39m"
	exit
else
	echo ""
fi
if ss -tulpen | awk '{print $5}' | grep -q ":6181$" ; then
	echo -e "\e[31mInstallation is not possible, port 6181 already in use.\e[39m"
	exit
else
	echo ""
fi
if ss -tulpen | awk '{print $5}' | grep -q ":9101$" ; then
	echo -e "\e[31mInstallation is not possible, port 9101 already in use.\e[39m"
	exit
else
	echo ""
fi
if [ ! $APTOS_NODENAME ]; then
read -p "Enter node name: " APTOS_NODENAME
echo 'export APTOS_NODENAME='\"${APTOS_NODENAME}\" >> $HOME/.bash_profile
fi
echo 'source $HOME/.bashrc' >> $HOME/.bash_profile
echo "export WORKSPACE=\"$HOME/.aptos\"" >>$HOME/.bash_profile
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
wget -qO aptos-cli.zip https://github.com/aptos-labs/aptos-core/releases/download/aptos-cli-v0.3.1/aptos-cli-0.3.1-Ubuntu-x86_64.zip
unzip -o aptos-cli.zip
chmod +x aptos
mv aptos /usr/local/bin 
 
#create folder,download config    
IPADDR=$(curl ifconfig.me) 
sleep 2   
mkdir -p $WORKSPACE
cd $WORKSPACE
wget -O $WORKSPACE/docker-compose.yaml https://raw.githubusercontent.com/aptos-labs/aptos-core/main/docker/compose/aptos-node/docker-compose.yaml
wget -O $WORKSPACE/validator.yaml https://raw.githubusercontent.com/aptos-labs/aptos-core/main/docker/compose/aptos-node/validator.yaml

aptos genesis generate-keys --assume-yes --output-dir $WORKSPACE/keys

aptos genesis set-validator-configuration \
    --local-repository-dir $WORKSPACE \
    --username $APTOS_NODENAME \
    --owner-public-identity-file $WORKSPACE/keys/public-keys.yaml \
    --validator-host $IPADDR:6180 \
    --stake-amount 100000000000000

#aptos genesis generate-layout-template --output-file $WORKSPACE/layout.yaml

echo "---
root_key: "D04470F43AB6AEAA4EB616B72128881EEF77346F2075FFE68E14BA7DEBD8095E"
users: [\"$APTOS_NODENAME\"]
chain_id: 43
allow_new_validators: false
epoch_duration_secs: 7200
is_test: true
min_stake: 100000000000000
min_voting_threshold: 100000000000000
max_stake: 100000000000000000
recurring_lockup_duration_secs: 86400
required_proposer_stake: 100000000000000
rewards_apy_percentage: 10
voting_duration_secs: 43200
voting_power_increase_limit: 20" >layout.yaml

wget https://github.com/aptos-labs/aptos-core/releases/download/aptos-framework-v0.3.0/framework.mrb -P $WORKSPACE
    
aptos genesis generate-genesis --assume-yes --local-repository-dir $WORKSPACE --output-dir $WORKSPACE
sleep 2
docker-compose down -v
sleep 2
docker compose up -d
