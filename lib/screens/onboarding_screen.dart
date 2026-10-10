import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_store.dart';
import '../models/ids.dart';
import '../models/player.dart';
import '../theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _department = TextEditingController();
  SkillLevel _level = SkillLevel.beginner;
  Handedness _hand = Handedness.right;

  @override
  void dispose() {
    _name.dispose();
    _department.dispose();
    super.dispose();
  }

  void _start() {
    if (!_form.currentState!.validate()) return;
    context.read<AppStore>().setMe(
      Player(
        id: newId(),
        name: _name.text.trim(),
        level: _level,
        hand: _hand,
        department: _department.text.trim(),
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [VeritasColors.navy, Color(0xFF1B4A7A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: VeritasColors.ball,
                        child: Icon(Icons.sports_tennis, color: VeritasColors.navy, size: 32),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Veritas Tennis',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'The tennis companion for Veritas University players. Keep score on court, track your '
                        'stats, climb the campus ladder, run tournaments and train smarter.',
                        style: TextStyle(color: Color(0xFFD5DEEA), fontSize: 15, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Create your player profile',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Everything is stored on your phone. No sign-up or internet needed.',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                Form(
                  key: _form,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Your name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => (v ?? '').trim().length < 2 ? 'Enter your name' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _department,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Department / level (optional)',
                          hintText: 'e.g. Computer Science, 200L',
                          prefixIcon: Icon(Icons.school_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<SkillLevel>(
                        isExpanded: true,
                        initialValue: _level,
                        decoration: const InputDecoration(
                          labelText: 'Playing level',
                          prefixIcon: Icon(Icons.trending_up),
                        ),
                        items: [for (final l in SkillLevel.values) DropdownMenuItem(value: l, child: Text(l.label))],
                        onChanged: (v) => setState(() => _level = v!),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<Handedness>(
                        segments: [for (final h in Handedness.values) ButtonSegment(value: h, label: Text(h.label))],
                        selected: {_hand},
                        onSelectionChanged: (s) => setState(() => _hand = s.first),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _start,
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text("Let's play"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
