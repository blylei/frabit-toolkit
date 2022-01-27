#! /bin/bash
#---------------------------------------------------- Head info -------------------------------------------
# author          : zhangl (blylei@163.com)
# create datetime : 2020-12-30
# funcation       : 将创建DB、创建应用账号及授权封装到脚本里,一键完成
# script name     : createdb.sh
#-----------------------------------------------------------------------------------------------------------
#-------------------------------------------------- Modified logs ------------------------------------------
# Version      People   Date             Notes
# V1.0.0       zhangl   2020-12-30       新增脚本
# V1.0.1       zhangl   2021-01-04       新增密码生成选项:可使用已知密码进行创建账号
#-----------------------------------------------------------------------------------------------------------
set -x

# 设定相关的初始值
dbname="$1"
mysql=$(which mysql)
date_=$(date +"%Y-%m-%d")
mysql_user="root"
mysql_pwd=$(cat /etc/.dbpwd)
lockFile="/var/lock/createdb.lock"
errorFile="/var/log/createdb.err"
resultFile="/etc/rc.d/createdb.txt"
port=3306
# 以下变量需要针对性的进行修改，不同实例，不同环境对应的域名和客户端IP都是不同的
hostname="db1.frabitech.com"
client_ips=('10.74.%' '10.70.%')

log() {
  # 将操作日志格式化以后登记到日志文件内
  dt_flg=$(date +'%F %T')
  echo "$dt_flg $1" >>${errorFile}
}

warron(){
  # 将操作日志格式化以后登记到日志文件内
  pass
}

get_pwd() {
  # 生成一个随机密码，满足如下密码强度要求：
  # 1）总长度12位
  # 2）包含字母大小写
  # 3）包含数字
  # 3）至少包含一个特殊字符【#、@、%、+、$】
  local pwd=$(openssl rand -base64 8)
  log "已生成密码: $pwd "
  echo "$pwd"
}

exe_sql() {
  # 向MySQL服务器提交拼接完成的SQL
  sql="$1"
  $mysql -u"$mysql_user" -p"$mysql_pwd" -e "$sql" >/dev/null
}

create_db() {
  # 根据传入的数据库名称进行创建,字符集不指定的话使用默认值
  local db="$1"
  local opt="utf8mb4"
  local sql="CREATE DATABASE $db DEFAULT CHARACTER SET $opt;"
  exe_sql "$sql"
  log "已创建数据库: $db"
}

grant_priv() {
  # 给指定账号授权：INSERT | SELECT | UPDATE | DELETE
  # 外部传入需要进行授权的账号 user
  # 外部传入需要进行授权的数据库 db
  local user="$1"
  local db="$2"
  local priv="INSERT ,SELECT ,UPDATE ,DELETE"
  local sql="GRANT $priv ON $db.* TO $user;"
  exe_sql "$sql"
  log "已给 ${user} 授予 ${db} ${priv} 的权限"
}

create_user() {
  # 创建应用账号并进行授权
  local db="$1"

  pwd=$(get_pwd)
  tmp_pwd="'"$pwd"'"
  for ((i = 0; i < ${#client_ips[@]}; i++)); do
    local ip=${client_ips["$i"]}
    local account="'$db'"@"'$ip'"
    local sql="CREATE USER $account IDENTIFIED BY $tmp_pwd;"
    exe_sql "$sql"
    log "已创建用户: $account "
    grant_priv "$account" "$db"
  done
}

main() {
  # 各函数入口
  local db="$1"
  create_db "$db"
  create_user "$db"
  echo "################ $date_ ######################## " >>${resultFile}
  echo "应用账号: $db 密码: $pwd 域名: $hostname 端口: $port" >>${resultFile}
  echo "################### END ######################## " >>${resultFile}
}

main "$dbname"
