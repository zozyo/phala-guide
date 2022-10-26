# Phala 矿池监控脚本

方便大家监控自己矿池的质押情况，写了个简单的脚本。

此脚本依赖官方的 console.js，需要安装过 node

[stakePool-mon.sh](./stakePool-mon.sh)

请自行更改脚本开头的矿池编号与node地址，node地址默认使用本地。

有部署过告警机器人的，请自行替换脚本中的告警命令。

---

## 使用方法，运行下列命令

下载脚本（已下载的可跳过）

```
wget https://raw.githubusercontent.com/Phala-Network/solo-mining-scripts/main/tools/console.js -O console.js
wget https://raw.githubusercontent.com/zozyo/phala-guide/main/stakePool-mon.sh -O stakePool-mon.sh
```

添加脚本运行权限
```
sudo chmod +x stakePool-mon.sh
```

运行脚本
```
sudo ./stakePool-mon.sh
```

---
