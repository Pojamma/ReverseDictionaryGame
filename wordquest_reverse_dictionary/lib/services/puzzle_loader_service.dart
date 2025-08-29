import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/puzzle.dart';
import '../models/puzzle_pack.dart';

class PuzzleLoaderService {
  static const String _basePath = 'assets/puzzles/';
  
  // Available puzzle pack files
  static const List<String> _puzzleFiles = [
    'puzzles_base.json',
    'puzzles_base200.json',
    'puzzles_holiday.json',
    'puzzles_movies_tv.json',
  ];

  // Load a single puzzle pack from assets
  Future<PuzzlePack> loadPuzzlePack(String filename) async {
    try {
      final String jsonString = await rootBundle.loadString('$_basePath$filename');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      return PuzzlePack.fromJson(jsonData);
    } catch (e) {
      throw Exception('Failed to load puzzle pack $filename: $e');
    }
  }

  // Load all available puzzle packs
  Future<List<PuzzlePack>> loadAllPuzzlePacks() async {
    final List<PuzzlePack> packs = [];
    
    for (final filename in _puzzleFiles) {
      try {
        final pack = await loadPuzzlePack(filename);
        packs.add(pack);
      } catch (e) {
        // Log error but continue loading other packs
        print('Warning: Failed to load $filename: $e');
      }
    }
    
    if (packs.isEmpty) {
      throw Exception('No puzzle packs could be loaded');
    }
    
    return packs;
  }

  // Load only the base puzzle pack (most important)
  Future<PuzzlePack> loadBasePuzzlePack() async {
    return loadPuzzlePack('puzzles_base.json');
  }

  // Get all puzzles from all packs combined
  Future<List<Puzzle>> loadAllPuzzles() async {
    final packs = await loadAllPuzzlePacks();
    final List<Puzzle> allPuzzles = [];
    
    for (final pack in packs) {
      allPuzzles.addAll(pack.puzzles);
    }
    
    return allPuzzles;
  }

  // Load puzzles by type from all packs
  Future<List<Puzzle>> loadPuzzlesByType(String type) async {
    final puzzles = await loadAllPuzzles();
    return puzzles.where((puzzle) => puzzle.type == type).toList();
  }

  // Load puzzles by difficulty from all packs
  Future<List<Puzzle>> loadPuzzlesByDifficulty(int difficulty) async {
    final puzzles = await loadAllPuzzles();
    return puzzles.where((puzzle) => puzzle.difficulty == difficulty).toList();
  }

  // Load puzzles by category from all packs
  Future<List<Puzzle>> loadPuzzlesByCategory(String category) async {
    final puzzles = await loadAllPuzzles();
    return puzzles.where((puzzle) => puzzle.category == category).toList();
  }

  // Get statistics about available content
  Future<Map<String, dynamic>> getContentStatistics() async {
    final packs = await loadAllPuzzlePacks();
    final allPuzzles = packs.expand((pack) => pack.puzzles).toList();
    
    final typeStats = <String, int>{};
    final difficultyStats = <int, int>{};
    final categoryStats = <String, int>{};
    
    for (final puzzle in allPuzzles) {
      typeStats[puzzle.type] = (typeStats[puzzle.type] ?? 0) + 1;
      difficultyStats[puzzle.difficulty] = (difficultyStats[puzzle.difficulty] ?? 0) + 1;
      categoryStats[puzzle.category] = (categoryStats[puzzle.category] ?? 0) + 1;
    }
    
    return {
      'total_packs': packs.length,
      'total_puzzles': allPuzzles.length,
      'types': typeStats,
      'difficulties': difficultyStats,
      'categories': categoryStats,
      'packs': packs.map((pack) => {
        'pack_id': pack.packId,
        'name': pack.name,
        'puzzle_count': pack.totalPuzzles,
      }).toList(),
    };
  }

  // Validate puzzle data integrity
  Future<List<String>> validatePuzzleData() async {
    final List<String> errors = [];
    
    try {
      final packs = await loadAllPuzzlePacks();
      final Set<String> seenIds = {};
      
      for (final pack in packs) {
        for (final puzzle in pack.puzzles) {
          // Check for duplicate IDs
          if (seenIds.contains(puzzle.id)) {
            errors.add('Duplicate puzzle ID: ${puzzle.id}');
          }
          seenIds.add(puzzle.id);
          
          // Validate required fields
          if (puzzle.answer.isEmpty) {
            errors.add('Empty answer for puzzle ${puzzle.id}');
          }
          
          if (puzzle.clue.isEmpty) {
            errors.add('Empty clue for puzzle ${puzzle.id}');
          }
          
          if (puzzle.difficulty < 1 || puzzle.difficulty > 3) {
            errors.add('Invalid difficulty ${puzzle.difficulty} for puzzle ${puzzle.id}');
          }
          
          if (puzzle.length != puzzle.answer.replaceAll(RegExp(r'[^\w]'), '').length) {
            errors.add('Length mismatch for puzzle ${puzzle.id}: expected ${puzzle.length}, got ${puzzle.answer.replaceAll(RegExp(r'[^\w]'), '').length}');
          }
        }
      }
    } catch (e) {
      errors.add('Failed to validate puzzle data: $e');
    }
    
    return errors;
  }
}