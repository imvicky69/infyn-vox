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
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // Windows Frameless Title Bar
          CustomTitleBar(
            statusText: _serverStatusPill,
            isConnected: _isServerConnected,
          ),

          // Core Workspace Area
          Expanded(
            child: Row(
              children: [
                // Left Navigation Rail
                _buildNavigationRail(),

                // Center Active View
                Expanded(
                  child: Container(
                    color: AppTheme.background,
                    child: _buildCurrentScreen(),
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

  Widget _buildCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return StudioScreen(
          apiService: _apiService,
          audioService: _audioService,
          userPersonas: _userPersonas,
          onAddPersona: (p) => setState(() => _userPersonas.add(p)),
          onAudioGenerated: (res) => setState(() => _currentResult = res),
        );
      case 1:
        return SegmenterScreen(
          apiService: _apiService,
          audioService: _audioService,
          userPersonas: _userPersonas,
        );
      case 2:
        return VoiceVaultScreen(
          apiService: _apiService,
          audioService: _audioService,
          userPersonas: _userPersonas,
          onAddPersona: (p) => setState(() => _userPersonas.add(p)),
          onDeletePersona: (id) => setState(() => _userPersonas.removeWhere((p) => p.id == id)),
        );
      case 3:
        return SettingsScreen(
          apiService: _apiService,
          sidecarService: _sidecarService,
          onConfigChanged: _checkServerStatus,
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildNavigationRail() {
    return Container(
      width: 72,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(right: BorderSide(color: AppTheme.surfaceBorder, width: 1)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildNavItem(0, Icons.graphic_eq, "Studio"),
          const SizedBox(height: 8),
          _buildNavItem(1, Icons.segment, "Long-Form"),
          const SizedBox(height: 8),
          _buildNavItem(2, Icons.folder_shared_outlined, "Vault"),
          const Spacer(),
          _buildNavItem(3, Icons.tune, "Settings"),
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
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary.withOpacity(0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppTheme.primary.withOpacity(0.5) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppTheme.primaryLight : AppTheme.textSecondary,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.primaryLight : AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
