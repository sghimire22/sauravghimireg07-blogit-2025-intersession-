import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/notification_controller.dart';
import '../../models/app_notification.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final notificationController = Provider.of<NotificationController>(context);
    final userId = authController.userId;

    return Scaffold(
      // ← soft grey background for the entire screen
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        // ← a slightly darker header
        backgroundColor: Colors.grey.shade800,
        title: Text(
          'Notifications',
          style: GoogleFonts.robotoSlab(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: Colors.white,
            onPressed: () => _refreshData(notificationController, userId),
          ),
        ],
      ),
      body: _buildNotificationContent(authController, notificationController),
    );
  }

  Widget _buildNotificationContent(
    AuthController authController,
    NotificationController notificationController,
  ) {
    if (authController.currentUser == null) {
      return _buildAuthRequiredState();
    }

    return StreamBuilder<List<AppNotification>>(
      stream: notificationController.getNotificationsStream(
        authController.userId!,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error!);
        }
        final notifications = snapshot.data ?? [];
        if (notifications.isEmpty) {
          return _buildEmptyState();
        }
        return RefreshIndicator(
          onRefresh:
              () =>
                  _refreshData(notificationController, authController.userId!),
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationItem(
                notification,
                notificationController,
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _refreshData(
    NotificationController controller,
    String? userId,
  ) async {
    if (userId != null) {
      await controller.refreshNotifications(userId);
    }
  }

  Widget _buildAuthRequiredState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.login, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Sign in to view notifications',
            style: GoogleFonts.robotoSlab(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            child: Text('Sign In', style: GoogleFonts.robotoSlab()),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading notifications...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(dynamic error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Could not load notifications',
            style: GoogleFonts.robotoSlab(fontSize: 16),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: GoogleFonts.robotoSlab(),
            ),
          ),
          ElevatedButton(
            onPressed:
                () => _refreshData(
                  Provider.of<NotificationController>(context, listen: false),
                  Provider.of<AuthController>(context, listen: false).userId,
                ),
            child: Text('Try Again', style: GoogleFonts.robotoSlab()),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_off, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: GoogleFonts.robotoSlab(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
          Text(
            'When you get notifications, they’ll appear here',
            style: GoogleFonts.robotoSlab(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    AppNotification notification,
    NotificationController controller,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      // lighter blue for unread
      color: notification.read ? Colors.white : Colors.lightBlue.shade50,
      child: ListTile(
        leading: _getNotificationIcon(notification.type),
        title: Text(
          _getNotificationTitle(notification),
          style: GoogleFonts.robotoSlab(
            fontSize: 16,
            fontWeight: notification.read ? FontWeight.w400 : FontWeight.w700,
          ),
        ),
        subtitle: Text(
          _formatDate(notification.timestamp),
          style: GoogleFonts.robotoSlab(
            fontSize: 14,
            color: notification.read ? Colors.grey[600] : Colors.blue[700],
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () => _handleNotificationTap(notification, controller),
      ),
    );
  }

  Widget _getNotificationIcon(String type) {
    switch (type) {
      case 'like':
        return CircleAvatar(
          backgroundColor: Colors.red[100],
          child: const Icon(Icons.favorite, color: Colors.red),
        );
      case 'comment':
        return CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: const Icon(Icons.comment, color: Colors.blue),
        );
      case 'follow':
        return CircleAvatar(
          backgroundColor: Colors.green[100],
          child: const Icon(Icons.person_add, color: Colors.green),
        );
      default:
        return CircleAvatar(
          backgroundColor: Colors.grey[200],
          child: const Icon(Icons.notifications, color: Colors.grey),
        );
    }
  }

  String _getNotificationTitle(AppNotification notification) {
    switch (notification.type) {
      case 'like':
        return '${notification.fromUserName} liked your post';
      case 'comment':
        return '${notification.fromUserName} commented: "${notification.message ?? ''}"';
      case 'follow':
        return '${notification.fromUserName} started following you';
      default:
        return 'New notification';
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, y • h:mm a').format(date);
  }

  void _handleNotificationTap(
    AppNotification notification,
    NotificationController controller,
  ) {
    if (!notification.read) {
      controller.markNotificationAsRead(notification.id);
    }
  }
}
