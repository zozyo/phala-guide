require('dotenv').config();
const { ApiPromise, WsProvider } = require('@polkadot/api');

const typedefs = require('@phala/typedefs').khala;

async function useApi() {
    const wsProvider = new WsProvider('wss://khala.api.onfinality.io/public-ws');
    const api = await ApiPromise.create({
        provider: wsProvider, types: {
            ...typedefs,
            NftAttr: {
                shares: "Balance",
            },
        }
    });
    return api;
}

async function main() {
    const args = process.argv.slice(2)
	const api = await useApi();

	poolInfo = (await api.query.phalaBasePool.pools(args[0])).toJSON();
	poolPid = poolInfo.stakePool.basepool.pid;
	poolCid = poolInfo.stakePool.basepool.cid;
	poolFreeId = poolInfo.stakePool.basepool.poolAccountId;
	poolTotal = BigInt(poolInfo.stakePool.basepool.totalValue);
	poolShare = BigInt(poolInfo.stakePool.basepool.totalShares);
	poolWithdrawQueue = poolInfo.stakePool.basepool.withdrawQueue;

	poolFree = (await api.query.assets.account(10000,poolFreeId)).toJSON();

	if ( poolFree != null ) {
		poolFree = BigInt(poolFree.balance)
	} else { poolFree = 0 };

	var withdrawSum = BigInt(0);
	for(var i = 0; i < poolWithdrawQueue.length; i++) {
		poolNftId = poolWithdrawQueue[i].nftId;
		userNft = (await api.query.rmrkCore.properties(poolCid, poolNftId, "stake-info")).unwrap().toHex();
	    userNftAmount = BigInt((api.createType('NftAttr', userNft)).toJSON().shares);
		withdrawSum = withdrawSum + userNftAmount;
	}

	var withdrawSumV = BigInt( withdrawSum * poolTotal / poolShare )

	const pool =
	{
		"pid": poolPid.toString(),
		"cid": poolCid.toString(),
		"totalValue": poolTotal.toString(),
		"totalShares": poolShare.toString(),
		"freeValue": poolFree.toString(),
		"withdrawValue": withdrawSumV.toString()
	}

	console.log(JSON.stringify(pool));

}

main().catch(console.error).finally(() => process.exit());
