import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final uuid = const Uuid();

  // Upload profile image
  Future<String> uploadProfileImage(String userId, File imageFile) async {
    try {
      // Create a unique filename
      String extension = path.extension(imageFile.path);
      String fileName = '$userId/${uuid.v4()}$extension';
      
      // Get reference to storage location
      Reference storageRef = _storage.ref().child('profile_images/$fileName');
      
      // Upload file
      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;
      
      // Get download URL
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading profile image: $e');
      throw Exception('Failed to upload profile image');
    }
  }

  // Upload ad image
  Future<String> uploadAdImage(String businessId, File imageFile) async {
    try {
      // Create a unique filename
      String extension = path.extension(imageFile.path);
      String fileName = '$businessId/${DateTime.now().millisecondsSinceEpoch}$extension';
      
      // Get reference to storage location
      Reference storageRef = _storage.ref().child('ad_images/$fileName');
      
      // Upload file
      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;
      
      // Get download URL
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading ad image: $e');
      throw Exception('Failed to upload ad image');
    }
  }

  // Upload event image
  Future<String> uploadEventImage(String eventId, File imageFile) async {
    try {
      // Create a unique filename
      String extension = path.extension(imageFile.path);
      String fileName = '$eventId/${DateTime.now().millisecondsSinceEpoch}$extension';
      
      // Get reference to storage location
      Reference storageRef = _storage.ref().child('event_images/$fileName');
      
      // Upload file
      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;
      
      // Get download URL
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading event image: $e');
      throw Exception('Failed to upload event image');
    }
  }

  // Upload article image
  Future<String> uploadArticleImage(String articleId, File imageFile) async {
    try {
      // Create a unique filename
      String extension = path.extension(imageFile.path);
      String fileName = '$articleId/${DateTime.now().millisecondsSinceEpoch}$extension';
      
      // Get reference to storage location
      Reference storageRef = _storage.ref().child('article_images/$fileName');
      
      // Upload file
      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;
      
      // Get download URL
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading article image: $e');
      throw Exception('Failed to upload article image');
    }
  }

  // Upload news tip media
  Future<String> uploadNewsTipMedia(File mediaFile) async {
    try {
      // Create a unique filename
      String extension = path.extension(mediaFile.path);
      String fileName = '${uuid.v4()}$extension';
      
      // Get reference to storage location
      Reference storageRef = _storage.ref().child('news_tip_media/$fileName');
      
      // Upload file
      UploadTask uploadTask = storageRef.putFile(mediaFile);
      TaskSnapshot taskSnapshot = await uploadTask;
      
      // Get download URL
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading news tip media: $e');
      throw Exception('Failed to upload news tip media');
    }
  }

  // Delete file
  Future<void> deleteFile(String fileUrl) async {
    try {
      Reference ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      print('Error deleting file: $e');
      throw Exception('Failed to delete file');
    }
  }
}