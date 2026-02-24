import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

// --- DATA MODEL FOR COINS ---
class Coin {
  final String id;
  final String name;
  final String symbol; // This is 'btc', 'eth', etc.
  final double price;
  final double changePercent24Hr;

  Coin({
    required this.id,
    required this.name,
    required this.symbol,
    required this.price,
    required this.changePercent24Hr,
  });

  // Factory constructor to parse the JSON from CoinGecko API
  factory Coin.fromJson(Map<String, dynamic> json) {
    return Coin(
      id: json['id'],
      name: json['name'],
      symbol: json['symbol'], // e.g., 'btc'
      price: (json['current_price'] ?? 0).toDouble(),
      changePercent24Hr: (json['price_change_percentage_24h'] ?? 0).toDouble(),
    );
  }
}

// --- DATA MODEL FOR NEWS ARTICLES ---
class Article {
  final String title;
  final String subtitle;
  final String imageUrl;
  final String fullArticle;

  Article({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.fullArticle,
  });

  // Factory constructor to parse the JSON from NewsAPI.org
  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'] ?? 'No Title',
      subtitle: json['description'] ?? 'No description available.',
      imageUrl: json['urlToImage'] ?? '', // Handle null or empty image URLs
      fullArticle: json['content'] ?? json['description'] ?? 'No content available.',
    );
  }
}

// --- THE API SERVICE CLASS ---
// This class will handle all our network requests.
class CryptoApiService {
  
  /// Fetches the Top 10 coins by market cap from CoinGecko.
  Future<List<Coin>> fetchMarketPrices() async {
    const url =
        'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=10&page=1';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Coin.fromJson(json)).toList();
      } else {
        log('Failed to load market prices: ${response.statusCode}');
        throw Exception('Failed to load market prices from CoinGecko');
      }
    } catch (e) {
      log('Error fetching market prices: $e');
      throw Exception('Error fetching market prices: $e');
    }
  }

  // --- NEW FUNCTION ---
  /// Fetches the current market data for a specific list of coin IDs.
  /// [coinIds] - A list of coin IDs, e.g., ['bitcoin', 'ethereum']
  Future<List<Coin>> fetchPricesForIds(List<String> coinIds) async {
    if (coinIds.isEmpty) {
      return []; // Return empty list if no IDs are provided
    }
    
    // Joins the list of IDs into a comma-separated string for the API
    final String ids = coinIds.join(',');
    final url =
        'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&ids=$ids';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        // We use the same Coin.fromJson factory, as the response structure is the same
        return data.map((json) => Coin.fromJson(json)).toList();
      } else {
        log('Failed to load prices for IDs: ${response.statusCode}');
        throw Exception('Failed to load prices for IDs');
      }
    } catch (e) {
      log('Error fetching prices for IDs: $e');
      throw Exception('Error fetching prices for IDs: $e');
    }
  }
  // --- END NEW FUNCTION ---


  /// Fetches crypto news from NewsAPI.org.
  /// Requires a valid API key.
  Future<List<Article>> fetchCryptoNews(String apiKey) async {
    if (apiKey.isEmpty || apiKey == 'PASTE_YOUR_API_KEY_HERE') {
       log('NewsAPI key is missing!');
       // Return an empty list or throw an error
       return []; 
    }
    
    final url =
        'https://newsapi.org/v2/everything?q=(crypto OR bitcoin) AND blockchain&sortBy=publishedAt&language=en&apiKey=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse = json.decode(response.body);
        List<dynamic> articlesJson = jsonResponse['articles'];
        return articlesJson.map((json) => Article.fromJson(json)).toList();
      } else {
        log('Failed to load news: ${response.statusCode}');
        log('Response body: ${response.body}');
        throw Exception('Failed to load crypto news');
      }
    } catch (e) {
      log('Error fetching news: $e');
      throw Exception('Error fetching news: $e');
    }
  }
}
