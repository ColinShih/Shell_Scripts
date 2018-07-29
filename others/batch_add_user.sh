#!/bin/bash
#Author: Colin
#Mail: 499219677@qq.com
#Time: 2018-06-20 11:22:24
#Name: add_user.sh
#Version:1.0
#Description: This is to 批量创建用户
. /etc/init.d/functions
user="colin"
passfile="/tmp/user.log"
for num in `seq -w 10`
do
    pass="`echo "test$RANDOM"|md5sum|cut -c3-11`"
    useradd $user${num} &> /dev/null &&\
    echo -e "$user${num}:$pass">>$passfile
    if [ $? -eq 0 ];then
        action "$user$num is ok" /bin/true
    else
        action "$user$num is failed" /bin/false
    fi
done
chpasswd < $passfile
cat $passfile && >$passfile
