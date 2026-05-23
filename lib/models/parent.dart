class Parent {
  final String id;
  final String guardianName;
  final String? phoneNumber;

  Parent({
    required this.id,
    required this.guardianName,
    this.phoneNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'guardian_name': guardianName,
      'phone_number': phoneNumber,
    };
  }

  factory Parent.fromMap(Map<String, dynamic> map) {
    return Parent(
      id: map['id'] as String,
      guardianName: map['guardian_name'] as String,
      phoneNumber: map['phone_number'] as String?,
    );
  }
}
