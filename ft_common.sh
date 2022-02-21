#! /bin/bash
# (c) 2022 frabit-toolkit Project maintained and limited by Blylei < blylei.info@gmail.com >
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)
#
# This toolkit is part of frabit-toolkit used for Oracle MySQL and Percona server
#

about_toolkits(){
 # 展示项目信息
 local VERSION='2.0.1'
 local proj_url='https://github.com/frabitech/frabit-toolkit'
 echo "(c) 2022 frabit-toolkit Project maintained and limited by Blylei < blylei.info@gmail.com >
GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

This toolkit is part of frabit-toolkit used for Oracle MySQL and Percona server

GitHub: $proj_url
Version: $VERSION
 "
}

error() {
  local lineno=$1
  shift
  if [[ -n "$lineno" ]]; then
    printf "${BD}ERROR${NBD} (line:$lineno) : ${*//%/%%}\n" 1>&2
  else
    printf "${BD}ERROR${NBD} : ${*//%/%%}\n" 1>&2
  fi
}

warning() {
  local lineno=$1
  shift
  if [[ -n "$lineno" ]]; then
    printf "${BD}WARNING${NBD} (line:$lineno) : ${*//%/%%}\n" 1>&2
  else
    printf "${BD}WARNING${NBD}: ${*//%/%%}\n" 1>&2
  fi
}

info() {
  if [[ $DEBUG -eq 1 ]]; then
    local lineno=$1
    shift
    if [[ -n "$lineno" ]]; then
      printf "${RED}${BD}info (line:$lineno) : ${*//%/%%}${NBD}${NRED}\n" 1>&2
    else
      printf "${RED}info: ${*//%/%%}${NRED}\n" 1>&2
    fi
  fi
}

debug() {
  if [[ $DEBUG -eq 1 ]]; then
    local lineno=$1
    shift
    if [[ -n "$lineno" ]]; then
      printf "${RED}${BD}debug (line:$lineno) : ${*//%/%%}${NBD}${NRED}\n" 1>&2
    else
      printf "${RED}debug: ${*//%/%%}${NRED}\n" 1>&2
    fi
  fi
}

# 将安全系数较高的选项以环境变量的形式提供
export VARIABLE="test"