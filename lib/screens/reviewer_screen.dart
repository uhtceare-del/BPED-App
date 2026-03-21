import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/reviewer_provider.dart';
import '../providers/cloudinary_provider.dart';
import '../providers/auth_provider.dart';
import '../models/reviewer_model.dart';
import '../widgets/pdf_viewer_widget.dart';

class ReviewerScreen extends ConsumerWidget {
  const ReviewerScreen({super.key});

  static const Color lnuNavy = Color(0xFF002147);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewersAsync = ref.watch(allReviewersProvider);

    return Scaffold(
      body: reviewersAsync.when(
        data: (reviewers) {
          if (reviewers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.upload_file,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('No reviewers uploaded yet.',
                      style: TextStyle(
                          color: Colors.grey, fontWeight: FontWeight.bold)),
                  const Text('Tap the button below to upload one.',
                      style:
                          TextStyle(color: Colors.black38, fontSize: 12)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reviewers.length,
            itemBuilder: (_, index) {
              final reviewer = reviewers[index];
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.picture_as_pdf,
                        color: Colors.red, size: 22),
                  ),
                  title: Text(reviewer.title,
                      style:
                          const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Category: ${reviewer.category}',
                      style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right,
                      color: Colors.grey),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PdfViewerWidget(
                        title: reviewer.title,
                        urlOrPath: reviewer.fileUrl,
                        isOffline: false,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: lnuNavy,
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20))),
          builder: (_) => const _UploadReviewerSheet(),
        ),
        label: const Text('Upload Reviewer',
            style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.upload_file, color: Colors.white),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Upload sheet — web uses bytes, mobile uses file path
// ---------------------------------------------------------------------------
class _UploadReviewerSheet extends ConsumerStatefulWidget {
  const _UploadReviewerSheet();

  @override
  ConsumerState<_UploadReviewerSheet> createState() =>
      _UploadReviewerSheetState();
}

class _UploadReviewerSheetState
    extends ConsumerState<_UploadReviewerSheet> {
  static const Color lnuNavy = Color(0xFF002147);

  final _titleController = TextEditingController();
  String? _selectedCategory;

  String? _filePath;      // mobile only
  Uint8List? _fileBytes;  // web only
  String? _fileName;

  bool _isUploading = false;

  bool get _hasFile => kIsWeb ? _fileBytes != null : _filePath != null;

  final List<String> _categories = [
    'Anatomy',
    'Kinesiology',
    'Sports Psychology',
    'Pedagogy',
    'Sports Management',
    'General',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    FocusScope.of(context).unfocus();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: kIsWeb, // required on web to receive bytes
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    setState(() {
      _fileName = file.name;
      if (kIsWeb) {
        _fileBytes = file.bytes;
        _filePath = null;
      } else {
        _filePath = file.path;
        _fileBytes = null;
      }
    });
  }

  Future<void> _upload() async {
    if (_titleController.text.trim().isEmpty) {
      _snack('Please enter a title.');
      return;
    }
    if (_selectedCategory == null) {
      _snack('Please select a category.');
      return;
    }
    if (!_hasFile) {
      _snack('Please pick a PDF file first.');
      return;
    }

    setState(() => _isUploading = true);

    try {
      final cloudinary = ref.read(cloudinaryProvider);
      final instructorId =
          ref.read(authControllerProvider).currentUser?.uid ?? '';

      String? url;
      if (kIsWeb) {
        url = await cloudinary.uploadBytes(
          _fileBytes!,
          filename: _fileName ?? 'reviewer.pdf',
        );
      } else {
        url = await cloudinary.uploadPdf(_filePath!);
      }

      if (url == null || url.isEmpty) {
        throw Exception(
          'Cloudinary returned no URL. '
          'Ensure your upload preset allows "raw" files.',
        );
      }

      final reviewer = ReviewerModel(
        id: '',
        title: _titleController.text.trim(),
        fileUrl: url,
        category: _selectedCategory!,
        uploadedAt: DateTime.now(),
        instructorId: instructorId, // ← scopes reviewer to this instructor
      );

      await ref.read(reviewerRepositoryProvider).uploadReviewer(reviewer);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reviewer uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        _snack('Upload failed: $e');
      }
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 28,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Upload Reviewer PDF',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: lnuNavy)),
          const SizedBox(height: 20),

          // Title
          TextField(
            controller: _titleController,
            enabled: !_isUploading,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
                labelText: 'Title', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 14),

          // Category
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(
                labelText: 'Category', border: OutlineInputBorder()),
            items: _categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: _isUploading
                ? null
                : (v) => setState(() => _selectedCategory = v),
          ),
          const SizedBox(height: 14),

          // File picker
          InkWell(
            onTap: _isUploading ? null : _pickFile,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _hasFile
                    ? Colors.red.shade50
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: _hasFile
                        ? Colors.red.shade300
                        : Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    _hasFile ? Icons.picture_as_pdf : Icons.attach_file,
                    color: _hasFile ? Colors.red : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _fileName ?? 'Tap to pick a PDF file',
                      style: TextStyle(
                          color:
                              _hasFile ? Colors.black87 : Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_hasFile)
                    const Icon(Icons.check_circle,
                        color: Colors.red, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Upload button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: lnuNavy,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isUploading ? null : _upload,
              child: _isUploading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Uploading…',
                            style: TextStyle(color: Colors.white)),
                      ],
                    )
                  : const Text('UPLOAD',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
