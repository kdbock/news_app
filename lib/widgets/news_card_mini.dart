import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:news_app/models/article.dart';
import 'package:news_app/widgets/webview_screen.dart';

class NewsCardMini extends StatelessWidget {
  final Article article;
  final VoidCallback? onTap;

  const NewsCardMini({super.key, required this.article, this.onTap});

  void _openArticle(BuildContext context) {
    if (onTap != null) {
      onTap!();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  WebViewScreen(url: article.url, title: article.title),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 2.0,
      child: InkWell(
        onTap: () => _openArticle(context),
        child: SizedBox(
          width: 160, // Fixed width for card
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Image - centered, fixed size
              SizedBox(
                height: 120,
                width: 160,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: article.imageUrl,
                    height: 120,
                    width: 160,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFd2982a),
                              strokeWidth: 2.0,
                            ),
                          ),
                        ),
                    errorWidget:
                        (context, url, error) => Image.asset(
                          'assets/images/Default.jpeg',
                          height: 120,
                          width: 160,
                          fit: BoxFit.cover,
                        ),
                  ),
                ),
              ),

              // Title in fixed height container
              Container(
                height: 60,
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      article.title,
                      style: const TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2d2c31),
                      ),
                      maxLines: 2,
                      textAlign: TextAlign.left,
                      overflow: TextOverflow.ellipsis,
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
