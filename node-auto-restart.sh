#!/bin/bash

function isSynced(){
	if [ -z $1 ]; then
		echo "未启动"
	elif [ -n $1 -o $1 = "false" ]; then
		echo "\E[1;32m已同步\E[0m"
	else
		echo "同步中"
	fi
}

#need sudo
if [ $(id -u) -ne 0 ]; then
	echo "请使用sudo运行!"
	exit 1
fi

#need jq
if ! type jq > /dev/null; then
	apt-get install -y jq
fi

#var
node_ip="127.0.0.1"
khala_block_last_check=0
kusama_block_last_check=0
node_stuck_count=0
restart_count=0

#reads var
read -p "检测区块未增加几分钟后重启？ (直接回车默认5分)" stuck_times
if [ -z $stuck_times ]; then stuck_times=5; fi

read -p "重启几次后未解决，更新节点？ (直接回车默认3次)" restart_times
if [ -z $restart_times ]; then restart_times=3; fi

while true; do
	#get_node_version
	node_system_version=$(curl -sH "Content-Type: application/json" -d '{"id":1, "jsonrpc":"2.0", "method": "system_version", "params":[]}' http://${node_ip}:9933 | jq '.result'  | tr -d '"' | cut -d'-' -f1)
	if [ -z $node_system_version ]; then node_system_version="节点未响应"; fi
	#get_khala_info
	node_khala_system_health=$(curl -sH "Content-Type: application/json" -d '{"id":1, "jsonrpc":"2.0", "method": "system_health", "params":[]}' http://${node_ip}:9933 | jq '.result')
	node_khala_system_health_isSyncing=$(echo $node_khala_system_health | jq '.isSyncing')
	node_khala_system_health_peers=$(echo $node_khala_system_health | jq '.peers')
	node_khala_system_syncState=$(curl -sH "Content-Type: application/json" -d '{"id":1, "jsonrpc":"2.0", "method": "system_syncState", "params":[]}' http://${node_ip}:9933 | jq '.result')
	node_khala_system_syncState_currentBlock=$(echo $node_khala_system_syncState | jq '.currentBlock')
	node_khala_system_syncState_highestBlock=$(echo $node_khala_system_syncState | jq '.highestBlock')
	node_khala_synced=$(isSynced $node_khala_system_health_isSyncing)

	#get_kusama_info
	node_kusama_system_health=$(curl -sH "Content-Type: application/json" -d '{"id":1, "jsonrpc":"2.0", "method": "system_health", "params":[]}' http://${node_ip}:9934 | jq '.result')
	node_kusama_system_health_isSyncing=$(echo $node_kusama_system_health | jq '.isSyncing')
	node_kusama_system_health_peers=$(echo $node_kusama_system_health | jq '.peers')
	node_kusama_system_syncState=$(curl -sH "Content-Type: application/json" -d '{"id":1, "jsonrpc":"2.0", "method": "system_syncState", "params":[]}' http://${node_ip}:9934 | jq '.result')
	node_kusama_system_syncState_currentBlock=$(echo $node_kusama_system_syncState | jq '.currentBlock')
	node_kusama_system_syncState_highestBlock=$(echo $node_kusama_system_syncState | jq '.highestBlock')
	node_kusama_synced=$(isSynced $node_kusama_system_health_isSyncing)

	#get node ip length
	node_ip_length=${#node_ip}
	hyphen=""
	for i in `seq 0 $node_ip_length`; do hyphen="-$hyphen"; done

	#print info
	printf "
--$hyphen--
  $node_ip  |
----------------------------------------------------------------------
  节点版本  |  khala节点  |  当前高度   |  最高高度   |  对等点数量  |
----------------------------------------------------------------------
  %-8s  |   $node_khala_synced    |  %-10s |  %-10s |   %-10s |
----------------------------------------------------------------------
            |   ksm节点   |  当前高度   |  最高高度   |  对等点数量  |
----------------------------------------------------------------------
            |   $node_kusama_synced    |  %-10s |  %-10s |   %-10s |
----------------------------------------------------------------------" $node_system_version $node_khala_system_syncState_currentBlock $node_khala_system_syncState_highestBlock $node_khala_system_health_peers $node_kusama_system_syncState_currentBlock $node_kusama_system_syncState_highestBlock $node_kusama_system_health_peers

	#if getting info fails
	if [ -z ${node_khala_system_syncState_currentBlock} ]; then
		node_khala_system_syncState_currentBlock=1
		khala_block_last_check=0
	fi

	if [ -z ${node_kusama_system_syncState_currentBlock} ]; then
		node_kusama_system_syncState_currentBlock=1
		kusama_block_last_check=0
	fi

	#compare block value
	khala_diff=`expr $node_khala_system_syncState_currentBlock - $khala_block_last_check`
	kusama_diff=`expr $node_kusama_system_syncState_currentBlock - $kusama_block_last_check`

	#save last check value
	khala_block_last_check=$node_khala_system_syncState_currentBlock
	kusama_block_last_check=$node_kusama_system_syncState_currentBlock

	printf "
---------------------------------
卡顿计数 |  $node_stuck_count  | 重启计数 |  $restart_count  |
"

	#if stuck, increase node_stuck_count
	if [ $khala_diff -lt 1 -o $kusama_diff -lt 1 ]; then
		node_stuck_count=`expr $node_stuck_count + 1`
	else
		node_stuck_count=0
	fi

	#if stuck too long, restart node
	if [ $node_stuck_count -ge $stuck_times ]; then
		echo "检测到卡顿超时！重启节点！" 		#可替换为各种告警脚本命令
		docker restart phala-node
		restart_count=`expr $restart_count + 1`
		node_stuck_count=0
		#waiting 5 mins for node fully restarted
		for i in `seq 300 -1 1`
		do
			echo -ne "--- ${i}s 等待重启完成 ---\r"
			sleep 1
		done
	fi

	#if restart not work, try update node
	if [ $restart_count -ge $restart_times ]; then
		echo "重启多次无效！更新节点！" 		#可替换为各种告警脚本命令
		phala stop node 			#停止节点命令，取决于用户部署环境
		docker image rm phalanetwork/khala-node
		docker pull phalanetwork/khala-node
		phala start 				#启动节点命令，取决于用户部署环境
		restart_count=0
		#waiting 5 mins for node fully restarted
		for i in `seq 300 -1 1`
		do
			echo -ne "--- ${i}s 等待重启完成 ---\r"
			sleep 1
		done
	fi

	#check every 60s
	for i in `seq 60 -1 1`
	do
		echo -ne "--- ${i}s 刷新 ---\r"
		sleep 1
	done
done
