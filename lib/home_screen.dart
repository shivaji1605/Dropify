// --- lib/HomeScreen.dart ---
// This file is now just the body of the page.

import 'package:crypto_guide/market_card.dart';
import 'package:crypto_guide/news_card.dart';
import 'package:flutter/material.dart';
import 'dart:developer';
import 'package:crypto_guide/crypto_api_service.dart';
// We re-use the same widgets
import 'package:crypto_guide/market_card.dart';
import 'package:crypto_guide/news_card.dart';
import 'package:crypto_guide/airdrop_card.dart';

// --- REMOVED: Imports for WalletScreen and TrackCoinScreen ---
// --- We will move this navigation to UserNavScreen ---

import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CryptoApiService _apiService = CryptoApiService();

  late Future<List<Coin>> _marketPricesFuture;
  late Future<List<Article>> _marketNewsFuture;

  final Stream<QuerySnapshot> _airdropsStream = FirebaseFirestore.instance
      .collection('airdrops')
      .orderBy('order')
      .snapshots();

  // IMPORTANT: Replace this with your actual API key
  final String _newsApiKey = 'ec0b4dc96ec34b3d97b53b2f6e16b6f6';

  @override
  void initState() {
    super.initState();
    _marketPricesFuture = _apiService.fetchMarketPrices();
    _marketNewsFuture = _apiService.fetchCryptoNews(_newsApiKey);
  }

  @override
  Widget build(BuildContext context) {
    // --- MODIFICATION: Scaffold, AppBar, and FAB are REMOVED ---
    // We just return the body content.
    return Container(
      color: Colors.grey[100], // Apply the background color here
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: const Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Portfolio Value",
                        style: TextStyle(color: Colors.grey)),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("\$12,847.32", // This is still your hardcoded value
                            style: TextStyle(
                                fontSize: 28, fontWeight: FontWeight.bold)),
                        Text("+5.67%",
                            style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold)),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text("Market Prices",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(
              height: 130,
              child: FutureBuilder<List<Coin>>(
                future: _marketPricesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    log(snapshot.error.toString());
                    return const Center(
                        child: Text("Could not load prices",
                            style: TextStyle(color: Colors.red)));
                  }
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    List<Coin> coins = snapshot.data!;
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: coins.length,
                      itemBuilder: (context, index) {
                        final coin = coins[index];
                        String price = "\$${coin.price.toStringAsFixed(2)}";
                        String change =
                            "${coin.changePercent24Hr.toStringAsFixed(2)}%";

                        // Use the new MarketCard widget
                        return MarketCard(
                          name: coin.symbol.toUpperCase(),
                          symbol: coin.name,
                          price: price,
                          change: change,
                        );
                      },
                    );
                  }
                  return const Center(child: Text("No data available"));
                },
              ),
            ),
            const SizedBox(height: 24),

            const Text("Live Airdrops",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: _airdropsStream,
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  log("Airdrop stream error: ${snapshot.error}");
                  return const Text('Could not load airdrops.',
                      style: TextStyle(color: Colors.red));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text("No live airdrops right now."));
                }

                return ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children:
                      snapshot.data!.docs.map((DocumentSnapshot document) {
                    Map<String, dynamic> data =
                        document.data()! as Map<String, dynamic>;
                    
                    // Use the new AirdropCard widget
                    return AirdropCard(
                      airdropId: document.id,
                      title: data['title'] ?? 'No Title',
                      subtitle: data['subtitle'] ?? '',
                      reward: data['reward'] ?? 'N/A',
                      deadline: data['deadline'] ?? 'Unknown',
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),

            const Text("Market News",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            FutureBuilder<List<Article>>(
              future: _marketNewsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  log(snapshot.error.toString());
                  return const Center(
                      child: Text("Could not load news",
                          style: TextStyle(color: Colors.red)));
                }
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  List<Article> allArticles = snapshot.data!;
                  List<Article> articles = allArticles.take(10).toList();

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: articles.length,
                    itemBuilder: (context, index) {
                      final article = articles[index];
                      // Use the new NewsCard widget
                      return NewsCard(
                        title: article.title,
                        subtitle: article.subtitle,
                        imageUrl: article.imageUrl,
                        fullArticle: article.fullArticle,
                      );
                    },
                  );
                }
                return const Center(child: Text("No news available"));
              },
            ),
            // Add padding for the FAB
            const SizedBox(height: 80), 
          ],
        ),
      ),
    );
  }
}