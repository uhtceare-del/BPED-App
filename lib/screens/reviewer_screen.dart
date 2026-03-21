import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:file_picker/file_picker.dart';

import '../providers/auth_provider.dart';
import '../providers/cloudinary_provider.dart';
import '../models/reviewer_model.dart';

// --- 1. NEW HELPER: Find out who teaches this student ---
final studentInstructorsForReviewersProvider =
    StreamProvider.autoDispose<List<String>>((ref) {
      final user = ref.watch(currentUserProvider).value;
      if (user == null || user.role.toLowerCase() == 'instructor')
        return Stream.value([]);

      return FirebaseFirestore.instance
          .collection('classes')
          .where('enrolledStudents', arrayContains: user.uid)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => doc.data()['instructorId'] as String)
                .toSet()
                .toList(),
          );
    });

// --- 2. THE FIX: SECURED MASTER-KEY REVIEWER STREAM ---
final securedReviewersStreamProvider =
    StreamProvider.autoDispose<List<ReviewerModel>>((ref) async* {
      final user = ref.watch(currentUserProvider).value;
      if (user == null) {
        yield [];
        return;
      }

      final isInstructor = user.role.toLowerCase() == 'instructor';
      final db = FirebaseFirestore.instance;

      if (isInstructor) {
        // INSTRUCTOR: See reviewers they uploaded
        yield* db
            .collection('reviewers')
            .where('instructorId', isEqualTo: user.uid)
            .snapshots()
            .map(
              (snapshot) => snapshot.docs
                  .map((doc) => ReviewerModel.fromFirestore(doc))
                  .toList(),
            );
      } else {
        // STUDENT: Use the Master Key helper provider
        final instructorIdsAsync = ref.watch(
          studentInstructorsForReviewersProvider,
        );

        // Yield empty if the helper is still loading or throws an error
        if (instructorIdsAsync.isLoading || instructorIdsAsync.hasError) {
          yield [];
          return;
        }

        final instructorIds = instructorIdsAsync.value ?? [];
        if (instructorIds.isEmpty) {
          yield [];
          return;
        }

        // Fetch all reviewers uploaded by their instructors
        yield* db
            .collection('reviewers')
            .where('instructorId', whereIn: instructorIds)
            .snapshots()
            .map(
              (snapshot) => snapshot.docs
                  .map((doc) => ReviewerModel.fromFirestore(doc))
                  .toList(),
            );
      }
    });
// --------------------------------------------------

class ReviewerScreen extends ConsumerStatefulWidget {
  const ReviewerScreen({super.key});

  @override
  ConsumerState<ReviewerScreen> createState() => _ReviewerScreenState();
}

class _ReviewerScreenState extends ConsumerState<ReviewerScreen> {
  static const Color lnuNavy = Color(0xFF002147);

  // Track downloading state for individual files to show progress spinners
  final Map<String, bool> _downloadingMap = {};
  final Map<String, double> _progressMap = {};

  // --- DOWNLOAD AND OPEN OFFLINE LOGIC ---
  Future<void> _downloadAndOpenReviewer(ReviewerModel reviewer) async {
    // Prevent multiple clicks while downloading
    if (_downloadingMap[reviewer.id] == true) return;

    // Check if the file actually has a URL
    if (reviewer.fileUrl == null || reviewer.fileUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No file URL found for this reviewer.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _downloadingMap[reviewer.id] = true;
      _progressMap[reviewer.id] = 0.0;
    });

