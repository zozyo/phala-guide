#!/bin/bash
trap "echo '===备份已中止！==='; exit" 2

if [ $(id -u) -ne 0 ]; then
	echo "请使用sudo运行!"
	exit 1
fi

read -p "输入启动 node 的 docker-compose.yml 所在文件夹路径: " yml_dir
read -p "输入 node 的数据文件所在文件夹路径: " node_path
read -p "输入 node 的数据文件夹名称: " node_dir
read -p "输入保存快照文件的所在文件夹路径（请确保磁盘空间足够！）: " pathz

node_space_usage=$(du -d 0 -BG $node_path/$node_dir | sed 's/\t/ /g' | cut -d' ' -f1)
while true ; do
	read -p "节点数据已使用 $node_space_usage，请确保快照文件所在磁盘空闲空间大于此值！[Y/n]: " yn
	case $yn in
		[Yy]* ) echo "===准备开始备份！==="; break;;
		[Nn]* ) echo "备份已中止！"; exit 1;;
		* ) ;;
	esac
done

ip="127.0.0.1"

dateToday=$(date +%F)
res=$(curl -sH "Content-Type: application/json" -d '{"id":1, "jsonrpc":"2.0", "method": "system_syncState", "params":[]}' http://${ip}:9933)
node_block=$(echo ${res} | jq '.result.currentBlock')
res2=$(curl -sH "Content-Type: application/json" -d '{"id":1, "jsonrpc":"2.0", "method": "system_syncState", "params":[]}' http://${ip}:9934)
node_block2=$(echo ${res2} | jq '.result.currentBlock')

echo "===今日日期 ${dateToday} ==="
echo "===khala 高度 ${node_block} ==="
echo "===kusama 高度 ${node_block2} ==="
echo "===停止节点==="
docker container rm --force phala-node
echo "===开始压缩，此步骤无显示，请耐心等待==="
mkdir -p ${pathz}/khala-kusama-snapshot-${dateToday}-${node_block}-${node_block2}
cd $node_path
tar --use-compress-program=pigz -cf ${pathz}/khala-kusama-snapshot-${dateToday}-${node_block}-${node_block2}/khala-snapshot-${dateToday}-${node_block}.tar.gz --exclude=khala-dev-node/chains/khala/keystore --exclude=khala-dev-node/chains/khala/network --exclude=khala-dev-node/polkadot $node_dir
tar --use-compress-program=pigz -cf ${pathz}/khala-kusama-snapshot-${dateToday}-${node_block}-${node_block2}/kusama-snapshot-${dateToday}-${node_block2}.tar.gz --exclude=khala-dev-node/chains --exclude=khala-dev-node/polkadot/chains/ksmcc3/keystore --exclude=khala-dev-node/polkadot/chains/ksmcc3/network $node_dir
echo "===压缩完成==="
echo "===启动节点==="
cd $yml_dir
docker-compose up -d
