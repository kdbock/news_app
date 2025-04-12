enum AdType {
  titleSponsor, // 0
  inFeedDashboard, // 1
  inFeedNews, // 2
  weather, // 3
  bannerAd, // 4
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
