import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

final cloudinaryProvider = Provider<CloudinaryService>((ref) {
  return CloudinaryService();
});

class CloudinaryService {
  final String cloudName = 'duviaos3y';
  final String uploadPreset = 'daren_unsigned';

  /// Upload image from mobile (File path)
  Future<String?> uploadImage(File file) async {
    return _upload(
      filePath: file.path,
      bytes: null,
      filename: file.path.split(Platform.pathSeparator).last,
    );
  }

  /// Upload image from web/browser (bytes)
  Future<String?> uploadBytes(
      Uint8List bytes, {
        String filename = 'avatar.jpg',
      }) async {
    return _upload(
      filePath: null,
      bytes: bytes,
      filename: filename,
    );
  }

  /// Shared private upload logic (handles both File and bytes)
  Future<String?> _upload({
    String? filePath,
    Uint8List? bytes,
    required String filename,
  }) async {
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    try {
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset;

      // Attach the file (either from path or bytes)
      if (filePath != null) {
        request.files.add(await http.MultipartFile.fromPath('file', filePath));
      } else if (bytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
        ));
      } else {
        throw Exception('No file provided for upload');
      }

      // Optional: uncomment/add fields as needed (preset must allow them for unsigned)
      // request.fields['folder'] = 'phys_ed/avatars';
      // request.fields['public_id'] = 'user_${DateTime.now().millisecondsSinceEpoch}';
      // request.fields['tags'] = 'flutter,profile,signup';

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Cloudinary Upload - Status: ${response.statusCode}');
      print('Cloudinary Upload - Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final secureUrl = data['secure_url'] as String?;
        if (secureUrl != null && secureUrl.isNotEmpty) {
          print('Upload success! URL: $secureUrl');
          return secureUrl;
        } else {
          print('No secure_url found in successful response');
          return null;
        }
      } else {
        // Common errors:
        // 400 → Preset not Unsigned, invalid preset name, or disallowed param
        // "upload preset must be whitelisted for unsigned uploads" → Preset Signing Mode must be Unsigned
        print('Upload failed with status ${response.statusCode}');
        return null;
      }
    } catch (e, stack) {
      print('Exception during Cloudinary upload: $e');
      print('Stack trace: $stack');
      return null;
    }
  }
}