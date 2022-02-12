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

myname=$(basename $0)
[ -f /etc/profile.d/frabit-toolkit.sh ] && . /etc/profile.d/frabit-toolkit.sh
error_file=/tmp/gtid_toolkit.log

# #####################################################################################################
# 接收并预处理命令行参数
# #####################################################################################################

for arg in "$@";do
shift
  case "$arg" in
    "-help"|"--help")                     set -- "$@" "-H" ;;
    "-cmd"|"--cmd")                       set -- "$@" "-c" ;;
    "-host"|"--host")                     set -- "$@" "-h" ;;
    "-port"|"--port")                     set -- "$@" "-P" ;;
    "-user"|"--user")                     set -- "$@" "-u" ;;
    "-passwd"|"--passwd")                 set -- "$@" "-p" ;;
    *)                                    set -- "$@" "$arg"
  esac
done

while getopts "c:h:P:u:p:H" OPTION
do
  case $OPTION in
    H) cmd="help" ;;
    c) cmd="$OPTARG" ;;
    h) host="$OPTARG" ;;
    P) port="$OPTARG" ;;
    u) user="$OPTARG" ;;
    p) passwd="$OPTARG" ;;
    *) echo "未知选项" ;;
  esac
done

# #####################################################################################################
# 以下函数为共用的
# #####################################################################################################
universal_sed() {
  if [[ $(uname) == "Darwin" || $(uname) == *"BSD"* ]]; then
    gsed "$@"
  else
    sed "$@"
  fi
}

about_toolkits(){
 # 展示项目信息
 proj_url='https://github.com/frabitech/frabit-toolkit'
 echo "gtid-toolkit 是frabit-toolkits中的一个gtid诊断工具。由Blylei开发，并根据GPLv3开源许可证发布到Github
Copyright (c) 2021, 2022 blylei.info@gmail.com
GitHub: $proj_url
 "
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

section () {
   local str="$1"
   awk -v var="${str} _" 'BEGIN {
      line = sprintf("# %-60s", var);
      i = index(line, "_");
      x = substr(line, i);
      gsub(/[_ \t]/, "#", x);
      printf("%s%s\n", substr(line, 1, i-1), x);
   }'
}

NAME_VAL_LEN=30
name_val () {
   printf "%+*s | %s\n" "${NAME_VAL_LEN}" "$1" "$2"
}

assert_nonempty() {
  name="$1"
  value="$2"

  if [ -z "$value" ] ; then
    fail "$name 必须提供对应的值"
  fi
}

check_db_opts(){
  # 检查连接数据库的信息是否提供
  assert_nonempty "host" "$host"
  assert_nonempty "user" "$user"
  assert_nonempty "passwd" "$passwd"
}

exec_sql(){
  # 根据数据库IP地址，创建连接并执行相应SQL
  local sql="$1"
  # 如果没有在命令行里提供端口号，则使用MySQL默认的3306
  if [ -z "$port" ] ; then
    port=3306
  fi
  mysql -h"$host" -P"$port" -u"$user" -p"$passwd" -NBe "$sql" 2>/dev/null
  return 0
}

print_result(){
  # 将命令行的运行结果，格式化后输出到终端
  local info="$1"
  local master_ip=""
  local master_hostname=""
  section "运行结果展示"
  name_val "时间" $(date +'%F %T')
  section "主库信息"
  name_val "主机地址" "$master_ip"
  name_val "主机名称" "$master_hostname"
}

prompt_help() {
  about_toolkits
  echo "用法: gtid-toolkit -c <cmd> -h ip_addr [-P <port>] -u <user> -p <passwd>"
  echo "举例: gtid-toolkit -c desc-topo -h 192.168.100.48 -u dbadmin -p Test_123"
  echo "选项:"
  echo "
  -H, --help            输出帮助文档并退出脚本
  -c,--cmd <cmd>        【必选】指定需要执行的命令
  -h,--host <ip_addr>   【必选】数据库实例地址
  -P,--port <3306>      【可选】数据库端口号，不提供的话，默认为3306
  -u,--user <username>  【必选】数据库用户，需要在整个MySQL集群上都存在
  -p,--passwd <passwd>  【必选】数据库密码，需要在整个MySQL集群上都相同
"

  cat "$0" | universal_sed -n '/run_cmd/,/esac/p' | egrep '".*"[)].*;;' | universal_sed -r -e 's/"(.*?)".*#(.*)/\1~\2/' | column -t -s "~"
}

# #####################################################################################################
# 以下函数与命令行对应，分别实现某个实用功能
# #####################################################################################################

