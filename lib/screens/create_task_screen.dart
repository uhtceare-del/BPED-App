import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../providers/auth_provider.dart';

class CreateTaskScreen extends ConsumerStatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  static const Color lnuNavy = Color(0xFF002147);

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

  Future<String?> _showSelectClassDialog(String instructorId) async {
    final classesSnapshot = await FirebaseFirestore.instance
        .collection('classes')
        .where('instructorId', isEqualTo: instructorId)
        .get();

    final classes = classesSnapshot.docs;

    if (classes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Create a class first!"),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return null;
    }

    String? chosenClassId;

    return await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                "Assign to Class",
                style: TextStyle(color: lnuNavy, fontWeight: FontWeight.bold),
              ),
              content: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Select Class",
                ),
                items: classes
                    .map(
                      (doc) => DropdownMenuItem(
                        value: doc.id,
                        child: Text(doc.data()['className'] ?? 'Unnamed'),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setDialogState(() => chosenClassId = val),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text("CANCEL"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: lnuNavy),
                  onPressed: chosenClassId == null
                      ? null
                      : () => Navigator.pop(context, chosenClassId),
                  child: const Text(
                    "ASSIGN",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    String? selectedClassId = await _showSelectClassDialog(user.uid);
    if (selectedClassId == null) return;

    setState(() => _isSaving = true);

    final newTask = TaskModel(
      id: '',
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      maxScore: int.tryParse(_scoreController.text) ?? 100,
      deadline: _selectedDate,
      lessonId: null,
      instructorId: user.uid,
      classId: selectedClassId,
    );

    try {
      await ref.read(taskRepositoryProvider).createTask(newTask);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'New Task / Quiz',
          style: TextStyle(fontWeight: FontWeight.bold, color: lnuNavy),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Task Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Instructions',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _scoreController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Max Points',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_month),
                    label: Text(
                      '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: lnuNavy,
                minimumSize: const Size(double.infinity, 55),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'ASSIGN TO CLASS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
