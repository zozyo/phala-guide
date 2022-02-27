node_ip="127.0.0.1"
pruntime_ip="127.0.0.1"

function isSynced(){
	if [ $1 = "false" ]; then
                echo "\E[1;32m已同步\E[0m"
        else
                echo "同步中"
        fi
}

function get_node_info(){
	#get_node_version
	node_system_version=$(curl -sH "Content-Type: application/json" -d '{"id":1, "jsonrpc":"2.0", "method": "system_version", "params":[]}' http://${node_ip}:9933 | jq '.result'  | tr -d '"' | cut -d'-' -f1)
	if [ -z $node_system_version ]; then echo "节点未响应！"; exit 2; fi
	#get_khala_info
	node_khala_system_health=$(curl -sH "Content-Type: application/json" -d '{"id":1, "jsonrpc":"2.0", "method": "system_health", "params":[]}' http://${node_ip}:9933 | jq '.result')
	node_khala_system_health_isSyncing=$(echo $node_khala_system_health | jq '.isSyncing')
	node_khala_system_health_peers=$(echo $node_khala_system_health | jq '.peers')
	node_khala_system_syncState=$(curl -sH "Content-Type: application/json" -d '{"id":1, "jsonrpc":"2.0", "method": "system_syncState", "params":[]}' http://${node_ip}:9933 | jq '.result')
	node_khala_system_syncState_currentBlock=$(echo $node_khala_system_syncState | jq '.currentBlock')
	node_khala_system_syncState_highestBlock=$(echo $node_khala_system_syncState | jq '.highestBlock')
	node_khala_diff=$(expr $node_khala_system_syncState_highestBlock - $node_khala_system_syncState_currentBlock)
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
----------------------------------------------------------------------
" $node_system_version $node_khala_system_syncState_currentBlock $node_khala_system_syncState_highestBlock $node_khala_system_health_peers $node_kusama_system_syncState_currentBlock $node_kusama_system_syncState_highestBlock $node_kusama_system_health_peers
}

function get_pruntime_info(){
	#get pruntime info
	pruntime_rpc_get_info=$(curl -X POST -sH "Content-Type: application/json" -d '{"input": {}, "nonce": {}}' http://${pruntime_ip}:8000/get_info)
	if [ -z $pruntime_rpc_get_info ]; then echo "pruntime 设备未响应！"; exit 3; fi
	pruntime_info=$(echo $pruntime_rpc_get_info | jq '.payload|fromjson')
	pruntime_info_blocknum=$(echo $pruntime_info | jq '.blocknum')
	pruntime_info_headernum=$(echo $pruntime_info | jq '.headernum')
	pruntime_info_para_headernum=$(echo $pruntime_info | jq '.para_headernum')
	pruntime_info_public_key=$(echo $pruntime_info | jq '.public_key' | sed 's/\"//g' | sed 's/^/0x/')
	pruntime_info_registered=$(echo $pruntime_info | jq '.registered')
	pruntime_info_score=$(echo $pruntime_info | jq '.score')
	pruntime_info_version=$(echo $pruntime_info | jq '.version' | sed 's/\"//g')
	if [ $pruntime_info_registered = "true" ]; then
		pruntime_registered="\E[1;32m已注册\E[0m"
	else
		pruntime_registered="未注册"
	fi
	#get pruntime ip length
	pruntime_ip_length=${#pruntime_ip}
	hyphen=""
	for i in `seq 0 $pruntime_ip_length`; do hyphen="-$hyphen"; done
	#print info
	printf "
--$hyphen--
  $pruntime_ip  |
-----------------------------------------------------------------------------------------------
  运行时版本   |  已同步的 khala 链高度   |  目标的 khala 链高度   |  已同步的 kusama 链高度  |
-----------------------------------------------------------------------------------------------
  %-10s   |  %-23s |  %-21s |   %-22s |
-----------------------------------------------------------------------------------------------
  链上注册情况 | 评分 |                              设备公钥                                 |
-----------------------------------------------------------------------------------------------
  $pruntime_registered       | %-4s |  %-64s   |
-----------------------------------------------------------------------------------------------
" $pruntime_info_version $pruntime_info_blocknum $pruntime_info_para_headernum $pruntime_info_headernum $pruntime_info_score $pruntime_info_public_key
}

main(){
	trap "clear;exit" 2

	local is_monitor_node=0
	local is_monitor_pruntime=0

	while true ; do
		read -p "是否监控节点状态?[Y/n]: " yn
		case $yn in
			[Yy]* ) is_monitor_node=1; break;;
			[Nn]* ) is_monitor_node=0; break;;
			* ) ;;
		esac
	done

	if [ $is_monitor_node -eq 1 ]; then
		read -p "输入节点机IP (直接回车默认本机): " node_ip
		if [ -z $node_ip ]; then node_ip="127.0.0.1"; fi
	fi

	while true ; do
		read -p "是否监控 pruntime 状态?[Y/n]: " yn
		case $yn in
			[Yy]* ) is_monitor_pruntime=1; break;;
			[Nn]* ) is_monitor_pruntime=0; break;;
			* ) ;;
		esac
	done

	if [ $is_monitor_pruntime -eq 1 ]; then
		read -p "输入 pruntime 机 IP (直接回车默认本机): " pruntime_ip
		if [ -z $pruntime_ip ]; then pruntime_ip="127.0.0.1"; fi
	fi

	while true; do
		clear
		if [ $is_monitor_node -eq 1 ]; then get_node_info; fi
		if [ $is_monitor_pruntime -eq 1 ]; then get_pruntime_info; fi
		#if not monitor anything, exit
		if [ $is_monitor_node -eq 0 -a $is_monitor_pruntime -eq 0 ]; then exit 1; fi
		#refresh every 60s
		echo ""
		for i in `seq 60 -1 1`
		do
			echo -ne "-------------------------   ${i}s刷新   --------------------------------\r"
			sleep 1
		done
	done
}

main
