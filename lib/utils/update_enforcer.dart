import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/api_endpoints.dart';
import '../core/theme/app_colors.dart';
import 'templates/dio_template.dart';

class UpdateChecker {
  static final UpdateChecker _instance = UpdateChecker._internal();
  factory UpdateChecker() => _instance;
  UpdateChecker._internal();

  /// ⚙️ Set this boolean to true if you explicitly want to test/enforce updates in debug mode.
  /// When false (default), debug versions bypass the update requirement completely.
  static bool enableUpdateInDebug = false;

  bool _isChecking = false;
  final int _retryCooldownSeconds = 2;

  Future<void> checkForUpdates({bool fromStartUp = false}) async {
    // Bypass in debug builds unless explicitly enabled
    if (kDebugMode && !enableUpdateInDebug) {
      Logger().d(
          'UpdateChecker: Bypassed in debug mode (enableUpdateInDebug is false).');
      if (!fromStartUp) {
        Get.snackbar(
          'update_check'.tr,
          'debug_update_bypassed'.tr,
          backgroundColor: Colors.blueGrey,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
      return;
    }

    if (_isChecking) return;
    _isChecking = true;

    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String installedVersion = packageInfo.version;

      await DioService.dioGet(
        path: ApiEndpoints.appVersion,
        onSuccess: (response) async {
          final data = response.data?['data'];
          if (data == null || data is! Map) return;

          final bool isAndroid = Platform.isAndroid;
          final String latestVersion = (isAndroid
                  ? data['latest_version_android']
                  : data['latest_version_ios'])
              ?.toString() ??
              '1.0.0';

          final String rawUpdateLink = (isAndroid
                  ? data['update_link_android']
                  : data['update_link_ios'])
              ?.toString() ??
              '';

          // Default fallback to Google Play Store / App Store link
          final String defaultLink = isAndroid
              ? 'https://play.google.com/store/apps/details?id=com.amn.delivery'
              : 'https://play.google.com/store/apps/details?id=com.amn.delivery';

          final String updateLink =
              rawUpdateLink.isNotEmpty ? rawUpdateLink : defaultLink;

          Logger().d(
              'UpdateChecker: installed=$installedVersion, latest=$latestVersion, link=$updateLink');

          if (_isUpdateAvailable(installedVersion, latestVersion)) {
            // Force update loop like yenetena_mobile
            if (Get.context != null) {
              await _forceImmediateUpdate(
                Get.context!,
                latestVersion: latestVersion,
                updateLink: updateLink,
              );
            }
          } else {
            if (!fromStartUp) {
              Get.snackbar(
                'update_check'.tr,
                '${'app_up_to_date'.tr} (v$installedVersion).',
                backgroundColor: const Color(0xFF10B981),
                colorText: Colors.white,
                snackPosition: SnackPosition.BOTTOM,
                margin: const EdgeInsets.all(16),
                borderRadius: 12,
                duration: const Duration(seconds: 3),
              );
            }
          }
        },
        onFailure: (error, response) {
          Logger().e('Update check failed: $error');
          if (!fromStartUp) {
            Get.snackbar(
              'update_check'.tr,
              'unable_to_check_updates'.tr,
              backgroundColor: Colors.redAccent,
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM,
              margin: const EdgeInsets.all(16),
              borderRadius: 12,
            );
          }
        },
      );
    } catch (e, stack) {
      Logger().e('Error in UpdateChecker: $e\n$stack');
    } finally {
      _isChecking = false;
    }
  }

  @visibleForTesting
  bool isUpdateAvailable(String installedVersion, String latestVersion) =>
      _isUpdateAvailable(installedVersion, latestVersion);

  @visibleForTesting
  int compareVersions(String v1, String v2) => _compareVersions(v1, v2);

  bool _isUpdateAvailable(String installedVersion, String latestVersion) {
    return _compareVersions(installedVersion, latestVersion) < 0;
  }

  int _compareVersions(String v1, String v2) {
    final clean1 = v1.split('+').first.trim();
    final clean2 = v2.split('+').first.trim();

    var parts1 = clean1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    var parts2 = clean2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    // If remote version has 2 components (e.g. "1.39") while app has 3 (e.g. "1.3.9"),
    // decompose "1.XY" into [1, X, Y]
    if (parts2.length == 2 && parts2[1] >= 10 && parts1.length >= 3) {
      final tens = parts2[1] ~/ 10;
      final units = parts2[1] % 10;
      parts2 = [parts2[0], tens, units];
    } else if (parts1.length == 2 && parts1[1] >= 10 && parts2.length >= 3) {
      final tens = parts1[1] ~/ 10;
      final units = parts1[1] % 10;
      parts1 = [parts1[0], tens, units];
    }

    final maxLength = math.max(parts1.length, parts2.length);
    for (int i = 0; i < maxLength; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 < p2) return -1;
      if (p1 > p2) return 1;
    }
    return 0;
  }

