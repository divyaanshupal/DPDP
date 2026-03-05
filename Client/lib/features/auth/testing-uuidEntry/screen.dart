import 'package:flutter/material.dart';
import 'package:kyrotics/features/home/presentation/newHomeScreen.dart';
import 'package:kyrotics/services/registerLog.dart';

class UuidEntryScreen extends StatefulWidget {
  const UuidEntryScreen({super.key});
  @override
  State<UuidEntryScreen> createState() => _UuidEntryScreenState();
}

class _UuidEntryScreenState extends State<UuidEntryScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleProceed() async {
    final uuid = _controller.text.trim();
    if (uuid.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a UUID')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await logEvent(
        eventType: "register-user",
        userType: "client",
        uuid: uuid,
        metadata: "{}",
      );

      if (success) {

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DocumentDashboard(uuid: uuid)),
          );
        }
      } else {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save log. Try again!')),
        );
      }
    } catch (e) {
      // ⚠️ Catch any exceptions
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter UUID')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'UUID',
              ),
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: _handleProceed,
                  child: const Text('Proceed'),
                ),
          ],
        ),
      ),
    );
  }
}
