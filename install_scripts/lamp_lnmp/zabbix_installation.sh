#########################################################################################
#!/bin/bash
# Author: Colin
# Time: 2018-06-03 10:58:21
# Name: zabbix_installation.sh
# Version: v1.0
# Description: auto-install zabbix script
# Attention:    1. This is script is only for CentOS_x64.
#               2. lnmp enviroment must be installed in advanced.
#               3. The end of download file must be tar.gz
#               4. Create_database.sql should be put in the same folder
########################################################################################

machine=`uname -m`
if [ $machine != "x86_64" ];then
    echo "Your system is 32bit,but this script is only run on 64bit"
    exit 1
fi

download_dir=/home/colin/tools/auto_install
zabbix_dir=/usr/local/zabbix
zabbix_download_url="https://jaist.dl.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/3.4.11/zabbix-3.4.11.tar.gz"
mysql_pwd="1234"
create_database_script=`pwd`/create_database.sql
nginx_dir=/usr/local/nginx
php_dir=/usr/local/php
php_user="www"
php_group="www"

[ -f /etc/init.d/functions ] && . /etc/init.d/functions
[ -d $download_dir ] || mkdir -p $download_dir
[ -d $zabbix_dir ] && rm -rf $zabbix_dir/* || mkdir -p $zabbix_dir

check(){
    if [ $? -ne 0 ];then
        action "The last command executed failed, pls check in $2." /bin/false
        exit 1
    else
        action "$1" /bin/true
    fi
}

start_check(){
    if [ $? -eq 0 ];then
        action "$1 start" /bin/true
    else
        action "$1 start" /bin/false
        exit 2
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
    user='zabbix'
    group='zabbix'
    user_exists=$(id -nu $user)
    if [ ! $user_exists ]; then
        /usr/sbin/groupadd -f $group
        /usr/sbin/useradd -g $group $user -s /sbin/nologin -M
    fi
     
    #install zabbix
    zabbix_download
    echo "Start to install zabbix, pls wait for a moment..."
    tar -zxf $download_file_zabbix && cd $zabbix_folder
    ./configure --prefix=/usr/local/zabbix --enable-server --enable-agent --with-mysql --enable-ipv6\
    --with-net-snmp --with-libcurl --with-libxml2 &> /tmp/chk_config_zabbix.log
    check "Zabbix options check" "/tmp/chk_config_zabbix.log"
    echo "Start to compile zabbix configuration, pls wait for a moment..."
    make -j4 &> /tmp/configure_zabbix.log 
    check "Zabbix compile" "/tmp/configure_zabbix.log"
    make install &> /tmp/make_install_zabbix.log
    check "Zabbix install" "/tmp/make_install_zabbix.log" 
}

zabbix_config(){    
    cd /usr/local && chown -R zabbix:zabbix zabbix
    mysql -uroot -p"$mysql_pwd" < $create_database_script
#    mysql -uroot -p"$mysql_pwd" -e "DROP DATABASE IF EXISTS zabbix;"
#    mysql -uroot -p"$mysql_pwd" -e "CREATE DATABASE zabbix default character set utf8 collate utf8_general_ci;"
#    mysql -uroot -p"$mysql_pwd" -e "grant all privileges on zabbix.* to zabbix@localhost identified by '1234';"
#    mysql -uroot -p"$mysql_pwd" -e "use zabbix;"
    sleep 1
    mysql -uroot -p"$mysql_pwd" zabbix < $download_dir/$zabbix_folder/database/mysql/schema.sql
    mysql -uroot -p"$mysql_pwd" zabbix < $download_dir/$zabbix_folder/database/mysql/images.sql
    mysql -uroot -p"$mysql_pwd" zabbix < $download_dir/$zabbix_folder/database/mysql/data.sql
    check "Database created"

    #Config zabbix
    cd $zabbix_dir
    [ -d logs ] || mkdir logs
    chown zabbix:zabbix logs
    #modify zabbix_server.conf
    sed -i "s/^LogFile=\/tmp\/zabbix_server.log/LogFile=\/usr\/local\/zabbix\/logs\/zabbix_server.log/" $zabbix_dir/etc/zabbix_server.conf
    sed -i "s/^# PidFile=\/tmp\/zabbix_server.pid/PidFile=\/usr\/local\/zabbix\/logs\/zabbix_server.pid/" $zabbix_dir/etc/zabbix_server.conf
    sed -i "s/^# DBHost=localhost/DBHost=localhost/" $zabbix_dir/etc/zabbix_server.conf
    sed -i "s/^# DBPassword=/DBPassword=1234/" $zabbix_dir/etc/zabbix_server.conf
    sed -i "s/^# DBSocket=\/tmp\/mysql.sock/DBSocket=\/tmp\/mysql.sock/" $zabbix_dir/etc/zabbix_server.conf
    sed -i "s|^# Include=/usr/local/etc/zabbix_server.conf.d/\*.conf|Include=$zabbix_dir/etc/zabbix_server.conf.d/*.conf|" $zabbix_dir/etc/zabbix_server.conf
    check "Server configuration change"

    #modify agentd_server.conf
    sed -i "s/^# PidFile=\/tmp\/zabbix_agentd.pid/PidFile=\/usr\/local\/zabbix\/logs\/zabbix_agentd.pid/" $zabbix_dir/etc/zabbix_agentd.conf
    sed -i "s/^LogFile=\/tmp\/zabbix_agentd.log/LogFile=\/usr\/local\/zabbix\/logs\/zabbix_agentd.log/" $zabbix_dir/etc/zabbix_agentd.conf
    sed -i "s|^# Include=/usr/local/etc/zabbix_agentd.conf.d/\*.conf|Include=$zabbix_dir/etc/zabbix_agentd.conf.d/*.conf|" $zabbix_dir/etc/zabbix_agentd.conf
    check "Agent server change"
    #start zabbix_server&zabbix_agentd
    $zabbix_dir/sbin/zabbix_server &>/dev/null
    start_check "Zabbix_server"
    $zabbix_dir/sbin/zabbix_agentd &>/dev/null
    start_check "Zabbix_agentd"

    #copy webpage to  server
    cp -r $download_dir/$zabbix_folder/frontends/php/* /usr/local/nginx/html/zabbix
    chown -R nginx:nginx /usr/local/nginx/html/zabbix
    #copy start scripts to /etc/init.d
    cd $download_dir/$zabbix_folder/misc/init.d/fedora/core5/
    cp zabbix_agentd zabbix_server /etc/init.d
    [ -f /usr/local/sbin/zabbix_agentd ] || ln -s $zabbix_dir/sbin/zabbix_agentd /usr/local/sbin
    [ -f /usr/local/sbin/zabbix_server ] || ln -s $zabbix_dir/sbin/zabbix_server /usr/local/sbin
    check "Zabbix configuration"
    rm -rf $download_dir/$zabbix_folder
}

change_php_config(){
#   change file php.ini 
    sed -i "s/^post_max_size = 8M/post_max_size = 16M/" $php_dir/etc/php.ini
    sed -i "s/^max_execution_time = 30/max_execution_time = 300/" $php_dir/etc/php.ini
    sed -i "s/^max_input_time = 60/max_input_time = 300/" $php_dir/etc/php.ini
    sed -i "s/^\;always_populate_raw_post_data = -1/always_populate_raw_post_data = -1/" $php_dir/etc/php.ini
#   change file zabbix.conf.php
    ls $nginx_dir/html/zabbix/conf/zabbix.conf.php.example &>/dev/null
    [ $? -eq 0 ] && mv $nginx_dir/html/zabbix/conf/zabbix.conf.php.example $nginx_dir/html/zabbix/conf/zabbix.conf.php

    sed -i -e '7d' -e '10d' $nginx_dir/html/zabbix/conf/zabbix.conf.php
    sed -i "6a\\\$DB\['PORT'\]             = '3306';" $nginx_dir/html/zabbix/conf/zabbix.conf.php
    sed -i "9a\\\$DB\['PASSWORD'\]         = '1234';" $nginx_dir/html/zabbix/conf/zabbix.conf.php
#    sed -i "s/^\$DB\['PORT'\]\t\t\t = '0';/\$DB\['PORT'\]             = '3306';/" $nginx_dir/html/zabbix/conf/zabbix.conf.php
#    sed -i "s/^\$DB\['PASSWORD'\]\t\t\t = '';/\$DB\['PASSWORD'\]         = '1234';/" $nginx_dir/html/zabbix/conf/zabbix.conf.php
    chown -R $php_user:$php_group $nginx_dir/html/zabbix/conf
    check "Php configuration file change"

    killall php-fpm
    [ ps aux|grep php-fpm|wc -l -le 1 ] && /etc/init.d/php-fpm start &>/dev/null
    start_check "Php-fpm"
    $nginx_dir/sbin/nginx -s stop
    $nginx_dir/sbin/nginx
    start_check "Nginx"
}

main(){
    dependence_install
    sleep 1
    zabbix_install
    sleep 1
    zabbix_config
    echo "Zabbix installation completed! "
    change_php_config
    echo "Pls open Zabbix URL: http://<server_ip_or_name>/zabbix/setup.php in your brower and start installing frontend"
}

main

