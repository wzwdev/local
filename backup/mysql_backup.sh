#!/bin/bash

#ʹ�ô�shellǰ�ֶ�ִ��7�α��ݲ�������֤��ʱ��������7��ı���
mkdir -p /alidata/backup/db/mysql
cd /alidata/backup/db/mysql && ls -t | tac | head -n 1 | awk '{print $1}' | xargs rm -fr
cp -r /alidata/db/mysql /alidata/backup/db/mysql/mysql_$(date +%Y%m%d%H%M%S)

#������ʱ����
#crontab -e
#59 23 * * * /alidata/shell/backup/mysql_backup.sh

#��ѯ������־
#tail -f /var/log/cron
