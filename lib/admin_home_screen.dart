import 'package:crypto_guide/market_card.dart';
import 'package:crypto_guide/news_card.dart';
import 'package:flutter/material.dart';
import 'dart:developer';
import 'package:crypto_guide/crypto_api_service.dart';
// We re-use the same widgets from home_screen.dart
import 'package:crypto_guide/home_screen.dart'
    show MarketCard, NewsCard, AirdropCard;
// We re-use the same dialogs from home_screen.dart
import 'package:crypto_guide/home_screen.dart'
    show _showMarketDetailsDialog, _showNewsDetailsDialog;

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final CryptoApiService _apiService = CryptoApiService();
  late Future<List<Coin>> _marketPricesFuture;
  late Future<List<Article>> _marketNewsFuture;

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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Admin Home',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
          ],
        ),
      ),
    );
  }
}
