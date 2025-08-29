import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'providers/game_provider.dart';
import 'services/puzzle_initialization_service.dart';
import 'screens/game_screen_provider.dart';
import 'widgets/difficulty_selector.dart';

void main() {
  // Initialize database factory for web/desktop
  try {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  } catch (e) {
    // Ignore errors on mobile platforms
  }
  
  runApp(const WordQuestApp());
}

class WordQuestApp extends StatelessWidget {
  const WordQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => GameProvider(),
      child: MaterialApp(
        title: 'WordQuest: Reverse Dictionary',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PuzzleInitializationService _initService = PuzzleInitializationService();
  InitializationStatus? _status;
  bool _isLoading = true;
  String _message = 'Initializing puzzles...';

  @override
  void initState() {
    super.initState();
    _initializePuzzles();
  }

  Future<void> _initializePuzzles() async {
    try {
      // Initialize base puzzles
      final result = await _initService.initializeBasePuzzles();
      final status = await _initService.getInitializationStatus();
      
      setState(() {
        _status = status;
        _isLoading = false;
        _message = result.message;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = 'Failed to initialize: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('WordQuest: Reverse Dictionary'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Welcome to WordQuest!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Guess the word from definitions, emojis, or riddles',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            if (_isLoading) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(_message),
            ] else ...[
              Icon(
                _status?.isInitialized == true ? Icons.check_circle : Icons.error,
                color: _status?.isInitialized == true ? Colors.green : Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _message,
                style: TextStyle(
                  fontSize: 14,
                  color: _status?.isInitialized == true ? Colors.green : Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              if (_status?.isInitialized == true) ...[
                const SizedBox(height: 16),
                Text(
                  'Loaded ${_status!.puzzlesInDatabase} puzzles',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ],
            
            // Difficulty Selector (only show when initialized)
            if (_status?.isInitialized == true) ...[
              const SizedBox(height: 20),
              const DifficultySelector(),
            ],
          ],
        ),
      ),
      floatingActionButton: _status?.isInitialized == true
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GameScreenProvider()),
                );
              },
              tooltip: 'Start Game',
              child: const Icon(Icons.play_arrow, size: 28),
            )
          : null,
    );
  }
}