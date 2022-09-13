#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

curPath=`pwd`
rootPath=$(dirname "$curPath")
rootPath=$(dirname "$rootPath")
serverPath=$(dirname "$rootPath")

install_tmp=${rootPath}/tmp/mw_install.pl
VERSION=$2

cpu_arch=`arch`
if [[ $cpu_arch != "x86_64" ]];then
  echo 'Does not support non-x86 system installation'
  exit 0
fi

# if [ -f "/usr/bin/apt-get" ];then
# 	systemver='ubuntu'
# elif [ -f "/etc/redhat-release" ];then
# 	systemver=`cat /etc/redhat-release|sed -r 's/.* ([0-9]+)\..*/\1/'`
# 	postfixver=`postconf mail_version|sed -r 's/.* ([0-9\.]+)$/\1/'`
# else
# 	echo 'Unsupported system version'
# 	exit 0
# fi

## curl -fsSL  https://raw.githubusercontent.com/midoks/mdserver-web/dev/scripts/update_dev.sh | bash
## debug:
## cd /www/server/mdserver-web/plugins/mail && bash install.sh install 1.0

bash ${rootPath}/scripts/getos.sh
OSNAME=`cat ${rootPath}/data/osname.pl`
OSNAME_ID=`cat /etc/*-release | grep VERSION_ID | awk -F = '{print $2}' | awk -F "\"" '{print $2}'`



Install_debain(){
	hostname=`hostname`
  	# 安装postfix和postfix-sqlite
  	debconf-set-selections <<< "postfix postfix/mailname string ${hostname}"
  	debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
  	apt install postfix -y
  	apt install postfix-sqlite -y
  	apt install sqlite -y

  	# 安装dovecot和dovecot-sieve
  	apt install dovecot-core dovecot-pop3d dovecot-imapd dovecot-lmtpd dovecot-sqlite dovecot-sieve -y

  	apt install rspamd -y

  	apt install cyrus-sasl-plain -y
}

Install_App()
{
	echo '正在安装脚本文件...' > $install_tmp
	mkdir -p $serverPath/source

	if [[ $OSNAME = "centos" ]]; then

		if [[ $OSNAME_ID == "7" ]];then
			Install_centos7
		fi

		if [[ $OSNAME_ID == "8" ]];then
			Install_centos8
		fi

  	elif [[ $OSNAME = "debian" ]]; then
    	Install_debain
  	else
    	Install_ubuntu
  	fi

  	filesize=`ls -l /etc/dovecot/dh.pem | awk '{print $5}'`
  	echo $filesize

  	if [ ! -f "/etc/dovecot/dh.pem" ] || [ $filesize -lt 300 ]; then
    	openssl dhparam 2048 > /etc/dovecot/dh.pem
  	fi
}

Uninstall_App()
{

	if [ -f $serverPath/mail/initd/mail ];then
		$serverPath/mail/initd/mail stop
	fi

	rm -rf $serverPath/mail
	echo "Uninstall_Mail" > $install_tmp
}

action=$1
if [ "${1}" == 'install' ];then
	Install_App
else
	Uninstall_App
fi
