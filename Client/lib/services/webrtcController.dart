import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:hive/hive.dart';
import 'package:kyrotics/features/documents/model/local_document_model.dart';
import 'package:kyrotics/features/encrption/hybrid_encryption_service.dart';
import 'package:kyrotics/features/encrption/rsa_key_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

final webrtcProvider = ChangeNotifierProvider<WebRTCController>((ref) => WebRTCController());

class WebRTCController extends ChangeNotifier {
   static const String signalingUrl = 'https://dpdp-j99k.onrender.com/';
  // static const String signalingUrl = 'http://192.168.230.1:4000/';

  io.Socket? socket;
  String? selfUuid;
  RTCPeerConnection? _pc;
  RTCDataChannel? _dc;
  final List<LocalDocument> receivedDocuments = [];
   List<String>? incomingRequestedDocs;
  Map<String, String>? incomingRequestTypes; // ✨ NEW: docName -> 'view' or 'download'

  String? incomingFromUuid;
  String? incomingFromName; // ✨ NEW: Sender's name
  String? incomingFromSocketId;
  String? incomingNote;
  int? incomingExpirationDays; // ✨ NEW: Expiration time for incoming request
  String? peerUuid;
  String? peerSocketId;
  String? _peerPublicKeyPem;
  
  //encrption part starts 
  Future<String?> getOwnPublicKey() async {
    if (selfUuid == null) return null;
    final rsaKeyService = RSAKeyService();
    return await rsaKeyService.getPublicKeyPem(selfUuid!);
  }
  
  // ✨ NEW: Send public key to peer
  Future<void> sendPublicKey() async {
    if (_dc?.state != RTCDataChannelState.RTCDataChannelOpen) return;
    
    final publicKey = await getOwnPublicKey();
    if (publicKey == null) {
      // Generate key pair if doesn't exist
      final rsaKeyService = RSAKeyService();
      final keyPair = await rsaKeyService.getOrGenerateKeyPair(selfUuid!);
      final publicKeyPem = rsaKeyService.publicKeyToPem(keyPair.publicKey);
      
      final keyMessage = jsonEncode({
        'type': 'public-key-exchange',
        'publicKey': publicKeyPem,
      });
      _dc!.send(RTCDataChannelMessage(keyMessage));
      debugPrint('[WebRTC] 🔐 Sent public key to peer');
    } else {
      final keyMessage = jsonEncode({
        'type': 'public-key-exchange',
        'publicKey': publicKey,
      });
      _dc!.send(RTCDataChannelMessage(keyMessage));
      debugPrint('[WebRTC] 🔐 Sent public key to peer');
    }
  }

  //encrption part ends

  bool _isDataChannelOpen = false;
  bool get isDataChannelOpen => _isDataChannelOpen;

  final Map<String, ({
  String name, 
  String fileType, 
  StringBuffer buffer, 
  DateTime? expirationTime, 
  bool isSharedFile, 
  String? requestType,
  bool isEncrypted,
  String? encryptedKey, // ✨ NEW: RSA-encrypted AES key
})> _reassemblyBuffers = {};
  
  // ✨ NEW: Track expected documents for sent requests (targetUuid -> list of expected document names)
  final Map<String, List<String>> _expectedDocuments = {};
  
  // ✨ NEW: Track request status (targetUuid -> 'pending'/'accepted'/'rejected')
  final Map<String, String> _requestStatus = {};
  
  // ✨ NEW: Track received documents count for each request (targetUuid -> count)
  final Map<String, int> _receivedDocumentsCount = {};
  
  // ✨ NEW: Track latest received document info for snackbar (targetUuid -> (docName, count, total))
  final Map<String, ({String docName, int count, int total})> _latestReceivedDocument = {};
  
  // ✨ NEW: Track if status/document changes need to show snackbar (used to trigger snackbar even if listener sees same state)
  final List<MapEntry<String, String>> _pendingStatusChanges = []; // List to track all pending status changes
  final Map<String, String> _pendingStatusChangeNames = {}; // Map to store names for pending status changes (uuid -> name)
  final List<MapEntry<String, ({String docName, int count, int total})>> _pendingDocumentInfos = []; // List to track all pending document infos
  
  // ✨ NEW: Get all request statuses (for listener access)
  Map<String, String> get allRequestStatuses => Map.unmodifiable(_requestStatus);
  
  // ✨ NEW: Get all latest received documents (for listener access)
  Map<String, ({String docName, int count, int total})> get allLatestReceivedDocuments => 
      Map.unmodifiable(_latestReceivedDocument);
  
  // ✨ NEW: Get pending status changes (cleared after being read)
  List<MapEntry<String, String>> getPendingStatusChanges() {
    if (_pendingStatusChanges.isNotEmpty) {
      final result = List<MapEntry<String, String>>.from(_pendingStatusChanges);
      _pendingStatusChanges.clear();
      debugPrint("[snackbar] 📥 Returning ${result.length} pending status changes");
      return result;
    }
    return [];
  }
  
  // ✨ NEW: Get name for a UUID (used with status changes)
  String? getNameForUuid(String uuid) {
    final name = _pendingStatusChangeNames.remove(uuid);
    debugPrint("[snackbar] 📥 Getting name for $uuid: $name");
    return name;
  }
  
  // ✨ NEW: Get pending document infos (cleared after being read)
  List<MapEntry<String, ({String docName, int count, int total})>> getPendingDocumentInfos() {
    if (_pendingDocumentInfos.isNotEmpty) {
      final result = List<MapEntry<String, ({String docName, int count, int total})>>.from(_pendingDocumentInfos);
      _pendingDocumentInfos.clear();
      debugPrint("[snackbar] 📥 Returning ${result.length} pending document infos");
      return result;
    }
    return [];
  }
  
  // ✨ NEW: Set expected documents when sending a request
  void setExpectedDocuments({
    required String targetUuid,
    required List<String> expectedDocuments,
  }) {
    debugPrint("[snackbar] 📝 Setting expected documents for targetUuid: $targetUuid");
    debugPrint("[snackbar] 📝 Expected documents: $expectedDocuments");
    _expectedDocuments[targetUuid] = expectedDocuments;
    _requestStatus[targetUuid] = 'pending';
    _receivedDocumentsCount[targetUuid] = 0;
    debugPrint("[snackbar] 📝 Request status set to 'pending' for $targetUuid");
    debugPrint("[snackbar] 📝 Received count initialized to 0 for $targetUuid");
    notifyListeners();
    debugPrint("[snackbar] 📝 Listeners notified after setting expected documents");
  }
  
  // ✨ NEW: Clear latest received document info (called after showing snackbar)
  void clearLatestReceivedDocument(String targetUuid) {
    _latestReceivedDocument.remove(targetUuid);
    notifyListeners();
  }

