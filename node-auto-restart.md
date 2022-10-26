# Phala 节点自动重启与升级脚本

鉴于有时上游升级或者其他情况导致节点获取不到最新高度，写了一个简单的自动检测的脚本共大家使用。

运行此脚本即可 [node-auto-restart.sh](./node-auto-restart.sh)

可以自定义检测到节点停更后，多少分钟后重启节点。多少次重启后仍未解决的，更新节点版本。

---

## 使用方法，运行下列命令

下载脚本（已下载的可跳过）

```
wget https://raw.githubusercontent.com/zozyo/phala-guide/main/node-auto-restart.sh -O node-auto-restart.sh
```

添加脚本运行权限
```
sudo chmod +x node-auto-restart.sh
```

运行脚本
```
sudo ./node-auto-restart.sh
```

---

## 重启命令和升级命令，根据不同部署环境命令不同，默认写的 solo 脚本的命令

修改重启命令和升级命令，只需修改脚本文件中后面添加了注释的几行即可

```
#restart commands
function restartNode(){
	echo "检测到卡顿超时！重启节点！" 		#可替换为各种告警脚本命令
	phala stop node 				#停止节点命令，取决于用户部署环境
	phala start 					#启动节点命令，取决于用户部署环境
}

#update commands
function updateNode() {
	echo "重启多次无效！更新节点！" 			#可替换为各种告警脚本命令
	phala stop node 				#停止节点命令，取决于用户部署环境
	docker image rm phalanetwork/khala-node		#移除旧 node 镜像
	docker pull phalanetwork/khala-node		#拉取新 node 镜像
	phala start 					#启动节点命令，取决于用户部署环境
}
```
