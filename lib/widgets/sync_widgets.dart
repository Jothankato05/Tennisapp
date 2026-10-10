import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_store.dart';
import '../data/club_sync.dart';

/// Pull-to-refresh that syncs with the club (or does nothing when not in one).
class SyncRefresh extends StatelessWidget {
  const SyncRefresh({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final sync = context.read<ClubSync>();
    if (context.select<AppStore, bool>((s) => s.club == null)) return child;
    return RefreshIndicator(onRefresh: sync.syncNow, child: child);
  }
}

/// Small cloud icon showing the club sync state.
class SyncStatusIcon extends StatelessWidget {
  const SyncStatusIcon({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<ClubSync>();
    final pending = context.select<AppStore, int>((s) => s.pendingChanges);
    final (icon, tip) = switch (sync.status) {
      SyncStatus.off => (Icons.cloud_off_outlined, 'Not in a club — tap to set up club sync'),
      SyncStatus.syncing => (Icons.cloud_sync_outlined, 'Syncing with your club…'),
      SyncStatus.error => (Icons.cloud_off, sync.error ?? 'Sync problem'),
      SyncStatus.idle =>
        pending > 0
            ? (Icons.cloud_upload_outlined, '$pending change(s) waiting to sync')
            : (Icons.cloud_done_outlined, 'Up to date with your club'),
    };
    return IconButton(
      tooltip: tip,
      onPressed: onPressed,
      icon: Icon(icon, color: sync.status == SyncStatus.error ? Theme.of(context).colorScheme.error : null),
    );
  }
}
