import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/puzzle.dart';
import '../models/difficulty_progression.dart';
import '../services/adaptive_database_service.dart';

enum GameStatus {
  loading,
  playing,
  completed,
  error,
}

class GameProvider extends ChangeNotifier {
  final AdaptiveDatabaseService _databaseService = AdaptiveDatabaseService.instance;
  
  // Game State
  GameStatus _status = GameStatus.loading;
  List<Puzzle> _puzzles = [];
  int _currentPuzzleIndex = 0;
  String? _feedback;
  bool _isCorrect = false;
  bool _isAnswering = false;
  String? _errorMessage;
  
  // Difficulty Progression
  UserProgressData _userProgress = UserProgressData.initial();
  DifficultyLevel _currentDifficulty = DifficultyLevel.easy;
  
  // Game Statistics
  int _totalScore = 0;
  int _correctAnswers = 0;
  int _totalAttempts = 0;
  
  // Getters
  GameStatus get status => _status;
  List<Puzzle> get puzzles => _puzzles;
  Puzzle? get currentPuzzle => _puzzles.isNotEmpty && _currentPuzzleIndex < _puzzles.length 
      ? _puzzles[_currentPuzzleIndex] 
      : null;
  int get currentPuzzleIndex => _currentPuzzleIndex;
  String? get feedback => _feedback;
  bool get isCorrect => _isCorrect;
  bool get isAnswering => _isAnswering;
  String? get errorMessage => _errorMessage;
  int get totalScore => _totalScore;
  int get correctAnswers => _correctAnswers;
  int get totalAttempts => _totalAttempts;
  int get remainingPuzzles => _puzzles.length - _currentPuzzleIndex - 1;
  double get progress => _puzzles.isNotEmpty ? (_currentPuzzleIndex + 1) / _puzzles.length : 0.0;
  
  // Difficulty Progression Getters
  UserProgressData get userProgress => _userProgress;
  DifficultyLevel get currentDifficulty => _currentDifficulty;
  List<DifficultyLevel> get availableDifficulties => _userProgress.availableLevels;
  bool get canProgressToNextLevel => _getCurrentDifficultyProgression().canUnlockNextLevel(
        accuracy: _getDifficultyAccuracy(_currentDifficulty),
      );
  
  // Initialize game with puzzles for current difficulty
  Future<void> initializeGame({int? limit = 20}) async {
    try {
      _status = GameStatus.loading;
      _errorMessage = null;
      notifyListeners();
      
      final puzzles = await _databaseService.getPuzzlesByDifficulty(_currentDifficulty.value);
      
      if (puzzles.isEmpty) {
        _status = GameStatus.error;
        _errorMessage = 'No puzzles available for ${_currentDifficulty.displayName} difficulty';
      } else {
        _puzzles = puzzles.take(limit ?? 20).toList()..shuffle();
        _currentPuzzleIndex = 0;
        _status = GameStatus.playing;
        _resetFeedback();
      }
    } catch (e) {
      _status = GameStatus.error;
      _errorMessage = 'Failed to load puzzles: $e';
    }
    notifyListeners();
  }
  
  // Submit an answer
  Future<void> submitAnswer(String userAnswer) async {
    if (_isAnswering || currentPuzzle == null || userAnswer.trim().isEmpty) return;
    
    _isAnswering = true;
    _totalAttempts++;
    notifyListeners();
    
    // Simulate brief processing delay for better UX
    await Future.delayed(const Duration(milliseconds: 200));
    
    final isCorrect = currentPuzzle!.isCorrectAnswer(userAnswer.trim());
    
    _isCorrect = isCorrect;
    _feedback = isCorrect 
        ? 'Correct! The answer is "${currentPuzzle!.answer}"'
        : 'Try again! Your answer: "$userAnswer"';
    
    if (isCorrect) {
      _correctAnswers++;
      _totalScore += currentPuzzle!.points;
      _updateUserProgress(correct: true);
      HapticFeedback.heavyImpact();
      
      // Auto-advance after 2 seconds on correct answer
      Future.delayed(const Duration(seconds: 2), () {
        if (_isCorrect) nextPuzzle();
      });
    } else {
      _updateUserProgress(correct: false);
      HapticFeedback.lightImpact();
    }
    
    _isAnswering = false;
    notifyListeners();
  }
  
  // Move to next puzzle
  void nextPuzzle() {
    if (_currentPuzzleIndex < _puzzles.length - 1) {
      _currentPuzzleIndex++;
      _resetFeedback();
    } else {
      _status = GameStatus.completed;
    }
    notifyListeners();
  }
  
  // Reset feedback state
  void _resetFeedback() {
    _feedback = null;
    _isCorrect = false;
    _isAnswering = false;
  }
  
  // Reset feedback manually (for UI interactions)
  void clearFeedback() {
    _resetFeedback();
    notifyListeners();
  }
  
  // Skip current puzzle
  void skipPuzzle() {
    nextPuzzle();
  }
  
  // Restart the current set of puzzles
  void restartGame() {
    _currentPuzzleIndex = 0;
    _status = GameStatus.playing;
    _totalScore = 0;
    _correctAnswers = 0;
    _totalAttempts = 0;
    _resetFeedback();
    notifyListeners();
  }
  
  // Get hint for current puzzle
  String? getCurrentHint() {
    return currentPuzzle?.hints.isNotEmpty == true ? currentPuzzle!.hints.first : null;
  }
  
