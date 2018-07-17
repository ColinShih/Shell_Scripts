###############################################################
#!/bin/bash
#Author: Colin
#Mail: 499219677@qq.com
#Time: 2018-07-06 17:13:27
#Name: rsyncd
#Version:1.0
#chkconfig: 2345 29 70
#Description: start|stop|restart rsync 
#idea: judge rsyncd service is running or not via pidfile
###############################################################
[ -f /etc/init.d/functions ] && . /etc/init.d/functions
pidfile=/var/run/rsyncd.pid
judge(){
    RETVAL=$?
    if [ $? -eq 0 ];then
        action "rsync is $1" /bin/true
    else
        action "rsync is $1" /bin/false
    fi
    return $RETVAL
}

start(){
    if [ -f $pidfile ];then
        echo "rsync is running.."
    else
        rsync --daemon
        judge start        
    fi
    return $RETVAL 
}

stop(){
    if [ ! -f $pidfile ];then
        echo "rsync is already stopped.."
        RETVAL=$?
    else
        kill -USR2 `cat $pidfile`
        rm -f $pidfile
        judge stop
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
        sleep 3
        start
        RETVAL=$?
        ;;
    status)
        if [ -f $pidfile ];then
            echo "rsyncd (pid `cat $pidfile`) is running.."
        else
            echo "rynd is stopped.."
        fi
        RETVAL=$?
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit
esac
exit $RETVAL

