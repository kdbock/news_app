# Advertising Module

## Overview
The advertising module provides functionality for managing advertisements within the Neuse News app, including creating, displaying, analyzing, and managing advertisements.

## Architecture
This module follows a clean architecture approach:
- **Models**: Data structures representing advertising entities
- **Repositories**: Data access layer
- **Services**: Business logic
- **Screens**: UI components for users and admins
- **Widgets**: Reusable UI components

## Key Components

### User Flows
1. **Advertiser Flow**:
   - Browse ad options
   - Create and customize ads
   - Complete checkout
   - View analytics

2. **Admin Flow**:
   - Review pending ads
   - Manage active ads
   - Access analytics

### Key Files
- `ad_type.dart`: Enum defining ad placement types
- `ad_status.dart`: Enum defining ad workflow states
- `ad_service.dart`: Core business logic for ad operations
- `ad_repository.dart`: Data access layer for ad persistence

## Usage Examples
```dart
// Creating a new ad
final adService = serviceLocator<AdService>();
final newAd = Ad(/* parameters */);
final imageFile = File(/* image path */);
final adId = await adService.createAd(newAd, imageFile);