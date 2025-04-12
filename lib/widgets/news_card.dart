import 'package:flutter/material.dart';
import 'package:neusenews/models/article.dart';
import 'package:neusenews/repositories/bookmarks_repository.dart';
import 'package:provider/provider.dart';

class NewsCard extends StatelessWidget {
  final Article article;
  final VoidCallback onReadMore;
  final bool showBookmarkButton;
  final String? sourceTag; // Add the missing parameter
  
  const NewsCard({
    super.key,
    required this.article,
    required this.onReadMore,
    this.showBookmarkButton = false,
    this.sourceTag, // Add parameter with default value of null
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Article image
          if (article.imageUrl.isNotEmpty)
            Image.network(
              article.imageUrl,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 180,
                color: Colors.grey[300],
                child: const Icon(Icons.image_not_supported, size: 50),
              ),
            ),
          
          // Source tag chip (if provided)
          if (sourceTag != null)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 16.0, right: 16.0, bottom: 0),
              child: Chip(
                label: Text(
                  sourceTag!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: const Color(0xFFd2982a),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
          
          // Article content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  article.excerpt,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                
                // Action row with bookmark button (if enabled)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'By ${article.author}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    
                    // Show bookmark button if requested
                    if (showBookmarkButton)
                      Consumer<BookmarksRepository>(
                        builder: (context, repo, _) {
                          final isBookmarked = repo.isBookmarked(article.id);
                          return IconButton(
                            icon: Icon(
                              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                              color: isBookmarked ? const Color(0xFFd2982a) : Colors.grey,
                            ),
                            onPressed: () => repo.toggleBookmark(article),
                          );
                        },
                      ),
                    
                    // Read more button
                    TextButton(
                      onPressed: onReadMore,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFd2982a),
                      ),
                      child: const Text('READ MORE'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
