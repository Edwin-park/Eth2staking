#!/bin/bash 


echo ""
echo ""
echo "---------------------------------"
echo -e "  자동 업데이트 ver : ""\033[32m"25.02.05"\033[0m"""
echo "  자동 재시작 Off  "
echo " g.start / lb.start / lv.start / mev.start 해야됨 "
echo "---------------------------------"
echo ""
echo ""
echo ""
echo ""
echo ""
echo "설치된 버전 확인중..."
echo ""


# Check versions of installed clients
	ins_vGE1=$(geth version | grep Version)
	ins_vGE2=${ins_vGE1%-stable*}
	ins_vGE=${ins_vGE2#*Version: }

	ins_vLH1=$(lighthouse --version | grep "Lighthouse v")
	ins_vLH2=${ins_vLH1#*v}
	ins_vLH=${ins_vLH2%-*}

	ins_vME1=$(mev-boost --version | grep mev-boost)
	ins_vME=${ins_vME1#*boost }



# Check the latest versions of clients
	lst_vGE1=$(curl -s -I https://github.com/ethereum/go-ethereum/releases/latest | grep tag)
	lst_vGE2=${lst_vGE1#*tag/v}
	lst_vGE=$(echo $lst_vGE2 | sed 's/\r$//')

	lst_vLH1=$(curl -s -I https://github.com/sigp/lighthouse/releases/latest | grep tag)
	lst_vLH2=${lst_vLH1#*tag/v}
	lst_vLH=$(echo $lst_vLH2 | sed 's/\r$//')

	lst_vME1=$(curl -s -I https://github.com/flashbots/mev-boost/releases/latest | grep tag)
	lst_vME2=${lst_vME1#*tag/v}
	lst_vME=$(echo $lst_vME2 | sed 's/\r$//')

# Client selection
	echo ""
	echo " 현재ver / 설치할ver"
	echo "---------------------------------------------------------------"
	echo -e "\033[0m""  1. geth (현재ver : ""\033[32m""$ins_vGE""\033[0m"" / 설치할ver : ""\033[31;1m""$lst_vGE""\033[0m"")"
	echo ""
	echo -e "\033[0m""  2. lighthouse (현재ver : ""\033[32m""$ins_vLH""\033[0m"" / 설치할ver : ""\033[31;1m""$lst_vLH""\033[0m"")"
	echo ""
	echo -e "\033[0m""  3. MEV-boost (현재ver : ""\033[32m""$ins_vME""\033[0m"" / 설치할ver : ""\033[31;1m""$lst_vME""\033[0m"")"
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


