#########################################################################################
#!/bin/bash
# Author: Colin
# Time: 2018-07-09 12:49:28
# Name: lnmp.sh
# Version: v1.3
# Description:this is to install lnmp environment
# Attention: This is script is only for CentOS, the end of download file must be tar.gz
#            both CentOS6,CentOS7 can be used
#            For mysql installation, using binary package, and no multiple instances used
#            nginx version: 1.8.1
#            mysql version: 5.6.36
#            php version:  5.6.12
#########################################################################################

machine=`uname -m`
if [ $machine != "x86_64" ];then
    echo "Your system is 32bit,but this script is only run on 64bit"
    exit 1
fi

download_dir=/home/colin/tools/auto_install
nginx_dir=/usr/local/nginx
mysql_dir=/usr/local/mysql
php_dir=/usr/local/php
nginx_download_url="http://nginx.org/download/nginx-1.8.1.tar.gz"
#binary package
#mysql_download_url="http://mirrors.sohu.com/mysql/MySQL-5.6/mysql-5.6.36-linux-glibc2.5-x86_64.tar.gz"
#source code package
mysql_download_url="https://mirrors.tuna.tsinghua.edu.cn/mysql/downloads/MySQL-5.6/mysql-5.6.39.tar.gz"
php_download_url="http://mirrors.sohu.com/php/php-5.6.12.tar.gz"

#mysql_conf_dir="/home/colin/conf/my.cnf"
root_pwd="1234"

[ -f /etc/init.d/functions ] && . /etc/init.d/functions
[ -d $download_dir ] || mkdir -p $download_dir

cat <<EOF
    ####################################################################
    #             LNMP auto installation system                        #
    #                  1) install nginx                                #
    #                  2) install mysql                                #
    #                  3) install php                                  #
    #                  4) install lnmp                                 #
    ####################################################################
EOF
read -p "Pls choose the nubmer above you want to operate: " num

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
        action "Starting $1" /bin/true
    else
        action "Starting $1" /bin/false
        exit 2
    fi
}
    

nginx_download(){
    cd $download_dir
    download_file_nginx=`echo $nginx_download_url|awk -F "/" '{print $NF}'`
    nginx_folder=`echo $download_file_nginx|awk -F ".tar.gz" '{print $1}'`
    ls $download_file_nginx &>/dev/null
    if [ $? -ne 0 ];then
        echo "Start to download nginx,pls wait......"
        wget -nv $nginx_download_url -P $download_dir -o /dev/null
        check "Nginx download"
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
        check "Mysql download"
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
        check "Php download"
    fi  
}

dependence_install(){
    echo "Start to install dependance, pls wait for a moment..."
    yum -y install vim-enhanced ncurses-devel elinks gcc gcc-c++ flex bison autoconf automake \
    gzip net-snmp-devel net-snmp ncurses-devel pcre pcre-devel openssl openssl-devel\
    libjpeg-devel libpng-devel libtiff-devel freetype-devel libXpm-devel gettext-devel  pam-devel libtool libtool-ltdl\
    fontconfig-devel libxml2-devel curl-devel  libicu libicu-devel libmcrypt libmcrypt-devel libmhash libmhash-develi\
    >/dev/null 2>&1
    check "Dependence install"
}

nginx_install(){    
    user='nginx'
    group='nginx'
    user_exists=$(id -nu $user)
    if [ ! $user_exists ]; then
        /usr/sbin/groupadd -f $group
        /usr/sbin/useradd -g $group $user -s /sbin/nologin -M
    fi
     
    #install nginx
    nginx_download
    echo "Start to install nginx, pls wait for a moment..."
    tar -zxf $download_file_nginx && cd $nginx_folder
    ./configure --prefix=$nginx_dir  --pid-path=$nginx_dir/logs/nginx.pid   --user=$user   --group=$group --with-http_ssl_module \
    --with-http_flv_module   --with-http_stub_status_module  --with-http_gzip_static_module --with-pcre &> /tmp/chk_config_nginx.log
    check "Nginx options check" "/tmp/chk_config_nginx.log" 

    echo "Start to compile nginx configuration, pls wait for a moment..."
    make -j4 &> /tmp/configure_nginx.log 
    check "Nginx compile" "/tmp/configure_nginx.log"
    make install &> /tmp/make_install_nginx.log
    check "Nginx install" "/tmp/make_install_nginx.log" 
    rm -rf $download_dir/$nginx_folder
}

