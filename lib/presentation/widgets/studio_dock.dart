import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/audio_service.dart';
import 'waveform_visualizer.dart';

class StudioDock extends StatefulWidget {
  final AudioService audioService;
  final String? trackTitle;
  final String? subtitle;
  final VoidCallback? onExport;

  const StudioDock({
    super.key,
    required this.audioService,
    this.trackTitle,
    this.subtitle,
    this.onExport,
  });

  @override
  State<StudioDock> createState() => _StudioDockState();
}

class _StudioDockState extends State<StudioDock> {
  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _playbackSpeed = 1.0;
  double _volume = 1.0;

  @override
  void initState() {
    super.initState();
    widget.audioService.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _playerState = s);
    });
    widget.audioService.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    widget.audioService.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final ms = (d.inMilliseconds.remainder(1000) ~/ 100).toString();
    return "$minutes:$seconds.$ms";
  }

  Future<void> _handleSaveAs() async {
    final path = widget.audioService.currentAudioPath;
    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No generated audio to export.")),
      );
      return;
    }

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: "Save 48kHz WAV Audio",
      fileName: "voxcpm_audio_48khz.wav",
      type: FileType.custom,
      allowedExtensions: ['wav'],
    );

    if (savePath != null) {
      final source = File(path);
      await source.copy(savePath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.surfaceLight,
            content: Text("Exported audio successfully to $savePath"),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAudio = widget.audioService.currentAudioPath != null;
    final isPlaying = _playerState == PlayerState.playing;

    return Container(
      height: 96,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(top: BorderSide(color: AppTheme.surfaceBorder, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Track Info
          SizedBox(
            width: 220,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.surfaceBorder),
                  ),
                  child: const Center(
                    child: Icon(Icons.music_note, color: AppTheme.secondary, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.trackTitle ?? "No Audio Generated",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppTheme.secondary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              "48 kHz",
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.secondary),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              widget.subtitle ?? "Studio Quality",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          // Center Controls & Scrubbable Waveform
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    // Play/Pause Button
                    GestureDetector(
                      onTap: hasAudio
                          ? () => isPlaying ? widget.audioService.pause() : widget.audioService.play()
                          : null,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: hasAudio
                              ? const LinearGradient(colors: [AppTheme.primary, AppTheme.secondary])
                              : null,
                          color: hasAudio ? null : AppTheme.surfaceLight,
                          shape: BoxShape.circle,
                          boxShadow: hasAudio
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primary.withOpacity(0.4),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: hasAudio ? Colors.white : AppTheme.textMuted,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Timestamp
                    Text(
                      _formatDuration(_position),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Waveform
                    Expanded(
                      child: WaveformVisualizer(
                        peaks: widget.audioService.currentWaveform,
                        currentPosition: _position,
                        totalDuration: _duration,
                        height: 38,
                        onSeek: (target) => widget.audioService.seek(target),
                      ),
                    ),

                    const SizedBox(width: 10),
                    Text(
                      _formatDuration(_duration),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          // Right Tools: Speed, Volume, Export
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Speed selector
              PopupMenuButton<double>(
                initialValue: _playbackSpeed,
                tooltip: "Playback Speed",
                color: AppTheme.surfaceLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppTheme.surfaceBorder),
                ),
                onSelected: (val) {
                  setState(() => _playbackSpeed = val);
                  widget.audioService.setPlaybackRate(val);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 0.75, child: Text("0.75x")),
                  const PopupMenuItem(value: 1.0, child: Text("1.0x (Normal)")),
                  const PopupMenuItem(value: 1.25, child: Text("1.25x")),
                  const PopupMenuItem(value: 1.5, child: Text("1.5x")),
                  const PopupMenuItem(value: 2.0, child: Text("2.0x")),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.surfaceBorder),
                  ),
                  child: Text(
                    "${_playbackSpeed}x",
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Volume Icon & Slider
              const Icon(Icons.volume_up, size: 18, color: AppTheme.textSecondary),
              SizedBox(
                width: 70,
                child: Slider(
                  value: _volume,
                  onChanged: (val) {
                    setState(() => _volume = val);
                    widget.audioService.setVolume(val);
                  },
                ),
              ),

              const SizedBox(width: 10),

              // Export Button
              ElevatedButton.icon(
                onPressed: hasAudio ? _handleSaveAs : null,
                icon: const Icon(Icons.download, size: 16),
                label: const Text("Export WAV", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
