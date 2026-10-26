import 'dart:async';

import 'package:flutter/material.dart';

import '../theme.dart';
import '../util/pwa.dart';

/// "Install the app" card shown on Home when the web version runs in a
/// browser tab. Hidden in the Android/iOS apps and once installed.
class InstallBanner extends StatefulWidget {
  const InstallBanner({super.key});

  @override
  State<InstallBanner> createState() => _InstallBannerState();
}

class _InstallBannerState extends State<InstallBanner> {
  bool _dismissed = false;
  Timer? _recheck;

  @override
  void initState() {
    super.initState();
    // Browsers fire the install prompt a moment after the page loads.
    _recheck = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _recheck?.cancel();
    super.dispose();
  }

  Future<void> _install() async {
    if (isIosBrowser) {
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (ctx) => const SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add to Home Screen', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                SizedBox(height: 16),
                _Step(icon: Icons.ios_share, text: 'Tap the Share button in Safari'),
                _Step(icon: Icons.add_box_outlined, text: 'Choose "Add to Home Screen"'),
              ],
            ),
          ),
        ),
      );
      return;
    }
    final installed = await promptInstall();
    if (installed && mounted) setState(() => _dismissed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed || !canOfferInstall) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Material(
        color: VeritasColors.ball,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 6, 10),
          child: Row(
            children: [
              const Icon(Icons.install_mobile_rounded, color: VeritasColors.navy),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Install the app',
                  style: TextStyle(color: VeritasColors.navy, fontWeight: FontWeight.w800),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: VeritasColors.navy,
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                ),
                onPressed: _install,
                child: const Text('Install'),
              ),
              IconButton(
                tooltip: 'Not now',
                onPressed: () => setState(() => _dismissed = true),
                icon: const Icon(Icons.close_rounded, color: VeritasColors.navy),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: VeritasColors.court),
          const SizedBox(width: 14),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
