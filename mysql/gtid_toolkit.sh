#! /bin/bash
#---------------------------------------------------- Head info -------------------------------------------
# author          : zhangl (blylei@163.com)
# create datetime : 2021-12-28
# funcation       : fix MySQL【Oracle's or Percona】 gtid issue
# script name     : gtid_toolkit.sh
#-----------------------------------------------------------------------------------------------------------
#-------------------------------------------------- Modified logs ------------------------------------------
# Version      People   Date             Notes
# V1.0.0       zhangl   2021-12-28      create this script
#-----------------------------------------------------------------------------------------------------------
set -eu

db_user=''
db_passwd=''
db_port=3306

error_file=/tmp/gtid_toolkit.log

## inject-empty
## reset-master
## desc-topo

usage() {
  echo "usage: $0 [options] node1 node2"
  echo "      ${DESCRIPTION}"                                           1>&2
  echo "      -a      Enable auto-pos if node1 can auto-post on node2 " 1>&2
  echo "      -h      Print this help"                                  1>&2
  exit $1
}

log() {
  # 将操作日志格式化以后登记到日志文件内
  dt_flg=$(date +'%F %T')
  echo "$dt_flg $1" >>${error_file}
}

init_conn(){
  # 根据数据库IP地址，创建连接
  local host="$1"
  local sql="$2"
  mysql -h"$host" -u "$db_user" -p"$db_passwd" -NBe "$sql"
  return 1
}

find_master(){
  # 根据提供的数据库IP地址，找到对应的主库， read_only=0 判断为主库，否则为从库
  local ip="$1"
  local role
  pass
}


desc_topo(){
  # MySQL 拓扑信息检查
  # 只需要提供集群里面的任何实例，就可以探测整个集群的拓扑信息
  pass
  return 1
}

inject_empty(){
  # 将从库上面的异常gtid取出来，到主库注入空事务
  pass
  return 1
}

reset_master(){
  # 在从库执行 reset_master,将异常gtid移除
  pass
  return 1
}


while getopts "a" opt; do
  case "$opt" in
    desc_topo)
       desc_topo
       ;;
    inject_empty)
       inject_empty
       ;;
    reset_master)
      reset_master
      ;;
    *) usage 1 ;;
  esac
done

node1="$1"
node2="$2"

gtid_purged=$(mysql -h $node2 -sse "SELECT @@global.gtid_purged")
gtid_missing=$(mysql -h $node1 -sse "SELECT GTID_SUBTRACT('$gtid_purged', @@global.gtid_executed)")

if [[ "$gtid_missing" ]]; then
  echo "$node1 cannot auto-position on $node2, missing GTID sets $gtid_missing" >&2
  exit 1
fi

if [[ $ENABLE_AUTO_POS ]]; then
  echo "OK, $node1 can auto-position on $node2, enabling..."
  mysql -h $node1 -e "STOP SLAVE; CHANGE MASTER TO MASTER_AUTO_POSITION=1; START SLAVE;"
  sleep 1
  mysql -h $node1 -e "SHOW SLAVE STATUS\G"
  echo "Auto-position enabled on $node1. Verify replica is running in output above."
else
  echo "OK, $node1 can auto-position on $node2. Use option -a to enable, or execute:"
  echo "    mysql -h $node1 -e \"STOP SLAVE; CHANGE MASTER TO MASTER_AUTO_POSITION=1; START SLAVE;\""
  echo "    mysql -h $node1 -e \"SHOW SLAVE STATUS\G\""
fi