#1.update yum resource
#2.close SELinux
#3.close iptables
#4.optimize auto-started service
#5.grant user colin to sudo
#6.time sync
#7.core optimization
#!/bin/bash
#Author: Colin
#set env
export PATH=$PATH:/bin:/sbin:/usr/sbin
#Require root to run this script
if [ "$UID" != "0" ];then
  echo "Pls run this script by root"
  exit
fi

#define cmd var
SERVICE=`which service`
CHKCONFIG=`which chkconfig`
function mod_yum(){
  if [ -e /etc/yum.resp.d/CentOS-Base.repo ];then
     mv /etc/yum.resp.d/CentOS-Base.repo /etc/yum.resp.d/CentOS-Base.repo.bak&&\
     wget -O /etc/yum.resp.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/CentOS-6.repo
  fi
}

function close_selinux(){
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
    setenforce 0 $>/dev/null
}

function close_iptables(){
    /etc/init.d/iptales stop
    chkconfig iptables off
}

function least_services(){
    chkconfig|awk '{print "chkconfig",$1,"off"}'|bash
    chkconfig|egrep "crond|sshd|network|rsyslog|sysstat"|awk '{print "chkconfig",$1,"on"}'|bash
}

function add_user(){
    if[ `grep -w oldboy /etc/passwd|wc -l` -lt 1 ] ;then
	useradd colin
	echo 123456|passwd --stdin oldboy\
	cp /etc/sudoers /etc/sudoers.ori
	echo "colin ALL=(ALL) NOPASSWD: ALL" >>/etc/sudoers
	tail -l /etc/sudoers
	visudo -c &>/dev/null
    fi
}

