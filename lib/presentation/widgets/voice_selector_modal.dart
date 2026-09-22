import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/voice_persona.dart';

class VoiceSelectorModal extends StatefulWidget {
  final List<VoicePersona> personas;
  final VoicePersona selectedPersona;
  final Function(VoicePersona) onSelect;

  const VoiceSelectorModal({
    super.key,
    required this.personas,
    required this.selectedPersona,
    required this.onSelect,
  });

  static Future<void> show(
    BuildContext context, {
    required List<VoicePersona> personas,
    required VoicePersona selectedPersona,
    required Function(VoicePersona) onSelect,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBg(context),
      barrierColor: Colors.black.withOpacity(0.6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => VoiceSelectorModal(
        personas: personas,
        selectedPersona: selectedPersona,
        onSelect: onSelect,
      ),
    );
  }

  @override
  State<VoiceSelectorModal> createState() => _VoiceSelectorModalState();
}

class _VoiceSelectorModalState extends State<VoiceSelectorModal> {
  String _filter = "All"; // "All", "Female", "Male", "Hindi", "English"

  @override
  Widget build(BuildContext context) {
    final filtered = widget.personas.where((p) {
      if (_filter == "Female") return p.gender.toLowerCase() == "female";
      if (_filter == "Male") return p.gender.toLowerCase() == "male";
      if (_filter == "Hindi") return p.language == "hi" || p.tags.contains("Hindi");
      if (_filter == "English") return p.language == "en";
      return true;
    }).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      height: 480,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Title & Count
          Row(
            children: [
              Text(
                "Select Voice Template",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.text(context),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.cardLight(context),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "${filtered.length} Voices",
                  style: TextStyle(fontSize: 10, color: AppTheme.textSub(context), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ["All", "Female", "Male", "Hindi", "English"].map((category) {
                final isSelected = _filter == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    backgroundColor: AppTheme.cardLight(context),
                    selectedColor: AppTheme.primary.withOpacity(0.15),
                    labelStyle: TextStyle(
                      fontSize: 11,
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
          ),
          const SizedBox(height: 12),

          // List of Personas
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (ctx, idx) {
                final p = filtered[idx];
                final isSelected = p.id == widget.selectedPersona.id;

                return InkWell(
                  onTap: () {
                    widget.onSelect(p);
                    Navigator.of(ctx).pop();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary.withOpacity(0.08) : AppTheme.cardLight(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? AppTheme.primary : AppTheme.border(context),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(p.avatar, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    p.name,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      fontSize: 13,
                                      color: AppTheme.text(context),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppTheme.cardBg(context),
                                      borderRadius: BorderRadius.circular(3),
                                      border: Border.all(color: AppTheme.border(context), width: 0.5),
                                    ),
                                    child: Text(
                                      p.gender.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: p.gender.toLowerCase() == 'female'
                                            ? Colors.pinkAccent
                                            : AppTheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppTheme.cardBg(context),
                                      borderRadius: BorderRadius.circular(3),
                                      border: Border.all(color: AppTheme.border(context), width: 0.5),
                                    ),
                                    child: Text(
                                      p.language.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textSub(context),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                p.controlInstruction,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11, color: AppTheme.textSub(context)),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: AppTheme.primary, size: 18),
                      ],
                    ),
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
