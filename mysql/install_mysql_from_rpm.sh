#! /bin/bash
#---------------------------------------------------- Head info ---------------------------------------
# author          : lei6.zhang (lei6.zhang@ly.com)
# create datetime : 2022-05-24
# funcation       : 基于rpm包一键安装官方版的MySQL
# script name     : install_mysql_from_rpm.sh
#------------------------------------------------------------------------------------------------------
#-------------------------------------------------- Modified logs -------------------------------------
# Version      People       Date             Notes
# V1.0.0       lei6.zhang   2022-05-24       新增脚本
#------------------------------------------------------------------------------------------------------
# set -x

error_file=/tmp/imfr.log
work_dir=/tmp/
mysql_db_dir=/data/mysql
cd "$work_dir"
# #####################################################################################################
# 接收并预处理命令行参数
# #####################################################################################################

for arg in "$@";do
shift
  case "$arg" in
    "-help"|"--help")                     set -- "$@" "-H" ;;
    "-version"|"--version")               set -- "$@" "-v" ;;
    "-mode"|"--mode")                     set -- "$@" "-m" ;;
    *)                                    set -- "$@" "$arg"
  esac
done

while getopts "v:m:H" OPTION
do
  case $OPTION in
    H) cmd="help" ;;
    c) cmd="$OPTARG" ;;
    v) version="$OPTARG" ;;
    m) mode="$OPTARG" ;;
    *) echo "未知选项" ;;
  esac
done

# #####################################################################################################
# 以下函数为共用的
# #####################################################################################################

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

check_opts(){
  # 检查连接数据库的版本信息是否提供
  assert_nonempty "version" "$version"
  # assert_nonempty "mode" "$mode"
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

get_os_info(){
  # 获取Linux的版本和架构
  local info=$(uname -r | awk -F"-" '{print $2}' | awk -F"." '{print $2,$3}')
  echo "$info"
}

remove_mariadb_if(){
  # 清理操作系统自带的MariaDB共享包
  local pkg=$(rpm -qa | grep mariadb)
  if [[ "$pkg" != "" ]];then
    rpm -e "$pkg" --nodeps
    log "正在移除：$pkg"
  fi

}

remove_other_version_if(){
  # 如果存在其他版MySQL，则先清理掉，在安装新版
  local pkgs=$(rpm -qa | grep mysql)
  if [[ "$pkgs" != "" ]];then
     # 如果存在的版本跟即将安装的相同，则跳过安装
     exist_mysql=$(mysqld --version | awk '{print $3}')
     if [[ "$exist_mysql" == "$version" ]];then
        fail "即将安装的MySQL版本已存在，请检查！！！"
     fi
     for comp in ${pkgs};do
        rpm -e "$comp" --nodeps
        log "正在移除：$comp"
     done
  fi
}

precheck(){
  #
  remove_mariadb_if
  remove_other_version_if

}

download_rpm(){
  # 从Oracle MySQL的yum源下载指定版本的MySQL组件
  # rpm包URL模式：https://repo.mysql.com/yum/mysql-5.7-community/el/7/x86_64/mysql-community-client-5.7.21-1.el7.x86_64.rpm
  local base_url="https://repo.mysql.com/yum"
  # MySQL版本号: major.minor.patch eg. 5.7.36
  major=$(echo "$version" | awk -F"." '{print $1}')
  minor=$(echo "$version" | awk -F"." '{print $2}')
  patch=$(echo "$version" | awk -F"." '{print $3}')

  info_str=$(get_os_info)
  arch=$(echo "$info_str" | awk -F" " '{print $2}')
  dist_os_version=$(echo "$info_str" | awk -F" " '{print $1}')
  case $dist_os_version in
     "el6") os_version=6 ;;
     "el7") os_version=7 ;;
     "el8") os_version=8 ;;
     *) fail "未知CentOS 版本: $dist_os_version"
  esac

  for comp in "server" "devel" "client" "common" "libs" "libs-compat";do
    local pkg=${base_url}/mysql-${major}.${minor}-community/el/"$os_version"/"$arch"/mysql-community-"$comp"-${major}.${minor}.${patch}-1.${dist_os_version}.${arch}.rpm
    log "正在下载: $pkg"
    wget "$pkg"
  done
}

transfer_rpm(){
  # 如果rpm包在本地或者中控机上，将其转移到待安装机器的work_dir路径下
  log "该功能待实现"
}

install_rpm(){
  # 将下载好的rpm安装到操作系统
    case $mode in
         "remote") download_rpm ;;
         "local") transfer_rpm ;;
         *) fail "未知安装方式，请重试: $mode"
    esac
    log "开始安装rpm包"
    rpm -ivh mysql-community-{server,devel,client,common,libs,libs-compat}-"${major}"."${minor}"."${patch}"-1."${dist_os_version}"."${arch}".rpm

}

