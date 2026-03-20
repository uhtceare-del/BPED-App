import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/course_provider.dart';
import 'course_detail_screen.dart'; // Import your detail screen

class CourseScreen extends ConsumerWidget {
  const CourseScreen({super.key});

  static const Color lnuNavy = Color(0xFF002147);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(allCoursesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Course Management',
            style: TextStyle(fontWeight: FontWeight.bold, color: lnuNavy)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: lnuNavy),
            onPressed: () => ref.refresh(allCoursesProvider),
          ),
        ],
      ),

      body: coursesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: lnuNavy)),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (courses) {
          if (courses.isEmpty) {
            return _buildEmptyState();
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
                    style: const TextStyle(fontWeight: FontWeight.bold, color: lnuNavy),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      course.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    // 🚀 NAVIGATE TO DETAIL SCREEN
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CourseDetailScreen(course: course),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: lnuNavy,
        onPressed: () => _showCreateCourseSheet(context, ref),
        label: const Text('New Course', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'No courses created yet.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const Text('Tap the button below to add your first course.',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _showCreateCourseSheet(BuildContext context, WidgetRef ref) {
    // You should use TextControllers here to capture the input
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 30, left: 24, right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Create New Course',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: lnuNavy)),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Course Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
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
                style: ElevatedButton.styleFrom(backgroundColor: lnuNavy, foregroundColor: Colors.white),
                onPressed: () {
                  // TODO: Call your CourseRepository.createCourse method here
                  Navigator.pop(context);
                },
                child: const Text('CREATE COURSE', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}