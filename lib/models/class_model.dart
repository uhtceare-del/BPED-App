class ClassModel {
  final String id;
  final String className; // e.g., BPED 2-B
  final String subject; // e.g., Team Sports
  final String schedule; // e.g., Mon/Wed 1:00PM - 2:30PM

  // --- NEW SECURITY FIELDS ---
  final String instructorId;
  final List<String>? enrolledStudents;

  ClassModel({
    required this.id,
    required this.className,
    required this.subject,
    required this.schedule,
    required this.instructorId, // Added here
    this.enrolledStudents, // Added here
  });

  Map<String, dynamic> toMap() {
    return {
      'className': className,
      'subject': subject,
      'schedule': schedule,
      // --- ADDED TO DATABASE SAVE ---
      'instructorId': instructorId,
      'enrolledStudents': enrolledStudents ?? [],
    };
  }

  factory ClassModel.fromFirestore(var doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClassModel(
      id: doc.id,
      className: data['className'] ?? '',
      subject: data['subject'] ?? '',
      schedule: data['schedule'] ?? '',
      // --- ADDED TO DATABASE READ ---
      instructorId: data['instructorId'] ?? '',
      enrolledStudents: List<String>.from(data['enrolledStudents'] ?? []),
    );
  }
}
