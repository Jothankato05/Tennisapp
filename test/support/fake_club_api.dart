import 'package:veritas_tennis/data/club_api.dart';

/// In-memory stand-in for the Supabase functions, with the same semantics.
class FakeClubApi implements ClubApi {
  final clubs = <String, String>{};
  final rows = <String, Map<String, Object?>>{}; // "code|kind|id" → row
  var _clock = DateTime.utc(2026, 10, 1);
  bool offline = false;

  String _tick() => (_clock = _clock.add(const Duration(microseconds: 1))).toIso8601String();

  void _check() {
    if (offline) throw const SyncException('No connection');
  }

  @override
  Future<ClubInfo> createClub(String name) async {
    _check();
    final code = 'CODE${clubs.length + 1}-ABCDE';
    clubs[code] = name;
    return ClubInfo(code: code, name: name);
  }

  @override
  Future<ClubInfo?> getClub(String code) async {
    _check();
    return clubs.containsKey(code) ? ClubInfo(code: code, name: clubs[code]!) : null;
  }

  @override
  Future<void> push(String code, List<OutgoingRecord> records) async {
    _check();
    if (!clubs.containsKey(code)) throw const ClubNotFoundException();
    for (final r in records) {
      final j = r.toJson();
      rows['$code|${r.kind}|${r.id}'] = {
        'kind': r.kind,
        'id': r.id,
        'data': j['data'],
        'deleted': j['deleted'] ?? false,
        'updated_at': _tick(),
      };
    }
  }

  @override
  Future<List<RemoteRecord>> pull(String code, {String? since, int limit = 1000}) async {
    _check();
    if (!clubs.containsKey(code)) throw const ClubNotFoundException();
    final after = since == null ? null : DateTime.parse(since);
    final list =
        rows.entries
            .where((e) => e.key.startsWith('$code|'))
            .map((e) => e.value)
            .where((r) => after == null || DateTime.parse(r['updated_at']! as String).isAfter(after))
            .toList()
          ..sort((a, b) => (a['updated_at']! as String).compareTo(b['updated_at']! as String));
    return list.take(limit).map((r) => RemoteRecord.fromJson(r.cast<String, dynamic>())).toList();
  }
}
