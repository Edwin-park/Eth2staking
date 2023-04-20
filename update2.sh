#!/bin/bash 


echo ""
echo ""
echo "---------------------------------"
echo -e "  자동 업데이트 ver : ""\033[32m"23.04.20"\033[0m"""
echo "---------------------------------"
echo ""
echo ""
echo "설치된 버전 확인중..."
echo ""


# Check versions of installed clients
	ins_vR1=$(/home/staker/bin/rocketpool -v | grep version)
	ins_vR=${ins_vR1#*version }




# Check the latest versions of clients
	lst_vR1=$(curl -s -I https://github.com/rocket-pool/smartnode-install/releases/latest | grep tag)
	lst_vR2=${lst_vR1#*tag/v}
	lst_vR=$(echo $lst_vR2 | sed 's/\r$//')



# Client selection
	echo ""
	echo "---------------------------------------------------------------"
	echo ""
	echo -e "\033[0m""  RocketPool (현재ver : ""\033[32m""$ins_vR""\033[0m"" / 설치할ver : ""\033[31;1m""$lst_vR""\033[0m"")"
	echo ""
	echo "---------------------------------------------------------------"
	echo ""

	





echo ""

echo " [주의] 로켓풀 서비스는 중지하시고, 시스템 및 로켓풀 업데이트를 시작하세요! "
read -p " r.stop 했나요? 업데이트를 시작할까요? [y , n] : " check


if [ "$check" = "y" ] ; then 
  echo "업데이트를 시작합니다... "

  sudo apt update -y && sudo apt upgrade -y && sudo apt dist-upgrade -y && sudo apt autoremove -y
  wget https://github.com/rocket-pool/smartnode-install/releases/latest/download/rocketpool-cli-linux-amd64 -O /home/staker/bin/rocketpool
  echo ""
  echo ""
  echo "시스템 전체(보안) 업데이트 완료!"
  echo ""
  echo "RocketPool v"$lst_vR" 업데이트 완료!"
  echo ""
  echo " r.install <- 명령어 실행후 r.start "
  echo ""
  echo ""
    





elif [ "$check" = "n" ] ; then 
  echo "업데이트를 취소합니다. "
  exit




else
  echo "입력을 확인해주세요! [y, n]"
  exit

fi


