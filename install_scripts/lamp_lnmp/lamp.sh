###########################################################
#!/bin/bash
# Author: Colin
# Time: 2018-06-11 19:51:21
# Name: lamp.sh
# Version: v1.1
# Description:this is to install lamp environment
# Attention: the end of install download file must be tar.gz
############################################################

#version=`grep -o " [0-9]" /etc/redhat-release|cut -d" " -f2`
#if [ "$version" -eq 7 ];then
#    echo    "system version is CentOS 7"
#else [ "$version" -eq 6 ];
#    echo    "system version is CentOS 6"
#fi
#
machine=`uname -m`
if [ $machine != "x86_64" ];then
    echo "Your system is 32bit,but this script is only run on 64bit"
    exit 1
fi

download_dir=/home/colin/tools/auto_install
apache_dir=/usr/local/apache2
mysql_dir=/usr/local/mysql
php_dir=/usr/local/php
apache_download_url="http://mirrors.sohu.com/apache/httpd-2.4.34.tar.gz"
mysql_download_url="http://mirrors.sohu.com/mysql/MySQL-5.6/mysql-5.6.36-linux-glibc2.5-x86_64.tar.gz"
php_download_url="http://mirrors.sohu.com/php/php-5.6.12.tar.gz"


[ -f /etc/init.d/functions ] && . /etc/init.d/functions
[ -d $download_dir ] || mkdir -p $download_dir
[ -d $apache_dir ] || mkdir -p $apache_dir
[ -d $mysql_dir ] || mkdir -p $mysql_dir
[ -d $php_dir ] || mkdir -p $php_dir

cat <<EOF
    ####################################################################
    #             LAMP auto installation system                        #
    #                  1) install apache                               #
    #                  2) install mysql                                #
    #                  3) install php                                  #
    #                  4) install lamp                                 #
    ####################################################################
EOF
read -p "Pls choose the nubmer above you want to operate: " num

check(){
    if [ $? -ne 0 ];then
        action "The last command executed failed, pls check it." /bin/false
        sleep 1
        exit 1
    else
        action "$1 executing" /bin/true
    fi
}

apache_download(){
    cd $download_dir
    download_file_apache=`echo $apache_download_url|awk -F "/" '{print $NF}'`
    apache_folder=`echo $download_file_apache|awk -F ".tar.gz" '{print $1}'`
    ls $download_file_apache &>/dev/null
    if [ $? -ne 0 ];then
        echo "Start to download apache,pls wait......"
        wget -nv $apache_download_url -P $download_dir -o /dev/null
        check "Apache download"
    fi
    apr_name=apr-1.6.3
    apr_util_name=apr-util-1.6.1
    ls $apr_name $apr_util_name &>/dev/null
    if [ $? -ne 0 ];then
        wget "https://mirrors.tuna.tsinghua.edu.cn/apache/apr/apr-1.6.3.tar.gz" &>/dev/null
        wget "https://mirrors.tuna.tsinghua.edu.cn/apache/apr/apr-util-1.6.1.tar.gz" &>/dev/null
        tar zxf apr-1.6.3.tar.gz && cp -fr apr-1.6.3 ./$apache_folder/srclib/apr &>/dev/null 
        tar zxf apr-util-1.6.1.tar.gz && cp -fr apr-util-1.6.1 ./$apache_folder/srclib/apr-util &>/dev/null
        rm -rf apr-1.6.3.tar.gz apr-util-1.6.1.tar.gz $apr_name $apr_util_name
    fi
}

mysql_download(){
    cd $download_dir
    download_file_mysql=`echo $mysql_download_url|awk -F "/" '{print $NF}'`
    mysql_folder=`echo $download_file_mysql|awk -F ".tar.gz" '{print $1}'`
    ls $download_file_mysql &>/dev/null   
    if [ $? -ne 0 ];then
        echo "Start to download mysql,pls wait for a moment..."
        wget -nv $mysql_download_url -P $download_dir -o /dev/null
        check "mysql download"
    fi  
}

