##############################################
#!/bin/bash
# Author: Colin
# Mail: 499219677@qq.com
# Time: 2018-07-17 22:17:12
# Name: multi_mysql_start.sh
# Version:1.0
# Description: 
##############################################
port=3306
MysqlUser="root"
MysqlPwd="1234"
MysqlDir="/usr/local/mysql"
mysql_start="mysqld_safe --defaults-file=$MysqlDir/data/$port/my.cnf &"
mysql_stop="mysqladmin -uroot -p1234 -S "

[ -f /etc/init.d/functions ] $$ . /etc/init.d/functions

start(){
    if [ `netstat -lnt|grep "$port"|wc -l` -eq 0 ];then
        printf "Start mysql...\n"
        /bin/sh $MysqlDir/bin/mysqld_safe --defaults-file=$MysqlDir/data/$port/my.cnf 2>&1 
}

stop(){

}

restart(){

}
