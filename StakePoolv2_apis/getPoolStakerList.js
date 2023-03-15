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

	//Query pool cid
	poolCid = (await api.query.phalaBasePool.pools(args[0])).toJSON().stakePool.basepool.cid;

	//Query raw staker list
	const nftEntries = (await api.query.rmrkCore.nfts.entries(poolCid))

	//Analyze raw staker list
	const poolNfts = nftEntries.map(([key, value]) => {
		const cid = key.args[0].toNumber()
		const nftId = key.args[1].toNumber()
		const owner = value.unwrap().owner.asAccountId.toString()
		return { cid, nftId, owner }
	})

	//Traverse and Query the share of each staker
	let poolStakerList = []

	for (let i = 0; i < poolNfts.length; i++) {
		userNft = (await api.query.rmrkCore.properties(poolCid, poolNfts[i].nftId, "stake-info")).unwrap().toHex();
		const userNftShare = BigInt((api.createType('NftAttr', userNft)).toJSON().shares).toString();

		const poolStaker =
		{
			"cid": poolNfts[i].cid,
			"nftId": poolNfts[i].nftId,
			"owner": poolNfts[i].owner,
			"share": userNftShare
		}
		//Only show stakers with share > 0
		if ( poolStaker.share != "0" ) poolStakerList.push(poolStaker)
	}

	console.log(JSON.stringify(poolStakerList))
}

main().catch(console.error).finally(() => process.exit());