nginx_config(){    
    #start nginx
    [ `lsof -i :80|wc -l` -lt 1 ] && $nginx_dir/sbin/nginx &>/dev/null
    start_check "Nginx" 

    #config nginx
    sed -i "s/^\#pid        logs\/nginx.pid;/pid        logs\/nginx.pid;/" $nginx_dir/conf/nginx.conf    
    sed -i '56a\location ~ \.php$ {\n\    root          html;\n\    fastcgi_pass  127.0.0.1:9000;\n\    fastcgi_index  index.php;\n\    fastcgi_param  SCRIPT_FILENAME  /usr/local/nginx/html$fastcgi_script_name;\n\    include        fastcgi_params;\n\}\n' $nginx_dir/conf/nginx.conf
    $nginx_dir/sbin/nginx -s reload
    echo -e '<?php\n phpinfo(); \n ?>\n' >$nginx_dir/html/index.php
    check "Nginx configure"
}

mysql_install(){
    user='mysql'
    group='mysql'
    user_exists=$(id -nu $user)
    if [ ! $user_exists ]; then
        /usr/sbin/groupadd -f $group
        /usr/sbin/useradd -g $group $user -s /sbin/nologin -M
    fi
     
    #install Mysql using binary package
    mysql_download
    echo "Start to install mysql, pls wait for a moment..." 
    tar -zxf $download_file_mysql  
    [ $? -eq 0 ] && mv $mysql_folder/* $mysql_dir
    check "Mysql install"
    rm -rf $download_dir/$mysql_folder
}
 
mysql_config(){
    #config mysql
#    mkdir -p /data/mysql
    echo "Start to configure mysql, pls wait for a moment..."
    chown -R mysql:mysql $mysql_dir
    $mysql_dir/scripts/mysql_install_db  --basedir=$mysql_dir --datadir=/data/3306/data --user=$user &>/tmp/chk_mysql.log
    check  "Checking mysql options" 
    cp $mysql_dir/support-files/my-default.cnf  /etc/my.cnf
    sed -i '7d' /etc/my.cnf
    sed -i "22a\[client]\n\default-character-set=utf8\n\port=3306\n\socket=/tmp/mysql.sock\n\[mysqld]\n\basedir=/usr/local/mysql\n\datadir=/usr/local/mysql/data\ncharacter_set_server=utf8\n\pid-file=/usr/local/mysql/data/mysql.pid\n\user=mysql\n\max_connections=1000\n " /etc/my.cnf
    cp $mysql_dir/support-files/mysql.server  /etc/init.d/mysqld
    sed -i "s#^basedir=#basedir=$mysql_dir#" /etc/init.d/mysqld
    sed -i "s#^datadir=#datadir=$mysql_dir/data#" /etc/init.d/mysqld
    [ $? -eq 0 ] && action "Mysql configuration"

     /etc/init.d/mysqld start &>/dev/null
     start_check "Mysql"
#    create admin account
    [ $? -eq 0 ] && mysqladmin -uroot password "$root_pwd"
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
     
    #install php
    yum install -y libxml2-devel openssl-devel libcurl-devel libjpeg-devel libpng-devel libicu-devel openldap-devel >/dev/null 2>&1
    php_download
    echo "Start to install php, pls wait for a moment..." 
    tar -zxf $download_file_php && cd $php_folder
    ./configure --prefix=$php_dir --with-config-file-path=$php_dir/etc\
     --with-mysql=$mysql_dir  --with-mysqli=$mysql_dir/bin/mysql_config\
     --enable-fpm\
     --enable-mbstring\
     --enable-soap\
     --enable-zip\
     --enable-calendar\
     --enable-bcmath\
     --enable-exif\
     --enable-ftp\
     --enable-intl\
     --enable-sockets\
     --with-openssl\
     --with-zlib\
     --with-curl\
     --with-gd\
     --with-zlib-dir=/usr/lib\
     --with-png-dir=/usr/lib\
     --with-jpeg-dir=/usr/lib\
     --with-freetype-dir=/usr/lib\
     --with-gettext\
     --with-mhash\
     --with-mysql-sock=/data/3306/mysql.sock\
     --with-mysqli=mysqlnd\
     --with-pdo-mysql=mysqlnd\
     --with-fpm-user=$user\
     --with-fpm-group=$group &> /tmp/chk_php.log
#####################previous compile options####################################    
#    --prefix=/usr/local/php\
#    --with-config-file-path=/usr/local/php/etc\
#    --with-mysql=/usr/local/mysql\
#    --with-mysqli=mysqlnd\ 
#    --with-pdo-mysql=mysqlnd\
#    --with-iconv-dir=/usr/local/libiconv\
#    --with-freetype-dir\ 
#    --with-jpeg-dir\ 
#    --with-zlib\ 
#    --disable-rpath\
#    --enable-safe-mode\ 
#    --enable-bcmath\ 
#    --enable-shmop\ 
#    --enable-sysvsem\ 
#    --enable-inline-optimization\ 
#    --with-curl\ 
#    --with-curlwrappers\
#    --enable-fpm\ 
#    --enable-mbstring\ 
#    --with-gd\ 
#    --enable--gd-native-ttf\ 
#    --with-openssl\
#    --with-mhash\ 
#    --enable-sockets\ 
#    --with-xmlrpc\
#    --enable-zip\ 
#    --enable-soap\ 
#    --enable-short-tags\ 
#    --enable-zend-multibyte\ 
#    --enable-static\
#    --with-xsl\ 
#    --with-fpm-user=nginx\ 
#    --with-fpm-group=nginx\ 
#    --enable-ftp
###############################################################
    check "Checking php options" "/tmp/chk_php.log"  
    echo "Start to compile php configuration,it may take you a short time,pls be patient..."
    make -j4 &> /tmp/configure_php.log
    check "Php compile" "/tmp/configure_php.log"
    make install &> /tmp/make_install_php.log
    check "Php install" "/tmp/configure_php.log"
}

php_config(){
    #config php
    cd $download_dir/$php_folder
    cp php.ini-development  $php_dir/etc/php.ini
    sed -i 's#^;date.timezone =#date.timezone=Asia/Shanghai#' $php_dir/etc/php.ini
    cp  $php_dir/etc/php-fpm.conf.default  $php_dir/etc/php-fpm.conf
    cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
    chmod +x /etc/init.d/php-fpm
    check "Php configuration" 
    rm -rf $download_dir/$php_folder
    #start php-fpm
    [ `ps aux|grep php-fpm|wc -l` -le 1 ] && $php_dir/sbin/php-fpm &>/dev/null
    start_check "Php-fpm"
#    /etc/init.d/php-fpm start
#    chkconfig php-fpm on
}

main(){
    [ -d $nginx_dir ] && rm -rf $nginx_dir/* || mkdir -p $nginx_dir
    [ -d $mysql_dir ] && rm -rf $mysql_dir/* || mkdir -p $mysql_dir
    [ -d $php_dir ] && rm -rf $php_dir/* || mkdir -p $php_dir
    dependence_install
    sleep 1
    nginx_install
    sleep 1
    nginx_config
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
        [ -d $nginx_dir ] && rm -rf $nginx_dir/* || mkdir -p $nginx_dir
        dependence_install
        nginx_install
        sleep 1
        nginx_config
        echo "Nginx installation completed! "
        ;;
    2)
        [ -d $mysql_dir ] && rm -rf $mysql_dir/* || mkdir -p $mysql_dir
        dependence_install
        mysql_install
        sleep 1
        mysql_config
        echo "Mysql installation completed! "
        ;;
    3)
        [ -d $php_dir ] && rm -rf $php_dir/* || mkdir -p $php_dir
        dependence_install
        php_install
        sleep 1
        php_config
        echo "Php installation completed! "
        ;;
    4)
        main
        echo "LNMP installation completed! "
        ;;
    *)
        echo "The number you input must be [1|2|3|4]."
        ;;
esac

