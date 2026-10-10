import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/app_store.dart';
import '../widgets/common.dart';
import 'ladder/player_form_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _export(BuildContext context) async {
    final store = context.read<AppStore>();
    await Clipboard.setData(ClipboardData(text: store.exportJson()));
    if (context.mounted) {
      showSnack(context, 'Backup copied. Paste it into a note, email or chat to keep it safe or share it.');
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
            const Text('Paste a Veritas Tennis backup. This replaces ALL data on this phone.'),
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
    try {
      context.read<AppStore>().importJson(raw);
      showSnack(context, 'Backup restored');
    } on FormatException catch (e) {
      showSnack(context, e.message);
    }
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
                ListTile(
                  leading: const Icon(Icons.upload_outlined),
                  title: const Text('Back up / share data'),
                  subtitle: const Text('Copies everything as text. Send it to a teammate or your club secretary.'),
                  onTap: () => _export(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: const Text('Restore from backup'),
                  subtitle: const Text('Load data copied from another phone'),
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
              title: Text('Veritas Tennis 1.0'),
              subtitle: Text(
                'Built for the tennis players of Veritas University, Abuja. Works fully offline — '
                'no account or data connection needed.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
