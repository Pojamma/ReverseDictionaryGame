import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/puzzle.dart';
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
  
  // Initialize game with puzzles
  Future<void> initializeGame({int? limit = 20}) async {
    try {
      _status = GameStatus.loading;
      _errorMessage = null;
      notifyListeners();
      
      final puzzles = await _databaseService.getPuzzles(limit: limit);
      
      if (puzzles.isEmpty) {
        _status = GameStatus.error;
        _errorMessage = 'No puzzles available';
      } else {
        _puzzles = puzzles;
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
      HapticFeedback.heavyImpact();
      
      // Auto-advance after 2 seconds on correct answer
      Future.delayed(const Duration(seconds: 2), () {
        if (_isCorrect) nextPuzzle();
      });
    } else {
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
  
  // Load new set of puzzles (for different difficulty/category)
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
      
      // For now, just load by limit. Later we can add filtering by difficulty, category, type
      final puzzles = await _databaseService.getPuzzles(limit: limit ?? 20);
      
      if (puzzles.isEmpty) {
        _status = GameStatus.error;
        _errorMessage = 'No puzzles found for the selected criteria';
      } else {
        _puzzles = puzzles;
        _currentPuzzleIndex = 0;
        _totalScore = 0;
        _correctAnswers = 0;
        _totalAttempts = 0;
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