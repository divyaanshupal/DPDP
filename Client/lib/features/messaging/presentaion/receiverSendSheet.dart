// ------------------------- Receiver Send Sheet -------------------------
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Ensure this path is correct for your project structure
import 'package:kyrotics/services/webrtcController.dart';

class ReceiverSendSheet extends ConsumerWidget {
  const ReceiverSendSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✨ 1. Watch the provider to get the latest state and rebuild on change.
    final webrtc = ref.watch(webrtcProvider);
    final textCtrl = TextEditingController();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textCtrl,
              decoration: const InputDecoration(hintText: 'Enter text to send'),
              // ✨ (Optional) Also disable the text field when not connected
              enabled: webrtc.isDataChannelOpen,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              // ✨ 2. Conditionally set the onPressed callback.
              //    - If the channel is open, provide the function to send data.
              //    - If not, provide `null` to automatically disable the button.
              onPressed: webrtc.isDataChannelOpen
                  ? () {
                      // Note: I'm assuming you will create this sendP2P method.
                      // If you're only sending documents, adapt this accordingly.
                      // ref.read(webrtcProvider).sendP2P(textCtrl.text.trim());
                      debugPrint("Send button pressed!"); // Placeholder
                      Navigator.pop(context);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                // ✨ (Optional) Add visual feedback for the disabled state.
                backgroundColor: webrtc.isDataChannelOpen ? Theme.of(context).primaryColor : Colors.grey,
                foregroundColor: Colors.white,
              ),
              child: Text(webrtc.isDataChannelOpen ? 'Send' : 'Connecting...'),
            ),
          ],
        ),
      ),
    );
  }
}