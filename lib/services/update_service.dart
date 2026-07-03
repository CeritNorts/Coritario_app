import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class UpdateInfo {
  final String version;
  final int buildNumber;
  final String changelog;
  final bool hasUpdate;

  UpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.changelog,
    required this.hasUpdate,
  });
}

class UpdateService {
  Future<UpdateInfo?> checkForUpdates() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

      // Añadimos el timestamp para evitar el caché del servidor
      final response = await http.get(Uri.parse(
        'https://ceritnorts.github.io/corario/version.json?t=${DateTime.now().millisecondsSinceEpoch}'
      ));
      
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final webVersion = data['version'] as String;
        final webBuildNumber = data['buildNumber'] as int? ?? 0;
        final changelog = data['changelog'] as String? ?? '';

        final hasUpdate = _isNewer(currentVersion, currentBuildNumber, webVersion, webBuildNumber);

        return UpdateInfo(
          version: webVersion,
          buildNumber: webBuildNumber,
          changelog: changelog,
          hasUpdate: hasUpdate,
        );
      }
    } catch (e) {
      debugPrint("Error checking for updates: $e");
    }
    return null;
  }

  // Descarga el APK con progreso y luego ejecuta la instalación
  Future<void> downloadAndInstallApk({
    required String url,
    required Function(double progress) onProgress,
    required VoidCallback onComplete,
    required Function(String error) onError,
  }) async {
    try {
      final dio = Dio();
      final tempDir = await getTemporaryDirectory();
      final apkPath = '${tempDir.path}/app-release.apk';

      // Eliminar el archivo si ya existe para evitar conflictos
      final file = File(apkPath);
      if (await file.exists()) {
        await file.delete();
      }

      await dio.download(
        url,
        apkPath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            onProgress(progress);
          }
        },
      );

      onComplete();

      // Abrir el instalador del APK
      final result = await OpenFilex.open(apkPath);
      debugPrint("Resultado de apertura del instalador: ${result.message}");
    } catch (e) {
      debugPrint("Error descargando/instalando el APK: $e");
      onError(e.toString());
    }
  }

  bool _isNewer(String currentVer, int currentBuild, String webVer, int webBuild) {
    final currentParts = currentVer.split('.').map((x) => int.tryParse(x) ?? 0).toList();
    final webParts = webVer.split('.').map((x) => int.tryParse(x) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      final currentPart = i < currentParts.length ? currentParts[i] : 0;
      final webPart = i < webParts.length ? webParts[i] : 0;

      if (webPart > currentPart) return true;
      if (webPart < currentPart) return false;
    }

    return webBuild > currentBuild;
  }
}
