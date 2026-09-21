import 'dart:io';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import '../models/text_segment.dart';

class SegmenterService {
  /// Splits long text into cohesive sentences or clauses, keeping sentences intact.
  List<TextSegment> splitText(String fullText, {int maxWordsPerSegment = 25}) {
    if (fullText.trim().isEmpty) return [];

    // Regex splitting on standard sentence terminators (. ! ? 。 ！ ？ \n)
    final sentencePattern = RegExp(r'[^.!?。\n!?]+[.!?。\n!?]*');
    final matches = sentencePattern.allMatches(fullText);
    
    final segments = <TextSegment>[];
    String currentChunk = "";
    int segmentIndex = 0;

    for (final match in matches) {
      final sentence = match.group(0)?.trim() ?? "";
      if (sentence.isEmpty) continue;

      final wordsInCurrent = currentChunk.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
      final wordsInSentence = sentence.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

      if (wordsInCurrent + wordsInSentence > maxWordsPerSegment && currentChunk.isNotEmpty) {
        segments.add(TextSegment(
          id: const Uuid().v4(),
          index: segmentIndex++,
          text: currentChunk.trim(),
        ));
        currentChunk = sentence;
      } else {
        currentChunk = currentChunk.isEmpty ? sentence : "$currentChunk $sentence";
      }
    }

    if (currentChunk.isNotEmpty) {
      segments.add(TextSegment(
        id: const Uuid().v4(),
        index: segmentIndex++,
        text: currentChunk.trim(),
      ));
    }

    return segments;
  }

  /// Stitches multiple 16-bit 48kHz WAV audio files into a single master WAV with customizable silence padding.
  Future<String> stitchSegments(
    List<String> wavPaths,
    String outputPath, {
    int pauseMs = 350,
    int sampleRate = 48000,
    int channels = 1,
  }) async {
    final combinedPcm = BytesBuilder();
    final pauseSampleCount = (sampleRate * (pauseMs / 1000.0)).toInt() * channels * 2;
    final pauseBytes = Uint8List(pauseSampleCount); // Silence is 0s

    for (int i = 0; i < wavPaths.length; i++) {
      final file = File(wavPaths[i]);
      if (!await file.exists()) continue;

      final bytes = await file.readAsBytes();
      if (bytes.length > 44) {
        // Append raw PCM data after standard 44-byte WAV header
        combinedPcm.add(bytes.sublist(44));
        // Append silence between segments (not after last segment)
        if (i < wavPaths.length - 1) {
          combinedPcm.add(pauseBytes);
        }
      }
    }

    final pcmData = combinedPcm.takeBytes();
    final header = _createWavHeader(pcmData.length, sampleRate: sampleRate, channels: channels);

    final outputFile = File(outputPath);
    final outputBuilder = BytesBuilder();
    outputBuilder.add(header);
    outputBuilder.add(pcmData);

    await outputFile.writeAsBytes(outputBuilder.takeBytes());
    return outputPath;
  }

  Uint8List _createWavHeader(int pcmLength, {int sampleRate = 48000, int channels = 1}) {
    final byteRate = sampleRate * channels * 2; // 16-bit
    final blockAlign = channels * 2;
    final totalDataLen = pcmLength + 36;

    final header = ByteData(44);
    // "RIFF"
    header.setUint8(0, 0x52); header.setUint8(1, 0x49); header.setUint8(2, 0x46); header.setUint8(3, 0x46);
    header.setUint32(4, totalDataLen, Endian.little);
    // "WAVE"
    header.setUint8(8, 0x57); header.setUint8(9, 0x41); header.setUint8(10, 0x56); header.setUint8(11, 0x45);
    // "fmt "
    header.setUint8(12, 0x66); header.setUint8(13, 0x6D); header.setUint8(14, 0x74); header.setUint8(15, 0x20);
    header.setUint32(16, 16, Endian.little); // subchunk1 size
    header.setUint16(20, 1, Endian.little);  // PCM format = 1
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, 16, Endian.little); // 16 bits per sample
    // "data"
    header.setUint8(36, 0x64); header.setUint8(37, 0x61); header.setUint8(38, 0x74); header.setUint8(39, 0x61);
    header.setUint32(40, pcmLength, Endian.little);

    return header.buffer.asUint8List();
  }

  /// Exports segments with duration into standard SubRip (.srt) subtitle file.
  String generateSrt(List<TextSegment> segments) {
    final srt = StringBuffer();
    double currentTime = 0.0;

    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final dur = seg.duration ?? 2.0;
      final startTime = currentTime;
      final endTime = currentTime + dur;

      srt.writeln("${i + 1}");
      srt.writeln("${_formatSrtTime(startTime)} --> ${_formatSrtTime(endTime)}");
      srt.writeln(seg.text);
      srt.writeln();

      currentTime = endTime + (seg.pauseAfterMs / 1000.0);
    }

    return srt.toString();
  }

  String _formatSrtTime(double seconds) {
    final h = (seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds.toInt() % 60).toString().padLeft(2, '0');
    final ms = ((seconds * 1000).toInt() % 1000).toString().padLeft(3, '0');
    return "$h:$m:$s,$ms";
  }
}
