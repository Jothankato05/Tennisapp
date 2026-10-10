import 'dart:async';

import 'package:flutter/foundation.dart';

import 'app_store.dart';
import 'club_api.dart';

enum SyncStatus { off, idle, syncing, error }

/// Keeps this phone's players, matches and tournaments in step with the club.
///
/// Local changes are pushed first, then everything changed elsewhere since the
/// last pull is applied. Records are last-writer-wins; changes not yet sent
/// from this phone are never overwritten by a pull.
class ClubSync extends ChangeNotifier {
  ClubSync(this.store, this.api, {this.debounce = const Duration(seconds: 3)}) {
    store.addListener(_onStoreChanged);
  }

  final AppStore store;
  final ClubApi api;
  final Duration debounce;

  static const _pushBatch = 200;
  static const _pageSize = 1000;

  /// Pulls overlap a little so changes committed slightly out of order on the
  /// server are never missed. Re-applying them is harmless.
  static const _overlap = Duration(minutes: 2);

  bool _running = false;
  bool _again = false;
  String? error;
  Timer? _debounceTimer;
  Timer? _periodic;

  SyncStatus get status {
    if (store.club == null) return SyncStatus.off;
    if (_running) return SyncStatus.syncing;
    if (error != null) return SyncStatus.error;
    return SyncStatus.idle;
  }

  /// Starts periodic background syncing while the app is open.
  void start() {
    _periodic?.cancel();
    _periodic = Timer.periodic(const Duration(minutes: 2), (_) => syncNow());
    syncNow();
  }

  void _onStoreChanged() {
    if (store.club == null || store.pendingChanges == 0) return;
    if (_running) {
      _again = true; // Edited while syncing: go round once more.
      return;
    }
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, syncNow);
  }

  Future<ClubInfo> createClub(String name) async {
    final info = await api.createClub(name.trim());
    store.joinClub(info, const []);
    await syncNow();
    return info;
  }

  /// Joins an existing club by its code. Throws [ClubNotFoundException].
  Future<ClubInfo> joinClub(String code) async {
    final normalised = code.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
    final info = await api.getClub(normalised);
    if (info == null) throw const ClubNotFoundException();
    final remote = <RemoteRecord>[];
    String? since;
    while (true) {
      final page = await api.pull(info.code, since: since, limit: _pageSize);
      remote.addAll(page);
      if (page.length < _pageSize) break;
      since = page.last.updatedAt;
    }
    store.joinClub(info, remote, cursor: remote.isEmpty ? null : remote.last.updatedAt);
    await syncNow();
    return info;
  }

  void leaveClub() {
    _debounceTimer?.cancel();
    error = null;
    store.leaveClub();
    notifyListeners();
  }

  /// Sends local changes and fetches the club's. Safe to call at any time.
  Future<void> syncNow() async {
    final club = store.club;
    if (club == null) return;
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    _debounceTimer?.cancel();
    notifyListeners();
    try {
      do {
        _again = false;
        await _push(club.code);
        await _pull(club.code);
      } while (_again && store.club?.code == club.code);
      error = null;
    } on ClubNotFoundException {
      error = 'This club no longer exists on the server.';
    } on SyncException catch (e) {
      error = e.message;
    } catch (e) {
      error = 'Sync failed: $e';
    } finally {
      _running = false;
      notifyListeners();
    }
  }

  Future<void> _push(String code) async {
    final pending = store.pendingRecords();
    for (var i = 0; i < pending.length; i += _pushBatch) {
      final batch = pending.sublist(i, i + _pushBatch > pending.length ? pending.length : i + _pushBatch);
      await api.push(code, [for (final p in batch) p.record]);
      store.markSent([for (final p in batch) (key: p.key, counter: p.counter)]);
    }
  }

  Future<void> _pull(String code) async {
    String? since = _rewind(store.syncCursor);
    String? newest = store.syncCursor;
    while (true) {
      final page = await api.pull(code, since: since, limit: _pageSize);
      store.applyRemote(page);
      if (page.isNotEmpty) {
        final last = page.last.updatedAt;
        if (newest == null || DateTime.parse(last).isAfter(DateTime.parse(newest))) newest = last;
        since = last;
      }
      if (page.length < _pageSize) break;
    }
    store.recordSync(cursor: newest);
  }

  static String? _rewind(String? cursor) {
    final t = cursor == null ? null : DateTime.tryParse(cursor);
    return t?.subtract(_overlap).toUtc().toIso8601String();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _periodic?.cancel();
    store.removeListener(_onStoreChanged);
    super.dispose();
  }
}
