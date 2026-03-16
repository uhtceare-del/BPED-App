import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/class_model.dart';

class ClassRepository {
  final FirebaseFirestore firestore;
  ClassRepository(this.firestore);

  Stream<List<ClassModel>> getAllClasses() {
    return firestore.collection('classes').snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => ClassModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Stream<ClassModel?> getClassById(String classId) {
    return firestore.collection('classes').doc(classId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return ClassModel.fromFirestore(doc.data()!, doc.id);
    });
  }
}