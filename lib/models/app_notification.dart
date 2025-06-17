import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String type; // "like", "comment", or "follow"
  final String fromUserId;
  final String fromUserName; // the sender’s display name
  final String? postId; // only for likes/comments
  final String? message; // only for comments
  final DateTime timestamp;
  final bool read;

  AppNotification({
    required this.id,
    required this.type,
    required this.fromUserId,
    required this.fromUserName,
    this.postId,
    this.message,
    required this.timestamp,
    this.read = false,
  });

  factory AppNotification.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      type: data['type'] as String,
      fromUserId: data['fromUserId'] as String,
      fromUserName: data['fromUserName'] as String? ?? '',
      postId: data['postId'] as String?,
      message: data['message'] as String?,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      read: data['read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'type': type,
    'fromUserId': fromUserId,
    'fromUserName': fromUserName,
    'postId': postId,
    'message': message,
    'timestamp': Timestamp.fromDate(timestamp),
    'read': read,
  };
}
