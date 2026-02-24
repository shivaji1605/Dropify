import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto_guide/crypto_api_service.dart';
import 'dart:developer';

class UserDetailScreen extends StatefulWidget {
  final String userId;
  final String displayName;

  const UserDetailScreen({
    super.key,
    required this.userId,
    required this.displayName,
  });

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CryptoApiService _apiService = CryptoApiService();

  int _videosWatched = 0;
  double _portfolioValue = 0.0;
  bool _isLoading = true;
  int _quizzesCompleted = 0;

  @override
  void initState() {
    super.initState();
    _loadAllUserData();
  }

  Future<void> _loadAllUserData() async {
    setState(() => _isLoading = true);
    try {
      // Load both pieces of data in parallel
      final results = await Future.wait([
  _loadVideoProgress(),
  _loadPortfolioValue(),
  _loadQuizProgress(), // <--- ADD THIS
]);
      
      if (mounted) {
  setState(() {
    _videosWatched = results[0] as int;
    _portfolioValue = results[1] as double;
    _quizzesCompleted = results[2] as int; // <--- ADD THIS
    _isLoading = false;
  });
}
    } catch (e) {
      log("Error loading user details: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<int> _loadVideoProgress() async {
    QuerySnapshot videoSnapshot = await _firestore
        .collection('users')
        .doc(widget.userId)
        .collection('videoProgress')
        .get();
    return videoSnapshot.docs.length;
  }

  Future<int> _loadQuizProgress() async {
  QuerySnapshot quizSnapshot = await _firestore
      .collection('users')
      .doc(widget.userId)
      .collection('quizProgress')
      .get();
  // We just need the count of completed quizzes
  return quizSnapshot.docs.length;
}

  Future<double> _loadPortfolioValue() async {
    QuerySnapshot portfolioSnapshot = await _firestore
        .collection('users')
        .doc(widget.userId)
        .collection('portfolio')
        .get();

    if (portfolioSnapshot.docs.isEmpty) {
      return 0.0;
    }

    List<String> coinIds = portfolioSnapshot.docs.map((doc) => doc.id).toList();
    Map<String, double> userAmounts = {
      for (var doc in portfolioSnapshot.docs)
        doc.id: (doc.data() as Map<String, dynamic>)['amount'] ?? 0.0
    };

    List<Coin> liveCoinData = await _apiService.fetchPricesForIds(coinIds);

    double newTotalValue = 0.0;
    for (var coin in liveCoinData) {
      double amount = userAmounts[coin.id] ?? 0;
      double value = amount * coin.price;
      newTotalValue += value;
    }
    return newTotalValue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.displayName),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("User ID: ${widget.userId}", style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 20),
                  _buildStatCard(
                    context,
                    title: "Portfolio Value",
                    value: "\$${_portfolioValue.toStringAsFixed(2)}",
                    icon: Icons.account_balance_wallet,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 16),
                  _buildStatCard(
                    context,
                    title: "Videos Watched",
                    value: _videosWatched.toString(),
                    icon: Icons.video_collection,
                    color: Colors.purple,
                  ),
                  const SizedBox(height: 16), // Add space
                  _buildStatCard(
                    context,
                    title: "Quizzes Completed",
                    value: _quizzesCompleted.toString(),
                    icon: Icons.quiz,
                    color: Colors.blue, // Or any color you like
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(BuildContext context, {required String title, required String value, required IconData icon, required Color color}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: color),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