  /// Ensures the user-specific documents box is opened
  Future<Box<LocalDocument>> _getUserDocumentsBox(String uuid) async {
    try {
      return Hive.box<LocalDocument>('documents_$uuid');
    } catch (e) {
      // If box doesn't exist, open it
      return await Hive.openBox<LocalDocument>('documents_$uuid');
    }
  }

  // --- Connect and Signaling methods ---
  Future<void> connect(String uuid) async {
    selfUuid = uuid;
    socket = io.io(signalingUrl, {
      'transports': ['websocket'],
      'autoConnect': false,
    });

    // All socket event listeners...
    socket!.on('connect', (_) {
      debugPrint("[log] Socket connected: ${socket!.id}");
      debugPrint("🔍 [DEBUG] Registering user with UUID: $selfUuid");
      socket!.emit('register-user', {'uuid': selfUuid});
      debugPrint("🔍 [DEBUG] User registration request sent");
    });


    socket!.on('incoming-call', (jsonData) {
      debugPrint("✅ [INCOMING CALL RECEIVED IN CONTROLLER]: $jsonData");

      final data = jsonDecode(jsonData as String);
      debugPrint("✅ [INCOMING CALL PARSED]: $data");
      incomingFromUuid = data['fromUuid'];
      incomingFromName = data['fromName'] ?? data['fromUuid']; // ✨ NEW: Get sender's name, fallback to UUID
      incomingFromSocketId = data['fromSocketId'];
      incomingNote = data['note'];
      incomingExpirationDays = data['expirationDays'] ?? 7; // ✨ NEW: Get expiration days, default to 7
      if (data['requestedDocuments'] != null) {
        incomingRequestedDocs = List<String>.from(data['requestedDocuments']);
      }
      if (data['requestTypes'] != null) {
        incomingRequestTypes = Map<String, String>.from(data['requestTypes']); // ✨ NEW: Get request types
      } else {
        // Default all to 'view' if not provided
        incomingRequestTypes = incomingRequestedDocs != null 
            ? Map.fromEntries(incomingRequestedDocs!.map((doc) => MapEntry(doc, 'view')))
            : null;
      }
      
      debugPrint("✅ [INCOMING CALL] From: $incomingFromName ($incomingFromUuid), Docs: $incomingRequestedDocs, RequestTypes: $incomingRequestTypes, Expiration: $incomingExpirationDays days");
      debugPrint("✅ [INCOMING CALL] Notifying listeners...");
      notifyListeners();
      debugPrint("✅ [INCOMING CALL] Listeners notified successfully");
    });




    socket!.on('call-accepted', (data) async {
      debugPrint("[snackbar] 📥 call-accepted event received, data: $data");
      final fromUuid = data['fromUuid'] as String?;
      final fromName = data['fromName'] as String?; // ✨ NEW: Get user name from server
      debugPrint("[snackbar] 📥 Parsed fromUuid: $fromUuid, fromName: $fromName");
      if (fromUuid != null) {
        // ✨ NEW: Mark request as accepted
        debugPrint("[snackbar] ✅ Marking request as accepted for $fromUuid");
        final wasPending = _requestStatus[fromUuid] == 'pending';
        _requestStatus[fromUuid] = 'accepted';
        debugPrint("[snackbar] ✅ Request status updated: ${_requestStatus[fromUuid]}");
        debugPrint("[snackbar] ✅ Previous status was pending: $wasPending");
        
        // ✨ NEW: Set pending status change for snackbar
        if (wasPending) {
          _pendingStatusChanges.add(MapEntry(fromUuid, 'accepted'));
          // ✨ NEW: Store name for this UUID
          if (fromName != null) {
            _pendingStatusChangeNames[fromUuid] = fromName;
            debugPrint("[snackbar] ✅ Stored name for $fromUuid: $fromName");
          }
          debugPrint("[snackbar] ✅ Added pending status change: $fromUuid -> accepted");
          debugPrint("[snackbar] ✅ Total pending status changes: ${_pendingStatusChanges.length}");
        }
        
        notifyListeners();
        debugPrint("[snackbar] ✅ Listeners notified - snackbar should appear");
        debugPrint("✅ [REQUEST STATUS] Request from $fromUuid accepted");
      } else {
        debugPrint("[snackbar] ⚠️ fromUuid is null, cannot update status");
      }
      peerUuid = fromUuid;
      peerSocketId = data['fromSocketId'];
      await _startAsCaller(peerSocketId!);
    });
    
    // ✨ NEW: Listen for call-rejected event
    socket!.on('call-rejected', (data) {
      debugPrint("[snackbar] 📥 call-rejected event received, data: $data");
      final fromUuid = data['fromUuid'] as String?;
      final fromName = data['fromName'] as String?; // ✨ NEW: Get user name from server
      debugPrint("[snackbar] 📥 Parsed fromUuid: $fromUuid, fromName: $fromName");
      if (fromUuid != null) {
        // ✨ NEW: Mark request as rejected
        debugPrint("[snackbar] ❌ Marking request as rejected for $fromUuid");
        final wasPending = _requestStatus[fromUuid] == 'pending';
        _requestStatus[fromUuid] = 'rejected';
        debugPrint("[snackbar] ❌ Request status updated: ${_requestStatus[fromUuid]}");
        debugPrint("[snackbar] ❌ Previous status was pending: $wasPending");
        
        // ✨ NEW: Set pending status change for snackbar
        if (wasPending) {
          _pendingStatusChanges.add(MapEntry(fromUuid, 'rejected'));
          // ✨ NEW: Store name for this UUID
          if (fromName != null) {
            _pendingStatusChangeNames[fromUuid] = fromName;
            debugPrint("[snackbar] ❌ Stored name for $fromUuid: $fromName");
          }
          debugPrint("[snackbar] ❌ Added pending status change: $fromUuid -> rejected");
          debugPrint("[snackbar] ❌ Total pending status changes: ${_pendingStatusChanges.length}");
        }
        
        notifyListeners();
        debugPrint("[snackbar] ❌ Listeners notified - snackbar should appear");
        debugPrint("❌ [REQUEST STATUS] Request from $fromUuid rejected");
      } else {
        debugPrint("[snackbar] ⚠️ fromUuid is null, cannot update status");
      }
    });
    socket!.on('offer', (data) async {
      await _ensurePeerConnection(data['from']);
      await _pc!.setRemoteDescription(RTCSessionDescription(data['offer']['sdp'], data['offer']['type']));
      final answer = await _pc!.createAnswer();
      await _pc!.setLocalDescription(answer);
      socket!.emit('answer', {'target': data['from'], 'answer': answer.toMap()});
    });
    socket!.on('answer', (data) async {
      if (_pc != null) {
        await _pc!.setRemoteDescription(RTCSessionDescription(data['answer']['sdp'], data['answer']['type']));
      }
    });
    socket!.on('ice-candidate', (data) async {
      if (_pc != null && data['candidate'] != null) {
        final ice = RTCIceCandidate(data['candidate']['candidate'], data['candidate']['sdpMid'], data['candidate']['sdpMLineIndex']);
        await _pc!.addCandidate(ice);
      }
    });

    socket!.connect();
  }

