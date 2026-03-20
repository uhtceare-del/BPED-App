import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/class_provider.dart'; // You'll create this next
import '../models/class_model.dart';

class ClassScreen extends ConsumerWidget {
  const ClassScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(allClassesProvider);

    return Scaffold(
      body: classesAsync.when(
        data: (classes) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: classes.length,
          itemBuilder: (context, index) {
            final section = classes[index];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.groups)),
                title: Text(section.className, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${section.subject} • ${section.schedule}"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Future: Show list of students in this class
                },
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddClassDialog(context, ref),
        label: const Text("Add Section"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _showAddClassDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final subjectController = TextEditingController();
    final schedController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Create New Section"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Class Name (e.g. BPED 1A)")),
            TextField(controller: subjectController, decoration: const InputDecoration(labelText: "Subject")),
            TextField(controller: schedController, decoration: const InputDecoration(labelText: "Schedule")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final newClass = ClassModel(
                id: '',
                className: nameController.text,
                subject: subjectController.text,
                schedule: schedController.text,
              );
              await ref.read(classRepositoryProvider).createClass(newClass);
              Navigator.pop(context);
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }
}