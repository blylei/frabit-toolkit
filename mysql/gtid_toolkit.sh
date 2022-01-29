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

myname=$(basename $0)
[ -f /etc/profile.d/frabit-toolkit.sh ] && . /etc/profile.d/frabit-toolkit.sh
error_file=/tmp/gtid_toolkit.log

# 处理命令行参数
for arg in "$@";
do
shift
  case "$arg" in
    "-help"|"--help")                     set -- "$@" "-h" ;;
    "-cmd"|"--cmd")                       set -- "$@" "-c" ;;
    "-inst"|"--inst")                     set -- "$@" "-i" ;;
    *)                                    set -- "$@" "$arg"
  esac
done

while getopts "c:i:h:" OPTION
do
  case $OPTION in
    h) cmd="help" ;;
    c) cmd="$OPTARG" ;;
    i) inst="$OPTARG" ;;
    *) echo "未知选项" ;;
  esac
done


universal_sed() {
  if [[ $(uname) == "Darwin" || $(uname) == *"BSD"* ]]; then
    gsed "$@"
  else
    sed "$@"
  fi
}

fail(){
  # 输出错误日志，并退出脚本执行
  message=${myname[$$]}: "$1"
  >&2 echo "$message"
  exit 1
}

log() {
  # 将操作日志格式化以后登记到日志文件内
  dt_flg=$(date +'%F %T')

  echo "$dt_flg $1" >>${error_file}
}

assert_nonempty() {
  name="$1"
  value="$2"

  if [ -z "$value" ] ; then
    fail "$name 必须提供对应的值"
  fi
}

print_result(){
  # 将命令行的运行结果，格式化后输出到终端
  pass
}

init_conn(){
  # 根据数据库IP地址，创建连接
  local host="$1"
  local sql="$2"
  mysql -h"$host" -u "$db_user" -p"$db_passwd" -NBe "$sql"
  return 1
}

prompt_help() {
  echo "用法: gtid-toolkit -c <cmd> -i instance"
  echo "举例: gtid-toolkit -c desc-topo -i 192.168.100.48"
  echo "选项:"
  echo "
  -h, --help
    输出帮助文档
  -c <cmd>
    指定需要执行的命令
  -i <ip_addr>
    数据库实例
"

  cat "$0" | universal_sed -n '/run_cmd/,/esac/p' | egrep '".*"[)].*;;' | universal_sed -r -e 's/"(.*?)".*#(.*)/\1~\2/' | column -t -s "~"
}

# ----------------------------------------------以下函数与命令行对应------------------------------------------
find_master(){
  # 根据提供的数据库IP地址，找到对应的主库， read_only=0 判断为主库，否则为从库
  local host="$i"
  local sql="select @@global.read_only;"
  local master="127.0.0.1:3306"
  is_master=$(init_conn "$host" "$sql")
  if [[ "$is_master" -eq 1 ]];then
    master="$(init_conn "$host" "select @@global.report_host,@@global.hostname;")"
  else
    pass
  fi
  echo "$master"
  return 0
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

enable_gtid(){
  # 在从库执行 reset_master,将主从复制模式从file:position 切换到gtid模式
  local sql="STOP SLAVE;CHANGE MASTER TO MASTER_AUTO_POSITION=1;START SLAVE;"
  init_conn "$host" "$sql"
  return 1
}

disable_gtid(){
  # 在从库执行 reset_master,将异常gtid移除
  pass
  return 1
}

enable_semisync(){
  # 在从库执行 reset_master,将主从复制模式从file:position 切换到gtid模式
  local sql="STOP SLAVE;CHANGE MASTER TO MASTER_AUTO_POSITION=1;START SLAVE;"
  init_conn "$host" "$sql"
  return 1
}

disable_semisync(){
  # 在从库执行 reset_master,将异常gtid移除
  pass
  return 1
}

run_cmd(){
  # 运行命令
  local cmd="$c"
  if [ -z "$cmd" ] ; then
    fail "No command given. Use $myname -c <cmd> [...] to do something useful"
  fi
  cmd=$(echo $cmd | universal_sed -e 's/slave/replica/')
  case $cmd in
    "desc-topo") desc_topo ;;              # 探测拓扑结构
    "inject-empty") inject_empty ;;        # 到主库注入空事务
    "reset-master") reset_master ;;        # 重置从库的gtid_purged
    "enable-gtid") enable_gtid ;;          # 主从复制切换到gtid模式
    "disable-gtid") disable_gtid ;;        # 主从复制切换到file:position模式
    "find-master") find_master ;;          # 根据提供的IP地址，返回该实例对应的主库
    "enable-semisync") enable_semisync ;;  # 启用半同步复制
    "disable-semisync") disable_semisync ;;  # 禁用半同步复制

    *) fail "不支持 $cmd" ;;
  esac
}

main(){
  # 脚本入口
  run_cmd
}

main
