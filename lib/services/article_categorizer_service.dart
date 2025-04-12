import 'package:neusenews/models/article.dart';
import 'package:flutter/foundation.dart';

class ArticleCategorizerService {
  // Keywords for different categories
  final Map<String, List<String>> _categoryKeywords = {
    'politics': [
      'election', 'vote', 'president', 'government', 'senate', 'congress',
      'democrat', 'republican', 'policy', 'legislation', 'law', 'political',
      'governor', 'mayor', 'candidate', 'campaign', 'ballot', 'polling',
      'administration', 'official', 'representative'
    ],
    'sports': [
      'game', 'team', 'player', 'score', 'win', 'lose', 'championship',
      'tournament', 'coach', 'athlete', 'football', 'baseball', 'basketball',
      'soccer', 'hockey', 'match', 'victory', 'defeat', 'season', 'sport',
      'league', 'playoff', 'final', 'compete', 'stadium'
    ],
    'business': [
      'market', 'stock', 'economy', 'company', 'corporation', 'business',
      'investor', 'profit', 'revenue', 'industry', 'ceo', 'finance', 'trade',
      'invest', 'startup', 'money', 'economic', 'commercial', 'venture',
      'enterprise', 'entrepreneur', 'dollar'
    ],
    'technology': [
      'tech', 'software', 'hardware', 'app', 'digital', 'internet', 'web',
      'computer', 'mobile', 'device', 'innovation', 'startup', 'developer',
      'programming', 'ai', 'artificial intelligence', 'data', 'code',
      'robot', 'virtual', 'cyber', 'smartphone', 'gadget'
    ],
    'health': [
      'doctor', 'patient', 'hospital', 'medical', 'health', 'disease',
      'treatment', 'medicine', 'vaccine', 'cure', 'symptom', 'illness',
      'healthcare', 'pandemic', 'virus', 'research', 'physician',
      'clinic', 'therapy', 'wellness', 'prescription'
    ],
    'entertainment': [
      'movie', 'film', 'tv', 'show', 'actor', 'actress', 'celebrity',
      'music', 'concert', 'album', 'song', 'star', 'entertainment',
      'hollywood', 'award', 'director', 'singer', 'performance',
      'theater', 'festival', 'streaming', 'television'
    ],
    'environment': [
      'climate', 'environment', 'earth', 'green', 'sustainable', 'eco',
      'nature', 'pollution', 'carbon', 'renewable', 'conservation',
      'wildlife', 'forest', 'ocean', 'planet', 'energy', 'fossil',
      'recycle', 'emission', 'global warming'
    ],
    'education': [
      'school', 'student', 'teacher', 'learn', 'education', 'university',
      'college', 'campus', 'class', 'course', 'professor', 'academic',
      'degree', 'study', 'research', 'curriculum', 'faculty', 'graduate',
      'tuition', 'scholarship', 'classroom'
    ],
    'crime': [
      'crime', 'police', 'criminal', 'arrest', 'law', 'investigation', 'case',
      'court', 'trial', 'judge', 'justice', 'prison', 'jail', 'sentence',
      'robbery', 'theft', 'murder', 'assault', 'fraud', 'victim', 'suspect'
    ],
    'obituaries': [
      'death', 'died', 'obituary', 'funeral', 'memorial', 'passed away',
      'remembered', 'survived by', 'life', 'legacy', 'tribute',
      'deceased', 'cemetery', 'service', 'condolence'
    ]
  };
  
  // Singleton pattern
  static final ArticleCategorizerService _instance = ArticleCategorizerService._internal();
  
  factory ArticleCategorizerService() => _instance;
  
  ArticleCategorizerService._internal();

  // Main method for categorizing articles
  Future<Map<String, double>> categorizeArticle(Article article) async {
    try {
      // Try to use external ML API if available
      final result = await _categorizeWithMlApi(article);
      if (result.isNotEmpty) {
        return result;
      }
    } catch (e) {
      debugPrint('Error using ML API for categorization: $e');
    }
    
    // Fall back to keyword-based categorization
    return _categorizeWithKeywords(article);
  }
  
  // Use an external ML API for categorization (simulated here)
  Future<Map<String, double>> _categorizeWithMlApi(Article article) async {
    try {
      // This would be replaced with a real ML API endpoint
      final String mlApiUrl = 'https://api.example.com/ml/categorize';
      
      // For now, just simulate calling an API by returning immediately
      // In a real implementation, you'd make an HTTP request to your ML service
      return {}; // Empty map means fallback to keyword-based approach
      
      /*
      // Code for actual API call when you have an ML service:
      final response = await http.post(
        Uri.parse(mlApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer YOUR_API_KEY',
        },
        body: jsonEncode({
          'title': article.title,
          'content': article.content,
          'excerpt': article.excerpt,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Map<String, double>.from(data['categories']);
      }
      */
    } catch (e) {
      debugPrint('Error in ML API categorization: $e');
      return {};
    }
  }
  
  // Keyword-based categorization as a fallback
  Map<String, double> _categorizeWithKeywords(Article article) {
    // Combine all text from the article
    final String text = '${article.title} ${article.excerpt} ${article.content}'.toLowerCase();
    
    Map<String, double> scores = {};
    
    // Calculate score for each category
    _categoryKeywords.forEach((category, keywords) {
      double score = 0;
      
      for (final keyword in keywords) {
        // Count occurrences of the keyword
        final RegExp regExp = RegExp(r'\b' + keyword.toLowerCase() + r'\b');
        final matches = regExp.allMatches(text);
        
        // Add to score, with higher weight for title matches
        score += matches.length * 1.0;
        
        // Check title specifically with higher weight
        if (article.title.toLowerCase().contains(keyword.toLowerCase())) {
          score += 3.0;
        }
      }
      
      // Normalize the score based on text length
      final wordCount = text.split(' ').length;
      if (wordCount > 0) {
        score = score / (wordCount / 100); // Score per 100 words
      }
      
      // Only include categories with non-zero scores
      if (score > 0) {
        scores[category] = score;
      }
    });
    
    // Normalize scores to add up to 1.0
    if (scores.isNotEmpty) {
      double totalScore = scores.values.reduce((a, b) => a + b);
      if (totalScore > 0) {
        scores.forEach((key, value) {
          scores[key] = value / totalScore;
        });
      }
    }
    
    return scores;
  }
  
  // Get primary category
  String getPrimaryCategory(Article article) {
    final categories = _categorizeWithKeywords(article);
    if (categories.isEmpty) return 'General';
    
    return categories.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
  
  // Get top N categories
  List<MapEntry<String, double>> getTopCategories(Article article, {int count = 3}) {
    final categories = _categorizeWithKeywords(article);
    final List<MapEntry<String, double>> entries = categories.entries.toList();
    
    // Sort by score in descending order
    entries.sort((a, b) => b.value.compareTo(a.value));
    
    // Return top N or all if less than N
    return entries.take(count).toList();
  }
}