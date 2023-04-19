#!/bin/bash 


echo ""
echo ""
echo "---------------------------------"
echo -e "  자동 업데이트 ver : ""\033[32m"23.04.19"\033[0m"""
echo "---------------------------------"
echo ""
echo ""
echo ""
echo ""
echo ""
echo "설치된 버전 확인중..."
echo ""


# Check versions of installed clients
	ins_vR1=$(rocketpool -V | grep version)
	ins_vR=${ins_vR1#*version }
	



https://github.com/rocket-pool/smartnode-install/releases/latest

# Check the latest versions of clients
	lst_vR1=$(curl -s -I https://github.com/rocket-pool/smartnode-install/releases/latest | grep tag)
	lst_vR2=${lst_vR1#*tag/v}
	lst_vR=$(echo $lst_vR2 | sed 's/\r$//')



# Client selection
	echo ""
	echo " 현재ver / 설치할ver"
	echo "---------------------------------------------------------------"
	echo -e "\033[0m""  RocketPool (현재ver : ""\033[32m""$ins_vR""\033[0m"" / 설치할ver : ""\033[31;1m""$lst_vR""\033[0m"")"
	echo ""
	echo "---------------------------------------------------------------"
	echo ""

	



echo "업데이트 할 클라이언트를 선택해주세요"
echo ""
echo "1 : Geth + 시스템전체"
echo "2 : Lighthous"
echo "3 : Mev-Boost"
echo ""
echo -n "[1,2,3] 엽력 : "
read select



echo ""

read -p " [ "$select" ] 선택하셨습니다. 업데이트 시작할까요? [y , n] : " check


if [ "$check" = "y" ] ; then 
  echo "업데이트를 시작합니다... "

  if [ "$select" = "1" ] ; then 
    sudo systemctl stop geth
    sudo apt update -y && sudo apt upgrade -y && sudo apt dist-upgrade -y && sudo apt autoremove -y
    sudo systemctl start geth
    echo ""
    echo ""
    ins_vGE1n=$(geth version | grep Version)
    ins_vGE2n=${ins_vGE1n%-stable*}
    ins_vGEn=${ins_vGE2n#*Version: }
    
    echo "Geth v"$ins_vGEn" 및 시스템전체 업데이트 완료!"
    echo ""
    
  elif [ "$select" = "2" ] ; then 
    cd ~
    curl -LO https://github.com/sigp/lighthouse/releases/download/v"$lst_vLH"/lighthouse-v"$lst_vLH"-x86_64-unknown-linux-gnu.tar.gz
    tar xvf lighthouse-v"$lst_vLH"-x86_64-unknown-linux-gnu.tar.gz
    sudo systemctl stop lighthousevalidator
    sudo systemctl stop lighthousebeacon
    sudo cp lighthouse /usr/local/bin
    sudo rm lighthouse lighthouse-v"$lst_vLH"-x86_64-unknown-linux-gnu.tar.gz
    sudo systemctl start lighthousebeacon
    sudo systemctl start lighthousevalidator
    echo ""
    echo ""
    ins_vLH1n=$(lighthouse --version | grep "Lighthouse v")
    ins_vLH2n=${ins_vLH1n#*v}
    ins_vLHn=${ins_vLH2n%-*}
    
    echo "Lighthouse v"$ins_vLHn" 업데이트 완료!"
    echo ""
    
  elif [ "$select" = "3" ] ; then 
    cd ~
    curl -LO https://github.com/flashbots/mev-boost/releases/download/v"$lst_vME"/mev-boost_"$lst_vME"_linux_amd64.tar.gz
    tar xvf mev-boost_"$lst_vME"_linux_amd64.tar.gz
    sudo systemctl stop mevboost
    sudo cp mev-boost /usr/local/bin
    sudo chown mevboost:mevboost /usr/local/bin/mev-boost
    sudo rm mev-boost LICENSE README.md mev-boost_"$lst_vME"_linux_amd64.tar.gz
    sudo systemctl start mevboost
    echo ""
    echo ""
    ins_vME1n=$(mev-boost --version | grep mev-boost)
    ins_vMEn=${ins_vME1n#*boost }
    echo "Mev-Boost v"$ins_vMEn" 업데이트 완료!"
    echo ""
  else
    exit
fi




elif [ "$check" = "n" ] ; then 
  echo "업데이트를 취소합니다. "
  exit




else
  echo "입력을 확인해주세요! [y, n]"
  exit

fi


