#!/bin/bash 

echo "설치하실 네트워크를 선택해주세요"
echo "1 : Prater Testnet"
echo "2 : Main net"
echo -n "[1,2] 엽력 : "
read network

if [ "$network" = "1" ] ; then 
  network2="Prater Testnet"
elif [ "$network" = "2" ] ; then 
  network2="Main net"
else
  echo "네트워크 착오입력 [1,2] "
  exit
fi


echo "블록제안 Tip 수령주소를 입력해주세요. "
echo -n " ex : [ 0xAa83d6C8A07492a28Af2DfDb57Fe69306362f02E ] : "
read address



echo "클라이언트 버전을 입력해주세요. "

echo -n "Geth 버전 입력하세요        (ex : 1.10.25) : "
read Geth

echo -n "Lighthouse 버전 입력하세요  (ex : 3.1.0)   : "
read Lighthouse

echo -n "Mev-Boost 버전 입력하세요   (ex : 1.3.2)   : "
read Mev





echo "네트워크 및 클라이언트 버전 최종확인"
echo ""
echo "네트워크 : $network2"
echo "Tip 수령주소 : $address"
echo "Geth v$Geth"
echo "Lighthous v$Lighthouse"
echo "Mev-Boost v$Mev"
echo ""



read -p "설치시작 [y , n] : " check


if [ "$check" = "y" ] ; then 
  echo "설치 시작합니다. "

sudo apt update -y && sudo apt upgrade -y && sudo apt dist-upgrade -y && sudo apt autoremove -y
sudo timedatectl set-timezone Asia/Seoul



#JWT 파일생성
cd ~
sudo mkdir -p /var/lib/jwtsecret
openssl rand -hex 32 | sudo tee /var/lib/jwtsecret/jwt.hex > /dev/null
echo ""
echo "JWT 생성완료"
echo ""

#geth 설치
sudo add-apt-repository -y ppa:ethereum/ethereum
sudo apt-get update
sudo apt-get install ethereum -y
sudo useradd --no-create-home --shell /bin/false geth
sudo mkdir -p /var/lib/geth
sudo chown -R geth:geth /var/lib/geth
echo ""
echo "Geth 설치완료"
echo ""

#Lighthouse 설치
cd ~
curl -LO https://github.com/sigp/lighthouse/releases/download/v"$Lighthouse"/lighthouse-v"$Lighthouse"-x86_64-unknown-linux-gnu.tar.gz
tar xvf lighthouse-v"$Lighthouse"-x86_64-unknown-linux-gnu.tar.gz
sudo cp lighthouse /usr/local/bin
sudo rm lighthouse lighthouse-v"$Lighthouse"-x86_64-unknown-linux-gnu.tar.gz
echo ""
echo "Lighthouse 설치완료"
echo ""

#비콘체인 설치
sudo useradd --no-create-home --shell /bin/false lighthousebeacon
sudo mkdir -p /var/lib/lighthouse/beacon
sudo chown -R lighthousebeacon:lighthousebeacon /var/lib/lighthouse/beacon
sudo chmod 700 /var/lib/lighthouse/beacon


#벨리데이터 설치
sudo useradd --no-create-home --shell /bin/false lighthousevalidator
sudo mkdir -p /var/lib/lighthouse/validators
sudo chown -R lighthousevalidator:lighthousevalidator /var/lib/lighthouse/validators
sudo chmod 700 /var/lib/lighthouse/validators


#MEV-Boost 설치
sudo useradd --no-create-home --shell /bin/false mevboost
cd ~
curl -LO https://github.com/flashbots/mev-boost/releases/download/v"$Mev"/mev-boost_"$Mev"_linux_amd64.tar.gz
tar xvf mev-boost_"$Mev"_linux_amd64.tar.gz
sudo cp mev-boost /usr/local/bin
sudo chown mevboost:mevboost /usr/local/bin/mev-boost
cd ~
sudo rm mev-boost LICENSE README.md mev-boost_"$Mev"_linux_amd64.tar.gz
echo ""
echo "Mev-Boost 설치완료"
echo ""

#Prater Testnet 서비스파일
if [ "$network" = "1" ] ; then 
cat > /etc/systemd/system/geth.service << EOF
[Unit]
Description=Geth
After=network-online.target

[Service]
Type=simple
User=geth
ExecStart=geth \\
  --goerli \\
  --datadir /var/lib/geth \\
  --metrics \\
  --pprof \\
  --http \\
  --http.addr=0.0.0.0 \\
  --cache=2048 \\
  --port=10001 \\
  --authrpc.jwtsecret /var/lib/jwtsecret/jwt.hex \\
  --authrpc.vhosts="*"

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
cat > /etc/systemd/system/lighthousebeacon.service << EOF
[Unit]
Description=Lighthouse Beacon Node
After=geth.target

[Service]
Type=simple
User=lighthousebeacon
Group=lighthousebeacon

ExecStart=/usr/local/bin/lighthouse bn \\
  --network prater \\
  --datadir /var/lib/lighthouse \\
  --http \\
  --http-address=0.0.0.0 \\
  --validator-monitor-auto \\
  --metrics \\
  --execution-endpoint http://localhost:8551 \\
  --execution-jwt /var/lib/jwtsecret/jwt.hex \\
  --port 9001 \\
  --discovery-port 9001 \\
  --checkpoint-sync-url https://26nBBRbB6LXwiG9j68YEx0jJ9zE:d32d9dd0eaecadb8a99b7fa6443a19e8@eth2-beacon-prater.infura.io \\
  --builder http://localhost:18550

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
cat > /etc/systemd/system/lighthousevalidator.service << EOF
[Unit]
Description=Lighthouse Validator Node
After=lighthousebeacon.target

