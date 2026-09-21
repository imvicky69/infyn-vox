import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/presets.dart';
import '../../data/models/voice_persona.dart';
import '../../data/models/text_segment.dart';
import '../../data/models/tts_request.dart';
import '../../data/services/tts_api_service.dart';
import '../../data/services/segmenter_service.dart';
import '../../data/services/audio_service.dart';

class SegmenterScreen extends StatefulWidget {
  final TTSApiService apiService;
  final AudioService audioService;
  final List<VoicePersona> userPersonas;

  const SegmenterScreen({
    super.key,
    required this.apiService,
    required this.audioService,
    required this.userPersonas,
  });

  @override
  State<SegmenterScreen> createState() => _SegmenterScreenState();
}

class _SegmenterScreenState extends State<SegmenterScreen> {
  final _inputController = TextEditingController(
    text: "Welcome to VoxStudio's Long-Form Speech Synthesizer. In large language audio models, generating very long continuous text often leads to acoustic drift or prosodic degradation.\n\nTo overcome this limitation, our Smart Segmenter breaks down articles, stories, or podcast scripts into semantic sentences. Each segment is synthesized individually with consistent acoustic embeddings.\n\nFinally, all high-resolution 48kHz audio chunks are seamlessly stitched together with natural pause intervals, and an aligned SRT subtitle file is generated automatically.",
  );

  final SegmenterService _segmenterService = SegmenterService();
  List<TextSegment> _segments = [];
  late VoicePersona _selectedVoice;
  bool _isGeneratingAll = false;
  int _currentIndex = 0;
  String? _masterAudioPath;

  @override
  void initState() {
    super.initState();
    _selectedVoice = DefaultPresets.presets.first;
    _handleSegmentScript();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _handleSegmentScript() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _segments = _segmenterService.splitText(text, maxWordsPerSegment: 22);
      _masterAudioPath = null;
    });
  }

  Future<void> _generateSegment(TextSegment seg) async {
    setState(() => seg.status = SegmentStatus.generating);
    try {
      final req = TTSRequest(
        text: seg.text,
        controlInstruction: _selectedVoice.controlInstruction,
        mode: _selectedVoice.promptText != null ? 'ultimate' : 'design',
        cfgValue: 2.0,
        inferenceTimesteps: 10,
        language: _selectedVoice.language,
      );

      final result = await widget.apiService.generateSpeech(req);
      setState(() {
        seg.status = SegmentStatus.ready;
        seg.audioPath = result.audioPath;
        seg.duration = result.duration;
      });
    } catch (e) {
      setState(() {
        seg.status = SegmentStatus.failed;
        seg.errorMessage = e.toString();
      });
    }
  }

  Future<void> _generateAllSegments() async {
    if (_segments.isEmpty) return;
    setState(() {
      _isGeneratingAll = true;
      _currentIndex = 0;
    });

    for (int i = 0; i < _segments.length; i++) {
      if (!mounted) break;
      setState(() => _currentIndex = i);
      await _generateSegment(_segments[i]);
    }

    if (mounted) {
      setState(() => _isGeneratingAll = false);
    }
  }

  Future<void> _stitchAndExport() async {
    final readyPaths = _segments
        .where((s) => s.status == SegmentStatus.ready && s.audioPath != null)
        .map((s) => s.audioPath!)
        .toList();

    if (readyPaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Generate segments first before stitching.")),
      );
      return;
    }

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: "Save Master 48kHz Stitched Audio",
      fileName: "voxcpm_master_stitched.wav",
      type: FileType.custom,
      allowedExtensions: ['wav'],
    );

    if (savePath != null) {
      final outPath = await _segmenterService.stitchSegments(readyPaths, savePath, pauseMs: 350);
      
      // Also export SRT subtitles
      final srtContent = _segmenterService.generateSrt(_segments);
      final srtPath = savePath.replaceAll(RegExp(r'\.wav$', caseSensitive: false), '.srt');
      await File(srtPath).writeAsString(srtContent);

      setState(() => _masterAudioPath = outPath);
      await widget.audioService.loadAudio(outPath);
      await widget.audioService.play();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.surfaceLight,
            content: Text("Master audio and subtitles exported to:\n$outPath\n$srtPath"),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final readyCount = _segments.where((s) => s.status == SegmentStatus.ready).length;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          // Left: Input Long-Form Script
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.segment, color: AppTheme.primary, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      "Long-Form Script Input",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _handleSegmentScript,
                      icon: const Icon(Icons.auto_awesome, size: 14),
                      label: const Text("Segment Script", style: TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.surfaceLight,
                        foregroundColor: AppTheme.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.glassCard(),
                    child: TextField(
                      controller: _inputController,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(fontSize: 13, height: 1.6, color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        hintText: "Paste your article or script here...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          // Right: Segments Queue & Stitch Controls
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "Segments (${_segments.length} chunks • $readyCount ready)",
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const Spacer(),
                    // Batch Generate Button
                    ElevatedButton.icon(
                      onPressed: _isGeneratingAll || _segments.isEmpty ? null : _generateAllSegments,
                      icon: _isGeneratingAll
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.play_circle_outline, size: 16),
                      label: Text(
                        _isGeneratingAll ? "Generating ${_currentIndex + 1}/${_segments.length}..." : "Generate All",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Stitch & Export Button
                    ElevatedButton.icon(
                      onPressed: readyCount > 0 ? _stitchAndExport : null,
                      icon: const Icon(Icons.merge, size: 16),
                      label: const Text("Stitch & Export", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondary,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_masterAudioPath != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, size: 16, color: AppTheme.success),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Master 48kHz audio stitched & loaded in dock player: ${File(_masterAudioPath!).uri.pathSegments.last}",
                            style: const TextStyle(fontSize: 11, color: AppTheme.success),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 4),

                // Segments List View
                Expanded(
                  child: _segments.isEmpty
                      ? Center(
                          child: Text(
                            "No segments. Paste text on the left and click 'Segment Script'.",
                            style: TextStyle(color: AppTheme.textMuted),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _segments.length,
                          itemBuilder: (context, index) {
                            final seg = _segments[index];
                            return _buildSegmentCard(seg, index);
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentCard(TextSegment seg, int index) {
    Color statusColor = AppTheme.textMuted;
    String statusLabel = "Pending";
    if (seg.status == SegmentStatus.generating) {
      statusColor = AppTheme.warning;
      statusLabel = "Synthesizing...";
    } else if (seg.status == SegmentStatus.ready) {
      statusColor = AppTheme.success;
      statusLabel = "${seg.duration?.toStringAsFixed(1)}s Ready";
    } else if (seg.status == SegmentStatus.failed) {
      statusColor = AppTheme.accent;
      statusLabel = "Error";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: seg.status == SegmentStatus.generating 
              ? AppTheme.primary 
              : AppTheme.surfaceBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "#${index + 1}",
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
              ),
              const SizedBox(width: 6),
              Text(
                statusLabel,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: statusColor),
              ),
              const Spacer(),
              if (seg.status == SegmentStatus.ready && seg.audioPath != null) ...[
                IconButton(
                  icon: const Icon(Icons.play_arrow, size: 18, color: AppTheme.secondary),
                  onPressed: () => widget.audioService.loadAudio(seg.audioPath!).then((_) => widget.audioService.play()),
                  tooltip: "Preview Segment",
                ),
              ],
              IconButton(
                icon: const Icon(Icons.refresh, size: 16, color: AppTheme.textMuted),
                onPressed: () => _generateSegment(seg),
                tooltip: "Re-synthesize this chunk",
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            seg.text,
            style: const TextStyle(fontSize: 13, height: 1.4, color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }
}
