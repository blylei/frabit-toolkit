# toolkits
日常运维MySQL、Redis、MongoDB等开源数据库的实用脚本，每个脚本都可以在类Unix系统上独立运行，没有其他依赖

# 安装方法
将代码库克隆到本地，执行install.sh脚本即可
- 1、克隆源码
  ```bash
   git clone https://github.com/frabitech/frabit-toolkit.git
   cd frabit-toolkit $$ chmod 755 *
  ```
  
- 2、执行install脚本进行安装
  ```bash
  bash ./install.sh
  ```
- 3、功能预览

  ```bash
  shell> gtid-toolkit -c help
   
  用法: gtid-toolkit -c <cmd> -h ip_addr [-P <port>] -u <user> -p <passwd>
  举例: gtid-toolkit -c desc-topo -h 192.168.100.48 -u dbadmin -p Test_123
  选项:

  -H, --help            输出帮助文档并退出脚本
  -V, --version         输出版本号并退出脚本
  -c,--cmd <cmd>        【必选】指定需要执行的命令
  -h,--host <ip_addr>   【必选】数据库实例地址
  -P,--port <3306>      【可选】数据库端口号，不提供的话，默认为3306
  -u,--user <username>  【必选】数据库用户，需要在整个MySQL集群上都存在
  -p,--passwd <passwd>  【必选】数据库密码，需要在整个MySQL集群上都相同

    help               向控制台输出帮助信息
    desc-topo          探测MySQL集群拓扑结构
    inject-empty       到主库注入空事务
    reset-master       重置从库的gtid_purged
    enable-gtid        主从复制切换到gtid模式
    disable-gtid       主从复制切换到file:position模式
    find-master        根据提供的IP地址，返回该实例对应的主库
    enable-semisync    启用半同步复制
    disable-semisync   禁用半同步复制
    start-slave        启动主从复制，包含IO线程和SQL线程
    start-slave-io     启动主从复制，仅IO线程
    start-slave-sql    启动主从复制，仅SQL线程
    stop-slave         停止主从复制，包含IO线程和SQL线程
    stop-slave-io      停止主从复制，仅IO线程
    stop-slave-sql     停止主从复制，仅SQL线程
    check-repl-status  检查MySQL主从复制状态
  ```
  ```bash
  shell> gtid-toolkit --version
  (c) 2022 frabit-toolkit Project maintained and limited by Blylei < blylei.info@gmail.com >
  GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

  This toolkit is part of frabit-toolkit used for Oracle MySQL and Percona server

  GitHub: https://github.com/frabitech/frabit-toolkit
  Version: 2.0.1 
  
  ```