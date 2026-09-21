import 'package:flutter_test/flutter_test.dart';
import 'package:vox_studio/data/services/segmenter_service.dart';
import 'package:vox_studio/data/models/tts_request.dart';
import 'package:vox_studio/core/constants/presets.dart';
import 'package:vox_studio/core/constants/languages.dart';

void main() {
  group('SegmenterService Tests', () {
    final service = SegmenterService();

    test('Splits multi-sentence paragraph into distinct segments', () {
      const text = "First sentence here. Second sentence follows! Third sentence is a question?";
      final segments = service.splitText(text, maxWordsPerSegment: 3);
      expect(segments.isNotEmpty, true);
      expect(segments.length, 3);
      expect(segments[0].text, contains("First sentence"));
    });

    test('Generates valid SRT formatted string from segments', () {
      final segments = service.splitText("Hello world. How are you today?");
      for (final s in segments) {
        s.duration = 1.5;
      }
      final srt = service.generateSrt(segments);
      expect(srt, contains("-->"));
      expect(srt, contains("Hello world."));
    });
  });

  group('Model and Preset Integrity Tests', () {
    test('Default presets load with valid IDs and non-empty control instructions', () {
      expect(DefaultPresets.presets.length, greaterThanOrEqualTo(5));
      for (final p in DefaultPresets.presets) {
        expect(p.id.isNotEmpty, true);
        expect(p.name.isNotEmpty, true);
        expect(p.avatar.isNotEmpty, true);
      }
    });

    test('Supported languages include 30 languages plus dialects', () {
      expect(SupportedLanguages.list.length, greaterThanOrEqualTo(30));
      expect(SupportedLanguages.list.any((l) => l.code == 'en'), true);
      expect(SupportedLanguages.list.any((l) => l.code == 'zh'), true);
      expect(SupportedLanguages.list.any((l) => l.code == 'hi'), true);
    });

    test('TTSRequest serializes properly into JSON matching API schema', () {
      final req = TTSRequest(
        text: "Test synthesis",
        controlInstruction: "Calm and steady",
        mode: "design",
        cfgValue: 2.5,
        inferenceTimesteps: 12,
      );
      final json = req.toJson();
      expect(json['text'], "Test synthesis");
      expect(json['control_instruction'], "Calm and steady");
      expect(json['cfg_value'], 2.5);
      expect(json['inference_timesteps'], 12);
    });
  });
}
