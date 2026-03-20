import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/class_model.dart';
import '../repositories/class_repository.dart';

// 1. The Repository Provider
// This provides the actual ClassRepository instance to the rest of the app
final classRepositoryProvider = Provider<ClassRepository>((ref) {
  return ClassRepository(FirebaseFirestore.instance);
});

// 2. The Stream Provider
// This automatically listens to Firestore and updates the UI whenever
// a new section is added or edited.
final allClassesProvider = StreamProvider<List<ClassModel>>((ref) {
  final repository = ref.watch(classRepositoryProvider);
  return repository.getClasses();
});