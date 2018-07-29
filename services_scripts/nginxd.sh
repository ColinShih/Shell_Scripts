###############################################################
#!/bin/bash
# Author: Colin
# Mail: 499219677@qq.com
# Time: 2018-07-06 17:13:27
# Name: nginxd
# Version:1.0
# chkconfig: 2345 31 71
# Description: start|stop|restart|status|reload|configTest nginx 
# idea: judge nginxd service is running or not via pidfile
###############################################################
basedir=/usr/local/nginx
bindir=$basedir/sbin/nginx
pidfile=$basedir/logs/nginx.pid
# source function library
[ -f /etc/init.d/functions ] && . /etc/init.d/functions
judge(){
    RETVAL=$?
    if [ $? -eq 0 ];then
        action "$1 nginx" /bin/true
    else
        action "$1 nginx" /bin/false
    fi
    return $RETVAL
}

start(){
    if [ -f $pidfile ];then
        echo "nginx is running.."
    else
        $bindir
        judge Starting        
    fi
    return $RETVAL 
}

stop(){
    if [ ! -f $pidfile ];then
        echo "nginx is already stopped.."
        RETVAL=$?
    else
        kill -USR2 `cat $pidfile`
        rm -rf $pidfile &>/dev/null
        killproc $bindir
        pkill nginx
        judge Stopping
    fi
    return $RETVAL
}
reload(){
    if [ -f $pidfile ];then
        $bindir -s reload
        judge Reloading
    else
        echo "nginx has not started.."
    fi
    return $RETVAL
}
status(){
    if [ -f $pidfile ];then
        echo "nginx (pid `cat $pidfile`) is running.."
    else
        echo "nginx is stopped.."
    fi
    return $RETVAL
}

case "$1" in 
    start)
        start
        RETVAL=$?
        ;;
    stop)
        stop
        RETVAL=$?
        ;;
    restart)
        stop
        sleep 2
        start
        RETVAL=$?
        ;;
    reload)
        reload
        RETVAL=$?
        ;;
    configTest)
        $bindir -t
        RETVAL=$?
        ;;
    status)
        status
        RETVAL=$?
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|reload|configTest|status}"
        exit
esac
exit $RETVAL

