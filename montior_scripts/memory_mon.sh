#!/bin/bash
#Author: Colin
#Mail: 499219677@qq.com
#Time: 2018-07-06 10:49:47
#Name: memory_mon.sh
#Version:1.0
#Description: This is to alert user when system memory is less then 100
###########################################################################
# The output format of free command 
#              total       used       free     shared    buffers     cached
# Mem:           992        918         73          0         61         53
# -/+ buffers/cache:        803        188
# Swap:          499        354        145
##########################################################################
FreeMem=`free -m|awk 'NR==3 {print $NF}'`
chars="Current memory is $FreeMem, pls pay attention"
if [ $FreeMem -lt 200 ];then
    echo $chars>logs/messages.txt
    mail -s "`date +%F" "%T` $chars" 499219677@qq.com <logs/messages.txt
fi

