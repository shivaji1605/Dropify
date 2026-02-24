// --- lib/quiz_page.dart ---
// This file defines BOTH QuizPage and QuizResultPage.

import 'package:flutter/material.dart';

class QuizPage extends StatefulWidget {
  final String topic;
  const QuizPage({super.key, required this.topic});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int currentQuestion = 0;
  int correct = 0;
  int wrong = 0;
  String? selectedAnswer;
  bool isAnswered = false;

  late final List<Map<String, Object>> questions;

  @override
  void initState() {
    super.initState();
    questions = _getQuestionsForTopic(widget.topic);
  }

  // Each topic has 8 unique questions (answers are strings)
  List<Map<String, Object>> _getQuestionsForTopic(String topic) {
    switch (topic) {
      case "Bitcoin Fundamentals":
        return [
          {
            "question": "Who created Bitcoin?",
            "options": [
              "Satoshi Nakamoto",
              "Vitalik Buterin",
              "Elon Musk",
              "Bill Gates",
            ],
            "answer": "Satoshi Nakamoto",
          },
          {
            "question": "What is the maximum supply of Bitcoin?",
            "options": ["21 million", "100 million", "50 million", "Unlimited"],
            "answer": "21 million",
          },
          {
            "question": "Which technology does Bitcoin use?",
            "options": ["Blockchain", "Cloud computing", "AI", "IoT"],
            "answer": "Blockchain",
          },
          {
            "question": "Bitcoin transactions are verified by?",
            "options": ["Miners", "Banks", "Governments", "Users"],
            "answer": "Miners",
          },
          {
            "question": "What is Bitcoin's unit?",
            "options": ["BTC", "ETH", "XRP", "LTC"],
            "answer": "BTC",
          },
          {
            "question": "How often is a new block found on average?",
            "options": ["10 minutes", "1 minute", "1 hour", "24 hours"],
            "answer": "10 minutes",
          },
          {
            "question": "Which hashing algorithm does Bitcoin primarily use?",
            "options": ["SHA-256", "Scrypt", "MD5", "Blake2"],
            "answer": "SHA-256",
          },
          {
            "question": "What is a Bitcoin wallet?",
            "options": [
              "Software to store keys",
              "Bank account",
              "Mining hardware",
              "Exchange",
            ],
            "answer": "Software to store keys",
          },
        ];

      case "Ethereum & Smart Contracts":
        return [
          {
            "question": "Who co-founded Ethereum?",
            "options": [
              "Vitalik Buterin",
              "Satoshi Nakamoto",
              "Elon Musk",
              "Charlie Lee",
            ],
            "answer": "Vitalik Buterin",
          },
          {
            "question": "What is Ethereum's native token symbol?",
            "options": ["ETH", "ETC", "EVM", "ETHR"],
            "answer": "ETH",
          },
          {
            "question": "What do smart contracts do?",
            "options": [
              "Self-execute code on blockchain",
              "Create PDFs",
              "Host websites",
              "Store email",
            ],
            "answer": "Self-execute code on blockchain",
          },
          {
            "question": "Which language is most used for Ethereum contracts?",
            "options": ["Solidity", "Python", "C++", "Rust"],
            "answer": "Solidity",
          },
          {
            "question": "What is 'gas' in Ethereum?",
            "options": [
              "Fee for transactions",
              "Storage type",
              "Consensus",
              "Token",
            ],
            "answer": "Fee for transactions",
          },
          {
            "question": "Which virtual machine executes Ethereum contracts?",
            "options": ["EVM", "JVM", "WASM", "LLVM"],
            "answer": "EVM",
          },
          {
            "question":
                "Ethereum moved to which consensus to reduce energy usage?",
            "options": [
              "Proof of Stake",
              "Proof of Work",
              "Delegated PoS",
              "PoA",
            ],
            "answer": "Proof of Stake",
          },
          {
            "question": "What can be built on Ethereum?",
            "options": ["dApps", "Only wallets", "Only exchanges", "Only NFTs"],
            "answer": "dApps",
          },
        ];

      case "Crypto Airdrops Explained":
        return [
          {
            "question": "What is a crypto airdrop?",
            "options": [
              "Free tokens distributed to users",
              "Paid token sale",
              "Token burn",
              "Exchange fee",
            ],
            "answer": "Free tokens distributed to users",
          },
          {
            "question": "Why do projects do airdrops?",
            "options": [
              "Marketing & adoption",
              "To close the project",
              "To mine coins",
              "To freeze assets",
            ],
            "answer": "Marketing & adoption",
          },
          {
            "question": "Who might be eligible for an airdrop?",
            "options": [
              "Existing token holders",
              "Only miners",
              "Only banks",
              "Only exchanges",
            ],
            "answer": "Existing token holders",
          },
          {
            "question": "How are airdrops usually delivered?",
            "options": [
              "To wallet addresses",
              "By email only",
              "By bank transfer",
              "By physical mail",
            ],
            "answer": "To wallet addresses",
          },
          {
            "question": "Airdrops often require?",
            "options": [
              "Simple tasks (follow/share)",
              "High fees",
              "Hardware",
              "Bank account",
            ],
            "answer": "Simple tasks (follow/share)",
          },
          {
            "question": "Are all airdrops legitimate?",
            "options": [
              "No, some are scams",
              "Yes, all are safe",
              "Always paid",
              "Never used",
            ],
            "answer": "No, some are scams",
          },
          {
            "question": "What is a snapshot in airdrop terms?",
            "options": [
              "Record of wallet balances at a time",
              "A photo",
              "A tweet",
              "A video",
            ],
            "answer": "Record of wallet balances at a time",
          },
          {
            "question": "Airdrops help projects to?",
            "options": [
              "Grow community",
              "Reduce users",
              "Hide tokens",
              "Avoid regulations",
            ],
            "answer": "Grow community",
          },
        ];

      case "Popular Airdrops & Companies":
        return [
          {
            "question": "Which DEX airdropped UNI tokens?",
            "options": ["Uniswap", "Coinbase", "Binance", "Kraken"],
            "answer": "Uniswap",
          },
          {
            "question": "Which airdrop token is named ARB?",
            "options": ["Arbitrum", "Avalanche", "Algorand", "Aave"],
            "answer": "Arbitrum",
          },
          {
            "question": "ENS airdrop rewarded which users?",
            "options": ["Name holders", "Miners", "Stakers", "Developers"],
            "answer": "Name holders",
          },
          {
            "question": "Which wallet hinted at a potential airdrop (example)?",
            "options": ["MetaMask", "PayPal", "Bank of X", "Chrome"],
            "answer": "MetaMask",
          },
          {
            "question": "Airdrops are often announced via?",
            "options": [
              "Social media",
              "TV only",
              "Bank letters",
              "Local papers",
            ],
            "answer": "Social media",
          },
          {
            "question": "Compound distributed which token initially?",
            "options": ["COMP", "UNI", "AAVE", "SUSHI"],
            "answer": "COMP",
          },
          {
            "question":
                "Which protocol rewarded early L2 users with OP tokens?",
            "options": ["Optimism", "Uniswap", "Aave", "Curve"],
            "answer": "Optimism",
          },
          {
            "question": "Airdrops typically attract?",
            "options": [
              "New users and attention",
              "Only banks",
              "Only government",
              "Telecoms",
            ],
            "answer": "New users and attention",
          },
        ];

      case "DeFi & DEX Airdrops":
        return [
          {
            "question": "What does DeFi mean?",
            "options": [
              "Decentralized Finance",
              "Defined Funds",
              "Direct Finance",
              "Distributed Files",
            ],
            "answer": "Decentralized Finance",
          },
          {
            "question": "What does DEX stand for?",
            "options": [
              "Decentralized Exchange",
              "Data Exchange",
              "Digital EXchange",
              "Direct Exchange",
            ],
            "answer": "Decentralized Exchange",
          },
          {
            "question": "DEXs allow trading without?",
            "options": [
              "Central intermediaries",
              "Tokens",
              "Cryptography",
              "Gas",
            ],
            "answer": "Central intermediaries",
          },
          {
            "question": "DeFi airdrops often reward?",
            "options": [
              "Liquidity providers",
              "Only developers",
              "Only exchanges",
              "Only miners",
            ],
            "answer": "Liquidity providers",
          },
          {
            "question": "Which chain hosts PancakeSwap?",
            "options": ["BNB Chain", "Ethereum", "Solana", "Cardano"],
            "answer": "BNB Chain",
          },
          {
            "question": "Curve token is called?",
            "options": ["CRV", "CVX", "CRO", "CRP"],
            "answer": "CRV",
          },
          {
            "question": "DeFi airdrops aim to?",
            "options": [
              "Incentivize users",
              "Hide tokens",
              "Burn tokens",
              "Avoid taxes",
            ],
            "answer": "Incentivize users",
          },
          {
            "question": "Example of DEX is?",
            "options": ["Uniswap", "Coinbase", "Robinhood", "PayPal"],
            "answer": "Uniswap",
          },
        ];

      case "Security in Airdrops":
        return [
          {
            "question": "What is a scam airdrop?",
            "options": [
              "Fake token drop to steal funds",
              "Official giveaway",
              "Charity",
              "Software update",
            ],
            "answer": "Fake token drop to steal funds",
          },
          {
            "question": "Never share?",
            "options": [
              "Private keys",
              "Public address",
              "Twitter handle",
              "Email",
            ],
            "answer": "Private keys",
          },
          {
            "question": "Verify airdrop via?",
            "options": [
              "Official channels",
              "Random DMs",
              "Unknown sites",
              "SMS only",
            ],
            "answer": "Official channels",
          },
          {
            "question": "Suspicious airdrops may request?",
            "options": [
              "Signing malicious transactions",
              "Watching videos",
              "Following socials",
              "Joining groups",
            ],
            "answer": "Signing malicious transactions",
          },
          {
            "question": "Use which wallets for safety?",
            "options": [
              "Non-custodial secure wallets",
              "Unknown apps",
              "Bank accounts",
              "Shared wallets",
            ],
            "answer": "Non-custodial secure wallets",
          },
          {
            "question": "Avoid clicking?",
            "options": [
              "Unknown links",
              "Official docs",
              "Verified sites",
              "Exchange pages",
            ],
            "answer": "Unknown links",
          },
          {
            "question": "Legit airdrops never ask for?",
            "options": [
              "Private keys",
              "Public address",
              "Handle",
              "Social follow",
            ],
            "answer": "Private keys",
          },
          {
            "question": "Security awareness helps you?",
            "options": [
              "Avoid scams",
              "Get free tokens always",
              "Mine faster",
              "Hack others",
            ],
            "answer": "Avoid scams",
          },
        ];

      default:
        return <Map<String, Object>>[];
    }
  }

