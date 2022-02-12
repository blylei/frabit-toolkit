#! /bin/bash
# (c) 2022 frabit-toolkit Project maintained and limited by Blylei < blylei.info@gmail.com >
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)
#
# This toolkit is part of frabit-toolkit
#
exec_path="/usr/local/bin"

# 将项目库文件复制到 /etc/profile.d路径下
cp ./ft_common.sh /etc/profile.d/

# 将脚本复制到 /usr/local/bin路径下
for toolkit in $(ls -l ./mysql | grep -v total)
do
    name=$(echo "$toolkit" | awk -F'.' '{print $1}' | sed -r -e 's/_/-/')
    ln -s "$exec_path"/frabit-toolkit/mysql/"$toolkit" "$exec_path"/bin/"$name"
done
