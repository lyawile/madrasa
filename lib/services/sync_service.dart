import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/parent.dart';
import '../models/student.dart';
import '../models/attendance.dart';

class SyncService {
  // Backend base URL — set to your server's local network IP.
  // Android cannot use 'localhost' when running on a physical device.
  static String baseUrl = 'http://192.168.1.163:8085/api';

  static void setBaseUrl(String newUrl) {
    baseUrl = newUrl;
  }

  /// Wraps an HTTP call with improved error messaging.
  /// Distinguishes network unreachable errors from server-side errors.
  Future<http.Response> _post(String endpoint, String body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    try {
      return await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 15));
    } on SocketException catch (e) {
      throw Exception('Cannot reach server at $baseUrl. '
          'Ensure the device is on the same Wi-Fi network and the backend is running. '
          '(${e.message})');
    } on TimeoutException {
      throw Exception('Connection timed out reaching $baseUrl. '
          'Check the IP address and ensure the backend is running.');
    }
  }

  // Sync Parents: POST local parents, returns server unified parents list
  Future<List<Parent>> syncParents(List<Parent> clientParents) async {
    debugPrint('[SyncService] Syncing ${clientParents.length} parents to $baseUrl/parents/sync');
    final body = json.encode(clientParents.map((p) => p.toMap()).toList());
    final response = await _post('/parents/sync', body);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      debugPrint('[SyncService] Received ${data.length} parents from server');
      return data.map((map) => Parent.fromMap(map)).toList();
    } else {
      throw Exception('Parent Sync Error: Server returned ${response.statusCode} — ${response.body}');
    }
  }

  // Sync Students: POST local students, returns server unified students list
  Future<List<Student>> syncStudents(List<Student> clientStudents) async {
    debugPrint('[SyncService] Syncing ${clientStudents.length} students to $baseUrl/students/sync');
    final body = json.encode(clientStudents.map((s) => s.toMap()).toList());
    final response = await _post('/students/sync', body);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      debugPrint('[SyncService] Received ${data.length} students from server');
      return data.map((map) => Student.fromMap(map)).toList();
    } else {
      throw Exception('Student Sync Error: Server returned ${response.statusCode} — ${response.body}');
    }
  }

  // Sync Attendance: POST local attendance, returns server unified attendance list
  Future<List<Attendance>> syncAttendance(List<Attendance> clientAttendance) async {
    debugPrint('[SyncService] Syncing ${clientAttendance.length} attendance records to $baseUrl/attendance/sync');
    final body = json.encode(clientAttendance.map((a) => a.toMap()).toList());
    final response = await _post('/attendance/sync', body);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      debugPrint('[SyncService] Received ${data.length} attendance records from server');
      return data.map((map) => Attendance.fromMap(map)).toList();
    } else {
      throw Exception('Attendance Sync Error: Server returned ${response.statusCode} — ${response.body}');
    }
  }
}

