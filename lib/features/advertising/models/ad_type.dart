enum AdType {
  titleSponsor, // 0 - Banner at the top of the homepage
  bannerAd, // 1 - Banner ad in various sections
  inFeedNews, // 2 - Ad within category-specific news feeds
  weather, // 3 - Sponsor banner in the weather section
  inFeedDashboard, // 4 - Ad within the main dashboard feed
}

extension AdTypeExtension on AdType {
  String get displayName {
    switch (this) {
      case AdType.titleSponsor:
        return 'Title Sponsor';
      case AdType.inFeedDashboard:
        return 'In-Feed Dashboard Ad';
      case AdType.inFeedNews:
        return 'In-Feed News Ad';
      case AdType.weather:
        return 'Weather Sponsor';
      case AdType.bannerAd:
        return 'Banner Ad';
    }
  }

  double get weeklyRate {
    switch (this) {
      case AdType.titleSponsor:
        return 249.0;
      case AdType.inFeedDashboard:
        return 149.0;
      case AdType.inFeedNews:
        return 99.0;
      case AdType.weather:
        return 199.0;
      case AdType.bannerAd:
        return 129.0;
    }
  }
}
