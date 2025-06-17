import 'package:blog_app/models/app_notification.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/post_controller.dart';
import '../../controllers/user_controller.dart';
import '../../controllers/notification_controller.dart';
import '../../models/post_model.dart';
import '../widgets/post_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  void initState() {
    super.initState();
    // Schedule user data loading after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadUserData();
      }
    });
  }

  Future<void> _loadUserData() async {
    final authController = context.read<AuthController>();
    final userController = context.read<UserController>();
    final uid = authController.currentUser?.uid;

    if (uid != null && mounted) {
      await userController.loadUser(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final postController = Provider.of<PostController>(context, listen: false);
    final currentUser = authController.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blog It'),
        actions: [
          if (currentUser != null) _buildNotificationBadge(authController),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed:
                () =>
                    currentUser != null
                        ? context.go('/profile')
                        : context.go('/login'),
            tooltip: 'Profile',
          ),
        ],
      ),
      body: _buildPostList(postController, authController),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (currentUser != null) {
            context.go('/create-post');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please sign in to create posts')),
            );
            context.go('/login');
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Create Post',
      ),
    );
  }

  Widget _buildNotificationBadge(AuthController authController) {
    return Builder(
      builder: (context) {
        final notificationController = Provider.of<NotificationController>(
          context,
          listen: false,
        );
        final uid = authController.userId;

        if (uid == null) return const SizedBox.shrink();

        return StreamBuilder<List<AppNotification>>(
          stream: notificationController.getNotificationsStream(uid),
          builder: (ctx, snap) {
            final count = snap.data?.length ?? 0;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () => context.go('/notifications'),
                  tooltip: 'Notifications',
                ),
                if (count > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        count > 9 ? '9+' : '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPostList(
    PostController postController,
    AuthController authController,
  ) {
    return StreamBuilder<List<Post>>(
      stream: postController.getPostsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Error loading posts'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => postController.getPostsStream(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final posts = snapshot.data;
        if (posts == null || posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No posts yet'),
                if (authController.currentUser != null)
                  TextButton(
                    onPressed: () => context.go('/create-post'),
                    child: const Text('Create your first post!'),
                  ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(8),
          itemCount: posts.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final post = posts[index];
            return PostCard(
              post: post,
              currentUserId: authController.currentUser?.uid,
              onLike:
                  authController.currentUser == null
                      ? () => _showLoginPrompt(context)
                      : () => postController.toggleLike(
                        post.id,
                        authController.currentUser!.uid,
                        post.likes,
                      ),
              onComment:
                  authController.currentUser == null
                      ? (_) => _showLoginPrompt(context)
                      : (comment) => postController.addComment(
                        post.id,
                        authController.currentUser!.uid,
                        comment,
                      ),
            );
          },
        );
      },
    );
  }

  void _showLoginPrompt(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please sign in to interact with posts')),
    );
    context.go('/login');
  }
}
