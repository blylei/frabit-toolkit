#! /bin/bash

exec_path="/usr/local/bin"
# 检查环境变量文件是否存在，不存在则创建
if [[ ! -f /etc/profile.d/frabit-toolkit.sh ]]; then
  echo "#! /bin/bash" >>/etc/profile.d/frabit-toolkit.sh
  echo "export db_user='dbadmin'" >>/etc/profile.d/frabit-toolkit.sh
  echo "export db_passwd='dbpasswd'" >>/etc/profile.d/frabit-toolkit.sh
  chmod 755 /etc/profile.d/frabit-toolkit.sh
fi

# 将脚本复制到 /usr/local/bin路径下
for toolkit in $(ls -l ./mysql | grep -v total)
do
    name=$(echo "$toolkit" | awk -F'.' '{print $1}' | sed -r -e 's/_/-/')
    ln -s "$exec_path"/frabit-toolkit/mysql/"$toolkit" "$exec_path"/bin/"$name"
done

for toolkit in $(ls | "$exec_path"/frabit-toolkit/redis)
do
    name=$(echo "$toolkit" | awk -F'.' '{print $1}' | sed -r -e 's/_/-/')
    ln -s "$exec_path"/frabit-toolkit/mysql/"$toolkit" "$exec_path"/bin/"$name"
done

for toolkit in $(ls | "$exec_path"/frabit-toolkit/mongodb)
do
    name=$(echo "$toolkit" | awk -F'.' '{print $1}' | sed -r -e 's/_/-/')
    ln -s "$exec_path"/frabit-toolkit/mysql/"$toolkit" "$exec_path"/bin/"$name"
done