  void requestConsent({
    required String targetUuid, 
    required String note,
    required List<String> requestedDocuments,
    required Map<String, String> requestTypes, // ✨ NEW: docName -> 'view' or 'download'
    required int expirationDays, // ✨ NEW: Expiration time in days
  }) {
    log("got a consent request for $targetUuid for $requestedDocuments with requestTypes: $requestTypes and $expirationDays days expiration");
    
    // Debug: Check socket connection
    if (socket == null) {
      log("❌ [ERROR] Socket is null! Cannot send call-request");
      return;
    }
    
    if (socket!.disconnected) {
      log("❌ [ERROR] Socket is disconnected! Cannot send call-request");
      return;
    }
    
    log("✅ [DEBUG] Socket connected: ${socket!.connected}, Socket ID: ${socket!.id}");
    
    socket?.emit('call-request', {
      'targetUuid': targetUuid,
      'note': note,
      'requestedDocuments': requestedDocuments,
      'requestTypes': requestTypes, // ✨ NEW: Include request types
      'expirationDays': expirationDays, // ✨ NEW: Include expiration time
    });
    
    log("📤 [DEBUG] Call-request emitted to server");
  }

  void acceptIncoming() {
    if (incomingFromSocketId == null || incomingFromUuid == null) return;
    peerUuid = incomingFromUuid;
    peerSocketId = incomingFromSocketId;
    
    // ✨ NEW: Store expected documents for receiver tracking before clearing
    if (incomingRequestedDocs != null && peerUuid != null) {
      _expectedDocuments[peerUuid!] = List<String>.from(incomingRequestedDocs!);
      _receivedDocumentsCount[peerUuid!] = 0; // Initialize count
      debugPrint('[Receiver] 📋 Stored expected documents for $peerUuid: ${incomingRequestedDocs}');
    }
    
    socket?.emit('call-accepted', {'targetSocketId': peerSocketId});
    
    // ✨ NEW: Clear socket ID so new requests can come in, but keep request data until transfer completes
    incomingFromSocketId = null;
    // ✨ NEW: Don't clear incoming request data yet - will be cleared after transfer completes
    // incomingFromUuid = null; // Keep for tracking
    // incomingFromName = null; // Keep for tracking
    // incomingNote = null; // Can clear
    // incomingExpirationDays = null; // Can clear
    // incomingRequestedDocs = null; // Keep for tracking
    // incomingRequestTypes = null; // Keep for tracking
    notifyListeners();
  }

  void rejectIncoming() {
    if (incomingFromSocketId != null) {
      socket?.emit('call-rejected', {'targetSocketId': incomingFromSocketId});
    }
    incomingFromSocketId = null;
    incomingNote = null;
    incomingFromUuid = null;
    incomingFromName = null; // ✨ NEW: Clear sender name
    incomingExpirationDays = null; // ✨ NEW: Clear expiration data
    incomingRequestedDocs = null;
    incomingRequestTypes = null; // ✨ NEW: Clear request types
    notifyListeners();
  }
  
  // ✨ NEW: Clear incoming request state (used when files are sent to prevent duplicate modals)
  void clearIncomingRequest() {
    incomingFromUuid = null;
    incomingFromName = null;
    incomingFromSocketId = null;
    incomingNote = null;
    incomingExpirationDays = null;
    incomingRequestedDocs = null;
    incomingRequestTypes = null;
    notifyListeners();
  }
  
  // void sendP2P(String text) {
  //   if (_dc?.state == RTCDataChannelState.RTCDataChannelOpen) {
  //     _dc!.send(RTCDataChannelMessage(text));
  //   }
  // }
  // Future<void> sendDocuments(List<LocalDocument> documents) async {
  //   if (_dc?.state != RTCDataChannelState.RTCDataChannelOpen) {
  //     debugPrint('[log] DataChannel is not open. Cannot send documents.');
  //     return;
  //   }

  //   const chunkSize = 16384; // 16 KB chunk size

  //   for (final doc in documents) {
  //     final docJson = doc.toJson();
  //     final docString = jsonEncode(docJson);

  //     // 1. Send START signal
  //     final startMessage = jsonEncode({
  //       'type': 'start',
  //       'name': doc.name,
  //       'fileType': doc.fileType,
  //     });
  //     _dc!.send(RTCDataChannelMessage(startMessage));
  //     debugPrint('[log] Sending START for ${doc.name}');
      
  //     await Future.delayed(const Duration(milliseconds: 50)); // Small delay

  //     // 2. Send data in CHUNKS
  //     for (var i = 0; i < docString.length; i += chunkSize) {
  //       final end = (i + chunkSize > docString.length) ? docString.length : i + chunkSize;
  //       final chunk = docString.substring(i, end);
  //       final chunkMessage = jsonEncode({'type': 'chunk', 'payload': chunk});
  //       _dc!.send(RTCDataChannelMessage(chunkMessage));
  //       debugPrint('[log] Sending CHUNK for ${doc.name}: ${chunk.length} bytes');
  //       await Future.delayed(const Duration(milliseconds: 1));
  //     }
  //     debugPrint('[log] Finished sending CHUNKS for ${doc.name}');
      
  //     await Future.delayed(const Duration(milliseconds: 50)); // Small delay

