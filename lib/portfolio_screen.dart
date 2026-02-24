import 'dart:async';
import 'dart:math' hide log; // <-- THIS IS THE FIX
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:developer'; // <-- THIS IS THE FIX

// --- MODIFIED: Added Firebase and API Service ---
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto_guide/crypto_api_service.dart';
import 'package:crypto_guide/custom_snackbar.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  String _selectedTimeframe = '1W';
  List<FlSpot> _chartData = [];
  bool _isLoading = true; // --- MODIFIED: True on init
  bool _isRefreshing = false;

  // --- MODIFIED: Firebase and API instances ---
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CryptoApiService _apiService = CryptoApiService();
  StreamSubscription? _authSubscription;
  String? _userId;

  // --- MODIFIED: This is now loaded from Firestore ---
  List<Map<String, dynamic>> _holdings = [];
  double _totalPortfolioValue = 0.0;
  double _portfolioChange24h = 0.0;

  @override
  void initState() {
    super.initState();
    _generateChartData(); // Generate placeholder chart
    
    // --- MODIFIED: Listen for auth state ---
    _authSubscription = _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _userId = user.uid;
        _loadPortfolio(); // Load portfolio once user is confirmed
      } else {
        _userId = null;
        if (mounted) {
           setState(() {
            _isLoading = false;
            _holdings = [];
            _totalPortfolioValue = 0.0;
            _portfolioChange24h = 0.0;
          });
        }
      }
    });

    // Handle case where user is already logged in
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      _userId = currentUser.uid;
      _loadPortfolio();
    } else {
       if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  // --- NEW: Load portfolio from Firestore and API ---
  Future<void> _loadPortfolio() async {
    if (_userId == null) {
      if(mounted) setState(() => _isLoading = false);
      return;
    }
    if(mounted) setState(() => _isLoading = true);

    try {
      // 1. Get user's saved holdings from Firestore
      QuerySnapshot portfolioSnapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('portfolio')
          .get();
          
      if (portfolioSnapshot.docs.isEmpty) {
        // User has no coins saved
         if (mounted) {
           setState(() {
            _holdings = [];
            _totalPortfolioValue = 0.0;
            _portfolioChange24h = 0.0;
            _isLoading = false;
          });
         }
        return;
      }

      // 2. Get the list of coin IDs to fetch from the API
      List<String> coinIds = portfolioSnapshot.docs.map((doc) => doc.id).toList();
      Map<String, double> userAmounts = {
         for (var doc in portfolioSnapshot.docs) doc.id: (doc.data() as Map<String, dynamic>)['amount'] ?? 0.0
      };

      // 3. Fetch live price data for these coins
      List<Coin> liveCoinData = await _apiService.fetchPricesForIds(coinIds);

      // 4. Merge Firestore data (amount) with API data (price, etc.)
      List<Map<String, dynamic>> newHoldings = [];
      double newTotalValue = 0.0;
      double totalValueYesterday = 0.0;

      for (var coin in liveCoinData) {
        double amount = userAmounts[coin.id] ?? 0;
        double value = amount * coin.price;
        double changePercent = coin.changePercent24Hr;
        
        newTotalValue += value;
        
        // Calculate the value 24h ago
        double priceYesterday = coin.price / (1 + (changePercent / 100));
        totalValueYesterday += amount * priceYesterday;
        
        newHoldings.add({
          'id': coin.id, // e.g., 'bitcoin'
          'symbol': coin.symbol.toUpperCase(),
          'name': coin.name,
          'amount': '$amount ${coin.symbol.toUpperCase()}',
          'value': value,
          'change': '${changePercent.toStringAsFixed(2)}%',
          'positive': changePercent >= 0,
        });
      }
      
      // Calculate total portfolio change
      double newPortfolioChange = 0.0;
      if (totalValueYesterday > 0) {
        newPortfolioChange = ((newTotalValue - totalValueYesterday) / totalValueYesterday) * 100;
      }

      // 5. Update the UI
      if (mounted) {
        setState(() {
          _holdings = newHoldings;
          _totalPortfolioValue = newTotalValue;
          _portfolioChange24h = newPortfolioChange;
          _isLoading = false;
          _isRefreshing = false;
        });
      }

    } catch (e) {
      log("Error loading portfolio: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        CustomSnackbar().showCustomSnackbar(context, "Could not load portfolio.", bgColor: Colors.red);
      }
    }
  }


  // Generate random chart data (for each timeframe)
  void _generateChartData() {
    final random = Random();
    _chartData = List.generate(7, (index) => FlSpot(index.toDouble(), 28000 + random.nextInt(4000).toDouble()));
  }

  // Handle timeframe change
  void _changeTimeframe(String timeframe) {
    setState(() {
      _selectedTimeframe = timeframe;
      _generateChartData();
    });
  }

  // Handle portfolio refresh
  Future<void> _refreshPortfolio() async {
    setState(() => _isRefreshing = true);
    await _loadPortfolio(); // --- MODIFIED: Call new load function ---
  }

  // --- MODIFIED: Add new coin via dialog ---
  void _addCoin() {
    if (_userId == null) {
      CustomSnackbar().showCustomSnackbar(context, "Please log in first.", bgColor: Colors.red);
      return;
    }
    
    final coinIdController = TextEditingController();
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Coin to Portfolio"),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: coinIdController,
                  decoration: const InputDecoration(
                    labelText: "Coin ID (e.g., 'bitcoin')",
                    hintText: "From CoinGecko (lowercase)",
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty) ? "Coin ID is required" : null,
                ),
                TextFormField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: "Amount Owned",
                    hintText: "e.g., 0.5",
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Amount is required";
                    if (double.tryParse(value) == null) return "Enter a valid number";
                    if (double.parse(value) <= 0) return "Amount must be positive";
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final String coinId = coinIdController.text.trim().toLowerCase();
                  final double amount = double.parse(amountController.text);
                  
                  // Save to Firestore
                  try {
                    await _firestore
                        .collection('users')
                        .doc(_userId)
                        .collection('portfolio')
                        .doc(coinId) // Use coin ID as document ID
                        .set({
                          'amount': amount,
                          'addedOn': FieldValue.serverTimestamp(),
                        }, SetOptions(merge: true)); // Use merge to update if already exists
                        
                    if (mounted) {
                      Navigator.of(context).pop();
                      CustomSnackbar().showCustomSnackbar(context, "$coinId added to portfolio!", bgColor: Colors.green);
                      _loadPortfolio(); // Refresh the list
                    }
                  } catch (e) {
                    log("Error adding coin: $e");
                     if (mounted) {
                       CustomSnackbar().showCustomSnackbar(context, "Failed to add coin.", bgColor: Colors.red);
                     }
                  }
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }
  
  // --- NEW: Delete a holding ---
  Future<void> _deleteCoin(String coinId) async {
    if (_userId == null) return;
    
    // Show confirmation
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove Coin"),
        content: Text("Are you sure you want to remove $coinId from your portfolio?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("Remove", style: TextStyle(color: Colors.red))),
        ],
      )
    );
    
    if (confirm != true) return;

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('portfolio')
          .doc(coinId)
          .delete();
          
      if (mounted) {
         CustomSnackbar().showCustomSnackbar(context, "$coinId removed.", bgColor: Colors.green);
         _loadPortfolio(); // Refresh list
      }
    } catch (e) {
      log("Error deleting coin: $e");
      if (mounted) {
         CustomSnackbar().showCustomSnackbar(context, "Failed to remove coin.", bgColor: Colors.red);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Icon(Icons.arrow_back, color: Colors.black), // This is on NavScreen, so it's not really used.
        title: const Text('Portfolio',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh, color: Colors.black),
            onPressed: _isRefreshing ? null : _refreshPortfolio,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPortfolio,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTotalValueCard(),
                const SizedBox(height: 20),
                _buildPerformanceChartCard(),
                const SizedBox(height: 20),
                _buildHoldingsSection(),
                const SizedBox(height: 20),
                _buildStudentProgressCard(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_portfolio',
        onPressed: _addCoin,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // --- MODIFIED: Build total value card from state ---
  Widget _buildTotalValueCard() {
    bool isPositive = _portfolioChange24h >= 0;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Total Portfolio Value',
              style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 8),
          _isLoading 
            ? const SizedBox(height: 32, child: CircularProgressIndicator())
            : Text('\$${_totalPortfolioValue.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _isLoading
            ? Container()
            : Row(children: [
                Icon(isPositive ? Icons.trending_up : Icons.trending_down, color: isPositive ? Colors.green : Colors.red, size: 18),
                const SizedBox(width: 4),
                Text('${_portfolioChange24h.toStringAsFixed(2)}%', style: TextStyle(color: isPositive ? Colors.green[700] : Colors.red[700])),
                const SizedBox(width: 4),
                const Text('24h', style: TextStyle(color: Colors.grey)),
              ]),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['1D', '1W', '1M', '1Y']
                .map((t) => _timeframeButton(t, _selectedTimeframe == t))
                .toList(),
          )
        ]),
      ),
    );
  }

  Widget _timeframeButton(String text, bool isSelected) {
    return ElevatedButton(
      onPressed: () => _changeTimeframe(text),
      style: ElevatedButton.styleFrom(
        foregroundColor: isSelected ? Colors.white : Colors.black,
        backgroundColor: isSelected ? Colors.blue[800] : Colors.grey[200],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      child: Text(text),
    );
  }

  Widget _buildPerformanceChartCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Portfolio Performance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: LineChart(LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 1,
                    getTitlesWidget: bottomTitleWidgets,
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: _chartData,
                  isCurved: true,
                  color: Colors.cyan,
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        Colors.cyan.withOpacity(0.3),
                        Colors.cyan.withOpacity(0.0)
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                )
              ],
              minY: 26000,
              maxY: 35000,
            )),
          ),
        ]),
      ),
    );
  }

  static Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(color: Colors.grey, fontSize: 12);
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(value.toInt() < days.length ? days[value.toInt()] : '',
          style: style),
    );
  }

  // --- MODIFIED: Build holdings from state ---
  Widget _buildHoldingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Your Holdings',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(_isRefreshing ? 'Updating...' : 'Updated: Now',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        
        if (_isLoading)
          const Center(child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ))
        else if (_holdings.isEmpty)
           const Center(child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text("You have no holdings. Tap '+' to add a coin."),
          ))
        else
          ..._holdings.map((coin) => _holdingItem(coin)).toList(),
      ],
    );
  }

  Widget _holdingItem(Map<String, dynamic> coin) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(children: [
        CircleAvatar(
          backgroundColor: Colors.grey[200],
          child: Text(coin['symbol'][0],
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 12),
        Text(coin['symbol'],
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(width: 6),
        Text(coin['name'], style: const TextStyle(color: Colors.grey)),
      ]),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center, // Added
        children: [
          Text('\$${coin['value'].toStringAsFixed(2)}',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(coin['change'],
              style: TextStyle(
                  color: coin['positive'] ? Colors.green : Colors.red)),
        ],
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Amount: ${coin['amount']}'),
                const SizedBox(height: 4),
                Text('Market Value: \$${coin['value'].toStringAsFixed(2)}'),
                const SizedBox(height: 4),
                Text('24h Change: ${coin['change']}'),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red[700]),
                    onPressed: () => _deleteCoin(coin['id']),
                  ),
                )
              ]),
        )
      ],
    );
  }

  // This is hard-coded, but could also be loaded from Firestore
  Widget _buildStudentProgressCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.school, color: Colors.blue),
            SizedBox(width: 8),
            Text('Student Journey Progress',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            const Text('Level 6',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Spacer(),
            Chip(
                label: const Text('Crypto Enthusiast'),
                backgroundColor: Colors.cyan[100],
                labelStyle: TextStyle(color: Colors.cyan[800]))
          ]),
          const SizedBox(height: 8),
          ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                  value: 0.6,
                  minHeight: 10,
                  backgroundColor: Colors.grey[300],
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.blue))),
          const SizedBox(height: 4),
          const Text('60% to next level', style: TextStyle(color: Colors.grey)),
        ]),
      ),
    );
  }
}


