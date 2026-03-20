import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/task_provider.dart';
import '../models/task_model.dart';
import 'create_task_screen.dart'; // You'll need this screen to set Title/Deadline
import 'create_question_screen.dart'; // The screen we just talked about

class TaskScreen extends ConsumerWidget {
  const TaskScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(allTasksProvider);

    return Scaffold(
      // We wrap the content in a Scaffold to enable the FloatingActionButton
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: tasksAsync.when(
          data: (tasks) {
            if (tasks.isEmpty) {
              return const Center(child: Text('No tasks or quizzes created yet.'));
            }

            return ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (_, index) {
                final TaskModel task = tasks[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      task.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(task.description),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.score_outlined, size: 16),
                            const SizedBox(width: 4),
                            Text('${task.maxScore} pts'),
                            const SizedBox(width: 16),
                            const Icon(Icons.calendar_today, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Due: ${task.deadline.day}/${task.deadline.month}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.add_circle_outline, color: Colors.blue),
                    onTap: () {
                      // Navigate to add questions to THIS specific task
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateQuestionScreen(taskId: task.id),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),

      // The FAB to create the Task "Container" itself
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to a screen to define Task Name, Max Score, and Deadline
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTaskScreen()),
          );
        },
        label: const Text('New Task/Quiz'),
        icon: const Icon(Icons.assignment_add),
      ),
    );
  }
}