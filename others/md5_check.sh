##############################################
#!/bin/bash
# Author: Colin
# Mail: 499219677@qq.com
# Time: 2018-07-10 21:40:34
# Name: md5_check.sh
# Version:1.0
# Description: 
##############################################
path=/var/html/www
[ -d /test/md5 ] ||mkdir -p /test/md5
md5_log=/test/md5/md5_$(date +%F).log
num_log=/test/md5/num_$(date +%F).log
touch $md5_log
touch $num_log
find $path -type f |xargs md5sum >$md5_log
find $path -type f |xargs md5sum >$num_log
num=$(cat $num_log|wc -l)
while true
do
    log=/test/md5/check.log
    [ ! -f $log ] && touch $log
    md5_count=$(md5sum -c $md5_log 2>/dev/null |grep FAILED|wc -l)
    num_count=$(find $path -type f|wc -l)
    find $path -type f >/test/md5/new.log
        if [ $md5_count -ne 0 ] || [ $num_count -ne 0 ];then
            echo "$(md5sum -c $md5_log 2>/dev/null |grep FAILED)">$log
            diff $num_log /test/md5/new.log >>$log
            mail -s "web site is misrepresented in $(date +'%F %T')" 499219677@qq.com <$log
        fi
        sleep 5
    done