  /// Forces the user into the update workflow in an inescapable loop until completed.
  /// Exactly follows yenetena_mobile's _forceImmediateUpdate pattern.
  Future<void> _forceImmediateUpdate(
    BuildContext context, {
    required String latestVersion,
    required String updateLink,
  }) async {
    bool updateCompleted = false;
    int attempt = 0;

    Logger().d("🔄 FORCE UPDATE LOOP STARTED");

    while (!updateCompleted) {
      attempt++;
      Logger().d("⏳ Attempt #$attempt — showing update dialog...");

      BuildContext? dialogContext;

      if (!context.mounted) break;

      // ---- SHOW NON-DISMISSIBLE UPDATE DIALOG ----
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          dialogContext = ctx;
          return PopScope(
            canPop: false,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.system_security_update_rounded,
                      color: Color(0xFFEF4444), size: 28),
                  SizedBox(width: 10),
                  Text(
                    "Update Required",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: Text(
                "A new version ($latestVersion) is available. You must update to continue.",
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      if (dialogContext != null) {
                        Navigator.of(dialogContext!).pop();
                      }
                    },
                    child: const Text(
                      "Update Now",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );

      Logger().d("🔍 Checking for update via Play Store...");

      try {
        if (Platform.isAndroid) {
          // Check for Google Play In-App Update
          AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();
          Logger().d(
              "ℹ️ Play Store checkForUpdate() returned: availability=${updateInfo.updateAvailability}, "
              "immediateAllowed=${updateInfo.immediateUpdateAllowed}, "
              "flexibleAllowed=${updateInfo.flexibleUpdateAllowed}");

          if (updateInfo.updateAvailability ==
              UpdateAvailability.updateNotAvailable) {
            Logger().w(
                "⚠️ Update not available on Play Store yet. Retrying in $_retryCooldownSeconds seconds...");
            await _openStore(updateLink);
            await Future.delayed(Duration(seconds: _retryCooldownSeconds));
            continue;
          }

          Logger().d("🚀 Starting IMMEDIATE in-app update...");

          if (updateInfo.immediateUpdateAllowed) {
            AppUpdateResult result = await InAppUpdate.performImmediateUpdate();
            Logger().d("📥 performImmediateUpdate() result = $result");

            if (result == AppUpdateResult.success) {
              Logger().d("🎉 UPDATE COMPLETED SUCCESSFULLY!");
              updateCompleted = true;
              break;
            }
          } else if (updateInfo.flexibleUpdateAllowed) {
            AppUpdateResult result = await InAppUpdate.startFlexibleUpdate();
            Logger().d("📥 startFlexibleUpdate() result = $result");

            if (result == AppUpdateResult.success) {
              await InAppUpdate.completeFlexibleUpdate();
              updateCompleted = true;
              break;
            }
          }
        } else {
          // iOS: direct to App Store
          await _openStore(updateLink);
        }
      } catch (e, stack) {
        Logger().e("❌ ERROR during update attempt #$attempt: $e\n$stack");
        // Fallback to launching store URL directly
        await _openStore(updateLink);
      }

      if (!updateCompleted) {
        Logger().d(
            "⚠️ Update did not complete. Retrying after cooldown...");
        await Future.delayed(Duration(seconds: _retryCooldownSeconds));
      }
    }

    Logger().d("🏁 FORCE UPDATE LOOP EXIT — Update is completed.");
  }

  Future<void> _openStore(String link) async {
    if (link.isEmpty) return;
    try {
      final uri = Uri.parse(link);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      Logger().e('Could not launch update URL: $link');
    }
  }
}
