#! /bin/bash
#---------------------------------------------------- Head info -------------------------------------------
# author          : zhangl (blylei@163.com)
# create datetime : 2021-05-07
# funcation       : 从db的粒度，导入、导出MySQL表空间
# script name     : tablespace_io.sh
#-----------------------------------------------------------------------------------------------------------
#-------------------------------------------------- Modified logs ------------------------------------------
# Version      People   Date             Notes
# V1.0.0       zhangl   2021-05-07       新增脚本
#-----------------------------------------------------------------------------------------------------------
set -x
# -------------------------定义全局变量--------------------------------------
INPUT="$1"
DEST_DIR=/etc/rc.d
TABLES=$DEST_DIR/tablespace_io.txt
mysql=$(which mysql)
DATE=$(date +"%Y-%m-%d")
mysql_user="root"
mysql_pwd=$(cat /etc/.dbpwd)
mysql_datadir=/mysqldata
error_file=$DEST_DIR/tablespace_io.log

log_info() {
  # 将操作日志格式化以后登记到日志文件内
  dt_flg=$(date +'%F %T')
  echo "$dt_flg $1" >>${error_file}
}

exe_sql(){
  # 向MySQL服务器提交拼接完成的SQL
  local db="$1"
  log_info "获取$db 包含的物理表"
  local sql="select concat(TABLE_SCHEMA,'.',TABLE_NAME) from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA ='$db' AND TABLE_TYPE='BASE TABLE';"
  $mysql -u"$mysql_user" -p"$mysql_pwd" -NBe "$sql" >> $TABLES
}

get_tables() {
  read -r -p  "请输入你需要操作的所有库名(可多个),名称之间用空格隔开即可: " dbnames
  for db in $dbnames
  do
     exe_sql "$db"
  done
  return 0
}

discard_tablespace(){
  local tables=$(cat $TABLES)
  log_info "开始解绑表空间的操作"
  for table in $tables
  do
     local sql="SET sql_log_bin=0;ALTER TABLE $table DISCARD TABLESPACE;"
     $mysql -u"$mysql_user" -p"$mysql_pwd" -NBe "$sql" >/dev/null
     log_info "解绑$table 的表空间"
  done
}

import_tablespace(){
  local tables=$(cat $TABLES)
  log_info "修改datadir的文件属性"
  chown -R mysql:mysql "$mysql_datadir"
  log_info "开始导入表空间的操作"
  for table in $tables
  do
     local sql="SET sql_log_bin=0;ALTER TABLE $table IMPORT TABLESPACE;"
     $mysql -u"$mysql_user" -p"$mysql_pwd" -NBe "$sql" >/dev/null
     log_info "导入$table 的表空间"
  done
}

rename_mid_file(){
   # 在当前操作结束后，将操作表清单重命名，备查
   local file="$TABLES"
    mv "$file" "$file"_bak
    log_info "重命名$file"
   return 0
}

main() {
  get_tables
  read -r -p  "请输入你需要进行的操作[import/discard]: " opt
  if [[ "$opt" == "import"  ]];then
              import_tablespace
  elif [[ "$opt" == "discard"  ]];then
              discard_tablespace
  else
     log_info "该操作无效，请输入import或者discard"
     exit 1
	fi
  rename_mid_file
  exit 0
}

main