    try {
      // 1. Get the local storage directory on the phone
      final directory = await getApplicationDocumentsDirectory();

      // Clean up the filename so it saves safely
      final fileName =
          (reviewer.title ?? 'reviewer').replaceAll(
            RegExp(r'[^a-zA-Z0-9_\-\.]'),
            '_',
          ) +
          '.pdf';
      final savePath = '${directory.path}/$fileName';
      final file = File(savePath);

      // 2. Check if the file is ALREADY downloaded (Offline Access!)
      if (await file.exists()) {
        debugPrint("DEBUG: File already exists offline. Opening...");
        setState(() => _downloadingMap[reviewer.id] = false);
        await OpenFile.open(savePath);
        return;
      }

      // 3. If not downloaded, fetch it from Firebase Storage
      debugPrint("DEBUG: Downloading file to $savePath");
      final dio = Dio();
      await dio.download(
        reviewer.fileUrl!,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _progressMap[reviewer.id] = received / total;
            });
          }
        },
      );

      // 4. Download complete! Open the file natively.
      debugPrint("DEBUG: Download complete. Opening file.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download complete. Opening...'),
            backgroundColor: Colors.green,
          ),
        );
      }

      await OpenFile.open(savePath);
    } catch (e) {
      debugPrint("DEBUG: Download error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _downloadingMap[reviewer.id] = false);
      }
    }
  }

  // --- WEB & MOBILE SAFE FILE UPLOAD LOGIC ---
  Future<void> _handleFileUpload(BuildContext context, WidgetRef ref) async {
    // 1. Pick the file safely
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: kIsWeb, // CRITICAL: Grabs raw bytes for Chrome!
    );

    if (result == null) return; // User canceled the picker

    final file = result.files.single;
    final fileName = file.name;
    final user = ref.read(currentUserProvider).value;

    if (user == null) return;

    // Show a loading spinner while uploading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: lnuNavy)),
    );

    try {
      String? remoteUrl;

      // 2. Upload safely based on the platform
      if (kIsWeb && file.bytes != null) {
        remoteUrl = await ref
            .read(cloudinaryProvider)
            .uploadFileBytes(file.bytes!, fileName);
      } else if (!kIsWeb && file.path != null) {
        remoteUrl = await ref.read(cloudinaryProvider).uploadFile(file.path!);
      }

      if (remoteUrl == null) throw Exception("Failed to upload to Cloudinary");

      // 3. Save the Reviewer details to Firestore
      await FirebaseFirestore.instance.collection('reviewers').add({
        'title': fileName,
        'fileUrl': remoteUrl,
        'instructorId': user.uid,
        'category': 'General',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        Navigator.pop(context); // Close the loading spinner
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Reviewer uploaded successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close the loading spinner
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Upload Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewersAsync = ref.watch(securedReviewersStreamProvider);
    final currentUser = ref.watch(currentUserProvider).value;
    final isInstructor = currentUser?.role.toLowerCase() == 'instructor';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Reviewers & Handouts',
          style: TextStyle(fontWeight: FontWeight.bold, color: lnuNavy),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: lnuNavy),
      ),
      body: reviewersAsync.when(
        data: (reviewers) {
          if (reviewers.isEmpty) {
            return _buildEmptyState(isInstructor);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reviewers.length,
            itemBuilder: (_, index) {
              final reviewer = reviewers[index];
              final isDownloading = _downloadingMap[reviewer.id] ?? false;
              final progress = _progressMap[reviewer.id] ?? 0.0;

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  ),
                  title: Text(
                    reviewer.title ?? 'Unnamed File',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: lnuNavy,
                    ),
                  ),
                  subtitle: Text(
                    'Category: ${reviewer.category ?? "General"}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  trailing: isDownloading
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 3,
                            color: lnuNavy,
                          ),
                        )
                      : const Icon(
                          Icons.download_rounded,
                          color: Colors.blueGrey,
                        ),
                  onTap: () => _downloadAndOpenReviewer(reviewer),
                ),
              );
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: lnuNavy)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: isInstructor
          ? FloatingActionButton.extended(
              backgroundColor: lnuNavy,
              onPressed: () => _handleFileUpload(context, ref),
              label: const Text(
                "Upload Reviewer",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              icon: const Icon(Icons.upload_file, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildEmptyState(bool isInstructor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.picture_as_pdf_rounded,
              size: 80,
              color: Colors.red.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Reviewers Available',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: lnuNavy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isInstructor
                ? 'Tap the button below to upload a PDF.'
                : 'Your instructors have not uploaded any reviewers yet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