check_exec_status(){
  # 检查函数执行的结果，如果失败则退出
  local exit_code="$1"
  if [ $exit_code -ne "0" ];then
     msg="[Error] 执行失败"
     fail "$msg"
  fi
}

create_dirs(){
  # 创建MySQL的数据文件夹和日志文件夹等
  log "开始创建数据文件夹和日志文件夹"
  mkdir -p ${mysql_db_dir}/{mysql_data,mysql_log,mysql_tmp} || fail "文件夹创建失败：mysql_data,mysql_log,mysql_tmp"
  mkdir -p ${mysql_db_dir}/mysql_log/{binlog,relaylog,logs} || fail "文件夹创建失败：binlog,relaylog,logs"
  log "修改DB修改文件夹的熟悉为 -R mysql:mysql"
  chown -R mysql:mysql ${mysql_db_dir}
  return 0

}

create_conf(){
  # 基于机器资源信息，生成/etc/my.cnf配置文件
  if [ -f /etc/my.cnf ];then
    cp /etc/my.cnf /etc/my.cnf_bak
  fi
  # 数据库实例的server-id由该机器物理IP的后两段组成，eg 172.100.23.189 --> server-id=23189
  local third=$(ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v 172.17.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:" | head -n 1 | awk -F"." '{print $3}')
  local fourth=$(ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v 172.17.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:" | head -n 1 | awk -F"." '{print $4}')
  local server_id="$third""$fourth"
  # buffer pool 分配宿主机75%的内存：mem * 0.75 向前取整
  local all_mem=$(free -g | grep Mem | awk '{print $2}')
  local ibbuf_pool_size=$(echo "$all_mem" \* 0.75 | bc | awk -F"." '{print $1}')
  local innodb_buffer_pool_size="$ibbuf_pool_size""G"
  log "开始生成MySQL配置文件：/etc/my.cnf"
  cat > /etc/my.cnf <<EOF
[client]
port            = 3000
socket          = ${mysql_db_dir}/mysql_data/mysql.sock

[mysql]
no-auto-rehash
max_allowed_packet = 128M
prompt                         = '(sit)(\u@\h) [\d]> '
default_character_set          = utf8mb4

[mysqldump]
quick
max_allowed_packet          = 128M
#myisam_max_sort_file_size  = 10G

[mysqld]
port            = 3000
user            = mysql
socket          = ${mysql_db_dir}/mysql_data/mysql.sock
# basedir       = /usr/local/mysql
datadir         = ${mysql_db_dir}/mysql_data
tmpdir          = ${mysql_db_dir}/mysql_tmp

character-set-server    = utf8mb4
sysdate-is-now
skip-name-resolve
read_only               = 1
open_files_limit        = 60000
table_open_cache        = 4096
table_definition_cache  = 4096
max_connections         = 5000
max_connect_errors      = 100000
back_log                = 1000
wait_timeout            = 3000
interactive_timeout     = 3000

sort_buffer_size        = 32M
read_buffer_size        = 8M
read_rnd_buffer_size    = 16M
join_buffer_size        = 32M

tmp_table_size          = 512M
max_heap_table_size     = 512M
max_allowed_packet      = 128M
myisam_sort_buffer_size = 64M

key_buffer_size             = 1G
query_cache_type            = 0
query_cache_size            = 0

eq_range_index_dive_limit = 2000
lower_case_table_names    = 1
explicit_defaults_for_timestamp = 1
# ====================== Logs Settings ================================
log-error            = ${mysql_db_dir}/mysql_log/logs/error.log
slow-query-log       = on
slow-query-log-file  = ${mysql_db_dir}/mysql_log/logs/slow.log
long_query_time      = 3

#log_slow_slave_statements      = 1

log_bin_trust_function_creators = 1
log-bin                         = ${mysql_db_dir}/mysql_log/binlog/mysql-bin
log-bin-index                   = ${mysql_db_dir}/mysql_log/binlog/mysql-bin.index

sync_binlog        = 1
expire_logs_days   = 7
binlog_format      = ROW
binlog_cache_size  = 8M
# ===================== Replication settings =========================
server-id                        = ${server_id}
binlog_gtid_simple_recovery      = 1
gtid_mode                        = ON
enforce-gtid-consistency         = 1
skip-slave-start                 = ON
relay-log                        = ${mysql_db_dir}/mysql_log/relaylog/mysql-relay-bin
relay-log-index                  = ${mysql_db_dir}/mysql_log/relaylog/mysql-relay-bin.index
relay-log-purge                  = 0
log-slave-updates                = on
master_info_repository           = TABLE
relay_log_info_repository        = TABLE
relay_log_recovery               = 1
# ====================== INNODB Specific Options ======================
innodb_data_home_dir                 = ${mysql_db_dir}/mysql_data
innodb_data_file_path                = ibdata1:10M:autoextend
innodb_buffer_pool_size              = ${innodb_buffer_pool_size}
innodb_buffer_pool_instances         = 8
innodb_log_buffer_size               = 128M
innodb_log_group_home_dir            = ${mysql_db_dir}/mysql_data
innodb_log_files_in_group            = 5
innodb_log_file_size                 = 50m
innodb_fast_shutdown                 = 1
innodb_force_recovery                = 0
innodb_file_per_table                = 1
innodb_lock_wait_timeout             = 100
innodb_thread_concurrency            = 64
innodb_flush_log_at_trx_commit       = 1
innodb_flush_method                  = O_DIRECT
innodb_read_io_threads               = 12
innodb-write-io-threads              = 16
innodb_io_capacity                   = 100
innodb_io_capacity_max               = 500
innodb_purge_threads                 = 1
innodb_autoinc_lock_mode             = 2
innodb_sort_buffer_size              = 6M
innodb_max_dirty_pages_pct           = 75
transaction-isolation                = READ-COMMITTED
# ======================  Undo Options ======================
innodb_undo_directory    =${mysql_db_dir}/mysql_data
innodb_undo_logs         = 128
innodb_undo_tablespaces  = 4
innodb_undo_log_truncate = on
innodb_max_undo_log_size = 100m
innodb_purge_rseg_truncate_frequency = 128

# ======================  mysqld-5.7 ======================
log_timestamps                       = system
innodb_purge_rseg_truncate_frequency = 128
innodb_buffer_pool_dump_pct          = 40
innodb_undo_log_truncate             = on
innodb_max_undo_log_size             = 5M
slave_preserve_commit_order          = 1
show_compatibility_56                = on
slave-parallel-type                  = LOGICAL_CLOCK
slave_parallel_workers               = 8
sql_mode = ''
event_scheduler=ON
EOF

}

add_admin_account(){
  # 新增mha账号、主从复制账号、zabbix监控账号等
  local sql="select 1;\
             select 2;"
  mysql -uroot -p"$random_passwd" -NBe "$sql"
  log "正在创建DB管理账号："
}

start_mysql(){
  # 配置开机启动脚本，并启动mysqld服务
  systemctl enable mysqld.service
  setenforce 0
  systemctl start mysqld.service

}

init_instance(){
  # 重置root@localhost账号的密码，并新增其他管理类账号
  precheck
  install_rpm
  create_dirs
  create_conf

  start_mysql
  random_passwd=$(grep "temporary password" ${mysql_db_dir}/mysql_log/logs/error.log | awk  -F":" '{print $5}' | awk '{print $1}')
  mysql -uroot -p"$random_passwd" --connect-expired-password -NBe "alter user root@localhost identified by '$random_passwd';"
  add_admin_account
  section "运行结果展示"
  name_val "时间" $(date +'%F %T')
  name_val "root" "【$random_passwd】"

}

prompt_help() {
  echo "用法: install_mysql_from_rpm -c <cmd> -h major.minor.patch -m remote"
  echo "举例: install_mysql_from_rpm -v 5.7.36 -m remote"
  echo "举例: install_mysql_from_rpm -v 5.7.36"
  echo "选项:"
  echo "
  -H, --help                    输出帮助文档并退出脚本
  -c,--cmd <cmd>               【可选 默认 install】指定需要执行的命令
  -v,--version <x.y.z>         【必选】MySQL版本号: major.minor.patch eg. 5.7.36
  -m,--mode <remote | local>   【可选 默认 remote】安装本地rpm包或者从MySQL官方yum下载下载
"
}

# #####################################################################################################
# 以下函数与命令行对应，分别实现某个实用功能
# #####################################################################################################


run_cmd(){
  # 运行命令
  # 如果没有在命令行里提供安装模式，则默认从MySQL官方yum源下载
  if [ -z "$mode" ] ; then
    mode="remote"
  fi
  # 在不通过cmd命令时，默认为install
  if [ -z "$cmd" ] ; then
    cmd="install"
  fi
  case $cmd in
    "help") prompt_help ;;                 # 向控制台输出帮助信息
    "install") init_instance ;;

    "*") fail "未知命令：$cmd" ;;
  esac
}

# #####################################################################################################
# 主函数入口，方便测试和调用
# #####################################################################################################

main(){
  # 脚本入口
  if [ $cmd != "help" ] ; then
    check_opts
  fi

  run_cmd
}

main