  //     // 3. Send END signal
  //     final endMessage = jsonEncode({'type': 'end', 'name': doc.name});
  //     _dc!.send(RTCDataChannelMessage(endMessage));
  //     debugPrint('[log] Sending END for ${doc.name}');
  //   }
  // }
  // In webrtcController.dart

Future<void> sendDocuments(List<LocalDocument> documents) async {
  log("Send document triggered");
  if (_dc?.state != RTCDataChannelState.RTCDataChannelOpen) {
    debugPrint('[log] DataChannel is not open. Cannot send documents.');
    return;
  }

   // ✨ NEW: Ensure we have peer's public key
  if (_peerPublicKeyPem == null) {
    debugPrint('[SENDER] ⚠️ Peer public key not received yet. Requesting...');
    // Request public key
    _dc!.send(RTCDataChannelMessage(jsonEncode({'type': 'request-public-key'})));

    int retries = 0;
    while (_peerPublicKeyPem == null && retries < 50) { // wait up to 5 seconds
      await Future.delayed(const Duration(milliseconds: 100));
      retries++;
    }

    if (_peerPublicKeyPem == null) {
      debugPrint('[SENDER] ❌ Peer public key still not available even after waiting. Cannot encrypt.');
      return;
    }

  }

  // ✨ NEW: Send our public key to peer
  //encrption process starts
  await sendPublicKey();
  await Future.delayed(const Duration(milliseconds: 100));

  final hybridEncryption = HybridEncryptionService(RSAKeyService());
  const chunkSize = 16384; // 16 KB chunk size

  for (final doc in documents) {
    try {
      // ✨ NEW: Encrypt file using hybrid encryption (AES + RSA)
      final encryptionResult = await hybridEncryption.encryptFile(
        doc.data,
        //peerUuid!, // Receiver's UUID
        _peerPublicKeyPem!,
      );
      
      final encryptedData = encryptionResult.encryptedData;
      final encryptedKeyBase64 = encryptionResult.encryptedKeyBase64;
      
      // Encode encrypted data to Base64
      final base64Data = base64Encode(encryptedData);

      debugPrint('[SENDER] 🔐 Document encrypted: ${doc.name}');
      debugPrint('[SENDER] 🔐 Original size: ${doc.data.length} bytes');
      debugPrint('[SENDER] 🔐 Encrypted size: ${encryptedData.length} bytes');

      // 1. Send START signal with encrypted AES key
      final startMessage = jsonEncode({
        'type': 'start',
        'name': doc.name,
        'fileType': doc.fileType,
        'expirationTime': doc.expirationTime?.toIso8601String(),
        'isSharedFile': doc.isSharedFile,
        'requestType': doc.requestType ?? 'view',
        'encrypted': true,
        'encryptedKey': encryptedKeyBase64, // ✨ NEW: RSA-encrypted AES key
      });
      _dc!.send(RTCDataChannelMessage(startMessage));
      debugPrint('[SENDER] 📤 Sending START for ${doc.name}');
      
      await Future.delayed(const Duration(milliseconds: 50));

      // 2. Send CHUNKS of encrypted Base64 data
      for (var i = 0; i < base64Data.length; i += chunkSize) {
        if (_dc?.state != RTCDataChannelState.RTCDataChannelOpen) {
          debugPrint('[SENDER] ❌ Connection lost while sending chunks for ${doc.name}');
          return;
        }
        
        final end = (i + chunkSize > base64Data.length) ? base64Data.length : i + chunkSize;
        final chunk = base64Data.substring(i, end);
        
        final chunkMessage = jsonEncode({
          'type': 'chunk',
          'name': doc.name,
          'payload': chunk
        });

        _dc!.send(RTCDataChannelMessage(chunkMessage));
        
        if (_dc != null) {
          final bufferedAmount = _dc!.bufferedAmount ?? 0;
          if (bufferedAmount > 500000) {
            await Future.delayed(const Duration(milliseconds: 50));
          } else {
            await Future.delayed(const Duration(milliseconds: 2));
          }
        } else {
          await Future.delayed(const Duration(milliseconds: 2));
        }
      }
      debugPrint('[log] Finished sending CHUNKS for ${doc.name}');
      
      await Future.delayed(const Duration(milliseconds: 100));

      // 3. Send END signal
      final endMessage = jsonEncode({'type': 'end', 'name': doc.name});
      _dc!.send(RTCDataChannelMessage(endMessage));
      debugPrint('[log] Sending END for ${doc.name}');
    } catch (e) {
      debugPrint('[SENDER] ❌ Error encrypting/sending ${doc.name}: $e');
    }
  }

  //encrption part ends




  //old non-encrption part below

  // const chunkSize = 16384; // 16 KB chunk size

  // for (final doc in documents) {
  //   // ✅ CORRECTION: Only Base64 encode the raw byte data.
  //   final base64Data = base64Encode(doc.data);

  //   // Debug: Log the document details
  //   debugPrint('[SENDER] 🔍 Sending document: ${doc.name}');
  //   debugPrint('[SENDER] 🔍 expirationTime: ${doc.expirationTime}');
  //   debugPrint('[SENDER] 🔍 isSharedFile: ${doc.isSharedFile}');
  //   debugPrint('[SENDER] 🔍 requestType: ${doc.requestType}');

  //   // 1. Send START signal with metadata (this is correct)
  //   final startMessage = jsonEncode({
  //     'type': 'start',
  //     'name': doc.name,
  //     'fileType': doc.fileType,
  //     'expirationTime': doc.expirationTime?.toIso8601String(), // ✨ NEW: Include expiration time
  //     'isSharedFile': doc.isSharedFile, // ✨ NEW: Include sharing flag
  //     'requestType': doc.requestType ?? 'view', // ✨ NEW: Include request type, default to 'view'
  //   });
  //   _dc!.send(RTCDataChannelMessage(startMessage));
  //   debugPrint('[SENDER] 📤 Sending START for ${doc.name} with expiration: ${doc.expirationTime?.toIso8601String()}, requestType: ${doc.requestType ?? 'view'}');
    
  //   await Future.delayed(const Duration(milliseconds: 50));

  //   // 2. Send CHUNKS of only the Base64 data string
  //   for (var i = 0; i < base64Data.length; i += chunkSize) {
  //     // ✨ FIX: Check connection state before sending each chunk
  //     if (_dc?.state != RTCDataChannelState.RTCDataChannelOpen) {
  //       debugPrint('[SENDER] ❌ Connection lost while sending chunks for ${doc.name}');
  //       return;
  //     }
      
  //     final end = (i + chunkSize > base64Data.length) ? base64Data.length : i + chunkSize;
  //     final chunk = base64Data.substring(i, end); // This is now a pure Base64 chunk
      
  //     // The payload contains the raw chunk
  //     final chunkMessage = jsonEncode({
  //       'type': 'chunk',
  //       'name': doc.name, // Still need the name to identify the file
  //       'payload': chunk
  //     });

  //     debugPrint('[SENDER] Attempting to send chunk for ${doc.name}');
  //     _dc!.send(RTCDataChannelMessage(chunkMessage));
      
  //     // ✨ FIX: Increase delay between chunks and wait for buffer to drain if it gets too large
  //     // If buffer is getting full, wait longer before sending next chunk
  //     if (_dc != null) {
  //       final bufferedAmount = _dc!.bufferedAmount ?? 0;
  //       if (bufferedAmount > 500000) { // If more than 500KB is buffered
  //         debugPrint('[SENDER] ⚠️ Buffer full (${bufferedAmount} bytes), waiting...');
  //         await Future.delayed(const Duration(milliseconds: 50));
  //       } else {
  //         await Future.delayed(const Duration(milliseconds: 2)); // Slightly longer delay
  //       }
  //     } else {
  //       await Future.delayed(const Duration(milliseconds: 2));
  //     }
  //   }
  //   debugPrint('[log] Finished sending CHUNKS for ${doc.name}');
    
  //   await Future.delayed(const Duration(milliseconds: 100)); // ✨ FIX: Longer delay after chunks

    // 3. Send END signal (this is correct)
  //   final endMessage = jsonEncode({'type': 'end', 'name': doc.name});
  //   _dc!.send(RTCDataChannelMessage(endMessage));
  //   debugPrint('[log] Sending END for ${doc.name}');
  // }
  
  // ✨ FIX: Wait for all data to be sent before closing connection
  debugPrint('[SENDER] ✅ All documents queued! Waiting for transmission to complete...');
  
  // Wait for buffered amount to reach 0 (all data sent) with timeout
  int maxWaitTime = 30000; // 30 seconds max wait
  int waited = 0;
  const checkInterval = 100; // Check every 100ms
  
  while (_dc != null) {
    final bufferedAmount = _dc!.bufferedAmount ?? 0;
    if (bufferedAmount == 0 || waited >= maxWaitTime) break;
    
    await Future.delayed(const Duration(milliseconds: checkInterval));
    waited += checkInterval;
    if (waited % 1000 == 0) {
      debugPrint('[SENDER] ⏳ Waiting for transmission... (${bufferedAmount} bytes remaining, waited ${waited}ms)');
    }
    
    // Check connection state
    if (_dc!.state != RTCDataChannelState.RTCDataChannelOpen) {
      debugPrint('[SENDER] ❌ Connection closed while waiting for transmission');
      break;
    }
  }
  
  if (_dc != null) {
    final finalBufferedAmount = _dc!.bufferedAmount ?? 0;
    if (finalBufferedAmount > 0) {
      debugPrint('[SENDER] ⚠️ Warning: ${finalBufferedAmount} bytes still buffered after timeout');
    } else {
      debugPrint('[SENDER] ✅ All data transmitted successfully');
    }
  }
  
  // ✨ FIX: Add additional delay to ensure receiver processes all messages
  debugPrint('[SENDER] ⏳ Waiting additional time for receiver to process...');
  await Future.delayed(const Duration(milliseconds: 1000)); // 1 second delay for receiver processing
  
  debugPrint('[SENDER] ✅ Closing connection...');
  _closeConnection();
}

