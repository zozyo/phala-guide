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

	const poolCid = (await api.query.phalaBasePool.pools(args[0])).toJSON().stakePool.basepool.cid;
	const nftEntries = (await api.query.uniques.account.entries(args[1],poolCid))

	let nftId
	const poolNfts = nftEntries.map(([key, value]) => {
		nftId = key.args[2].toNumber()
	})

	userNft = (await api.query.rmrkCore.properties(poolCid, nftId, "stake-info")).unwrap().toHex();
	const userNftAmount = BigInt((api.createType('NftAttr', userNft)).toJSON().shares).toString();

	console.log(userNftAmount);
}

main().catch(console.error).finally(() => process.exit());
