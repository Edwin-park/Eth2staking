#!/bin/bash 

echo "설치하실 네트워크를 선택해주세요"
echo "1 : Prater Testnet"
echo "2 : Main net"
echo -n "[1,2] 엽력 : "
read network

if [ "$network" = "1" ] ; then 
  network="Prater Testnet"
elif [ "$network" = "2" ] ; then 
  network="Main net"
else
  echo "네트워크 착오입력 [1,2] "
  exit
fi


echo "클라이언트 버전을 입력해주세요. "

echo -n "Geth 버전 입력하세요        (ex : 1.10.25) : "
read Geth

echo -n "Lighthouse 버전 입력하세요  (ex : 3.1.0)   : "
read Lighthouse

echo -n "Mev-Boost 버전 입력하세요   (ex : 1.3.2)   : "
read Mev





echo "네트워크 및 클라이언트 버전 최종확인"

echo "네트워크 : $network"
echo "Geth v$Geth"
echo "Lighthous v$Lighthouse"
echo "Mev-Boost v$Mev"
echo ""



read -p "설치시작 [y , n] : " check


if [ "$check" = "y" ] ; then 
  echo "설치 시작합니다. "





elif [ "$check" = "n" ] ; then 
  echo "설치 취소합니다. "
  exit




else
  echo "입력 확인해주세요! [y, n]"
  exit

fi