  void onOptionSelected(String option) {
    if (isAnswered) return;

    final correctAnswer = questions[currentQuestion]['answer'] as String;
    setState(() {
      selectedAnswer = option;
      isAnswered = true;

      // increment counters
      if (option == correctAnswer) {
        correct++;
      } else {
        wrong++;
      }
    });

    // short delay to show highlight, then move to next or show result
    Future.delayed(const Duration(milliseconds: 700), () {
      if (currentQuestion < questions.length - 1) {
        setState(() {
          currentQuestion++;
          selectedAnswer = null;
          isAnswered = false;
        });
      } else {
        final double percent =
            questions.isEmpty ? 0.0 : correct / questions.length;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => QuizResultPage(
              topic: widget.topic,
              total: questions.length,
              correct: correct,
              wrong: wrong,
              percent: percent,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.topic)),
        body: const Center(child: Text("No questions available for this topic.")),
      );
    }

    final q = questions[currentQuestion];
    final options = (q['options'] as List<String>);

    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        title: Text(widget.topic),
        backgroundColor: Colors.indigo,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (currentQuestion + 1) / questions.length,
              color: Colors.amber,
              backgroundColor: Colors.white24,
              minHeight: 8,
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo.shade400, Colors.blue.shade300],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    "Question ${currentQuestion + 1}/${questions.length}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    q['question'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Options
            ...options.map((opt) {
              // color logic to highlight correct/incorrect after answer
              Color borderColor = Colors.grey.shade300;
              Color fillColor = Colors.white;
              Color textColor = Colors.black87;

              if (isAnswered) {
                final correctAnswer = q['answer'] as String;
                if (opt == correctAnswer) {
                  borderColor = Colors.green;
                  fillColor = Colors.green.shade100;
                } else if (opt == selectedAnswer &&
                    selectedAnswer != correctAnswer) {
                  borderColor = Colors.red;
                  fillColor = Colors.red.shade100;
                }
              } else if (selectedAnswer == opt) {
                borderColor = Colors.indigo;
                fillColor = Colors.indigo.shade50;
              }

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: 2),
                ),
                child: ListTile(
                  title: Text(opt, style: TextStyle(color: textColor)),
                  onTap: () => onOptionSelected(opt),
                ),
              );
            }).toList(),

            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "✅ Correct: $correct",
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "❌ Wrong: $wrong",
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- THIS IS THE CORRECT, SINGLE LOCATION FOR THIS CLASS ---
class QuizResultPage extends StatelessWidget {
  final String topic;
  final int total;
  final int correct;
  final int wrong;
  final double percent;

