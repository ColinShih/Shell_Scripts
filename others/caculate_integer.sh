#!/bin/bash
#两个整数的四则运算
read -t 15 -p "please input two number: " a b
#判断字符串a和b的长度
[ ${#a} -le 0 ]&&{
  echo "the first number is null"
  exit 1
}
[ ${#b} -le 0 ]&&{
  echo "then the second nubmer is null"
  exit 1
}
#判断a和b是否为整形
expr $a + 1 &>/dev/null
RETVAL_A=$?
expr $b + 1 &>/dev/null
RETVAL_B=$?
if [ $RETVAL_A -ne 0 -o $RETVAL_B -ne 0 ];then
  echo "one of the num is not integer, pls input again"
  exit 1
fi

echo "a+b=$(($a+$b))"
echo "a-b=$(($a-$b))"
echo "a*b=$(($a*$b))"
echo "a/b=$(($a/$b))"
