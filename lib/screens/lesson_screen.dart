import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lesson_model.dart';
import '../providers/auth_provider.dart';
import 'create_lesson_screen.dart';

// --- 1. NEW HELPER: Find out who teaches this student ---
final studentInstructorsForLessonsProvider =
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

// --- 2. THE FIX: SECURED MASTER-KEY LESSON STREAM ---
final securedLessonsStreamProvider =
    StreamProvider.autoDispose<List<LessonModel>>((ref) async* {
      final user = ref.watch(currentUserProvider).value;
      if (user == null) {
        yield [];
        return;
      }

      final isInstructor = user.role.toLowerCase() == 'instructor';
      final db = FirebaseFirestore.instance;

      if (isInstructor) {
        // INSTRUCTOR: Only see lessons they created themselves
        yield* db
            .collection('lessons')
            .where('instructorId', isEqualTo: user.uid)
            .snapshots()
            .map(
              (snapshot) => snapshot.docs
                  .map((doc) => LessonModel.fromFirestore(doc))
                  .toList(),
            );
      } else {
        // STUDENT: Use the Master Key helper provider
        final instructorIdsAsync = ref.watch(
          studentInstructorsForLessonsProvider,
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

        // Fetch all lessons uploaded by their instructors
        yield* db
            .collection('lessons')
            .where('instructorId', whereIn: instructorIds)
            .snapshots()
            .map(
              (snapshot) => snapshot.docs
                  .map((doc) => LessonModel.fromFirestore(doc))
                  .toList(),
            );
      }
    });
// --------------------------------------------------

class LessonScreen extends ConsumerWidget {
  const LessonScreen({super.key});

  static const Color lnuNavy = Color(0xFF002147);

  // --- CRUD: DELETE LESSON ---
  void _showDeleteLessonDialog(BuildContext context, LessonModel lesson) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          "Delete Lesson",
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text("Are you sure you want to delete '${lesson.title}'?"),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(securedLessonsStreamProvider);
    final currentUser = ref.watch(currentUserProvider).value;
    final isInstructor = currentUser?.role.toLowerCase() == 'instructor';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Lessons & Modules',
          style: TextStyle(fontWeight: FontWeight.bold, color: lnuNavy),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: lnuNavy),
      ),
      body: lessonsAsync.when(
        data: (lessons) {
          if (lessons.isEmpty) {
            return _buildEmptyState(isInstructor);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lessons.length,
            itemBuilder: (_, index) {
              final lesson = lessons[index];

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
                      color: lesson.videoUrl != null
                          ? Colors.red.withOpacity(0.1)
                          : lnuNavy.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      lesson.videoUrl != null
                          ? Icons.play_circle_fill
                          : Icons.description,
                      color: lesson.videoUrl != null
                          ? Colors.redAccent
                          : lnuNavy,
                    ),
                  ),
                  title: Text(
                    lesson.title ?? 'Unnamed Lesson',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: lnuNavy,
                    ),
                  ),
                  subtitle: Text(
                    lesson.description ?? 'No description provided.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  // --- EDIT & DELETE ICONS FOR INSTRUCTOR ---
                  trailing: isInstructor
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: Colors.blueAccent,
                              ),
                              tooltip: "Edit Lesson",
                              onPressed: () {
                                // TODO: Navigate to an EditLessonScreen and pass the 'lesson' object to it
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Routing to Edit Screen..."),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              tooltip: "Delete Lesson",
                              onPressed: () =>
                                  _showDeleteLessonDialog(context, lesson),
                            ),
                          ],
                        )
                      : const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    // Navigate to Lesson Detail/Preview
                  },
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateLessonScreen(),
                  ),
                );
              },
              backgroundColor: lnuNavy,
              foregroundColor: Colors.white,
              label: const Text(
                'Create Lesson',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              icon: const Icon(Icons.add),
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
              color: lnuNavy.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.play_lesson_rounded,
              size: 80,
              color: lnuNavy.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Lessons Available',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: lnuNavy,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              isInstructor
                  ? 'Tap the button below to publish your first lesson.'
                  : 'You are not enrolled in any courses with active lessons right now.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
