import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path/path.dart' as p;

final cloudinaryProvider = Provider<CloudinaryService>((ref) {
  return CloudinaryService();
});

class CloudinaryService {
  final String cloudName = 'duviaos3y';
  final String uploadPreset = 'daren_unsigned';

  // --- FOR MOBILE UPLOADS ---
  Future<String?> uploadFile(String filePath) async {
    return _upload(
      filePath: filePath,
      bytes: null,
      filename: p.basename(filePath),
    );
  }

  // --- FOR PROFILE PICTURES ---
  Future<String?> uploadImage(File file) async {
    return uploadFile(file.path);
  }

  // --- THE FIX: FOR WEB UPLOADS ---
  // Matches the exact call in create_lesson_screen.dart
  Future<String?> uploadFileBytes(Uint8List bytes, String filename) async {
    return _upload(filePath: null, bytes: bytes, filename: filename);
  }

  // --- INTERNAL UPLOAD LOGIC ---
  Future<String?> _upload({
    String? filePath,
    Uint8List? bytes,
    required String filename,
  }) async {
    // Cloudinary best practice: use 'auto' to let their servers automatically
    // detect if the file is an image, a video (mp4), or a raw file (pdf).
    String resourceType = 'auto';

    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload',
    );

    try {
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset;

      if (filePath != null) {
        request.files.add(await http.MultipartFile.fromPath('file', filePath));
      } else if (bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: filename),
        );
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
