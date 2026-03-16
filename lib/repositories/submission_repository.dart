import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/submission_model.dart';

class SubmissionRepository {
  final FirebaseFirestore firestore;
  SubmissionRepository(this.firestore);

  Stream<List<SubmissionModel>> getAllSubmissions() {
    return firestore.collection('submissions').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => SubmissionModel.fromFirestore(doc)).toList());
  }

  Stream<List<SubmissionModel>> getSubmissionsByTask(String taskId) {
    return firestore
        .collection('submissions')
        .where('taskId', isEqualTo: taskId)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => SubmissionModel.fromFirestore(doc)).toList());
  }
}