  // ✨ NEW: Method to close WebRTC connection and clear all state
  void _closeConnection() {
    debugPrint('[WebRTC] 🧹 Cleaning up connection and state...');
    
    // Close data channel
    if (_dc != null) {
      try {
        _dc!.close();
        debugPrint('[WebRTC] ✅ Data channel closed');
      } catch (e) {
        debugPrint('[WebRTC] ⚠️ Error closing data channel: $e');
      }
      _dc = null;
    }
    
    // Close peer connection
    if (_pc != null) {
      try {
        _pc!.close();
        debugPrint('[WebRTC] ✅ Peer connection closed');
      } catch (e) {
        debugPrint('[WebRTC] ⚠️ Error closing peer connection: $e');
      }
      _pc = null;
    }
    
    // Clear connection state
    _isDataChannelOpen = false;
    peerUuid = null;
    peerSocketId = null;
    
    // Clear incoming request state (now safe to clear since transfer is complete)
    incomingFromUuid = null;
    incomingFromName = null;
    incomingFromSocketId = null;
    incomingNote = null;
    incomingExpirationDays = null;
    incomingRequestedDocs = null;
    incomingRequestTypes = null;
    
    // Clear reassembly buffers
    _reassemblyBuffers.clear();
    
    // Clear tracking maps (but keep _requestStatus for snackbar history)
    // _expectedDocuments.clear(); // Keep for now, will be cleared per request
    // _receivedDocumentsCount.clear(); // Keep for now, will be cleared per request
    // _latestReceivedDocument.clear(); // Keep for now, will be cleared per request
    
    debugPrint('[WebRTC] ✅ State cleared successfully');
    notifyListeners();
  }

  // Future<void> _startAsCaller(String targetSocketId) async {
  //   await _ensurePeerConnection(targetSocketId);
  //   final offer = await _pc!.createOffer();
  //   await _pc!.setLocalDescription(offer);
  //   socket!.emit('offer', {'target': targetSocketId, 'offer': offer.toMap()});
  // }
  // In WebRTCController class

Future<void> _startAsCaller(String targetSocketId) async {
  // First, ensure the peer connection and its listeners are set up.
  await _ensurePeerConnection(targetSocketId);

  // ✨ ADD THIS HERE: The caller is responsible for creating the data channel.
  final ch = await _pc!.createDataChannel('chat', RTCDataChannelInit());
  _attachDataChannel(ch);

  // Now, create and send the offer.
  final offer = await _pc!.createOffer();
  await _pc!.setLocalDescription(offer);
  socket!.emit('offer', {'target': targetSocketId, 'offer': offer.toMap()});
}

  // Future<void> _ensurePeerConnection(String targetSocketId) async {
  //   if (_pc != null) return;
  //   _pc = await createPeerConnection({'iceServers': [{'urls': 'stun:stun.l.google.com:19302'}]});

  //   _pc!.onIceCandidate = (c) {
  //     if (c != null) {
  //       socket?.emit('ice-candidate', {'target': targetSocketId, 'candidate': c.toMap()});
  //     }
  //   };
  //   _pc!.onDataChannel = (channel) => _attachDataChannel(channel);

