import 'package:flutter/material.dart';
import 'package:crypto_guide/airdrop_details_screen.dart';

class AirdropCard extends StatelessWidget {
  final String title, subtitle, reward, deadline;
  final String airdropId;

  const AirdropCard({
    super.key,
    required this.airdropId,
    required this.title,
    required this.subtitle,
    required this.reward,
    required this.deadline,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(subtitle, style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(reward,
                      style: const TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text("Deadline: $deadline", style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AirdropDetailsScreen(
                        airdropTitle: title,
                        airdropDocumentId: airdropId,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Participate",
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
