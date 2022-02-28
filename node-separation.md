↖目录点这个图标 ⁝☰

# 分离节点教程

在分离操作前，先了解一下 `docker-compose.yml` 的配置原理。

---

## docker-compose.yml 的配置介绍

安装好 `docker-compose` 后，运行 `sudo docker-compose up -d` 会读取当前文件夹下的 `docker-compose.yml` 配置文件和 `.env` 的环境变量文件。

分离的配置文件编辑好后，只需在配置文件存放的文件夹下运行 `sudo docker-compose up -d` 即可启动配置文件内所有服务。

停止服务的命令为

```
sudo docker-compose stop phala-node       #停止节点
sudo docker-compose stop phala-pruntime   #停止挖矿软件 pruntime
sudo docker-compose stop phala-pherry     #停止中转组件 pherry
```

升级配置文件内所有镜像的命令为

```
sudo docker-compose pull    #升级前建议先停止服务
```

查看容器当前运行详细状况的命令为

```
sudo docker-compose top
```

---

下面以官方 solo 脚本的 `docker-compose.yml` 举例说明：

```
version: "3"                                                #指定 docker-compose 版本
services:                                                   #定义服务部分,下面每个服务都是可以单独提出的
 phala-node:                                                #服务名称，可自定义
   image: ${NODE_IMAGE}                                     #服务使用的 docker 镜像，此处 ${NODE_IMAGE} 指从 .env 文件读取的值
   container_name: phala-node                               #容器名称，可自定义
   hostname: phala-node                                     #容器对外的 DNS 解析名称
   ports:                                                   #容器对外映射的端口列表
    - "9933:9933"                                           #左边为主机的端口，右边为容器内的端口。以冒号分隔
    - "9934:9934"
    - "9944:9944"
    - "9945:9945"
    - "30333:30333"
    - "30334:30334"
   environment:                                             #启动容器时的环境变量列表
    - NODE_NAME=${NODE_NAME}
    - NODE_ROLE=MINER
   volumes:                                                 #启动容器时挂载的目录
    - ${NODE_VOLUMES}                                       #左边为主机的目录，右边为容器内的目录。以冒号分隔

 phala-pruntime:
   image: ${PRUNTIME_IMAGE}
   container_name: phala-pruntime
   hostname: phala-pruntime
   ports:
    - "8000:8000"
   devices:                                                 #设备映射列表，此处为 pruntime 所使用的 SGX 设备
    - /dev/sgx/enclave                                      #通常报错是因为此处为空或者设备没装好驱动
    - /dev/sgx/provision                                    #可以使用命令 find /dev/ -maxdepth 2 | grep sgx 来查看当前安装的 SGX 设备
    - /dev/sgx_enclave                                      #并将这些设备填入此处，例如    - /dev/isgx, 注意缩进。
    - /dev/sgx_provision                                    #注意上述 find 命令如果获取到 /dev/sgx 则忽略，这是一个文件夹。
   environment:
    - EXTRA_OPTS=--cores=${CORES}                           #pruntime 运行的核心数量，在 .env 中读取 CORES 的值
    - ROCKET_ADDRESS=0.0.0.0
   volumes:
    - ${PRUNTIME_VOLUMES}

 phala-pherry:
   image: ${PHERRY_IMAGE}
   container_name: phala-pherry
   hostname: phala-pherry
   depends_on:                                              #容器的依赖项，会等待下列容器启动完成后再启动。
    - phala-node                                            #分离节点时候需要删除 phala-node 这行
    - phala-pruntime
   restart: always                                          #在容器退出时总是重启容器
   entrypoint:                                              #指定接入点列表
    [
      "/root/pherry",
      "-r",
      "--parachain",
      "--mnemonic=${MNEMONIC}",                             #读取 .env 中 MNEMONIC 的值，此为 GAS 账号助记词
      "--substrate-ws-endpoint=ws://phala-node:9945",       #此为 kusama 链节点地址，分离时需要修改此处
      "--collator-ws-endpoint=ws://phala-node:9944",        #此为 khala 链节点地址，分离时需要修改此处
      "--pruntime-endpoint=http://phala-pruntime:8000",     #此为 pruntime 地址，如果 pherry 也在设备上，就保持不变
      "--operator=${OPERATOR}",                             #读取 .env 中 OPERATOR 的值，此为 Pool 创建账号的账户地址
      "--fetch-blocks=512",                                 #同步时每次请求 512 个区块
      "--auto-restart"
    ]
```

---

## 将节点分离到节点机，示例中节点机不运行挖矿，因此不需要 SGX 支持

### 节点机需要执行的环境部署命令（这里使用清华镜像源下载docker）

```
sudo apt-get install jq curl wget unzip zip dkms -y

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository "deb [arch=amd64] https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/ubuntu $(lsb_release -cs) stable"

sudo apt-get install -y docker-ce docker-ce-cli containerd.io

sudo usermod -aG docker $USER
```

*鉴于国内网络环境, docker-compose 可能会下载失败，建议使用代理执行下面的命令*

```
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose
```

验证是否成功安装 docker-compose

```
sudo docker-compose -v

如果成功安装，则应该得到如下的返回

docker-compose version 1.29.2, build 5becea4c
```

### 节点机的 `docker-compose.yml` 示例

