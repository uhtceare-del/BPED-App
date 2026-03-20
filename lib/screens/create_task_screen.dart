import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';

class CreateTaskScreen extends ConsumerStatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _scoreController = TextEditingController(text: '100');

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  bool _isSaving = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    // Inside _saveTask method
    final newTask = TaskModel(
      id: '',
      title: _titleController.text,
      description: _descController.text,
      maxScore: int.tryParse(_scoreController.text) ?? 100,
      deadline: _selectedDate,
      lessonId: null, // or your specific lesson ID variable
      // REMOVE 'createdAt: ...' FROM HERE
    );

    try {
      // Use your existing task repository provider
      await ref.read(taskRepositoryProvider).createTask(newTask);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Task / Quiz')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Task Title',
                hintText: 'e.g., Midterm Quiz or Basketball Spike Demo',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'Enter a title' : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Instructions',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _scoreController,
                    decoration: const InputDecoration(labelText: 'Max Points', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_month),
                    label: Text('${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveTask,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator()
                  : const Text('Create Task & Go to Questions', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}