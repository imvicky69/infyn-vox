import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../../core/theme/app_theme.dart';

class CustomTitleBar extends StatefulWidget {
  final String statusText;
  final bool isConnected;

  const CustomTitleBar({
    super.key,
    this.statusText = "Ready",
    this.isConnected = true,
  });

  @override
  State<CustomTitleBar> createState() => _CustomTitleBarState();
}

class _CustomTitleBarState extends State<CustomTitleBar> {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    _checkMaximized();
  }

  Future<void> _checkMaximized() async {
    final max = await windowManager.isMaximized();
    if (mounted) setState(() => _isMaximized = max);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        border: Border(bottom: BorderSide(color: AppTheme.border(context), width: 1)),
      ),
      child: Row(
        children: [
          // Window Drag Area & App Branding
          Expanded(
            child: DragToMoveArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        'lib/images/logo.png',
                        width: 22,
                        height: 22,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "infyn Vox",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: AppTheme.text(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.cardLight(context),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.border(context), width: 0.5),
                      ),
                      child: const Text(
                        "48kHz Studio",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Status Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: widget.isConnected 
                            ? AppTheme.success.withOpacity(0.12)
                            : AppTheme.warning.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.isConnected 
                              ? AppTheme.success.withOpacity(0.4)
                              : AppTheme.warning.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.isConnected ? AppTheme.success : AppTheme.warning,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.statusText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: widget.isConnected ? AppTheme.success : AppTheme.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Theme Toggle Button
          ValueListenableBuilder<ThemeMode>(
            valueListenable: AppTheme.themeModeNotifier,
            builder: (context, mode, _) {
              final isDark = mode == ThemeMode.dark;
              return Tooltip(
                message: isDark ? "Switch to Light Mode" : "Switch to Dark Mode",
                child: InkWell(
                  onTap: () => AppTheme.toggleTheme(),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                      size: 16,
                      color: AppTheme.textSub(context),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
          // Window Control Buttons (Minimize, Maximize, Close)
          _WindowButton(
            icon: Icons.remove,
            onTap: () => windowManager.minimize(),
          ),
          _WindowButton(
            icon: _isMaximized ? Icons.filter_none : Icons.crop_square,
            iconSize: 13,
            onTap: () async {
              if (await windowManager.isMaximized()) {
                windowManager.unmaximize();
                setState(() => _isMaximized = false);
              } else {
                windowManager.maximize();
                setState(() => _isMaximized = true);
              }
            },
          ),
          _WindowButton(
            icon: Icons.close,
            isClose: true,
            onTap: () => windowManager.close(),
          ),
        ],
      ),
    );
  }
}

class _WindowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isClose;
  final double iconSize;

  const _WindowButton({
    required this.icon,
    required this.onTap,
    this.isClose = false,
    this.iconSize = 15,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color bg = Colors.transparent;
    if (_isHovered) {
      bg = widget.isClose ? const Color(0xFFE81123) : AppTheme.surfaceLight;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 46,
          height: 42,
          color: bg,
          child: Icon(
            widget.icon,
            size: widget.iconSize,
            color: widget.isClose && _isHovered ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
