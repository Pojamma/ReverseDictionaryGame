enum DifficultyLevel {
  easy(1, 'Easy', 'Perfect for beginners'),
  medium(2, 'Medium', 'Moderate challenge'),
  hard(3, 'Hard', 'For puzzle masters');

  const DifficultyLevel(this.value, this.displayName, this.description);
  
  final int value;
  final String displayName;
  final String description;
  
  static DifficultyLevel fromValue(int value) {
    return DifficultyLevel.values.firstWhere(
      (level) => level.value == value,
      orElse: () => DifficultyLevel.easy,
    );
  }
}

class DifficultyProgression {
  final DifficultyLevel currentLevel;
  final int puzzlesSolvedInLevel;
  final int totalPuzzlesInLevel;
  final bool isLevelUnlocked;
  final double progressInLevel;
  
  const DifficultyProgression({
    required this.currentLevel,
    required this.puzzlesSolvedInLevel,
    required this.totalPuzzlesInLevel,
    required this.isLevelUnlocked,
    required this.progressInLevel,
  });
  
  // Requirements to unlock next difficulty level
  static const int puzzlesRequiredToUnlock = 15; // Must solve 15 puzzles to unlock next level
  static const double accuracyRequiredToUnlock = 70.0; // Must have 70% accuracy
  
  bool canUnlockNextLevel({required double accuracy}) {
    return puzzlesSolvedInLevel >= puzzlesRequiredToUnlock && 
           accuracy >= accuracyRequiredToUnlock;
  }
  
  DifficultyLevel? get nextLevel {
    switch (currentLevel) {
      case DifficultyLevel.easy:
        return DifficultyLevel.medium;
      case DifficultyLevel.medium:
        return DifficultyLevel.hard;
      case DifficultyLevel.hard:
        return null; // Already at max level
    }
  }
  
  bool get isMaxLevel => currentLevel == DifficultyLevel.hard;
  
  @override
  String toString() {
    return 'DifficultyProgression(level: ${currentLevel.displayName}, solved: $puzzlesSolvedInLevel/$totalPuzzlesInLevel, progress: ${(progressInLevel * 100).toStringAsFixed(1)}%)';
  }
}

class UserProgressData {
  final Map<DifficultyLevel, int> puzzlesSolvedByDifficulty;
  final Map<DifficultyLevel, int> totalAttemptsByDifficulty;
  final Map<DifficultyLevel, bool> unlockedLevels;
  final DifficultyLevel currentDifficulty;
  
  const UserProgressData({
    required this.puzzlesSolvedByDifficulty,
    required this.totalAttemptsByDifficulty,
    required this.unlockedLevels,
    required this.currentDifficulty,
  });
  
  factory UserProgressData.initial() {
    return UserProgressData(
      puzzlesSolvedByDifficulty: {
        DifficultyLevel.easy: 0,
        DifficultyLevel.medium: 0,
        DifficultyLevel.hard: 0,
      },
      totalAttemptsByDifficulty: {
        DifficultyLevel.easy: 0,
        DifficultyLevel.medium: 0,
        DifficultyLevel.hard: 0,
      },
      unlockedLevels: {
        DifficultyLevel.easy: true,  // Easy is always unlocked
        DifficultyLevel.medium: false,
        DifficultyLevel.hard: false,
      },
      currentDifficulty: DifficultyLevel.easy,
    );
  }
  
  double getAccuracyForLevel(DifficultyLevel level) {
    final attempts = totalAttemptsByDifficulty[level] ?? 0;
    final solved = puzzlesSolvedByDifficulty[level] ?? 0;
    return attempts > 0 ? (solved / attempts) * 100 : 0.0;
  }
  
  bool isLevelUnlocked(DifficultyLevel level) {
    return unlockedLevels[level] ?? false;
  }
  
  List<DifficultyLevel> get availableLevels {
    return DifficultyLevel.values.where(isLevelUnlocked).toList();
  }
  
  UserProgressData copyWith({
    Map<DifficultyLevel, int>? puzzlesSolvedByDifficulty,
    Map<DifficultyLevel, int>? totalAttemptsByDifficulty,
    Map<DifficultyLevel, bool>? unlockedLevels,
    DifficultyLevel? currentDifficulty,
  }) {
    return UserProgressData(
      puzzlesSolvedByDifficulty: puzzlesSolvedByDifficulty ?? this.puzzlesSolvedByDifficulty,
      totalAttemptsByDifficulty: totalAttemptsByDifficulty ?? this.totalAttemptsByDifficulty,
      unlockedLevels: unlockedLevels ?? this.unlockedLevels,
      currentDifficulty: currentDifficulty ?? this.currentDifficulty,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'puzzlesSolvedByDifficulty': puzzlesSolvedByDifficulty.map(
        (key, value) => MapEntry(key.value.toString(), value),
      ),
      'totalAttemptsByDifficulty': totalAttemptsByDifficulty.map(
        (key, value) => MapEntry(key.value.toString(), value),
      ),
      'unlockedLevels': unlockedLevels.map(
        (key, value) => MapEntry(key.value.toString(), value),
      ),
      'currentDifficulty': currentDifficulty.value,
    };
  }
  
  factory UserProgressData.fromJson(Map<String, dynamic> json) {
    return UserProgressData(
      puzzlesSolvedByDifficulty: Map.fromEntries(
        (json['puzzlesSolvedByDifficulty'] as Map<String, dynamic>).entries.map(
          (e) => MapEntry(DifficultyLevel.fromValue(int.parse(e.key)), e.value as int),
        ),
      ),
      totalAttemptsByDifficulty: Map.fromEntries(
        (json['totalAttemptsByDifficulty'] as Map<String, dynamic>).entries.map(
          (e) => MapEntry(DifficultyLevel.fromValue(int.parse(e.key)), e.value as int),
        ),
      ),
      unlockedLevels: Map.fromEntries(
        (json['unlockedLevels'] as Map<String, dynamic>).entries.map(
          (e) => MapEntry(DifficultyLevel.fromValue(int.parse(e.key)), e.value as bool),
        ),
      ),
      currentDifficulty: DifficultyLevel.fromValue(json['currentDifficulty'] as int),
    );
  }
}