#!/bin/sh

#shell begin install software-----------------------------------------------------------
#Jdk安装：
mkdir -p /alidata/server && wget -O /alidata/server/jdk-1.8.0.tar.gz http://114.55.255.20:50080/oss/docker/jdk-1.8.0.tar.gz
cd /alidata/server/ && tar -zxf jdk-1.8.0.tar.gz && rm -f jdk-1.8.0.tar.gz
wget -O /alidata/server/jdk-1.8.0/jre/lib/security/java.security https://raw.githubusercontent.com/wzwdev/local/master/jdk-1.8.0/java.security
chmod -R 755 /alidata/server/jdk-1.8.0
echo "JAVA_HOME=/alidata/server/jdk-1.8.0" >> /etc/profile
echo "CLASSPATH=.:$JAVA_HOME/lib/tools.jar:$JAVA_HOME/lib/dt.jar" >> /etc/profile
echo "PATH=\$JAVA_HOME/bin:$PATH" >> /etc/profile
echo "export JAVA_HOME CLASSPATH PATH" >> /etc/profile
source /etc/profile

#Tomcat安装：##Linux下以root身份运行才能监听1024以内的低端口，docker文件在制作时设置为80端口，此处进行更正为8080:Catalina.startLifecycleException:  Protocol handler initialization failed:  java.net.BindException: Permission denied<null>:80

groupadd tomcat
useradd tomcat -g tomcat
mkdir -p /alidata/server && wget -O /alidata/server/tomcat-8.0.32.tar.gz http://114.55.255.20:50080/oss/docker/tomcat-8.0.32.tar.gz
cd /alidata/server/ && tar -zxf tomcat-8.0.32.tar.gz && rm -f tomcat-8.0.32.tar.gz
wget -O /alidata/server/tomcat-8.0.32/conf/server.xml https://raw.githubusercontent.com/wzwdev/local/master/tomcat-8.0.32/server.xml
chown -R tomcat:tomcat /alidata/server/tomcat-8.0.32
chmod -R 755 /alidata/server/tomcat-8.0.32
su tomcat -c /alidata/server/tomcat-8.0.32/bin/startup.sh

#MySQL安装[2G内存配置]:
#mysql.cnf中配置 socket=/tmp/mysql.sock，不然报异常：Starting MySQL.2018-05-22T03:50:26.311679Z mysqld_safe Directory '/var/lib/mysql' for UNIX socket file don't exists. ERROR! The server quit without updating PID file (/alidata/server/mysql/data/webf.com.pid). 
#/var/log/mariadb/mariadb.log 手工建立，并设置为mysql用户可以访问

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

#root登录
mysql -uroot -proot
#修改root密码;
use mysql;
delete from user where user is null;   
delete from user where user = '';
update user set password=password('root') where user='root';
flush privileges;
#创建应用程序用户：jcclouds/jcclouds;
grant all privileges on *.* to jcclouds@'%' identified by 'jcclouds' with grant option;
revoke super on *.* from jcclouds@'%';
flush privileges;
quit;

#Nginx安装：
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

#关闭防火墙，最后webf实例安装后会开启的
systemctl disable firewalld
systemctl stop firewalld
systemctl disable iptables
systemctl stop iptables

#访问地址
echo access nginx: http://ip
echo access tomcat: http://ip:8080
echo access mysql: root/root jcclouds/jcclouds
#shell end install software-----------------------------------------------------------


#下面作为第二部分在shell中执行(如果一次性复制后在执行到部署数据库时会出错脚本错误，估计超长了)


#shell begin install webf-----------------------------------------------------------
#webf4.0实例部署：建立数据库webf[root/root],在Nginx中配置webf访问，在Tomcat中设置只有127.0.0.1(即Nginx)才能访问tomcat，避免直接访问Tomcat
#关闭服务器
su tomcat -c /alidata/server/tomcat-8.0.32/bin/shutdown.sh
/alidata/server/nginx-1.10.1/sbin/nginx -s quit
#部署数据库
wget -O /alidata/server/webf.sql https://raw.githubusercontent.com/wzwdev/local/master/webf/webf.sql
mysql -uroot -proot
create database if not exists webf default character set utf8 collate utf8_general_ci;
quit;
mysql -uroot -proot webf < /alidata/server/webf.sql
rm -f /alidata/server/webf.sql
#部署Tomcat应用
wget -O /alidata/server/tomcat-8.0.32/conf/server.xml https://raw.githubusercontent.com/wzwdev/local/master/webf/server.xml
wget -O /alidata/server/tomcat-8.0.32/webapps/webf.war https://raw.githubusercontent.com/wzwdev/local/master/webf/webf.war
#配置Nginx
wget -O /alidata/server/nginx-1.10.1/conf/nginx.conf https://raw.githubusercontent.com/wzwdev/local/master/webf/nginx.conf
#启动服务器
su tomcat -c /alidata/server/tomcat-8.0.32/bin/startup.sh
/alidata/server/nginx-1.10.1/sbin/nginx
#webf访问(nginx)
# http://192.168.0.30/webf
#webf访问(看tomcat是否不能直接访问,如果能访问就是配置有问题)
# http://192.168.0.30：8080/webf

#设置开机启动
wget -O /etc/rc.local https://raw.githubusercontent.com/wzwdev/local/master/webf/rc.local
#CentOS7 的/etc/rc.local不会开机执行,这个文件是为了兼容性的问题而添加的
chmod +x /etc/rc.d/rc.local

#iptables设置只有22,80端口可以通过外部访问，mysql可以通过本机访问
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

#开发用时数据库对外可以访问规则
iptables -A INPUT -p tcp --dport 3306 -j ACCEPT

#shell end install webf-----------------------------------------------------------

