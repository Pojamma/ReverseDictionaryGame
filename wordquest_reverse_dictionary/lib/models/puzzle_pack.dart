import 'puzzle.dart';

class PuzzlePack {
  final String packId;
  final String name;
  final String description;
  final List<Puzzle> puzzles;
  final String version;

  const PuzzlePack({
    required this.packId,
    required this.name,
    required this.description,
    required this.puzzles,
    this.version = '1.0.0',
  });

  factory PuzzlePack.fromJson(Map<String, dynamic> json) {
    final packData = json['packs'][0] as Map<String, dynamic>; // Assuming single pack per file
    
    return PuzzlePack(
      packId: packData['pack_id'] as String,
      name: packData['name'] as String,
      description: packData['description'] as String,
      puzzles: (packData['puzzles'] as List)
          .map((puzzleJson) => Puzzle.fromJson(puzzleJson as Map<String, dynamic>))
          .toList(),
      version: json['version'] as String? ?? '1.0.0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'packs': [
        {
          'pack_id': packId,
          'name': name,
          'description': description,
          'puzzles': puzzles.map((puzzle) => puzzle.toJson()).toList(),
        }
      ],
    };
  }

  // Get puzzles by type
  List<Puzzle> getPuzzlesByType(String type) {
    return puzzles.where((puzzle) => puzzle.type == type).toList();
  }

  // Get puzzles by difficulty
  List<Puzzle> getPuzzlesByDifficulty(int difficulty) {
    return puzzles.where((puzzle) => puzzle.difficulty == difficulty).toList();
  }

  // Get puzzles by category
  List<Puzzle> getPuzzlesByCategory(String category) {
    return puzzles.where((puzzle) => puzzle.category == category).toList();
  }

  // Get random puzzles
  List<Puzzle> getRandomPuzzles(int count) {
    final shuffled = List<Puzzle>.from(puzzles);
    shuffled.shuffle();
    return shuffled.take(count).toList();
  }

  // Statistics
  int get totalPuzzles => puzzles.length;
  
  Map<String, int> get puzzleCountByType {
    final counts = <String, int>{};
    for (final puzzle in puzzles) {
      counts[puzzle.type] = (counts[puzzle.type] ?? 0) + 1;
    }
    return counts;
  }
  
  Map<int, int> get puzzleCountByDifficulty {
    final counts = <int, int>{};
    for (final puzzle in puzzles) {
      counts[puzzle.difficulty] = (counts[puzzle.difficulty] ?? 0) + 1;
    }
    return counts;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PuzzlePack && other.packId == packId;
  }

  @override
  int get hashCode => packId.hashCode;

  @override
  String toString() {
    return 'PuzzlePack(packId: $packId, name: $name, puzzles: ${puzzles.length})';
  }
}