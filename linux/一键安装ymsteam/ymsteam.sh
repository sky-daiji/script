#!/bin/bash
# 设置机构ID(ID需要修改)
ID="46"
#关闭防火墙和selinux
systemctl disable --now firewalld NetworkManager && systemctl stop firewalld 
setenforce 0
sed -ri '/^[^#]*SELINUX=/s#=.+$#=disabled#' /etc/selinux/config
# 配置时间同步
yum -y install wget chrony vim net-tools
cat <<EOF > /etc/chrony.conf
server ntp.aliyun.com iburst
stratumweight 0
driftfile /var/lib/chrony/drift
rtcsync
makestep 10 3
bindcmdaddress 127.0.0.1
bindcmdaddress ::1
keyfile /etc/chrony.keys
commandkey 1
generatecommandkey
logchange 0.5
logdir /var/log/chrony
EOF
systemctl enable chronyd && systemctl restart chronyd
# 设置主机名
hostnamectl set-hostname $ID
# 初始化系统内核参数
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
cat <<EOF > /etc/security/limits.conf
root soft nofile 65535
root hard nofile 65535
* soft nofile 65535
* hard nofile 65535
EOF
cat <<EOF > /etc/sysctl.conf
net.ipv4.neigh.default.gc_stale_time=120
net.ipv4.ip_forward = 1

# see details in https://help.aliyun.com/knowledge_detail/39428.html
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
net.ipv4.conf.default.arp_announce = 2
net.ipv4.conf.lo.arp_announce=2
net.ipv4.conf.all.arp_announce=2

# see details in https://help.aliyun.com/knowledge_detail/41334.html
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 1024
net.ipv4.tcp_synack_retries = 2

net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1

kernel.sysrq=1
EOF
sysctl -p
# 更改 ssh服务端口
sed -i 'N;16aPort 2210' /etc/ssh/sshd_config
systemctl restart sshd 
#安装openvpn-client
yum -y install gcc gcc-c++ pcre-devel openssl openssl-devel zlib zlib-devel 
yum -y install epel-release openvpn
#挂载共享盘共享盘
mount -t cifs -o username=daiji,password=DJ@1993.com  //172.16.18.246/Mfg-doc/研发中心/SEC/运维部/ymsteam线下店配置/openvpn-校区配置文件以及秘钥文件  /mnt
#添加openvpn客户端配置文件以及密钥
cp /mnt/$ID/* /etc/openvpn/client/

#添加客户端启动服务
cat <<EOF > /usr/lib/systemd/system/openvpn@.service
[Unit]
Description=OpenVPN Robust And Highly Flexible Tunneling Application On %I
After=network.target

[Service]
Type=notify
PrivateTmp=true
ExecStart=/usr/sbin/openvpn --cd /etc/openvpn/client/ --config %i.conf --auth-user-pass /etc/openvpn/client/passwd

[Install]
WantedBy=multi-user.target

EOF
systemctl enable openvpn@client && systemctl start openvpn@client
cd /etc/openvpn/client/ 
chmod 644 ./*
# 卸载共享盘
umount //172.16.18.246/Mfg-doc/研发中心/SEC/运维部/ymsteam线下店配置/openvpn-校区配置文件以及秘钥文件  /mnt
# 安装 tengine
cd /usr/local/src/
wget http://tengine.taobao.org/download/tengine-2.1.2.tar.gz 
tar -xzvf tengine-2.1.2.tar.gz
cd /usr/local/src/tengine-2.1.2/
./configure && make && make install
groupadd nginx
useradd nginx -g nginx -s /sbin/nologin
mkdir /usr/local/nginx/conf/vhost 
mkdir /var/data/video -p
wget http://172.16.18.252/linux/ymsteam/nginx/video/xxcj001.mp4 -P /var/data/video/
chown nginx:nginx /var/data/video -R
rm -f /usr/local/nginx/conf/nginx.conf
wget http://172.16.18.252/linux/ymsteam/nginx/conf/nginx.conf -P /usr/local/nginx/conf/
wget http://172.16.18.252/linux/ymsteam/nginx/conf/video.conf -P /usr/local/nginx/conf/vhost/
cat <<EOF > /usr/lib/systemd/system/nginx.service
[Unit]
Description=nginx
After=network.target
  
[Service]
Type=forking
ExecStart=/usr/local/nginx/sbin/nginx
ExecReload=/usr/local/nginx/sbin/nginx -s reload
ExecStop=/usr/local/nginx/sbin/nginx -s quit
PrivateTmp=true
  
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload && systemctl start nginx && systemctl enable nginx 
# 创建ID
mkdir /var/data/ID
cat <<EOF > /var/data/ID/id.txt
$ID
EOF
# 安装java环境
wget http://172.16.18.252/linux/APP/jdk-8u201-linux-x64.tar.gz -P /root
mkdir /usr/local/java
cd /root
tar -xzvf jdk-8u201-linux-x64.tar.gz
mv jdk1.8.0_201/ /usr/local/java/
sed -i '$a\export JAVA_HOME=/usr/local/java/jdk1.8.0_201 \nexport JRE_HOME=/usr/local/java/jdk1.8.0_201/jre\nexport CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar:$JRE_HOME/lib:$CLASSPATH\nexport PATH=$PATH:$JAVA_HOME/bin' /etc/profile
source /etc/profile
# 运行jar包
mkdir /tmp/java/
cd /tmp/java
touch transfer-web-service.log
mkdir /var/data/jar
wget http://172.16.18.252/linux/ymsteam/transfer-web-service.jar -P /var/data/jar

# 运行jar包并且通过supervisor进行监管jar启动
yum install -y supervisor
systemctl enable supervisord.service && systemctl start supervisord.service
cat <<EOF > /etc/supervisord.d/transfer-web-service.ini 
[program:transfer-web-service]   
command=/bin/bash -c "/usr/local/java/jdk1.8.0_201/bin/java -jar /var/data/jar/transfer-web-service.jar"
directory=/var/data/jar
user=root
stopsignal=INT
autostart=true
autorestart=true
startsecs=3
stdout_logfile=/tmp/java/transfer-web-service.log
EOF
supervisorctl reload 
