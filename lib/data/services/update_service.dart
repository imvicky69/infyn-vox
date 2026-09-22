import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class AppReleaseInfo {
  final String tagName;
  final String versionName;
  final String releaseNotes;
  final String htmlUrl;
  final String? downloadUrl;
  final DateTime? publishedAt;
  final bool isNewer;

  const AppReleaseInfo({
    required this.tagName,
    required this.versionName,
    required this.releaseNotes,
    required this.htmlUrl,
    this.downloadUrl,
    this.publishedAt,
    required this.isNewer,
  });

  factory AppReleaseInfo.fromJson(Map<String, dynamic> json, String currentVersion) {
    final tagName = (json['tag_name'] as String? ?? '').trim();
    final cleanTag = tagName.replaceAll(RegExp(r'^[vV]'), '');
    final name = (json['name'] as String? ?? tagName).trim();
    final body = (json['body'] as String? ?? '').trim();
    final htmlUrl = (json['html_url'] as String? ?? 'https://github.com/imvicky69/infyn-vox/releases').trim();
    
    // Check for direct executable or zip assets
    String? directUrl;
    final assets = json['assets'] as List<dynamic>?;
    if (assets != null && assets.isNotEmpty) {
      for (final a in assets) {
        final assetName = (a['name'] as String? ?? '').toLowerCase();
        if (assetName.endsWith('.exe') || assetName.endsWith('.zip')) {
          directUrl = a['browser_download_url'] as String?;
          break;
        }
      }
    }

    DateTime? publishedAt;
    if (json['published_at'] != null) {
      publishedAt = DateTime.tryParse(json['published_at'] as String);
    }

    final isNewer = UpdateService.isNewerVersion(cleanTag, currentVersion);

    return AppReleaseInfo(
      tagName: tagName,
      versionName: name.isNotEmpty ? name : tagName,
      releaseNotes: body,
      htmlUrl: htmlUrl,
      downloadUrl: directUrl,
      publishedAt: publishedAt,
      isNewer: isNewer,
    );
  }
}

class UpdateService {
  static const String currentAppVersion = "1.0.0";
  static const String repoOwner = "imvicky69";
  static const String repoName = "infyn-vox";

  static String get releasesApiUrl =>
      "https://api.github.com/repos/$repoOwner/$repoName/releases/latest";

  /// Checks whether [remoteVersion] is strictly newer than [localVersion] using semantic versioning.
  static bool isNewerVersion(String remoteVersion, String localVersion) {
    try {
      final remoteParts = _parseVersion(remoteVersion);
      final localParts = _parseVersion(localVersion);

      for (int i = 0; i < 3; i++) {
        if (remoteParts[i] > localParts[i]) return true;
        if (remoteParts[i] < localParts[i]) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static List<int> _parseVersion(String ver) {
    // Remove leading v/V, strip build metadata or prerelease tags for primary comparison
    final sanitized = ver.trim().replaceAll(RegExp(r'^[vV]'), '');
    final clean = sanitized.split(RegExp(r'[-+]')).first;
    final segments = clean.split('.');

    final major = segments.isNotEmpty ? int.tryParse(segments[0]) ?? 0 : 0;
    final minor = segments.length > 1 ? int.tryParse(segments[1]) ?? 0 : 0;
    final patch = segments.length > 2 ? int.tryParse(segments[2]) ?? 0 : 0;

    return [major, minor, patch];
  }

  /// Queries GitHub Releases for the latest version.
  /// Returns [AppReleaseInfo] if found, or null if offline, rate-limited, or no releases exist.
  Future<AppReleaseInfo?> checkForUpdate({http.Client? client}) async {
    final httpClient = client ?? http.Client();
    try {
      final response = await httpClient.get(
        Uri.parse(releasesApiUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'infyn-vox-desktop-updater',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return AppReleaseInfo.fromJson(data, currentAppVersion);
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      if (client == null) httpClient.close();
    }
  }

  /// Launches the given [url] in the user's default browser on Windows.
  static Future<void> openReleaseUrl(String url) async {
    try {
      if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', url]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [url]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [url]);
      }
    } catch (_) {}
  }
}
