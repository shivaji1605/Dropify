import 'package:flutter/material.dart';

// This dialog function now "belongs" to the MarketCard
// It's private to this file, but MarketCard can call it.
void _showMarketDetailsDialog(
    BuildContext context, String name, String symbol, String price, String change) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('$symbol Details ($name)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Price: $price',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text('24h Change: $change',
                style: TextStyle(
                    color: change.startsWith('-') ? Colors.red : Colors.green)),
            const SizedBox(height: 16),
            const Text(
                'Here, you could display more information like market cap, volume, or even a mini-chart.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

// This is the same MarketCard widget, now in its own file
class MarketCard extends StatelessWidget {
  final String name, symbol, price, change;
  const MarketCard({
    super.key,
    required this.name,
    required this.symbol,
    required this.price,
    required this.change,
  });

  @override
  Widget build(BuildContext context) {
    bool isPositive = !change.startsWith('-');
    return InkWell(
      onTap: () {
        // It can now call the dialog function from its own file
        _showMarketDetailsDialog(context, name, symbol, price, change);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(symbol, style: TextStyle(color: Colors.grey[600])),
            const Spacer(),
            Text(price,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              change,
              style: TextStyle(
                  color: isPositive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

