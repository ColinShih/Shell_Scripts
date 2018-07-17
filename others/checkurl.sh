#!/bin/bash
#Date:	2018/01/01
#Author:  Colin
#Descrption:  This scripts is to check URL is available or not
#Version:  1.0

function usage(){
    echo $"Usage:$0 url"
    exit 1
}

checkUrl(){
timeout=5
fails=0
success=0
#CMD=`curl -I -s -w "{http_code}\n" -o /dev/null`
while true
    do
        read -p "pls input a url: " url
        wget $url --timeout=$timeout --tries=1 -q -O /dev/null 
        if [ $? -ne 0 ] ;then
            let fails=fails+1
        else
            let success=success+1
        fi
        if [ $success -ge 1 ] ;then
            echo success
            exit 0
        fi
        if [ $fails -ge 1 ] ;then
            critical="connection timeout."
            echo $critical
            echo $critical|mail -s "$critical" 499219677@qq.com
            exit 2
        fi
    done
}
checkUrl
