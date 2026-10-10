import 'dart:convert';

import 'package:http/http.dart' as http;

/// The shared backend for club sync. The defaults point at the Veritas Tennis
/// Supabase project; override with --dart-define for another deployment.
/// The publishable key is meant to ship inside apps: the database only
/// exposes functions that require a valid club code.
const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://zgnpftbegetnqfriwaoo.supabase.co');
const supabaseKey = String.fromEnvironment(
  'SUPABASE_KEY',
  defaultValue: 'sb_publishable_MMJtDxFBfEzptX-ueF7i_g_IHoOXBNu',
);

class ClubInfo {
  const ClubInfo({required this.code, required this.name});

  final String code;
  final String name;

  Map<String, dynamic> toJson() => {'code': code, 'name': name};

  factory ClubInfo.fromJson(Map<String, dynamic> json) =>
      ClubInfo(code: json['code'] as String, name: json['name'] as String);
}

/// A record going up to the club: [data] is null when it was deleted.
class OutgoingRecord {
  const OutgoingRecord({required this.kind, required this.id, this.data});

  final String kind;
  final String id;
  final Map<String, dynamic>? data;

  Map<String, dynamic> toJson() => {'kind': kind, 'id': id, if (data != null) 'data': data else 'deleted': true};
}

class RemoteRecord {
  const RemoteRecord({
    required this.kind,
    required this.id,
    required this.data,
    required this.deleted,
    required this.updatedAt,
  });

  final String kind;
  final String id;
  final Map<String, dynamic>? data;
  final bool deleted;

  /// Server timestamp exactly as sent, used as the pull cursor.
  final String updatedAt;

  String get key => '$kind/$id';

  factory RemoteRecord.fromJson(Map<String, dynamic> json) => RemoteRecord(
    kind: json['kind'] as String,
    id: json['id'] as String,
    data: (json['data'] as Map?)?.cast<String, dynamic>(),
    deleted: json['deleted'] as bool? ?? false,
    updatedAt: json['updated_at'] as String,
  );
}

class ClubNotFoundException implements Exception {
  const ClubNotFoundException();

  @override
  String toString() => 'No club has that code. Check it and try again.';
}

class SyncException implements Exception {
  const SyncException(this.message);
  final String message;

  @override
  String toString() => message;
}

abstract class ClubApi {
  Future<ClubInfo> createClub(String name);

  /// Returns null when no club has [code].
  Future<ClubInfo?> getClub(String code);

  Future<void> push(String code, List<OutgoingRecord> records);

  /// Records changed after [since] (everything when null), oldest first.
  Future<List<RemoteRecord>> pull(String code, {String? since, int limit = 1000});
}

class SupabaseClubApi implements ClubApi {
  SupabaseClubApi({http.Client? client, this.baseUrl = supabaseUrl, this.apiKey = supabaseKey})
    : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;
  final String apiKey;

  Future<Object?> _rpc(String fn, Map<String, Object?> body) async {
    final http.Response res;
    try {
      res = await _client
          .post(
            Uri.parse('$baseUrl/rest/v1/rpc/$fn'),
            headers: {'apikey': apiKey, 'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 25));
    } catch (_) {
      throw const SyncException('No connection. Changes will sync when you are back online.');
    }
    final decoded = res.body.isEmpty ? null : jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode >= 200 && res.statusCode < 300) return decoded;
    final error = decoded is Map ? decoded : const {};
    if (error['code'] == 'P0002') throw const ClubNotFoundException();
    throw SyncException(
      res.statusCode >= 500
          ? 'The club server is not responding. Try again in a few minutes.'
          : (error['message'] as String? ?? 'Sync failed (${res.statusCode})'),
    );
  }

  @override
  Future<ClubInfo> createClub(String name) async {
    final rows = await _rpc('create_club', {'p_name': name}) as List;
    return ClubInfo.fromJson((rows.single as Map).cast<String, dynamic>());
  }

  @override
  Future<ClubInfo?> getClub(String code) async {
    final rows = await _rpc('get_club', {'p_code': code}) as List;
    return rows.isEmpty ? null : ClubInfo.fromJson((rows.first as Map).cast<String, dynamic>());
  }

  @override
  Future<void> push(String code, List<OutgoingRecord> records) async {
    await _rpc('sync_push', {'p_code': code, 'p_records': records.map((r) => r.toJson()).toList()});
  }

  @override
  Future<List<RemoteRecord>> pull(String code, {String? since, int limit = 1000}) async {
    final rows = await _rpc('sync_pull', {'p_code': code, 'p_since': since, 'p_limit': limit}) as List;
    return rows.map((r) => RemoteRecord.fromJson((r as Map).cast<String, dynamic>())).toList();
  }
}
