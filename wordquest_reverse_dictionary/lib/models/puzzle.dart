class Puzzle {
  final String id;
  final String type; // 'definition', 'emoji', 'riddle'
  final String clue;
  final String answer;
  final List<String> altAnswers;
  final String category;
  final int difficulty; // 1-3
  final int length;
  final List<String> hints;
  final List<String> tags;
  final int points;

  const Puzzle({
    required this.id,
    required this.type,
    required this.clue,
    required this.answer,
    required this.altAnswers,
    required this.category,
    required this.difficulty,
    required this.length,
    required this.hints,
    required this.tags,
    required this.points,
  });

  factory Puzzle.fromJson(Map<String, dynamic> json) {
    return Puzzle(
      id: json['id'] as String,
      type: json['type'] as String,
      clue: json['clue'] as String,
      answer: json['answer'] as String,
      altAnswers: List<String>.from(json['alt_answers'] ?? []),
      category: json['category'] as String,
      difficulty: json['difficulty'] as int,
      length: json['length'] as int,
      hints: List<String>.from(json['hints'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      points: json['points'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'clue': clue,
      'answer': answer,
      'alt_answers': altAnswers,
      'category': category,
      'difficulty': difficulty,
      'length': length,
      'hints': hints,
      'tags': tags,
      'points': points,
    };
  }

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'type': type,
      'clue': clue,
      'answer': answer,
      'alt_answers': altAnswers.join(','),
      'category': category,
      'difficulty': difficulty,
      'length': length,
      'hints': hints.join(','),
      'tags': tags.join(','),
      'points': points,
    };
  }

  factory Puzzle.fromDatabase(Map<String, dynamic> db) {
    return Puzzle(
      id: db['id'] as String,
      type: db['type'] as String,
      clue: db['clue'] as String,
      answer: db['answer'] as String,
      altAnswers: db['alt_answers'] != null && (db['alt_answers'] as String).isNotEmpty
          ? (db['alt_answers'] as String).split(',')
          : [],
      category: db['category'] as String,
      difficulty: db['difficulty'] as int,
      length: db['length'] as int,
      hints: db['hints'] != null && (db['hints'] as String).isNotEmpty
          ? (db['hints'] as String).split(',')
          : [],
      tags: db['tags'] != null && (db['tags'] as String).isNotEmpty
          ? (db['tags'] as String).split(',')
          : [],
      points: db['points'] as int,
    );
  }

  bool isCorrectAnswer(String userAnswer) {
    final normalized = userAnswer.toLowerCase().trim().replaceAll(RegExp(r'[^\w\s]'), '');
    final correctAnswer = answer.toLowerCase().trim().replaceAll(RegExp(r'[^\w\s]'), '');
    
    if (normalized == correctAnswer) return true;
    
    for (final alt in altAnswers) {
      final normalizedAlt = alt.toLowerCase().trim().replaceAll(RegExp(r'[^\w\s]'), '');
      if (normalized == normalizedAlt) return true;
    }
    
    return false;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Puzzle && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Puzzle(id: $id, type: $type, answer: $answer)';
  }
}