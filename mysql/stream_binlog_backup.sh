#! /bin/bash
#---------------------------------------------------- Head info -------------------------------------------
# author          : zhangl (blylei@163.com)
# create datetime : 2021-10-14
# funcation       : 在备份slave上实时拷贝对应主库的binlog
# script name     : stream_binlog_backup.sh
#-----------------------------------------------------------------------------------------------------------
#-------------------------------------------------- Modified logs ------------------------------------------
# Version      People   Date             Notes
# V1.0.0       zhangl   2021-10-14       新增脚本
#-----------------------------------------------------------------------------------------------------------
set -x
set -o pipefail

# Initial values
source /etc/stream_binlog.cnf # 敏感信息存储在单独的配置文件里面
lock_file="/var/lock/stream_binlog.lock"
error_file="/var/log/mysql/stream_binlog.err"
log_file="/var/log/mysql/stream_binlog.log"
retention=30 # Retention in days
bin_prefix="mysql-bin"
binlog_base_path="/remote_backup/binlog"
binlog_backup_path="${binlog_base_path}"/"${source_mysql_host}"
retry=3


create_file_if()
{
	[[ -d ${binlog_backup_path} ]] || mkdir -p ${binlog_backup_path}
  [[ -f ${log_file} ]] || touch ${log_file}
	[[ -f ${error_file} ]] || touch ${error_file}
}


send_alert(){
  if [ -e "$error_file" ]; then
    alert_msg=$(cat $error_file)
    echo -e "${alert_msg}" | mailx -s "[$HOSTNAME] ALERT binlog backups" "${email}"
  fi
}

destructor(){
  send_alert
  local latest=$(ls -1 $binlog_backup_path | egrep mysql-bin.[0-9] | tail -1)
  rm -f $lock_file $error_file

}

# Setting TRAP in order to capture SIG and cleanup things
trap destructor EXIT INT TERM

verify_execution(){
  local exit_code="$1"
  local must_die=${3-:"false"}
  if [ $exit_code -ne "0" ]; then
    msg="[ERROR] Failed execution. ${2}"
    echo "$msg" >>${error_file}
    if [ "$must_die" == "true" ]; then
      exit 1
    else
      return 1
    fi
  fi
  return 0
}

set_lock_file(){
  pidmbl=$(pidof mysqlbinlog)
  if [[ -e "$lock_file" || ! -z "$pidmbl" ]]; then
    trap - EXIT INT TERM
    verify_execution "1" "Script already running. $lock_file exists or mysqlbinlog is already running. $pidmbl"
    send_alert
    rm -f "$error_file"
    exit 2
  else
    touch "$lock_file"
    create_file_if
  fi
}

log_info(){
  echo "[$(date +%y%m%d-%H:%M:%S)] $1" >>$log_file
}

get_binlog_size(){
  binlog_size=$(mysql -u${mysql_user} --password=${mysql_password} -h${source_mysql_host} --port=${source_mysql_port} -N -e"show variables like 'max_binlog_size'" 2>/dev/null | awk '{print $2}' 2>&1)
  verify_execution "$?" "Error getting max_binlog_size $out"

  if [ -z "$binlog_size" ]; then
    binlog_size=1024
    log_info "[Warning] Cannot get max_binlog_size value, instead 1024 Bytes used"
    return
  fi

  log_info "[OK] max_binlog_size obtained: $binlog_size"
}

verify_mysqlbinlog(){

  which mysqlbinlog &>/dev/null
  verify_execution "$?" "Cannot find mysqlbinlog tool" true
  log_info "[OK] Found 'mysqlbinlog' utility"

  have_raw=$(mysqlbinlog --help | grep "\--raw")
  if [ -z "$have_raw" ]; then
    verify_execution "1" "Incorrect mysqlbinlog version. Needs 5.6 and later version with --raw parameter" true
  fi
  log_info "[OK] Verified mysqlbinlog utility version"
}

find_first_binlog(){
  local first=$(mysql -u${mysql_user} --password=${mysql_password} -h${source_mysql_host} --port=${source_mysql_port} -N -e"show binary logs" 2>/dev/null | head -n1 | awk '{print $1}')
  echo "$first"
}

find_latest_binlog(){
  pushd $binlog_backup_path &>/dev/null
  verify_execution "$?" "Backup path $binlog_backup_path does not exists" true

  local latest=$(ls -1 | grep $bin_prefix | tail -1)
  msg="[OK] Found latest backup binlog: $latest"
  if [ -z "$latest" ]; then
    latest=$(find_first_binlog)
    msg="[Warning] No binlog file founded on backup directory (${binlog_backup_path}). Using instead $latest as first file (obtained from SHOW BINARY LOGS)"
  fi
  log_info "$msg"
  popd &>/dev/null
  # cmd_md5=md5sum /mysqldata/binlog/$latest | awk  '{printf "%s\n",$1}'
  # local_latest_md5=$(md5sum "$latest" | awk  '{printf "%s\n",$1}')
  # source_md5=$(ssh ${source_mysql_host} )
  latest=${latest%%.gz}
  echo "$latest"
}

stream_binlogs(){
  first_binlog_file=$(find_latest_binlog)
  pushd $binlog_backup_path &>/dev/null

  out=$(mysqlbinlog --raw --read-from-remote-server --stop-never --verify-binlog-checksum --user=${mysql_user} --password=${mysql_password} --host=${source_mysql_host} --port=${source_mysql_port}  --stop-never-slave-server-id=54060 $first_binlog_file 2>&1) &
  verify_execution "$?" "Error while launching mysqlbinlog utility. $out"
  pid_mysqlbinlog=$(pidof mysqlbinlog)
  log_info "[OK] Launched mysqlbinlog utility. Backup running: mysqlbinlog --raw --read-from-remote-server --stop-never --verify-binlog-checksum --user=${mysql_user} --password=XXXXX --host=${source_mysql_host} --port=${source_mysql_port} --stop-never-slave-server-id=54060 $first_binlog_file"

  popd &>/dev/null
}

rotate_backups(){
  out=$(find $binlog_backup_path -type f -name "${bin_prefix}*" -mtime +${retention} -print -exec rm -Rf {} \;)
  es=$?
  if [ "$es" -ne 123 ]; then
    verify_execution "$es" "Error while removing old backups. $out" true
  fi

}

compress_binlogs(){

  pushd $binlog_backup_path &>/dev/null
  local now=$(date +%s)
  local skip_first=1

  for i in $(ls -1t | grep $bin_prefix | grep -v ".gz"); do
    if [ $skip_first -eq 1 ]; then
      skip_first=0
      continue
    fi
    local created=$(stat -c %Y $i)
    local diff=$(($now - $created))
    local size=$(du -b $i | awk '{print $1}')

    if [[ $size -ge $binlog_size || $diff -gt 300 ]]; then
      out=$(gzip $i 2>&1)
      verify_execution "$?" "Error compressing binlog file ${i}. $out" true
    fi
  done

  popd &>/dev/null

}

verify_all_running(){

  local try_this_times=$(echo $retry)
  while true; do
    if [ ! -d /proc/$pid_mysqlbinlog ]; then
      log_info "[ERROR] mysqlbinlog stopped. Attempting a restart .... "
      stream_binlogs
      try_this_times=$(($try_this_times - 1))
      if [ $try_this_times -eq 0 ]; then
        verify_execution "1" "Error while restarting mysqlbinlog utility after $retry attempts. Terminating the script" true
      fi
    fi

    compress_binlogs
    rotate_backups

    sleep 30
  done
}

set_lock_file
verify_mysqlbinlog
get_binlog_size
stream_binlogs
verify_all_running