  // Load puzzles for specific difficulty level
  Future<void> loadPuzzlesForDifficulty(DifficultyLevel difficulty, {int? limit}) async {
    _currentDifficulty = difficulty;
    await initializeGame(limit: limit);
  }
  
  // Switch difficulty level
  Future<void> changeDifficulty(DifficultyLevel newDifficulty) async {
    if (!_userProgress.isLevelUnlocked(newDifficulty)) {
      throw Exception('Difficulty level ${newDifficulty.displayName} is not unlocked yet');
    }
    
    _currentDifficulty = newDifficulty;
    _resetGameStats();
    await initializeGame();
  }
  
  // Update user progress after each answer
  void _updateUserProgress({required bool correct}) {
    final currentSolved = _userProgress.puzzlesSolvedByDifficulty[_currentDifficulty] ?? 0;
    final currentAttempts = _userProgress.totalAttemptsByDifficulty[_currentDifficulty] ?? 0;
    
    final newSolved = correct ? currentSolved + 1 : currentSolved;
    final newAttempts = currentAttempts + 1;
    
    final updatedSolvedMap = Map<DifficultyLevel, int>.from(_userProgress.puzzlesSolvedByDifficulty);
    updatedSolvedMap[_currentDifficulty] = newSolved;
    
    final updatedAttemptsMap = Map<DifficultyLevel, int>.from(_userProgress.totalAttemptsByDifficulty);
    updatedAttemptsMap[_currentDifficulty] = newAttempts;
    
    _userProgress = _userProgress.copyWith(
      puzzlesSolvedByDifficulty: updatedSolvedMap,
      totalAttemptsByDifficulty: updatedAttemptsMap,
    );
    
    // Check if user can unlock next difficulty level
    _checkAndUnlockNextLevel();
  }
  
  // Check if user can unlock the next difficulty level
  void _checkAndUnlockNextLevel() {
    final progression = _getCurrentDifficultyProgression();
    if (progression.canUnlockNextLevel(accuracy: _getDifficultyAccuracy(_currentDifficulty))) {
      final nextLevel = progression.nextLevel;
      if (nextLevel != null && !_userProgress.isLevelUnlocked(nextLevel)) {
        final updatedUnlockedMap = Map<DifficultyLevel, bool>.from(_userProgress.unlockedLevels);
        updatedUnlockedMap[nextLevel] = true;
        
        _userProgress = _userProgress.copyWith(unlockedLevels: updatedUnlockedMap);
        
        // Trigger notification about unlock
        _showLevelUnlockedNotification(nextLevel);
      }
    }
  }
  
  // Get difficulty progression for current level
  DifficultyProgression _getCurrentDifficultyProgression() {
    final solved = _userProgress.puzzlesSolvedByDifficulty[_currentDifficulty] ?? 0;
    final totalInLevel = 50; // Assume 50 puzzles per difficulty level (can be dynamic)
    
    return DifficultyProgression(
      currentLevel: _currentDifficulty,
      puzzlesSolvedInLevel: solved,
      totalPuzzlesInLevel: totalInLevel,
      isLevelUnlocked: _userProgress.isLevelUnlocked(_currentDifficulty),
      progressInLevel: totalInLevel > 0 ? solved / totalInLevel : 0.0,
    );
  }
  
  // Get accuracy for specific difficulty level
  double _getDifficultyAccuracy(DifficultyLevel level) {
    return _userProgress.getAccuracyForLevel(level);
  }
  
  // Show notification when new level is unlocked
  void _showLevelUnlockedNotification(DifficultyLevel newLevel) {
    // This could trigger a dialog or notification in the UI
    // For now, just update feedback
    _feedback = '🎉 Congratulations! ${newLevel.displayName} difficulty unlocked!';
  }
  
  // Reset game statistics for new difficulty session
  void _resetGameStats() {
    _totalScore = 0;
    _correctAnswers = 0;
    _totalAttempts = 0;
  }
  
  // Load new set of puzzles (for different difficulty/category) - Updated
  Future<void> loadPuzzles({
    int? limit,
    int? difficulty,
    String? category,
    String? type,
  }) async {
    try {
      _status = GameStatus.loading;
      _errorMessage = null;
      notifyListeners();
      
      List<Puzzle> puzzles;
      if (difficulty != null) {
        final diffLevel = DifficultyLevel.fromValue(difficulty);
        puzzles = await _databaseService.getPuzzlesByDifficulty(diffLevel.value);
      } else {
        puzzles = await _databaseService.getPuzzles(limit: limit ?? 20);
      }
      
      if (puzzles.isEmpty) {
        _status = GameStatus.error;
        _errorMessage = 'No puzzles found for the selected criteria';
      } else {
        _puzzles = puzzles.take(limit ?? 20).toList()..shuffle();
        _currentPuzzleIndex = 0;
        _resetGameStats();
        _status = GameStatus.playing;
        _resetFeedback();
      }
    } catch (e) {
      _status = GameStatus.error;
      _errorMessage = 'Failed to load puzzles: $e';
    }
    notifyListeners();
  }
  
  // Get accuracy percentage
  double get accuracy => _totalAttempts > 0 ? (_correctAnswers / _totalAttempts) * 100 : 0.0;
  
  // Check if game is complete
  bool get isGameComplete => _status == GameStatus.completed;
  
  // Check if game is in error state
  bool get hasError => _status == GameStatus.error;
  
  // Check if currently loading
  bool get isLoading => _status == GameStatus.loading;
}