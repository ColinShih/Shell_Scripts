#!/bin/bash
#Author: Colin
#Mail: 499219677@qq.com
#Time: 2018-06-24 22:30:02
#Name: a.sh
#Version:1.0
#Description: This is to 输入两个数，画出梯形
read -t 5 -p "pls input two numbers: " a b
if [ -n "`echo $(($a+$b))|sed 's/[0-9]//g'`" ];then
#|| -n "`echo $b|sed 's/[0-9]//g'`" ];then
    echo "error"
fi

#if [ $# -ne 2 ];then
#    echo "USAGE: $0 num1(>2) num2"
#    exit
#fi
for n in `seq $a $b`
   do
    for((m=1;m<=$n;m++))
        do
            echo -n "*"
        done
            echo
   done

