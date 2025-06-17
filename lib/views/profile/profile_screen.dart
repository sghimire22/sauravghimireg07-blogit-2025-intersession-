import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/user_controller.dart';
import '../../controllers/post_controller.dart';
import '../../models/post_model.dart';
import '../widgets/post_card.dart';

class ProfileScreen extends StatefulWidget {
  final String? viewUserId;
  const ProfileScreen({super.key, this.viewUserId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final authController = context.read<AuthController>();
    final userController = context.read<UserController>();
    final postController = context.read<PostController>();

    final uid = widget.viewUserId ?? authController.currentUser!.uid;
    await userController.loadUser(uid);
    await postController.updateUserPostCount(uid);
    postController.getUserPosts(uid).first;

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final userController = context.watch<UserController>();
    final postController = context.watch<PostController>();

    if (authController.currentUser == null) {
      return _buildUnauthenticatedView();
    }
    if (userController.currentUser == null) {
      return Scaffold(
        appBar: _buildAppBar(authController, userController),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final profileUser = userController.currentUser!;
    final isMe =
        widget.viewUserId == null ||
        widget.viewUserId == authController.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF8D9BA1),
      appBar: _buildAppBar(authController, userController),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // PROFILE HEADER
            Container(
              width: double.infinity,
              color: Colors.yellow.shade100,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage:
                        profileUser.photoUrl != null
                            ? CachedNetworkImageProvider(profileUser.photoUrl!)
                            : null,
                    child:
                        profileUser.photoUrl == null
                            ? const Icon(Icons.person, size: 50)
                            : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profileUser.displayName,
                    style: GoogleFonts.lato(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    profileUser.email,
                    style: GoogleFonts.lato(fontSize: 16, color: Colors.blue),
                  ),
                  const SizedBox(height: 16),
                  if (!isMe)
                    FutureBuilder<bool>(
                      future: userController.isFollowing(profileUser.id),
                      builder: (ctx, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        final isFollowing = snap.data ?? false;
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.purple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () async {
                            if (isFollowing) {
                              await userController.unfollowUser(profileUser.id);
                            } else {
                              await userController.followUser(profileUser.id);
                            }
                            setState(() {});
                          },
                          child: Text(isFollowing ? 'Unfollow' : 'Follow'),
                        );
                      },
                    ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statItem('Posts', postController.userPostsCount),
                      _statItem('Followers', userController.followersCount),
                      _statItem('Following', userController.followingCount),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // POSTS LIST
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                isMe ? 'My Posts' : 'Posts',
                style: GoogleFonts.lato(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            StreamBuilder<List<Post>>(
              stream: postController.getUserPosts(profileUser.id),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final posts = snap.data ?? [];
                if (posts.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No posts yet'),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: posts.length,
                  itemBuilder: (c, i) {
                    final p = posts[i];
                    final isOwner = p.userId == authController.currentUser!.uid;
                    return PostCard(
                      post: p,
                      currentUserId: authController.currentUser!.uid,
                      onLike:
                          () => postController.toggleLike(
                            p.id,
                            authController.currentUser!.uid,
                            p.likes,
                          ),
                      onComment:
                          (text) => postController.addComment(
                            p.id,
                            authController.currentUser!.uid,
                            text,
                          ),
                      onDelete:
                          isOwner
                              ? () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text('Delete post?'),
                                        content: const Text(
                                          'This cannot be undone.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                );
                                if (confirmed == true) {
                                  await postController.deletePost(p.id);
                                }
                              }
                              : null,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnauthenticatedView() => Scaffold(
    appBar: AppBar(title: const Text('Profile')),
    body: Center(
      child: ElevatedButton(
        onPressed: () => context.go('/login'),
        child: const Text('Please sign in'),
      ),
    ),
  );

  AppBar _buildAppBar(AuthController auth, UserController userCtrl) {
    final isMe =
        widget.viewUserId == null || widget.viewUserId == auth.currentUser?.uid;
    return AppBar(
      backgroundColor: const Color(0xFFC69A77),
      elevation: 0,
      title: Text(
        isMe ? 'My Profile' : '${userCtrl.currentUser!.displayName}\'s Profile',
        style: GoogleFonts.lato(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.black87),
      actions: [
        if (isMe)
          IconButton(
            icon: const Icon(Icons.edit),
            color: Colors.black87,
            onPressed: () => context.go('/edit-profile'),
          ),
        if (isMe)
          IconButton(
            icon: const Icon(Icons.logout),
            color: Colors.black87,
            onPressed: () => auth.signOut().then((_) => context.go('/')),
          ),
      ],
    );
  }

  Widget _statItem(String label, int count) => Column(
    children: [
      Text(
        count.toString(),
        style: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 4),
      Text(label, style: GoogleFonts.lato(fontSize: 14)),
    ],
  );
}
