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

### Enhanced News Experience
- **Clean Reading Experience**: No intrusive pop-up ads, creating a premium feel
- **Rich Media Support**: Images, videos, and interactive content
- **Share Functionality**: Easily share articles across social platforms
- **Source Attribution**: Clear display of content sources and authors

### Monetization Strategy
- **Internal Ad System**: Custom in-app advertising platform rather than third-party ad networks
  - **Title Sponsors**: Premium placement ads shown on home and section pages
  - **Weather Sponsors**: Targeted ads displayed alongside weather information
  - **Section Sponsors**: Category-specific advertising opportunities
  - **Admin Approval**: All ads require administrative review before publication
  - **Analytics**: Advertisers receive impression and click-through metrics

### Sponsored Content Platform
- **Sponsored Articles**:
  - **Self-Service Submission**: Businesses can submit their own sponsored content
  - **Fixed Pricing Model**: $50 fee for 30-day publication
  - **Editorial Control**: All sponsored content requires admin approval
  - **Transparent Labeling**: Clearly marked as "SPONSORED" for user transparency
  - **Payment Processing**: Secure in-app payment system

- **Sponsored Events**:
  - **Community Calendar Integration**: Events appear in the main calendar feed
  - **Fixed Pricing Model**: $25 fee per event submission
  - **Admin Review System**: All events require approval before publication
  - **Enhanced Visibility**: Special styling for sponsored events
  - **Detailed Information**: Support for descriptions, images, ticket links

### Administrative Tools
- **Content Moderation**: Review and approve/reject user-submitted content
- **Dashboard**: Overview of submitted content awaiting review
- **User Management**: Manage user roles and permissions
- **Analytics**: Track engagement and revenue metrics

### Ad Management System
- **Firebase-Based Storage**: All ad creative stored in Firebase Storage
- **Impression Tracking**: Records when ads are viewed
- **Click Tracking**: Monitors user engagement with advertisements
- **Scheduling System**: Supports date-based campaign management

### Payment Processing
- **In-App Purchases**: Secure payment processing for sponsored content
- **Receipt Management**: Confirmation emails and in-app receipts
- **Renewal Options**: Easy renewal process for recurring sponsors

### Content Review Workflow
1. **Submission**: Users complete form and make payment
2. **Review Queue**: Content enters admin review system
3. **Approval/Rejection**: Admins can approve or reject with feedback
4. **Publication**: Approved content is automatically published
5. **Analytics**: Sponsors can view performance metrics

## Design Philosophy

The app embraces a "community-first" approach to monetization, where advertising is integrated naturally into the user experience rather than disrupting it. The focus is on creating value for both users and local businesses through:

1. **Relevance**: Ensuring ads and sponsored content are locally relevant
2. **Quality**: Maintaining high editorial standards through review processes
3. **Transparency**: Clear labeling of sponsored content
4. **Value**: Providing affordable marketing opportunities for local businesses

This monetization strategy aligns with the app's tagline of providing "hyper-local news with no pop-up ads, no AP news, and no online subscription fees."

## Technology Stack

- **Framework**: Flutter/Dart
- **Backend**: Firebase (Authentication, Firestore, Storage)
- **State Management**: Provider
- **Data Sources**: RSS feeds, Weather APIs
- **Analytics**: Firebase Analytics
- **Authentication**: Email/Password, Google Sign-In, Apple Sign-In- 

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

