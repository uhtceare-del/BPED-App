import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../models/task_model.dart';
import 'create_task_screen.dart';
import 'create_question_screen.dart';

// --- THE MASTER KEY: SECURED TASK STREAM ---
final securedTasksStreamProvider = StreamProvider.autoDispose<List<TaskModel>>((
  ref,
) async* {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) {
    yield [];
    return;
  }

  final isInstructor = user.role.toLowerCase() == 'instructor';
  final db = FirebaseFirestore.instance;

  if (isInstructor) {
    // INSTRUCTOR: Only see tasks they created
    yield* db
        .collection('tasks')
        .where('instructorId', isEqualTo: user.uid)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => TaskModel.fromFirestore(doc)).toList(),
        );
  } else {
    // STUDENT: 1. Get classes they are enrolled in
    final classSnap = await db
        .collection('classes')
        .where('enrolledStudents', arrayContains: user.uid)
        .get();

    final enrolledClassIds = classSnap.docs.map((d) => d.id).toList();
    if (enrolledClassIds.isEmpty) {
      yield [];
      return;
    }

    // 2. See only tasks assigned to those classes
    yield* db
        .collection('tasks')
        .snapshots()
        .map(
          (snap) => snap.docs
              .where((doc) => enrolledClassIds.contains(doc.data()['classId']))
              .map((doc) => TaskModel.fromFirestore(doc))
              .toList(),
        );
  }
});

class TaskScreen extends ConsumerWidget {
  const TaskScreen({super.key});

  static const Color lnuNavy = Color(0xFF002147);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(securedTasksStreamProvider);
    final user = ref.watch(currentUserProvider).value;
    final isInstructor = user?.role.toLowerCase() == 'instructor';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Tasks & Quizzes',
          style: TextStyle(fontWeight: FontWeight.bold, color: lnuNavy),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: tasksAsync.when(
        data: (tasks) {
          if (tasks.isEmpty) {
            return Center(
              child: Text(
                isInstructor
                    ? 'No tasks created yet.'
                    : 'No tasks assigned to your classes.',
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (_, index) {
              final task = tasks[index];

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    task.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: lnuNavy,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.score_outlined,
                            size: 16,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text('${task.maxScore} pts'),
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Due: ${task.deadline.day}/${task.deadline.month}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
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
                              onPressed: () {
                                /* Navigate to Edit */
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('tasks')
                                    .doc(task.id)
                                    .delete();
                              },
                            ),
                          ],
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: () {
                    if (isInstructor) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CreateQuestionScreen(taskId: task.id),
                        ),
                      );
                    } else {
                      // Logic for Student to take the quiz or view submission
                    }
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
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateTaskScreen(),
                ),
              ),
              backgroundColor: lnuNavy,
              label: const Text(
                'New Task/Quiz',
                style: TextStyle(color: Colors.white),
              ),
              icon: const Icon(Icons.assignment_add, color: Colors.white),
            )
          : null,
    );
  }
}
