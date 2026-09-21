class WordTimestamp {
  final String word;
  final double start;
  final double end;

  WordTimestamp({
    required this.word,
    required this.start,
    required this.end,
  });

  factory WordTimestamp.fromJson(Map<String, dynamic> json) => WordTimestamp(
    word: json['word'] ?? '',
    start: (json['start'] as num).toDouble(),
    end: (json['end'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'word': word,
    'start': start,
    'end': end,
  };
}

class GenerationResult {
  final String id;
  final String audioPath;
  final double duration;
  final double inferenceTime;
  final double rtf;
  final int sampleRate;
  final String text;
  final String? voiceName;
  final List<WordTimestamp> timestamps;
  final DateTime createdAt;

  GenerationResult({
    required this.id,
    required this.audioPath,
    required this.duration,
    required this.inferenceTime,
    required this.rtf,
    required this.sampleRate,
    required this.text,
    this.voiceName,
    this.timestamps = const [],
    required this.createdAt,
  });
}
