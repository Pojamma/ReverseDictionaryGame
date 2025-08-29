import 'puzzle_loader_service.dart';
import 'adaptive_database_service.dart';
import '../models/puzzle.dart';

class PuzzleInitializationService {
  final PuzzleLoaderService _puzzleLoader = PuzzleLoaderService();
  final AdaptiveDatabaseService _databaseService = AdaptiveDatabaseService.instance;

  // Initialize puzzles by loading from JSON and storing in database
  Future<InitializationResult> initializePuzzles({bool forceReload = false}) async {
    try {
      final dbInfo = await _databaseService.getDatabaseInfo();
      final currentPuzzleCount = dbInfo['puzzle_count'] as int;
      
      // Skip initialization if database already has puzzles (unless forced)
      if (currentPuzzleCount > 0 && !forceReload) {
        return InitializationResult(
          success: true,
          message: 'Database already contains $currentPuzzleCount puzzles',
          puzzleCount: currentPuzzleCount,
          loadedFromCache: true,
        );
      }

      // Load puzzles from JSON assets
      final packs = await _puzzleLoader.loadAllPuzzlePacks();
      final allPuzzles = <Puzzle>[];
      
      for (final pack in packs) {
        allPuzzles.addAll(pack.puzzles);
      }

      if (allPuzzles.isEmpty) {
        return InitializationResult(
          success: false,
          message: 'No puzzles found in asset files',
          puzzleCount: 0,
        );
      }

      // Validate puzzle data before insertion
      final validationErrors = await _puzzleLoader.validatePuzzleData();
      if (validationErrors.isNotEmpty) {
        return InitializationResult(
          success: false,
          message: 'Puzzle validation failed: ${validationErrors.first}',
          puzzleCount: 0,
          validationErrors: validationErrors,
        );
      }

      // Insert puzzles into database
      await _databaseService.insertPuzzles(allPuzzles);
      
      // Verify insertion
      final finalCount = (await _databaseService.getDatabaseInfo())['puzzle_count'] as int;
      
      return InitializationResult(
        success: true,
        message: 'Successfully loaded $finalCount puzzles into database',
        puzzleCount: finalCount,
        loadedFromCache: false,
        packCount: packs.length,
      );
      
    } catch (e) {
      return InitializationResult(
        success: false,
        message: 'Initialization failed: $e',
        puzzleCount: 0,
        error: e.toString(),
      );
    }
  }

  // Initialize only base puzzles (minimal set for testing)
  Future<InitializationResult> initializeBasePuzzles({bool forceReload = false}) async {
    try {
      final dbInfo = await _databaseService.getDatabaseInfo();
      final currentPuzzleCount = dbInfo['puzzle_count'] as int;
      
      if (currentPuzzleCount > 0 && !forceReload) {
        return InitializationResult(
          success: true,
          message: 'Database already contains $currentPuzzleCount puzzles',
          puzzleCount: currentPuzzleCount,
          loadedFromCache: true,
        );
      }

      // Load only base puzzle pack
      final basePack = await _puzzleLoader.loadBasePuzzlePack();
      
      if (basePack.puzzles.isEmpty) {
        return InitializationResult(
          success: false,
          message: 'No puzzles found in base pack',
          puzzleCount: 0,
        );
      }

      // Insert base puzzles into database
      await _databaseService.insertPuzzles(basePack.puzzles);
      
      return InitializationResult(
        success: true,
        message: 'Successfully loaded ${basePack.puzzles.length} base puzzles',
        puzzleCount: basePack.puzzles.length,
        loadedFromCache: false,
        packCount: 1,
      );
      
    } catch (e) {
      return InitializationResult(
        success: false,
        message: 'Base initialization failed: $e',
        puzzleCount: 0,
        error: e.toString(),
      );
    }
  }

  // Get initialization status
  Future<InitializationStatus> getInitializationStatus() async {
    try {
      final dbInfo = await _databaseService.getDatabaseInfo();
      final puzzleCount = dbInfo['puzzle_count'] as int;
      final progressRecords = dbInfo['progress_records'] as int;
      
      // Get content statistics from assets
      final contentStats = await _puzzleLoader.getContentStatistics();
      final availablePuzzles = contentStats['total_puzzles'] as int;
      
      return InitializationStatus(
        isInitialized: puzzleCount > 0,
        puzzlesInDatabase: puzzleCount,
        puzzlesAvailable: availablePuzzles,
        progressRecords: progressRecords,
        isFullyLoaded: puzzleCount == availablePuzzles,
        contentStatistics: contentStats,
      );
      
    } catch (e) {
      return InitializationStatus(
        isInitialized: false,
        puzzlesInDatabase: 0,
        puzzlesAvailable: 0,
        progressRecords: 0,
        isFullyLoaded: false,
        error: e.toString(),
      );
    }
  }

  // Reset and reinitialize
  Future<InitializationResult> resetAndReinitialize() async {
    try {
      // Clear existing puzzle data (but keep progress and settings)
      await _databaseService.clearAllData();
      
      // Reinitialize with all puzzles
      return await initializePuzzles(forceReload: true);
      
    } catch (e) {
      return InitializationResult(
        success: false,
        message: 'Reset failed: $e',
        puzzleCount: 0,
        error: e.toString(),
      );
    }
  }

  // Quick health check
  Future<bool> isHealthy() async {
    try {
      final status = await getInitializationStatus();
      return status.isInitialized && status.puzzlesInDatabase > 0;
    } catch (e) {
      return false;
    }
  }
}

// Result classes for better error handling and status reporting

class InitializationResult {
  final bool success;
  final String message;
  final int puzzleCount;
  final bool loadedFromCache;
  final int? packCount;
  final String? error;
  final List<String>? validationErrors;

  const InitializationResult({
    required this.success,
    required this.message,
    required this.puzzleCount,
    this.loadedFromCache = false,
    this.packCount,
    this.error,
    this.validationErrors,
  });

  @override
  String toString() {
    return 'InitializationResult(success: $success, message: $message, puzzleCount: $puzzleCount)';
  }
}

class InitializationStatus {
  final bool isInitialized;
  final int puzzlesInDatabase;
  final int puzzlesAvailable;
  final int progressRecords;
  final bool isFullyLoaded;
  final Map<String, dynamic>? contentStatistics;
  final String? error;

  const InitializationStatus({
    required this.isInitialized,
    required this.puzzlesInDatabase,
    required this.puzzlesAvailable,
    required this.progressRecords,
    required this.isFullyLoaded,
    this.contentStatistics,
    this.error,
  });

  double get loadingProgress {
    if (puzzlesAvailable == 0) return 0.0;
    return puzzlesInDatabase / puzzlesAvailable;
  }

  @override
  String toString() {
    return 'InitializationStatus(initialized: $isInitialized, dbPuzzles: $puzzlesInDatabase, available: $puzzlesAvailable)';
  }
}