import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TrackCoinScreen extends StatefulWidget {
  const TrackCoinScreen({super.key});

  @override
  State<TrackCoinScreen> createState() => _TrackCoinScreenState();
}

class _TrackCoinScreenState extends State<TrackCoinScreen> {
  TextEditingController searchController = TextEditingController();
  Map<String, dynamic>? coinData;
  bool isLoading = false;
  bool hasError = false;

  Future<void> fetchCoinDetails(String query) async {
    setState(() {
      isLoading = true;
      hasError = false;
      coinData = null;
    });

    try {
      final url = 'https://api.coingecko.com/api/v3/coins/$query';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          coinData = data;
        });
      } else {
        setState(() {
          hasError = true;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        title: const Text(
          "Track Coin",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
              String query = searchController.text.trim().toLowerCase();
              if (query.isNotEmpty) {
                fetchCoinDetails(query);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search any coin (e.g., bitcoin, ethereum)",
                prefixIcon: const Icon(Icons.currency_bitcoin),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (value) {
                fetchCoinDetails(value.trim().toLowerCase());
              },
            ),
            const SizedBox(height: 20),
            if (isLoading)
              const CircularProgressIndicator()
            else if (hasError)
              const Text(
                "No data found. Try another coin name.",
                style: TextStyle(color: Colors.red),
              )
            else if (coinData != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.network(
                            coinData!['image']['large'],
                            height: 80,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            coinData!['name'],
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            coinData!['symbol'].toUpperCase(),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "\$${coinData!['market_data']['current_price']['usd'].toString()}",
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "24h Change: ${coinData!['market_data']['price_change_percentage_24h'].toStringAsFixed(2)}%",
                            style: TextStyle(
                              fontSize: 16,
                              color: coinData!['market_data']
                                          ['price_change_percentage_24h'] >
                                      0
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Divider(color: Colors.grey.shade300),
                          const SizedBox(height: 10),
                          _infoRow("Market Cap",
                              "\$${coinData!['market_data']['market_cap']['usd']}"),
                          _infoRow("24h High",
                              "\$${coinData!['market_data']['high_24h']['usd']}"),
                          _infoRow("24h Low",
                              "\$${coinData!['market_data']['low_24h']['usd']}"),
                          const SizedBox(height: 20),
                          const Text(
                            "About Coin",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _parseDescription(
                                coinData!['description']['en'] ?? ""),
                            textAlign: TextAlign.justify,
                            style: TextStyle(
                                color: Colors.grey.shade700, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 15)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black)),
        ],
      ),
    );
  }

  String _parseDescription(String desc) {
    // Remove long HTML-like tags from CoinGecko API description
    final cleaned = desc.replaceAll(RegExp(r'<[^>]*>'), '');
    return cleaned.length > 500 ? "${cleaned.substring(0, 500)}..." : cleaned;
  }
}