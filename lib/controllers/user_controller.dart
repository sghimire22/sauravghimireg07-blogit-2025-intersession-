import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_notification.dart';
import '../services/user_service.dart';
import '../services/storage_service.dart';
import '../models/user_model.dart';
import 'package:image_picker/image_picker.dart';

class UserController with ChangeNotifier {
  final UserService _userService = UserService();
  final StorageService _storageService = StorageService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  int _followersCount = 0;
  int get followersCount => _followersCount;

  int _followingCount = 0;
  int get followingCount => _followingCount;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadUser(String userId) async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _userService.getUser(userId);
      final followers = await _userService.getFollowersCount(userId) ?? 0;
      final following = await _userService.getFollowingCount(userId) ?? 0;

      _currentUser = user;
      _followersCount = followers;
      _followingCount = following;
    } catch (e) {
      debugPrint('Error loading user: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update the signed-in user's profile
  Future<void> updateProfile({
    required String userId,
    required String displayName,
    XFile? imageFile,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      String? photoUrl;
      if (imageFile != null) {
        photoUrl = await _storageService.uploadProfileImage(imageFile);
      }

      final updatedUser = AppUser(
        id: userId,
        email: _currentUser!.email,
        displayName: displayName,
        photoUrl: photoUrl ?? _currentUser!.photoUrl,
        createdAt: _currentUser!.createdAt,
      );

      await _userService.updateUser(updatedUser);
      _currentUser = updatedUser;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Follow another user and send an in-app notification
  Future<void> followUser(String targetUserId) async {
    final me = _auth.currentUser!;
    final meId = me.uid;
    if (meId == targetUserId) return;

    final myName = me.displayName ?? 'Anonymous';

    try {
      // Write follow relationship
      await _userService.followUser(meId, targetUserId);

      // Send in-app "follow" notification
      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .collection('notifications')
          .add(
            AppNotification(
              id: '',
              type: 'follow',
              fromUserId: meId,
              fromUserName: myName,
              postId: null,
              message: null,
              timestamp: DateTime.now(),
            ).toMap(),
          );

      //  Refresh counts
      if (_currentUser?.id == targetUserId) {
        _followersCount =
            await _userService.getFollowersCount(targetUserId) ?? 0;
      } else if (_currentUser?.id == meId) {
        _followingCount = await _userService.getFollowingCount(meId) ?? 0;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error following user: $e');
      rethrow;
    }
  }

  /// Unfollow another user
  Future<void> unfollowUser(String targetUserId) async {
    final me = _auth.currentUser!;
    final meId = me.uid;
    if (meId == targetUserId) return;

    try {
      await _userService.unfollowUser(meId, targetUserId);

      if (_currentUser?.id == targetUserId) {
        _followersCount =
            await _userService.getFollowersCount(targetUserId) ?? 0;
      } else if (_currentUser?.id == meId) {
        _followingCount = await _userService.getFollowingCount(meId) ?? 0;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error unfollowing user: $e');
      rethrow;
    }
  }

  /// Check if the signed-in user is following [targetUserId]
  Future<bool> isFollowing(String targetUserId) {
    final meId = _auth.currentUser!.uid;
    return _userService.isFollowing(meId, targetUserId);
  }
}
