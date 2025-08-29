import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/puzzle.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'wordquest.db';
  static const int _databaseVersion = 1;
  
  // Table names
  static const String _puzzlesTable = 'puzzles';
  static const String _progressTable = 'user_progress';
  static const String _settingsTable = 'settings';

  // Get database instance
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  // Initialize database
  Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), _databaseName);
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Create tables
  Future<void> _onCreate(Database db, int version) async {
    // Puzzles table
    await db.execute('''
      CREATE TABLE $_puzzlesTable (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        clue TEXT NOT NULL,
        answer TEXT NOT NULL,
        alt_answers TEXT,
        category TEXT NOT NULL,
        difficulty INTEGER NOT NULL,
        length INTEGER NOT NULL,
        hints TEXT,
        tags TEXT,
        points INTEGER NOT NULL,
        created_at INTEGER DEFAULT (strftime('%s', 'now'))
      )
    ''');

    // User progress table
    await db.execute('''
      CREATE TABLE $_progressTable (
        puzzle_id TEXT PRIMARY KEY,
        solved INTEGER DEFAULT 0,
        attempts INTEGER DEFAULT 0,
        hints_used INTEGER DEFAULT 0,
        best_time INTEGER,
        last_attempted INTEGER,
        FOREIGN KEY (puzzle_id) REFERENCES $_puzzlesTable (id)
      )
    ''');

    // Settings table
    await db.execute('''
      CREATE TABLE $_settingsTable (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at INTEGER DEFAULT (strftime('%s', 'now'))
      )
    ''');

    // Create indexes for performance
    await db.execute('CREATE INDEX idx_puzzles_type ON $_puzzlesTable (type)');
    await db.execute('CREATE INDEX idx_puzzles_difficulty ON $_puzzlesTable (difficulty)');
    await db.execute('CREATE INDEX idx_puzzles_category ON $_puzzlesTable (category)');
    await db.execute('CREATE INDEX idx_progress_solved ON $_progressTable (solved)');
  }

  // Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future schema changes here
  }

  // PUZZLE OPERATIONS

  // Insert a single puzzle
  Future<void> insertPuzzle(Puzzle puzzle) async {
    final db = await database;
    await db.insert(
      _puzzlesTable,
      puzzle.toDatabase(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Insert multiple puzzles
  Future<void> insertPuzzles(List<Puzzle> puzzles) async {
    final db = await database;
    final batch = db.batch();
    
    for (final puzzle in puzzles) {
      batch.insert(
        _puzzlesTable,
        puzzle.toDatabase(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  // Get all puzzles
  Future<List<Puzzle>> getAllPuzzles() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_puzzlesTable);
    return maps.map((map) => Puzzle.fromDatabase(map)).toList();
  }

  // Get puzzles by type
  Future<List<Puzzle>> getPuzzlesByType(String type) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _puzzlesTable,
      where: 'type = ?',
      whereArgs: [type],
    );
    return maps.map((map) => Puzzle.fromDatabase(map)).toList();
  }

  // Get puzzles by difficulty
  Future<List<Puzzle>> getPuzzlesByDifficulty(int difficulty) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _puzzlesTable,
      where: 'difficulty = ?',
      whereArgs: [difficulty],
    );
    return maps.map((map) => Puzzle.fromDatabase(map)).toList();
  }

  // Get puzzles by category
  Future<List<Puzzle>> getPuzzlesByCategory(String category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _puzzlesTable,
      where: 'category = ?',
      whereArgs: [category],
    );
    return maps.map((map) => Puzzle.fromDatabase(map)).toList();
  }

  // Get random puzzles
  Future<List<Puzzle>> getRandomPuzzles(int count) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _puzzlesTable,
      orderBy: 'RANDOM()',
      limit: count,
    );
    return maps.map((map) => Puzzle.fromDatabase(map)).toList();
  }

  // Get puzzles with optional limit
  Future<List<Puzzle>> getPuzzles({int? limit}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _puzzlesTable,
      orderBy: 'RANDOM()',
      limit: limit,
    );
    return maps.map((map) => Puzzle.fromDatabase(map)).toList();
  }

  // Get unsolved puzzles
  Future<List<Puzzle>> getUnsolvedPuzzles({int? difficulty, String? type}) async {
    final db = await database;
    String whereClause = '''
      $_puzzlesTable.id NOT IN (
        SELECT puzzle_id FROM $_progressTable WHERE solved = 1
      )
    ''';
    List<dynamic> whereArgs = [];

    if (difficulty != null) {
      whereClause += ' AND difficulty = ?';
      whereArgs.add(difficulty);
    }

    if (type != null) {
      whereClause += ' AND type = ?';
      whereArgs.add(type);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      _puzzlesTable,
      where: whereClause,
      whereArgs: whereArgs,
    );
    return maps.map((map) => Puzzle.fromDatabase(map)).toList();
  }

  // USER PROGRESS OPERATIONS

  // Record puzzle attempt
  Future<void> recordPuzzleAttempt(String puzzleId, bool solved, int hintsUsed, int timeSpent) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    await db.insert(
      _progressTable,
      {
        'puzzle_id': puzzleId,
        'solved': solved ? 1 : 0,
        'attempts': 1,
        'hints_used': hintsUsed,
        'best_time': solved ? timeSpent : null,
        'last_attempted': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Update puzzle progress
  Future<void> updatePuzzleProgress(String puzzleId, bool solved, int hintsUsed, int timeSpent) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final existing = await db.query(
      _progressTable,
      where: 'puzzle_id = ?',
      whereArgs: [puzzleId],
    );

    if (existing.isEmpty) {
      await recordPuzzleAttempt(puzzleId, solved, hintsUsed, timeSpent);
      return;
    }

    final current = existing.first;
    final newAttempts = (current['attempts'] as int) + 1;
    final currentBestTime = current['best_time'] as int?;
    final newBestTime = solved && (currentBestTime == null || timeSpent < currentBestTime) 
        ? timeSpent 
        : currentBestTime;

    await db.update(
      _progressTable,
      {
        'solved': solved ? 1 : (current['solved'] as int),
        'attempts': newAttempts,
        'hints_used': (current['hints_used'] as int) + hintsUsed,
        'best_time': newBestTime,
        'last_attempted': now,
      },
      where: 'puzzle_id = ?',
      whereArgs: [puzzleId],
    );
  }

  // Get user statistics
  Future<Map<String, dynamic>> getUserStatistics() async {
    final db = await database;
    
    final totalPuzzles = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $_puzzlesTable')) ?? 0;
    final solvedPuzzles = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $_progressTable WHERE solved = 1')) ?? 0;
    final totalAttempts = Sqflite.firstIntValue(await db.rawQuery('SELECT SUM(attempts) FROM $_progressTable')) ?? 0;
    final totalHintsUsed = Sqflite.firstIntValue(await db.rawQuery('SELECT SUM(hints_used) FROM $_progressTable')) ?? 0;
    
    return {
      'total_puzzles': totalPuzzles,
      'solved_puzzles': solvedPuzzles,
      'unsolved_puzzles': totalPuzzles - solvedPuzzles,
      'total_attempts': totalAttempts,
      'total_hints_used': totalHintsUsed,
      'success_rate': totalAttempts > 0 ? solvedPuzzles / totalAttempts : 0.0,
    };
  }

  // SETTINGS OPERATIONS

  // Save setting
  Future<void> saveSetting(String key, String value) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    await db.insert(
      _settingsTable,
      {
        'key': key,
        'value': value,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get setting
  Future<String?> getSetting(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _settingsTable,
      where: 'key = ?',
      whereArgs: [key],
    );
    
    return maps.isNotEmpty ? maps.first['value'] as String : null;
  }

  // Get all settings
  Future<Map<String, String>> getAllSettings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_settingsTable);
    
    final Map<String, String> settings = {};
    for (final map in maps) {
      settings[map['key'] as String] = map['value'] as String;
    }
    return settings;
  }

  // UTILITY OPERATIONS

  // Clear all data
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(_progressTable);
    await db.delete(_settingsTable);
    // Note: Keep puzzles table intact
  }

  // Get database info
  Future<Map<String, dynamic>> getDatabaseInfo() async {
    final db = await database;
    final puzzleCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $_puzzlesTable')) ?? 0;
    final progressCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $_progressTable')) ?? 0;
    final settingsCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $_settingsTable')) ?? 0;
    
    return {
      'database_path': db.path,
      'version': await db.getVersion(),
      'puzzle_count': puzzleCount,
      'progress_records': progressCount,
      'settings_count': settingsCount,
    };
  }

  // Close database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}