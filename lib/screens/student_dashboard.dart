import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/course_provider.dart';
import '../providers/auth_provider.dart';
import '../models/course_model.dart';
import '../providers/student_provider.dart';

class StudentDashboard extends ConsumerStatefulWidget {
  const StudentDashboard({super.key});

  @override
  ConsumerState<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends ConsumerState<StudentDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Dashboard')),
      body: _buildPage(ref),
      drawer: Drawer(
        child: Column(
          children: [
            const DrawerHeader(child: Text('Menu', style: TextStyle(fontSize: 24))),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: const Icon(Icons.book),
                    title: const Text('Courses'),
                    selected: _selectedIndex == 0,
                    onTap: () => setState(() => _selectedIndex = 0),
                  ),
                  ListTile(
                    leading: const Icon(Icons.task),
                    title: const Text('Tasks'),
                    selected: _selectedIndex == 1,
                    onTap: () => setState(() => _selectedIndex = 1),
                  ),
                  ListTile(
                    leading: const Icon(Icons.menu_book),
                    title: const Text('Lessons'),
                    selected: _selectedIndex == 2,
                    onTap: () => setState(() => _selectedIndex = 2),
                  ),
                  ListTile(
                    leading: const Icon(Icons.rate_review),
                    title: const Text('Reviewers'),
                    selected: _selectedIndex == 3,
                    onTap: () => setState(() => _selectedIndex = 3),
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: () async {
                await ref.read(authControllerProvider).signOut();
                if (!mounted) return;
                Navigator.of(context).popUntil((route) => route.isFirst); // go back to login
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(WidgetRef ref) {
    switch (_selectedIndex) {
      case 0:
        return _buildCoursesPage(ref);
      case 1:
        return _buildTasksPage(ref);
      case 2:
        return _buildLessonsPage(ref);
      case 3:
        return _buildReviewersPage(ref);
      default:
        return const Center(child: Text('Page not found'));
    }
  }

  Widget _buildCoursesPage(WidgetRef ref) {
    final enrolledCoursesAsync = ref.watch(studentCoursesProvider);

    return enrolledCoursesAsync.when(
      data: (enrolledCourses) {
        if (enrolledCourses.isEmpty) {
          return Center(
            child: ElevatedButton(
              onPressed: () => _showCourseSelection(context, ref),
              child: const Text('Enroll in a course'),
            ),
          );
        }

        final studentId = ref.read(authControllerProvider).currentUser!.uid;

        return ListView.builder(
          itemCount: enrolledCourses.length,
          itemBuilder: (context, index) {
            final course = enrolledCourses[index];
            final isEnrolled = course.enrolledStudents?.contains(studentId) ?? false;

            return ListTile(
              title: Text(course.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.description),
                  if (isEnrolled)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'You are enrolled in: ${course.name}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                ],
              ),
              trailing: isEnrolled
                  ? null // Button disappears if enrolled
                  : ElevatedButton(
                onPressed: () async {
                  await ref.read(courseRepositoryProvider).enrollStudentInCourse(
                    courseId: course.id,
                    studentId: studentId,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Enrolled in ${course.name}')),
                  );
                  setState(() {}); // refresh UI to hide button
                },
                child: const Text('Enroll'),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildTasksPage(WidgetRef ref) {
    // TODO: Connect to tasks provider
    return const Center(child: Text('Tasks Page'));
  }

  Widget _buildLessonsPage(WidgetRef ref) {
    // TODO: Connect to lessons provider
    return const Center(child: Text('Lessons Page'));
  }

  Widget _buildReviewersPage(WidgetRef ref) {
    // TODO: Connect to reviewers provider
    return const Center(child: Text('Reviewers Page'));
  }

  void _showCourseSelection(BuildContext context, WidgetRef ref) async {
    final availableCourses = await ref.read(courseRepositoryProvider).getAllCoursesOnce();

    if (availableCourses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No courses available for enrollment')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        CourseModel? selectedCourse;
        return AlertDialog(
          title: const Text('Select Course'),
          content: DropdownButtonFormField<CourseModel>(
            items: availableCourses.map((course) {
              return DropdownMenuItem<CourseModel>(
                value: course,
                child: Text(course.name),
              );
            }).toList(),
            onChanged: (course) => selectedCourse = course,
            decoration: const InputDecoration(labelText: 'Course'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedCourse != null) {
                  await ref.read(courseRepositoryProvider).enrollStudentInCourse(
                    courseId: selectedCourse!.id,
                    studentId: ref.read(authControllerProvider).currentUser!.uid,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Enrolled in ${selectedCourse!.name}')),
                  );
                }
              },
              child: const Text('Enroll'),
            ),
          ],
        );
      },
    );
  }
}