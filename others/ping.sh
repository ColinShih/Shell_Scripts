#!/bin/bash
#Author: Colin
#Mail: 499219677@qq.com
#Time: 2018-06-20 19:46:14
#Name: ping.sh
#Version:1.0
#Description: This is to test the range od
CMD="ping -W 2 -c 2"
ip="192.168.121."
for n in `seq 254`
do
    {
        $CMD $ip$n &> /dev/null
        if [ $? -eq 0 ];then
            echo "$ip$n is ok"
        fi
    }
done
