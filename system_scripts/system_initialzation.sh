if [ $USER != "root" ]; then
    echo "pls use sudo to run this scripts.."
    exit 1
fi

cd /usr/local/src
wget http://mirrors.163.com/.help/CentOS6-Base-163.repo
cd /etc/yum.repos.d/
mv CentOS-Base.repo CentOS-Base.repo.bak
cp /usr/local/src/CentOS6-Base-163.repo ./CentOS-Base.repo
yum clean all #清除yum缓存
yum makecache #重建缓存
yum update -y  #升级Linux系统
cd ../
cd /usr/local/src
wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
rpm -ivh epel-release-6-8.noarch.rpm
yum -y install gcc gcc-c++ vim-enhanced unzip unrar sysstat
yum -y install ntp
echo "01 01 * * * /usr/sbin/ntpdate ntp.api.bz    >> /dev/null 2>&1" >> /etc/crontab
/usr/sbin/ntpdate ntp.api.bz
service crond restart

ulimit -SHn 65534
echo "ulimit -SHn 65534" >> /etc/rc.local
cat >> /etc/security/limits.conf << EOF
*                     soft     nofile             65535
*                     hard     nofile             65535
EOF
echo "fs.file-max=419430" >> /etc/sysctl.conf

cat >> /etc/sysctl.conf << EOF
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 1
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 10000 65535
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_max_tw_buckets = 36000
net.ipv4.route.gc_timeout = 100
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_synack_retries = 1
net.core.somaxconn = 16384
net.core.netdev_max_backlog = 16384
net.ipv4.tcp_max_orphans = 16384

EOF
/sbin/sysctl -p

sed -i 's@ca::ctrlaltdel:/sbin/shutdown -t3 -r now@#ca::ctrlaltdel:/sbin/shutdown -t3 -r now@' /etc/inittab
sed -i 's@SELINUX=enforcing@SELINUX=disabled@' /etc/selinux/config
service iptables stop
chkconfig iptables off
sed -i 's@#PermitRootLogin yes@PermitRootLogin no@' /etc/ssh/sshd_config 
sed -i 's@#PermitEmptyPasswords no@PermitEmptyPasswords no@' /etc/ssh/sshd_config 
sed -i 's@#UseDNS yes@UseDNS no@' /etc/ssh/sshd_config /etc/ssh/sshd_config
service sshd restart
echo "install ipv6 /bin/true" > /etc/modprobe.d/disable-ipv6.conf
echo "IPV6INIT=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0
chkconfig ip6tables off
for i in `chkconfig --list|grep 3:on|awk '{print $1}'`;do chkconfig --level 3 $i off;done
for CURSRV  in crond rsyslog sshd network;do chkconfig --level 3 $CURSRV on;done
reboot
