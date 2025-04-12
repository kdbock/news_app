# news_app
# Neuse News Mobile App

![Neuse News](https://img.shields.io/badge/Neuse%20News-App-gold)
![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue)
![License](https://img.shields.io/badge/License-Proprietary-red)

> Hyper-local news with no pop-up ads, no AP news and no online subscription fees. No kidding!

A comprehensive mobile application providing local news, sports, political, and business content from eastern North Carolina. The app serves as a digital hub for the community, featuring content from multiple trusted sources including NeuseNews.com, NeuseNewsSports.com, and NCPoliticalNews.com.

## Features

### News & Content
- **Multi-source News Feeds**: Local news, sports, politics, columns, and more
- **Category Navigation**: Easy browsing through various news categories
- **Article Bookmarking**: Save favorite articles for later reading
- **Obituaries & Public Records**: Access to important community information
- **Classified Listings**: Browse and place classified ads

### User Engagement
- **News Tips Submission**: Submit tips about local happenings
- **Sponsored Content**: Businesses can submit sponsored articles and events
- **User Accounts**: Personalized experience with saved preferences

### Community Tools
- **Weather Dashboard**: Local weather information and forecasts
- **Events Calendar**: Comprehensive community events listing
- **Advertising Platform**: Self-service ad creation and management

### Role-based Access
- **Regular Users**: Access to all content and basic features
- **Contributors**: Submit and manage their own content
- **Advertisers**: Place and monitor advertising campaigns
- **Administrators**: Moderate content and manage the platform
- **Investors**: Access to analytics and performance dashboards

## Technology Stack

- **Framework**: Flutter/Dart
- **Backend**: Firebase (Authentication, Firestore, Storage)
- **State Management**: Provider
- **Data Sources**: RSS feeds, Weather APIs
- **Analytics**: Firebase Analytics
- **Authentication**: Email/Password, Google Sign-In, Apple Sign-In

## Project Structure

```
lib/
├── constants/            # App-wide constants
├── di/                   # Dependency injection
├── features/             # Feature modules
│   ├── admin/            # Admin dashboard and tools
│   ├── advertising/      # Ad creation and management
│   ├── events/           # Calendar and event management
│   ├── news/             # News feeds and articles
│   ├── users/            # User profiles and authentication
│   └── weather/          # Weather forecasts
├── models/               # Data models
├── navigation/           # Navigation helpers
├── providers/            # State management
├── repositories/         # Data access layer
├── screens/              # Main app screens
├── services/             # Business logic services
├── theme/                # App theming
├── utils/                # Utility functions
├── widgets/              # Reusable UI components
├── firebase_options.dart # Firebase configuration
└── main.dart            # Application entry point
```

## Getting Started

### Prerequisites
- Flutter SDK (latest stable)
- Dart SDK
- Firebase project setup
- OpenWeatherMap API key

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/kdbock/news_app.git
cd news_app
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Configure Firebase**
   - Create a Firebase project
   - Enable Authentication (Email/Password, Google, Apple)
   - Set up Firestore with appropriate rules
   - Download and replace the Firebase config files

4. **Set up API Keys**
   - Add your OpenWeatherMap API key to the appropriate configuration file

5. **Run the app**
```bash
flutter run
```

## Design Guidelines

- **Primary Colors**: 
  - Gold: #d2982a
  - Dark Gray: #2d2c31
- **Theme**: Modern design with white background, gold accent elements
- **Typography**: System fonts with hierarchical sizing

## Firebase Configuration

The app uses Firebase for backend services:
- Authentication (Email/Password, Google, Apple, Anonymous)
- Firestore for data storage
- Storage for images and media
- Analytics for user behavior tracking

## License

This project is proprietary software. All rights reserved.

## Acknowledgements

- News content provided by NeuseNews.com, NeuseNewsSports.com, and NCPoliticalNews.com
- Weather data from OpenWeatherMap API

---

*Note: Add screenshots of key screens to enhance this README.*

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
# Neuse News Mobile App

![Neuse News](https://img.shields.io/badge/Neuse%20News-App-gold)
![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue)
![License](https://img.shields.io/badge/License-Proprietary-red)

> Hyper-local news with no pop-up ads, no AP news and no online subscription fees. No kidding!

A comprehensive mobile application providing local news, sports, political, and business content from eastern North Carolina. The app serves as a digital hub for the community, featuring content from multiple trusted sources including NeuseNews.com, NeuseNewsSports.com, and NCPoliticalNews.com.

## Features

### News & Content
- **Multi-source News Feeds**: Local news, sports, politics, columns, and more
- **Category Navigation**: Easy browsing through various news categories
- **Article Bookmarking**: Save favorite articles for later reading
- **Obituaries & Public Records**: Access to important community information
- **Classified Listings**: Browse and place classified ads

### User Engagement
- **News Tips Submission**: Submit tips about local happenings
- **Sponsored Content**: Businesses can submit sponsored articles and events
- **User Accounts**: Personalized experience with saved preferences

### Community Tools
- **Weather Dashboard**: Local weather information and forecasts
- **Events Calendar**: Comprehensive community events listing
- **Advertising Platform**: Self-service ad creation and management

### Role-based Access
- **Regular Users**: Access to all content and basic features
- **Contributors**: Submit and manage their own content
- **Advertisers**: Place and monitor advertising campaigns
- **Administrators**: Moderate content and manage the platform
- **Investors**: Access to analytics and performance dashboards

## Technology Stack

- **Framework**: Flutter/Dart
- **Backend**: Firebase (Authentication, Firestore, Storage)
- **State Management**: Provider
- **Data Sources**: RSS feeds, Weather APIs
- **Analytics**: Firebase Analytics
- **Authentication**: Email/Password, Google Sign-In, Apple Sign-In

## Project Structure

```
lib/
├── constants/            # App-wide constants
├── di/                   # Dependency injection
├── features/             # Feature modules
│   ├── admin/            # Admin dashboard and tools
│   ├── advertising/      # Ad creation and management
│   ├── events/           # Calendar and event management
│   ├── news/             # News feeds and articles
│   ├── users/            # User profiles and authentication
│   └── weather/          # Weather forecasts
├── models/               # Data models
├── navigation/           # Navigation helpers
├── providers/            # State management
├── repositories/         # Data access layer
├── screens/              # Main app screens
├── services/             # Business logic services
├── theme/                # App theming
├── utils/                # Utility functions
├── widgets/              # Reusable UI components
├── firebase_options.dart # Firebase configuration
└── main.dart            # Application entry point
```

## Getting Started

### Prerequisites
- Flutter SDK (latest stable)
- Dart SDK
- Firebase project setup
- OpenWeatherMap API key

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/kdbock/news_app.git
cd news_app
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Configure Firebase**
   - Create a Firebase project
   - Enable Authentication (Email/Password, Google, Apple)
   - Set up Firestore with appropriate rules
   - Download and replace the Firebase config files

4. **Set up API Keys**
   - Add your OpenWeatherMap API key to the appropriate configuration file

5. **Run the app**
```bash
flutter run
```

## Design Guidelines

- **Primary Colors**: 
  - Gold: #d2982a
  - Dark Gray: #2d2c31
- **Theme**: Modern design with white background, gold accent elements
- **Typography**: System fonts with hierarchical sizing

## Firebase Configuration

The app uses Firebase for backend services:
- Authentication (Email/Password, Google, Apple, Anonymous)
- Firestore for data storage
- Storage for images and media
- Analytics for user behavior tracking

## License

This project is proprietary software. All rights reserved.

## Acknowledgements

- News content provided by NeuseNews.com, NeuseNewsSports.com, and NCPoliticalNews.com
- Weather data from OpenWeatherMap API

---

*Note: Add screenshots of key screens to enhance this README.*
For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
=======
A hyper local news app

