#### 适用于配置过SSH同用户名和同密码的同类交换机进行批量配置. 目录架构如下：

```bash
[root@cobbler-200 script2]# ls -ll
total 12
-rw-r--r-- 1 root root  80 Aug 10 09:42 cmd.txt
-rwxr-xr-x 1 root root 670 Aug 10 09:52 conf.py
-rwxr-xr-x 1 root root 895 Aug 10 10:11 ss_sw_cmd.py

[root@cobbler-200 script2]# cat cmd.txt
clock timezone UTC add 8
sys
ntp-service unicast-server 120.25.115.20
dis clock

[root@cobbler-200 script2]# cat conf.py
#-*- coding: utf-8 -*-
#!/usr/bin/python
#要执行操作的交换机管理
swip={
'HX_S5720_4F_3' : '172.18.18.254',
'HX_AC6005_4F_2' : '172.18.18.252',
'JR_S3700_2F_1' :  '172.18.18.54',
'JR_S5700_2F_2' : '172.18.18.22',
'JR_S5700_2F_3' : '172.18.18.23',
'JR_S5700_2F_4' : '172.18.18.24',
'JR_S5700_2F_POE_1' : '172.18.18.21',
'JR_S5700_4F_1' : '172.18.18.41',
'JR_S5700_4F_2' : '172.18.18.42',
'JR_S5700_4F_POE_3' : '172.18.18.43',
'JR_S5700_5F_2' : '172.18.18.52',
'JR_S5700_5F_POE_1' : '172.18.18.51',
'JR_SERCER' : '172.18.18.53',
};

#交换机SSH用户名密码    
username = "admin"  #用户名
passwd = "HUAWEI/sz1.com"    #密码
threads = [15]   #多线程

[root@cobbler-200 script2]# cat ss_sw_cmd.py
#-*- coding: utf-8 -*-
#!/usr/bin/python
import paramiko
import threading
import time
import os
from conf import *

#拿到cmd.txt文件中的命令
with open('./cmd.txt', 'r') as f:
    cmd_line= f.readlines()
cmd=[]
for c in cmd_line:
     cmd.append(c)
#定义连接与操作
def ssh2(ip,username,passwd,cmd):
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(ip,22,username,passwd,timeout=10)
        ssh_shell = ssh.invoke_shell()
        for m in cmd:
            res = ssh_shell.sendall(m)
            time.sleep(float(1))
        print ssh_shell.recv(1024)
        ssh.close()
    except :
        print '%s\tError\n'%(ip)

if __name__=='__main__':
    print "Begin......"
    for key in swip:
        ip = swip[key]
        a=threading.Thread(target=ssh2,args=(ip,username,passwd,cmd))
        a.start()
```
