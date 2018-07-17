#!/bin/bash
# 自动安装lamp&lnmp环境
path=/server/scripts/lamp_lnmp
lamp_name=lamp.sh
lnmp_name=lnmp.sh
[ -d $path ] || mkdir -p $path
cat <<EOF
	1. [install lamp]
	2. [install lnmp]
	3. [exit]
	please input the number you want to select
EOF
read num
#判断用户输入的数字必须为整形
expr $num + 1 &>/dev/null
[ $? -ne 0 ] &&{
  echo "The number you input must be [1|2|3]"
  exit 1
}

case $num in
    1)
        echo "start installing lamp"
        sleep 2
        [ -x $path/lamp.sh ] ||{
            echo "$path/lamp.sh does not exist or cannot be executed"
            exit 1
        }
        source $path/$lamp_name
        exit $?
        ;;
    2)
        echo "start installing lnmp..."
        sleep 2;
        [ -x "$path/lnmp.sh" ] ||{
            echo "$path/lamp.sh does not exist or cannot be executed"
            exit 1
        }
        source $path/$lnmp_name
        exit $?
        ;;
    3)
        echo "bye, bye.."
        exit 3
        ;;
    *)
        echo "The number you input must be 1 2 3"
        echo "input error"
        exit 4
        ;;
esac
