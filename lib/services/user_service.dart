import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createUser(AppUser user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toMap());
    } catch (e) {
      throw 'Error creating user: ${e.toString()}';
    }
  }

  Future<AppUser?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return AppUser.fromMap({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      throw 'Error getting user: ${e.toString()}';
    }
  }

  Future<void> updateUser(AppUser user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toMap());
    } catch (e) {
      throw 'Error updating user: ${e.toString()}';
    }
  }

  Future<int?> getFollowersCount(String userId) async {
    try {
      final snapshot =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('followers')
              .count()
              .get();
      return snapshot.count;
    } catch (e) {
      debugPrint('Error getting followers count: $e');
      return 0; // Default value instead of null
    }
  }

  Future<int?> getFollowingCount(String userId) async {
    try {
      final snapshot =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('following')
              .count()
              .get();
      return snapshot.count;
    } catch (e) {
      throw 'Error getting following count: ${e.toString()}';
    }
  }

  Future<void> followUser(String followerId, String followingId) async {
    try {
      final batch = _firestore.batch();

      // Add to follower's following list
      batch.set(
        _firestore
            .collection('users')
            .doc(followerId)
            .collection('following')
            .doc(followingId),
        {'timestamp': FieldValue.serverTimestamp()},
      );

      // Add to following user's followers list
      batch.set(
        _firestore
            .collection('users')
            .doc(followingId)
            .collection('followers')
            .doc(followerId),
        {'timestamp': FieldValue.serverTimestamp()},
      );

      await batch.commit();
    } catch (e) {
      throw 'Error following user: ${e.toString()}';
    }
  }

  Future<void> unfollowUser(String followerId, String followingId) async {
    try {
      final batch = _firestore.batch();

      // Remove from follower's following list
      batch.delete(
        _firestore
            .collection('users')
            .doc(followerId)
            .collection('following')
            .doc(followingId),
      );

      // Remove from following user's followers list
      batch.delete(
        _firestore
            .collection('users')
            .doc(followingId)
            .collection('followers')
            .doc(followerId),
      );

      await batch.commit();
    } catch (e) {
      throw 'Error unfollowing user: ${e.toString()}';
    }
  }

  Stream<List<AppUser>> searchUsers(String query) {
    return _firestore
        .collection('users')
        .where('displayName', isGreaterThanOrEqualTo: query)
        .where('displayName', isLessThan: query + 'z')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AppUser.fromMap({...doc.data(), 'id': doc.id}))
              .toList();
        });
  }

  Future<bool> isFollowing(String followerId, String followingId) async {
    final doc =
        await _firestore
            .collection('users')
            .doc(followingId)
            .collection('followers')
            .doc(followerId)
            .get();
    return doc.exists;
  }

  Future<List<AppUser>> getFollowers(String userId) async {
    try {
      final snapshot =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('followers')
              .get();

      final users = <AppUser>[];
      for (final doc in snapshot.docs) {
        final user = await getUser(doc.id);
        if (user != null) {
          users.add(user);
        }
      }
      return users;
    } catch (e) {
      throw 'Error getting followers: ${e.toString()}';
    }
  }

  Future<List<AppUser>> getFollowing(String userId) async {
    try {
      final snapshot =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('following')
              .get();

      final users = <AppUser>[];
      for (final doc in snapshot.docs) {
        final user = await getUser(doc.id);
        if (user != null) {
          users.add(user);
        }
      }
      return users;
    } catch (e) {
      throw 'Error getting following: ${e.toString()}';
    }
  }
}
