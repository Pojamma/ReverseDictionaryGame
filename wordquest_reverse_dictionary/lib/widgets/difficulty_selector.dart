import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/difficulty_progression.dart';
import '../providers/game_provider.dart';

class DifficultySelector extends StatelessWidget {
  const DifficultySelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final availableDifficulties = gameProvider.availableDifficulties;
        final currentDifficulty = gameProvider.currentDifficulty;
        
        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: 24,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Difficulty Level',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Difficulty level buttons
                Row(
                  children: DifficultyLevel.values.map((difficulty) {
                    final isAvailable = availableDifficulties.contains(difficulty);
                    final isSelected = difficulty == currentDifficulty;
                    final userProgress = gameProvider.userProgress;
                    final solved = userProgress.puzzlesSolvedByDifficulty[difficulty] ?? 0;
                    final accuracy = userProgress.getAccuracyForLevel(difficulty);
                    
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Column(
                          children: [
                            // Difficulty button
                            ElevatedButton(
                              onPressed: isAvailable && !isSelected
                                  ? () => _selectDifficulty(context, difficulty)
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : isAvailable
                                        ? Theme.of(context).colorScheme.secondaryContainer
                                        : Theme.of(context).disabledColor.withOpacity(0.1),
                                foregroundColor: isSelected
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : isAvailable
                                        ? Theme.of(context).colorScheme.onSecondaryContainer
                                        : Theme.of(context).disabledColor,
                                elevation: isSelected ? 4 : 1,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    difficulty.displayName,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (!isAvailable)
                                    const Icon(Icons.lock, size: 16)
                                  else if (isSelected)
                                    const Icon(Icons.check_circle, size: 16),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            // Progress info
                            if (isAvailable) ...[
                              Text(
                                'Solved: $solved',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (accuracy > 0)
                                Text(
                                  'Accuracy: ${accuracy.toStringAsFixed(0)}%',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: accuracy >= 70 ? Colors.green : Colors.orange,
                                  ),
                                ),
                            ] else ...[
                              Text(
                                'Locked',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).disabledColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 16),
                
                // Progress to next level
                if (gameProvider.canProgressToNextLevel) ..._buildUnlockProgress(context, gameProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildUnlockProgress(BuildContext context, GameProvider gameProvider) {
    final nextLevel = _getNextLevel(gameProvider.currentDifficulty);
    if (nextLevel != null && !gameProvider.userProgress.isLevelUnlocked(nextLevel)) {
      return [
        const Divider(),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.star,
              size: 16,
              color: Colors.amber,
            ),
            const SizedBox(width: 8),
            Text(
              'Ready to unlock ${nextLevel.displayName}!',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.amber.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ];
    }
    return [];
  }

  DifficultyLevel? _getNextLevel(DifficultyLevel current) {
    switch (current) {
      case DifficultyLevel.easy:
        return DifficultyLevel.medium;
      case DifficultyLevel.medium:
        return DifficultyLevel.hard;
      case DifficultyLevel.hard:
        return null; // Already at max level
    }
  }

  void _selectDifficulty(BuildContext context, DifficultyLevel difficulty) {
    final gameProvider = context.read<GameProvider>();
    
    // Show confirmation dialog if switching during active game
    if (gameProvider.status == GameStatus.playing && gameProvider.currentPuzzle != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Switch Difficulty?'),
          content: Text(
            'Switching to ${difficulty.displayName} will start a new game. Your current progress will not be saved.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                gameProvider.changeDifficulty(difficulty);
              },
              child: const Text('Switch'),
            ),
          ],
        ),
      );
    } else {
      gameProvider.changeDifficulty(difficulty);
    }
  }
}

// Compact version for app bars or smaller spaces
class CompactDifficultyIndicator extends StatelessWidget {
  const CompactDifficultyIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final currentDifficulty = gameProvider.currentDifficulty;
        final progression = gameProvider.userProgress;
        final solved = progression.puzzlesSolvedByDifficulty[currentDifficulty] ?? 0;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getDifficultyColor(currentDifficulty).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getDifficultyColor(currentDifficulty),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getDifficultyIcon(currentDifficulty),
                size: 16,
                color: _getDifficultyColor(currentDifficulty),
              ),
              const SizedBox(width: 4),
              Text(
                '${currentDifficulty.displayName} ($solved)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _getDifficultyColor(currentDifficulty),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getDifficultyColor(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.easy:
        return Colors.green;
      case DifficultyLevel.medium:
        return Colors.orange;
      case DifficultyLevel.hard:
        return Colors.red;
    }
  }

  IconData _getDifficultyIcon(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.easy:
        return Icons.sentiment_satisfied;
      case DifficultyLevel.medium:
        return Icons.sentiment_neutral;
      case DifficultyLevel.hard:
        return Icons.sentiment_very_dissatisfied;
    }
  }
}