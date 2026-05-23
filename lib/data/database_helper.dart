import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('madrasa.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onConfigure: _onConfigure,
    );
  }

  Future _onConfigure(Database db) async {
    // Enable Foreign Key support in SQLite
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _createDB(Database db, int version) async {
    // Create parents table
    await db.execute('''
      CREATE TABLE parents (
        id TEXT PRIMARY KEY,
        guardian_name TEXT NOT NULL,
        phone_number TEXT
      )
    ''');

    // Create students table
    await db.execute('''
      CREATE TABLE students (
        id TEXT PRIMARY KEY,
        parent_id TEXT NOT NULL,
        full_name TEXT NOT NULL,
        class_id TEXT NOT NULL,
        FOREIGN KEY (parent_id) REFERENCES parents (id) ON DELETE CASCADE
      )
    ''');

    // Create attendance table
    await db.execute('''
      CREATE TABLE attendance (
        id TEXT PRIMARY KEY,
        student_id TEXT NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL,
        FOREIGN KEY (student_id) REFERENCES students (id) ON DELETE CASCADE
      )
    ''');

    // Enforce UNIQUE composite index on (student_id, date)
    await db.execute('''
      CREATE UNIQUE INDEX idx_attendance_student_date 
      ON attendance (student_id, date)
    ''');
  }

  // CRUD Operations

  // Parent CRUD
  Future<int> insertParent(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('parents', row);
  }

  Future<List<Map<String, dynamic>>> queryAllParents() async {
    final db = await instance.database;
    return await db.query('parents', orderBy: 'guardian_name ASC');
  }

  // Student CRUD
  Future<int> insertStudent(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('students', row);
  }

  Future<List<Map<String, dynamic>>> queryStudentsForParent(String parentId) async {
    final db = await instance.database;
    return await db.query('students', where: 'parent_id = ?', whereArgs: [parentId]);
  }

  Future<List<Map<String, dynamic>>> queryAllStudents() async {
    final db = await instance.database;
    return await db.query('students', orderBy: 'full_name ASC');
  }

  // Attendance CRUD
  Future<int> insertOrUpdateAttendance(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert(
      'attendance',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> queryAttendanceForDate(String date) async {
    final db = await instance.database;
    return await db.query('attendance', where: 'date = ?', whereArgs: [date]);
  }

  Future<Map<String, dynamic>?> queryAttendanceForStudentAndDate(String studentId, String date) async {
    final db = await instance.database;
    final results = await db.query(
      'attendance',
      where: 'student_id = ? AND date = ?',
      whereArgs: [studentId, date],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  // Transaction for Parent & Pupil Registration
  Future<void> registerParentAndStudents(Map<String, dynamic> parentRow, List<Map<String, dynamic>> studentRows) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.insert('parents', parentRow);
      for (final studentRow in studentRows) {
        await txn.insert('students', studentRow);
      }
    });
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}
