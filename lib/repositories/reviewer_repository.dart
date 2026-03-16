import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reviewer_model.dart';

class ReviewerRepository {
  final FirebaseFirestore firestore;
  ReviewerRepository(this.firestore);

  Stream<List<ReviewerModel>> getReviewersByClass(String classId) {
    return firestore
        .collection('reviewers')
        .where('classId', isEqualTo: classId)
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => ReviewerModel.fromFirestore(doc)) // pass the doc itself
        .toList());
  }
  Stream<List<ReviewerModel>> getAllReviewers() {
    return firestore
        .collection('reviewers')
        .snapshots()
        .map((snap) =>
        snap.docs.map((doc) => ReviewerModel.fromFirestore(doc)).toList());
  }

  Future<void> uploadReviewer(ReviewerModel reviewer) =>
      firestore.collection('reviewers').add(reviewer.toMap());

  Future<void> deleteReviewer(String id) =>
      firestore.collection('reviewers').doc(id).delete();
}