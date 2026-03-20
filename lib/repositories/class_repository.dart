import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/class_model.dart';



class ClassRepository {
  final FirebaseFirestore _firestore;
  ClassRepository(this._firestore);

  Stream<List<ClassModel>> getClasses() {
    return _firestore.collection('classes').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => ClassModel.fromFirestore(doc)).toList());
  }

  Future<void> createClass(ClassModel classData) async {
    await _firestore.collection('classes').add(classData.toMap());
  }

}