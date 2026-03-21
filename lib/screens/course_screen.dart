import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/course_provider.dart';
import '../providers/auth_provider.dart';
import '../models/course_model.dart';
import 'course_detail_screen.dart';

// --- 1. NEW HELPER: Find out who teaches this student ---
final studentInstructorsProvider = StreamProvider.autoDispose<List<String>>((
  ref,
) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null || user.role?.toLowerCase() == 'instructor')
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

// --- 2. THE FIX: SECURED MASTER-KEY COURSE STREAM ---
final securedCoursesStreamProvider =
    StreamProvider.autoDispose<List<CourseModel>>((ref) {
      final user = ref.watch(currentUserProvider).value;
      if (user == null) return Stream.value([]);

      final isInstructor = user.role?.toLowerCase() == 'instructor';
      final collection = FirebaseFirestore.instance.collection('courses');

      if (isInstructor) {
        return collection
            .where('instructorId', isEqualTo: user.uid)
            .snapshots()
            .map(
              (snapshot) => snapshot.docs.map((doc) {
                final data = doc.data();
                return CourseModel(
                  id: doc.id,
                  name: data['name'] ?? '',
                  description: data['description'] ?? '',
                  instructorId: data['instructorId'] ?? '',
                  videoUrl: data['videoUrl'] ?? '',
                  enrolledStudents: [],
                );
              }).toList(),
            );
      } else {
        final instructorIdsAsync = ref.watch(studentInstructorsProvider);

        return instructorIdsAsync.when(
          data: (instructorIds) {
            if (instructorIds.isEmpty) return Stream.value([]);

            return collection
                .where('instructorId', whereIn: instructorIds)
                .snapshots()
                .map(
                  (snapshot) => snapshot.docs.map((doc) {
                    final data = doc.data();
                    return CourseModel(
                      id: doc.id,
                      name: data['name'] ?? '',
                      description: data['description'] ?? '',
                      instructorId: data['instructorId'] ?? '',
                      videoUrl: data['videoUrl'] ?? '',
                      enrolledStudents: [],
                    );
                  }).toList(),
                );
          },
          loading: () => Stream.value([]),
          error: (_, __) => Stream.value([]),
        );
      }
    });

class CourseScreen extends ConsumerWidget {
  const CourseScreen({super.key});

  static const Color lnuNavy = Color(0xFF002147);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(securedCoursesStreamProvider);
    final currentUserAsync = ref.watch(currentUserProvider);
    final isInstructor =
        currentUserAsync.value?.role?.toLowerCase() == 'instructor';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Course Management',
          style: TextStyle(fontWeight: FontWeight.bold, color: lnuNavy),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: lnuNavy),
            onPressed: () => ref.refresh(securedCoursesStreamProvider),
          ),
        ],
      ),
      body: coursesAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: lnuNavy)),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (courses) {
          if (courses.isEmpty) {
            return _buildEmptyState(isInstructor);
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
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
                      color: lnuNavy.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.school_outlined, color: lnuNavy),
                  ),
                  title: Text(
                    course.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: lnuNavy,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      course.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  trailing: isInstructor
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: Colors.blueAccent,
                              ),
                              tooltip: "Edit Course",
                              onPressed: () =>
                                  _showEditCourseSheet(context, ref, course),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              tooltip: "Delete Course",
                              onPressed: () =>
                                  _showDeleteCourseDialog(context, course),
                            ),
                          ],
                        )
                      : const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CourseDetailScreen(course: course),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: isInstructor
          ? FloatingActionButton.extended(
              backgroundColor: lnuNavy,
              onPressed: () => _showCreateCourseSheet(context, ref),
              label: const Text(
                'New Course',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildEmptyState(bool isInstructor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            isInstructor
                ? 'No courses created yet.'
                : 'You are not enrolled in any courses.',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateCourseSheet(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (context, setModalState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 30,
              left: 24,
              right: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create New Course',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: lnuNavy,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  enabled: !isSubmitting,
                  decoration: const InputDecoration(
                    labelText: 'Course Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  enabled: !isSubmitting,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Course Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: lnuNavy,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final name = nameController.text.trim();
                            final desc = descController.text.trim();
                            if (name.isEmpty || desc.isEmpty) return;
                            setModalState(() => isSubmitting = true);
                            try {
                              final user = ref.read(currentUserProvider).value;
                              final newCourse = CourseModel(
                                id: '',
                                name: name,
                                description: desc,
                                instructorId: user?.uid ?? 'unknown',
                                videoUrl: '',
                                enrolledStudents: [],
                              );
                              await ref
                                  .read(courseRepositoryProvider)
                                  .createCourse(newCourse);
                              if (context.mounted) Navigator.pop(context);
                            } catch (e) {
                              setModalState(() => isSubmitting = false);
                            }
                          },
                    child: isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('CREATE COURSE'),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditCourseSheet(
    BuildContext context,
    WidgetRef ref,
    CourseModel course,
  ) {
    final nameController = TextEditingController(text: course.name);
    final descController = TextEditingController(text: course.description);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (context, setModalState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 30,
              left: 24,
              right: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edit Course',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: lnuNavy,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  enabled: !isSubmitting,
                  decoration: const InputDecoration(
                    labelText: 'Course Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  enabled: !isSubmitting,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Course Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            setModalState(() => isSubmitting = true);
                            try {
                              await FirebaseFirestore.instance
                                  .collection('courses')
                                  .doc(course.id)
                                  .update({
                                    'name': nameController.text.trim(),
                                    'description': descController.text.trim(),
                                  });
                              if (context.mounted) Navigator.pop(context);
                            } catch (e) {
                              setModalState(() => isSubmitting = false);
                            }
                          },
                    child: isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('SAVE CHANGES'),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteCourseDialog(BuildContext context, CourseModel course) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          "Delete Course",
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text("Delete '${course.name}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance
                  .collection('courses')
                  .doc(course.id)
                  .delete();
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
