import 'package:blog_app/views/widgets/comment_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../controllers/post_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/post_model.dart';

class PostDetailScreen extends StatelessWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final postController = Provider.of<PostController>(context);
    final authController = Provider.of<AuthController>(context);
    final commentController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
        actions: [
          if (post.userId == authController.currentUser?.uid)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.go('/edit-post', extra: post),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage:
                            post.userAvatarUrl != null
                                ? CachedNetworkImageProvider(
                                  post.userAvatarUrl!,
                                )
                                : null,
                        child:
                            post.userAvatarUrl == null
                                ? const Icon(Icons.person)
                                : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        post.userDisplayName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(
                        post.createdAt.toString(),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (post.title.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        post.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Text(post.content),
                  const SizedBox(height: 16),
                  if (post.imageUrls.isNotEmpty)
                    SizedBox(
                      height: 300,
                      child: PageView.builder(
                        itemCount: post.imageUrls.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: CachedNetworkImage(
                              imageUrl: post.imageUrls[index],
                              fit: BoxFit.contain,
                              placeholder:
                                  (context, url) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                              errorWidget:
                                  (context, url, error) =>
                                      const Icon(Icons.error),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          post.likes.contains(authController.currentUser?.uid)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color:
                              post.likes.contains(
                                    authController.currentUser?.uid,
                                  )
                                  ? Colors.red
                                  : null,
                        ),
                        onPressed:
                            () => postController.toggleLike(
                              post.id,
                              authController.currentUser!.uid,
                              post.likes,
                            ),
                      ),
                      Text('${post.likes.length} likes'),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Comments',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ...post.comments.map(
                    (comment) => CommentWidget(comment: comment),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          decoration: const InputDecoration(
                            hintText: 'Add a comment...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () {
                          if (commentController.text.isNotEmpty) {
                            postController.addComment(
                              post.id,
                              authController.currentUser!.uid,
                              commentController.text,
                            );
                            commentController.clear();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
