# toolkits
日常运维MySQL、Redis、MongoDB的实用脚本，每个脚本都可以在类Unix系统上独立运行，没有其他依赖

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
- 3、探测当前集群的拓扑结构
  ```bash
  gtid_toolkit -c desc_topo -i 192.168.100.48
  ```
  
- 4、修复gtid异常的集群
  
  - 注入空事务
    ```bash
      gtid_toolkit -c desc_topo -i 192.168.100.48
    ```
    
  - 重置从库gtid值
    ```bash
      gtid_toolkit -c reset_master -i 192.168.100.48
    ```
