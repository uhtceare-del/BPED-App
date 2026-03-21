import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phys_ed/widgets/video_player_widget.dart';
import 'package:phys_ed/widgets/pdf_viewer_widget.dart';
import '../models/course_model.dart';
import '../providers/lesson_provider.dart';
// ADDED: Import your auth provider to check who is logged in
import '../providers/auth_provider.dart';

class CourseDetailScreen extends ConsumerWidget {
  final CourseModel course;
  const CourseDetailScreen({super.key, required this.course});

  static const Color lnuNavy = Color(0xFF002147);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Fetch the lessons
    final lessonsAsync = ref.watch(lessonsByCourseProvider(course.id));

    // 2. Fetch the current logged-in user
    final currentUser = ref.watch(currentUserProvider).value;

    // 3. Determine if the user is an instructor
    // NOTE: Change '.role' if your user_model.dart uses a different field name (like 'userType')
    final bool isInstructor = currentUser?.role?.toLowerCase() == 'instructor';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          course.name,
          style: const TextStyle(color: lnuNavy, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: lnuNavy),
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // MAIN COURSE VIDEO
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
                  Text(
                    course.description,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 30),
                  _buildHeader("LESSONS & MODULES"),
                  const Divider(),

                  // DYNAMIC LESSON LIST
                  lessonsAsync.when(
                    data: (lessons) {
                      if (lessons.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            "No lessons available for this course.",
                            style: TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        );
                      }
                      return Column(
                        // Pass the isInstructor boolean down to the tile builder!
                        children: lessons
                            .map(
                              (lesson) => _buildLessonTile(
                                context,
                                lesson,
                                isInstructor,
                              ),
                            )
                            .toList(),
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
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: Colors.blueGrey,
        fontSize: 11,
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 200,
      width: double.infinity,
      color: lnuNavy.withOpacity(0.05),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.play_circle_outline, size: 50, color: lnuNavy),
          Text(
            "Course overview video unavailable",
            style: TextStyle(color: lnuNavy, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // UPDATED: Now accepts the 'isInstructor' boolean
  Widget _buildLessonTile(
    BuildContext context,
    dynamic lesson,
    bool isInstructor,
  ) {
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
            color: lnuNavy,
            size: 20,
          ),
        ),
        title: Text(
          lesson.title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          lesson.category ?? "General",
          style: const TextStyle(fontSize: 11),
        ),

        // --- THE MAGIC HAPPENS HERE ---
        // If they are an instructor, show the Edit/Delete buttons.
        // If they are a student, just show the grey arrow!
        trailing: isInstructor
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: Colors.blueAccent,
                      size: 20,
                    ),
                    tooltip: "Edit Lesson",
                    onPressed: () => _showEditDialog(context, lesson),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    tooltip: "Delete Lesson",
                    onPressed: () => _showDeleteDialog(context, lesson),
                  ),
                ],
              )
            : const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),

        onTap: () {
          if (lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty) {
            _navigateToVideo(context, lesson);
          } else if (lesson.pdfUrl != null && lesson.pdfUrl!.isNotEmpty) {
            _navigateToPdf(context, lesson);
          }
        },
      ),
    );
  }

  // --- CRUD: EDIT DIALOG ---
  void _showEditDialog(BuildContext context, dynamic lesson) {
    final TextEditingController titleController = TextEditingController(
      text: lesson.title,
    );
    final TextEditingController categoryController = TextEditingController(
      text: lesson.category,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Edit Lesson",
          style: TextStyle(color: lnuNavy, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Lesson Title",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: "Category (e.g., Module 1)",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: lnuNavy),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirebaseFirestore.instance
                    .collection('lessons')
                    .doc(lesson.id)
                    .update({
                      'title': titleController.text.trim(),
                      'category': categoryController.text.trim(),
                    });

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Lesson updated successfully!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                debugPrint("Update error: $e");
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error updating: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              "SAVE CHANGES",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // --- CRUD: DELETE DIALOG ---
  void _showDeleteDialog(BuildContext context, dynamic lesson) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Delete Lesson",
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "Are you sure you want to permanently delete '${lesson.title}'?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirebaseFirestore.instance
                    .collection('lessons')
                    .doc(lesson.id)
                    .delete();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Lesson deleted!"),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              } catch (e) {
                debugPrint("Delete error: $e");
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error deleting: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _navigateToVideo(BuildContext context, dynamic lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(lesson.title)),
          body: VideoPlayerWidget(
            title: lesson.title,
            urlOrPath: lesson.videoUrl!,
            isOffline: false,
          ),
        ),
      ),
    );
  }

  void _navigateToPdf(BuildContext context, dynamic lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerWidget(
          title: lesson.title,
          urlOrPath: lesson.pdfUrl!,
          isOffline: false,
        ),
      ),
    );
  }
}
