#!/bin/bash
#author:huangweibo
path="/home"
user="root"
passwd="ling4022@163.com"
dbname="zabbix"
host="localhost"
today=`date +%Y%m%d`
sqlname=$dbname$today.sql
#backup
/usr/local/mysql/bin/mysqldump  -h$host -u$user -p$passwd --single-transaction --set-gtid-purged=OFF --databases $dbname >$path/$sqlname
