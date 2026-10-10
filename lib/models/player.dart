enum SkillLevel {
  beginner('Beginner'),
  improver('Improver'),
  intermediate('Intermediate'),
  advanced('Advanced'),
  competitive('Competitive');

  const SkillLevel(this.label);
  final String label;
}

enum Handedness {
  right('Right-handed'),
  left('Left-handed');

  const Handedness(this.label);
  final String label;
}

class Player {
  const Player({
    required this.id,
    required this.name,
    this.level = SkillLevel.beginner,
    this.hand = Handedness.right,
    this.department = '',
    this.phone = '',
    this.notes = '',
    required this.createdAt,
  });

  final String id;
  final String name;
  final SkillLevel level;
  final Handedness hand;

  /// Department, faculty or hall, e.g. "Computer Science, 300L".
  final String department;
  final String phone;
  final String notes;
  final DateTime createdAt;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  Player copyWith({
    String? name,
    SkillLevel? level,
    Handedness? hand,
    String? department,
    String? phone,
    String? notes,
  }) => Player(
    id: id,
    name: name ?? this.name,
    level: level ?? this.level,
    hand: hand ?? this.hand,
    department: department ?? this.department,
    phone: phone ?? this.phone,
    notes: notes ?? this.notes,
    createdAt: createdAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'level': level.name,
    'hand': hand.name,
    'department': department,
    'phone': phone,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
    id: json['id'] as String,
    name: json['name'] as String,
    level: SkillLevel.values.asNameMap()[json['level']] ?? SkillLevel.beginner,
    hand: Handedness.values.asNameMap()[json['hand']] ?? Handedness.right,
    department: json['department'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    notes: json['notes'] as String? ?? '',
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
  );
}