  const QuizResultPage({
    super.key,
    required this.topic,
    required this.total,
    required this.correct,
    required this.wrong,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPassed = percent >= 0.5;
    final Color mainColor = isPassed ? Colors.green : Colors.redAccent;

    return Scaffold(
      appBar: AppBar(
        title: Text("$topic - Results"),
        backgroundColor: Colors.indigo,
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Colors.indigo.shade50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPassed ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                  size: 80,
                  color: mainColor,
                ),
                const SizedBox(height: 16),
                Text(
                  isPassed ? "Congratulations!" : "Keep Practicing!",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: mainColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "You completed the quiz on $topic",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54, fontSize: 16),
                ),
                const SizedBox(height: 18),
                Text(
                  "Score: $correct / $total",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: percent,
                        strokeWidth: 10,
                        color: mainColor,
                        backgroundColor: Colors.grey.shade200,
                      ),
                      Text(
                        "${(percent * 100).toStringAsFixed(0)}%",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: mainColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    // This now pops back to Learningscreen and returns the percentage
                    Navigator.pop(context, percent);
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text("Back to Learning"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => QuizPage(topic: topic)),
                    );
                  },
                  icon: const Icon(Icons.refresh, color: Colors.indigo),
                  label: const Text(
                    "Retry Quiz",
                    style: TextStyle(color: Colors.indigo),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.indigo),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}