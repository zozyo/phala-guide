pid=2000
ENDPOINT="ws://127.0.0.1:9944"

function alertStakeChange(){
	#replace with any alert commands
	echo "池$1：质押变化量：$2，当前闲置量：$3，总质押量：$4"
}

function alertWithdrawSum(){
	#replace with any alert commands
	echo "池$1：提质押等待总额：$2"
}

function waitMinute(){
	for i in `seq 60 -1 1`; do
		echo -ne "--- ${i}s 刷新 ---\r"
		sleep 1
	done
}

function numeric(){
    declare input=${1:-$(</dev/stdin)};
    echo $(echo $input | sed 's/,//g' | awk '{printf ("%.2f\n",$1/1000000000000)}')
}

function getWithdrawSum(){
	queue=$*

	#get queue length
	queueLength=$(echo $queue | jq '.|length' | awk '{print $1-1}')

	#get queue shares each
    for p in `seq 0 $queueLength`; do
        shares[$p]=$(echo $withdrawQueue | jq -r ".[$p].shares" | numeric)
    done

	#get sum
    sum=0
    for each in ${shares[*]}; do
        sum=`echo "$sum + $each" | bc`
    done

	#return queue share sum
	echo $sum
}

lastStake=0

while true; do
	#get stake pool info from node
	stakePool=$(node console.js --substrate-ws-endpoint $ENDPOINT chain stake-pool $pid 2>/dev/null)

	#replace single quotes with double quotes
	stakePool_e=$(echo $stakePool | sed "s/'/@/g" | sed 's/@/"/g')

	#if get info failed
	if [[ -z $stakePool_e ]]; then
		waitMinute
		continue
	fi

	#filter
	withdrawQueue=$(jq -rn "$stakePool_e | .withdrawQueue")
	totalStake=$(jq -rn "$stakePool_e | .totalStake" | numeric)
	freeStake=$(jq -rn "$stakePool_e | .freeStake" | numeric)

	#if stake changed
	if [ "$totalStake" != "$lastStake" ]; then
		changeStake=$(echo "$totalStake - $lastStake" | bc)
		lastStake=$totalStake

		#send alert msg
		alertStakeChange $pid $changeStake $freeStake $totalStake
	fi

	#if has withdrawQueue
	if [ "$withdrawQueue" != "[]" -a "$withdrawQueue" != "$withdrawQueue_last" ]; then
		withdrawSum=$(getWithdrawSum $withdrawQueue)
		alertWithdrawSum $pid $withdrawSum
	fi

	withdrawQueue_last=$withdrawQueue

	#loop 60s
	waitMinute
done
