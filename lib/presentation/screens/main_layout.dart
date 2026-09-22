import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/voice_persona.dart';
import '../../data/models/generation_result.dart';
import '../../data/services/tts_api_service.dart';
import '../../data/services/audio_service.dart';
import '../../data/services/sidecar_service.dart';
import '../widgets/custom_title_bar.dart';
import '../widgets/studio_dock.dart';
import 'studio_screen.dart';
import 'segmenter_screen.dart';
import 'saved_files_screen.dart';
import 'voice_vault_screen.dart';
import 'settings_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  final TTSApiService _apiService = TTSApiService();
  final AudioService _audioService = AudioService();
  final SidecarService _sidecarService = SidecarService();

  final List<VoicePersona> _userPersonas = [];
  final List<GenerationResult> _savedResults = [];
  GenerationResult? _currentResult;
  bool _isServerConnected = false;
  String _serverStatusPill = "Checking...";

  @override
  void initState() {
    super.initState();
    _sidecarService.onStatusChanged.listen((status) {
      if (status == SidecarStatus.running) {
        _checkServerStatus();
      }
    });
    _initEngineAndCheckStatus();
  }

  @override
  void dispose() {
    _audioService.dispose();
    _sidecarService.dispose();
    super.dispose();
  }

  void _onAudioGenerated(GenerationResult res) {
    setState(() {
      _currentResult = res;
      _savedResults.removeWhere((r) => r.id == res.id);
      _savedResults.insert(0, res);
    });
  }

  Future<void> _checkServerStatus() async {
    final health = await _apiService.checkHealth();
    if (mounted) {
      setState(() {
        if (health['status'] == 'healthy') {
          _isServerConnected = true;
          _serverStatusPill = "48kHz Engine Ready (${health['device'] ?? 'Neural'})";
        } else {
          _isServerConnected = false;
          _serverStatusPill = "Engine Offline (Click Settings)";
        }
      });
    }
  }

  Future<void> _initEngineAndCheckStatus() async {
    var health = await _apiService.checkHealth();
    if (health['status'] == 'healthy') {
      if (mounted) {
        setState(() {
          _isServerConnected = true;
          _serverStatusPill = "48kHz Engine Ready (${health['device'] ?? 'Neural'})";
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _serverStatusPill = "Auto-starting Engine...";
      });
    }

    await _sidecarService.startLocalServer();

    for (int i = 0; i < 6; i++) {
      await Future.delayed(const Duration(milliseconds: 1000));
      health = await _apiService.checkHealth();
      if (health['status'] == 'healthy') {
        if (mounted) {
          setState(() {
            _isServerConnected = true;
            _serverStatusPill = "48kHz Engine Ready (${health['device'] ?? 'Neural'})";
          });
        }
        return;
      }
    }

    if (mounted) {
      setState(() {
        _isServerConnected = false;
        _serverStatusPill = "Engine Offline (Click Settings)";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: Column(
        children: [
          // Windows Frameless Title Bar
          CustomTitleBar(
            statusText: _serverStatusPill,
            isConnected: _isServerConnected,
          ),

          // Core Workspace Area with IndexedStack to fully preserve all state
          Expanded(
            child: Row(
              children: [
                // Left Navigation Rail
                _buildNavigationRail(),

                // Center Active View (IndexedStack preserves text, voice, sliders across tab switches)
                Expanded(
                  child: Container(
                    color: AppTheme.bg(context),
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: [
                        // Tab 0: Studio Screen
                        StudioScreen(
                          apiService: _apiService,
                          audioService: _audioService,
                          userPersonas: _userPersonas,
                          onAddPersona: (p) => setState(() => _userPersonas.add(p)),
                          onAudioGenerated: _onAudioGenerated,
                        ),
                        // Tab 1: Long-Form Segmenter Screen
                        SegmenterScreen(
                          apiService: _apiService,
                          audioService: _audioService,
                          userPersonas: _userPersonas,
                          onAudioGenerated: _onAudioGenerated,
                        ),
                        // Tab 2: Saved Files Library & Batch Export
                        SavedFilesScreen(
                          audioService: _audioService,
                          apiService: _apiService,
                          savedResults: _savedResults,
                          onClearAll: () => setState(() => _savedResults.clear()),
                          onDeleteResult: (id) => setState(() => _savedResults.removeWhere((r) => r.id == id)),
                        ),
                        // Tab 3: Voice Vault Screen
                        VoiceVaultScreen(
                          apiService: _apiService,
                          audioService: _audioService,
                          userPersonas: _userPersonas,
                          onAddPersona: (p) => setState(() => _userPersonas.add(p)),
                          onDeletePersona: (id) => setState(() => _userPersonas.removeWhere((p) => p.id == id)),
                        ),
                        // Tab 4: Settings Screen
                        SettingsScreen(
                          apiService: _apiService,
                          sidecarService: _sidecarService,
                          onConfigChanged: _checkServerStatus,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Persistent Studio Bottom Audio Dock
          StudioDock(
            audioService: _audioService,
            apiService: _apiService,
            trackTitle: _currentResult?.text != null
                ? (_currentResult!.text.length > 35
                    ? "${_currentResult!.text.substring(0, 35)}..."
                    : _currentResult!.text)
                : null,
            subtitle: _currentResult?.voiceName != null
                ? "Voice: ${_currentResult!.voiceName}"
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationRail() {
    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        border: Border(right: BorderSide(color: AppTheme.border(context), width: 1)),
      ),
      child: Column(
        children: [
          // Logo Branding at top of Rail
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'lib/images/logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const Divider(height: 1, indent: 14, endIndent: 14),
          const SizedBox(height: 12),
          _buildNavItem(0, Icons.graphic_eq, "Studio"),
          const SizedBox(height: 8),
          _buildNavItem(1, Icons.segment, "Long-Form"),
          const SizedBox(height: 8),
          _buildNavItem(2, Icons.folder_copy_outlined, "Library"),
          const SizedBox(height: 8),
          _buildNavItem(3, Icons.record_voice_over_outlined, "Vault"),
          const Spacer(),
          _buildNavItem(4, Icons.tune, "Settings"),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;

    return Tooltip(
      message: label,
      preferBelow: false,
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 54,
          height: 52,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppTheme.primary.withOpacity(0.4) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? AppTheme.primary : AppTheme.textSub(context),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppTheme.primary : AppTheme.textSub(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
