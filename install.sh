#! /bin/bash

exec_path="/usr/local/bin"
# 检查环境变量文件是否存在，不存在则创建
if [[ ! -f /etc/profile.d/frabit-toolkit.sh ]]; then
  echo "#! /bin/bash" >>/etc/profile.d/frabit-toolkit.sh
  echo "export db_user='dbadmin'" >>/etc/profile.d/frabit-toolkit.sh
  echo "export db_passwd='dbpasswd'" >>/etc/profile.d/frabit-toolkit.sh
  chmod 755 /etc/profile.d/frabit-toolkit.sh
fi

# 给脚本创建软连接
cp ./* "$exec_path"/frabit-toolkit

for dir in $(ls -l  "$exec_path"/frabit-toolkit | awk '/^d/ { print $9}')
do
  for toolkit in $(ls | "$exec_path"/frabit-toolkit/"$dir")
  do
    name=$(echo "$toolkit" | awk -F'.' '{print $1}' | sed -r -e 's/_/-/')
    ln -s "$exec_path"/frabit-toolkit/mysql/"$toolkit" "$exec_path"/"$name"
  done
done
