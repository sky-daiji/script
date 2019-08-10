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
