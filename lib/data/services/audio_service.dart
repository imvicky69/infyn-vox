import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  
  String? _currentAudioPath;
  List<double> _currentWaveform = [];
  
  Stream<Duration> get onPositionChanged => _player.onPositionChanged;
  Stream<Duration> get onDurationChanged => _player.onDurationChanged;
  Stream<PlayerState> get onPlayerStateChanged => _player.onPlayerStateChanged;

  String? get currentAudioPath => _currentAudioPath;
  List<double> get currentWaveform => _currentWaveform;

  AudioService() {
    _player.setReleaseMode(ReleaseMode.stop);
  }

  Future<void> loadAudio(String path) async {
    _currentAudioPath = path;
    _currentWaveform = await _extractWaveformPeaks(path, peakCount: 80);
    await _player.setSource(DeviceFileSource(path));
  }

  Future<void> play() async {
    if (_currentAudioPath != null) {
      await _player.resume();
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> setPlaybackRate(double rate) async {
    await _player.setPlaybackRate(rate);
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }

  Future<void> dispose() async {
    await _player.dispose();
  }

  /// Extracts normalized amplitude peaks from a local WAV file for waveform rendering.
  Future<List<double>> _extractWaveformPeaks(String filePath, {int peakCount = 80}) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return _generateSyntheticPeaks(peakCount);

      final bytes = await file.readAsBytes();
      if (bytes.length < 44) return _generateSyntheticPeaks(peakCount);

      // Skip 44-byte standard WAV header
      final pcmBytes = bytes.sublist(44);
      final totalSamples = pcmBytes.length ~/ 2; // Assuming 16-bit PCM
      if (totalSamples < peakCount) return _generateSyntheticPeaks(peakCount);

      final blockSize = totalSamples ~/ peakCount;
      final peaks = <double>[];
      final byteData = ByteData.sublistView(pcmBytes);

      for (int i = 0; i < peakCount; i++) {
        double maxAmp = 0;
        final start = i * blockSize;
        final end = min(start + blockSize, totalSamples);
        for (int j = start; j < end; j += 4) { // sample step
          final sample = byteData.getInt16(j * 2, Endian.little).abs();
          if (sample > maxAmp) {
            maxAmp = sample.toDouble();
          }
        }
        // Normalize 16-bit PCM range (0..32767) to 0.1..1.0
        final normalized = (maxAmp / 32768.0).clamp(0.08, 1.0);
        peaks.add(normalized);
      }
      return peaks;
    } catch (_) {
      return _generateSyntheticPeaks(peakCount);
    }
  }

  List<double> _generateSyntheticPeaks(int count) {
    final rand = Random();
    return List.generate(count, (i) {
      final t = i / count;
      final curve = sin(t * pi) * 0.7 + 0.2;
      return (curve + rand.nextDouble() * 0.15).clamp(0.1, 1.0);
    });
  }
}
