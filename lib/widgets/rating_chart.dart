import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../logic/ratings.dart';

/// Line chart of a player's rating after each ranked match.
class RatingChart extends StatelessWidget {
  const RatingChart({super.key, required this.history, this.height = 140});

  final List<RatingPoint> history;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final values = [startingRating, ...history.map((p) => p.rating)];
    return Semantics(
      label: 'Rating history from $startingRating to ${values.last} over ${history.length} ranked matches',
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _RatingPainter(
            values,
            line: scheme.primary,
            fill: scheme.primary.withValues(alpha: 0.12),
            grid: scheme.outlineVariant,
            text: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _RatingPainter extends CustomPainter {
  _RatingPainter(this.values, {required this.line, required this.fill, required this.grid, required this.text});

  final List<int> values;
  final Color line, fill, grid, text;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 40.0, bottom = 6.0, top = 8.0;
    final lo = values.reduce(math.min) - 10, hi = values.reduce(math.max) + 10;
    final w = size.width - left, h = size.height - top - bottom;
    double y(num v) => top + h - (v - lo) / (hi - lo) * h;
    double x(int i) => left + (values.length == 1 ? w / 2 : i / (values.length - 1) * w);

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final v in [lo + 10, (lo + hi) ~/ 2, hi - 10]) {
      canvas.drawLine(Offset(left, y(v)), Offset(size.width, y(v)), gridPaint);
      final tp = TextPainter(
        text: TextSpan(
          text: '$v',
          style: TextStyle(color: text, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y(v) - tp.height / 2));
    }

    final path = Path()..moveTo(x(0), y(values[0]));
    for (var i = 1; i < values.length; i++) {
      path.lineTo(x(i), y(values[i]));
    }
    final area = Path.from(path)
      ..lineTo(x(values.length - 1), top + h)
      ..lineTo(x(0), top + h)
      ..close();
    canvas.drawPath(area, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(Offset(x(values.length - 1), y(values.last)), 4, Paint()..color = line);
  }

  @override
  bool shouldRepaint(_RatingPainter old) => old.values != values || old.line != line;
}