php_download(){
    cd $download_dir
    download_file_php=`echo $php_download_url|awk -F "/" '{print $NF}'`
    php_folder=`echo $download_file_php|awk -F ".tar.gz" '{print $1}'`
    ls $download_file_php &>/dev/null   
    if [ $? -ne 0 ];then
        echo "Start to download php, pls wait for a moment..."
        wget -nv $php_download_url -P $download_dir -o /dev/null
        check "php download"
    fi  
}

dependence_install(){
    echo "Start to install dependance, pls wait for a moment..."
    yum -y install vim-enhanced ncurses-devel elinks gcc gcc-c++ flex bison autoconf automake \
    gzip net-snmp-devel net-snmp ncurses-devel pcre pcre-devel openssl openssl-devel\
    libjpeg-devel libpng-devel libtiff-devel freetype-devel libXpm-devel gettext-devel  pam-devel libtool libtool-ltdl\
    fontconfig-devel libxml2-devel curl-devel  libicu libicu-devel libmcrypt libmcrypt-devel libmhash libmhash-develi\
    >/dev/null 2>&1
    check "Dependence installation"
}

apache_install(){    
    user='apache'
    group='apache'
    user_exists=$(id -nu $user)
    if [ ! $user_exists ]; then
        /usr/sbin/groupadd -f $group
        /usr/sbin/useradd -g $group $user -s /sbin/nologin -M
    fi
     
    #install apache
    apache_download
    
    echo "Start to install apache, pls wait for a moment..."
    tar -zxf $download_file_apache && cd $apache_folder
    ./configure --prefix=$apache_dir  --with-mpm=worker --enable-cache --enable-disk-cache\
     --enable-mem-cache--enable-file-cache --enable-nonportable-atomics --with-included-apr  --enable-mods-shared=most\
     --enable-so--enable-rewrite --enable-ssl &>/dev/null
     
    [ $? -eq 0 ] && action "Checking apache options" /bin/true
    echo "Start to compile apache configuration, pls wait for a moment..."
    [ $? -eq 0 ] && make -j4 &> /tmp/configure_apache.log 
    [ $? -eq 0 ] && make install &> /tmp/make_install_apache.log
    check "Apache installation" 
    rm -rf $download_dir/$apache_folder
}

apache_config(){    
     
    #config apache
    sed -i "389a\\\tAddType application/x-httpd-php .php" $apache_dir/conf/httpd.conf
    sed -i 's/DirectoryIndex index.html/DirectoryIndex index.html index.htm index.php/' $apache_dir/conf/httpd.conf
    sed -i "s/^\#ServerName www.example.com:80/ServerName localhost:80/" $apache_dir/conf/httpd.conf
    $apache_dir/bin/apachectl -t
    [ `lsof -i :80|wc -l` -lt 1 ] && $apache_dir/bin/apachectl start
    echo -e '<?php\n phpinfo(); \n ?>\n' >$apache_dir/htdocs/index.php
    check "Apache configuration"
}

