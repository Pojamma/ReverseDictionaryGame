import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../widgets/difficulty_selector.dart';

class GameScreenProvider extends StatefulWidget {
  const GameScreenProvider({super.key});

  @override
  State<GameScreenProvider> createState() => _GameScreenProviderState();
}

class _GameScreenProviderState extends State<GameScreenProvider> with TickerProviderStateMixin {
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _answerFocusNode = FocusNode();
  
  late AnimationController _feedbackAnimationController;
  late Animation<double> _feedbackAnimation;
  
  @override
  void initState() {
    super.initState();
    _feedbackAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _feedbackAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _feedbackAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    
    // Initialize game
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameProvider>().initializeGame(limit: 20);
    });
  }

  @override
  void dispose() {
    _answerController.dispose();
    _answerFocusNode.dispose();
    _feedbackAnimationController.dispose();
    super.dispose();
  }

  void _submitAnswer() {
    final gameProvider = context.read<GameProvider>();
    final userAnswer = _answerController.text.trim();
    
    if (userAnswer.isNotEmpty) {
      gameProvider.submitAnswer(userAnswer).then((_) {
        if (gameProvider.isCorrect) {
          _feedbackAnimationController.forward().then((_) {
            _answerController.clear();
          });
        } else {
          _feedbackAnimationController.forward();
          _answerController.clear();
        }
      });
    }
  }

  void _nextPuzzle() {
    final gameProvider = context.read<GameProvider>();
    gameProvider.nextPuzzle();
    _feedbackAnimationController.reset();
    _answerController.clear();
    Future.delayed(const Duration(milliseconds: 300), () {
      _answerFocusNode.requestFocus();
    });
  }

  void _showHint() {
    final gameProvider = context.read<GameProvider>();
    final hint = gameProvider.getCurrentHint();
    
    if (hint != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Hint'),
          content: Text(hint),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it!'),
            ),
          ],
        ),
      );
    }
  }

  void _showCompletionDialog() {
    final gameProvider = context.read<GameProvider>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Congratulations!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You\'ve completed ${gameProvider.puzzles.length} puzzles!'),
            const SizedBox(height: 16),
            Text('Score: ${gameProvider.totalScore} points'),
            Text('Accuracy: ${gameProvider.accuracy.toStringAsFixed(1)}%'),
            Text('Correct answers: ${gameProvider.correctAnswers}/${gameProvider.totalAttempts}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Return to home
            },
            child: const Text('Back to Home'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              gameProvider.restartGame();
              _feedbackAnimationController.reset();
              _answerController.clear();
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        // Show completion dialog when game is complete
        if (gameProvider.isGameComplete) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showCompletionDialog();
          });
        }

        // Loading state
        if (gameProvider.isLoading) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('WordQuest Game'),
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading puzzles...'),
                ],
              ),
            ),
          );
        }

        // Error state
        if (gameProvider.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('WordQuest Game'),
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    gameProvider.errorMessage ?? 'An error occurred',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => gameProvider.initializeGame(limit: 20),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        // No puzzle available
        if (gameProvider.currentPuzzle == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('WordQuest Game'),
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            ),
            body: const Center(
              child: Text('No puzzles available'),
            ),
          );
        }

        final currentPuzzle = gameProvider.currentPuzzle!;

        return Scaffold(
          appBar: AppBar(
            title: const Text('WordQuest Game'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            actions: [
              IconButton(
                onPressed: currentPuzzle.hints.isNotEmpty ? _showHint : null,
                icon: const Icon(Icons.lightbulb_outline, size: 28), // Increased icon size
                tooltip: 'Hint',
              ),
              IconButton(
                onPressed: gameProvider.skipPuzzle,
                icon: const Icon(Icons.skip_next, size: 28), // Increased icon size
                tooltip: 'Skip Puzzle',
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CompactDifficultyIndicator(),
                      const SizedBox(height: 4),
                      Text(
                        '${gameProvider.currentPuzzleIndex + 1} / ${gameProvider.puzzles.length}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${gameProvider.totalScore} pts',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Progress indicator
                LinearProgressIndicator(
                  value: gameProvider.progress,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Puzzle card
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Chip(
                              label: Text(currentPuzzle.type.toUpperCase()),
                              backgroundColor: _getTypeColor(currentPuzzle.type),
                            ),
                            Chip(
                              label: Text('${currentPuzzle.length} letters'),
                              backgroundColor: Colors.grey.shade200,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          currentPuzzle.clue,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Answer input
                TextField(
                  controller: _answerController,
                  focusNode: _answerFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Your answer',
                    hintText: 'Type your guess here...',
                    border: const OutlineInputBorder(),
                    suffixIcon: gameProvider.isAnswering
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            onPressed: _submitAnswer,
                            icon: const Icon(Icons.send, size: 28), // Increased icon size
                          ),
                  ),
                  onSubmitted: (_) => _submitAnswer(),
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  textCapitalization: TextCapitalization.none,
                ),
                const SizedBox(height: 16),
                
                // Submit button
                ElevatedButton(
                  onPressed: gameProvider.isAnswering ? null : _submitAnswer,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  child: gameProvider.isAnswering
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit Answer'),
                ),
                const SizedBox(height: 24),
                
                // Feedback
                if (gameProvider.feedback != null)
                  AnimatedBuilder(
                    animation: _feedbackAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _feedbackAnimation.value,
                        child: Card(
                          color: gameProvider.isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Icon(
                                  gameProvider.isCorrect ? Icons.check_circle : Icons.cancel,
                                  color: gameProvider.isCorrect ? Colors.green : Colors.red,
                                  size: 28, // Increased icon size
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    gameProvider.feedback!,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: gameProvider.isCorrect ? Colors.green.shade800 : Colors.red.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                const Spacer(),
                
                // Next button (only show if correct)
                if (gameProvider.isCorrect)
                  ElevatedButton(
                    onPressed: _nextPuzzle,
                    child: Text(gameProvider.remainingPuzzles > 0 ? 'Next Puzzle' : 'Finish'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'definition':
        return Colors.blue.shade200;
      case 'emoji':
        return Colors.orange.shade200;
      case 'riddle':
        return Colors.purple.shade200;
      default:
        return Colors.grey.shade200;
    }
  }
}