#! /bin/bash
#---------------------------------------------------- Head info ---------------------------------------
# author          : lei6.zhang (lei6.zhang@ly.com)
# create datetime : 2022-07-05
# funcation       : 缩减文件的大小
# script name     : truncate_file.sh
#------------------------------------------------------------------------------------------------------
#-------------------------------------------------- Modified logs -------------------------------------
# Version      People       Date             Notes
# V1.0.0       lei6.zhang   2022-07-05       新增脚本
#------------------------------------------------------------------------------------------------------
# set -x
truncate_cmd=$(which truncate)
my_name=$(basename $0)
if [ -z "$truncate_cmd" ] ; then
  exit 1
fi

for arg in "$@";do
shift
  case "$arg" in
    "-help"|"--help")                     set -- "$@" "-H" ;;
    "-file"|"--file")                     set -- "$@" "-f" ;;
    *)                                    set -- "$@" "$arg"
  esac
done

while getopts "f:H" OPTION
do
  case $OPTION in
    H) cmd="help" ;;
    f) file="$OPTARG" ;;
    *) echo "未知选项" ;;
  esac
done

fail(){
  # 输出错误日志，并退出脚本执行
  message="${my_name[$$]}: $1"
 >&2 echo "$message"
  exit 1
}

assert_nonempty() {
  name="$1"
  value="$2"

  if [ -z "$value" ] ; then
    fail "$name 必须提供对应的值"
  fi
}

check_opts(){
  # 必须提供需要操作的文件名
  assert_nonempty "file" "$file"
}

prompt_help() {
  echo "用法: truncate_file -f /full/path/to/file"
  echo "举例: truncate_file -f  /tmp/testfile.txt"
  echo "选项:"
  echo "
  -H, --help                    输出帮助文档并退出脚本
  -f, --filename               【必选】指定需要缩减大小的文件名
"
}

get_filesize(){
  # 获取到文件的byte大小，，将其转换成gigabyte
  local file_name="$1"
  local size_byte=$(du -b "$file_name"  | awk '{print $1}')
  local giga_unit=1073741824 # 1024*1024*1024
  # size=$(expr $size_byte / $giga_unit)
  size=$((size_byte / giga_unit))
  echo "$size"
}

truncate_file(){
  # 当文件大小超过10G时，才会缩减文件的大小，否则退出执行
  local file_name="$file"
  local file_size=$(get_filesize "$file_name")

  if [ "$file_size" -gt 10 ];then
    for size in $(seq "$file_size" -10 10);do
      sleep 3
      truncate_cmd -s "$size"G "$file_name"
      echo "剩余文件大小：$size"
    done
  else
      fail "该文件大小为：$file_size G.文件小于10G，请使用rm命令直接删除"
  fi
}

run_cmd(){
  # 运行命令
  # 在不通过cmd命令时，默认为install
  if [ -z "$cmd" ] ; then
    cmd="do"
  fi
  case $cmd in
    "help") prompt_help ;;                 # 向控制台输出帮助信息
    "do") truncate_file ;;

    "*") fail "未知命令：$cmd" ;;
  esac
}

# #####################################################################################################
# 主函数入口，方便测试和调用
# #####################################################################################################

main(){
  # 脚本入口
  if [[ $cmd != "help" ]] ; then
    check_opts
  fi

  run_cmd
}

main

