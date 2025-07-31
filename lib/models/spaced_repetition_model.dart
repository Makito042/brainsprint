
class ReviewTime {
  final int hour;
  final int minute;

  ReviewTime({required this.hour, required this.minute});

  Map<String, dynamic> toMap() {
    return {
      'hour': hour,
      'minute': minute,
    };
  }

  factory ReviewTime.fromMap(Map<String, dynamic> map) {
    return ReviewTime(
      hour: map['hour'],
      minute: map['minute'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReviewTime &&
           other.hour == hour &&
           other.minute == minute;
  }

  @override
  int get hashCode => hour.hashCode ^ minute.hashCode;
}

class ReviewSlot {
  final int dayOfWeek; // 0-6 where 0=Monday, 1=Tuesday, etc.
  final ReviewTime time;

  ReviewSlot({required this.dayOfWeek, required this.time});

  String get dayName {
    // dayOfWeek is 0-6 where 0=Monday, 1=Tuesday, etc.
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[dayOfWeek];
  }

  Map<String, dynamic> toMap() {
    return {
      'dayOfWeek': dayOfWeek,
      'time': time.toMap(),
    };
  }

  factory ReviewSlot.fromMap(Map<String, dynamic> map) {
    return ReviewSlot(
      dayOfWeek: map['dayOfWeek'],
      time: ReviewTime.fromMap(map['time']),
    );
  }
}

class SpacedRepetitionPreferences {
  final List<ReviewSlot> reviewSlots;
  final Map<String, DateTime> nextReviewDates;
  final Map<String, int> masteryLevels;

  SpacedRepetitionPreferences({
    required this.reviewSlots,
    required this.nextReviewDates,
    required this.masteryLevels,
  });

  Map<String, dynamic> toMap() {
    return {
      'reviewSlots': reviewSlots.map((slot) => slot.toMap()).toList(),
      'nextReviewDates': nextReviewDates.map((key, value) => MapEntry(key, value.toIso8601String())),
      'masteryLevels': masteryLevels,
    };
  }

  factory SpacedRepetitionPreferences.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return SpacedRepetitionPreferences(
      reviewSlots: [],
      nextReviewDates: {},
      masteryLevels: {},
    );
    }

    return SpacedRepetitionPreferences(
      reviewSlots: (map['reviewSlots'] as List<dynamic>?)?.map((slot) => ReviewSlot.fromMap(slot)).toList() ?? [],
      nextReviewDates: (map['nextReviewDates'] as Map<String, dynamic>?)?.map((key, value) => MapEntry(key, DateTime.parse(value))) ?? {},
      masteryLevels: (map['masteryLevels'] as Map<String, dynamic>?)?.map((key, value) => MapEntry(key, value as int)) ?? {},
    );
  }
}
