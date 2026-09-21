enum SegmentStatus { pending, generating, ready, failed }

class TextSegment {
  final String id;
  final int index;
  String text;
  SegmentStatus status;
  String? audioPath;
  double? duration;
  int pauseAfterMs;
  String? errorMessage;

  TextSegment({
    required this.id,
    required this.index,
    required this.text,
    this.status = SegmentStatus.pending,
    this.audioPath,
    this.duration,
    this.pauseAfterMs = 300,
    this.errorMessage,
  });
}
