#!/bin/bash 


echo ""
echo ""
echo "---------------------------------"
echo -e "  자동 설치 ver : ""\033[32m"25.11.26"\033[0m"""
echo ""
echo "  메인넷 mev 릴레이 수정 "
echo ""
echo "---------------------------------"
echo ""
echo ""
echo ""
echo ""
echo ""
echo ""


echo "설치하실 네트워크를 선택해주세요"
echo "1 : Holesky Testnet"
echo "2 : Main net"
echo -n "[1,2] 엽력 : "
read network

if [ "$network" = "1" ] ; then 
  network2="Holesky Testnet"
elif [ "$network" = "2" ] ; then 
  network2="Main net"
else
  echo "네트워크 착오입력 [1,2] "
  exit
fi


echo "블록제안 Tip 수령주소를 입력해주세요. "
echo -n " ex : [ 0x388C818CA8B9251b393131C08a736A67ccB19297 ] : "
read address



 # Check the latest versions of clients
	lst_vGE=$(curl -s -L -o /dev/null -w '%{url_effective}' https://github.com/ethereum/go-ethereum/releases/latest | sed 's|.*/tag/v||')
	lst_vLH=$(curl -s -L -o /dev/null -w '%{url_effective}' https://github.com/sigp/lighthouse/releases/latest | sed 's|.*/tag/v||')
	lst_vME=$(curl -s -L -o /dev/null -w '%{url_effective}' https://github.com/flashbots/mev-boost/releases/latest | sed 's|.*/tag/v||')





echo "---------------------------------------------------------------"
echo ""
echo "네트워크 및 클라이언트 버전 최종확인"
echo ""
echo "네트워크 : $network2"
echo "Tip 수령주소 : $address"
echo "Geth v$lst_vGE"
echo "Lighthous v$lst_vLH"
echo "Mev-Boost v$lst_vME"
echo ""
echo "---------------------------------------------------------------"


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
echo "Geth v"$lst_vGE" 설치완료"
echo ""

#Lighthouse 설치
cd ~
curl -LO https://github.com/sigp/lighthouse/releases/download/v"$lst_vLH"/lighthouse-v"$lst_vLH"-x86_64-unknown-linux-gnu.tar.gz
tar xvf lighthouse-v"$lst_vLH"-x86_64-unknown-linux-gnu.tar.gz
sudo cp lighthouse /usr/local/bin
sudo rm lighthouse lighthouse-v"$lst_vLH"-x86_64-unknown-linux-gnu.tar.gz
echo ""
echo "Lighthouse v"$lst_vLH" 설치완료"
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
curl -LO https://github.com/flashbots/mev-boost/releases/download/v"$lst_vME"/mev-boost_"$lst_vME"_linux_amd64.tar.gz
tar xvf mev-boost_"$lst_vME"_linux_amd64.tar.gz
sudo cp mev-boost /usr/local/bin
sudo chown mevboost:mevboost /usr/local/bin/mev-boost
cd ~
sudo rm mev-boost LICENSE README.md mev-boost_"$lst_vME"_linux_amd64.tar.gz
echo ""
echo "Mev-Boost v"$lst_vME" 설치완료"
echo ""

#Holesky Testnet 서비스파일
if [ "$network" = "1" ] ; then 
cat > /etc/systemd/system/geth.service << EOF
[Unit]
Description=Geth
After=network-online.target
[Service]
Type=simple
User=geth
ExecStart=geth \\
  --holesky \\
  --datadir /var/lib/geth \\
  --metrics \\
  --pprof \\
  --http \\
  --http.addr=0.0.0.0 \\
  --port=10001 \\
  --authrpc.jwtsecret /var/lib/jwtsecret/jwt.hex \\
  --authrpc.vhosts="*" \\
  --state.scheme=path
Restart=always
RestartSec=5
TimeoutSec=900
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
  --network holesky \\
  --datadir /var/lib/lighthouse \\
  --http \\
  --http-address=0.0.0.0 \\
  --validator-monitor-auto \\
  --metrics \\
  --execution-endpoint http://localhost:8551 \\
  --execution-jwt /var/lib/jwtsecret/jwt.hex \\
  --port 9001 \\
  --discovery-port 9001 \\
  --checkpoint-sync-url https://goerli.beaconstate.ethstaker.cc \\
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
  --network holesky \\
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
    -holesky \\
    -relay-check \\
    -relays https://0xb1559beef7b5ba3127485bbbb090362d9f497ba64e177ee2c8e7db74746306efad687f2cf8574e38d70067d40ef136dc@relay-stag.ultrasound.money,https://0xab78bf8c781c58078c3beb5710c57940874dd96aef2835e7742c866b4c7c0406754376c2c8285a36c630346aa5c5f833@holesky.aestus.live,http://0x821f2a65afb70e7f2e820a925a9b4c80a159620582c1766b1b09729fec178b11ea22abb3a51f07b288be815a1a2ff516@testnet.relay-proxy.blxrbdn.com:18552/,https://0x821f2a65afb70e7f2e820a925a9b4c80a159620582c1766b1b09729fec178b11ea22abb3a51f07b288be815a1a2ff516@bloxroute.holesky.blxrbdn.com,https://0x833b55e20769a8a99549a28588564468423c77724a0ca96cffd58e65f69a39599d877f02dc77a0f6f9cda2a3a4765e56@relay-holesky.beaverbuild.org,https://0xb1d229d9c21298a87846c7022ebeef277dfc321fe674fa45312e20b5b6c400bfde9383f801848d7837ed5fc449083a12@relay-holesky.edennetwork.io,https://0xaa58208899c6105603b74396734a6263cc7d947f444f396a90f7b7d3e65d102aec7e5e5291b27e08d02c50a050825c2f@holesky.titanrelay.xyz/,https://0xafa4c6985aa049fb79dd37010438cfebeb0f2bd42b115b89dd678dab0670c1de38da0c4e9138c9290a398ecd9a0b3110@boost-relay-holesky.flashbots.net,https://0xa55c1285d84ba83a5ad26420cd5ad3091e49c55a813eee651cd467db38a8c8e63192f47955e9376f6b42f6d190571cb5@relay-holesky.bolt.chainbound.io,https://0xaa58208899c6105603b74396734a6263cc7d947f444f396a90f7b7d3e65d102aec7e5e5291b27e08d02c50a050825c2f@holesky-preconf.titanrelay.xyz,https://0x8d6ff9fdf3b8c05293f6c240f57034c6c5244d7ecb2b9a6e597de575b373610d6345f5060c150012d1cc42d38b8383ac@preconfs-holesky.aestus.live
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
  --port=20001 \\
  --authrpc.jwtsecret /var/lib/jwtsecret/jwt.hex \\
  --authrpc.vhosts="*" \\
  --state.scheme=path
Restart=always
RestartSec=5
TimeoutSec=900
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
  --checkpoint-sync-url https://beaconstate.ethstaker.cc \\
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
	# Titan Relay Global (Mainnet) (Non-filtering)
	-relay https://0x8c4ed5e24fe5c6ae21018437bde147693f68cda427cd1122cf20819c30eda7ed74f72dece09bb313f2a1855595ab677d@global.titanrelay.xyz \\
	# Titan Relay Regional (Mainnet) (Filtering)
	-relay https://0x8c4ed5e24fe5c6ae21018437bde147693f68cda427cd1122cf20819c30eda7ed74f72dece09bb313f2a1855595ab677d@regional.titanrelay.xyz \\
	# Agnostic Relay (Mainnet)
	-relay https://0xa7ab7a996c8584251c8f925da3170bdfd6ebc75d50f5ddc4050a6fdc77f2a3b5fce2cc750d0865e05d7228af97d69561@agnostic-relay.net \\
	# Ultra Sound Relay (Mainnet)
	-relay https://0xa1559ace749633b997cb3fdacffb890aeebdb0f5a3b6aaa7eeeaf1a38af0a8fe88b9e4b1f61f236d2e64d95733327a62@relay.ultrasound.money \\
	# Flashbots (Mainnet)
	-relay https://0xac6e77dfe25ecd6110b8e780608cce0dab71fdd5ebea22a16c0205200f2f8e2e3ad3b71d3499c54ad14d6c21b41a37ae@boost-relay.flashbots.net \\
	# bloXroute Max-Profit (Mainnet)
	-relay https://0x8b5d2e73e2a3a55c6c87b8b6eb92e0149a125c852751db1422fa951e42a09b82c142c3ea98d0d9930b056a3bc9896b8f@bloxroute.max-profit.blxrbdn.com

Restart=always
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF
else
  echo "네트워크 착오입력 [1,2] "
  exit
fi




echo "---------------------------------------------------------------"
echo ""
echo "최종설치 완료! geth, beacon 서비스 시작 !"
echo ""
echo "네트워크 : $network2"
echo "Tip 수령주소 : $address"
echo "Geth v$lst_vGE"
echo "Lighthous v$lst_vLH"
echo "Mev-Boost v$lst_vME"
echo ""
echo "geth 로그 보는법 : g.log"
echo "beacon 로그 보는법 : lb.log"
echo ""
echo "4단계 이어서 진행하시면 됩니다!"
echo ""
echo "---------------------------------------------------------------"


sudo systemctl daemon-reload
sudo systemctl start geth
sudo systemctl start lighthousebeacon





elif [ "$check" = "n" ] ; then 
  echo "설치를 취소합니다. "
  exit




else
  echo "입력을 확인해주세요! [y, n]"
  exit

fi
