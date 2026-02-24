import 'package:flutter/material.dart';

import 'package:youtube_player_flutter/youtube_player_flutter.dart';



class YoutubeVideoScreen extends StatefulWidget {

  final String videoUrl;

  final String title;



  const YoutubeVideoScreen({

    super.key,

    required this.videoUrl,

    required this.title,

  });



  @override

  State<YoutubeVideoScreen> createState() => _YoutubeVideoScreenState();

}



class _YoutubeVideoScreenState extends State<YoutubeVideoScreen> {

  late YoutubePlayerController _controller;



  @override

  void initState() {

    super.initState();

    final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl)!;

    _controller = YoutubePlayerController(

      initialVideoId: videoId,

      flags: const YoutubePlayerFlags(autoPlay: true, mute: false),

    );

  }



  @override

  void dispose() {

    _controller.dispose();

    super.dispose();

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(

        title: Text(

          widget.title,

          style: const TextStyle(fontWeight: FontWeight.bold),

        ),

        centerTitle: true,

        elevation: 0,

        backgroundColor: Colors.deepPurple,

      ),

      body: YoutubePlayerBuilder(

        player: YoutubePlayer(

          controller: _controller,

          showVideoProgressIndicator: true,

          progressIndicatorColor: Colors.deepPurpleAccent,

          progressColors: const ProgressBarColors(

            playedColor: Colors.deepPurple,

            handleColor: Colors.deepPurpleAccent,

          ),

        ),

        builder: (context, player) => SingleChildScrollView(

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              player,

              Container(

                width: double.infinity,

                padding: const EdgeInsets.all(20),

                decoration: const BoxDecoration(

                  color: Colors.white,

                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),

                  boxShadow: [

                    BoxShadow(

                      color: Colors.black12,

                      blurRadius: 8,

                      offset: Offset(0, -2),

                    ),

                  ],

                ),

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Text(

                      widget.title,

                      style: const TextStyle(

                        fontSize: 22,

                        fontWeight: FontWeight.bold,

                        color: Colors.black87,

                      ),

                    ),

                    const SizedBox(height: 12),

                    Row(

                      children: const [

                        Icon(Icons.visibility, color: Colors.grey, size: 20),

                        SizedBox(width: 6),

                        Text(

                          "1.2M views",

                          style: TextStyle(color: Colors.grey, fontSize: 14),

                        ),

                        SizedBox(width: 16),

                        Icon(Icons.thumb_up_alt_outlined,

                            color: Colors.grey, size: 20),

                        SizedBox(width: 6),

                        Text(

                          "24K likes",

                          style: TextStyle(color: Colors.grey, fontSize: 14),

                        ),

                      ],

                    ),

                    const SizedBox(height: 20),

                    const Divider(thickness: 1, color: Colors.grey),

                    const SizedBox(height: 12),

                    const Text(

                      "Description",

                      style: TextStyle(

                        fontSize: 18,

                        fontWeight: FontWeight.w600,

                        color: Colors.black87,

                      ),

                    ),

                    const SizedBox(height: 8),

                    const Text(

                      "Learn the fundamentals of cryptocurrency and blockchain technology in this video. Understand how digital currencies work and their impact on the financial world.",

                      style: TextStyle(

                        fontSize: 15,

                        color: Colors.black54,

                        height: 1.5,

                      ),

                    ),

                    const SizedBox(height: 24),

                    ElevatedButton.icon(

                      onPressed: () {},

                      icon: const Icon(Icons.quiz, color: Colors.white),

                      label: const Text(

                        "Take Related Quiz",

                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),

                      ),

                      style: ElevatedButton.styleFrom(

                        backgroundColor: Colors.deepPurple,

                        minimumSize: const Size(double.infinity, 50),

                        shape: RoundedRectangleBorder(

                          borderRadius: BorderRadius.circular(12),

                        ),

                      ),

                    ),

                  ],

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }

}