```
version: "3"
services:
 phala-node:
   image: ${NODE_IMAGE}
   container_name: phala-node
   hostname: phala-node
   ports:
    - "9933:9933"
    - "9934:9934"
    - "9944:9944"
    - "9945:9945"
    - "30333:30333"
    - "30334:30334"
   environment:
    - NODE_NAME=${NODE_NAME}
    - NODE_ROLE=MINER
   volumes:
    - ${NODE_VOLUMES}
```

### 节点机的 `.env` 示例
```
NODE_IMAGE=phalanetwork/khala-node
NODE_VOLUMES=/var/khala-dev-node:/root/data
NODE_NAME=khala_node
```

这里 `NODE_VOLUMES` 的 `/var/khala-dev-node` 为主机的保存节点数据的目录，有需要的可自行修改

例如想保存在 `/root/node_data`, 就可以改为 `NODE_VOLUMES=/root/node_data:/root/data`

---

## 将矿机的节点移除，并将 pherry 指向节点机

先正常使用 solo 脚本安装，并配置, 但是先不执行 `sudo phala start`

### 矿机的 `docker-compose.yml` 示例，此示例在矿机上运行 pherry

```
version: "3"
services:
 phala-pruntime:
   image: ${PRUNTIME_IMAGE}
   container_name: phala-pruntime
   hostname: phala-pruntime
   ports:
    - "8000:8000"
   devices:
    - /dev/sgx/enclave
    - /dev/sgx/provision
    - /dev/sgx_enclave
    - /dev/sgx_provision
   environment:
    - EXTRA_OPTS=--cores=${CORES}
    - ROCKET_ADDRESS=0.0.0.0
   volumes:
    - ${PRUNTIME_VOLUMES}

 phala-pherry:
   image: ${PHERRY_IMAGE}
   container_name: phala-pherry
   hostname: phala-pherry
   depends_on:
    - phala-pruntime
   restart: always
   entrypoint:
    [
      "/root/pherry",
      "-r",
      "--parachain",
      "--mnemonic=${MNEMONIC}",
      "--substrate-ws-endpoint=ws://${NODE_IP}:9945",
      "--collator-ws-endpoint=ws://${NODE_IP}:9944",
      "--pruntime-endpoint=http://phala-pruntime:8000",
      "--operator=${OPERATOR}",
      "--fetch-blocks=512",
      "--auto-restart"
    ]
```

### 矿机的 `.env` 示例，此示例的节点 IP 地址为 10.1.1.1

```
PRUNTIME_IMAGE=phalanetwork/phala-pruntime
PHERRY_IMAGE=phalanetwork/phala-pherry
PRUNTIME_VOLUMES=/var/khala-pruntime-data:/root/data
CORES=4
MNEMONIC=xxxx xxxx xxxx
OPERATOR=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
NODE_IP=10.1.1.1
```

这里 `PRUNTIME_VOLUMES` 的 `/var/khala-pruntime-data` 为矿机的保存矿机**运行快照**和**公钥**的目录。建议备份此目录文件。

也可参照节点机修改保存目录的方式更改目录。

`CORES` 为想要使用的核心数量，`MNEMONIC` 为 GAS 费账号助记词，`OPERATOR` 为 POOL 创建者的账号地址。

---

## 将矿机与 pherry 分别部署

矿机上先正常使用 solo 脚本安装，并配置, 但是先不执行 `sudo phala start`

### 矿机的 `docker-compose.yml` 示例，此示例在矿机上只运行 pruntime

```
version: "3"
services:
 phala-pruntime:
   image: ${PRUNTIME_IMAGE}
   container_name: phala-pruntime
   hostname: phala-pruntime
   ports:
    - "8000:8000"
   devices:
    - /dev/sgx/enclave
    - /dev/sgx/provision
    - /dev/sgx_enclave
    - /dev/sgx_provision
   environment:
    - EXTRA_OPTS=--cores=${CORES}
    - ROCKET_ADDRESS=0.0.0.0
   volumes:
    - ${PRUNTIME_VOLUMES}
```

### 矿机的 `.env` 示例

```
PRUNTIME_IMAGE=phalanetwork/phala-pruntime
PRUNTIME_VOLUMES=/var/khala-pruntime-data:/root/data
CORES=4
```

`CORES` 为想要使用的核心数量

***注意！运行 pherry 设备也需要执行和节点机一样的环境部署命令***

### 运行 pherry 设备的 `docker-compose.yml` 示例

```
version: "3"
services:
 phala-pherry:
   image: ${PHERRY_IMAGE}
   container_name: phala-pherry
   hostname: phala-pherry
   restart: always
   entrypoint:
    [
      "/root/pherry",
      "-r",
      "--parachain",
      "--mnemonic=${MNEMONIC}",
      "--substrate-ws-endpoint=ws://${NODE_IP}:9945",
      "--collator-ws-endpoint=ws://${NODE_IP}:9944",
      "--pruntime-endpoint=http://${MINER_IP}:8000",
      "--operator=${OPERATOR}",
      "--fetch-blocks=512",
      "--auto-restart"
    ]
```

### 运行 pherry 设备的 `.env` 示例，此示例的节点 IP 地址为 10.1.1.1, 矿机 IP 地址为 10.2.2.2

```
PHERRY_IMAGE=phalanetwork/phala-pherry
MNEMONIC=xxxx xxxx xxxx
OPERATOR=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
NODE_IP=10.1.1.1
MINER_IP=10.2.2.2
```

`MNEMONIC` 为 GAS 费账号助记词，`OPERATOR` 为 POOL 创建者的账号地址。
