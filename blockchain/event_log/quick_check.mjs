// event_log/quick_check.mjs
import { ethers } from 'ethers';
import fs from 'fs';

const rpc = process.env.AMOY_RPC ?? 'https://rpc-amoy.polygon.technology/';
const address = process.env.CONTRACT_ADDRESS;

const provider = new ethers.JsonRpcProvider(rpc, { chainId: 80002, name: 'polygon-amoy' });
console.log('network:', await provider.getNetwork());
console.log('code:', await provider.getCode(address));

const abi = JSON.parse(fs.readFileSync('server/AppEventLog.json','utf8')).abi; // <- fixed path
const c = new ethers.Contract(address, abi, provider);
console.log('total():', String(await c.total()));