  //   if (peerSocketId == targetSocketId) {
  //     final ch = await _pc!.createDataChannel('chat', RTCDataChannelInit());
  //     _attachDataChannel(ch);
  //   }
  // }
  // In WebRTCController class

// Future<void> _ensurePeerConnection(String targetSocketId) async {
//   if (_pc != null) return;

//   _pc = await createPeerConnection({
//     'iceServers': [
//       {'urls': 'stun:stun.l.google.com:19302'}
//     ]
//   });

//   _pc!.onIceCandidate = (c) {
//     if (c != null) {
//       socket?.emit('ice-candidate', {'target': targetSocketId, 'candidate': c.toMap()});
//     }
//   };

//   // The callee will listen for the channel to arrive here.
//   _pc!.onDataChannel = (channel) => _attachDataChannel(channel);

//   // ⛔️ REMOVE THIS BLOCK: This logic was causing the race condition.
//   // The data channel is now created explicitly by the caller in _startAsCaller.
//   /*
//   if (peerSocketId == targetSocketId) {
//     final ch = await _pc!.createDataChannel('chat', RTCDataChannelInit());
//     _attachDataChannel(ch);
//   }
//   */
// }
Future<void> _ensurePeerConnection(String targetSocketId) async {
  if (_pc != null) return;

  // Your existing ICE server configuration
  final Map<String, dynamic> configuration = {
    'iceServers': [
      {
        'urls': 'stun:stun.relay.metered.ca:80',
      },
      {
        'urls': 'turn:global.relay.metered.ca:80',
        'username': '3b662fc74c01b1a909fe4090',
        'credential': 'ZtzcrV1dm6iH+08G',
      },
      {
        'urls': 'turn:global.relay.metered.ca:80?transport=tcp',
        'username': '3b662fc74c01b1a909fe4090',
        'credential': 'ZtzcrV1dm6iH+08G',
      },
      {
        'urls': 'turn:global.relay.metered.ca:443',
        'username': '3b662fc74c01b1a909fe4090',
        'credential': 'ZtzcrV1dm6iH+08G',
      },
      {
        'urls': 'turns:global.relay.metered.ca:443?transport=tcp',
        'username': '3b662fc74c01b1a909fe4090',
        'credential': 'ZtzcrV1dm6iH+08G',
      },
    ]
    // 'iceServers': [
    //   {'urls': 'stun:stun.l.google.com:19302'}
    //   // 💡 If connection fails, you will need to add a TURN server here.
    //   // {
    //   //   'urls': 'turn:your-turn-server.com:3478',
    //   //   'username': '3b662fc74c01b1a909fe4090',
    //   //   'credential': 'ZtzcrV1dm6iH+08G',
    //   // },
    // ]
  };

  _pc = await createPeerConnection(configuration);

  // 🪵 ================== ADD THESE LOGS ================== 🪵

  // Log #1: ICE Connection State
  // This is the MOST IMPORTANT log for your issue. It tracks network connectivity.
  _pc!.onIceConnectionState = (RTCIceConnectionState state) {
    debugPrint('[P2P Connection] 🧊 ICE Connection State: $state');
  };

  // Log #2: Peer Connection State
  // This is a higher-level state of the overall connection.
  _pc!.onConnectionState = (RTCPeerConnectionState state) {
    debugPrint('[P2P Connection] 🔗 Connection State: $state');
  };

  // Log #3: Signaling State
  // Tracks the state of the offer/answer exchange.
  _pc!.onSignalingState = (RTCSignalingState state) {
    debugPrint('[P2P Connection]  signaling state: $state');
  };

  // Log #4: ICE Candidate Generation
  // Logs each time a potential connection path (candidate) is found.
  _pc!.onIceCandidate = (c) {
    debugPrint('[P2P Connection] 🕵️ Found ICE candidate: ${c.candidate}');
    socket?.emit('ice-candidate', {'target': targetSocketId, 'candidate': c.toMap()});
  };

  // 🪵 ================= END OF LOGS ================= 🪵

  // Your existing data channel listener
  _pc!.onDataChannel = (channel) => _attachDataChannel(channel);}

  // void _attachDataChannel(RTCDataChannel channel) {
  //   _dc = channel;
  //   _dc!.onMessage = (RTCDataChannelMessage message) {
  //     final data = jsonDecode(message.text);
  //     final type = data['type'];

  //     switch (type) {
  //       case 'start':
  //         debugPrint('[log] Receiving START for ${data['name']}');
  //         _fileDataBuffer.clear(); // Prepare buffer for new file
  //         _fileDataBuffer.write(jsonEncode({'name': data['name'], 'fileType': data['fileType'], 'data': ''}));
  //         break;
  //       case 'chunk':
  //         final payload = data['payload'] as String;
  //         // This is a simplified way to insert the chunk into our JSON string buffer
  //         _fileDataBuffer.write(payload.substring(1, payload.length - 1));
  //         break;
  //       case 'end':
  //         debugPrint('[log] Receiving END for ${data['name']}');
  //         try {
  //           // Reconstruct the full JSON from the buffer
  //           final fullFileJsonString = _fileDataBuffer.toString().replaceAllMapped(RegExp(r'"data":""(.*)"}'), (match) {
  //             return '"data":"${match.group(1)}"}';
  //           });
  //           final fileJson = jsonDecode(fullFileJsonString);
  //           final doc = LocalDocument.fromJson(fileJson);
            
  //           receivedDocuments.add(doc);
  //           notifyListeners(); // Notify UI that a new document has been received
  //           debugPrint('[log] Successfully reassembled and added ${doc.name}');
  //         } catch (e) {
  //           debugPrint('[log] Error reassembling file: $e');
  //         }
  //         _fileDataBuffer.clear();
  //         break;
  //       default:
  //         debugPrint('[log] Unknown message type received: $type');
  //     }
  //   };
  // }
  void _attachDataChannel(RTCDataChannel channel) {
    _dc = channel;
    _dc!.onDataChannelState = (RTCDataChannelState state) async {
    log('[DataChannel] State changed to: $state');           
      if (state == RTCDataChannelState.RTCDataChannelOpen) {   
        _isDataChannelOpen = true;
        await sendPublicKey();                          
      } else {                                                 
        _isDataChannelOpen = false;                         
      }                                                         
      // Notify the UI that the connection status has changed   ← 6 spaces (add 2 more)
      notifyListeners();                                        
    };



    _dc!.onMessage = (RTCDataChannelMessage message) async {
      final data = jsonDecode(message.text);
      final type = data['type'];
      // The file's name is the key to tracking its progress.
      final fileName = data['name'] as String?;

      // if (fileName == null) {
      //   debugPrint('[Receiver] ⚠️ Received message without a filename, ignoring.');
      //   return;
      // }

      switch (type) {
    case 'request-public-key':
      // ✨ NEW: Send public key when requested
      await sendPublicKey();
      break;

    case 'public-key-exchange':
      // ✨ NEW: Receive and store peer's public key
      _peerPublicKeyPem = data['publicKey'] as String;
      debugPrint('[Receiver] 🔐 Received peer public key');
      debugPrint("🔑 [RECEIVER] Raw PEM received:\n$_peerPublicKeyPem");
      debugPrint("🔑 Raw PEM length: ${_peerPublicKeyPem?.length}");
      break;

    case 'start':
      final fileName=data['name'];
      debugPrint('[Receiver] ✅ Receiving START for "$fileName"');
      _reassemblyBuffers[fileName] = (
        name: data['name'],
        fileType: data['fileType'],
        buffer: StringBuffer(),
        expirationTime: data['expirationTime'] != null 
            ? DateTime.parse(data['expirationTime']) 
            : null,
        isSharedFile: true,
        requestType: data['requestType'] ?? 'view',
        isEncrypted: data['encrypted'] ?? false,
        encryptedKey: data['encryptedKey'] as String?, // ✨ NEW: Store encrypted AES key
      );
      break;

    case 'chunk':
      final payload = data['payload'] as String;
      final fileName = data['name'];
      if (_reassemblyBuffers.containsKey(fileName)) {
        _reassemblyBuffers[fileName]!.buffer.write(payload);
      }
      break;

    case 'end':
      final fileName = data['name'];
      debugPrint('[Receiver] ✅ Receiving END for "$fileName"');
      final record = _reassemblyBuffers[fileName];

      if (record != null) {
        try {
          final completeBase64Data = record.buffer.toString();
          final encryptedBytes = base64Decode(completeBase64Data);
          
          // ✨ NEW: Decrypt using hybrid decryption
          Uint8List fileBytes;
          if (record.isEncrypted == true && record.encryptedKey != null) {
            final hybridEncryption = HybridEncryptionService(RSAKeyService());
            fileBytes = await hybridEncryption.decryptFile(
              encryptedBytes,
              record.encryptedKey!,
              selfUuid!, // Own UUID (we decrypt with our private key)
            );
            debugPrint('[Receiver] 🔐 Document decrypted successfully');
          } else {
            // Fallback for unencrypted files
            fileBytes = encryptedBytes;
            debugPrint('[Receiver] ⚠️ Document not encrypted');
          }

          final doc = LocalDocument(
            name: record.name,
            fileType: record.fileType,
            data: fileBytes,
            expirationTime: record.expirationTime,
            isSharedFile: record.isSharedFile,
            requestType: record.requestType,
            senderUuid: peerUuid,
            senderName: incomingFromName ?? peerUuid,
            receivedAt: DateTime.now(),
          );
          
          final box = await _getUserDocumentsBox(selfUuid!);
          await box.add(doc);
          
          // ... rest of existing tracking code ...

        } catch (e) {
          debugPrint('[Receiver] ❌ Error during decryption: $e');
        } finally {
          _reassemblyBuffers.remove(fileName);
        }
      }
      break;
      
    default:
      debugPrint('[Receiver] ❔ Unknown message type: $type');
  }
    };
  }
  

      

