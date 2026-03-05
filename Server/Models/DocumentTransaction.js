const mongoose = require('mongoose');

const documentRequestSchema = new mongoose.Schema({
  name: { type: String, required: true },
  fileType: { type: String, required: true },
  requestType: { type: String, enum: ['view', 'download'], default: 'view' }
}, { _id: false });

const transactionSchema = new mongoose.Schema({
  // Who sent the request
  senderUuid: {
    type: String,
    required: true,
    index: true
  },
  senderName: {
    type: String,
    required: true
  },
  
  // Who received the request
  receiverUuid: {
    type: String,
    required: true,
    index: true
  },
  receiverName: {
    type: String,
    required: true
  },
  
  // Request details
  requestedDocuments: [documentRequestSchema],
  note: String,
  expirationDays: { type: Number, default: 7 },
  
  // Status tracking
  status: {
    type: String,
    enum: ['pending', 'accepted', 'rejected', 'completed', 'expired'],
    default: 'pending',
    index: true
  },
  
  // Transfer completion tracking
  documentsReceived: [{
    name: String,
    fileType: String,
    receivedAt: Date,
    requestType: String
  }],
  totalDocumentsRequested: { type: Number, default: 0 },
  documentsReceivedCount: { type: Number, default: 0 },
  
  // Timestamps
  requestedAt: { type: Date, default: Date.now },
  respondedAt: Date, // When accepted/rejected
  completedAt: Date, // When all documents received
  
  // Expiration
  expiresAt: Date
  
}, { timestamps: true });

// Indexes for efficient queries
transactionSchema.index({ senderUuid: 1, createdAt: -1 });
transactionSchema.index({ receiverUuid: 1, createdAt: -1 });
transactionSchema.index({ status: 1 });
transactionSchema.index({ senderUuid: 1, receiverUuid: 1, status: 1 });

module.exports = mongoose.model('DocumentTransaction', transactionSchema);

