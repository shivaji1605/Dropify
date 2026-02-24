import 'package:flutter/material.dart';

// This dialog function now "belongs" to the NewsCard
void _showNewsDetailsDialog(
    BuildContext context, String title, String imageUrl, String fullArticle) {
  Widget networkImageWidget;
  if (imageUrl.isNotEmpty && Uri.parse(imageUrl).isAbsolute) {
    networkImageWidget = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        height: 150,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 150,
            color: Colors.grey[200],
            alignment: Alignment.center,
            child: Icon(Icons.broken_image, color: Colors.grey[400], size: 50),
          );
        },
      ),
    );
  } else {
    networkImageWidget = const SizedBox.shrink();
  }

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                networkImageWidget,
                const SizedBox(height: 16),
                Text(fullArticle),
              ],
            ),
          ),
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

// This is the same NewsCard widget, now in its own file
class NewsCard extends StatelessWidget {
  final String imageUrl, title, subtitle, fullArticle;
  const NewsCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    this.fullArticle = "No additional details available.",
  });

  @override
  Widget build(BuildContext context) {
    Widget networkImageWidget;
    if (imageUrl.isNotEmpty && Uri.parse(imageUrl).isAbsolute) {
      networkImageWidget = Image.network(
        imageUrl,
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 150,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 150,
            color: Colors.grey[200],
            alignment: Alignment.center,
            child: Icon(Icons.broken_image, color: Colors.grey[400], size: 50),
          );
        },
      );
    } else {
      networkImageWidget = Container(
        height: 150,
        color: Colors.grey[200],
        alignment: Alignment.center,
        child: Icon(Icons.image_not_supported, color: Colors.grey[400], size: 50),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // It can now call the private dialog function
          _showNewsDetailsDialog(context, title, imageUrl, fullArticle);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            networkImageWidget,
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[700])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
