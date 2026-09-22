import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/voice_persona.dart';
import '../../data/services/tts_api_service.dart';

class CloneModal extends StatefulWidget {
  final TTSApiService apiService;
  final Function(VoicePersona) onPersonaCreated;

  const CloneModal({
    super.key,
    required this.apiService,
    required this.onPersonaCreated,
  });

  @override
  State<CloneModal> createState() => _CloneModalState();
}

class _CloneModalState extends State<CloneModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Common Fields
  final _nameController = TextEditingController(text: "My Cloned Voice");
  String _selectedGender = "Female";
  final String _selectedLanguage = "en";
  String _selectedAvatar = "🎙️";

  // Mode 1: Voice Design
  final _designPromptController = TextEditingController(
    text: "A warm young woman with a soft, gentle, and melodic voice. Speaks slowly with comforting emotion.",
  );

  // Mode 2: Controllable & Ultimate Cloning
  String? _referenceAudioPath;
  final _stylePromptController = TextEditingController(
    text: "Slightly faster pace, cheerful and confident tone.",
  );
  final _transcriptController = TextEditingController();
  bool _isTranscribing = false;

  final List<String> _avatars = ["🎙️", "✨", "🚀", "💡", "🌸", "⚡", "🎭", "👑", "🎧", "🤖"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _designPromptController.dispose();
    _stylePromptController.dispose();
    _transcriptController.dispose();
    super.dispose();
  }

  Future<void> _pickReferenceAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['wav', 'mp3', 'm4a', 'flac', 'ogg'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _referenceAudioPath = result.files.single.path;
      });

      // If in Ultimate tab, auto-transcribe
      if (_tabController.index == 2) {
        _transcribeAudio();
      }
    }
  }

  Future<void> _transcribeAudio() async {
    if (_referenceAudioPath == null) return;
    setState(() => _isTranscribing = true);
    final text = await widget.apiService.transcribeReferenceAudio(_referenceAudioPath!);
    if (mounted) {
      setState(() {
        _isTranscribing = false;
        if (text.isNotEmpty) {
          _transcriptController.text = text;
        }
      });
    }
  }

  void _handleCreate() {
    if (_nameController.text.trim().isEmpty) return;

    String instruction = "";
    String? promptText;
    List<String> tags = [];

    if (_tabController.index == 0) {
      // Voice Design
      instruction = _designPromptController.text.trim();
      tags = ["Voice Design", _selectedGender, _selectedLanguage];
    } else if (_tabController.index == 1) {
      // Controllable Cloning
      instruction = _stylePromptController.text.trim();
      tags = ["Controllable Clone", _selectedGender];
    } else {
      // Ultimate Continuation Cloning
      promptText = _transcriptController.text.trim();
      tags = ["Ultimate Clone", "Continuation"];
    }

    final persona = VoicePersona(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      gender: _selectedGender,
      language: _selectedLanguage,
      controlInstruction: instruction,
      referenceAudioPath: _referenceAudioPath,
      promptText: promptText,
      avatar: _selectedAvatar,
      tags: tags,
      isPreset: false,
      createdAt: DateTime.now(),
    );

    widget.onPersonaCreated(persona);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.cardBg(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.border(context), width: 1),
      ),
      child: Container(
        width: 680,
        height: 580,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.record_voice_over, color: AppTheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Voice Studio & Cloning Wizard",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.text(context)),
                    ),
                    Text(
                      "Create custom voices using Zero-Shot Voice Design or Voice Cloning",
                      style: TextStyle(fontSize: 12, color: AppTheme.textSub(context)),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: AppTheme.textSub(context), size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tab Bar
            Container(
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.cardLight(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(7),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.textSub(context),
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: "🎨 Voice Design"),
                  Tab(text: "🎛️ Controllable Clone"),
                  Tab(text: "🎙️ Ultimate Cloning"),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Common info: Name, Avatar, Gender
            Row(
              children: [
                // Avatar Picker
                PopupMenuButton<String>(
                  initialValue: _selectedAvatar,
                  color: AppTheme.cardBg(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: AppTheme.border(context)),
                  ),
                  onSelected: (val) => setState(() => _selectedAvatar = val),
                  itemBuilder: (context) => _avatars
                      .map((a) => PopupMenuItem(value: a, child: Text(a, style: const TextStyle(fontSize: 20))))
                      .toList(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.cardLight(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border(context)),
                    ),
                    child: Center(
                      child: Text(_selectedAvatar, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name Field
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    style: TextStyle(fontSize: 13, color: AppTheme.text(context)),
                    decoration: InputDecoration(
                      labelText: "Voice Persona Name",
                      labelStyle: TextStyle(fontSize: 12, color: AppTheme.textSub(context)),
                      filled: true,
                      fillColor: AppTheme.cardLight(context),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Gender Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.cardLight(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border(context)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedGender,
                      dropdownColor: AppTheme.cardBg(context),
                      items: ["Female", "Male", "Neutral"]
                          .map((g) => DropdownMenuItem(
                                value: g,
                                child: Text(g, style: TextStyle(fontSize: 12, color: AppTheme.text(context))),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedGender = val);
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Voice Design
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Voice Description Instruction:",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSub(context)),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: TextField(
                          controller: _designPromptController,
                          maxLines: 5,
                          style: TextStyle(fontSize: 13, color: AppTheme.text(context)),
                          decoration: InputDecoration(
                            hintText: "Describe gender, age, tone, emotion, pace (e.g., Young female voice, gentle, smiling)...",
                            hintStyle: TextStyle(fontSize: 12, color: AppTheme.textSub(context)),
                            filled: true,
                            fillColor: AppTheme.cardLight(context),
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
                              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Tab 2: Controllable Cloning
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildReferenceAudioPicker(),
                      const SizedBox(height: 12),
                      Text(
                        "Style Guidance Prompt (optional):",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSub(context)),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _stylePromptController,
                        maxLines: 2,
                        style: TextStyle(fontSize: 13, color: AppTheme.text(context)),
                        decoration: InputDecoration(
                          hintText: "Adjust emotion, speaking speed, or emphasis while preserving original timbre...",
                          hintStyle: TextStyle(fontSize: 12, color: AppTheme.textSub(context)),
                          filled: true,
                          fillColor: AppTheme.cardLight(context),
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
                            borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Tab 3: Ultimate Cloning
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildReferenceAudioPicker(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            "Reference Transcript (ASR Continuation):",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSub(context)),
                          ),
                          const Spacer(),
                          if (_isTranscribing)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: TextField(
                          controller: _transcriptController,
                          maxLines: 4,
                          style: TextStyle(fontSize: 13, color: AppTheme.text(context)),
                          decoration: InputDecoration(
                            hintText: "Exact spoken transcript of the reference audio for 100% nuanced continuation...",
                            hintStyle: TextStyle(fontSize: 12, color: AppTheme.textSub(context)),
                            filled: true,
                            fillColor: AppTheme.cardLight(context),
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
                              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("Cancel", style: TextStyle(color: AppTheme.textSub(context))),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _handleCreate,
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text("Save to Voice Vault", style: TextStyle(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferenceAudioPicker() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardLight(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Row(
        children: [
          Icon(
            _referenceAudioPath != null ? Icons.check_circle : Icons.upload_file,
            color: _referenceAudioPath != null ? AppTheme.success : AppTheme.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _referenceAudioPath != null
                  ? File(_referenceAudioPath!).uri.pathSegments.last
                  : "Upload Reference Audio (3-10s clean audio snippet)",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: _referenceAudioPath != null ? AppTheme.text(context) : AppTheme.textSub(context),
              ),
            ),
          ),
          OutlinedButton(
            onPressed: _pickReferenceAudio,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.text(context),
              side: BorderSide(color: AppTheme.border(context)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text("Choose File", style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
