// update_service.dart — auto-update service for Virent.
//
// Checks GitHub Releases for a newer version. When found, downloads the
// platform-appropriate installer (VirentSetup.exe for Windows, .apk for
// Android) and launches it. Progress is reported via a callback so the
// UI can show a progress bar.
//
// GitHub API endpoint used:
//   GET https://api.github.com/repos/FreedoomForm/Virent/releases/latest
//
// The release must have a tag_name matching the version (e.g. "v1.0.1")
// and at least one asset with a recognizable name:
//   - Windows:  filename contains "Setup" or ends with ".exe"
//   - Android:  filename ends with ".apk"

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// State of the update flow.
enum UpdateState {
  /// No check has been performed yet.
  idle,

  /// Currently checking GitHub for a newer release.
  checking,

  /// No update is available — the running version is the latest.
  upToDate,

  /// An update is available. [UpdateInfo] holds the details.
  available,

  /// Downloading the installer. [progress] (0.0–1.0) tracks the progress.
  downloading,

  /// Download complete — the installer is being launched.
  installing,

  /// The update failed (network error, parse error, etc.). [error] holds
  /// a human-readable message.
  error,
}

/// Metadata about an available update.
class UpdateInfo {
  final String version;
  final String downloadUrl;
  final String fileName;
  final String releaseNotes;

  const UpdateInfo({
    required this.version,
    required this.downloadUrl,
    required this.fileName,
    required this.releaseNotes,
  });
}

/// Result of an update check.
class UpdateCheckResult {
  final UpdateState state;
  final UpdateInfo? info;
  final String? error;

  const UpdateCheckResult({
    required this.state,
    this.info,
    this.error,
  });
}

/// Singleton service that checks for updates and downloads installers.
class UpdateService {
  static const _repo = 'FreedoomForm/Virent';
  static const _apiUrl = 'https://api.github.com/repos/$_repo/releases/latest';

  /// Checks GitHub for a newer release. Returns [UpdateCheckResult].
  Future<UpdateCheckResult> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version; // e.g. "1.0.0"

      final res = await http.get(
        Uri.parse(_apiUrl),
        headers: {'Accept': 'application/vnd.github+json'},
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) {
        // No releases yet → up to date.
        return const UpdateCheckResult(state: UpdateState.upToDate);
      }

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final tag = (json['tag_name'] ?? '').toString();
      // Strip leading "v" from tag: "v1.0.1" → "1.0.1"
      final latestVersion = tag.startsWith('v') ? tag.substring(1) : tag;

      if (latestVersion.isEmpty || !_isNewer(latestVersion, currentVersion)) {
        return const UpdateCheckResult(state: UpdateState.upToDate);
      }

      // Find the right asset for the current platform.
      final assets = (json['assets'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      final asset = _pickAsset(assets);
      if (asset == null) {
        return const UpdateCheckResult(
          state: UpdateState.error,
          error: 'Не найден установочный файл для вашей платформы',
        );
      }

      return UpdateCheckResult(
        state: UpdateState.available,
        info: UpdateInfo(
          version: latestVersion,
          downloadUrl: asset['browser_download_url'] as String,
          fileName: asset['name'] as String,
          releaseNotes: (json['body'] ?? '').toString(),
        ),
      );
    } catch (e) {
      return UpdateCheckResult(
        state: UpdateState.error,
        error: 'Не удалось проверить обновления: $e',
      );
    }
  }

  /// Downloads the installer to a temp file and launches it.
  /// [onProgress] is called with a 0.0–1.0 value as bytes stream in.
  Future<String> downloadAndInstall(
    String url,
    String fileName, {
    void Function(double progress)? onProgress,
  }) async {
    final tempDir = Directory.systemTemp;
    final filePath = '${tempDir.path}/$fileName';
    final file = File(filePath);

    final request = http.Request('GET', Uri.parse(url));
    final response = await http.Client().send(request);

    if (response.statusCode != 200) {
      throw Exception('Download failed: HTTP ${response.statusCode}');
    }

    final totalBytes = response.contentLength ?? 0;
    var receivedBytes = 0;
    final sink = file.openWrite();

    await for (final chunk in response.stream) {
      sink.add(chunk);
      receivedBytes += chunk.length;
      if (totalBytes > 0 && onProgress != null) {
        onProgress(receivedBytes / totalBytes);
      }
    }
    await sink.close();

    return filePath;
  }

  /// Picks the right asset for the current platform.
  Map<String, dynamic>? _pickAsset(List<Map<String, dynamic>> assets) {
    if (Platform.isWindows) {
      // Look for "VirentSetup.exe" or any .exe with "Setup" in the name.
      for (final a in assets) {
        final name = (a['name'] ?? '').toString().toLowerCase();
        if (name.contains('setup') && name.endsWith('.exe')) return a;
      }
      // Fallback: any .exe
      for (final a in assets) {
        final name = (a['name'] ?? '').toString().toLowerCase();
        if (name.endsWith('.exe')) return a;
      }
    } else if (Platform.isAndroid) {
      // Look for any .apk file.
      for (final a in assets) {
        final name = (a['name'] ?? '').toString().toLowerCase();
        if (name.endsWith('.apk')) return a;
      }
    }
    // Fallback: return the first asset.
    return assets.isNotEmpty ? assets.first : null;
  }

  /// Compares two semantic version strings. Returns `true` if [remote]
  /// is strictly newer than [local].
  bool _isNewer(String remote, String local) {
    final r = remote.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final l = local.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    // Pad to same length.
    while (r.length < l.length) r.add(0);
    while (l.length < r.length) l.add(0);
    for (var i = 0; i < r.length; i++) {
      if (r[i] > l[i]) return true;
      if (r[i] < l[i]) return false;
    }
    return false;
  }
}
