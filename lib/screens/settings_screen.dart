import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/app_store.dart';
import '../util/device.dart';
import '../widgets/common.dart';
import 'club_screen.dart';
import 'ladder/player_form_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _restore(BuildContext context, String raw) async {
    final store = context.read<AppStore>();
    final ok = await confirm(
      context,
      title: 'Replace all data?',
      message: 'Everything on this phone will be replaced by the backup. This cannot be undone.',
      confirmLabel: 'Restore',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    try {
      store.importJson(raw);
      showSnack(context, 'Backup restored');
    } on FormatException catch (e) {
      showSnack(context, e.message);
    }
  }

  Future<void> _importFile(BuildContext context) async {
    try {
      final raw = await pickBackupFile();
      if (raw == null || !context.mounted) return;
      await _restore(context, raw);
    } catch (_) {
      if (context.mounted) showSnack(context, 'Could not open that file');
    }
  }

  Future<void> _import(BuildContext context) async {
    final controller = TextEditingController();
    final clip = await Clipboard.getData(Clipboard.kTextPlain);
    if (clip?.text != null && clip!.text!.trimLeft().startsWith('{')) controller.text = clip.text!;
    if (!context.mounted) return;
    final raw = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Paste the text of a Veritas Tennis backup.'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 6,
              decoration: const InputDecoration(hintText: '{ "version": 1, … }'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Restore')),
        ],
      ),
    );
    controller.dispose();
    if (raw == null || raw.trim().isEmpty || !context.mounted) return;
    await _restore(context, raw);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final me = store.me;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (me != null)
            Card(
              child: ListTile(
                leading: PlayerAvatar(initials: me.initials, highlight: true),
                title: Text(me.name),
                subtitle: const Text('Edit your player profile'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PlayerFormScreen(player: me))),
              ),
            ),
          const SectionHeader('Club'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: Text(store.club?.name ?? 'Club sync'),
              subtitle: Text(store.club == null ? 'Not joined' : 'Code ${store.club!.code} · tap to manage'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ClubScreen())),
            ),
          ),
          const SectionHeader('Your data'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Stored on this phone'),
                  subtitle: Text(
                    '${store.players.length} players · ${store.matches.length} matches · '
                    '${store.tournaments.length} tournaments · ${store.sessions.length} practice sessions',
                  ),
                ),
                const Divider(height: 1),
                Builder(
                  builder: (tile) => ListTile(
                    leading: const Icon(Icons.upload_outlined),
                    title: const Text('Back up'),
                    subtitle: const Text('Save to Drive or share'),
                    onTap: () => shareBackupFile(tile, store.exportJson()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.file_open_outlined),
                  title: const Text('Restore from file'),
                  onTap: () => _importFile(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.content_paste_outlined),
                  title: const Text('Restore from pasted text'),
                  onTap: () => _import(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.delete_forever_outlined, color: Theme.of(context).colorScheme.error),
                  title: Text('Erase all data', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  onTap: () async {
                    final ok = await confirm(
                      context,
                      title: 'Erase everything?',
                      message:
                          'All players, matches, tournaments and practice logs on this phone will be deleted. '
                          'Back up first if you might need them.',
                      confirmLabel: 'Erase',
                      destructive: true,
                    );
                    if (ok && context.mounted) {
                      Navigator.of(context).popUntil((r) => r.isFirst);
                      await store.resetAll();
                    }
                  },
                ),
              ],
            ),
          ),
          const SectionHeader('About'),
          const Card(
            child: ListTile(
              leading: Icon(Icons.sports_tennis),
              title: Text('Veritas Tennis 1.2'),
              subtitle: Text('Made for VUNA Racqueteers · Veritas University, Abuja'),
            ),
          ),
        ],
      ),
    );
  }
}
