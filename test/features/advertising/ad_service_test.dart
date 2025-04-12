import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:neusenews/features/advertising/models/ad.dart';
import 'package:neusenews/features/advertising/models/ad_type.dart';
import 'package:neusenews/features/advertising/models/ad_status.dart';
import 'package:neusenews/features/advertising/services/ad_service.dart';
import 'package:neusenews/features/advertising/repositories/ad_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

// Mock classes
class MockAdRepository extends Mock implements AdRepository {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {
  final String uidValue;

  MockUser({required this.uidValue});

  @override
  String get uid => uidValue; // Provide a mock UID
}

void main() {
  late AdService adService;
  late MockAdRepository mockRepository;
  late MockFirebaseAuth mockAuth;

  setUp(() {
    mockRepository = MockAdRepository();
    mockAuth = MockFirebaseAuth();
    adService = AdService(repository: mockRepository, auth: mockAuth);
  });

  group('AdService tests', () {
    test('createAd should call repository with correct data', () async {
      // Arrange
      final user = MockUser(uidValue: '123');
      when(mockAuth.currentUser).thenReturn(user);

      final ad = Ad(
        businessId: '123',
        businessName: 'Test Business',
        headline: 'Test Ad',
        description: 'This is a test ad',
        linkUrl: 'https://example.com',
        type: AdType.inFeedNews,
        status: AdStatus.pending,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)), // Add endDate
        cost: 100.0, // Add cost
      );

      final imageFile = File('test_assets/test_image.jpg');

      // Act
      await adService.createAd(ad, imageFile);

      // Assert
      verify(mockRepository.createAd(ad)).called(1);
      verify(mockRepository.uploadAdImage(any<String>(), imageFile)).called(1);
    });

    test('getActiveAdsByType should call repository method', () async {
      // Arrange
      final adType = AdType.inFeedNews;
      when(
        mockRepository.getActiveAdsByType(adType),
      ).thenAnswer((_) => Stream.value([]));

      // Act
      final result = adService.getActiveAdsByType(adType);

      // Assert
      expect(result, isA<Stream<List<Ad>>>());
      verify(mockRepository.getActiveAdsByType(adType)).called(1);
    });

    test('approveAd should update ad status to active', () async {
      // Arrange
      const adId = 'ad123';
      when(
        mockRepository.updateAdStatus(adId, AdStatus.active),
      ).thenAnswer((_) async {});

      // Act
      await adService.approveAd(adId);

      // Assert
      verify(mockRepository.updateAdStatus(adId, AdStatus.active)).called(1);
    });

    test('rejectAd should update ad status to rejected with reason', () async {
      // Arrange
      const adId = 'ad123';
      const rejectionReason = 'Not suitable';
      when(
        mockRepository.updateAdStatus(
          adId,
          AdStatus.rejected,
          rejectionReason: rejectionReason,
        ),
      ).thenAnswer((_) async {});

      // Act
      await adService.rejectAd(adId, rejectionReason);

      // Assert
      verify(
        mockRepository.updateAdStatus(
          adId,
          AdStatus.rejected,
          rejectionReason: rejectionReason,
        ),
      ).called(1);
    });

    test('calculateAdCost should return correct cost', () {
      // Arrange
      final adType = AdType.inFeedNews;
      const durationWeeks = 4;

      // Act
      final cost = adService.calculateAdCost(adType, durationWeeks);

      // Assert
      expect(cost, adType.weeklyRate * durationWeeks);
    });

    test('deleteAd should call repository method', () async {
      // Arrange
      const adId = 'ad123';
      when(mockRepository.deleteAd(adId)).thenAnswer((_) async {});

      // Act
      await adService.deleteAd(adId);

      // Assert
      verify(mockRepository.deleteAd(adId)).called(1);
    });
  });
}
