import 'dart:convert';
import 'dart:html' as html;
import '../models/puzzle.dart';

class WebStorageService {
  static const String _puzzlesKey = 'wordquest_puzzles';
  static const String _progressKey = 'wordquest_progress';
  static const String _settingsKey = 'wordquest_settings';

  // PUZZLE OPERATIONS

  // Insert multiple puzzles
  Future<void> insertPuzzles(List<Puzzle> puzzles) async {
    final puzzleData = puzzles.map((p) => p.toJson()).toList();
    html.window.localStorage[_puzzlesKey] = jsonEncode(puzzleData);
  }

  // Get puzzles with optional limit
  Future<List<Puzzle>> getPuzzles({int? limit}) async {
    final data = html.window.localStorage[_puzzlesKey];
    if (data == null) return [];
    
    try {
      final List<dynamic> puzzleData = jsonDecode(data);
      var puzzles = puzzleData.map((p) => Puzzle.fromJson(p)).toList();
      
      // Shuffle for random order
      puzzles.shuffle();
      
      if (limit != null && puzzles.length > limit) {
        puzzles = puzzles.take(limit).toList();
      }
      
      return puzzles;
    } catch (e) {
      return [];
    }
  }

  // Get all puzzles
  Future<List<Puzzle>> getAllPuzzles() async {
    return await getPuzzles();
  }

  // Get puzzles by type
  Future<List<Puzzle>> getPuzzlesByType(String type) async {
    final allPuzzles = await getAllPuzzles();
    return allPuzzles.where((p) => p.type == type).toList();
  }

  // Get puzzles by difficulty
  Future<List<Puzzle>> getPuzzlesByDifficulty(int difficulty) async {
    final allPuzzles = await getAllPuzzles();
    return allPuzzles.where((p) => p.difficulty == difficulty).toList();
  }

  // Get puzzles by category
  Future<List<Puzzle>> getPuzzlesByCategory(String category) async {
    final allPuzzles = await getAllPuzzles();
    return allPuzzles.where((p) => p.category == category).toList();
  }

  // Get random puzzles
  Future<List<Puzzle>> getRandomPuzzles(int count) async {
    return await getPuzzles(limit: count);
  }

  // USER PROGRESS OPERATIONS

  // Record puzzle attempt
  Future<void> recordPuzzleAttempt(String puzzleId, bool solved, int hintsUsed, int timeSpent) async {
    final progressData = _getProgressData();
    progressData[puzzleId] = {
      'solved': solved,
      'attempts': (progressData[puzzleId]?['attempts'] ?? 0) + 1,
      'hints_used': (progressData[puzzleId]?['hints_used'] ?? 0) + hintsUsed,
      'best_time': solved ? timeSpent : progressData[puzzleId]?['best_time'],
      'last_attempted': DateTime.now().millisecondsSinceEpoch,
    };
    _saveProgressData(progressData);
  }

  // Get user statistics
  Future<Map<String, dynamic>> getUserStatistics() async {
    final allPuzzles = await getAllPuzzles();
    final progressData = _getProgressData();
    
    final totalPuzzles = allPuzzles.length;
    final solvedPuzzles = progressData.values.where((p) => p['solved'] == true).length;
    final totalAttempts = progressData.values.fold<int>(0, (sum, p) => sum + (p['attempts'] as int? ?? 0));
    final totalHintsUsed = progressData.values.fold<int>(0, (sum, p) => sum + (p['hints_used'] as int? ?? 0));
    
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
    final settingsData = _getSettingsData();
    settingsData[key] = value;
    _saveSettingsData(settingsData);
  }

  // Get setting
  Future<String?> getSetting(String key) async {
    final settingsData = _getSettingsData();
    return settingsData[key];
  }

  // Get all settings
  Future<Map<String, String>> getAllSettings() async {
    return _getSettingsData();
  }

  // PRIVATE HELPER METHODS

  Map<String, dynamic> _getProgressData() {
    final data = html.window.localStorage[_progressKey];
    if (data == null) return {};
    
    try {
      return Map<String, dynamic>.from(jsonDecode(data));
    } catch (e) {
      return {};
    }
  }

  void _saveProgressData(Map<String, dynamic> data) {
    html.window.localStorage[_progressKey] = jsonEncode(data);
  }

  Map<String, String> _getSettingsData() {
    final data = html.window.localStorage[_settingsKey];
    if (data == null) return {};
    
    try {
      return Map<String, String>.from(jsonDecode(data));
    } catch (e) {
      return {};
    }
  }

  void _saveSettingsData(Map<String, String> data) {
    html.window.localStorage[_settingsKey] = jsonEncode(data);
  }

  // UTILITY OPERATIONS

  // Clear all data
  Future<void> clearAllData() async {
    html.window.localStorage.remove(_progressKey);
    html.window.localStorage.remove(_settingsKey);
    // Keep puzzles intact
  }

  // Get database info (web storage info)
  Future<Map<String, dynamic>> getDatabaseInfo() async {
    final allPuzzles = await getAllPuzzles();
    final progressData = _getProgressData();
    final settingsData = _getSettingsData();
    
    return {
      'database_path': 'Browser LocalStorage',
      'version': 1,
      'puzzle_count': allPuzzles.length,
      'progress_records': progressData.length,
      'settings_count': settingsData.length,
    };
  }

  // Close database (no-op for web storage)
  Future<void> close() async {
    // Nothing to close for web storage
  }
}