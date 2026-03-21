import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/course_model.dart';
import '../models/lesson_model.dart';
import '../providers/lesson_provider.dart';
import '../widgets/video_player_widget.dart';
import '../widgets/pdf_viewer_widget.dart';
import '../widgets/audio_player_widget.dart';
import '../widgets/download_button.dart';

class CourseDetailScreen extends ConsumerWidget {
  final CourseModel course;

  const CourseDetailScreen({super.key, required this.course});

  static const Color lnuNavy = Color(0xFF002147);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(lessonsByCourseProvider(course.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(course.name,
            style: const TextStyle(
                color: lnuNavy, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: lnuNavy),
        elevation: 0.5,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course description card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: lnuNavy.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: lnuNavy.withOpacity(0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('About this Course',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: lnuNavy,
                        fontSize: 13,
                        letterSpacing: 0.5)),
                const SizedBox(height: 6),
                Text(course.description,
                    style: TextStyle(
                        color: Colors.grey.shade700, fontSize: 13, height: 1.5)),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text('LESSONS',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 1.2,
                    color: Colors.blueGrey.shade600)),
          ),

          // Lessons list
          Expanded(
            child: lessonsAsync.when(
              data: (lessons) {
                if (lessons.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.menu_book_outlined,
                            size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        const Text('No lessons yet.',
                            style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: lessons.length,
                  itemBuilder: (context, index) {
                    final lesson = lessons[index];
                    return _LessonCard(lesson: lesson);
                  },
                );
              },
              loading: () =>
              const Center(child: CircularProgressIndicator(color: lnuNavy)),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final LessonModel lesson;

  const _LessonCard({required this.lesson});

  static const Color lnuNavy = Color(0xFF002147);

  @override
  Widget build(BuildContext context) {
    final hasVideo = lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty;
    final hasPdf = lesson.pdfUrl != null && lesson.pdfUrl!.isNotEmpty;
    final hasAudio = lesson.audioUrl != null && lesson.audioUrl!.isNotEmpty;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & category
            Row(
              children: [
                Expanded(
                  child: Text(lesson.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                if (lesson.category != null && lesson.category!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: lnuNavy.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(lesson.category!,
                        style: const TextStyle(
                            fontSize: 10,
                            color: lnuNavy,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            if (lesson.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(lesson.description,
                  style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
            if (hasVideo || hasPdf || hasAudio) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (hasVideo)
                    _MediaChip(
                      icon: Icons.play_circle_outline,
                      label: 'Video',
                      color: Colors.blue,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VideoPlayerWidget(
                            title: lesson.title,
                            urlOrPath: lesson.videoUrl!,
                            isOffline: false,
                          ),
                        ),
                      ),
                    ),
                  if (hasPdf)
                    _MediaChip(
                      icon: Icons.picture_as_pdf_outlined,
                      label: 'PDF',
                      color: Colors.red,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PdfViewerWidget(
                            title: lesson.title,
                            urlOrPath: lesson.pdfUrl!,
                            isOffline: false,
                          ),
                        ),
                      ),
                    ),
                  if (hasAudio)
                    _MediaChip(
                      icon: Icons.headphones_outlined,
                      label: 'Audio',
                      color: Colors.purple,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AudioPlayerWidget(
                            title: lesson.title,
                            urlOrPath: lesson.audioUrl!,
                            isOffline: false,
                          ),
                        ),
                      ),
                    ),
                  // Download button for the first available resource
                  if (hasPdf)
                    DownloadButton(
                      materialId: '${lesson.id}_pdf',
                      title: '${lesson.title} (PDF)',
                      url: lesson.pdfUrl!,
                      fileExtension: '.pdf',
                    )
                  else if (hasVideo)
                    DownloadButton(
                      materialId: '${lesson.id}_video',
                      title: '${lesson.title} (Video)',
                      url: lesson.videoUrl!,
                      fileExtension: '.mp4',
                    )
                  else if (hasAudio)
                      DownloadButton(
                        materialId: '${lesson.id}_audio',
                        title: '${lesson.title} (Audio)',
                        url: lesson.audioUrl!,
                        fileExtension: '.mp3',
                      ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MediaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MediaChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}