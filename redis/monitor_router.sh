#! /bin/bash
#---------------------------------------------------- Head info -------------------------------------------
# author          : zhangl (blylei@163.com)
# create datetime : 2021-10-14
# funcation       : 监控mysqlrouter的状态
# script name     : monitor_router.sh
#-----------------------------------------------------------------------------------------------------------
#-------------------------------------------------- Modified logs ------------------------------------------
# Version      People   Date             Notes
# V1.0.0       zhangl   2021-10-14       新增脚本
# V1.0.1       zhangl   2021-12-13       新增检查mysqlrouter到后端MySQL数据库的连接状态检查
#-----------------------------------------------------------------------------------------------------------
# set -x
INPUT="$1"
mysql_user="lbs_ro"
mysql_passwd='passwd_123'
keepalived_conf=/etc/keepalived/keepalived.conf

chk_process(){
  # 检查指定组件的进程是否存在
  local component="$1"
  local status=$(systemctl status "$component"| grep running| grep -v grep | wc -l)
  if [ "$status" -eq 1 ]
  then
    echo 1
  else
    echo 0
  fi
}

# V1.0.1
find_vip(){
  # 从keepalived配置文件里面查找对于的vip
  local vip
  if [[ -f ${keepalived_conf} ]];then
    vip=$(grep -A 1 virtual_ipaddress "$keepalived_conf"| grep 172.16| awk  '{print $1}' | awk -F"/" '{print $1}')
  else
    echo "$keepalived_conf 不存在"
    exit
  fi
  echo "$vip"
}

chk_vip(){
  # 检查vip到数据库的连接是否正常
  local vip=$(find_vip)
  sql="select 1;"
  status=$(mysql -h "$vip" -u "$mysql_user" -p"$mysql_passwd" -NBe "$sql" 2>/dev/null)
  if [ "$status" == "1" ]
  then
    echo 1
  else
    echo 0
  fi
}


if [ "$INPUT" == "mysqlrouter" ];then
  chk_process "mysqlrouter"
elif [ "$INPUT" == "keepalived" ];then
  chk_process "keepalived"
elif [ "$INPUT" == "vip" ];then
  chk_vip
else
  exit
fi

