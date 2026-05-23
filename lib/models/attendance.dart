class Attendance {
  final String id;
  final String studentId;
  final String date; // Format: YYYY-MM-DD
  final String status; // 'present', 'absent', 'late'

  Attendance({
    required this.id,
    required this.studentId,
    required this.date,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'date': date,
      'status': status,
    };
  }

  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'] as String,
      studentId: map['student_id'] as String,
      date: map['date'] as String,
      status: map['status'] as String,
    );
  }
}
