class TTSRequest {
  final String text;
  final String? controlInstruction;
  final String mode; // 'design', 'controllable', 'ultimate'
  final String? referenceAudioPath;
  final String? promptText;
  final double cfgValue;
  final int inferenceTimesteps;
  final int? seed;
  final bool denoise;
  final bool normalize;
  final bool returnTimestamps;
  final String? language;

  TTSRequest({
    required this.text,
    this.controlInstruction,
    this.mode = 'design',
    this.referenceAudioPath,
    this.promptText,
    this.cfgValue = 2.0,
    this.inferenceTimesteps = 10,
    this.seed,
    this.denoise = false,
    this.normalize = true,
    this.returnTimestamps = false,
    this.language,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'control_instruction': controlInstruction,
    'mode': mode,
    'reference_audio_path': referenceAudioPath,
    'prompt_text': promptText,
    'cfg_value': cfgValue,
    'inference_timesteps': inferenceTimesteps,
    'seed': seed,
    'denoise': denoise,
    'normalize': normalize,
    'return_timestamps': returnTimestamps,
    'language': language,
  };
}
