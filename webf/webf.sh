#!/bin/sh

#shell begin install software-----------------------------------------------------------
#Jdk��װ��
mkdir -p /alidata/server && wget -O /alidata/server/jdk-1.8.0.tar.gz http://114.55.255.20:50080/oss/docker/jdk-1.8.0.tar.gz
cd /alidata/server/ && tar -zxf jdk-1.8.0.tar.gz && rm -f jdk-1.8.0.tar.gz
wget -O /alidata/server/jdk-1.8.0/jre/lib/security/java.security https://raw.githubusercontent.com/wzwdev/local/master/jdk-1.8.0/java.security
chmod -R 755 /alidata/server/jdk-1.8.0
echo "JAVA_HOME=/alidata/server/jdk-1.8.0" >> /etc/profile
echo "CLASSPATH=.:$JAVA_HOME/lib/tools.jar:$JAVA_HOME/lib/dt.jar" >> /etc/profile
echo "PATH=\$JAVA_HOME/bin:$PATH" >> /etc/profile
echo "export JAVA_HOME CLASSPATH PATH" >> /etc/profile
source /etc/profile

#Tomcat��װ��##Linux����root������в��ܼ���1024���ڵĵͶ˿ڣ�docker�ļ�������ʱ����Ϊ80�˿ڣ��˴����и���Ϊ8080:Catalina.startLifecycleException:  Protocol handler initialization failed:  java.net.BindException: Permission denied<null>:80

groupadd tomcat
useradd tomcat -g tomcat
mkdir -p /alidata/server && wget -O /alidata/server/tomcat-8.0.32.tar.gz http://114.55.255.20:50080/oss/docker/tomcat-8.0.32.tar.gz
cd /alidata/server/ && tar -zxf tomcat-8.0.32.tar.gz && rm -f tomcat-8.0.32.tar.gz
wget -O /alidata/server/tomcat-8.0.32/conf/server.xml https://raw.githubusercontent.com/wzwdev/local/master/tomcat-8.0.32/server.xml
chown -R tomcat:tomcat /alidata/server/tomcat-8.0.32
chmod -R 755 /alidata/server/tomcat-8.0.32
su tomcat -c /alidata/server/tomcat-8.0.32/bin/startup.sh

#MySQL��װ[2G�ڴ�����]:
#mysql.cnf������ socket=/tmp/mysql.sock����Ȼ���쳣��Starting MySQL.2018-05-22T03:50:26.311679Z mysqld_safe Directory '/var/lib/mysql' for UNIX socket file don't exists. ERROR! The server quit without updating PID file (/alidata/server/mysql/data/webf.com.pid). 
#/var/log/mariadb/mariadb.log �ֹ�������������Ϊmysql�û����Է���

groupadd mysql
useradd mysql -g mysql
rpm --rebuilddb && yum install -y libaio
mkdir -p /alidata/server && wget -O /alidata/server/mysql.tar.gz http://114.55.255.20:50080/oss/docker/mysql.tar.gz
cd /alidata/server/ && tar -zxf mysql.tar.gz && rm -f mysql.tar.gz
wget -O /alidata/server/mysql/my.cnf https://raw.githubusercontent.com/wzwdev/local/master/mysql-5.7.20/my.cnf
wget -O /etc/init.d/mysqld https://raw.githubusercontent.com/wzwdev/local/master/mysql-5.7.20/mysqld
chown -R mysql:mysql /alidata/server/mysql
chmod -R 750 /alidata/server/mysql
chmod 750 /etc/init.d/mysqld
mkdir -p /var/log/mariadb && touch /var/log/mariadb/mariadb.log && chown mysql:mysql /var/log/mariadb/mariadb.log
echo "export PATH=$PATH:/alidata/server/mysql/bin" >> /etc/profile
source /etc/profile
/etc/init.d/mysqld start

#root��¼
mysql -uroot -proot
#�޸�root����;
use mysql;
delete from user where user is null;   
delete from user where user = '';
update user set password=password('root') where user='root';
flush privileges;
#����Ӧ�ó����û���jcclouds/jcclouds;
grant all privileges on *.* to jcclouds@'%' identified by 'jcclouds' with grant option;
revoke super on *.* from jcclouds@'%';
flush privileges;
quit;

