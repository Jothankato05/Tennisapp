import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_store.dart';
import '../data/club_api.dart';
import '../data/club_sync.dart';
import '../theme.dart';
import '../util/device.dart';
import '../util/format.dart';
import '../widgets/common.dart';

class ClubScreen extends StatefulWidget {
  const ClubScreen({super.key});

  @override
  State<ClubScreen> createState() => _ClubScreenState();
}

class _ClubScreenState extends State<ClubScreen> {
  final _name = TextEditingController(text: 'Veritas University Tennis Club');
  final _code = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on ClubNotFoundException catch (e) {
      if (mounted) showSnack(context, e.toString());
    } on SyncException catch (e) {
      if (mounted) showSnack(context, e.message);
    } catch (e) {
      if (mounted) showSnack(context, 'Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _create() {
    final name = _name.text.trim();
    if (name.length < 2) {
      showSnack(context, 'Give the club a name');
      return;
    }
    _run(() async {
      final info = await context.read<ClubSync>().createClub(name);
      if (mounted) showSnack(context, 'Club created. Share the code ${info.code} with your players.');
    });
  }

  void _join() {
    final code = _code.text.trim();
    if (code.length < 5) {
      showSnack(context, 'Enter the club code, e.g. KQ7MZ-3HXPA');
      return;
    }
    _run(() async {
      final info = await context.read<ClubSync>().joinClub(code);
      if (mounted) showSnack(context, 'Joined ${info.name}');
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final club = store.club;
    return Scaffold(
      appBar: AppBar(title: const Text('Club sync')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_busy) const LinearProgressIndicator(),
            if (club == null) ..._notInClub(context) else ..._inClub(context, store, club),
          ],
        ),
      ),
    );
  }

  List<Widget> _notInClub(BuildContext context) {
    final muted = TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant);
    return [
      Card(
        color: VeritasColors.navy,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.groups, color: VeritasColors.ball, size: 32),
              SizedBox(height: 10),
              Text(
                'One ladder for the whole club',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 6),
              Text(
                'Join a club and everyone\'s players, results, ladder and tournaments stay in sync across '
                'all members\' phones. Practice logs stay private. The app keeps working offline and syncs '
                'when you are connected.',
                style: TextStyle(color: Color(0xFFD5DEEA), height: 1.4),
              ),
            ],
          ),
        ),
      ),
      const SectionHeader('Join your club'),
      Text('Ask your club captain or secretary for the code.', style: muted),
      const SizedBox(height: 10),
      TextField(
        controller: _code,
        textCapitalization: TextCapitalization.characters,
        autocorrect: false,
        decoration: const InputDecoration(labelText: 'Club code', hintText: 'KQ7MZ-3HXPA'),
        onSubmitted: (_) => _join(),
      ),
      const SizedBox(height: 10),
      FilledButton.icon(onPressed: _join, icon: const Icon(Icons.login), label: const Text('Join club')),
      const SectionHeader('Or start a new club'),
      Text('For captains: create the club once, then share the code in your WhatsApp group.', style: muted),
      const SizedBox(height: 10),
      TextField(
        controller: _name,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: 'Club name'),
      ),
      const SizedBox(height: 10),
      OutlinedButton.icon(onPressed: _create, icon: const Icon(Icons.add), label: const Text('Create club')),
      const SizedBox(height: 16),
      Text(
        'When you join, players on this phone with the same name as a club player are merged automatically. '
        'You can merge other duplicates from a player\'s profile.',
        style: muted.copyWith(fontSize: 12.5),
      ),
    ];
  }

  List<Widget> _inClub(BuildContext context, AppStore store, ClubInfo club) {
    final sync = context.watch<ClubSync>();
    final theme = Theme.of(context);
    final status = switch (sync.status) {
      SyncStatus.syncing => 'Syncing…',
      SyncStatus.error => sync.error ?? 'Sync problem',
      _ when store.pendingChanges > 0 => '${store.pendingChanges} change(s) waiting to sync',
      _ when store.lastSyncAt != null =>
        'Up to date · last synced ${fmtRelativeDay(store.lastSyncAt!).toLowerCase()} at ${fmtTime(store.lastSyncAt!)}',
      _ => 'Not synced yet',
    };
    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(club.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              const Text('Club code', style: TextStyle(fontWeight: FontWeight.w600)),
              SelectableText(
                club.code,
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 2),
              ),
              const SizedBox(height: 4),
              Text(
                'Anyone with this code can join and edit club results, so only share it with your players.',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12.5),
              ),
              const SizedBox(height: 12),
              Builder(
                builder: (btn) => FilledButton.icon(
                  onPressed: () => shareText(
                    btn,
                    'Join our tennis club "${club.name}" on the Veritas Tennis app 🎾\n'
                    'Open the app › Home › cloud icon (or Settings › Club sync) › Join club\n'
                    'Club code: ${club.code}',
                    subject: club.name,
                  ),
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Invite players'),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      Card(
        child: ListTile(
          leading: Icon(
            sync.status == SyncStatus.error ? Icons.cloud_off : Icons.cloud_done_outlined,
            color: sync.status == SyncStatus.error ? theme.colorScheme.error : null,
          ),
          title: Text(status),
          trailing: sync.status == SyncStatus.syncing
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : TextButton(onPressed: sync.syncNow, child: const Text('SYNC NOW')),
        ),
      ),
      const SectionHeader('What is shared'),
      Text(
        '• Players, match results, the ladder and tournaments are shared with the club.\n'
        '• Your practice log and any match you are scoring right now stay on this phone until saved.\n'
        '• If two people edit the same thing, the last change to reach the club wins.',
        style: TextStyle(color: theme.colorScheme.onSurfaceVariant, height: 1.5),
      ),
      const SizedBox(height: 24),
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
        onPressed: () async {
          final ok = await confirm(
            context,
            title: 'Leave ${club.name}?',
            message: 'Your data stays on this phone but will stop syncing. You can rejoin with the code at any time.',
            confirmLabel: 'Leave',
            destructive: true,
          );
          if (ok && context.mounted) context.read<ClubSync>().leaveClub();
        },
        icon: const Icon(Icons.logout),
        label: const Text('Leave club'),
      ),
    ];
  }
}
