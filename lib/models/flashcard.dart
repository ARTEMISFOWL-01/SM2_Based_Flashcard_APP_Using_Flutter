import 'package:hive/hive.dart';

part 'flashcard.g.dart';

@HiveType(typeId: 1)
class Flashcard extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String question;

  @HiveField(2)
  String answer;

  @HiveField(3)
  int interval; // days

  @HiveField(4)
  DateTime nextReview;

  @HiveField(5)
  int correctCount;

  @HiveField(6)
  double easeFactor; // SM-2: starts at 2.5

  @HiveField(7)
  int repetitions; // SM-2: number of successful reviews

  Flashcard({
    required this.id,
    required this.question,
    required this.answer,
    this.interval = 1,
    DateTime? nextReview,
    this.correctCount = 0,
    this.easeFactor = 2.5,
    this.repetitions = 0,
  }) : nextReview = nextReview ?? DateTime.now();
}

/// SM-2 quality ratings (0–5 scale)
enum SM2Rating {
  again(0, 'Again', '😰'),
  hard(1, 'Hard', '😓'),
  good(3, 'Good', '🙂'),
  easy(4, 'Easy', '😊'),
  perfect(5, 'Perfect', '🤩');

  const SM2Rating(this.value, this.label, this.emoji);
  final int value;
  final String label;
  final String emoji;
}

class SM2Result {
  final int interval;
  final double easeFactor;
  final int repetitions;
  final DateTime nextReview;

  const SM2Result({
    required this.interval,
    required this.easeFactor,
    required this.repetitions,
    required this.nextReview,
  });
}

SM2Result applySM2({
  required int quality,       // 0–5
  required int interval,      // current interval in days
  required double easeFactor, // current EF (default 2.5)
  required int repetitions,   // number of consecutive correct reviews
}) {
  int newInterval;
  int newRepetitions;
  double newEF;

  if (quality < 3) {
    // Failed recall – restart
    newRepetitions = 0;
    newInterval = 1;
    newEF = easeFactor; // EF unchanged on failure
  } else {
    // Successful recall
    newRepetitions = repetitions + 1;
    if (newRepetitions == 1) {
      newInterval = 1;
    } else if (newRepetitions == 2) {
      newInterval = 6;
    } else {
      newInterval = (interval * easeFactor).round();
    }

    // Update EF: EF' = EF + (0.1 - (5-q)*(0.08 + (5-q)*0.02))
    newEF = easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    if (newEF < 1.3) newEF = 1.3; // minimum EF
  }

  final nextReview = DateTime.now().add(Duration(seconds: newInterval*5));

  return SM2Result(
    interval: newInterval,
    easeFactor: newEF,
    repetitions: newRepetitions,
    nextReview: nextReview,
  );
}
