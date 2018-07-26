##########################################################
#!/bin/bash
# Author: Colin
# Mail: 499219677@qq.com
# Time: 2018-07-17 22:17:12
# Name: mysqld_multi_instances_start.sh
# Version:1.0
# Description: multiple_instance mysql start scripts
###########################################################
[ -f /etc/init.d/functions ] && . /etc/init.d/functions
Path=/usr/local/mysql
Mysql_bin=$Path/bin
Mysql_owner="mysql"
Mysql_user="root"
Mysql_pwd="1234"
action=$1
port=$2
mysql_start="$Mysql_bin/mysqld_safe --defaults-file=/data/$port/my.cnf --user=$Mysql_owner"
mysql_stop="$Mysql_bin/mysqladmin -u$Mysql_user -p$Mysql_pwd -S /data/$port/mysql.sock shutdown"
pid_file=/data/$port/mysqld.pid
RETVAL=0

Usage(){
    echo "Usage: $0 (start|stop|restart|status) port"
}

if [ $# -ne 2 ];then
    Usage
    exit 1
fi

start(){
    if [ -f $pid_file ];then
        echo "mysql $port is already running.."
        RETVAL=2
    else
        $mysql_start >/dev/null 2>&1 &
        sleep 5
        if [ -f $pid_file ];then
            action "Start mysql $port" /bin/true
        else
            action "Start mysql $port" /bin/false
        fi
    fi
    return $RETVAL
}

stop(){
    if [ -f $pid_file ];then
        $mysql_stop >/dev/null 2>&1
        RETVAL=$?
        if [ $RETVAL -eq 0 ];then
            action "Stop mysql $port" /bin/true
        else
            action "Stop mysql $port" /bin/false
        fi
    else
        echo "Mysql $port is already stopped"
        RETVAL=3
    fi
    return $RETVAL
}

restart(){
    stop
    sleep 2
    start 
    RETVAL=$?
    return $RETVAL
}

status(){
    if [ -f $pid_file ];then
        echo "mysql $port is running.."
    else
        echo "mysql $port is stopped.."
    fi
    return $RETVAL
}

case "$action" in
    start)
        start
        RETVAL=$?
        ;;
    stop)
        stop
        RETVAL=$?
        ;;
    restart)
        restart
        RETVAL=$?
        ;;
    status)
        status
        RETVAL=$?
        ;;
    *)
        Usage
        exit 0
esac
exit $RETVAL

