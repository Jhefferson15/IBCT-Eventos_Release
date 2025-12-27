
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

final updateServiceProvider = Provider<UpdateService>((ref) => UpdateService());

class UpdateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      // Fetch latest version from Firestore
      final doc = await _firestore.collection('config').doc('app').get();
      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null) return null;

      final latestVersion = data['version'] as String?;
      final downloadUrl = data['download_url'] as String?;

      if (latestVersion == null || downloadUrl == null) return null;

      // Get current version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      if (_isVersionNewer(currentVersion, latestVersion)) {
        return AppUpdateInfo(
          latestVersion: latestVersion,
          downloadUrl: downloadUrl,
        );
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('Error checking for update: $e');
      return null;
    }
  }

  Stream<OtaEvent> downloadAndInstall(String url) {
    return OtaUpdate().execute(
      url,
      destinationFilename: 'ibct_eventos.apk', 
    );
  }

  bool _isVersionNewer(String current, String latest) {
    try {
      // Simplified version comparison (assumes semver format x.y.z)
      // Removing build number (+1) for comparison if needed, but simple comparison often works 
      // if formatting is consistent.
      // Better approach: split by dots.
      
      final currentParts = current.split('+')[0].split('.').map(int.parse).toList();
      final latestParts = latest.split('+')[0].split('.').map(int.parse).toList();

      for (int i = 0; i < latestParts.length; i++) {
        // If current doesn't have this part (e.g. 1.0 vs 1.0.1), treat as 0
        final currentPart = i < currentParts.length ? currentParts[i] : 0;
        final latestPart = latestParts[i];

        if (latestPart > currentPart) return true;
        if (latestPart < currentPart) return false;
      }
      return false; // Equal
    } catch (e) {
      return false; 
    }
  }
}

class AppUpdateInfo {
  final String latestVersion;
  final String downloadUrl;

  AppUpdateInfo({required this.latestVersion, required this.downloadUrl});
}
