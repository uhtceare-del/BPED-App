import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'course_screen.dart';
import 'task_screen.dart';        // ← was CreateTaskScreen (wrong)
import 'lesson_screen.dart';
import 'class_screen.dart';
import 'reviewer_screen.dart';
import 'submission_screen.dart';

final selectedModuleProvider = StateProvider<int>((ref) => 0);

class InstructorDashboard extends ConsumerWidget {
  const InstructorDashboard({super.key});

  static const Color lnuNavy = Color(0xFF002147);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedModuleProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final userAsync = ref.watch(currentUserProvider);

    Widget content;
    switch (selectedIndex) {
      case 0:
        content = const CourseScreen();
        break;
      case 1:
        content = const TaskScreen();      // ← fixed: list first, create via FAB
        break;
      case 2:
        content = const LessonScreen();
        break;
      case 3:
        content = const ClassScreen();
        break;
      case 4:
        content = const ReviewerScreen();
        break;
      case 5:
        content = const SubmissionScreen();
        break;
      default:
        content = const CourseScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Instructor Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: lnuNavy,
        actions: [
          userAsync.when(
            data: (user) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white24,
                backgroundImage:
                (user?.avatarUrl != null && user!.avatarUrl.isNotEmpty)
                    ? NetworkImage(user.avatarUrl)
                    : null,
                child:
                (user?.avatarUrl == null || user!.avatarUrl.isEmpty)
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
            ),
            loading: () => const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2)),
            error: (_, __) =>
            const Icon(Icons.error_outline, color: Colors.white),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => ref.read(authControllerProvider).signOut(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: screenWidth >= 700
          ? _buildWideLayout(ref, selectedIndex, content)
          : Padding(padding: const EdgeInsets.all(16), child: content),
      bottomNavigationBar:
      screenWidth < 700 ? _buildBottomNav(ref, selectedIndex) : null,
    );
  }

  Widget _buildWideLayout(
      WidgetRef ref, int selectedIndex, Widget content) {
    return Row(
      children: [
        NavigationRail(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) =>
          ref.read(selectedModuleProvider.notifier).state = index,
          labelType: NavigationRailLabelType.all,
          selectedIconTheme: const IconThemeData(color: lnuNavy),
          selectedLabelTextStyle:
          const TextStyle(color: lnuNavy, fontWeight: FontWeight.bold),
          destinations: const [
            NavigationRailDestination(
                icon: Icon(Icons.book_outlined),
                selectedIcon: Icon(Icons.book),
                label: Text('Courses')),
            NavigationRailDestination(
                icon: Icon(Icons.task_outlined),
                selectedIcon: Icon(Icons.task),
                label: Text('Tasks')),
            NavigationRailDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book),
                label: Text('Lessons')),
            NavigationRailDestination(
                icon: Icon(Icons.groups_outlined),
                selectedIcon: Icon(Icons.groups),
                label: Text('Classes')),
            NavigationRailDestination(
                icon: Icon(Icons.upload_file_outlined),
                selectedIcon: Icon(Icons.upload_file),
                label: Text('Reviewers')),
            NavigationRailDestination(
                icon: Icon(Icons.assignment_outlined),
                selectedIcon: Icon(Icons.assignment_turned_in),
                label: Text('Submissions')),
          ],
        ),
        const VerticalDivider(width: 1),
        Expanded(
            child: Padding(
                padding: const EdgeInsets.all(16), child: content)),
      ],
    );
  }

  Widget _buildBottomNav(WidgetRef ref, int selectedIndex) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: (index) =>
      ref.read(selectedModuleProvider.notifier).state = index,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: lnuNavy,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Courses'),
        BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Tasks'),
        BottomNavigationBarItem(
            icon: Icon(Icons.menu_book), label: 'Lessons'),
        BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Classes'),
        BottomNavigationBarItem(
            icon: Icon(Icons.upload_file), label: 'Reviewers'),
        BottomNavigationBarItem(
            icon: Icon(Icons.assignment_turned_in), label: 'Submissions'),
      ],
    );
  }
}