import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../controllers/post_controller.dart';
import '../../models/post_model.dart';

class EditPostScreen extends StatefulWidget {
  final Post post;
  const EditPostScreen({super.key, required this.post});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  late final Post _post;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  List<String> _currentImages = [];
  List<XFile> _newImages = [];

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _titleController = TextEditingController(text: _post.title);
    _contentController = TextEditingController(text: _post.content);
    _currentImages = List.from(_post.imageUrls);
  }

  Future<void> _pickImages() async {
    try {
      final pickedFiles = await ImagePicker().pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );
      setState(() => _newImages.addAll(pickedFiles));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking images: ${e.toString()}')),
        );
      }
    }
  }

  void _removeImage(int index, bool isNew) {
    setState(() {
      if (isNew) {
        _newImages.removeAt(index);
      } else {
        _currentImages.removeAt(index);
      }
    });
  }

  Future<void> _savePost() async {
    if (!_formKey.currentState!.validate()) return;

    final postController = context.read<PostController>();

    try {
      // Create updated post
      final updatedPost = Post(
        id: _post.id,
        userId: _post.userId,
        userDisplayName: _post.userDisplayName,
        userAvatarUrl: _post.userAvatarUrl,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        imageUrls: _currentImages,
        createdAt: _post.createdAt,
        likes: _post.likes,
        comments: _post.comments,
      );

      if (_newImages.isNotEmpty) {
        final newImageUrls = await postController.uploadPostImages(_newImages);
        updatedPost.imageUrls.addAll(newImageUrls);
      }

      // Save updated post
      await postController.updatePost(updatedPost);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post updated successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating post: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final postController = context.watch<PostController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Post'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: postController.isLoading ? null : _savePost,
          ),
        ],
      ),
      body:
          postController.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _contentController,
                        decoration: const InputDecoration(
                          labelText: 'Content',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 5,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter some content';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _pickImages,
                        child: const Text('Add More Images'),
                      ),
                      const SizedBox(height: 16),
                      if (_currentImages.isNotEmpty || _newImages.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Images',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  _currentImages.asMap().entries.map((entry) {
                                    return Stack(
                                      children: [
                                        Container(
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.grey,
                                            ),
                                          ),
                                          child: CachedNetworkImage(
                                            imageUrl: entry.value,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.close,
                                              size: 20,
                                            ),
                                            onPressed:
                                                () => _removeImage(
                                                  entry.key,
                                                  false,
                                                ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                            ),
                            if (_newImages.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Text(
                                'New Images',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children:
                                    _newImages.asMap().entries.map((entry) {
                                      return Stack(
                                        children: [
                                          Container(
                                            width: 100,
                                            height: 100,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.grey,
                                              ),
                                            ),
                                            child: Image.file(
                                              File(entry.value.path),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Positioned(
                                            top: 0,
                                            right: 0,
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.close,
                                                size: 20,
                                              ),
                                              onPressed:
                                                  () => _removeImage(
                                                    entry.key,
                                                    true,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                              ),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
              ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
