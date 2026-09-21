import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/languages.dart';
import '../../core/constants/presets.dart';
import '../../data/models/voice_persona.dart';
import '../../data/models/tts_request.dart';
import '../../data/models/generation_result.dart';
import '../../data/services/tts_api_service.dart';
import '../../data/services/audio_service.dart';
import '../widgets/clone_modal.dart';

class StudioScreen extends StatefulWidget {
  final TTSApiService apiService;
  final AudioService audioService;
  final Function(GenerationResult) onAudioGenerated;
  final List<VoicePersona> userPersonas;
  final Function(VoicePersona) onAddPersona;

  const StudioScreen({
    super.key,
    required this.apiService,
    required this.audioService,
    required this.onAudioGenerated,
    required this.userPersonas,
    required this.onAddPersona,
  });

  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends State<StudioScreen> {
  final _textController = TextEditingController(
    text: "VoxCPM2 is a tokenizer-free Text-to-Speech system that directly generates continuous speech representations. It supports 30 languages, creative voice design, and true-to-life voice cloning at 48kHz studio quality.",
  );

  late VoicePersona _selectedPersona;
  String _selectedLanguageCode = "auto";
  double _cfgValue = 2.0;
  int _inferenceTimesteps = 10;
  bool _randomSeed = true;
  final int _manualSeed = 42;
  bool _denoise = false;
  bool _normalize = true;

  bool _isGenerating = false;
  String? _lastError;
  GenerationResult? _lastResult;

  @override
  void initState() {
    super.initState();
    _selectedPersona = DefaultPresets.presets.first;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  int get _wordCount => _textController.text.trim().isEmpty 
      ? 0 
      : _textController.text.trim().split(RegExp(r'\s+')).length;

  int get _charCount => _textController.text.length;

  String get _estimatedDuration {
    final seconds = (_wordCount * 0.42).round();
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return m > 0 ? "${m}m ${s}s" : "${s}s";
  }

  Future<void> _handleSynthesize() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isGenerating = true;
      _lastError = null;
    });

