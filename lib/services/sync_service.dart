import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/parent.dart';
import '../models/student.dart';
import '../models/attendance.dart';

class SyncService {
  // Configurable base URL. 
  // In Flutter, 10.0.2.2 points to host localhost when running in Android Emulator.
  // We check if it is running in web or emulator to automatically configure the best URL!
  static String baseUrl = kIsWeb ? 'http://localhost:8085/api' : 'http://10.0.2.2:8085/api';

  static void setBaseUrl(String newUrl) {
    baseUrl = newUrl;
  }

  // Sync Parents: POST local parents, returns server unified parents list
  Future<List<Parent>> syncParents(List<Parent> clientParents) async {
    final url = Uri.parse('$baseUrl/parents/sync');
    final body = json.encode(clientParents.map((p) => p.toMap()).toList());
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((map) => Parent.fromMap(map)).toList();
    } else {
      throw Exception('Parent Sync Error: Server returned ${response.statusCode}');
    }
  }

  // Sync Students: POST local students, returns server unified students list
  Future<List<Student>> syncStudents(List<Student> clientStudents) async {
    final url = Uri.parse('$baseUrl/students/sync');
    final body = json.encode(clientStudents.map((s) => s.toMap()).toList());
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((map) => Student.fromMap(map)).toList();
    } else {
      throw Exception('Student Sync Error: Server returned ${response.statusCode}');
    }
  }

  // Sync Attendance: POST local attendance, returns server unified attendance list
  Future<List<Attendance>> syncAttendance(List<Attendance> clientAttendance) async {
    final url = Uri.parse('$baseUrl/attendance/sync');
    final body = json.encode(clientAttendance.map((a) => a.toMap()).toList());
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((map) => Attendance.fromMap(map)).toList();
    } else {
      throw Exception('Attendance Sync Error: Server returned ${response.statusCode}');
    }
  }
}
