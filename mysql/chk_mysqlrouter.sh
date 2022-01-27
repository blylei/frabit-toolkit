#! /bin/bash
#---------------------------------------------------- Head info -------------------------------------------
# author          : zhangl (blylei@163.com)
# create datetime : 2021-10-14
# funcation       : 检查mysqlrouter的健康状态。如果失败，先尝试重启，重启不成功则kill掉keepalived,触发vip漂移
# script name     : chk_mysqlrouter.sh
#-----------------------------------------------------------------------------------------------------------
#-------------------------------------------------- Modified logs ------------------------------------------
# Version      People   Date             Notes
# V1.0.0       zhangl   2021-10-14       新增脚本
#-----------------------------------------------------------------------------------------------------------
DATE=`date +"%Y%m%d"`
LOG_FILE=/tmp/chk_mysqlrouter_${DATE}.log

log(){
    local dt_flg=`date +'%F %T'`
    echo "$dt_flg $1" >> ${LOG_FILE}
}

purge_log(){
  # 清理3天之前的日志文件
  find /tmp/ -type f -mtime +3 -name "chk_mysqlrouter_*" -exec rm -rf {} \;
}

chk_router(){
  log "检查mysqlrouter的健康状态"
  if [ "$(ps -ef | grep "mysqlrouter"| grep -v grep )" == "" ]
  then
    log "mysqlrouter的进程不存在，正在尝试重启"
    service mysqlrouter start
    sleep 3
    if [ "$(ps -ef | grep "mysqlrouter"| grep -v grep )" == "" ]
    then
      log "mysqlrouter重启失败"
      PID=1
      return $PID
    fi
  else
      log "mysqlrouter进程正常，退出检查"
      exit
  fi
}

chk_port(){
  log "检查mysqlrouter监听的端口是否存在"
  if [ "$(netstat -anptl | grep 'LISTEN' | grep 'mysqlrouter' | sed 's/:/ /g' | awk '{print $5}')" == "" ]
  then
    log "mysqlrouter监听的端口不存在，正在尝试重启"
    service mysqlrouter start
    sleep 3
    if [ "$(netstat -anptl | grep 'LISTEN' | grep 'mysqlrouter' | sed 's/:/ /g' | awk '{print $5}')" == "" ]
    then
      log "mysqlrouter重启失败"
      NID=1
      return $NID
    fi
  else
    log "mysqlrouter端口正常，退出检查"
    exit
  fi
}

main(){
  chk_router
  chk_port
  if [[ $PID = 1 ]] &&  [[ $NID = 1 ]]
  then
    echo $PID
    echo $NID
    log "mysqlrouter异常，正在停止keepalived"
    killall keepalived
  fi
  purge_log
}

main