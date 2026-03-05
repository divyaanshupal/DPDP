const express = require('express');
const router = express.Router();
const DocumentTransaction = require('../Models/DocumentTransaction');

// Get all transactions for a user
router.get('/:uuid', async (req, res) => {
  try {
    const { uuid } = req.params;
    const { type, status, limit = 100 } = req.query;
    
    let query = {};
    
    if (type === 'sent') {
      query.senderUuid = uuid;
    } else if (type === 'received') {
      query.receiverUuid = uuid;
    } else {
      // Both sent and received
      query.$or = [
        { senderUuid: uuid },
        { receiverUuid: uuid }
      ];
    }
    
    if (status) {
      query.status = status;
    }
    
    const transactions = await DocumentTransaction.find(query)
      .sort({ createdAt: -1 })
      .limit(parseInt(limit));
    
    res.json(transactions);
  } catch (error) {
    console.error(`❌ [ERROR] Failed to fetch transactions:`, error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;

