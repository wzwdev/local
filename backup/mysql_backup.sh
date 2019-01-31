#!/bin/bash

#使用此shell前手动执行7次备份操作，保证定时任务开启后7天的备份
mkdir -p /alidata/backup/db/mysql
cd /alidata/backup/db/mysql && ls -t | tac | head -n 1 | awk '{print $1}' | xargs rm -fr
cp -r /alidata/db/mysql /alidata/backup/db/mysql/mysql_$(date +%Y%m%d%H%M%S)

#创建定时任务
#crontab -e
#59 23 * * * /alidata/shell/backup/mysql_backup.sh

#查询任务日志
#tail -f /var/log/cron
