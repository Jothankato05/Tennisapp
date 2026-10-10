import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// Opening animation: a tennis ball drops onto the court, bounces, then rises
/// and turns into a medallion revealing the Veritas University crest.
/// Tap anywhere to skip.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 3400))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    });
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    precacheImage(const AssetImage('assets/brand/veritas_crest.png'), context);
    precacheImage(const AssetImage('assets/brand/racqueteers_cutout.png'), context);
    if (MediaQuery.of(context).disableAnimations) {
      _c.value = 0.62; // Skip the bounce for people who prefer reduced motion.
    }
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _skip() {
    if (_c.value < 0.9) _c.animateTo(1, duration: const Duration(milliseconds: 280));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      // Material supplies the app's text style (the splash sits above the Navigator).
      child: Material(
        type: MaterialType.transparency,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _skip,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final t = _c.value;
              final exit = _interval(t, 0.9, 1.0, Curves.easeIn);
              return Opacity(
                opacity: 1 - exit,
                child: LayoutBuilder(builder: (context, box) => _scene(context, box.biggest, t)),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _scene(BuildContext context, Size size, double t) {
    final medallionCenter = Offset(size.width / 2, size.height * 0.40);
    const medallionRadius = 78.0;
    final crestIn = _interval(t, 0.56, 0.70, Curves.easeOutBack);
    final crestOpacity = _interval(t, 0.56, 0.66, Curves.easeOut);
    final shine = _interval(t, 0.68, 0.84, Curves.easeInOut);
    final title = _interval(t, 0.68, 0.80, Curves.easeOutCubic);
    final subtitle = _interval(t, 0.72, 0.84, Curves.easeOutCubic);
    final badge = _interval(t, 0.76, 0.88, Curves.easeOutCubic);

    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(
          painter: _CourtAndBallPainter(
            t: t,
            ground: size.height * 0.64,
            medallionCenter: medallionCenter,
            medallionRadius: medallionRadius,
          ),
        ),
        // Crest inside the medallion.
        Positioned(
          left: medallionCenter.dx - medallionRadius,
          top: medallionCenter.dy - medallionRadius,
          width: medallionRadius * 2,
          height: medallionRadius * 2,
          child: Opacity(
            opacity: crestOpacity,
            child: Transform.scale(
              scale: 0.8 + 0.2 * crestIn,
              child: ClipOval(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(22),
                      child: Image.asset('assets/brand/veritas_crest.png', filterQuality: FilterQuality.high),
                    ),
                    if (shine > 0 && shine < 1)
                      Transform.translate(
                        offset: Offset((shine * 2 - 1) * medallionRadius * 2.2, 0),
                        child: Transform.rotate(
                          angle: 0.35,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0),
                                  Colors.white.withValues(alpha: 0.65),
                                  Colors.white.withValues(alpha: 0),
                                ],
                                stops: const [0.38, 0.5, 0.62],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Wordmark.
        Positioned(
          left: 24,
          right: 24,
          top: medallionCenter.dy + medallionRadius + 30,
          child: Column(
            children: [
              Opacity(
                opacity: title,
                child: Transform.translate(
                  offset: Offset(0, 14 * (1 - title)),
                  child: const Text(
                    'Veritas Tennis',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Opacity(
                opacity: subtitle,
                child: Transform.translate(
                  offset: Offset(0, 10 * (1 - subtitle)),
                  child: const Text(
                    'VERITAS UNIVERSITY  ·  ABUJA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: VeritasColors.cream,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Team badge.
        Positioned(
          left: 0,
          right: 0,
          bottom: 48 + MediaQuery.of(context).padding.bottom,
          child: Opacity(
            opacity: badge,
            child: Transform.translate(
              offset: Offset(0, 12 * (1 - badge)),
              child: Center(
                child: Image.asset(
                  'assets/brand/racqueteers_cutout.png',
                  height: 88,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

double _interval(double t, double begin, double end, [Curve curve = Curves.linear]) {
  if (t <= begin) return 0;
  if (t >= end) return 1;
  return curve.transform((t - begin) / (end - begin));
}

/// A drop and three bounces with decreasing height, as fractions of the
/// drop height. Each entry: (start, end, peak). The first is the fall.
const _hops = [(0.00, 0.18, 1.0), (0.18, 0.33, 0.42), (0.33, 0.42, 0.14), (0.42, 0.48, 0.04)];
const _squashAtImpact = [0.15, 0.09, 0.04];

class _CourtAndBallPainter extends CustomPainter {
  _CourtAndBallPainter({
    required this.t,
    required this.ground,
    required this.medallionCenter,
    required this.medallionRadius,
  });

  final double t;
  final double ground;
  final Offset medallionCenter;
  final double medallionRadius;

  static const _ballRadius = 30.0;
  static final List<_Speck> _specks = _makeSpecks();

  static List<_Speck> _makeSpecks() {
    final rnd = math.Random(42);
    return List.generate(900, (_) {
      final a = rnd.nextDouble() * 2 * math.pi;
      final d = math.sqrt(rnd.nextDouble());
      return _Speck(Offset(math.cos(a) * d, math.sin(a) * d), 0.15 + rnd.nextDouble() * 0.35, rnd.nextBool());
    });
  }

  /// Height above the ground (0..1 of the drop) at time [time].
  double _height(double time) {
    for (final (s, e, peak) in _hops) {
      if (time >= s && time < e) {
        final u = (time - s) / (e - s);
        if (s == 0) return 1 - u * u; // the drop: accelerating fall
        return 4 * peak * u * (1 - u);
      }
    }
    return 0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackground(canvas, size);

    final dropHeight = ground - 80;
    final r = _ballRadius;
    final bounceEnd = _hops.last.$2;
    final morph = _interval(t, bounceEnd, 0.62, Curves.easeInOutCubic);
    final whiten = _interval(t, 0.52, 0.6, Curves.easeIn);

    // Horizontal drift: comes in from the left and settles in the middle.
    double xAt(double time) {
      final p = Curves.easeOutCubic.transform((time / bounceEnd).clamp(0.0, 1.0));
      return size.width / 2 - size.width * 0.32 * (1 - p);
    }

    final h = _height(t);
    final groundCenter = Offset(xAt(t), ground - r - h * dropHeight);

    // Squash on contact.
    var squash = 0.0;
    for (var i = 0; i < _squashAtImpact.length; i++) {
      final contact = _hops[i].$2;
      final d = (t - contact).abs();
      if (d < 0.012) squash = math.max(squash, _squashAtImpact[i] * (1 - d / 0.012));
    }

    // Rolling spin from horizontal travel, plus a little backspin wobble.
    final spin = (groundCenter.dx - size.width / 2) / r + t * 2.2;

    final center = Offset.lerp(groundCenter, medallionCenter, morph)!;
    final radius = r + (medallionRadius - r) * morph;

    // Ground shadow (fades as the ball lifts away from the court).
    if (morph < 1) {
      final lift = (h + morph * 1.5).clamp(0.0, 1.0);
      final shadowW = r * 2.4 * (1 - 0.55 * lift);
      final shadowH = r * 0.55 * (1 - 0.5 * lift);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(groundCenter.dx, ground + 2), width: shadowW, height: shadowH),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.5 * (1 - lift * 0.85) * (1 - morph))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 + 10 * lift),
      );
    }

    // Impact ripples on the court.
    for (var i = 0; i < 2; i++) {
      final contact = _hops[i].$2;
      final age = (t - contact) / 0.1;
      if (age > 0 && age < 1) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(xAt(contact), ground + 2),
            width: r * (2.4 + age * 5),
            height: r * (0.5 + age * 1.1),
          ),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = Colors.white.withValues(alpha: 0.22 * (1 - age) * (i == 0 ? 1 : 0.6)),
        );
      }
    }

    // Expanding gold ring as the medallion appears.
    final ring = _interval(t, 0.6, 0.76, Curves.easeOut);
    if (ring > 0 && ring < 1) {
      canvas.drawCircle(
        medallionCenter,
        medallionRadius + 6 + ring * 46,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2 * (1 - ring) + 0.4
          ..color = VeritasColors.ball.withValues(alpha: 0.55 * (1 - ring)),
      );
    }

    if (whiten < 1) {
      // Stretch slightly along the direction of travel when moving fast.
      final dh = (_height((t + 0.004).clamp(0.0, 1.0)) - _height((t - 0.004).clamp(0.0, 1.0))).abs() / 0.008;
      final stretch = morph > 0 ? 0.0 : (dh / 22).clamp(0.0, 0.05);
      _paintBall(canvas, center, radius, spin, squash * (1 - morph) - stretch);
    }
    if (whiten > 0) {
      // Medallion: soft shadow + white disc + thin gold edge.
      canvas.drawCircle(
        center.translate(0, 8),
        radius,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.35 * whiten)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
      canvas.drawCircle(center, radius, Paint()..color = Colors.white.withValues(alpha: whiten));
      canvas.drawCircle(
        center,
        radius - 1,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = VeritasColors.ball.withValues(alpha: 0.9 * whiten),
      );
    }
  }

  void _paintBackground(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -0.25),
          radius: 1.1,
          colors: [Color(0xFF0D3A5E), VeritasColors.navy, Color(0xFF010E1A)],
          stops: [0, 0.6, 1],
        ).createShader(rect),
    );

    // Court lines in perspective, very faint.
    final fade = _interval(t, 0.0, 0.15) * (1 - _interval(t, 0.55, 0.75) * 0.7);
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.07 * fade)
      ..strokeWidth = 1.2;
    final horizon = ground - 40;
    final cx = size.width / 2;
    for (final f in [-1.0, -0.62, 0.62, 1.0]) {
      canvas.drawLine(
        Offset(cx + f * size.width * 0.22, horizon),
        Offset(cx + f * size.width * 0.9, size.height),
        line,
      );
    }
    canvas.drawLine(Offset(cx - size.width * 0.22, horizon), Offset(cx + size.width * 0.22, horizon), line);
    canvas.drawLine(Offset(cx, horizon + 30), Offset(cx, size.height), line);
    final serviceY = horizon + (size.height - horizon) * 0.42;
    final spread = 0.22 + (0.9 - 0.22) * 0.42;
    canvas.drawLine(
      Offset(cx - size.width * spread * 0.62, serviceY),
      Offset(cx + size.width * spread * 0.62, serviceY),
      line,
    );
  }

  void _paintBall(Canvas canvas, Offset c, double r, double spin, double squash, {double alpha = 1}) {
    canvas.save();
    canvas.translate(c.dx, c.dy + r * squash); // keep the bottom on the court while squashed
    canvas.scale(1 + squash, 1 - squash);
    final rect = Rect.fromCircle(center: Offset.zero, radius: r);

    // Felt base with key light from the upper left.
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.38, -0.42),
          radius: 1.05,
          colors: [
            const Color(0xFFF6F99A).withValues(alpha: alpha),
            const Color(0xFFDCE84B).withValues(alpha: alpha),
            const Color(0xFFB3C12B).withValues(alpha: alpha),
            const Color(0xFF5E6A0E).withValues(alpha: alpha),
          ],
          stops: const [0, 0.32, 0.72, 1],
        ).createShader(rect),
    );
    if (alpha < 1) {
      canvas.restore();
      return;
    }

    canvas.save();
    canvas.clipPath(Path()..addOval(rect));

    // Felt texture.
    final speck = Paint();
    for (final s in _specks) {
      speck.color = s.light ? const Color(0x14FFFFFF) : const Color(0x123D4A00);
      canvas.drawCircle(s.pos * r, s.size * r / 24, speck);
    }

    // Seams: two curves that rotate with the spin.
    canvas.save();
    canvas.rotate(spin);
    final seamGroove = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.2
      ..color = const Color(0x334A5500)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.04);
    final seam = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.085
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xF2F4F7EC)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.012);
    for (final side in [-1.0, 1.0]) {
      final arc = Rect.fromCircle(center: Offset(side * r * 1.32, 0), radius: r * 0.98);
      final start = side < 0 ? -0.95 : math.pi - 0.95;
      canvas.drawArc(arc, start, 1.9, false, seamGroove);
      canvas.drawArc(arc, start, 1.9, false, seam);
    }
    canvas.restore();

    // Form shadow on the lower right for volume.
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0.5, 0.6),
          radius: 1.1,
          colors: [Color(0x00000000), Color(0x00000000), Color(0x66000000)],
          stops: [0, 0.45, 1],
        ).createShader(rect),
    );
    // Soft specular highlight.
    canvas.drawCircle(
      Offset(-r * 0.36, -r * 0.4),
      r * 0.42,
      Paint()
        ..shader = RadialGradient(colors: [Colors.white.withValues(alpha: 0.55), Colors.white.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: Offset(-r * 0.36, -r * 0.4), radius: r * 0.42)),
    );
    canvas.restore(); // clip

    // Fuzzy rim: felt fibres soften the silhouette, brighter where the light hits.
    canvas.drawCircle(
      Offset.zero,
      r * 1.005,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.07
        ..shader = SweepGradient(
          colors: const [Color(0x55E9F27A), Color(0x22808C1A), Color(0x55E9F27A)],
          transform: GradientRotation(-math.pi * 0.75),
        ).createShader(rect)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.05),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CourtAndBallPainter old) => old.t != t || old.ground != ground;
}

class _Speck {
  const _Speck(this.pos, this.size, this.light);
  final Offset pos;
  final double size;
  final bool light;
}
