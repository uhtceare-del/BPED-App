import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'course_screen.dart';
import 'task_screen.dart';
import 'lesson_screen.dart';
import 'class_screen.dart';
import 'reviewer_screen.dart';
import 'submission_screen.dart';
import '../providers/auth_provider.dart';

final selectedModuleProvider = StateProvider<int>((ref) => 0);

class InstructorDashboard extends ConsumerWidget {
  const InstructorDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedModuleProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    Widget content;
    switch (selectedIndex) {
      case 0:
        content = const CourseScreen();
        break;
      case 1:
        content = const TaskScreen();
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

    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Instructor Dashboard"),
        actions: [
          CircleAvatar(
            radius: 18,
            backgroundImage: user?.avatarUrl.isNotEmpty == true
                ? NetworkImage(user!.avatarUrl)
                : null,
            child: user?.avatarUrl.isEmpty ?? true
                ? const Icon(Icons.person)
                : null,
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authControllerProvider).signOut();
            },
          ),
          const SizedBox(width: 10),
        ],
      ),

      body: screenWidth >= 700
          ? Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) =>
            ref.read(selectedModuleProvider.notifier).state = index,
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.book),
                label: Text('Courses'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.task),
                label: Text('Tasks'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.menu_book),
                label: Text('Lessons'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.class_),
                label: Text('Classes'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.upload_file),
                label: Text('Reviewers'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.assignment_turned_in),
                label: Text('Submissions'),
              ),
            ],
          ),

          const VerticalDivider(width: 1),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: content,
            ),
          ),
        ],
      )
          : Padding(
        padding: const EdgeInsets.all(16),
        child: content,
      ),

      bottomNavigationBar: screenWidth < 700
          ? BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) =>
        ref.read(selectedModuleProvider.notifier).state = index,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: "Courses",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task),
            label: "Tasks",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: "Lessons",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.class_),
            label: "Classes",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file),
            label: "Reviewers",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_turned_in),
            label: "Submissions",
          ),
        ],
      )
          : null,
    );
  }
}