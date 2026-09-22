import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/update_service.dart';

class UpdateDialog extends StatelessWidget {
  final AppReleaseInfo releaseInfo;
  final bool isForced;

  const UpdateDialog({
    super.key,
    required this.releaseInfo,
    this.isForced = true,
  });

  static Future<void> show(
    BuildContext context, {
    required AppReleaseInfo releaseInfo,
    bool isForced = true,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: !isForced,
      builder: (ctx) => UpdateDialog(
        releaseInfo: releaseInfo,
        isForced: isForced,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isForced,
      child: Dialog(
        backgroundColor: AppTheme.cardBg(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        child: Container(
          width: 520,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Badge & App Info
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                    ),
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          'lib/images/logo.png',
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "infyn Vox",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.text(context),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: isForced
                                    ? AppTheme.primary.withOpacity(0.15)
                                    : AppTheme.cardLight(context),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isForced ? AppTheme.primary : AppTheme.border(context),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                isForced ? "UPDATE REQUIRED" : "UPDATE AVAILABLE",
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isForced
                            ? "A newer release is available. Please update to continue using infyn Vox."
                            : "A new version of infyn Vox has been released.",
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSub(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Version Comparison Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.cardLight(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border(context)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Current: ",
                          style: TextStyle(fontSize: 12, color: AppTheme.textSub(context)),
                        ),
                        Text(
                          "v${UpdateService.currentAppVersion}",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.text(context),
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_forward, size: 14, color: AppTheme.primary),
                    Row(
                      children: [
                        Text(
                          "Latest: ",
                          style: TextStyle(fontSize: 12, color: AppTheme.textSub(context)),
                        ),
                        Text(
                          releaseInfo.tagName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Release Notes Box
              if (releaseInfo.releaseNotes.isNotEmpty) ...[
                Text(
                  "What's New in ${releaseInfo.tagName}:",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.text(context),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  constraints: const BoxConstraints(maxHeight: 140),
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.isDark(context)
                        ? const Color(0xFF0C0C0E)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border(context)),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      releaseInfo.releaseNotes,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.5,
                        color: AppTheme.textSub(context),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ] else
                const SizedBox(height: 8),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isForced) ...[
                    TextButton.icon(
                      onPressed: () => exit(0),
                      icon: Icon(Icons.power_settings_new, size: 14, color: AppTheme.textSub(context)),
                      label: Text("Exit App", style: TextStyle(color: AppTheme.textSub(context))),
                    ),
                  ] else ...[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text("Later", style: TextStyle(color: AppTheme.textSub(context))),
                    ),
                  ],
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      final url = releaseInfo.downloadUrl ?? releaseInfo.htmlUrl;
                      UpdateService.openReleaseUrl(url);
                    },
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text("Download & Update", style: TextStyle(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 3,
                      shadowColor: AppTheme.primary.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
