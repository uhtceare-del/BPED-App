import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/class_model.dart';
import '../repositories/class_repository.dart';
import 'auth_provider.dart';

final classRepositoryProvider = Provider<ClassRepository>((ref) {
  return ClassRepository(ref.watch(firestoreProvider));
});

final classesProvider = StreamProvider<List<ClassModel>>((ref) {
  return ref.watch(classRepositoryProvider).getAllClasses();
});

final allClassesProvider = StreamProvider<List<ClassModel>>((ref) {
  return ref.watch(classRepositoryProvider).getAllClasses();
});