      // switch (type) {
      //   case 'start':
      //     debugPrint('[Receiver] ✅ Receiving START for "$fileName"');
      //     // ✨ FIX: Create a new, dedicated record for this file transfer.
      //     _reassemblyBuffers[fileName] = (
      //       name: data['name'],
      //       fileType: data['fileType'],
      //       buffer: StringBuffer(),
      //       expirationTime: data['expirationTime'] != null 
      //           ? DateTime.parse(data['expirationTime']) 
      //           : null, // ✨ NEW: Parse expiration time
      //       isSharedFile: true, // ✨ NEW: All received files are shared files
      //       requestType: data['requestType'] ?? 'view', // ✨ NEW: Get request type, default to 'view'
      //     );
      //     debugPrint('[Receiver] 🔍 Request type for "$fileName": ${data['requestType'] ?? 'view'}');
      //     break;

      //   case 'chunk':
      //     // ✨ FIX: Append the data chunk to the correct file's specific buffer.
      //     final payload = data['payload'] as String;
      //     if (_reassemblyBuffers.containsKey(fileName)) {
      //       _reassemblyBuffers[fileName]!.buffer.write(payload);
      //     } else {
      //       debugPrint('[Receiver] ⚠️ Received chunk for an unknown file: "$fileName"');
      //     }
      //     break;

      //   case 'end':
      //     debugPrint('[Receiver] ✅ Receiving END for "$fileName"');
      //     // ✨ FIX: Finalize the file, create the model, and clean up.
      //     final record = _reassemblyBuffers[fileName];

      //     if (record != null) {
      //       try {
      //         // 1. Get the complete Base64 string from the dedicated buffer.
      //         final completeBase64Data = record.buffer.toString();
              
      //         // 2. Decode the Base64 string back into binary data (Uint8List).
      //         final fileBytes = base64Decode(completeBase64Data);

      //         // 3. Create the document object with the stored metadata and decoded bytes.
      //         final doc = LocalDocument(
      //           name: record.name,
      //           fileType: record.fileType,
      //           data: fileBytes,
      //           expirationTime: record.expirationTime, // ✨ NEW: Include expiration time
      //           isSharedFile: record.isSharedFile, // ✨ NEW: Include sharing flag
      //           requestType: record.requestType, // ✨ NEW: Include request type
      //           senderUuid: peerUuid, // ✨ NEW: Store sender UUID
      //           senderName: incomingFromName ?? peerUuid, // ✨ NEW: Store sender name
      //           receivedAt: DateTime.now(), // ✨ NEW: Store receive timestamp
      //         );
              
      //         // Debug: Check the created document
      //         debugPrint('[Receiver] 🔍 Created document: ${doc.name}');
      //         debugPrint('[Receiver] 🔍 isSharedFile: ${doc.isSharedFile}');
      //         debugPrint('[Receiver] 🔍 expirationTime: ${doc.expirationTime}');
      //         debugPrint('[Receiver] 🔍 requestType: ${doc.requestType}');

      //         // Save to user-specific Hive storage
      //         final box = await _getUserDocumentsBox(selfUuid!);
      //         await box.add(doc);
              
      //         // Debug: Check what's in Hive
      //         debugPrint('[Receiver] 📦 Hive box now contains ${box.length} documents');
      //         debugPrint('[Receiver] 📦 Shared files in Hive: ${box.values.where((d) => d.isSharedFile == true).length}');
              
      //         receivedDocuments.add(doc);
      //         debugPrint("[snackbar] 📄 Document received: ${doc.name}");
      //         debugPrint("[snackbar] 📄 Checking if document matches expected documents...");
      //         debugPrint("[snackbar] 📄 Total expected documents map entries: ${_expectedDocuments.length}");
              
      //         // ✨ NEW: Check if this document is expected for any pending request
      //         bool matched = false;
      //         for (final entry in _expectedDocuments.entries) {
      //           final targetUuid = entry.key;
      //           final expectedDocs = entry.value;
      //           debugPrint("[snackbar] 📄 Checking against targetUuid: $targetUuid, expected docs: $expectedDocs");
                
      //           if (expectedDocs.contains(doc.name)) {
      //             matched = true;
      //             debugPrint("[snackbar] ✅ Document ${doc.name} matches expected document for $targetUuid");
      //             // This document is expected - increment count
      //             final previousCount = _receivedDocumentsCount[targetUuid] ?? 0;
      //             _receivedDocumentsCount[targetUuid] = previousCount + 1;
      //             final count = _receivedDocumentsCount[targetUuid]!;
      //             final total = expectedDocs.length;
                  
