const practiceFocusAreas = [
  'Forehand',
  'Backhand',
  'Serve',
  'Return',
  'Volleys',
  'Overhead',
  'Footwork',
  'Fitness',
  'Match play',
  'Doubles',
];

class PracticeSession {
  const PracticeSession({
    required this.id,
    required this.date,
    required this.minutes,
    this.focus = const [],
    this.drillIds = const [],
    this.intensity = 3,
    this.notes = '',
  });

  final String id;
  final DateTime date;
  final int minutes;
  final List<String> focus;
  final List<String> drillIds;

  /// How hard the session felt, 1 (easy) to 5 (very hard).
  final int intensity;
  final String notes;

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'minutes': minutes,
    'focus': focus,
    'drills': drillIds,
    'intensity': intensity,
    'notes': notes,
  };

  factory PracticeSession.fromJson(Map<String, dynamic> json) => PracticeSession(
    id: json['id'] as String,
    date: DateTime.parse(json['date'] as String),
    minutes: json['minutes'] as int,
    focus: (json['focus'] as List? ?? const []).cast<String>(),
    drillIds: (json['drills'] as List? ?? const []).cast<String>(),
    intensity: json['intensity'] as int? ?? 3,
    notes: json['notes'] as String? ?? '',
  );
}
