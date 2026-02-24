import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // You may need to run "flutter pub add intl"

class UserNotificationDrawer extends StatelessWidget {
  const UserNotificationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header for the drawer
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.indigo.shade100,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.notifications,
                  color: Colors.indigo.shade800,
                  size: 30,
                ),
                const SizedBox(width: 16),
                Text(
                  'Notifications',
                  style: TextStyle(
                    color: Colors.indigo.shade800,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // StreamBuilder to show the list of notifications
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                      child: Text("Could not load notifications."));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "You have no new notifications.",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                // Build the list
                return ListView(
                  padding: EdgeInsets.zero,
                  children:
                      snapshot.data!.docs.map((DocumentSnapshot document) {
                    Map<String, dynamic> data =
                        document.data()! as Map<String, dynamic>;

                    String title = data['title'] ?? 'No Title';
                    String message = data['message'] ?? 'No Message';
                    String timeAgo = 'Just now';

                    if (data['timestamp'] != null) {
                      timeAgo = DateFormat('MMM d, yyyy  h:mm a')
                          .format((data['timestamp'] as Timestamp).toDate());
                    }

                    return ListTile(
                      leading: const Icon(Icons.notifications_active,
                          color: Colors.indigo),
                      title: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(message),
                      trailing: Text(
                        timeAgo,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