      //             debugPrint("[snackbar] 📊 Document count updated: $previousCount -> $count");
      //             debugPrint("[snackbar] 📊 Total expected: $total");
                  
      //             // ✨ NEW: Create document info once and use for both storage and pending list
      //             final docInfo = (
      //               docName: doc.name,
      //               count: count,
      //               total: total,
      //             );
                  
      //             // Store latest received document info for snackbar
      //             _latestReceivedDocument[targetUuid] = docInfo;
                  
      //             // ✨ NEW: Set pending document info for snackbar
      //             _pendingDocumentInfos.add(MapEntry(targetUuid, docInfo));
                  
      //             debugPrint('[snackbar] 📊 Stored latest received document: $targetUuid -> ${doc.name} ($count/$total)');
      //             debugPrint('[snackbar] 📊 Added pending document info: $targetUuid -> ${doc.name} ($count/$total)');
      //             debugPrint('[snackbar] 📊 Total pending document infos: ${_pendingDocumentInfos.length}');
      //             debugPrint('[Receiver] 📊 Document "${doc.name}" received ($count/$total) for request from $targetUuid');
      //             notifyListeners(); // Notify to show snackbar
      //             debugPrint("[snackbar] 📊 Listeners notified - snackbar should appear for document receipt");
      //             break; // Only match to first matching request
      //           }
      //         }
      //         if (!matched) {
      //           debugPrint("[snackbar] ⚠️ Document ${doc.name} does NOT match any expected documents");
      //         }
              
//               receivedDocuments.add(doc);
//               debugPrint("[snackbar] 📄 Document received: ${doc.name}");
              
//               // ✨ NEW: Also track for receiver side (when we're receiving documents from accepted requests)
//               if (peerUuid != null && incomingRequestedDocs != null && incomingRequestedDocs!.contains(doc.name)) {
//                 // Increment received count for this sender
//                 final previousCount = _receivedDocumentsCount[peerUuid!] ?? 0;
//                 _receivedDocumentsCount[peerUuid!] = previousCount + 1;
//                 final count = _receivedDocumentsCount[peerUuid!]!;
//                 final total = incomingRequestedDocs!.length;
                
//                 debugPrint("[snackbar] ✅ Document ${doc.name} matches expected document for $peerUuid (receiver side)");
//                 debugPrint("[snackbar] 📊 Document count updated: $previousCount -> $count");
//                 debugPrint("[snackbar] 📊 Total expected: $total");
//                 debugPrint('[Receiver] 📊 Document "${doc.name}" received ($count/$total) from $peerUuid');
                
//                 notifyListeners(); // Notify to show snackbar
                
//                 // ✨ NEW: Check if all expected documents have been received (receiver side)
//                 if (count >= total && total > 0) {
//                   debugPrint('[Receiver] ✅ All documents received from $peerUuid! Closing connection...');
//                   // Clear expected documents for this peer
//                   _expectedDocuments.remove(peerUuid);
//                   _receivedDocumentsCount.remove(peerUuid);
//                   _latestReceivedDocument.remove(peerUuid);
//                   // Close connection after a short delay to ensure all data is processed
//                   Future.delayed(const Duration(milliseconds: 500), () {
//                     _closeConnection();
//                   });
//                 }
//               }
              
//               // ✨ NEW: Check sender-side tracking (for documents we're receiving from sent requests)
//               for (final entry in _expectedDocuments.entries) {
//                 final targetUuid = entry.key;
//                 final expectedDocs = entry.value;
//                 debugPrint("[snackbar] 📄 Checking against targetUuid: $targetUuid, expected docs: $expectedDocs");
                
//                 if (expectedDocs.contains(doc.name)) {
//                   debugPrint("[snackbar] ✅ Document ${doc.name} matches expected document for $targetUuid");
//                   // This document is expected - increment count
//                   final previousCount = _receivedDocumentsCount[targetUuid] ?? 0;
//                   _receivedDocumentsCount[targetUuid] = previousCount + 1;
//                   final count = _receivedDocumentsCount[targetUuid]!;
//                   final total = expectedDocs.length;
                  
//                   debugPrint("[snackbar] 📊 Document count updated: $previousCount -> $count");
//                   debugPrint("[snackbar] 📊 Total expected: $total");
                  
//                   // ✨ NEW: Create document info once and use for both storage and pending list
//                   final docInfo = (
//                     docName: doc.name,
//                     count: count,
//                     total: total,
//                   );
                  
//                   // Store latest received document info for snackbar
//                   _latestReceivedDocument[targetUuid] = docInfo;
                  
//                   // ✨ NEW: Set pending document info for snackbar
//                   _pendingDocumentInfos.add(MapEntry(targetUuid, docInfo));
                  
//                   debugPrint('[snackbar] 📊 Stored latest received document: $targetUuid -> ${doc.name} ($count/$total)');
//                   debugPrint('[snackbar] 📊 Added pending document info: $targetUuid -> ${doc.name} ($count/$total)');
//                   debugPrint('[snackbar] 📊 Total pending document infos: ${_pendingDocumentInfos.length}');
//                   debugPrint('[Receiver] 📊 Document "${doc.name}" received ($count/$total) for request from $targetUuid');
//                   notifyListeners(); // Notify to show snackbar
//                   debugPrint("[snackbar] 📊 Listeners notified - snackbar should appear for document receipt");
                  
//                   // ✨ NEW: Check if all expected documents have been received (sender side)
//                   if (count >= total && total > 0) {
//                     debugPrint('[Receiver] ✅ All documents received from $targetUuid! Closing connection...');
//                     // Clear expected documents for this peer
//                     _expectedDocuments.remove(targetUuid);
//                     _receivedDocumentsCount.remove(targetUuid);
//                     _latestReceivedDocument.remove(targetUuid);
//                     // Close connection after a short delay to ensure all data is processed
//                     Future.delayed(const Duration(milliseconds: 500), () {
//                       _closeConnection();
//                     });
//                   }
//                   break; // Only match to first matching request
//                 }
//               }

//             } catch (e) {
//               debugPrint('[Receiver] ❌ Error during final reassembly of "$fileName": $e');
//             } finally {
//               // 4. IMPORTANT: Remove the entry from the map to free memory.
//               _reassemblyBuffers.remove(fileName);
//             }
//           } else {
//              debugPrint('[Receiver] ⚠️ Received END for a file that was not started: "$fileName"');
//           }
//           break;
          
//         default:
//           debugPrint('[Receiver] ❔ Unknown message type received: $type');
//       }
//     };
//   }

 }