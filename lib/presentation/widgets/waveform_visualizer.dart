import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class WaveformVisualizer extends StatelessWidget {
  final List<double> peaks;
  final Duration currentPosition;
  final Duration totalDuration;
  final Function(Duration) onSeek;
  final double height;

  const WaveformVisualizer({
    super.key,
    required this.peaks,
    required this.currentPosition,
    required this.totalDuration,
    required this.onSeek,
    this.height = 64,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalDuration.inMilliseconds > 0
        ? (currentPosition.inMilliseconds / totalDuration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            final dx = details.localPosition.dx.clamp(0.0, constraints.maxWidth);
            final tapProgress = dx / constraints.maxWidth;
            final targetMs = (tapProgress * totalDuration.inMilliseconds).toInt();
            onSeek(Duration(milliseconds: targetMs));
          },
          child: SizedBox(
            height: height,
            width: constraints.maxWidth,
            child: CustomPaint(
              painter: _WaveformPainter(
                peaks: peaks.isEmpty ? _defaultPeaks : peaks,
                progress: progress,
              ),
            ),
          ),
        );
      },
    );
  }

  static final List<double> _defaultPeaks = List.generate(64, (i) => 0.2 + (i % 5) * 0.15);
}

class _WaveformPainter extends CustomPainter {
  final List<double> peaks;
  final double progress;

  _WaveformPainter({required this.peaks, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (peaks.isEmpty) return;

    final barCount = peaks.length;
    final totalSpacing = (barCount - 1) * 2.0;
    final barWidth = ((size.width - totalSpacing) / barCount).clamp(1.5, 8.0);
    final centerY = size.height / 2;

    final playedPaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppTheme.primary, AppTheme.secondary],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth;

    final unplayedPaint = Paint()
      ..color = AppTheme.surfaceBorder.withOpacity(0.6)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth;

    for (int i = 0; i < barCount; i++) {
      final x = i * (barWidth + 2.0) + (barWidth / 2);
      final barProgress = i / barCount;
      final isPlayed = barProgress <= progress;

      final amp = peaks[i].clamp(0.1, 1.0);
      final barHeight = amp * (size.height * 0.85);

      canvas.drawLine(
        Offset(x, centerY - barHeight / 2),
        Offset(x, centerY + barHeight / 2),
        isPlayed ? playedPaint : unplayedPaint,
      );
    }

    // Draw playhead vertical line with subtle glow
    final playheadX = progress * size.width;
    final playheadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0;

    canvas.drawLine(
      Offset(playheadX, 0),
      Offset(playheadX, size.height),
      playheadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.peaks != peaks;
  }
}
