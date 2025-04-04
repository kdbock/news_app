import 'package:flutter/material.dart';
import 'package:neusenews/constants/app_config.dart';
import 'package:neusenews/models/article.dart';
import 'package:neusenews/models/event.dart';
import 'package:neusenews/widgets/webview_screen.dart';
import 'package:neusenews/features/news/screens/news_screen.dart';
import 'package:url_launcher/url_launcher.dart';

// Features imports using aliases for clarity
import 'package:neusenews/features/weather/screens/weather_screen.dart'
    as weather;
import 'package:neusenews/features/news/screens/local_news_screen.dart'
    as local_news;
import 'package:neusenews/features/news/screens/sports_screen.dart' as sports;
import 'package:neusenews/features/news/screens/politics_screen.dart'
    as politics;
import 'package:neusenews/features/news/screens/obituaries_screen.dart'
    as obituaries;
import 'package:neusenews/features/news/screens/columns_screen.dart' as columns;
import 'package:neusenews/features/news/screens/public_notices_screen.dart'
    as public_notices;
import 'package:neusenews/features/news/screens/classifieds_screen.dart'
    as classifieds;
import 'package:neusenews/features/events/screens/calendar_screen.dart'
    as calendar;

class NavigatorService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static NavigatorState? get navigator => navigatorKey.currentState;

  // Base navigation method with proper mounted checks
  static Future<T?> navigateTo<T>(BuildContext context, Widget screen) {
    if (!context.mounted) return Future.value(null);
    return Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  // Article navigation
  static void openArticle(BuildContext context, Article article) {
    if (!context.mounted) return;
    Navigator.pushNamed(context, '/article', arguments: article);
  }

  // Category navigation
  static void navigateToCategory(BuildContext context, String category) {
    if (!context.mounted) return;

    switch (category) {
      case 'localnews':
        navigateTo(context, const local_news.LocalNewsScreen());
        break;
      case 'sports':
        navigateTo(context, const sports.SportsScreen());
        break;
      case 'politics':
        navigateTo(context, const politics.PoliticsScreen());
        break;
      case 'columns':
        navigateTo(context, const columns.ColumnsScreen());
        break;
      case 'classifieds':
        navigateTo(context, const classifieds.ClassifiedsScreen());
        break;
      case 'obituaries':
        navigateTo(context, const obituaries.ObituariesScreen());
        break;
      case 'publicnotices':
        navigateTo(context, const public_notices.PublicNoticesScreen());
        break;
      case 'weather':
        navigateTo(context, const weather.WeatherScreen());
        break;
      case 'calendar':
        navigateTo(context, const calendar.CalendarScreen());
        break;
      default:
        // Generic RSS feed screen
        final feedUrl =
            AppConfig.rssFeedUrls[category] ?? AppConfig.rssFeedUrls['main']!;
        navigateTo(context, NewsScreen(sources: [feedUrl], title: category));
    }
  }

  // Combined news feed navigation
  static void navigateToCombinedNewsFeed(BuildContext context) {
    if (!context.mounted) return;

    // Fix 1: Remove const keyword and ensure non-null values
    final sources = [
      AppConfig.rssFeedUrls['main'] ??
          'https://www.neusenews.com/index?format=rss',
      AppConfig.rssFeedUrls['sports'] ??
          'https://www.neusenewssports.com/news-1?format=rss',
      AppConfig.rssFeedUrls['politics'] ??
          'https://www.ncpoliticalnews.com/news?format=rss',
    ];

    navigateTo(context, NewsScreen(sources: sources, title: 'News'));
  }

  // Event details navigation
  static void showEventDetails(BuildContext context, Event event) {
    if (!context.mounted) return;
    navigateTo(context, calendar.CalendarScreen(selectedDate: event.eventDate));
  }

  // Web view navigation
  static void openWebView(BuildContext context, String url, String title) {
    if (!context.mounted) return;
    navigateTo(context, WebViewScreen(url: url, title: title));
  }

  // External URL navigation with fallback
  static Future<void> openExternalUrl(BuildContext context, String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open $url')));
      }
    }
  }
}
