import 'package:flutter/material.dart';
import 'package:crypto_guide/custom_snackbar.dart';
// --- NEW IMPORT: Added Firestore ---
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer';

class AdminNotificationScreen extends StatefulWidget {
  const AdminNotificationScreen({super.key});

  @override
  State<AdminNotificationScreen> createState() =>
      _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // --- THIS FUNCTION IS NOW MODIFIED ---
  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() => _isLoading = true);

    try {
      // --- MODIFICATION: Replaced Future.delayed with a real Firestore write ---
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(), // Automatically add the time
      });
      // --- END OF MODIFICATION ---

      if (mounted) {
        CustomSnackbar().showCustomSnackbar(
          context,
          "Notification sent successfully!", // Updated text
          bgColor: Colors.green,
        );
        _titleController.clear();
        _messageController.clear();
      }

    } catch (e) {
      log("Error sending notification: $e");
      if (mounted) {
        CustomSnackbar().showCustomSnackbar(
          context,
          "Failed to send notification.",
          bgColor: Colors.red,
        );
      }
    } finally {
      // This will run even if there is an error
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Send Notification"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Broadcast to All Users",
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Notification Title",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? "Title is required" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: "Notification Message",
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) =>
                    (value == null || value.isEmpty) ? "Message is required" : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _sendNotification,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: const Text("Send Notification"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}