import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto_guide/user_detail_screen.dart'; // We will create this next
import 'dart:developer';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final Stream<QuerySnapshot> _usersStream =
      FirebaseFirestore.instance.collection('users').snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Analytics"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _usersStream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            log("Error loading users: ${snapshot.error}");
            return const Center(child: Text("Could not load users."));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No users found."));
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data =
                  document.data()! as Map<String, dynamic>;
              
              return ListTile(
                title: Text(data['displayName'] ?? 'No Name'),
                subtitle: Text(document.id), // Shows the User ID
                trailing: (data['isAdmin'] ?? false) 
                  ? const Chip(label: Text('Admin'), backgroundColor: Colors.indigo, labelStyle: TextStyle(color: Colors.white),)
                  : const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserDetailScreen(
                        userId: document.id,
                        displayName: data['displayName'] ?? 'User',
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
