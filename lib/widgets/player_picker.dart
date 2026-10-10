import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_store.dart';
import '../models/match_record.dart';
import '../models/player.dart';
import 'common.dart';

/// Bottom sheet to pick a club player, or type a guest's name.
Future<Participant?> pickParticipant(
  BuildContext context, {
  String title = 'Choose player',
  Set<String> exclude = const {},
  bool allowGuest = true,
}) {
  return showModalBottomSheet<Participant>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _PickerSheet(title: title, exclude: exclude, allowGuest: allowGuest),
  );
}

class _PickerSheet extends StatefulWidget {
  const _PickerSheet({required this.title, required this.exclude, required this.allowGuest});

  final String title;
  final Set<String> exclude;
  final bool allowGuest;

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final q = _query.text.trim().toLowerCase();
    final players = store.players
        .where((p) => !widget.exclude.contains(p.id))
        .where((p) => q.isEmpty || p.name.toLowerCase().contains(q) || p.department.toLowerCase().contains(q))
        .toList();
    final typed = _query.text.trim();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _query,
                    autofocus: store.players.length > 8,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: widget.allowGuest ? 'Search players or type a guest name' : 'Search players',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: [
                  if (widget.allowGuest && typed.length >= 2)
                    ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person_add_alt)),
                      title: Text('Use "$typed" as a guest'),
                      subtitle: const Text('Guest results are not ranked on the ladder'),
                      onTap: () => Navigator.pop(context, Participant(name: typed)),
                    ),
                  for (final Player p in players)
                    ListTile(
                      leading: PlayerAvatar(initials: p.initials, highlight: p.id == store.meId),
                      title: Text(p.id == store.meId ? '${p.name} (you)' : p.name),
                      subtitle: Text([p.level.label, if (p.department.isNotEmpty) p.department].join(' · ')),
                      trailing: Text('${store.ratingOf(p.id)}'),
                      onTap: () => Navigator.pop(context, Participant(playerId: p.id, name: p.name)),
                    ),
                  if (players.isEmpty && typed.length < 2)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No players found. Add club players from the Ladder tab, or type a name to play a guest.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
