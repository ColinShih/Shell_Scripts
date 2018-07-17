#!/bin/bash
#Author:  Colin
#Date:  2018/01/02
#Description:  caculate number
print_usage(){
  printf "please enter an integer: \n"
  exit 1
}
read -t 5 -p "Please inuput first number: " firstnum
if [ -n "`echo $firstnum|sed 's/[0-9]//g'`" ] ;then
  print_usage
fi
read -t 5 -p "Please input an operator: " operator
if [ "$operator" != "+"  ] && [ "$operator" != "-" && [ $operator != "*" ] && [ $operator != "/" ] ;then
echo "Please use {+|-|*|/}"
exit 2
fi
read -t 5 -p "Please input second nubmer: " secondnum
if [ -n "`echo $secondnum|sed 's/[0-9]//g'`" ] ;then
  print_usage
fi
echo "$firstnum$operator$secondnum=$(($firstnum$operator$secondnum))"
