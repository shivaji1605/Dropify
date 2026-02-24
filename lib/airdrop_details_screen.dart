import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer';
// --- NEW: Import Firestore ---
import 'package:cloud_firestore/cloud_firestore.dart';

class AirdropDetailsScreen extends StatefulWidget {
  final String airdropTitle;
  // --- NEW: Receive the document ID ---
  final String airdropDocumentId;

  const AirdropDetailsScreen({
    super.key,
    required this.airdropTitle,
    required this.airdropDocumentId,
  });

  @override
  State<AirdropDetailsScreen> createState() => _AirdropDetailsScreenState();
}

class _AirdropDetailsScreenState extends State<AirdropDetailsScreen> {
  // --- REMOVED: Static _airdropManuals map ---

  // --- NEW: State variables for loading and tasks ---
  bool _isLoading = true;
  List<Map<String, String?>> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasksFromFirestore();
  }

  // --- NEW: Function to load tasks from Firestore ---
  Future<void> _loadTasksFromFirestore() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('airdrops')
          .doc(widget.airdropDocumentId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        // Get the 'tasks' array from Firestore
        final List<dynamic> taskData = data['tasks'] ?? [];
        
        // Convert the List<dynamic> to the correct type
        final List<Map<String, String?>> parsedTasks = taskData
            .map((task) => Map<String, String?>.from(task as Map))
            .toList();

        if (mounted) {
          setState(() {
            _tasks = parsedTasks;
            _isLoading = false;
          });
        }
      } else {
        // No document found
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      log("Error loading airdrop tasks: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper function to launch a URL (unchanged)
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      log('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.airdropTitle), // Use title from widget
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
            color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Participation Guide",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Complete these tasks to maximize your chances.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // --- MODIFIED: Build list from state ---
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_tasks.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    "No participation tasks listed for this airdrop yet. Check back soon!",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              )
            else
              // Build the list of task cards from Firestore data
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  final task = _tasks[index];
                  final String taskDescription = task['task'] ?? 'No description';
                  final String? taskUrl = task['url'];
                  final String? taskReward = task['reward'];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ),
                      title: Text(
                        taskDescription,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: taskReward != null && taskReward.isNotEmpty
                          ? Text(
                              "Reward: $taskReward",
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          : null,
                      trailing: taskUrl != null
                          ? ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                _launchURL(taskUrl);
                              },
                              child: const Text(
                                "Go",
                                style: TextStyle(color: Colors.white),
                              ),
                            )
                          : null,
                    ),
                  );
                },
              ),

            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.yellow.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.yellow.shade700),
              ),
              child: Text(
                "Disclaimer: Airdrops are not guaranteed. Always do your own research and never share your private keys. These instructions are for educational purposes only.",
                style: TextStyle(
                  color: Colors.yellow.shade900,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

