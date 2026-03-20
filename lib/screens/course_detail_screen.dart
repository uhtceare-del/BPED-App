import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phys_ed/widgets/video_player_widget.dart';
import 'package:phys_ed/widgets/pdf_viewer_widget.dart'; // Ensure this exists
import '../models/course_model.dart';
import '../providers/lesson_provider.dart'; // Uses your uploaded provider

class CourseDetailScreen extends ConsumerWidget {
  final CourseModel course;
  const CourseDetailScreen({super.key, required this.course});

  static const Color lnuNavy = Color(0xFF002147);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Uses your lessonsByCourseProvider from lesson_provider.dart
    final lessonsAsync = ref.watch(lessonsByCourseProvider(course.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(course.name,
            style: const TextStyle(color: lnuNavy, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: lnuNavy),
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. MAIN COURSE VIDEO (from CourseModel)
            if (course.videoUrl != null && course.videoUrl!.isNotEmpty)
              Container(
                height: 250,
                width: double.infinity,
                color: Colors.black,
                child: VideoPlayerWidget(
                  title: course.name,
                  urlOrPath: course.videoUrl!,
                  isOffline: false,
                ),
              )
            else
              _buildPlaceholder(),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader("COURSE DESCRIPTION"),
                  const SizedBox(height: 8),
                  Text(course.description,
                      style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87)),

                  const SizedBox(height: 30),
                  _buildHeader("LESSONS & MODULES"),
                  const Divider(),

                  // 2. DYNAMIC LESSON LIST (from LessonModel)
                  lessonsAsync.when(
                    data: (lessons) {
                      if (lessons.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text("No lessons available for this course.",
                              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                        );
                      }
                      return Column(
                        children: lessons.map((lesson) => _buildLessonTile(context, lesson)).toList(),
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(color: lnuNavy),
                      ),
                    ),
                    error: (err, _) => Text("Error: $err"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String text) {
    return Text(text,
        style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.blueGrey, fontSize: 11));
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 200, width: double.infinity, color: lnuNavy.withOpacity(0.05),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.play_circle_outline, size: 50, color: lnuNavy),
          Text("Course overview video unavailable", style: TextStyle(color: lnuNavy, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildLessonTile(BuildContext context, dynamic lesson) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: lnuNavy.withOpacity(0.1),
          child: Icon(
              lesson.pdfUrl != null && lesson.pdfUrl!.isNotEmpty
                  ? Icons.picture_as_pdf
                  : Icons.play_lesson,
              color: lnuNavy, size: 20
          ),
        ),
        title: Text(lesson.title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(lesson.category ?? "General",
            style: const TextStyle(fontSize: 11)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: () {
          // Priority: Open Video if available, else open PDF
          if (lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty) {
            _navigateToVideo(context, lesson);
          } else if (lesson.pdfUrl != null && lesson.pdfUrl!.isNotEmpty) {
            _navigateToPdf(context, lesson);
          }
        },
      ),
    );
  }

  void _navigateToVideo(BuildContext context, dynamic lesson) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(lesson.title)),
        body: VideoPlayerWidget(title: lesson.title, urlOrPath: lesson.videoUrl!, isOffline: false),
      ),
    ));
  }

  void _navigateToPdf(BuildContext context, dynamic lesson) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PdfViewerWidget(title: lesson.title, urlOrPath: lesson.pdfUrl!, isOffline: false),
    ));
  }
}