#! /bin/bash
#---------------------------------------------------- Head info -------------------------------------------
# author          : zhangl (blylei@163.com)
# create datetime : 2021-03-08
# funcation       : clone mysql account based on already exist
# script name     : clone_account.sh
#-----------------------------------------------------------------------------------------------------------
#-------------------------------------------------- Modified logs ------------------------------------------
# Version      People   Date             Notes
# V1.0.0       zhangl   2021-03-08       新增脚本
# V1.0.1       zhangl   2021-03-08       1）修复一个账号有多条授权记录，使用分号分割异常的场景；
#                                        2）脚本只能本地执行
# V1.0.2       zhangl   2021-11-10       修改执行SQL的逻辑
#-----------------------------------------------------------------------------------------------------------
set -x
# -------------------------定义全局变量--------------------------------------
INPUT="$1"   # format  原网段:目标网段:实例 【10.80:10.82】
if [ -z "$INPUT" ];then
    echo "输入参数:原网段:目标网段 [eg 10.80:10.82]"
    echo "使用方法:原网段->克隆源【包含用户名、密码、权限】"
    echo "使用方法:目标网段->待创建的新账号"
    exit 1
fi

src_net=`echo $INPUT | awk -F ':' '{print $1}'`
dest_net=`echo $INPUT | awk -F ':' '{print $2}'`
host=localhost
DEST_DIR=/tmp
MYSQL=`which mysql`
DATE=`date +"%Y%m%d%H"`
USER="root"
PASSWD=`cat /etc/.dbpwd`
PORT=3306
err_log="$DEST_DIR"/clone_account.err
accounts="$DEST_DIR"/account_"$DATE".txt
create_user_sql="$DEST_DIR"/account_"$DATE".sql
grant_user_sql="$DEST_DIR"/grant_"$DATE".sql


[[ -d ${DEST_DIR} ]] || mkdir -p ${DEST_DIR}

log(){
    local dt_flg=`date +'%F %T'`
    echo "$dt_flg $1" >> "$err_log"
}

get_account(){
  local host="$1"
  log "开始提取数据库账号"
  "$MYSQL" -h"$host" -u"$USER" -p"$PASSWD" -sN -e "select concat('\'',user,'\'','@','\'',host,'\'') from mysql.user where host like '$src_net.%'" >> "$accounts";
  log "提取数据库账号成功"
}

get_create_account_sql(){
  local host="$1"
  local account="$2"
  log "提取账号创建语句"
  local sql=`"$MYSQL" -h"$host" -u"$USER" -p"$PASSWD" -sN -e "SHOW CREATE USER $account;"`
  echo "$sql;" >> "$create_user_sql";
  log "替换账号网段"
  # 将账号创建语句中的源网段替换为新的网段，比如 10.80 替换为 10.82
  sed -i "s/$src_net/$dest_net/g" "$create_user_sql"
}

show_grant(){
  local host="$1"
  local account="$2"
  log "提取授权语句"
  local sql=`"$MYSQL" -h"$host" -u"$USER" -p"$PASSWD" -sN -e "SHOW  GRANTS FOR $account;"`
  echo "$sql" | grep -v USAGE >> "$grant_user_sql"
  # 将账号创建语句中的源网段替换为新的网段，比如 10.80 替换为 10.82
  log "替换权限网段"
  sed -i "s/$src_net/$dest_net/g" "$grant_user_sql"
}


execute_sql(){
  local host="$1"
  log "创建新账号"
  "$MYSQL" -h"$host" -u"$USER" -p"$PASSWD" -Nbe "source "$create_user_sql";"
  log "对新账号授权"
  "$MYSQL" -h"$host" -u"$USER" -p"$PASSWD" -Nbe "source "$grant_user_sql";"
}

clone_account(){
  local src_net="$1"
  local dest_net="$2"
  local host="$3"
  log "开始克隆账号"
  get_account "$host"

  for account in `cat "$accounts" `
  do
     get_create_account_sql "$host" "$account"
     show_grant "$host" "$account"
  done
  # V1.0.1
  sed -i "s/%'$/%';/g" "$grant_user_sql"
  execute_sql "$host"
  log "账号克隆完成"
}

clone_account "$src_net" "$dest_net" "$host"

exit 0
