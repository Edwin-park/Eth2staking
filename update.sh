#!/bin/bash 

echo "업데이트 할 클라이언트를 선택해주세요"
echo "1 : Geth + 시스템전체"
echo "2 : Lighthous"
echo "3 : Mev-Boost"
echo -n "[1,2,3] 엽력 : "
read select

if [ "$select" = "1" ] ; then 
  echo -n "Geth 버전 입력하세요        (ex : 1.10.25) : "
  read Geth
elif [ "$select" = "2" ] ; then 
  echo -n "Lighthouse 버전 입력하세요  (ex : 3.1.0)   : "
  read Lighthouse
elif [ "$select" = "3" ] ; then 
  echo -n "Mev-Boost 버전 입력하세요   (ex : 1.3.2)   : "
  read Mev
else
  echo "네트워크 착오입력 [1,2,3] "
  exit
fi


echo "업데이트 버전 최종확인"
echo ""

if [ "$select" = "1" ] ; then 
  echo "Geth v$Geth"
elif [ "$select" = "2" ] ; then 
  echo "Lighthous v$Lighthouse"
elif [ "$select" = "3" ] ; then 
  echo "Mev-Boost v$Mev"
else
  exit
fi



echo ""

read -p "업데이트 시작 [y , n] : " check


if [ "$check" = "y" ] ; then 
  echo "업데이트 시작합니다. "

  if [ "$select" = "1" ] ; then 
    sudo systemctl stop geth
    sudo apt update -y && sudo apt upgrade -y && sudo apt dist-upgrade -y && sudo apt autoremove -y
    sudo systemctl start geth
    geth version
    echo ""
    echo "Geth 및 시스템전체 업데이트 완료"
    echo ""
  elif [ "$select" = "2" ] ; then 
    cd ~
    curl -LO https://github.com/sigp/lighthouse/releases/download/v"$Lighthouse"/lighthouse-v"$Lighthouse"-x86_64-unknown-linux-gnu.tar.gz
    tar xvf lighthouse-v"$Lighthouse"-x86_64-unknown-linux-gnu.tar.gz
    sudo systemctl stop lighthousebeacon
    sudo cp lighthouse /usr/local/bin
    sudo rm lighthouse lighthouse-v"$Lighthouse"-x86_64-unknown-linux-gnu.tar.gz
    sudo systemctl start lighthousebeacon
    cd ~ && /usr/local/bin/lighthouse --version
    echo ""
    echo "Lighthouse 업데이트 완료"
    echo ""
  elif [ "$select" = "3" ] ; then 
    cd ~
    curl -LO https://github.com/flashbots/mev-boost/releases/download/v"$Mev"/mev-boost_"$Mev"_linux_amd64.tar.gz
    tar xvf mev-boost_"$Mev"_linux_amd64.tar.gz
    sudo systemctl stop mevboost
    sudo cp mev-boost /usr/local/bin
    sudo chown mevboost:mevboost /usr/local/bin/mev-boost
    sudo rm mev-boost LICENSE README.md mev-boost_"$Mev"_linux_amd64.tar.gz
    sudo systemctl start mevboost
    cd ~ && mev-boost -version
    echo ""
    echo "Mev-Boost 업데이트 완료"
    echo ""
  else
    exit
fi




elif [ "$check" = "n" ] ; then 
  echo "설치 취소합니다. "
  exit




else
  echo "입력 확인해주세요! [y, n]"
  exit

fi





