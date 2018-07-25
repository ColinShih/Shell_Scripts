##############################################
#!/bin/bash
# Author: Colin
# Mail: 499219677@qq.com
# Time: 2018-03-22 11:19:41
# Name: cut_nginx_log.sh
# Version:1.0
# Description: 
##############################################
DateFormat=`date +%Y%m%d`
BaseDir="/usr/local/nginx"
NginxLogDir="$BaseDir/logs"
Logname="access_www"
[ -d $NginxLogDir ] && cd $NginxLogDir || exit 1
[ -f ${Logname}.log ] || exit 1
/bin/mv ${Logname}.log ${Logname}_${DateFormat}.log
$BaseDir/sbin/nginx -s reload
