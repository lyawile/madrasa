import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../data/database_helper.dart';
import '../models/parent.dart';
import '../models/student.dart';
import '../models/attendance.dart';
import '../services/sync_service.dart';

class MadrasaProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();

  List<Parent> _parents = [];
  List<Student> _students = [];
  Map<String, List<Student>> _parentToStudents = {};
  
  DateTime _selectedDate = DateTime.now();
  Map<String, Attendance> _attendanceMap = {}; // Key: student_id
  bool _isLoading = false;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  String? _syncErrorMessage;

  // Getters
  List<Parent> get parents => _parents;
  List<Student> get students => _students;
  Map<String, List<Student>> get parentToStudents => _parentToStudents;
  DateTime get selectedDate => _selectedDate;
  Map<String, Attendance> get attendanceMap => _attendanceMap;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get syncErrorMessage => _syncErrorMessage;

  // Check if the current date is a weekend (Thursday or Friday)
  bool get isWeekend {
    return _selectedDate.weekday == DateTime.thursday || _selectedDate.weekday == DateTime.friday;
  }

  // Initialize Provider - Fetch Parents and Students
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      await fetchParentsAndStudents();
      await loadAttendanceForDate(_selectedDate);
    } catch (e) {
      debugPrint('Database initialization failed (expected in unit tests): $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Fetch registered Parents and Pupils from local SQFlite
  Future<void> fetchParentsAndStudents() async {
    final parentMaps = await _dbHelper.queryAllParents();
    _parents = parentMaps.map((map) => Parent.fromMap(map)).toList();

    final studentMaps = await _dbHelper.queryAllStudents();
    _students = studentMaps.map((map) => Student.fromMap(map)).toList();

    // Map parents to siblings
    _parentToStudents = {};
    for (final parent in _parents) {
      _parentToStudents[parent.id] = [];
    }
    for (final student in _students) {
      if (_parentToStudents.containsKey(student.parentId)) {
        _parentToStudents[student.parentId]!.add(student);
      } else {
        _parentToStudents[student.parentId] = [student];
      }
    }
  }

  // Register Parent and multiple Siblings in a single transaction
  Future<void> registerParentWithStudents({
    required String guardianName,
    String? phoneNumber,
    required List<Map<String, String>> pupilDetails, // Contains 'name' and 'class'
  }) async {
    final parentId = _uuid.v4();
    final parent = Parent(
      id: parentId,
      guardianName: guardianName.trim(),
      phoneNumber: (phoneNumber == null || phoneNumber.trim().isEmpty) ? null : phoneNumber.trim(),
    );

    final List<Map<String, dynamic>> studentRows = [];
    for (final pupil in pupilDetails) {
      final studentId = _uuid.v4();
      final student = Student(
        id: studentId,
        parentId: parentId,
        fullName: pupil['name']!.trim(),
        classId: pupil['class']!.trim(),
      );
      studentRows.add(student.toMap());
    }

    await _dbHelper.registerParentAndStudents(parent.toMap(), studentRows);

    // Refresh parents and student records
    await fetchParentsAndStudents();

    // Re-initialize attendance for the current selected date so the new pupils are registered as "present"
    if (!isWeekend) {
      await loadAttendanceForDate(_selectedDate);
    } else {
      notifyListeners();
    }
  }

  // Load and auto-initialize attendance for selected date
  Future<void> loadAttendanceForDate(DateTime date) async {
    _selectedDate = date;
    
    if (isWeekend) {
      _attendanceMap = {};
      notifyListeners();
      return;
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    
    // Fetch existing attendance records from SQFlite
    final attendanceMaps = await _dbHelper.queryAttendanceForDate(dateStr);
    final existingAttendance = attendanceMaps.map((map) => Attendance.fromMap(map)).toList();
    
    final Map<String, Attendance> loadedMap = {};
    for (final record in existingAttendance) {
      loadedMap[record.studentId] = record;
    }

    // Check for students that don't have an attendance record for this date
    for (final student in _students) {
      if (!loadedMap.containsKey(student.id)) {
        // Automatically initialize to 'present' and save to DB
        final attendanceId = _uuid.v4();
        final newRecord = Attendance(
          id: attendanceId,
          studentId: student.id,
          date: dateStr,
          status: 'present',
        );
        
        await _dbHelper.insertOrUpdateAttendance(newRecord.toMap());
        loadedMap[student.id] = newRecord;
      }
    }

    _attendanceMap = loadedMap;
    notifyListeners();
  }

  // Toggle attendance status: present -> absent -> late -> present
  Future<void> toggleAttendanceStatus(String studentId) async {
    if (isWeekend) return; // Prevent edits on Thursday/Friday

    final currentRecord = _attendanceMap[studentId];
    if (currentRecord == null) return;

    String nextStatus;
    switch (currentRecord.status) {
      case 'present':
        nextStatus = 'absent';
        break;
      case 'absent':
        nextStatus = 'late';
        break;
      case 'late':
      default:
        nextStatus = 'present';
        break;
    }

    final updatedRecord = Attendance(
      id: currentRecord.id,
      studentId: studentId,
      date: currentRecord.date,
      status: nextStatus,
    );

    // Save instantly to SQFlite
    await _dbHelper.insertOrUpdateAttendance(updatedRecord.toMap());

    // Update in-memory state
    _attendanceMap[studentId] = updatedRecord;
    notifyListeners();
  }

  // Change selected date
  Future<void> setDate(DateTime date) async {
    _isLoading = true;
    notifyListeners();

    await loadAttendanceForDate(date);

    _isLoading = false;
    notifyListeners();
  }

  // Offline-First Sync Cycle
  Future<void> synchronizeWithBackend() async {
    _isSyncing = true;
    _syncErrorMessage = null;
    notifyListeners();

    try {
      final syncService = SyncService();

      // 1. Sync Parents: Push local parents, get server parents list
      final serverParents = await syncService.syncParents(_parents);
      // Merge server parents into local SQFlite
      for (final parent in serverParents) {
        await _dbHelper.insertParent(parent.toMap());
      }

      // 2. Sync Students: Push local students, get server students list
      final serverStudents = await syncService.syncStudents(_students);
      // Merge server students into local SQFlite
      for (final student in serverStudents) {
        await _dbHelper.insertStudent(student.toMap());
      }

      // 3. Sync Attendance: Query all local attendance records
      final localAttendanceMaps = await _dbHelper.queryAllAttendance();
      final localAttendance = localAttendanceMaps.map((map) => Attendance.fromMap(map)).toList();

      final serverAttendance = await syncService.syncAttendance(localAttendance);
      // Merge server attendance into local SQFlite
      for (final record in serverAttendance) {
        await _dbHelper.insertOrUpdateAttendance(record.toMap());
      }

      // 4. Re-fetch all parents and students to refresh in-memory state
      await fetchParentsAndStudents();

      // 5. Re-load attendance for current selected date
      await loadAttendanceForDate(_selectedDate);

      _lastSyncTime = DateTime.now();
    } catch (e) {
      _syncErrorMessage = e.toString();
      debugPrint('Sync failed: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
}
