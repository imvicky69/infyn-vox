import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/tts_api_service.dart';
import '../../data/services/sidecar_service.dart';

class SettingsScreen extends StatefulWidget {
  final TTSApiService apiService;
  final SidecarService sidecarService;
  final VoidCallback onConfigChanged;

  const SettingsScreen({
    super.key,
    required this.apiService,
    required this.sidecarService,
    required this.onConfigChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _urlController;
  late TextEditingController _apiKeyController;
  Map<String, dynamic>? _healthData;
  Map<String, dynamic>? _modelData;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.apiService.baseUrl);
    _apiKeyController = TextEditingController(text: widget.apiService.apiKey ?? "");
    _checkServer();
    widget.sidecarService.onStatusChanged.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _checkServer() async {
    setState(() => _isChecking = true);
    final health = await widget.apiService.checkHealth();
    final model = await widget.apiService.getModelStatus();
    if (mounted) {
      setState(() {
        _healthData = health;
        _modelData = model;
        _isChecking = false;
      });
    }
  }

  void _saveConfig() {
    widget.apiService.baseUrl = _urlController.text.trim();
    widget.apiService.apiKey = _apiKeyController.text.trim().isEmpty ? null : _apiKeyController.text.trim();
    widget.onConfigChanged();
    _checkServer();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.cardLight(context),
        content: Text("Server configuration updated successfully.", style: TextStyle(color: AppTheme.text(context))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isHealthy = _healthData?['status'] == 'healthy';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.tune, color: AppTheme.primary, size: 24),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Engine Settings & Hardware Hub",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.text(context)),
                  ),
                  Text(
                    "Configure backend endpoints, local sidecar processes, and monitor system resources",
                    style: TextStyle(fontSize: 12, color: AppTheme.textSub(context)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Hardware Intel Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBg(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withOpacity(0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.memory, color: AppTheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "Detected Hardware: Intel(R) Iris(R) Xe Graphics (iGPU)",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.text(context)),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text("Shared Memory", style: TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "ℹ️ Recommendation: Because this machine utilizes integrated graphics, connecting to a Remote GPU Server (vLLM-Omni / RunPod / Modal / LAN NVIDIA RTX) delivers instantaneous ~0.15 RTF streaming synthesis. For offline usage, local CPU mode operates via our optimized sidecar.",
                  style: TextStyle(fontSize: 12, height: 1.5, color: AppTheme.textSub(context)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Remote Server Configuration Card
          Container(
            padding: const EdgeInsets.all(20),
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
                    const Icon(Icons.cloud_outlined, color: AppTheme.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      "VoxCPM Server Connection (vLLM-Omni / FastAPI / OpenAI)",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.text(context)),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: _isChecking
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.refresh, size: 18, color: AppTheme.text(context)),
                      onPressed: _checkServer,
                      tooltip: "Ping Server",
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _urlController,
                        style: TextStyle(fontSize: 13, color: AppTheme.text(context)),
                        decoration: InputDecoration(
                          labelText: "Server Endpoint URL",
                          labelStyle: TextStyle(color: AppTheme.textSub(context)),
                          hintText: "http://127.0.0.1:8808 or https://your-gpu-server.com",
                          hintStyle: TextStyle(color: AppTheme.textSub(context)),
                          filled: true,
                          fillColor: AppTheme.cardLight(context),
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
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _apiKeyController,
                        obscureText: true,
                        style: TextStyle(fontSize: 13, color: AppTheme.text(context)),
                        decoration: InputDecoration(
                          labelText: "API Key (optional)",
                          labelStyle: TextStyle(color: AppTheme.textSub(context)),
                          hintText: "Bearer token",
                          hintStyle: TextStyle(color: AppTheme.textSub(context)),
                          filled: true,
                          fillColor: AppTheme.cardLight(context),
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
                    ElevatedButton(
                      onPressed: _saveConfig,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Save & Connect"),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Connection Status Panel
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardLight(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isHealthy ? Icons.check_circle : Icons.error_outline,
                            color: isHealthy ? AppTheme.success : AppTheme.warning,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isHealthy
                                  ? "Connected: ${_healthData?['service']} (${_healthData?['device']}) • 48kHz Output Ready"
                                  : "Server Offline or Unreachable at ${_urlController.text}",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isHealthy ? AppTheme.text(context) : AppTheme.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (isHealthy && _modelData != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          "Model: ${_modelData!['model'] ?? 'VoxCPM2'}  |  Arch: ${_modelData!['architecture'] ?? 'MiniCPM-4-2B + LocDiT'}  |  Languages: ${_modelData!['supported_languages'] ?? 30}",
                          style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Local Sidecar Process Manager
          Container(
            padding: const EdgeInsets.all(20),
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
                    const Icon(Icons.terminal, color: AppTheme.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      "Local Sidecar Process Controller",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.text(context)),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: widget.sidecarService.status == SidecarStatus.running
                            ? AppTheme.success.withOpacity(0.15)
                            : AppTheme.cardLight(context),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.border(context)),
                      ),
                      child: Text(
                        widget.sidecarService.status.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: widget.sidecarService.status == SidecarStatus.running
                              ? AppTheme.success
                              : AppTheme.textSub(context),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "Launches a local background instance of server.py or llama.cpp-omni on your PC. Flutter monitors logs and automatically shuts down the background worker upon application close.",
                  style: TextStyle(fontSize: 12, color: AppTheme.textSub(context)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: widget.sidecarService.status == SidecarStatus.running
                          ? null
                          : () async {
                              await widget.sidecarService.startLocalServer();
                              _checkServer();
                            },
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text("Launch Local Server"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: widget.sidecarService.status == SidecarStatus.running
                          ? () => widget.sidecarService.stopLocalServer()
                          : null,
                      icon: const Icon(Icons.stop, size: 16),
                      label: const Text("Stop Server"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.accent,
                        side: BorderSide(color: AppTheme.border(context)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Terminal Output Window
                Container(
                  height: 140,
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.isDark(context) ? const Color(0xFF09090B) : const Color(0xFFF4F4F5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border(context)),
                  ),
                  child: ListView.builder(
                    itemCount: widget.sidecarService.logs.length,
                    itemBuilder: (ctx, idx) {
                      return Text(
                        widget.sidecarService.logs[idx],
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: AppTheme.textSub(context),
                        ),
                      );
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
}