[Service]
Type=simple
User=lighthousevalidator
Group=lighthousevalidator

ExecStart=/usr/local/bin/lighthouse vc \\
  --network prater \\
  --beacon-nodes http://localhost:5052 \\
  --datadir /var/lib/lighthouse \\
  --metrics \\
  --suggested-fee-recipient $address \\
  --builder-proposals

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
cat > /etc/systemd/system/mevboost.service << EOF
[Unit]
Description=mev-boost
After=network-online.target

[Service]
Type=simple
User=mevboost
Group=mevboost

ExecStart=mev-boost \\
    -goerli \\
    -relay-check \\
    -relays https://0xafa4c6985aa049fb79dd37010438cfebeb0f2bd42b115b89dd678dab0670c1de38da0c4e9138c9290a398ecd9a0b3110@builder-relay-goerli.flashbots.net,https://0x821f2a65afb70e7f2e820a925a9b4c80a159620582c1766b1b09729fec178b11ea22abb3a51f07b288be815a1a2ff516@bloxroute.max-profit.builder.goerli.blxrbdn.com,https://0x8f7b17a74569b7a57e9bdafd2e159380759f5dc3ccbd4bf600414147e8c4e1dc6ebada83c0139ac15850eb6c975e82d0@builder-relay-goerli.blocknative.com,https://0xaa1488eae4b06a1fff840a2b6db167afc520758dc2c8af0dfb57037954df3431b747e2f900fe8805f05d635e9a29717b@relay-goerli.edennetwork.io

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF



#Main net 서비스파일
elif [ "$network" = "2" ] ; then 
cat > /etc/systemd/system/geth.service << EOF
[Unit]
Description=Geth
After=network-online.target

[Service]
Type=simple
User=geth
ExecStart=geth \\
  --datadir /var/lib/geth \\
  --metrics \\
  --pprof \\
  --http \\
  --http.addr=0.0.0.0 \\
  --cache=8192 \\
  --port=20001 \\
  --authrpc.jwtsecret /var/lib/jwtsecret/jwt.hex \\
  --authrpc.vhosts="*"

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
cat > /etc/systemd/system/lighthousebeacon.service << EOF
[Unit]
Description=Lighthouse Beacon Node
After=geth.target

[Service]
Type=simple
User=lighthousebeacon
Group=lighthousebeacon

ExecStart=/usr/local/bin/lighthouse bn \\
  --network mainnet \\
  --datadir /var/lib/lighthouse \\
  --http \\
  --http-address=0.0.0.0 \\
  --validator-monitor-auto \\
  --metrics \\
  --execution-endpoint http://localhost:8551 \\
  --execution-jwt /var/lib/jwtsecret/jwt.hex \\
  --port 9002 \\
  --discovery-port 9002 \\
  --checkpoint-sync-url https://26pgNISME52yCryWfyA0jNQPYDe:80d95be613e437ff37ee8024f2fb4d4e@eth2-beacon-mainnet.infura.io \\
  --builder http://localhost:18550

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
cat > /etc/systemd/system/lighthousevalidator.service << EOF
[Unit]
Description=Lighthouse Validator Node
After=lighthousebeacon.target

[Service]
Type=simple
User=lighthousevalidator
Group=lighthousevalidator

ExecStart=/usr/local/bin/lighthouse vc \\
  --network mainnet \\
  --beacon-nodes http://localhost:5052 \\
  --datadir /var/lib/lighthouse \\
  --metrics \\
  --suggested-fee-recipient $address \\
  --builder-proposals

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
cat > /etc/systemd/system/mevboost.service << EOF
[Unit]
Description=mev-boost
After=network-online.target

[Service]
Type=simple
User=mevboost
Group=mevboost

ExecStart=mev-boost \\
    -mainnet \\
    -relay-check \\
    -relays https://0xac6e77dfe25ecd6110b8e780608cce0dab71fdd5ebea22a16c0205200f2f8e2e3ad3b71d3499c54ad14d6c21b41a37ae@boost-relay.flashbots.net,https://0x8b5d2e73e2a3a55c6c87b8b6eb92e0149a125c852751db1422fa951e42a09b82c142c3ea98d0d9930b056a3bc9896b8f@bloxroute.max-profit.blxrbdn.com,https://0x9000009807ed12c1f08bf4e81c6da3ba8e3fc3d953898ce0102433094e5f22f21102ec057841fcb81978ed1ea0fa8246@builder-relay-mainnet.blocknative.com,https://0xb3ee7afcf27f1f1259ac1787876318c6584ee353097a50ed84f51a1f21a323b3736f271a895c7ce918c038e4265918be@relay.edennetwork.io

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
else
  echo "네트워크 착오입력 [1,2] "
  exit
fi





echo ""
echo "최종설치 완료! geth, beacon 서비스 시작! "
echo ""

sudo systemctl daemon-reload
sudo systemctl start geth
sudo systemctl start lighthousebeacon

echo "geth 로그 보는법 : g.log"
echo "beacon 로그 보는법 : lb.log"




elif [ "$check" = "n" ] ; then 
  echo "설치 취소합니다. "
  exit




else
  echo "입력 확인해주세요! [y, n]"
  exit

fi





