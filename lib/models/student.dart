class Student {
  final String id;
  final String parentId;
  final String fullName;
  final String classId;

  Student({
    required this.id,
    required this.parentId,
    required this.fullName,
    required this.classId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parent_id': parentId,
      'full_name': fullName,
      'class_id': classId,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] as String,
      parentId: map['parent_id'] as String,
      fullName: map['full_name'] as String,
      classId: map['class_id'] as String,
    );
  }
}