#Nginx��װ��
groupadd nginx
useradd nginx -g nginx
yum install -y pcre pcre-devel
yum install -y zlib zlib-devel
yum install -y openssl openssl-devel
mkdir -p /alidata/server && wget -O /alidata/server/nginx-1.10.1.tar.gz http://114.55.255.20:50080/oss/docker/nginx-1.10.1.tar.gz
cd /alidata/server/ && tar -zxf nginx-1.10.1.tar.gz && rm -f nginx-1.10.1.tar.gz
wget -O /alidata/server/nginx-1.10.1/conf/nginx.conf https://raw.githubusercontent.com/wzwdev/local/master/nginx-1.10.1/nginx.conf
chown -R nginx:nginx /alidata/server/nginx-1.10.1
/alidata/server/nginx-1.10.1/sbin/nginx

#�رշ���ǽ�����webfʵ����װ��Ὺ����
systemctl disable firewalld
systemctl stop firewalld
systemctl disable iptables
systemctl stop iptables

#���ʵ�ַ
echo access nginx: http://ip
echo access tomcat: http://ip:8080
echo access mysql: root/root jcclouds/jcclouds
#shell end install software-----------------------------------------------------------


#������Ϊ�ڶ�������shell��ִ��(���һ���Ը��ƺ���ִ�е��������ݿ�ʱ�����ű����󣬹��Ƴ�����)


#shell begin install webf-----------------------------------------------------------
#webf4.0ʵ�����𣺽������ݿ�webf[root/root],��Nginx������webf���ʣ���Tomcat������ֻ��127.0.0.1(��Nginx)���ܷ���tomcat������ֱ�ӷ���Tomcat
#�رշ�����
su tomcat -c /alidata/server/tomcat-8.0.32/bin/shutdown.sh
/alidata/server/nginx-1.10.1/sbin/nginx -s quit
#�������ݿ�
wget -O /alidata/server/webf.sql https://raw.githubusercontent.com/wzwdev/local/master/webf/webf.sql
mysql -uroot -proot
create database if not exists webf default character set utf8 collate utf8_general_ci;
quit;
mysql -uroot -proot webf < /alidata/server/webf.sql
rm -f /alidata/server/webf.sql
#����TomcatӦ��
wget -O /alidata/server/tomcat-8.0.32/conf/server.xml https://raw.githubusercontent.com/wzwdev/local/master/webf/server.xml
wget -O /alidata/server/tomcat-8.0.32/webapps/webf.war https://raw.githubusercontent.com/wzwdev/local/master/webf/webf.war
#����Nginx
wget -O /alidata/server/nginx-1.10.1/conf/nginx.conf https://raw.githubusercontent.com/wzwdev/local/master/webf/nginx.conf
#����������
su tomcat -c /alidata/server/tomcat-8.0.32/bin/startup.sh
/alidata/server/nginx-1.10.1/sbin/nginx
#webf����(nginx)
# http://192.168.0.30/webf
#webf����(��tomcat�Ƿ���ֱ�ӷ���,����ܷ��ʾ�������������)
# http://192.168.0.30��8080/webf

#���ÿ�������
wget -O /etc/rc.local https://raw.githubusercontent.com/wzwdev/local/master/webf/rc.local
#CentOS7 ��/etc/rc.local���Ὺ��ִ��,����ļ���Ϊ�˼����Ե��������ӵ�
chmod +x /etc/rc.d/rc.local

#iptables����ֻ��22,80�˿ڿ���ͨ���ⲿ���ʣ�mysql����ͨ����������
yum install -y iptables-services
iptables -F 
iptables -X
iptables -Z
iptables -F -t nat
iptables -X -t nat
iptables -Z -t nat
iptables -X -t mangle
#ssh
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -P INPUT DROP
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
#server access internet
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
#ping
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT

#web
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
#mysql localhost access
iptables -A INPUT -p tcp -s 127.0.0.1 --dport 3306 -j ACCEPT
#save
systemctl disable firewalld
systemctl stop firewalld
service iptables save
systemctl enable iptables
systemctl restart iptables

#������ʱ���ݿ������Է��ʹ���
iptables -A INPUT -p tcp --dport 3306 -j ACCEPT

#shell end install webf-----------------------------------------------------------