mysql_install(){
    user='mysql'
    group='mysql'
    user_exists=$(id -nu $user)
    if [ ! $user_exists ]; then
        /usr/sbin/groupadd -f $group
        /usr/sbin/useradd -g $group $user -s /sbin/nologin -M
    fi
     
    #install Mysql
    mysql_download
    echo "Start to install mysql, pls wait for a moment..." 
    tar -zxf $download_file_mysql  
    [ $? -eq 0 ] && mv $mysql_folder/* $mysql_dir
    check "Mysql installation"
    rm -rf $download_dir/$mysql_folder
}
 
mysql_config(){
    #config mysql
#    mkdir -p /data/mysql
    echo "Start to configure mysql, pls wait for a moment..."
    chown -R mysql:mysql $mysql_dir
    $mysql_dir/scripts/mysql_install_db  --basedir=$mysql_dir --datadir=$mysql_dir/data --user=mysql  &>/dev/null
    check "Check mysql options"
    cp $mysql_dir/support-files/my-default.cnf  /etc/my.cnf
    cp $mysql_dir/support-files/mysql.server  /etc/init.d/mysqld
    sed -i "s#^basedir=#basedir=$mysql_dir#" /etc/init.d/mysqld
    sed -i "s#^datadir=#datadir=$mysql_dir/data#" /etc/init.d/mysqld
    check "Configuration mysql" 
    #start mysql
    /etc/init.d/mysqld start
#    chkconfig mysqld on
}

php_install(){
    user='www'
    group='www'
    user_exists=$(id -nu $user)
    if [ ! $user_exists ]; then
        /usr/sbin/groupadd -f $group
        /usr/sbin/useradd -g $group $user -s /sbin/nologin -M
    fi
     
    #install php,apxs is the php compiler of apache
    yum install -y libxml2-devel openssl-devel libcurl-devel libjpeg-devel libpng-devel libicu-devel openldap-devel >/dev/null 2>&1
    php_download
    echo "Start to install php, pls wait for a moment..." 
    tar -zxf $download_file_php && cd $php_folder
    ./configure --prefix=$php_dir --with-config-file-path=$php_dir/etc\
     --with-mysql=$mysql_dir  --with-mysqli=$mysql_dir/bin/mysql_config\
     --with-apxs2=$apache_dir/bin/apxs\
     --enable-fpm\
     --enable-mbstring\
     --enable-soap\
     --enable-zip\
     --enable-calendar\
     --enable-bcmath\
     --enable-exif\
     --enable-ftp\
     --enable-intl\
     --with-openssl\
     --with-zlib\
     --with-curl\
     --with-gd\
     --with-zlib-dir=/usr/lib\
     --with-png-dir=/usr/lib\
     --with-jpeg-dir=/usr/lib\
     --with-gettext\
     --with-mhash\
     --with-fpm-user=www\
     --with-fpm-group=www &> /tmp/chk_php.log
    
    [ $? -eq 0 ] && action "checking php options" /bin/true  
    echo "Start to compile php configuration for a moment..."
    [ $? -eq 0 ] && make -j4 &> /tmp/configure_php.log 
    [ $? -eq 0 ] && make install &> /tmp/make_install_php.log
    check "php install"
}

php_config(){
    #config php
    cd $download_dir/$php_folder
    cp php.ini-development  $php_dir/etc/php.ini
    sed -i 's#^;date.timezone =#date.timezone=Asia/Shanghai#' $php_dir/etc/php.ini
    cp  $php_dir/etc/php-fpm.conf.default  $php_dir/etc/php-fpm.conf
    cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
    chmod +x /etc/init.d/php-fpm
    check "Configuration php" 
    rm -rf $download_dir/$php_folder
    #start php-fpm
    [ `ps aux|grep php-fpm|wc -l` -le 1 ] && $php_dir/sbin/php-fpm
#    /etc/init.d/php-fpm start
#    chkconfig php-fpm on
}

main(){
    dependence_install
    sleep 1
    apache_install
    sleep 1
    apache_config
    sleep 1
    mysql_install
    sleep 1
    mysql_config
    sleep 1
    php_install
    sleep 1
    php_config
}


expr $num + 1 &>/dev/null
if [ $? -ne 0 ];then
    echo "The number you input must be [1|2|3|4]."
    exit 1
fi
case $num in
    1)
        dependence_install
        apache_install
        sleep 1
        apache_config
        echo "Installation completed! "
        ;;
    2)
        dependence_install
        mysql_install
        sleep 1
        mysql_config
        echo "Installation completed! "
        ;;
    3)
        dependence_install
        php_install
        sleep 1
        php_config
        echo "Installation completed! "
        ;;
    4)
        main
        echo "Installation completed! "
        ;;
    *)
        echo "The number you input must be [1|2|3|4]."
        ;;
esac

