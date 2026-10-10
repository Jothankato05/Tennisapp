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
  SkillLevel _level = SkillLevel.beginner;
  Handedness _hand = Handedness.right;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _start() {
    if (!_form.currentState!.validate()) return;
    context.read<AppStore>().setMe(
      Player(id: newId(), name: _name.text.trim(), level: _level, hand: _hand, createdAt: DateTime.now()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: VeritasColors.navy,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 24, 32, 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Image.asset('assets/brand/racqueteers_cutout.png', filterQuality: FilterQuality.high),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Veritas Tennis',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Score. Compete. Improve.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SafeArea(
                top: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Form(
                      key: _form,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Welcome', style: theme.textTheme.headlineSmall),
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _name,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(hintText: 'Your name'),
                              validator: (v) => (v ?? '').trim().length < 2 ? 'Enter your name' : null,
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final l in SkillLevel.values)
                                  ChoiceChip(
                                    label: Text(l.label),
                                    selected: _level == l,
                                    onSelected: (_) => setState(() => _level = l),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SegmentedButton<Handedness>(
                              showSelectedIcon: false,
                              segments: const [
                                ButtonSegment(value: Handedness.right, label: Text('Right-handed')),
                                ButtonSegment(value: Handedness.left, label: Text('Left-handed')),
                              ],
                              selected: {_hand},
                              onSelectionChanged: (s) => setState(() => _hand = s.first),
                            ),
                            const SizedBox(height: 24),
                            FilledButton(onPressed: _start, child: const Text("Let's play")),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
