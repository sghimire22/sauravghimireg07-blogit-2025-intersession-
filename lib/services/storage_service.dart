import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<List<String>> uploadPostImages(List<XFile> images) async {
    try {
      List<String> downloadUrls = [];

      for (var image in images) {
        final String fileName =
            'posts/${DateTime.now().millisecondsSinceEpoch}_${images.indexOf(image)}.jpg';
        final Reference storageRef = _storage.ref().child(fileName);
        final UploadTask uploadTask = storageRef.putFile(File(image.path));
        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
      }

      return downloadUrls;
    } catch (e) {
      throw 'Error uploading images: ${e.toString()}';
    }
  }

  Future<String> uploadProfileImage(XFile image) async {
    try {
      final String fileName =
          'profiles/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = _storage.ref().child(fileName);
      final UploadTask uploadTask = storageRef.putFile(File(image.path));
      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw 'Error uploading profile image: ${e.toString()}';
    }
  }

  Future<void> deleteImage(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      throw 'Error deleting image: ${e.toString()}';
    }
  }
}
