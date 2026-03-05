// // Server/blockchain/blockchain.service.js

const { ethers } = require("ethers");
const fs = require("fs");
const path = require("path");
const express = require("express");

const router = express.Router();

const abiPath = path.join(__dirname, "AppEventLog.json");
if (!fs.existsSync(abiPath)) {
  throw new Error(`❌ ABI file not found at: ${abiPath}`);
}
const artifact = JSON.parse(fs.readFileSync(abiPath, "utf8"));
const abi = artifact.abi;
const contractAddress = process.env.CONTRACT_ADDRESS;

// ✨ FIX 1: Define a variable to hold the shared contract instance.
let sharedContractInstance;

function initializeBlockchain(io) {
  console.log("🔧 Initializing Blockchain Service...");

  // ... (Provider & Wallet Setup is the same)
  if (!process.env.AMOY_RPC || !process.env.PRIVATE_KEY) {
    throw new Error("❌ Missing AMOY_RPC or PRIVATE_KEY in .env");
  }
  if (!contractAddress || !ethers.isAddress(contractAddress)) {
    throw new Error("❌ Missing or invalid CONTRACT_ADDRESS in .env");
  }
  const wssUrl = process.env.AMOY_WSS;
  let provider;
  if (wssUrl) {
    console.log("✅ Connecting via WebSocket for real-time events...");
    provider = new ethers.WebSocketProvider(wssUrl, { name: "polygon-amoy", chainId: 80002 });
  } else {
    console.warn("ℹ️ AMOY_WSS not set; falling back to HTTP polling for events.");
    provider = new ethers.JsonRpcProvider(process.env.AMOY_RPC, { name: "polygon-amoy", chainId: 80002 });
  }
  const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

  // ✨ FIX 2: Assign the created contract to our shared variable.
  sharedContractInstance = new ethers.Contract(contractAddress, abi, wallet);

  // --- Event Listener Logic (no changes here) ---
  function handleAppEvent(event_type, user_type, uuid, metadata, timestamp, evt) {
    console.log("📢 New Blockchain Event Received:");
    const eventData = {
      eventType: event_type,
      userType: user_type,
      uuid: uuid,
      metadata: metadata,
      timestamp: new Date(Number(timestamp) * 1000).toISOString(),
      txHash: evt.transactionHash,
      blockNumber: evt.blockNumber,
    };
    console.log(eventData);
    io.emit("blockchain-event", eventData);
  }

  sharedContractInstance.on("AppEvent", handleAppEvent);
  console.log("✅ Event listener for 'AppEvent' is active.");
  
  if (provider.on) {
    provider.on("error", (e) => console.error("🚨 WebSocket provider error:", e));
    //provider.on("close", (code, reason) => console.warn(`WebSocket closed: ${code} - ${reason}`));
  }
  
  // No need to return anything anymore, as the instance is shared.
}

// ✨ FIX 3: The getContract function is now much simpler.
function getContract() {
  if (!sharedContractInstance) {
     throw new Error("Blockchain service has not been initialized yet!");
  }
  return sharedContractInstance;
}

// --- API Endpoints (no changes needed in the route handlers themselves) ---
router.post("/log", async (req, res) => {
  try {
    const { event_type = "UNKNOWN_EVENT", user_type = "UNKNOWN_USER", uuid = "", metadata = "" } = req.body || {};
    const contract = getContract();
    const tx = await contract.log(event_type, user_type, uuid, metadata);
    const receipt = await tx.wait();
    res.json({ ok: true, txHash: tx.hash, blockNumber: receipt.blockNumber, explorer: `https://amoy.polygonscan.com/tx/${tx.hash}` });
  } catch (err) {
    console.error("❌ Error in /log:", err);
    res.status(500).json({ ok: false, error: err.message });
  }
});

router.get("/total", async (_req, res) => {
  try {
    const contract = getContract();
    const total = await contract.total();
    res.json({ ok: true, total: Number(total) });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

module.exports = { initializeBlockchain, blockchainRouter: router };