find_master(){
  # 根据提供的数据库IP地址，找到对应的主库， read_only=0 判断为主库，否则为从库
  local sql="select @@global.read_only;"
  local master="127.0.0.1:3306"
  is_master=$(exec_sql "$sql")
  if [[ "$is_master" -eq 0 ]];then
    master="$(exec_sql "select @@global.report_host,@@global.hostname;")"
  else
    pass
  fi
  print_result "$master"
  return 0
}

desc_topo(){
  # MySQL 拓扑信息检查
  # 只需要提供集群里面的任何实例，就可以探测整个集群的拓扑信息
  echo "功能待实现"
  return 1
}

inject_empty(){
  # 将从库上面的异常gtid取出来，到主库注入空事务
  echo "功能待实现"
  return 1
}

reset_master(){
  # 在从库执行 reset_master,将异常gtid移除
  echo "功能待实现"

  return 1
}

enable_gtid(){
  # 在从库执行 reset_master,将主从复制模式从file:position 切换到gtid模式
  local sql="STOP SLAVE;CHANGE MASTER TO MASTER_AUTO_POSITION=1;START SLAVE;"
  exec_sql "$sql"
  return 1
}

disable_gtid(){
  # 在从库执行 reset_master,将异常gtid移除
  echo "功能待实现"
  return 1
}

start_slave(){
  # 根据数据库IP地址，启动主从同步
  local sql="START SLAVE;"
  ret=$(exec_sql "$sql")
  return 0
}

start_slave_io(){
  # 根据数据库IP地址，启动主从同步
  local sql="START SLAVE io_thread;"
  ret=$(exec_sql "$sql")
  return 0
}

start_slave_sql(){
  # 根据数据库IP地址，启动主从同步
  local sql="START SLAVE sql_thread;"
  ret=$(exec_sql "$sql")
  return 0
}

stop_slave(){
  # 根据数据库IP地址，停止主从同步
  local sql="STOP SLAVE;"
  ret=$(exec_sql "$sql")
  return 1
}

stop_slave_io(){
  # 根据数据库IP地址，停止主从同步
  local sql="STOP SLAVE io_thread;"
  ret=$(exec_sql "$sql")
  return 1
}

stop_slave_sql(){
  # 根据数据库IP地址，停止主从同步
  local sql="STOP SLAVE sql_thread;"
  ret=$(exec_sql "$sql")
  return 1
}

enable_semisync(){
  # 在从库执行 reset_master,将主从复制模式从file:position 切换到gtid模式
  local sql="STOP SLAVE;CHANGE MASTER TO MASTER_AUTO_POSITION=1;START SLAVE;"
  exec_sql "$sql"
  return 1
}

disable_semisync(){
  # 在从库执行 reset_master,将异常gtid移除
  echo "功能待实现"
  return 1
}

run_cmd(){
  # 运行命令
  if [ -z "$cmd" ] ; then
    fail "没有提供命令. 请使用 $myname -c <cmd> [...] 去完成某些实用操作"
  fi
  case $cmd in
    "help") prompt_help ;;                 # 向控制台输出帮助信息
    "desc-topo") desc_topo ;;              # 探测MySQL集群拓扑结构
    "inject-empty") inject_empty ;;        # 到主库注入空事务
    "reset-master") reset_master ;;        # 重置从库的gtid_purged
    "enable-gtid") enable_gtid ;;          # 主从复制切换到gtid模式
    "disable-gtid") disable_gtid ;;        # 主从复制切换到file:position模式
    "find-master") find_master ;;          # 根据提供的IP地址，返回该实例对应的主库
    "enable-semisync") enable_semisync ;;    # 启用半同步复制
    "disable-semisync") disable_semisync ;;  # 禁用半同步复制
    "start-slave") start_slave ;;            # 启动主从复制，包含IO线程和SQL线程
    "start-slave-io") start_slave_io ;;      # 启动主从复制，仅启动IO线程
    "start-slave-sql") start_slave_sql ;;    # 启动主从复制，仅启动SQL线程
    "stop-slave") stop_slave ;;              # 停止主从复制，包含IO线程和SQL线程
    "stop-slave-io") stop_slave_io ;;        # 停止主从复制，仅启动IO线程
    "stop-slave-sql") stop_slave_sql ;;      # 停止主从复制，仅启动SQL线程

    *) fail "不支持 $cmd" ;;
  esac
}

# #####################################################################################################
# 主函数入口，方便测试和调用
# #####################################################################################################

main(){
  # 脚本入口
  if [ $cmd != "help" ] ; then
    check_db_opts
  fi

  run_cmd
}

main
