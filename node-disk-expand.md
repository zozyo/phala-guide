↖目录点这个图标 ⁝☰

# Phala 节点数据磁盘扩展

## 非 lvm 方法，直接挂载，本文以使用 solo 脚本举例

### 1. 停止 node 运行

```
sudo phala stop node
```

### 2. 接入新的大空间磁盘（以原先 1T，后插入一块 4T 磁盘举例）

```
如果只能关机接入的，上一步需要停止所有组件并关机
sudo phala stop
注意如果 pruntime 为旧版本，需要重新从 0 开始同步
新版本的 pruntime 有持久化功能，可以很快恢复
```

接入磁盘后，检查系统内是否有新磁盘出现
```
sudo lsblk | grep disk
```

如果为 SATA 硬盘，可能的返回是这样
```
sda      8:0    0   1T  0 disk
sdb      8:16    0   4T  0 disk
```

如果为 nvme 硬盘，可能的返回是这样
```
sda      8:0    0   1T  0 disk
nvme0n1      259:0    0   4T  0 disk
```

**可以得知新磁盘被分配到的卷标为 sdb (或是 nvme0n1)**

**此步非常关键！接下来的步骤中，使用错误的卷标可能会导致文件丢失及系统崩溃！！**


### 3. 格式化硬盘并建立分区（以 ext4 举例）

SATA 盘
```
sudo parted /dev/sdb mklabel gpt
下一步输入 yes 并回车
sudo mkfs.ext4 -F /dev/sdb
```

nvme 盘
```
sudo parted /dev/nvme0n1 mklabel gpt
下一步输入 yes 并回车
sudo mkfs.ext4 -F /dev/nvme0n1
```

### 4. 挂载磁盘（举例挂载到 /var/node_data/khala-dev-node）

SATA 盘
```
sudo mkdir /var/node_data
sudo mount /dev/sdb /var/node_data
```

nvme 盘
```
sudo mkdir /var/node_data
sudo mount /dev/nvme0n1 /var/node_data
```

### 5. 移动数据到新磁盘

```
数据量比较大，取决于硬盘读写速度，需要一定时间完成，请耐心等待
sudo mv /var/khala-dev-node /var/node_data/
```

### 6. 修改 node 使用目录

```
sudo sed -i "4c NODE_VOLUMES=/var/node_data/khala-dev-node:/root/data" /opt/phala/.env
```

### 7. 启动 phala

```
sudo phala start
```
