import 'dart:io';

import 'package:blog_app/models/app_notification.dart';
import 'package:blog_app/models/post_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PostController with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int _userPostsCount = 0;
  int get userPostsCount => _userPostsCount;

  // 1) Stream of all posts
  Stream<List<Post>> getPostsStream() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs
                  .map((doc) => Post.fromMap({...doc.data(), 'id': doc.id}))
                  .toList(),
        );
  }

  // 2) Stream of posts for a specific user
  Stream<List<Post>> getUserPosts(String userId) {
    return _firestore
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs
                  .map((doc) => Post.fromMap({...doc.data(), 'id': doc.id}))
                  .toList(),
        );
  }

  // 3) Upload images helper
  Future<List<String>> uploadPostImages(List<XFile> images) async {
    try {
      _setLoading(true);
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw 'User not authenticated';

      final List<String> downloadUrls = [];
      for (final image in images) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName =
            'posts/$userId/${timestamp}_${images.indexOf(image)}.jpg';
        final ref = _storage.ref().child(fileName);
        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'uploadedBy': userId},
        );

        final snapshot = await ref.putFile(File(image.path), metadata);
        if (snapshot.state == TaskState.success) {
          downloadUrls.add(await ref.getDownloadURL());
        } else {
          throw 'Failed to upload image ${image.name}';
        }
      }
      return downloadUrls;
    } on FirebaseException catch (e) {
      throw 'Firebase Storage Error: ${e.message}';
    } catch (e) {
      throw 'Image upload failed: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // 4) Create a post
  Future<void> createPost({
    required String userId,
    required String? userDisplayName,
    required String? userAvatarUrl,
    required String title,
    required String content,
    required List<XFile> images,
  }) async {
    try {
      _setLoading(true);

      if (title.isEmpty || content.isEmpty) {
        throw 'Title and content cannot be empty';
      }

      final imageUrls =
          images.isNotEmpty ? await uploadPostImages(images) : <String>[];

      final post = Post(
        id: '',
        userId: userId,
        userDisplayName: userDisplayName ?? 'Anonymous',
        userAvatarUrl: userAvatarUrl,
        title: title,
        content: content,
        imageUrls: imageUrls,
        createdAt: DateTime.now(),
        likes: [],
        comments: [],
      );

      await _firestore.collection('posts').add(post.toMap());
      await updateUserPostCount(userId);
    } on FirebaseException catch (e) {
      throw 'Firebase Error: ${e.message}';
    } catch (e) {
      throw 'Failed to create post: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // 5) Update a post
  Future<void> updatePost(Post post) async {
    try {
      _setLoading(true);
      await _firestore.collection('posts').doc(post.id).update(post.toMap());
    } on FirebaseException catch (e) {
      throw 'Firebase Error: ${e.message}';
    } catch (e) {
      throw 'Failed to update post: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // 6) Delete a post (and its images)
  Future<void> deletePost(String postId) async {
    try {
      _setLoading(true);

      final doc = await _firestore.collection('posts').doc(postId).get();
      if (!doc.exists) return;

      final post = Post.fromMap({...doc.data()!, 'id': doc.id});
      final userId = post.userId;

      if (post.imageUrls.isNotEmpty) {
        await Future.wait(
          post.imageUrls.map((url) => _storage.refFromURL(url).delete()),
        );
      }

      await _firestore.collection('posts').doc(postId).delete();
      await updateUserPostCount(userId);
    } on FirebaseException catch (e) {
      throw 'Firebase Error: ${e.message}';
    } catch (e) {
      throw 'Failed to delete post: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // 7) Toggle like (and notify with fromUserName)
  Future<void> toggleLike(
    String postId,
    String userId,
    List<String> currentLikes,
  ) async {
    try {
      final me = _auth.currentUser!;
      final myName = me.displayName ?? 'Anonymous';

      if (currentLikes.contains(userId)) {
        // remove like
        await _firestore.collection('posts').doc(postId).update({
          'likes': FieldValue.arrayRemove([userId]),
        });
      } else {
        // fetch owner
        final postDoc = await _firestore.collection('posts').doc(postId).get();
        final postOwnerId = postDoc['userId'] as String;

        // add like
        await _firestore.collection('posts').doc(postId).update({
          'likes': FieldValue.arrayUnion([userId]),
        });

        // notify owner
        if (postOwnerId != userId) {
          await _firestore
              .collection('users')
              .doc(postOwnerId)
              .collection('notifications')
              .add(
                AppNotification(
                  id: '',
                  type: 'like',
                  fromUserId: userId,
                  fromUserName: myName,
                  postId: postId,
                  message: null,
                  timestamp: DateTime.now(),
                ).toMap(),
              );
        }
      }
    } on FirebaseException catch (e) {
      throw 'Firebase Error: ${e.message}';
    } catch (e) {
      throw 'Failed to toggle like: ${e.toString()}';
    }
  }

  // 8) Add a comment (and notify with fromUserName)
  Future<void> addComment(String postId, String userId, String content) async {
    _setLoading(true);
    try {
      if (content.trim().isEmpty) throw 'Comment cannot be empty';

      // fetch owner
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      final postOwnerId = postDoc['userId'] as String;

      // build comment
      final me = _auth.currentUser!;
      final displayName = me.displayName ?? 'Anonymous';
      final photoUrl = me.photoURL;
      final comment = Comment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        userDisplayName: displayName,
        userAvatarUrl: photoUrl,
        content: content.trim(),
        createdAt: DateTime.now(),
      );

      // push comment
      await _firestore.collection('posts').doc(postId).update({
        'comments': FieldValue.arrayUnion([comment.toMap()]),
      });

      // notify owner
      if (postOwnerId != userId) {
        await _firestore
            .collection('users')
            .doc(postOwnerId)
            .collection('notifications')
            .add(
              AppNotification(
                id: '',
                type: 'comment',
                fromUserId: userId,
                fromUserName: displayName,
                postId: postId,
                message: content.trim(),
                timestamp: DateTime.now(),
              ).toMap(),
            );
      }
    } on FirebaseException catch (e) {
      throw 'Firebase Error: ${e.message}';
    } catch (e) {
      throw 'Failed to add comment: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // 9) Internal loading helper
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // 10) Recompute a user’s post count
  Future<void> updateUserPostCount(String userId) async {
    try {
      final snapshot =
          await _firestore
              .collection('posts')
              .where('userId', isEqualTo: userId)
              .get();
      _userPostsCount = snapshot.docs.length;
    } catch (e) {
      _userPostsCount = 0;
    } finally {
      notifyListeners();
    }
  }
}
