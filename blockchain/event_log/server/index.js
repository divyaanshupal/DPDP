// index.js inside blockchain/event_log/server

const { ethers } = require("ethers");
const fs = require("fs");
const path = require("path");
const express = require("express");

const dotenv = require("dotenv");

dotenv.config({ path: path.join(__dirname, ".env") });

const router = express.Router();

// ✅ Load ABI
const abiPath = path.join(__dirname, "AppEventLog.json");
if (!fs.existsSync(abiPath)) {
  throw new Error(`❌ ABI file not found at: ${abiPath}`);
}

const artifact = JSON.parse(fs.readFileSync(abiPath, "utf8"));
const abi = artifact.abi;
const contractAddress = process.env.CONTRACT_ADDRESS;

// ✅ Provider & Wallet
if (!process.env.AMOY_RPC || !process.env.PRIVATE_KEY) {
  throw new Error("❌ Missing AMOY_RPC or PRIVATE_KEY in .env");
}
if (!contractAddress || !ethers.isAddress(contractAddress)) {
  throw new Error("❌ Missing or invalid CONTRACT_ADDRESS in .env");
}

const wssUrl = process.env.AMOY_WSS;
let provider;
if (wssUrl) {
  provider = new ethers.WebSocketProvider(wssUrl, {
    name: "polygon-amoy",
    chainId: 80002,
  });
} else {
  provider = new ethers.JsonRpcProvider(process.env.AMOY_RPC, {
    name: "polygon-amoy",
    chainId: 80002,
  });
  provider.pollingInterval = 10000;
}

const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
const contract = new ethers.Contract(contractAddress, abi, wallet);

// ------------------ APIs ------------------
router.get("/", (_req, res) => {
  res.send("✅ Blockchain API is running.");
});

router.post("/log", async (req, res) => {
  try {
    const {
      event_type = "UNKNOWN_EVENT",
      user_type = "UNKNOWN_USER",
      uuid = "",
      metadata = "",
    } = req.body || {};

    const tx = await contract.log(event_type, user_type, uuid, metadata);
    const receipt = await tx.wait();

    res.json({
      ok: true,
      txHash: tx.hash,
      blockNumber: receipt.blockNumber,
      explorer: `https://amoy.polygonscan.com/tx/${tx.hash}`,
    });
  } catch (err) {
    console.error("❌ Error in /log:", err);
    res.status(500).json({ ok: false, error: err.message });
  }
});

router.get("/total", async (_req, res) => {
  try {
    const total = await contract.total();
    res.json({ ok: true, total: Number(total) });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

router.get("/events", async (_req, res) => {
  try {
    const filter = contract.filters.AppEvent();
    const events = await contract.queryFilter(filter, 0, "latest");
    const formatted = events.map((e) => ({
      txHash: e.transactionHash,
      block: e.blockNumber,
      tag: e.args[0],
      user: e.args[1],
      timestamp: new Date(Number(e.args[2]) * 1000).toISOString(),
    }));
    res.json({ ok: true, events: formatted });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

// ------------------ Listener Logic ------------------
function handleAppEvent(tag, user, timestamp, evt) {
  console.log("📢 New Event:");
  console.log("  Tag:", tag);
  console.log("  User:", user);
  console.log("  Time:", new Date(Number(timestamp) * 1000).toISOString());
  console.log("  Tx:", evt.transactionHash);
}

async function startPollingEvents() {
  try {
    let lastBlock = await provider.getBlockNumber();
    setInterval(async () => {
      try {
        const latest = await provider.getBlockNumber();
        if (latest <= lastBlock) return;

        const filter = contract.filters.AppEvent();
        const events = await contract.queryFilter(
          filter,
          lastBlock + 1,
          latest
        );
        for (const e of events) {
          handleAppEvent(e.args[0], e.args[1], e.args[2], e);
        }
        lastBlock = latest;
      } catch (err) {
        const msg = err?.message || "";
        if (/(filter not found)/i.test(msg) || err?.code === -32000) {
          return; // benign, will retry
        }
        console.error("@TODO Error while polling events:", err);
      }
    }, 10000);
  } catch (err) {
    console.error("@TODO Failed to start event polling:", err);
  }
}

// Auto-start listeners when module loads
if (wssUrl) {
  contract.on("AppEvent", handleAppEvent);
  if (provider.on) {
    provider.on("error", (e) => console.error("WebSocket provider error:", e));
    provider.on("close", () => console.warn("WebSocket provider closed"));
  }
} else {
  console.warn("ℹ️ AMOY_WSS not set; falling back to HTTP polling for events");
  startPollingEvents();
}

module.exports = router;
