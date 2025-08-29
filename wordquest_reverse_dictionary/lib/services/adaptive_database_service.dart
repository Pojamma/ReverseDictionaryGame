import 'dart:html' as html show window;
import '../models/puzzle.dart';
import 'database_service.dart';
import 'web_storage_service.dart';

class AdaptiveDatabaseService {
  static AdaptiveDatabaseService? _instance;
  late final dynamic _service;
  
  AdaptiveDatabaseService._() {
    // Detect if we're on web by checking if html.window exists
    bool isWeb = false;
    try {
      // This will only work on web
      html.window;
      isWeb = true;
    } catch (e) {
      // We're not on web
      isWeb = false;
    }
    
    _service = isWeb ? WebStorageService() : DatabaseService();
  }
  
  static AdaptiveDatabaseService get instance {
    _instance ??= AdaptiveDatabaseService._();
    return _instance!;
  }

  // PUZZLE OPERATIONS

  Future<void> insertPuzzle(Puzzle puzzle) async {
    if (_service is DatabaseService) {
      await (_service as DatabaseService).insertPuzzle(puzzle);
    } else {
      await (_service as WebStorageService).insertPuzzles([puzzle]);
    }
  }

  Future<void> insertPuzzles(List<Puzzle> puzzles) async {
    if (_service is DatabaseService) {
      await (_service as DatabaseService).insertPuzzles(puzzles);
    } else {
      await (_service as WebStorageService).insertPuzzles(puzzles);
    }
  }

  Future<List<Puzzle>> getAllPuzzles() async {
    if (_service is DatabaseService) {
      return await (_service as DatabaseService).getAllPuzzles();
    } else {
      return await (_service as WebStorageService).getAllPuzzles();
    }
  }

  Future<List<Puzzle>> getPuzzles({int? limit}) async {
    if (_service is DatabaseService) {
      return await (_service as DatabaseService).getPuzzles(limit: limit);
    } else {
      return await (_service as WebStorageService).getPuzzles(limit: limit);
    }
  }

  Future<List<Puzzle>> getPuzzlesByType(String type) async {
    if (_service is DatabaseService) {
      return await (_service as DatabaseService).getPuzzlesByType(type);
    } else {
      return await (_service as WebStorageService).getPuzzlesByType(type);
    }
  }

  Future<List<Puzzle>> getPuzzlesByDifficulty(int difficulty) async {
    if (_service is DatabaseService) {
      return await (_service as DatabaseService).getPuzzlesByDifficulty(difficulty);
    } else {
      return await (_service as WebStorageService).getPuzzlesByDifficulty(difficulty);
    }
  }

  Future<List<Puzzle>> getPuzzlesByCategory(String category) async {
    if (_service is DatabaseService) {
      return await (_service as DatabaseService).getPuzzlesByCategory(category);
    } else {
      return await (_service as WebStorageService).getPuzzlesByCategory(category);
    }
  }

  Future<List<Puzzle>> getRandomPuzzles(int count) async {
    if (_service is DatabaseService) {
      return await (_service as DatabaseService).getRandomPuzzles(count);
    } else {
      return await (_service as WebStorageService).getRandomPuzzles(count);
    }
  }

  // USER PROGRESS OPERATIONS

  Future<void> recordPuzzleAttempt(String puzzleId, bool solved, int hintsUsed, int timeSpent) async {
    if (_service is DatabaseService) {
      await (_service as DatabaseService).recordPuzzleAttempt(puzzleId, solved, hintsUsed, timeSpent);
    } else {
      await (_service as WebStorageService).recordPuzzleAttempt(puzzleId, solved, hintsUsed, timeSpent);
    }
  }

  Future<Map<String, dynamic>> getUserStatistics() async {
    if (_service is DatabaseService) {
      return await (_service as DatabaseService).getUserStatistics();
    } else {
      return await (_service as WebStorageService).getUserStatistics();
    }
  }

  // SETTINGS OPERATIONS

  Future<void> saveSetting(String key, String value) async {
    if (_service is DatabaseService) {
      await (_service as DatabaseService).saveSetting(key, value);
    } else {
      await (_service as WebStorageService).saveSetting(key, value);
    }
  }

  Future<String?> getSetting(String key) async {
    if (_service is DatabaseService) {
      return await (_service as DatabaseService).getSetting(key);
    } else {
      return await (_service as WebStorageService).getSetting(key);
    }
  }

  Future<Map<String, String>> getAllSettings() async {
    if (_service is DatabaseService) {
      return await (_service as DatabaseService).getAllSettings();
    } else {
      return await (_service as WebStorageService).getAllSettings();
    }
  }

  // UTILITY OPERATIONS

  Future<void> clearAllData() async {
    if (_service is DatabaseService) {
      await (_service as DatabaseService).clearAllData();
    } else {
      await (_service as WebStorageService).clearAllData();
    }
  }

  Future<Map<String, dynamic>> getDatabaseInfo() async {
    if (_service is DatabaseService) {
      return await (_service as DatabaseService).getDatabaseInfo();
    } else {
      return await (_service as WebStorageService).getDatabaseInfo();
    }
  }

  Future<void> close() async {
    if (_service is DatabaseService) {
      await (_service as DatabaseService).close();
    } else {
      await (_service as WebStorageService).close();
    }
  }
}