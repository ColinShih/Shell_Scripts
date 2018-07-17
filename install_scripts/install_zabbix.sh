###########################################################
#!/bin/bash
# Author: Colin
# Time: 2018-06-03 10:58:21
# Name: install_zabbix.sh
# Version: v1.0
# Description: install zabbix script
# Attention: This is script is only for CentOS, the end of download file must be tar.gz
############################################################

machine=`uname -m`
if [ $machine != "x86_64" ];then
    echo "Your system is 32bit,but this script is only run on 64bit"
    exit 1
fi
download_dir=/home/colin/tools/auto_install
#download_dir=`pwd`
zabbix_dir=/usr/local/zabbix
zabbix_download_url="https://jaist.dl.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/3.4.11/zabbix-3.4.11.tar.gz"
create_database_script=`pwd`/create_database.sql
nginx_dir=/usr/local/nginx
php_dir=/usr/local/php
php_user="www"

[ -f /etc/init.d/functions ] && . /etc/init.d/functions
[ -d $download_dir ] || mkdir -p $download_dir
[ -d $zabbix_dir ] || mkdir -p $zabbix_dir

check(){
    if [ $? -ne 0 ];then
        action "The last command executed failed, pls check it." /bin/false
        sleep 1
        exit 1
    else
        action "$1 executing" /bin/true
    fi
}

zabbix_download(){
    cd $download_dir
    download_file_zabbix=`echo $zabbix_download_url|awk -F "/" '{print $NF}'`
    zabbix_folder=`echo $download_file_zabbix|awk -F ".tar.gz" '{print $1}'`
    ls $download_file_zabbix &>/dev/null
    if [ $? -ne 0 ];then
        echo "Start to download zabbix,pls wait......"
        wget -nv $zabbix_download_url -P $download_dir -o /dev/null
        check "Zabbix download"
    fi
}

dependence_install(){
    echo "Start to install dependance, pls wait for a moment..."
    yum -y install net-snmp-devel libxml2-devel libcurl-deve libevent libevent-devel >/dev/null 2>&1
    check "Dependence installation"
}

zabbix_install(){    
    #添加zabbix用户
    user='zabbix'
    group='zabbix'
    user_exists=$(id -nu $user)
    if [ ! $user_exists ]; then
        /usr/sbin/groupadd -f $group
        /usr/sbin/useradd -g $group $user -s /sbin/nologin -M
    fi
     
    #安装zabbix
    zabbix_download
    echo "Start to install zabbix, pls wait for a moment..."
    tar -zxf $download_file_zabbix && cd $zabbix_folder
    ./configure --prefix=/usr/local/zabbix --enable-server --enable-agent --with-mysql --enable-ipv6\
    --with-net-snmp --with-libcurl --with-libxml2 &> /tmp/chk_config_zabbix.log
     
    [ $? -eq 0 ] && action "Checking zabbix options" /bin/true
    echo "Start to compile zabbix configuration, pls wait for a moment..."
    [ $? -eq 0 ] && make -j4 &> /tmp/configure_zabbix.log 
    [ $? -eq 0 ] && make install &> /tmp/make_install_zabbix.log
    check "Zabbix installation" 
#    rm -rf $download_dir/$zabbix_folder
}

zabbix_config(){    
    cd /usr/local && chown -R zabbix:zabbix zabbix
    mysql -uroot -p'1234' < $create_database_script
    sleep 1
    mysql -uroot -p'1234' zabbix < $download_dir/$zabbix_folder/database/mysql/schema.sql
    mysql -uroot -p'1234' zabbix < $download_dir/$zabbix_folder/database/mysql/images.sql
    mysql -uroot -p'1234' zabbix < $download_dir/$zabbix_folder/database/mysql/data.sql

    #配置zabbix
    cd $zabbix_dir
    [ -d logs ] || mkdir logs
    chown zabbix:zabbix logs
    sed -i "s/^LogFile=\/tmp\/zabbix_server.log/LogFile=\/usr\/local\/zabbix\/logs\/zabbix_server.log/" $zabbix_dir/etc/zabbix_server.conf
    sed -i "s/^# PidFile=\/tmp\/zabbix_server.pid/PidFile=\/usr\/local\/zabbix\/logs\/zabbix_server.pid/" $zabbix_dir/etc/zabbix_server.conf
    sed -i "s/^# DBHost=localhost/DBHost=localhost/" $zabbix_dir/etc/zabbix_server.conf
    sed -i "s/^# DBPassword=/DBPassword=1234/" $zabbix_dir/etc/zabbix_server.conf
    sed -i "s/^# DBSocket=\/tmp\/mysql.sock/DBSocket=\/tmp\/mysql.sock/" $zabbix_dir/etc/zabbix_server.conf
    sed -i "s/^# Include=\/usr\/local\/etc\/zabbix_server.conf.d\/\*.conf/Include=\/usr\/local\/etc\/zabbix_server.conf.d\/*.conf/" $zabbix_dir/etc/zabbix_server.conf
    
    
    sed -i "s/^# PidFile=\/tmp\/zabbix_agentd.pid/PidFile=\/usr\/local\/zabbix\/logs\/zabbix_agentd.pid/" $zabbix_dir/etc/zabbix_agentd.conf
    sed -i "s/^LogFile=\/tmp\/zabbix_agentd.log/LogFile=\/usr\/local\/zabbix\/logs\/zabbix_agentd.log/" $zabbix_dir/etc/zabbix_agentd.conf
    sed -i "s/^# Include=\/usr\/local\/etc\/zabbix_agentd.conf.d\/\*.conf/Include=\/usr\/local\/etc\/zabbix_agentd.conf.d\/*.conf/" $zabbix_dir/etc/zabbix_agentd.conf
    $zabbix_dir/sbin/zabbix_server
    $zabbix_dir/sbin/zabbix_agentd

    mv $download_dir/$zabbix_folder/frontends/php/ /usr/local/nginx/html/zabbix
    chown -R nginx:nginx /usr/local/nginx/html/zabbix
    rm -rf $download_dir/$zabbix_folder
    check "Zabbix configuration"
}

change_php_config(){
#   change file php.ini 
    sed -i "s/^post_max_size = 8M/post_max_size = 16M/" $php_dir/etc/php.ini
    sed -i "s/^max_execution_time = 30/max_execution_time = 300/" $php_dir/etc/php.ini
    sed -i "s/^max_input_time = 60/max_input_time = 300/" $php_dir/etc/php.ini
    sed -i "s/^\;always_populate_raw_post_data = -1/always_populate_raw_post_data = -1/" $php_dir/etc/php.ini
#   change file zabbix.conf.php
    mv $nginx_dir/html/zabbix/conf/zabbix.conf.php.example $nginx_dir/html/zabbix/conf/zabbix.conf.php
    chown $php_user $nginx_dir/html/zabbix/conf

#    sed -i "s/^\$DB['PORT']             = '0';/\$DB['PORT']             = '3306';/" $nginx_dir/html/zabbix/conf/zabbix.conf.php
#    sed -i "s/^\$DB['PASSWORD']         = '';/\$$DB['PASSWORD']         = '1234';/" $nginx_dir/html/zabbix/conf/zabbix.conf.php

    killall php-fpm
    /etc/init.d/php-fpm start
    $nginx_dir/sbin/nginx -s stop
    $nginx_dir/sbin/nginx
}

main(){
    dependence_install
    sleep 1
    zabbix_install
    sleep 1
    zabbix_config
    echo "Installation completed! "
    change_php_config
    echo "Pls open Zabbix URL: http://<server_ip_or_name>/zabbix/setup.php in your brower and start installing frontend"
}

main

