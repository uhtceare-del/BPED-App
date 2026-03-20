import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path/path.dart' as p; // Add 'path' to pubspec.yaml

final cloudinaryProvider = Provider<CloudinaryService>((ref) {
  return CloudinaryService();
});

class CloudinaryService {
  final String cloudName = 'duviaos3y';
  final String uploadPreset = 'daren_unsigned';

  /// FIX: This matches the call in your CreateLessonScreen
  /// It now accepts a String path and handles the File conversion internally
  Future<String?> uploadFile(String filePath) async {
    return _upload(
      filePath: filePath,
      bytes: null,
      filename: p.basename(filePath),
    );
  }

  /// Keep this for Profile Pictures / Avatars
  Future<String?> uploadImage(File file) async {
    return uploadFile(file.path);
  }

  /// Keep this for Web compatibility
  Future<String?> uploadBytes(Uint8List bytes, {String filename = 'file.pdf'}) async {
    return _upload(
      filePath: null,
      bytes: bytes,
      filename: filename,
    );
  }

  /// Internal Logic Updated to handle Images, Videos, and PDFs
  Future<String?> _upload({
    String? filePath,
    Uint8List? bytes,
    required String filename,
  }) async {
    // Determine the resource type based on extension
    final extension = p.extension(filename).toLowerCase();
    String resourceType = 'auto'; // Default for Images/PDFs

    if (extension == '.mp4' || extension == '.mov' || extension == '.avi') {
      resourceType = 'video';
    }

    // Cloudinary URL changes based on resource type (image, video, or raw)
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload');

    try {
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset;

      if (filePath != null) {
        request.files.add(await http.MultipartFile.fromPath('file', filePath));
      } else if (bytes != null) {
        request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['secure_url'] as String?;
      } else {
        print('Cloudinary Error (${response.statusCode}): ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception during Cloudinary upload: $e');
      return null;
    }
  }
}