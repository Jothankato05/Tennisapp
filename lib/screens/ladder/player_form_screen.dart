import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_store.dart';
import '../../models/ids.dart';
import '../../models/player.dart';

class PlayerFormScreen extends StatefulWidget {
  const PlayerFormScreen({super.key, this.player});

  final Player? player;

  @override
  State<PlayerFormScreen> createState() => _PlayerFormScreenState();
}

class _PlayerFormScreenState extends State<PlayerFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.player?.name);
  late final _department = TextEditingController(text: widget.player?.department);
  late final _phone = TextEditingController(text: widget.player?.phone);
  late final _notes = TextEditingController(text: widget.player?.notes);
  late SkillLevel _level = widget.player?.level ?? SkillLevel.beginner;
  late Handedness _hand = widget.player?.hand ?? Handedness.right;

  @override
  void dispose() {
    for (final c in [_name, _department, _phone, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final store = context.read<AppStore>();
    final name = _name.text.trim();
    final duplicate = store.players.any((p) => p.id != widget.player?.id && p.name.toLowerCase() == name.toLowerCase());
    if (duplicate) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('There is already a player called $name. Add a surname or initial.')));
      return;
    }
    final base = widget.player ?? Player(id: newId(), name: name, createdAt: DateTime.now());
    store.savePlayer(
      base.copyWith(
        name: name,
        level: _level,
        hand: _hand,
        department: _department.text.trim(),
        phone: _phone.text.trim(),
        notes: _notes.text.trim(),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.player != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Edit player' : 'Add player'),
        actions: [TextButton(onPressed: _save, child: const Text('SAVE'))],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              autofocus: !editing,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline)),
              validator: (v) => (v ?? '').trim().length < 2 ? 'Enter a name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _department,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Department / level',
                hintText: 'e.g. Mass Communication, 300L',
                prefixIcon: Icon(Icons.school_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone / WhatsApp (optional)',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<SkillLevel>(
              isExpanded: true,
              initialValue: _level,
              decoration: const InputDecoration(labelText: 'Playing level', prefixIcon: Icon(Icons.trending_up)),
              items: [for (final l in SkillLevel.values) DropdownMenuItem(value: l, child: Text(l.label))],
              onChanged: (v) => setState(() => _level = v!),
            ),
            const SizedBox(height: 12),
            SegmentedButton<Handedness>(
              segments: [for (final h in Handedness.values) ButtonSegment(value: h, label: Text(h.label))],
              selected: {_hand},
              onSelectionChanged: (s) => setState(() => _hand = s.first),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Usual playing times, strengths, availability…',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
