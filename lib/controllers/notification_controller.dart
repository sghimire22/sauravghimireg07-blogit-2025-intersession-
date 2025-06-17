import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_notification.dart';

class NotificationController with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<AppNotification>> getNotificationsStream(String userId) {
    if (userId.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .handleError((error) {
          debugPrint('Notification stream error: $error');
          return Stream.value([]);
        })
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => AppNotification.fromDoc(doc)).toList(),
        );
  }

  Future<void> refreshNotifications(String userId) async {
    notifyListeners(); // This will trigger a rebuild of listeners
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null || notificationId.isEmpty) return;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }
}
