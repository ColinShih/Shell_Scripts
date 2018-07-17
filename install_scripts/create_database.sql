CREATE DATABASE if not exists zabbix default character set utf8 collate utf8_general_ci;
grant all privileges on zabbix.* to zabbix@localhost identified by '1234';
use zabbix; 
