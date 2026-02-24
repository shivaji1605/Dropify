// --- lib/Learningscreen.dart ---

import 'package:crypto_guide/youtube_video_screen.dart';
import 'package:flutter/material.dart';
// --- MODIFICATION #1: Fixed import to 'quiz_page.dart' ---
import 'package:crypto_guide/quiz_page.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer';
import 'dart:async';

// ---------------- MAIN LEARNING SCREEN ----------------
class Learningscreen extends StatefulWidget {
  const Learningscreen({super.key});

  @override
  State<Learningscreen> createState() => _LearningscreenState();
}

class _LearningscreenState extends State<Learningscreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<User?>? _authSubscription;

  int _videosWatched = 0;
  final Set<String> _watchedVideoTitles = {};

  var quizList = [
    {
      "title": "Bitcoin Fundamentals",
      "level": "Beginner",
      "questions": 8,
      "description": "Test your knowledge of Bitcoin basics.",
      "progress": 0.0,
      "color": Colors.green,
      "badge": Icons.currency_bitcoin,
    },
    {
      "title": "Ethereum & Smart Contracts",
      "level": "Intermediate",
      "questions": 8,
      "description": "Learn about Ethereum and smart contracts.",
      "progress": 0.0,
      "color": Colors.orange,
      "badge": Icons.flash_on,
    },
    {
      "title": "Crypto Airdrops Explained",
      "level": "Beginner",
      "questions": 8,
      "description": "Learn what crypto airdrops are and why they exist.",
      "progress": 0.0,
      "color": Colors.blue,
      "badge": Icons.air,
    },
    {
      "title": "Popular Airdrops & Companies",
      "level": "Intermediate",
      "questions": 8,
      "description":
          "Identify well-known crypto companies that offer airdrops.",
      "progress": 0.0,
      "color": Colors.purple,
      "badge": Icons.business_center,
    },
    {
      "title": "DeFi & DEX Airdrops",
      "level": "Advanced",
      "questions": 8,
      "description": "Understand DeFi-based and DEX airdrop strategies.",
      "progress": 0.0,
      "color": Colors.teal,
      "badge": Icons.swap_horiz,
    },
    {
      "title": "Security in Airdrops",
      "level": "Intermediate",
      "questions": 8,
      "description": "Learn how to stay safe and identify scam airdrops.",
      "progress": 0.0,
      "color": Colors.redAccent,
      "badge": Icons.shield,
    },
  ];

  final Stream<QuerySnapshot> _videosStream = FirebaseFirestore.instance
      .collection('videos')
      .orderBy('order') 
      .snapshots();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _isLoading = true; 

    _authSubscription = _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        log("Learning Screen: Auth listener detected user ${user.uid}. Loading progress.");
        _loadLearningProgress(user.uid);
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _videosWatched = 0;
            _watchedVideoTitles.clear();
            var newQuizList = quizList.map((quiz) {
              var newQuiz = Map<String, Object>.from(quiz);
              newQuiz['progress'] = 0.0;
              return newQuiz;
            }).toList();
            quizList = newQuizList;
          });
        }
        log("Learning Screen: User logged out.");
      }
    });

    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      log("Learning Screen: User ${currentUser.uid} found on init. Loading progress.");
      _loadLearningProgress(currentUser.uid);
    }
  }

  Future<void> _loadLearningProgress(String userId) async {
    if (!_isLoading && mounted) {
      setState(() => _isLoading = true);
    }

    try {
      // --- 1. Load Quiz Data ---
      QuerySnapshot progressSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('quizProgress')
          .get();

      Map<String, double> quizUpdates = {};
      for (var doc in progressSnapshot.docs) {
        String quizTitle = doc.id;
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        double progress = (data?['progress'] as num?)?.toDouble() ?? 0.0;
        quizUpdates[quizTitle] = progress;
      }
      
      var newQuizList = quizList.map((quiz) {
        var newQuiz = Map<String, Object>.from(quiz);
        newQuiz['progress'] = quizUpdates[newQuiz['title']] ?? 0.0;
        return newQuiz;
      }).toList();

      // --- 2. Load Video Data ---
      QuerySnapshot videoSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('videoProgress')
          .get();
          
      final watchedTitles = <String>{};
      for (var doc in videoSnapshot.docs) {
        watchedTitles.add(doc.id);
      }

      // --- 3. Call setState ONCE with all new data ---
      if (mounted) {
        setState(() {
          quizList = newQuizList; 
          _watchedVideoTitles.clear();
          _watchedVideoTitles.addAll(watchedTitles);
          _videosWatched = _watchedVideoTitles.length;
          _isLoading = false; 
        });
        log("Quiz and Video progress loaded successfully. Videos: $_videosWatched");
      }
    } catch (e) {
      log("Error loading learning progress: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _saveQuizProgress(String quizTitle, double progress) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('quizProgress')
          .doc(quizTitle)
          .set({
        'progress': progress,
        'lastAttempted': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      log("Quiz progress saved for $quizTitle");
    } catch (e) {
      log("Error saving quiz progress for $quizTitle: $e");
    }
  }

  Future<void> _saveVideoProgress(String videoTitle) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      log("User not logged in, cannot save video progress.");
      return;
    }

    if (_watchedVideoTitles.contains(videoTitle)) {
      log("Video '$videoTitle' already watched.");
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('videoProgress')
          .doc(videoTitle)
          .set({
        'watched': true,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() {
          _watchedVideoTitles.add(videoTitle);
          _videosWatched = _watchedVideoTitles.length;
        });
      }
      log("Video progress saved for $videoTitle");
    } catch (e) {
      log("Error saving video progress for $videoTitle: $e");
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _authSubscription?.cancel();
    super.dispose();
  }

  double get overallProgress {
    if (quizList.isEmpty) return 0.0;
    double sum =
        quizList.fold(0.0, (prev, q) => prev + (q['progress'] as double));
    return sum / quizList.length;
  }

  // ---------------- QUIZ SECTION ----------------
  Widget buildQuizSection() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: quizList.length,
      itemBuilder: (context, index) {
        final quiz = quizList[index];
        return InkWell(
          onTap: () async {
            if (_isLoading) return;

            final double? result = await Navigator.push<double>(
              context,
              MaterialPageRoute(
                  builder: (_) => QuizPage(topic: quiz['title'] as String)),
            );
            
            // --- THIS IS THE CORRECTED LOGIC ---
            if (result != null) {
              double clampedResult = result.clamp(0.0, 1.0);
              
              setState(() {
                // Directly modify the list item inside setState
                // This forces Flutter to see the change.
                quizList[index]['progress'] = clampedResult;
                log("QUIZ COMPLETE: Rebuilding UI with updated progress."); 
              });
              
              await _saveQuizProgress(quiz['title'] as String, clampedResult);
            }
          },
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 15),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: (quiz['color'] as Color).withOpacity(
                          0.12,
                        ),
                        child: Icon(quiz['badge'] as IconData,
                            color: quiz['color'] as Color),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          quiz['title'] as String,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: (quiz['color'] as Color).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          quiz['level'] as String,
                          style: TextStyle(
                            color: quiz['color'] as Color,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "${quiz['questions']} questions",
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    quiz['description'] as String,
                    style: const TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: (quiz['progress'] as double).clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(quiz['color'] as Color),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "${((quiz['progress'] as double).clamp(0.0, 1.0) * 100).toInt()}% Completed",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------- VIDEO SECTION ----------------
  Widget buildVideoSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _videosStream,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          log("Error loading videos: ${snapshot.error}");
          return const Center(child: Text("Could not load videos."));
        }
        if (snapshot.connectionState == ConnectionState.waiting || _isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No videos available yet. Check back soon!"));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          itemBuilder: (context, index) {
            DocumentSnapshot document = snapshot.data!.docs[index];
            Map<String, dynamic> video = document.data()! as Map<String, dynamic>;

            final String videoTitle = video['title'] ?? 'No Title';
            final String videoUrl = video['url'] ?? '';
            final String thumbnailUrl = video['thumbnail'] ?? ''; 

            final bool isWatched = _watchedVideoTitles.contains(videoTitle);

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 4,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  _saveVideoProgress(videoTitle);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => YoutubeVideoScreen(
                        videoUrl: videoUrl,
                        title: videoTitle,
                      ),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        thumbnailUrl.isEmpty
                          ? Container( 
                              height: 180,
                              color: Colors.grey[300],
                              alignment: Alignment.center,
                              child: Icon(Icons.videocam_off, color: Colors.grey[600], size: 40),
                            )
                          : Image.network(
                              thumbnailUrl,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const SizedBox(
                                  height: 180,
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 180,
                                  color: Colors.grey[300],
                                  alignment: Alignment.center,
                                  child: Icon(Icons.broken_image, color: Colors.grey[600], size: 40),
                                );
                              },
                            ),
                        
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.play_circle_outline,
                          color: Colors.white.withOpacity(0.9),
                          size: 60,
                        ),
                        if (isWatched)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.8),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, color: Colors.white, size: 20),
                            ),
                          ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                        Colors.white,
                        Colors.white.withOpacity(0.9),
                        Colors.white.withOpacity(0.7)
                      ], begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: const [
                        0.0,
                        0.7,
                        1.0
                      ])),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                            12.0, 12.0, 12.0, 16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                videoTitle,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  // --- END OF VIDEO SECTION ---

  // --- ACHIEVEMENTS SECTION ---
  Widget buildAchievementsSection() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final int quizzesCompleted =
        quizList.where((q) => (q['progress'] as double) > 0.0).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 25),
          const Text(
            "Your Achievements",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 180,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                achievementCard(
                  title: "First Steps",
                  description: "Complete your first quiz",
                  unlockedDate: quizzesCompleted >= 1
                      ? "Unlocked" 
                      : "Locked",
                  icon: Icons.star,
                  color: Colors.orange,
                  unlocked: quizzesCompleted >= 1,
                ),
                achievementCard(
                  title: "Knowledge Seeker",
                  description: "Watch 5 educational videos",
                  unlockedDate: _videosWatched >= 5 ? "Unlocked" : "Locked",
                  icon: Icons.school,
                  color: Colors.indigo,
                  unlocked: _videosWatched >= 5,
                ),
                achievementCard(
                  title: "Quiz Explorer",
                  description: "Complete 3 different quizzes",
                  unlockedDate: quizzesCompleted >= 3 ? "Unlocked" : "Locked",
                  icon: Icons.emoji_events,
                  color: Colors.green,
                  unlocked: quizzesCompleted >= 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          const Text(
            "Achievement Progress",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "🧩 Complete 6 quizzes",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
              Text(
                "$quizzesCompleted/6",
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (quizzesCompleted.clamp(0, 6) / 6).toDouble(),
              minHeight: 8,
              color: Colors.blueAccent,
              backgroundColor: const Color(0xFFE0E0E0),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "🎥 Watch 5 videos",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
              Text(
                "$_videosWatched/5",
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_videosWatched.clamp(0, 5) / 5).toDouble(),
              minHeight: 8,
              color: Colors.purpleAccent,
              backgroundColor: const Color(0xFFE0E0E0),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget achievementCard({
    required String title,
    required String description,
    required String unlockedDate,
    required IconData icon,
    required Color color,
    required bool unlocked,
  }) {
    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: unlocked ? color.withOpacity(0.08) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: unlocked ? color : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: unlocked ? color : Colors.grey, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: unlocked ? Colors.black : Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Text(description, style: const TextStyle(color: Colors.black54)),
          const Spacer(),
          Text(
            unlockedDate,
            style: TextStyle(
              fontSize: 12,
              color: unlocked ? color : Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- MAIN BUILD (Unchanged) ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Learning Dashboard",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.indigoAccent,
          labelColor: Colors.indigo,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Videos'),
            Tab(text: 'Quizzes'),
            Tab(text: 'Achievements'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            height: 140,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 24, 82, 129),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.school, color: Colors.white, size: 24),
                      SizedBox(width: 10),
                      Text(
                        "Learning Journey",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: overallProgress.clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation(
                        Colors.lightBlueAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${(overallProgress * 100).toStringAsFixed(0)}% Completed",
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                buildVideoSection(),
                buildQuizSection(),
                buildAchievementsSection(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_learning',
        onPressed: () => _tabController.animateTo(1),
        icon: const Icon(Icons.flash_on),
        label: const Text("Quick Quiz"),
        backgroundColor: Colors.amber,
      ),
    );
  }
}

// --- MODIFICATION #2: The duplicate QuizResultPage class has been DELETED from this file ---