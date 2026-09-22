import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/audio_service.dart';
import '../../data/services/tts_api_service.dart';
import 'waveform_visualizer.dart';

class StudioDock extends StatefulWidget {
  final AudioService audioService;
  final TTSApiService? apiService;
  final String? trackTitle;
  final String? subtitle;
  final VoidCallback? onExport;

  const StudioDock({
    super.key,
    required this.audioService,
    this.apiService,
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

  bool _isExporting = false;

  Future<void> _handleExport(String format) async {
    final path = widget.audioService.currentAudioPath;
    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No generated audio to export.")),
      );
      return;
    }

    final ext = format.toLowerCase().trim();
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: "Export Audio as ${ext.toUpperCase()}",
      fileName: "voxcpm_speech.$ext",
      type: FileType.custom,
      allowedExtensions: [ext],
    );

    if (savePath == null) return;

    setState(() => _isExporting = true);

    try {
      if (ext == 'wav') {
        final source = File(path);
        await source.copy(savePath);
      } else {
        final api = widget.apiService ?? TTSApiService();
        final bytes = await api.convertAudio(path, ext);
        await File(savePath).writeAsBytes(bytes);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.cardLight(context),
            content: Text("Exported ${ext.toUpperCase()} successfully to $savePath", style: TextStyle(color: AppTheme.text(context))),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.accent,
            content: Text("Export failed: $e"),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
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
        color: AppTheme.cardBg(context),
        border: Border(top: BorderSide(color: AppTheme.border(context), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(AppTheme.isDark(context) ? 0.35 : 0.06),
            blurRadius: 16,
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
                    color: AppTheme.cardLight(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border(context)),
                  ),
                  child: const Center(
                    child: Icon(Icons.music_note, color: AppTheme.primary, size: 22),
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
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.text(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              "48 kHz",
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primary),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              widget.subtitle ?? "Studio Quality",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: AppTheme.textSub(context)),
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
                          color: hasAudio ? AppTheme.primary : AppTheme.cardLight(context),
                          shape: BoxShape.circle,
                          boxShadow: hasAudio
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primary.withOpacity(0.35),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: hasAudio ? Colors.white : AppTheme.textSub(context),
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Timestamp
                    Text(
                      _formatDuration(_position),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: AppTheme.textSub(context),
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
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: AppTheme.textSub(context),
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
                color: AppTheme.cardBg(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: AppTheme.border(context)),
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
                    color: AppTheme.cardLight(context),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.border(context)),
                  ),
                  child: Text(
                    "${_playbackSpeed}x",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.text(context)),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Volume Icon & Slider
              Icon(Icons.volume_up, size: 18, color: AppTheme.textSub(context)),
              SizedBox(
                width: 70,
                child: Slider(
                  value: _volume,
                  activeColor: AppTheme.primary,
                  onChanged: (val) {
                    setState(() => _volume = val);
                    widget.audioService.setVolume(val);
                  },
                ),
              ),

              const SizedBox(width: 10),

              // Multi-format Export Split Button
              Container(
                decoration: BoxDecoration(
                  color: hasAudio ? AppTheme.primary : AppTheme.cardLight(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: (hasAudio && !_isExporting) ? () => _handleExport('mp3') : null,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isExporting)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            else
                              Icon(Icons.download, size: 16, color: hasAudio ? Colors.white : AppTheme.textSub(context)),
                            const SizedBox(width: 6),
                            Text(
                              _isExporting ? "Converting..." : "Export MP3",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: hasAudio ? Colors.white : AppTheme.textSub(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 22,
                      color: hasAudio ? Colors.white.withOpacity(0.2) : AppTheme.border(context),
                    ),
                    PopupMenuButton<String>(
                      enabled: hasAudio && !_isExporting,
                      tooltip: "More Export Formats",
                      color: AppTheme.cardBg(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: AppTheme.border(context)),
                      ),
                      onSelected: (fmt) => _handleExport(fmt),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: "mp3",
                          child: Row(
                            children: [
                              Icon(Icons.music_note, size: 16, color: AppTheme.primary),
                              SizedBox(width: 8),
                              Text("MP3 (Universal format)"),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: "wav",
                          child: Row(
                            children: [
                              Icon(Icons.graphic_eq, size: 16, color: AppTheme.primary),
                              SizedBox(width: 8),
                              Text("WAV (48kHz Lossless Studio)"),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: "flac",
                          child: Row(
                            children: [
                              Icon(Icons.album, size: 16, color: AppTheme.primary),
                              SizedBox(width: 8),
                              Text("FLAC (Lossless compressed)"),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: "ogg",
                          child: Row(
                            children: [
                              Icon(Icons.podcasts, size: 16, color: AppTheme.primary),
                              SizedBox(width: 8),
                              Text("OGG (Vorbis audio)"),
                            ],
                          ),
                        ),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                        child: Icon(
                          Icons.arrow_drop_down,
                          color: hasAudio ? Colors.white : AppTheme.textSub(context),
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
