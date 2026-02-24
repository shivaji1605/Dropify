import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto_guide/custom_snackbar.dart';
import 'dart:developer';
// Note: The 'intl' package import is now removed

// This helper class is part of this file
class AirdropTask {
  String task;
  String url;
  String reward;

  AirdropTask({required this.task, required this.url, required this.reward});

  Map<String, String?> toMap() {
    return {
      'task': task,
      'url': url.isNotEmpty ? url : null,
      'reward': reward.isNotEmpty ? reward : null,
    };
  }
}

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _rewardController = TextEditingController();
  final _deadlineController = TextEditingController(); // This is a text field again
  final _orderController = TextEditingController();

  final List<AirdropTask> _tasks = [];

  final _taskDescController = TextEditingController();
  final _taskUrlController = TextEditingController();
  final _taskRewardController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _rewardController.dispose();
    _deadlineController.dispose();
    _orderController.dispose();
    _taskDescController.dispose();
    _taskUrlController.dispose();
    _taskRewardController.dispose();
    super.dispose();
  }

  // --- The _selectDate() function has been removed ---

  void _showAddTaskDialog() {
    _taskDescController.clear();
    _taskUrlController.clear();
    _taskRewardController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add New Task"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _taskDescController,
                decoration: const InputDecoration(labelText: "Task Description (e.g., 'Follow on X')"),
              ),
              TextField(
                controller: _taskUrlController,
                decoration: const InputDecoration(labelText: "URL (e.g., 'https://twitter.com/...')"),
              ),
              TextField(
                controller: _taskRewardController,
                decoration: const InputDecoration(labelText: "Reward (e.g., '50 Points')"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (_taskDescController.text.isNotEmpty) {
                  setState(() {
                    _tasks.add(AirdropTask(
                      task: _taskDescController.text.trim(),
                      url: _taskUrlController.text.trim(),
                      reward: _taskRewardController.text.trim(),
                    ));
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveAirdrop() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final List<Map<String, String?>> tasksForFirestore =
          _tasks.map((task) => task.toMap()).toList();

      await FirebaseFirestore.instance.collection('airdrops').add({
        'title': _titleController.text.trim(),
        'subtitle': _subtitleController.text.trim(),
        'reward': _rewardController.text.trim(),
        'deadline': _deadlineController.text.trim(), // Saves the text as-is
        'order': int.tryParse(_orderController.text.trim()) ?? 0,
        'tasks': tasksForFirestore,
      });

      if (mounted) {
        CustomSnackbar().showCustomSnackbar(
          context,
          "Airdrop saved successfully!",
          bgColor: Colors.green,
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      log("Error saving airdrop: $e");
      if (mounted) {
        CustomSnackbar().showCustomSnackbar(
          context,
          "Failed to save airdrop.",
          bgColor: Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Panel"),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Airdrop Details",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: "Title"),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  TextFormField(
                    controller: _subtitleController,
                    decoration: const InputDecoration(labelText: "Subtitle"),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  TextFormField(
                    controller: _rewardController,
                    decoration: const InputDecoration(labelText: "Reward"),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  
                  // --- MODIFICATION: This is the original Deadline field ---
                  TextFormField(
                    controller: _deadlineController,
                    decoration: const InputDecoration(labelText: "Deadline"),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  // --- END OF MODIFICATION ---

                  TextFormField(
                    controller: _orderController,
                    decoration: const InputDecoration(labelText: "Order"),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),

                  const SizedBox(height: 24),
                  const Text("Airdrop Tasks",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      return Card(
                        child: ListTile(
                          title: Text(task.task),
                          subtitle: Text(task.reward.isNotEmpty ? "Reward: ${task.reward}" : "No reward"),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _tasks.removeAt(index);
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  Center(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text("Add Task"),
                      onPressed: _showAddTaskDialog,
                    ),
                  ),

                  const SizedBox(height: 30),
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text("Save New Airdrop"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 15),
                      ),
                      onPressed: _isLoading ? null : _saveAirdrop,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}