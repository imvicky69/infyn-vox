import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/presets.dart';
import '../../data/models/voice_persona.dart';
import '../../data/services/tts_api_service.dart';
import '../../data/services/audio_service.dart';
import '../widgets/clone_modal.dart';

class VoiceVaultScreen extends StatefulWidget {
  final TTSApiService apiService;
  final AudioService audioService;
  final List<VoicePersona> userPersonas;
  final Function(VoicePersona) onAddPersona;
  final Function(String) onDeletePersona;

  const VoiceVaultScreen({
    super.key,
    required this.apiService,
    required this.audioService,
    required this.userPersonas,
    required this.onAddPersona,
    required this.onDeletePersona,
  });

  @override
  State<VoiceVaultScreen> createState() => _VoiceVaultScreenState();
}

class _VoiceVaultScreenState extends State<VoiceVaultScreen> {
  String _filter = "All"; // "All", "Presets", "Clones"

  @override
  Widget build(BuildContext context) {
    final allList = [...DefaultPresets.presets, ...widget.userPersonas];
    final filtered = allList.where((p) {
      if (_filter == "Presets") return p.isPreset;
      if (_filter == "Clones") return !p.isPreset;
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            children: [
              const Icon(Icons.folder_shared_outlined, color: AppTheme.primary, size: 24),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Voice Vault & Persona Library",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.text(context)),
                  ),
                  Text(
                    "Manage your custom cloned timbres and curated 48kHz voice design presets",
                    style: TextStyle(fontSize: 12, color: AppTheme.textSub(context)),
                  ),
                ],
              ),
              const Spacer(),
              // Create New Voice Button
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => CloneModal(
                      apiService: widget.apiService,
                      onPersonaCreated: (newPersona) {
                        widget.onAddPersona(newPersona);
                        setState(() {});
                      },
                    ),
                  );
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text("New Voice / Clone", style: TextStyle(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Filters
          Row(
            children: ["All", "Presets", "Clones"].map((category) {
              final isSelected = _filter == category;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  backgroundColor: AppTheme.cardLight(context),
                  selectedColor: AppTheme.primary.withOpacity(0.15),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppTheme.primary : AppTheme.textSub(context),
                  ),
                  side: BorderSide(
                    color: isSelected ? AppTheme.primary : AppTheme.border(context),
                  ),
                  onSelected: (_) => setState(() => _filter = category),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Voices Grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.45,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final persona = filtered[index];
                return _buildPersonaCard(persona);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonaCard(VoicePersona p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.cardLight(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border(context)),
                ),
                child: Center(
                  child: Text(p.avatar, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.text(context)),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            p.isPreset ? "Preset" : "Custom Clone",
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          p.gender,
                          style: TextStyle(fontSize: 11, color: AppTheme.textSub(context)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!p.isPreset) ...[
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 16, color: AppTheme.textSub(context)),
                  onPressed: () => widget.onDeletePersona(p.id),
                  tooltip: "Delete Voice",
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Description / Instruction
          Expanded(
            child: Text(
              p.controlInstruction.isNotEmpty ? p.controlInstruction : "Reference audio continuation voice.",
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, height: 1.4, color: AppTheme.textSub(context)),
            ),
          ),
          const SizedBox(height: 8),
          // Tags
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: p.tags.take(3).map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.cardLight(context),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tag,
                  style: TextStyle(fontSize: 10, color: AppTheme.textSub(context)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
