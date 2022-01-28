#! /bin/bash

exe_path="/usr/bin"
# 检查环境变量文件是否存在，不存在则创建
if [[ ! -f /etc/profile.d/frabit-toolkit.sh ]]; then
  echo "#! /bin/bash" >>/etc/profile.d/frabit-toolkit.sh
  echo "export db_user='dbadmin'" >>/etc/profile.d/frabit-toolkit.sh
  echo "export db_passwd='dbpasswd'" >>/etc/profile.d/frabit-toolkit.sh
  chmod 755 /etc/profile.d/frabit-toolkit.sh
fi

