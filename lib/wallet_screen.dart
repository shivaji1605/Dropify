import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto_guide/crypto_api_service.dart';
import 'package:crypto_guide/edit_profile_screen.dart'; // Import EditProfileScreen
import 'dart:developer';
import 'dart:async';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  // Firebase and API instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CryptoApiService _apiService = CryptoApiService();
  StreamSubscription? _authSubscription;
  String? _userId;

  // State variables for our data
  bool _isLoading = true;
  String _walletAddress = "No wallet set";
  double _totalPortfolioValue = 0.0;

  @override
  void initState() {
    super.initState();

    _authSubscription = _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _userId = user.uid;
        _loadWalletData(user.uid);
      } else {
        _userId = null;
        if (mounted) {
          setState(() {
            _isLoading = false;
            _walletAddress = "Not logged in";
            _totalPortfolioValue = 0.0;
          });
        }
      }
    });

    // Handle case where user is already logged in
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      _userId = currentUser.uid;
      _loadWalletData(currentUser.uid);
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  // This function loads BOTH profile info (wallet) and portfolio (value)
  Future<void> _loadWalletData(String userId) async {
    if (mounted) setState(() => _isLoading = true);

    try {
      // --- 1. Load Wallet Address from Profile ---
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();

      String address = "No wallet set. Tap to edit.";
      if (userDoc.exists && userDoc.data() != null) {
        var data = userDoc.data() as Map<String, dynamic>;
        if (data.containsKey('walletAddress') &&
            data['walletAddress'].isNotEmpty) {
          address = data['walletAddress'];
        }
      }

      // --- 2. Load Portfolio Value ---
      QuerySnapshot portfolioSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('portfolio')
          .get();

      double newTotalValue = 0.0;
      if (portfolioSnapshot.docs.isNotEmpty) {
        List<String> coinIds =
            portfolioSnapshot.docs.map((doc) => doc.id).toList();
        Map<String, double> userAmounts = {
          for (var doc in portfolioSnapshot.docs)
            doc.id: (doc.data() as Map<String, dynamic>)['amount'] ?? 0.0
        };

        List<Coin> liveCoinData = await _apiService.fetchPricesForIds(coinIds);

        for (var coin in liveCoinData) {
          double amount = userAmounts[coin.id] ?? 0;
          double value = amount * coin.price;
          newTotalValue += value;
        }
      }

      // --- 3. Update the UI ---
      if (mounted) {
        setState(() {
          _walletAddress = address;
          _totalPortfolioValue = newTotalValue;
          _isLoading = false;
        });
      }
    } catch (e) {
      log("Error loading wallet data: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _walletAddress = "Error loading wallet";
          _totalPortfolioValue = 0.0;
        });
      }
    }
  }

  // --- NEW: Navigation to Edit Profile ---
  void _navigateToEditProfile() {
    User? user = _auth.currentUser;
    if (user != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditProfileScreen(currentUser: user),
        ),
      ).then((_) {
        // When we come back from the edit screen, reload the data
        _loadWalletData(user.uid);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "My Wallet",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 🪙 Balance Card
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFe0f7fa), Color(0xFFffffff)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Total Balance",
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // --- MODIFIED: Dynamic Total Value ---
                  _isLoading
                      ? const SizedBox(
                          height: 30, child: CircularProgressIndicator())
                      : Text(
                          "\$${_totalPortfolioValue.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                  const SizedBox(height: 12),
                  // --- MODIFIED: Dynamic Wallet Address ---
                  Row(
                    children: [
                      Icon(Icons.wallet_outlined,
                          color: Colors.blueGrey, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _walletAddress,
                          style: const TextStyle(
                            color: Colors.blueGrey,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // --- NEW: Edit Button ---
                      GestureDetector(
                        onTap: _navigateToEditProfile,
                        child: const Icon(Icons.edit_outlined,
                            color: Colors.blueAccent, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 💰 Wallet Actions (No change)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _walletAction(Icons.add_circle_outline, "Add Funds"),
                _walletAction(Icons.send_outlined, "Send"),
                _walletAction(Icons.qr_code_2_outlined, "Scan"),
                _walletAction(Icons.history, "History"),
              ],
            ),

            const SizedBox(height: 40),

            // 🔄 Recent Transactions (No change)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Recent Transactions",
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 15),

            _transactionTile("BTC Transfer", "-0.15 BTC", "Oct 27, 2025"),
            _transactionTile("ETH Received", "+0.32 ETH", "Oct 26, 2025"),
            _transactionTile("USDT Top-Up", "+1500 USDT", "Oct 25, 2025"),
            _transactionTile("Gas Fee", "-0.002 BTC", "Oct 24, 2025"),
          ],
        ),
      ),
    );
  }

  // Wallet Action Button Widget (No change)
  static Widget _walletAction(IconData icon, String label) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blueAccent.withOpacity(0.1),
          ),
          padding: const EdgeInsets.all(14),
          child: Icon(icon, color: Colors.blueAccent, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Transaction Tile Widget (No change)
  static Widget _transactionTile(String title, String amount, String date) {
    final isPositive = amount.startsWith('+');
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPositive
              ? Colors.greenAccent.withOpacity(0.2)
              : Colors.redAccent.withOpacity(0.2),
          child: Icon(
            isPositive ? Icons.arrow_downward : Icons.arrow_upward,
            color: isPositive ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.w500, fontSize: 16),
        ),
        subtitle: Text(
          date,
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        trailing: Text(
          amount,
          style: TextStyle(
            color: isPositive ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