    try {
      final req = TTSRequest(
        text: text,
        controlInstruction: _selectedPersona.controlInstruction.isNotEmpty 
            ? _selectedPersona.controlInstruction 
            : null,
        mode: _selectedPersona.promptText != null 
            ? 'ultimate' 
            : (_selectedPersona.referenceAudioPath != null ? 'controllable' : 'design'),
        referenceAudioPath: _selectedPersona.referenceAudioPath,
        promptText: _selectedPersona.promptText,
        cfgValue: _cfgValue,
        inferenceTimesteps: _inferenceTimesteps,
        seed: _randomSeed ? Random().nextInt(100000) : _manualSeed,
        denoise: _denoise,
        normalize: _normalize,
      );

      final result = await widget.apiService.generateSpeech(req, voiceName: _selectedPersona.name);
      
      if (mounted) {
        setState(() {
          _lastResult = result;
          _isGenerating = false;
        });
        widget.onAudioGenerated(result);
        await widget.audioService.loadAudio(result.audioPath);
        await widget.audioService.play();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _lastError = e.toString();
        });
      }
    }
  }

  void _loadSampleText() {
    setState(() {
      _textController.text = "Welcome to VoxStudio PC. Experience pristine 48kHz speech synthesis with fluid prosody, true-to-life emotion, and seamless multilingual generation across thirty global languages.";
    });
  }

  @override
  Widget build(BuildContext context) {
    final allPersonas = [...DefaultPresets.presets, ...widget.userPersonas];

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column: Script Editor & Stats
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Toolbar Header
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Language Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.surfaceBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedLanguageCode,
                            dropdownColor: AppTheme.surfaceLight,
                            items: SupportedLanguages.list.map((lang) {
                              return DropdownMenuItem(
                                value: lang.code,
                                child: Text(
                                  "${lang.flag}  ${lang.name}",
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedLanguageCode = val);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Quick Stats Pills
                      _buildStatPill(Icons.short_text, "$_wordCount words"),
                      const SizedBox(width: 8),
                      _buildStatPill(Icons.text_fields, "$_charCount chars"),
                      const SizedBox(width: 8),
                      _buildStatPill(Icons.timer_outlined, "~$_estimatedDuration reading"),

                      const SizedBox(width: 24),

                      // Action Buttons
                      TextButton.icon(
                        onPressed: _loadSampleText,
                        icon: const Icon(Icons.auto_awesome, size: 14, color: AppTheme.secondary),
                        label: const Text("Sample", style: TextStyle(fontSize: 12, color: AppTheme.secondary)),
                      ),
                      TextButton.icon(
                        onPressed: () => _textController.clear(),
                        icon: const Icon(Icons.clear_all, size: 14, color: AppTheme.textMuted),
                        label: const Text("Clear", style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Main Script Input Box
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.glassCard(),
                    child: TextField(
                      controller: _textController,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: AppTheme.textPrimary,
                        letterSpacing: 0.2,
                      ),
                      decoration: const InputDecoration(
                        hintText: "Enter or paste your text to synthesize with VoxCPM2...\n\nPro-tip: For voice design mode, you can also prepend descriptions like:\n(Young woman, gentle and sweet voice) Hello world!",
                        hintStyle: TextStyle(fontSize: 14, color: AppTheme.textMuted),
                        border: InputBorder.none,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Generation Status & Action Button Bar
                Row(
                  children: [
                    if (_lastResult != null) ...[
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.surfaceBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.speed, size: 14, color: AppTheme.success),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  "RTF: ${_lastResult!.rtf.toStringAsFixed(2)}x  •  ${_lastResult!.duration.toStringAsFixed(1)}s audio  •  ${_lastResult!.sampleRate}Hz",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (_lastError != null) ...[
                      Expanded(
                        child: Text(
                          _lastError!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: AppTheme.accent),
                        ),
                      ),
                    ],
                    const Spacer(),

                    // Primary Synthesize Button
                    ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _handleSynthesize,
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.graphic_eq, size: 18),
                      label: Text(
                        _isGenerating ? "Synthesizing 48kHz Audio..." : "Synthesize 48kHz Audio",
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 6,
                        shadowColor: AppTheme.primary.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          // Right Column: Voice Persona & Hyperparameters Inspector
          SizedBox(
            width: 320,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selected Voice Persona Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.glassCard(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.surfaceBorder),
                              ),
                              child: Center(
                                child: Text(_selectedPersona.avatar, style: const TextStyle(fontSize: 22)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedPersona.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _selectedPersona.tags.join(" • "),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Voice Instruction preview
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _selectedPersona.controlInstruction.isNotEmpty
                                ? _selectedPersona.controlInstruction
                                : "Standard voice synthesis mode",
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Change Voice / Clone Button
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showVoicePicker(allPersonas),
                                icon: const Icon(Icons.people_outline, size: 14),
                                label: const Text("Change Voice", style: TextStyle(fontSize: 11)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.textPrimary,
                                  side: const BorderSide(color: AppTheme.surfaceBorder),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: "Clone or Design New Voice",
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => CloneModal(
                                    apiService: widget.apiService,
                                    onPersonaCreated: (newPersona) {
                                      widget.onAddPersona(newPersona);
                                      setState(() => _selectedPersona = newPersona);
                                    },
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add, size: 18, color: AppTheme.secondary),
                              style: IconButton.styleFrom(
                                backgroundColor: AppTheme.surfaceLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Diffusion Hyperparameters Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.glassCard(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "LocDiT Flow-Matching Settings",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 14),

                        // CFG Guidance Slider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("CFG Guidance Scale", style: TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
                            Text(_cfgValue.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.secondary)),
                          ],
                        ),
                        Slider(
                          value: _cfgValue,
                          min: 1.0,
                          max: 4.0,
                          divisions: 30,
                          onChanged: (val) => setState(() => _cfgValue = val),
                        ),
                        const Text(
                          "Higher = strictly adheres to prompt/reference. Lower = more creative variation.",
                          style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                        ),

                        const SizedBox(height: 14),

                        // Inference Steps Slider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("DiT Flow Steps", style: TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
                            Text("$_inferenceTimesteps steps", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.secondary)),
                          ],
                        ),
                        Slider(
                          value: _inferenceTimesteps.toDouble(),
                          min: 4,
                          max: 25,
                          divisions: 21,
                          onChanged: (val) => setState(() => _inferenceTimesteps = val.toInt()),
                        ),
                        const Text(
                          "Recommended: 10 steps for optimal speed vs studio audio fidelity.",
                          style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                        ),

                        const SizedBox(height: 14),

                        // Seed Settings
                        Row(
                          children: [
                            const Text("Random Seed", style: TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
                            const Spacer(),
                            Switch(
                              value: _randomSeed,
                              activeColor: AppTheme.primary,
                              onChanged: (val) => setState(() => _randomSeed = val),
                            ),
                          ],
                        ),

                        const Divider(color: AppTheme.surfaceBorder, height: 24),

                        // Toggles: Denoise & Normalize
                        Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Text Normalization", style: TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
                                  Text("WeText processing for numbers and dates", style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                                ],
                              ),
                            ),
                            Switch(
                              value: _normalize,
                              activeColor: AppTheme.secondary,
                              onChanged: (val) => setState(() => _normalize = val),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("ZipEnhancer Denoising", style: TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
                                  Text("Clean background noise from reference clip", style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                                ],
                              ),
                            ),
                            Switch(
                              value: _denoise,
                              activeColor: AppTheme.primary,
                              onChanged: (val) => setState(() => _denoise = val),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.textMuted),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  void _showVoicePicker(List<VoicePersona> personas) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Select Voice Persona", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: personas.length,
                  itemBuilder: (ctx, idx) {
                    final p = personas[idx];
                    final isSelected = p.id == _selectedPersona.id;
                    return ListTile(
                      leading: Text(p.avatar, style: const TextStyle(fontSize: 22)),
                      title: Text(p.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: AppTheme.textPrimary)),
                      subtitle: Text(p.controlInstruction, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                      trailing: isSelected ? const Icon(Icons.check, color: AppTheme.primary) : null,
                      onTap: () {
                        setState(() => _selectedPersona = p);
                        Navigator.of(ctx).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
