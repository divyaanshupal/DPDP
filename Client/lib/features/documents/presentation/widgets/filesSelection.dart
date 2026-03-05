import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ✨ 1. Add Riverpod import
import 'package:hive/hive.dart';
import 'package:kyrotics/features/documents/model/local_document_model.dart';
import 'package:kyrotics/services/webrtcController.dart'; // ✨ 2. Add controller import

// ✨ 3. Convert from StatefulWidget to ConsumerStatefulWidget
class DocumentSelectionDialog extends ConsumerStatefulWidget {
  final Function(List<LocalDocument>) onSend;

  const DocumentSelectionDialog({super.key, required this.onSend});

  @override
  // ✨ 4. Adjust the createState return type
  ConsumerState<DocumentSelectionDialog> createState() => _DocumentSelectionDialogState();
}

// ✨ 5. Convert from State to ConsumerState
class _DocumentSelectionDialogState extends ConsumerState<DocumentSelectionDialog> {
  final List<LocalDocument> _allDocuments = [];
  final Set<LocalDocument> _selectedDocuments = {};

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    final webrtcController = ref.read(webrtcProvider);
    final uuid = webrtcController.selfUuid;
    
    if (uuid == null) return;
    
    try {
      final box = Hive.box<LocalDocument>('documents_$uuid');
      _allDocuments.addAll(box.values);
    } catch (e) {
      final box = await Hive.openBox<LocalDocument>('documents_$uuid');
      _allDocuments.addAll(box.values);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✨ 6. Watch the provider to get the connection status.
    //    This will cause the dialog to rebuild when the connection state changes.
    final webrtc = ref.watch(webrtcProvider);

    return AlertDialog(
      title: const Text('Select Documents to Send'),
      content: SizedBox(
        width: double.maxFinite,
        child: _allDocuments.isEmpty
            ? const Center(child: Text('You have no documents to send.'))
            : ListView.builder(
                shrinkWrap: true,
                itemCount: _allDocuments.length,
                itemBuilder: (context, index) {
                  final doc = _allDocuments[index];
                  final isSelected = _selectedDocuments.contains(doc);
                  return CheckboxListTile(
                    title: Text(doc.name),
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedDocuments.add(doc);
                        } else {
                          _selectedDocuments.remove(doc);
                        }
                        
                      });
                    },
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          // ✨ 7. Update the onPressed logic to check both conditions.
          onPressed: webrtc.isDataChannelOpen && _selectedDocuments.isNotEmpty
              ? () {
                  widget.onSend(_selectedDocuments.toList());
                  Navigator.pop(context);
                }
              : null, // Button is disabled if channel is closed OR no files are selected
          style: ElevatedButton.styleFrom(
            // ✨ 8. (Optional but recommended) Add visual feedback
            backgroundColor: webrtc.isDataChannelOpen ? Colors.deepPurple : Colors.grey,
            foregroundColor: Colors.white,
          ),
          // ✨ 9. Update the button text based on connection state
          child: Text(webrtc.isDataChannelOpen ? 'Send' : 'Connecting...'),
        ),
      ],
    );
  }
}