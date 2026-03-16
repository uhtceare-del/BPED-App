import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/class_provider.dart';
import '../models/class_model.dart';

class ClassScreen extends ConsumerWidget {
  const ClassScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(allClassesProvider);

    return classesAsync.when(
      data: (classes) {
        if (classes.isEmpty) {
          return const Center(child: Text('No classes available.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: classes.length,
          itemBuilder: (_, index) {
            final ClassModel c = classes[index];

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text(c.name),
                subtitle: Text('Year Level: ${c.yearLevel}'),
                trailing: Text(
                  c.createdAt.toLocal().toString().split(' ')[0],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}