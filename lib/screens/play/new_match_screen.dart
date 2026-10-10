import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_store.dart';
import '../../models/ids.dart';
import '../../models/live_match.dart';
import '../../models/match_record.dart';
import '../../scoring/match_format.dart';
import '../../widgets/common.dart';
import '../../widgets/player_picker.dart';
import 'live_match_screen.dart';

class NewMatchScreen extends StatefulWidget {
  const NewMatchScreen({super.key, this.sideA, this.sideB, this.tournamentId, this.fixtureId, this.title});

  final Participant? sideA;
  final Participant? sideB;
  final String? tournamentId;
  final String? fixtureId;
  final String? title;

  @override
  State<NewMatchScreen> createState() => _NewMatchScreenState();
}

class _NewMatchScreenState extends State<NewMatchScreen> {
  MatchFormat _format = const MatchFormat();
  final List<Participant?> _a = [null, null];
  final List<Participant?> _b = [null, null];
  int _firstServer = 0;

  bool get _locked => widget.fixtureId != null;

  @override
  void initState() {
    super.initState();
    final store = context.read<AppStore>();
    final me = store.me;
    _a[0] = widget.sideA ?? (me == null ? null : Participant(playerId: me.id, name: me.name));
    _b[0] = widget.sideB;
    if (_locked) _format = _format.copyWith(finalSet: FinalSet.matchTiebreak);
  }

  int get _perSide => _format.doubles ? 2 : 1;

  Set<String> _takenIds({Participant? except}) => {
    for (final p in [..._a.take(_perSide), ..._b.take(_perSide)])
      if (p?.playerId != null && p != except) p!.playerId!,
  };

  Future<void> _pick(List<Participant?> side, int index, String label) async {
    final picked = await pickParticipant(
      context,
      title: label,
      exclude: _takenIds(except: side[index]),
    );
    if (picked != null) setState(() => side[index] = picked);
  }

  String? get _problem {
    final all = [..._a.take(_perSide), ..._b.take(_perSide)];
    if (all.any((p) => p == null)) return 'Choose every player';
    final names = all.map((p) => p!.playerId ?? 'guest:${p.name.toLowerCase()}').toList();
    if (names.toSet().length != names.length) return 'The same player is listed twice';
    return null;
  }

  void _start() {
    final problem = _problem;
    if (problem != null) {
      showSnack(context, problem);
      return;
    }
    final store = context.read<AppStore>();
    if (store.liveMatch != null) {
      showSnack(context, 'Finish or discard the match in progress first');
      return;
    }
    store.startLive(
      LiveMatch(
        id: newId(),
        format: _format,
        sideA: [for (final p in _a.take(_perSide)) p!],
        sideB: [for (final p in _b.take(_perSide)) p!],
        firstServerSide: _firstServer,
        startedAt: DateTime.now(),
        tournamentId: widget.tournamentId,
        fixtureId: widget.fixtureId,
      ),
    );
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => const LiveMatchScreen()));
  }

  String _sideLabel(List<Participant?> side, String fallback) {
    final names = side.take(_perSide).map((p) => p?.name).whereType<String>().toList();
    return names.isEmpty ? fallback : names.join(' / ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget slot(List<Participant?> side, int i, String label) {
      final p = side[i];
      return Card(
        child: ListTile(
          enabled: !(_locked && i == 0),
          leading: PlayerAvatar(initials: p == null ? '?' : _initials(p.name), radius: 18),
          title: Text(p?.name ?? label),
          subtitle: Text(p == null ? 'Tap to choose' : (p.playerId == null ? 'Guest' : 'Club player')),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _pick(side, i, label),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? 'New match')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!_locked)
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Singles'), icon: Icon(Icons.person)),
                ButtonSegment(value: true, label: Text('Doubles'), icon: Icon(Icons.people)),
              ],
              selected: {_format.doubles},
              onSelectionChanged: (s) => setState(() => _format = _format.copyWith(doubles: s.first)),
            ),
          const SectionHeader('Side A'),
          slot(_a, 0, _format.doubles ? 'Player A1' : 'Player A'),
          if (_format.doubles) ...[const SizedBox(height: 8), slot(_a, 1, 'Player A2 (partner)')],
          const SectionHeader('Side B'),
          slot(_b, 0, _format.doubles ? 'Player B1' : 'Player B'),
          if (_format.doubles) ...[const SizedBox(height: 8), slot(_b, 1, 'Player B2 (partner)')],
          if (_format.doubles)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'The first player listed on each side serves first for their team.',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          const SectionHeader('Format'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sets', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 1, label: Text('1 set')),
                      ButtonSegment(value: 3, label: Text('Best of 3')),
                      ButtonSegment(value: 5, label: Text('Best of 5')),
                    ],
                    selected: {_format.bestOf},
                    onSelectionChanged: (s) => setState(() => _format = _format.copyWith(bestOf: s.first)),
                  ),
                  const SizedBox(height: 12),
                  const Text('Games per set', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 6, label: Text('Standard (6)')),
                      ButtonSegment(value: 4, label: Text('Short (4)')),
                    ],
                    selected: {_format.gamesPerSet},
                    onSelectionChanged: (s) => setState(() => _format = _format.copyWith(gamesPerSet: s.first)),
                  ),
                  if (_format.bestOf > 1) ...[
                    const SizedBox(height: 12),
                    const Text('Deciding set', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<FinalSet>(
                      isExpanded: true,
                      initialValue: _format.finalSet,
                      items: const [
                        DropdownMenuItem(value: FinalSet.tiebreak, child: Text('Full set with tiebreak')),
                        DropdownMenuItem(value: FinalSet.matchTiebreak, child: Text('10-point match tiebreak')),
                        DropdownMenuItem(value: FinalSet.advantage, child: Text('Advantage set (no tiebreak)')),
                      ],
                      onChanged: (v) => setState(() => _format = _format.copyWith(finalSet: v)),
                    ),
                  ],
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('No-ad scoring'),
                    subtitle: const Text('Deciding point at 40-40'),
                    value: _format.noAd,
                    onChanged: (v) => setState(() => _format = _format.copyWith(noAd: v)),
                  ),
                ],
              ),
            ),
          ),
          const SectionHeader('Who serves first?'),
          SegmentedButton<int>(
            segments: [
              ButtonSegment(value: 0, label: Text(_sideLabel(_a, 'Side A'), overflow: TextOverflow.ellipsis)),
              ButtonSegment(value: 1, label: Text(_sideLabel(_b, 'Side B'), overflow: TextOverflow.ellipsis)),
            ],
            selected: {_firstServer},
            onSelectionChanged: (s) => setState(() => _firstServer = s.first),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(onPressed: _start, icon: const Icon(Icons.play_arrow), label: const Text('Start match')),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}
