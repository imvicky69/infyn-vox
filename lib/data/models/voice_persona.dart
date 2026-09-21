class VoicePersona {
  final String id;
  final String name;
  final String gender;
  final String language;
  final String controlInstruction;
  final String? referenceAudioPath;
  final String? promptText; // Transcription of reference audio for Ultimate Cloning
  final String avatar;
  final List<String> tags;
  final bool isPreset;
  final DateTime? createdAt;

  VoicePersona({
    required this.id,
    required this.name,
    required this.gender,
    required this.language,
    required this.controlInstruction,
    this.referenceAudioPath,
    this.promptText,
    required this.avatar,
    this.tags = const [],
    this.isPreset = false,
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'gender': gender,
    'language': language,
    'controlInstruction': controlInstruction,
    'referenceAudioPath': referenceAudioPath,
    'promptText': promptText,
    'avatar': avatar,
    'tags': tags,
    'isPreset': isPreset,
    'createdAt': createdAt?.toIso8601String(),
  };

  factory VoicePersona.fromJson(Map<String, dynamic> json) => VoicePersona(
    id: json['id'],
    name: json['name'],
    gender: json['gender'],
    language: json['language'] ?? 'en',
    controlInstruction: json['controlInstruction'] ?? '',
    referenceAudioPath: json['referenceAudioPath'],
    promptText: json['promptText'],
    avatar: json['avatar'] ?? '🎙️',
    tags: List<String>.from(json['tags'] ?? []),
    isPreset: json['isPreset'] ?? false,
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
  );
}
