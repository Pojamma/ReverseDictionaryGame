import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/puzzle.dart';
import '../services/adaptive_database_service.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  final AdaptiveDatabaseService _databaseService = AdaptiveDatabaseService.instance;
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _answerFocusNode = FocusNode();
  
  Puzzle? _currentPuzzle;
  bool _isLoading = true;
  bool _isAnswering = false;
  String? _feedback;
  bool _isCorrect = false;
  int _currentPuzzleIndex = 0;
  List<Puzzle> _puzzles = [];
  
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
    _loadPuzzles();
  }

  @override
  void dispose() {
    _answerController.dispose();
    _answerFocusNode.dispose();
    _feedbackAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadPuzzles() async {
    try {
      final puzzles = await _databaseService.getPuzzles(limit: 20);
      if (puzzles.isNotEmpty) {
        setState(() {
          _puzzles = puzzles;
          _currentPuzzle = puzzles[0];
          _isLoading = false;
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          _answerFocusNode.requestFocus();
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _feedback = 'Error loading puzzles: $e';
      });
    }
  }

  void _submitAnswer() {
    if (_answerController.text.trim().isEmpty || _currentPuzzle == null) return;
    
    setState(() {
      _isAnswering = true;
    });

    final userAnswer = _answerController.text.trim();
    final isCorrect = _currentPuzzle!.isCorrectAnswer(userAnswer);
    
    setState(() {
      _isCorrect = isCorrect;
      _feedback = isCorrect 
          ? 'Correct! The answer is "${_currentPuzzle!.answer}"'
          : 'Try again! Your answer: "$userAnswer"';
      _isAnswering = false;
    });
    
    _feedbackAnimationController.forward();
    
    if (isCorrect) {
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(seconds: 2), () {
        _nextPuzzle();
      });
    } else {
      HapticFeedback.lightImpact();
      _answerController.clear();
    }
  }

  void _nextPuzzle() {
    if (_currentPuzzleIndex < _puzzles.length - 1) {
      setState(() {
        _currentPuzzleIndex++;
        _currentPuzzle = _puzzles[_currentPuzzleIndex];
        _feedback = null;
        _answerController.clear();
      });
      _feedbackAnimationController.reset();
      _answerFocusNode.requestFocus();
    } else {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Congratulations!'),
        content: Text('You\'ve completed ${_puzzles.length} puzzles!'),
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
              _restartGame();
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  void _restartGame() {
    setState(() {
      _currentPuzzleIndex = 0;
      _currentPuzzle = _puzzles[0];
      _feedback = null;
      _answerController.clear();
    });
    _feedbackAnimationController.reset();
    _answerFocusNode.requestFocus();
  }

  void _showHint() {
    if (_currentPuzzle?.hints.isNotEmpty == true) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Hint'),
          content: Text(_currentPuzzle!.hints.first),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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

    if (_currentPuzzle == null) {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('WordQuest Game'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _currentPuzzle?.hints.isNotEmpty == true ? _showHint : null,
            icon: const Icon(Icons.lightbulb_outline),
            tooltip: 'Hint',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                '${_currentPuzzleIndex + 1} / ${_puzzles.length}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                          label: Text(_currentPuzzle!.type.toUpperCase()),
                          backgroundColor: _getTypeColor(),
                        ),
                        Chip(
                          label: Text('${_currentPuzzle!.length} letters'),
                          backgroundColor: Colors.grey.shade200,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _currentPuzzle!.clue,
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
            TextField(
              controller: _answerController,
              focusNode: _answerFocusNode,
              decoration: InputDecoration(
                labelText: 'Your answer',
                hintText: 'Type your guess here...',
                border: const OutlineInputBorder(),
                suffixIcon: _isAnswering
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        onPressed: _submitAnswer,
                        icon: const Icon(Icons.send),
                      ),
              ),
              onSubmitted: (_) => _submitAnswer(),
              textInputAction: TextInputAction.done,
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isAnswering ? null : _submitAnswer,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              child: _isAnswering
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit Answer'),
            ),
            const SizedBox(height: 24),
            if (_feedback != null)
              AnimatedBuilder(
                animation: _feedbackAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _feedbackAnimation.value,
                    child: Card(
                      color: _isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(
                              _isCorrect ? Icons.check_circle : Icons.cancel,
                              color: _isCorrect ? Colors.green : Colors.red,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _feedback!,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: _isCorrect ? Colors.green.shade800 : Colors.red.shade800,
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
            if (_isCorrect)
              ElevatedButton(
                onPressed: _nextPuzzle,
                child: Text(_currentPuzzleIndex < _puzzles.length - 1 ? 'Next Puzzle' : 'Finish'),
              ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor() {
    switch (_currentPuzzle!.type.toLowerCase()) {
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