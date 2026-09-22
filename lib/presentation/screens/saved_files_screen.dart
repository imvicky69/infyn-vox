import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/generation_result.dart';
import '../../data/services/audio_service.dart';
import '../../data/services/tts_api_service.dart';

class SavedFilesScreen extends StatefulWidget {
  final AudioService audioService;
  final TTSApiService apiService;
  final List<GenerationResult> savedResults;
  final VoidCallback onClearAll;
  final Function(String id) onDeleteResult;

  const SavedFilesScreen({
    super.key,
    required this.audioService,
    required this.apiService,
    required this.savedResults,
    required this.onClearAll,
    required this.onDeleteResult,
  });

  @override
  State<SavedFilesScreen> createState() => _SavedFilesScreenState();
}

class _SavedFilesScreenState extends State<SavedFilesScreen> {
  String _searchQuery = "";
  bool _isBatchExporting = false;

  String _formatDuration(double seconds) {
    final s = seconds.toInt();
    final m = s ~/ 60;
    final sec = s % 60;
    final ms = ((seconds - s) * 10).toInt();
    return "$m:${sec.toString().padLeft(2, '0')}.$ms";
  }

  Future<void> _handleExportAll() async {
    if (widget.savedResults.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No recordings available to export.")),
      );
      return;
    }

    final selectedDir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: "Choose Folder to Export All Recordings",
    );

    if (selectedDir == null) return;

    setState(() => _isBatchExporting = true);

    try {
      int successCount = 0;
      final manifestLines = <String>[
        "# infyn Vox - Export Manifest",
        "# Exported: ${DateTime.now().toIso8601String()}",
        "# Total Tracks: ${widget.savedResults.length}",
        "",
      ];

      for (int i = 0; i < widget.savedResults.length; i++) {
        final item = widget.savedResults[i];
        final src = File(item.audioPath);
        if (await src.exists()) {
          final cleanVoice = (item.voiceName ?? "Voice").replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
          final targetFilename = "${(i + 1).toString().padLeft(2, '0')}_${cleanVoice}_${item.id.substring(0, 6)}.wav";
          final destPath = "$selectedDir/$targetFilename";
          await src.copy(destPath);
          successCount++;

          manifestLines.add("[$targetFilename] | Duration: ${_formatDuration(item.duration)} | Voice: ${item.voiceName ?? 'Default'}");
          manifestLines.add("Text: ${item.text}");
          manifestLines.add("");
        }
      }

      // Write manifest
      final manifestFile = File("$selectedDir/export_manifest.txt");
      await manifestFile.writeAsString(manifestLines.join("\n"));

      if (mounted) {
        setState(() => _isBatchExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.success,
            content: Text("Batch exported $successCount tracks to: $selectedDir"),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isBatchExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.error,
            content: Text("Export failed: $e"),
          ),
        );
      }
    }
  }

  Future<void> _exportSingle(GenerationResult item) async {
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: "Export Track",
      fileName: "vox_${item.id.substring(0, 8)}.wav",
      type: FileType.custom,
      allowedExtensions: ['wav'],
    );

    if (savePath != null) {
      await File(item.audioPath).copy(savePath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.primary,
            content: Text("Exported track to $savePath"),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.savedResults.where((r) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final textMatches = r.text.toLowerCase().contains(q);
      final voiceMatches = (r.voiceName ?? "").toLowerCase().contains(q);
      return textMatches || voiceMatches;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                ),
                child: const Icon(Icons.folder_copy_outlined, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Recordings Library",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.text(context),
                    ),
                  ),
                  Text(
                    "${widget.savedResults.length} tracks synthesized • Preserved locally for export",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSub(context),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Search Input
              SizedBox(
                width: 220,
                height: 36,
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: TextStyle(fontSize: 12, color: AppTheme.text(context)),
                  decoration: InputDecoration(
                    hintText: "Search transcript...",
                    hintStyle: TextStyle(fontSize: 12, color: AppTheme.textSub(context)),
                    prefixIcon: Icon(Icons.search, size: 16, color: AppTheme.textSub(context)),
                    filled: true,
                    fillColor: AppTheme.cardLight(context),
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppTheme.border(context)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppTheme.border(context)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.primary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Export All Button
              ElevatedButton.icon(
                onPressed: _isBatchExporting || widget.savedResults.isEmpty ? null : _handleExportAll,
                icon: _isBatchExporting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.download, size: 16),
                label: Text(
                  _isBatchExporting ? "Exporting..." : "Export All (${widget.savedResults.length})",
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 8),
              // Clear All Button
              if (widget.savedResults.isNotEmpty)
                IconButton(
                  tooltip: "Clear All History",
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppTheme.cardBg(context),
                        title: Text("Clear Library?", style: TextStyle(color: AppTheme.text(context))),
                        content: Text(
                          "This removes all tracks from the current library view. Underlying audio files in output folder will remain.",
                          style: TextStyle(color: AppTheme.textSub(context), fontSize: 13),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text("Cancel"),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              widget.onClearAll();
                              setState(() {});
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.error,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text("Clear All"),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: Icon(Icons.delete_outline, size: 18, color: AppTheme.textSub(context)),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Content List / Empty State
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.audio_file_outlined,
                          size: 48,
                          color: AppTheme.textSub(context).withOpacity(0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.savedResults.isEmpty
                              ? "No Saved Recordings Yet"
                              : "No matches for '$_searchQuery'",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.text(context),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Synthesize speech in the Studio or Long-Form tab to auto-save recordings here.",
                          style: TextStyle(fontSize: 12, color: AppTheme.textSub(context)),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final item = filtered[idx];
                      final isPlaying = widget.audioService.currentAudioPath == item.audioPath;
                      final timeStr = DateFormat('h:mm a • MMM d').format(item.createdAt);

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg(context),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isPlaying ? AppTheme.primary : AppTheme.border(context),
                            width: isPlaying ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Play Button
                            InkWell(
                              onTap: () async {
                                if (isPlaying) {
                                  await widget.audioService.pause();
                                } else {
                                  await widget.audioService.loadAudio(item.audioPath);
                                  await widget.audioService.play();
                                }
                                setState(() {});
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isPlaying ? AppTheme.primary : AppTheme.primary.withOpacity(0.12),
                                ),
                                child: Icon(
                                  isPlaying ? Icons.pause : Icons.play_arrow,
                                  size: 18,
                                  color: isPlaying ? Colors.white : AppTheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Track Info & Text Snippet
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        item.voiceName ?? "VoxCPM Voice",
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.text(context),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: AppTheme.cardLight(context),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          "48kHz WAV",
                                          style: TextStyle(fontSize: 9, color: AppTheme.primary, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        timeStr,
                                        style: TextStyle(fontSize: 11, color: AppTheme.textSub(context)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.text,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.4,
                                      color: AppTheme.textSub(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 16),

                            // Duration Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.cardLight(context),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _formatDuration(item.duration),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.text(context),
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Single Export Button
                            IconButton(
                              tooltip: "Save File As...",
                              icon: const Icon(Icons.file_download_outlined, size: 18),
                              color: AppTheme.textSub(context),
                              onPressed: () => _exportSingle(item),
                            ),

                            // Delete Button
                            IconButton(
                              tooltip: "Remove from list",
                              icon: const Icon(Icons.close, size: 16),
                              color: AppTheme.textSub(context),
                              onPressed: () {
                                widget.onDeleteResult(item.id);
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
