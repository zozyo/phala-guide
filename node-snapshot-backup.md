↖目录点这个图标 ⁝☰

# Phala 节点数据备份方法

写了个生成备份的脚本，有需要的可以使用 [auto_node_snapshot.sh](./auto_node_snapshot.sh)

下载脚本（已下载的可跳过）

```
wget https://raw.githubusercontent.com/zozyo/phala-guide/main/auto_node_snapshot.sh -O auto_node_snapshot.sh
```

脚本使用了 pigz 加快压缩速度，会使用所有 CPU 线程，**不建议在未分离的机器上使用该脚本！**

示例使用方法：

```
sudo chmod +x auto_node_snapshot.sh
sudo ./auto_node_snapshot.sh
输入启动 node 的 docker-compose.yml 所在文件夹路径: /opt/phala
输入 node 的数据文件所在文件夹路径: /var
输入 node 的数据文件夹名称: khala-dev-node
输入保存快照文件的所在文件夹路径（请确保磁盘空间足够！）: /var/node-snap
节点数据已使用 798G，请确保快照文件所在磁盘空闲空间大于此值！[Y/n]: y
===准备开始备份！===
===今日日期 YYYY-MM-DD ===
===khala 高度 xxxxxx ===
===kusama 高度 xxxxxx ===
===停止节点===
===开始压缩，此步骤无显示，请耐心等待===
===压缩完成===
===启动节点===
Creating phala-node ... done  
```

生成好的压缩包解压示例，此示例节点数据保存在默认的 /var/khala-dev-node

**覆盖前必须先停止节点！！**

```
tar -xzf khala-snapshot-**********.tar.gz -C /var
tar -xzf kusama-snapshot-*********.tar.gz -C /var
```
