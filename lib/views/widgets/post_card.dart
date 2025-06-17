import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/post_model.dart';
import 'comment_widget.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final String? currentUserId;
  final VoidCallback? onLike;
  final Function(String)? onComment;
  final VoidCallback? onDelete;
  final bool isDetailed;

  const PostCard({
    super.key,
    required this.post,
    this.currentUserId,
    this.onLike,
    this.onComment,
    this.onDelete,
    this.isDetailed = false,
  });

  @override
  Widget build(BuildContext context) {
    final isLiked = currentUserId != null && post.likes.contains(currentUserId);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap:
            isDetailed ? null : () => context.go('/post-detail', extra: post),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER ROW: avatar, name, date, (optional) delete
              Row(
                children: [
                  InkWell(
                    onTap: () => context.go('/profile/${post.userId}'),
                    child: Row(
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
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('MMM d, y').format(post.createdAt),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  if (onDelete != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete post',
                      onPressed: onDelete,
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 12),

              // TITLE with Merriweather
              if (post.title.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    post.title,
                    style: GoogleFonts.merriweather(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              // CONTENT
              Text(post.content),
              const SizedBox(height: 12),

              // IMAGES
              if (post.imageUrls.isNotEmpty)
                SizedBox(
                  height: isDetailed ? 300 : 200,
                  child:
                      isDetailed
                          ? PageView.builder(
                            itemCount: post.imageUrls.length,
                            itemBuilder:
                                (ctx, i) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ),
                                  child: CachedNetworkImage(
                                    imageUrl: post.imageUrls[i],
                                    fit: BoxFit.contain,
                                    placeholder:
                                        (c, u) => const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                    errorWidget:
                                        (c, u, e) => const Icon(Icons.error),
                                  ),
                                ),
                          )
                          : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: post.imageUrls.length,
                            itemBuilder:
                                (ctx, i) => Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: CachedNetworkImage(
                                    imageUrl: post.imageUrls[i],
                                    width: 200,
                                    fit: BoxFit.cover,
                                    placeholder:
                                        (c, u) => const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                    errorWidget:
                                        (c, u, e) => const Icon(Icons.error),
                                  ),
                                ),
                          ),
                ),

              const SizedBox(height: 12),

              // LIKE & COMMENT BUTTONS
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : null,
                    ),
                    onPressed: onLike,
                  ),
                  Text('${post.likes.length}'),
                  const SizedBox(width: 16),
                  const Icon(Icons.comment),
                  Text('${post.comments.length}'),
                ],
              ),

              // INLINE COMMENTS PREVIEW
              if (!isDetailed && post.comments.isNotEmpty)
                ...post.comments.map((c) => CommentWidget(comment: c)),

              if (!isDetailed && post.comments.length > 2)
                TextButton(
                  onPressed: () => context.go('/post-detail', extra: post),
                  child: Text('View all ${post.comments.length} comments'),
                ),

              // COMMENT INPUT
              if (onComment != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Add a comment…',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onSubmitted: onComment,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
