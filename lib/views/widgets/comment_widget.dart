import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../models/post_model.dart';

class CommentWidget extends StatelessWidget {
  final Comment comment;
  final bool showDate;

  const CommentWidget({
    super.key,
    required this.comment,
    this.showDate = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage:
                comment.userAvatarUrl != null
                    ? CachedNetworkImageProvider(comment.userAvatarUrl!)
                    : null,
            child:
                comment.userAvatarUrl == null
                    ? const Icon(Icons.person, size: 16)
                    : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.userDisplayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (showDate)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          DateFormat('MMM d').format(comment.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(comment.content),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
