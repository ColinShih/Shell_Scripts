#########################################################################################
#!/bin/bash
# Author: Colin
# Time: 2018-05-03 19:28:21
# Name: install_menu.sh
# Version: v1.0
# Description: install script menu
########################################################################################

path=/server/scripts/lamp_lnmp
lamp_name=lamp.sh
lnmp_name=lnmp.sh
zabbix_name=zabbix_installation.sh
[ -d $path ] || mkdir -p $path
cat <<EOF
	1. [install lamp]
	2. [install lnmp]
	3. [install zabbix]
	4. [exit]
	please input number you want to select
EOF
read num

expr $num + 1 &>/dev/null
[ $? -ne 0 ] &&{
  echo "The number you input must be [1|2|3|4]"
  exit 1
}

case $num in
    1)
        echo "start installing lamp"
        sleep 2
        [ -x $path/$lamp_name ] ||{
            echo "$path/$lamp_name does not exist or cannot be executed"
            exit 1
        }
        source $path/$lamp_name
        exit $?
        ;;
    2)
        echo "start installing lnmp..."
        sleep 2;
        [ -x "$path/$lnmp_name" ] ||{
            echo "$path/$lnmp_name does not exist or cannot be executed"
            exit 1
        }
        source $path/$lnmp_name
        exit $?
        ;;
    3)
        echo "start installing zabbix..."
        sleep 2;
        [ -x "$path/$zabbix_name" ] ||{
            echo "$path/$zabbix_name does not exist or cannot be executed"
            exit 1
        }
        source $path/$zabbix_name
        exit $?
        ;;
    4)
        echo "bye, bye.."
        exit 3
        ;;
    *)
        echo "The number you input must be 1|2|3|4"
        echo "input error"
        exit 4
        ;;
esac
