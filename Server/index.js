// server.js
const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const mongoose = require('mongoose');
const cors = require('cors');
const bodyParser = require('body-parser');
require('dotenv').config();

const registerRoute = require('./routes/register.route');
const transactionRoute = require('./routes/transactions.route');
const { initializeBlockchain, blockchainRouter } = require('./blockchain/blockchain.service');

const User = require('./Models/User'); // to fetch UUID validation if needed

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Routes
app.get("/", (req, res) => {
  res.send("Hello world");
});
app.use('/api', registerRoute); // e.g. POST /api/register
app.use('/api/transactions', transactionRoute); // ✨ NEW: Transaction routes
app.use("/blockchain",blockchainRouter);



// MongoDB Connection
mongoose.connect(process.env.MONGO_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true
}).then(() => console.log('✅ MongoDB connected'))
  .catch(err => console.error(err));

// { socketId, uuid }
const connectedUsers = new Map();

io.on('connection', (socket) => {
  console.log(`🔌 [CONNECT] New socket connected: ${socket.id}`);

  // Client should emit 'register-user' right after connecting
  socket.on('register-user', async (data) => {
    console.log(`📥 [EVENT] register-user from socket ${socket.id}, payload:`, data);

    const { uuid } = data;
    if (!uuid) {
      console.log(`⚠️ [ERROR] Missing UUID from socket ${socket.id}`);
      socket.emit('register-error', { message: 'UUID required' });
      return;
    }

    // ✅ optional: validate user exists in DB
    const userExists = await User.exists({ uuid });
    if (!userExists) {
      console.log(`❌ [ERROR] Invalid UUID (${uuid}) from socket ${socket.id}`);
      socket.emit('register-error', { message: 'Invalid UUID' });
      return;
    }

    // Save mapping
    connectedUsers.set(socket.id, { uuid, socketId: socket.id });

    console.log(`👤 [REGISTERED] User ${uuid} mapped to socket ${socket.id}`);
    console.log(`🔍 [DEBUG] Total connected users: ${connectedUsers.size}`);
    console.log(`🔍 [DEBUG] Connected users:`, Array.from(connectedUsers.values()).map(u => u.uuid));

    // Send back confirmation
    socket.emit('registered', { uuid });

    // Send updated user list to all clients
    const usersList = Array.from(connectedUsers.values()).map(user => ({
      uuid: user.uuid,
      socketId: user.socketId
    }));
    io.emit('users-list', usersList);
    console.log(`📡 [BROADCAST] Updated users list sent, total users: ${usersList.length}`);

    // Notify others
    socket.broadcast.emit('user-connected', { uuid, socketId: socket.id });
    console.log(`📣 [NOTIFY] Broadcasted that user ${uuid} connected`);
  });

  // Call request
  socket.on('call-request', async (data) => {
    console.log(`📥 [EVENT] call-request from ${socket.id}, payload:`, data);

    const fromUser = connectedUsers.get(socket.id);
    if (!fromUser) {
      console.log(`⚠️ [ERROR] call-request from unknown socket ${socket.id}`);
      return;
    }

    const targetUuid = data.targetUuid;
    console.log(`🔍 [DEBUG] Looking for target user: ${targetUuid}`);
    console.log(`🔍 [DEBUG] Currently connected users:`, Array.from(connectedUsers.values()).map(u => u.uuid));
    
    const target = Array.from(connectedUsers.values()).find(u => u.uuid === targetUuid);

    if (target) {
      console.log(`📞 [CALL] ${fromUser.uuid} requesting call -> ${target.uuid}`);
      console.log(`🔍 [DEBUG] Target socket ID: ${target.socketId}`);

      // ✨ NEW: Fetch sender's name from database
      let senderName = fromUser.uuid; // fallback to UUID
      let sender = null;
      try {
        sender = await User.findOne({ uuid: fromUser.uuid });
        if (sender && sender.name) {
          senderName = sender.name;
          console.log(`👤 [DEBUG] Found sender name: ${senderName}`);
        } else {
          console.log(`⚠️ [WARNING] Sender name not found for UUID: ${fromUser.uuid}`);
        }
      } catch (error) {
        console.log(`❌ [ERROR] Failed to fetch sender name: ${error.message}`);
      }

      // ✨ NEW: Fetch receiver's name from database
      let receiverName = targetUuid;
      try {
        const receiver = await User.findOne({ uuid: targetUuid });
        if (receiver && receiver.name) {
          receiverName = receiver.name;
          console.log(`👤 [DEBUG] Found receiver name: ${receiverName}`);
        }
      } catch (error) {
        console.log(`❌ [ERROR] Failed to fetch receiver name: ${error.message}`);
      }

      const payload = {
        fromUuid: fromUser.uuid,
        fromName: senderName, // ✨ NEW: Include sender's name
        fromSocketId: socket.id,
        note: data.note,
        requestedDocuments: data.requestedDocuments,
        requestTypes: data.requestTypes || {}, // ✨ NEW: Include request types, default to empty object
        expirationDays: data.expirationDays || 7 // ✨ NEW: Include expiration days, default to 7
      };

      console.log(`📤 [DEBUG] Emitting incoming-call to socket: ${target.socketId}`);
      console.log(`📤 [DEBUG] Payload:`, payload);
      
      io.to(target.socketId).emit('incoming-call', JSON.stringify(payload));
      console.log(`✅ [DEBUG] incoming-call event emitted successfully`);

      // ✨ NEW: Create transaction record
      try {
        const DocumentTransaction = require('./Models/DocumentTransaction');
        const expirationDate = new Date();
        expirationDate.setDate(expirationDate.getDate() + (data.expirationDays || 7));

        // Get document types from sender's documents if available
        const requestedDocsWithTypes = (data.requestedDocuments || []).map((docName) => {
          const doc = sender?.documents?.find(d => d.name === docName);
          return {
            name: docName,
            fileType: doc?.fileType || 'unknown',
            requestType: data.requestTypes?.[docName] || 'view'
          };
        });

        const transaction = await DocumentTransaction.create({
          senderUuid: fromUser.uuid,
          senderName: senderName,
          receiverUuid: targetUuid,
          receiverName: receiverName,
          requestedDocuments: requestedDocsWithTypes,
          note: data.note || null,
          expirationDays: data.expirationDays || 7,
          status: 'pending',
          totalDocumentsRequested: data.requestedDocuments?.length || 0,
          expiresAt: expirationDate
        });

        console.log(`📝 [TRANSACTION] Created transaction ${transaction._id} for ${fromUser.uuid} -> ${targetUuid}`);
      } catch (error) {
        console.error(`❌ [ERROR] Failed to create transaction:`, error);
      }

    } else {
      console.log(`❌ [ERROR] Target ${targetUuid} not found for call-request`);
      console.log(`❌ [ERROR] Available users:`, Array.from(connectedUsers.values()).map(u => u.uuid));
      socket.emit('call-error', { message: 'Target not found or offline' });
    }
  });

  // Call accepted
  socket.on('call-accepted', async (data) => {
    console.log(`📥 [EVENT] call-accepted from ${socket.id}, payload:`, data);

    const callee = connectedUsers.get(socket.id);
    if (!callee) {
      console.log(`⚠️ [ERROR] call-accepted from unknown socket ${socket.id}`);
      return;
    }

    const targetSocketId = data.targetSocketId;
    if (connectedUsers.has(targetSocketId)) {
      const senderUser = connectedUsers.get(targetSocketId);
      
      // ✨ NEW: Fetch user name from database
      try {
        const user = await User.findOne({ uuid: callee.uuid }).select('name');
        const fromName = user?.name || callee.uuid; // Fallback to UUID if name not found
        
        console.log(`✅ [CALL-ACCEPTED] ${callee.uuid} (${fromName}) accepted call with socket ${targetSocketId}`);
        io.to(targetSocketId).emit('call-accepted', {
          fromUuid: callee.uuid,
          fromName: fromName, // ✨ NEW: Include user name
          fromSocketId: socket.id
        });
      } catch (error) {
        console.log(`⚠️ [ERROR] Failed to fetch user name for ${callee.uuid}:`, error);
        // Fallback to UUID if fetch fails
        io.to(targetSocketId).emit('call-accepted', {
          fromUuid: callee.uuid,
          fromName: callee.uuid,
          fromSocketId: socket.id
        });
      }

      // ✨ NEW: Update transaction status
      if (senderUser) {
        try {
          const DocumentTransaction = require('./Models/DocumentTransaction');
          await DocumentTransaction.findOneAndUpdate(
            {
              senderUuid: senderUser.uuid,
              receiverUuid: callee.uuid,
              status: 'pending'
            },
            {
              status: 'accepted',
              respondedAt: new Date()
            },
            { sort: { createdAt: -1 } }
          );
          console.log(`📝 [TRANSACTION] Updated transaction status to 'accepted'`);
        } catch (error) {
          console.error(`❌ [ERROR] Failed to update transaction:`, error);
        }
      }
    }
  });

  // Call rejected
  socket.on('call-rejected', async (data) => {
    console.log(`📥 [EVENT] call-rejected from ${socket.id}, payload:`, data);

    const callee = connectedUsers.get(socket.id);
    if (!callee) {
      console.log(`⚠️ [ERROR] call-rejected from unknown socket ${socket.id}`);
      return;
    }

    const targetSocketId = data.targetSocketId;
    if (connectedUsers.has(targetSocketId)) {
      const senderUser = connectedUsers.get(targetSocketId);
      
      // ✨ NEW: Fetch user name from database
      try {
        const user = await User.findOne({ uuid: callee.uuid }).select('name');
        const fromName = user?.name || callee.uuid; // Fallback to UUID if name not found
        
        console.log(`❌ [CALL-REJECTED] ${callee.uuid} (${fromName}) rejected call with socket ${targetSocketId}`);
        io.to(targetSocketId).emit('call-rejected', {
          fromUuid: callee.uuid,
          fromName: fromName, // ✨ NEW: Include user name
          fromSocketId: socket.id
        });
      } catch (error) {
        console.log(`⚠️ [ERROR] Failed to fetch user name for ${callee.uuid}:`, error);
        // Fallback to UUID if fetch fails
        io.to(targetSocketId).emit('call-rejected', {
          fromUuid: callee.uuid,
          fromName: callee.uuid,
          fromSocketId: socket.id
        });
      }

      // ✨ NEW: Update transaction status
      if (senderUser) {
        try {
          const DocumentTransaction = require('./Models/DocumentTransaction');
          await DocumentTransaction.findOneAndUpdate(
            {
              senderUuid: senderUser.uuid,
              receiverUuid: callee.uuid,
              status: 'pending'
            },
            {
              status: 'rejected',
              respondedAt: new Date()
            },
            { sort: { createdAt: -1 } }
          );
          console.log(`📝 [TRANSACTION] Updated transaction status to 'rejected'`);
        } catch (error) {
          console.error(`❌ [ERROR] Failed to update transaction:`, error);
        }
      }
    }
  });

  // WebRTC signaling
  // socket.on('offer', (data) => {
  //   console.log(`📥 [SIGNAL] offer from ${socket.id}, target: ${data.targetSocketId}`);
  //   const target = connectedUsers.get(data.target || data.targetSocketId);

  //   if (target) {
  //     io.to(target.socketId).emit('offer', {
  //       offer: data.offer,
  //       fromSocketId: socket.id,
  //       fromUuid: connectedUsers.get(socket.id)?.uuid
  //     });
  //     console.log(`📤 [FORWARDED] offer from ${socket.id} -> ${target.socketId}`);
  //   }
  // });

  // socket.on('answer', (data) => {
  //   console.log(`📥 [SIGNAL] answer from ${socket.id}, target: ${data.targetSocketId}`);
  //   const target = connectedUsers.get(data.target || data.targetSocketId);

  //   if (target) {
  //     io.to(target.socketId).emit('answer', {
  //       answer: data.answer,
  //       fromSocketId: socket.id,
  //       fromUuid: connectedUsers.get(socket.id)?.uuid
  //     });
  //     console.log(`📤 [FORWARDED] answer from ${socket.id} -> ${target.socketId}`);
  //   }
  // });

  // socket.on('ice-candidate', (data) => {
  //   console.log(`📥 [SIGNAL] ice-candidate from ${socket.id}, target: ${data.targetSocketId}`);
  //   const target = connectedUsers.get(data.target || data.targetSocketId);

  //   if (target) {
  //     io.to(target.socketId).emit('ice-candidate', {
  //       candidate: data.candidate,
  //       fromSocketId: socket.id,
  //       fromUuid: connectedUsers.get(socket.id)?.uuid
  //     });
  //     console.log(`📤 [FORWARDED] ice-candidate from ${socket.id} -> ${target.socketId}`);
  //   }
  // });
// WebRTC signaling - CORRECTED LOGIC
  socket.on('offer', (data) => {
    console.log(`📥 [SIGNAL] offer from ${socket.id} to ${data.target}`);
    // The 'data.target' from the client IS the target socket ID.
    // We don't need to look it up in a map.
    io.to(data.target).emit('offer', {
      from: socket.id, // Use 'from' to match client expectation
      offer: data.offer
    });
    console.log(`📤 [FORWARDED] offer from ${socket.id} -> ${data.target}`);
  });

  socket.on('answer', (data) => {
    console.log(`📥 [SIGNAL] answer from ${socket.id} to ${data.target}`);
    io.to(data.target).emit('answer', {
      from: socket.id, // Use 'from'
      answer: data.answer
    });
    console.log(`📤 [FORWARDED] answer from ${socket.id} -> ${data.target}`);
  });

  socket.on('ice-candidate', (data) => {
    console.log(`📥 [SIGNAL] ice-candidate from ${socket.id} to ${data.target}`);
    io.to(data.target).emit('ice-candidate', {
      from: socket.id, // Use 'from'
      candidate: data.candidate
    });
    // Don't log the full candidate object, it's too verbose.
    console.log(`📤 [FORWARDED] ice-candidate from ${socket.id} -> ${data.target}`);
  });


  // Direct messaging
  socket.on('send-direct-message', (data) => {
    console.log(`📥 [EVENT] send-direct-message from ${socket.id}, payload:`, data);

    const fromUser = connectedUsers.get(socket.id);
    if (!fromUser) {
      console.log(`⚠️ [ERROR] direct-message from unknown socket ${socket.id}`);
      return;
    }

    const targetUuid = data.targetUuid;
    const targetUser = Array.from(connectedUsers.values()).find(u => u.uuid === targetUuid);

    if (targetUser) {
      console.log(`💬 [DM] ${fromUser.uuid} -> ${targetUuid}: "${data.message}"`);
      io.to(targetUser.socketId).emit('direct-message', {
        message: data.message,
        fromUuid: fromUser.uuid
      });
    } else {
      console.log(`❌ [ERROR] direct-message target ${targetUuid} not found`);
      socket.emit('direct-error', { message: 'Target not found' });
    }
  });

  // Disconnect cleanup
  socket.on('disconnect', () => {
    const user = connectedUsers.get(socket.id);
    if (user) {
      connectedUsers.delete(socket.id);
      console.log(`❌ [DISCONNECT] User ${user.uuid} (socket ${socket.id}) disconnected`);
      socket.broadcast.emit('user-disconnected', {
        uuid: user.uuid,
        socketId: socket.id
      });
      console.log(`📣 [NOTIFY] Broadcasted that user ${user.uuid} disconnected`);
    } else {
      console.log(`❌ [DISCONNECT] Unknown socket ${socket.id} disconnected`);
    }
  });
});


const PORT = process.env.PORT || 4000;
server.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);

  // ✨ FIX: Initialize the blockchain service here
  try {
    initializeBlockchain(io);

    app.use("/blockchain",blockchainRouter);
  } catch (error) {
    console.error("🚨 Failed to initialize blockchain service:", error.message);
  }
});
