import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

class InAppUpdateService {
  static const Duration _checkInterval = Duration(hours: 24);
  DateTime? _lastCheckTime;

  Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      if (_lastCheckTime != null &&
          DateTime.now().difference(_lastCheckTime!) < _checkInterval) {
        return null;
      }

      final info = await InAppUpdate.checkForUpdate();
      _lastCheckTime = DateTime.now();
      return info;
    } catch (e) {
      debugPrint('Error checking for update: $e');
      throw Exception('Error checking for update: $e');
    }
  }

  Future<void> startFlexibleUpdate(BuildContext context) async {
    try {
      await InAppUpdate.startFlexibleUpdate();
      _showSnackBar(context, 'Update downloading in background...');

      _listenForFlexibleUpdateCompletion(context);
    } catch (e) {
      debugPrint('Error starting flexible update: $e');
      _showSnackBar(context, 'Failed to start update download');
      throw Exception('Error starting flexible update: $e');
    }
  }

  void _listenForFlexibleUpdateCompletion(BuildContext context) {
    Future.delayed(const Duration(seconds: 5), () async {
      try {
        final info = await InAppUpdate.checkForUpdate();
        if (info.installStatus == InstallStatus.downloaded) {
          _showUpdateReadyDialog(context);
        } else if (info.installStatus == InstallStatus.downloading) {
          _listenForFlexibleUpdateCompletion(context);
        }
      } catch (e) {
        debugPrint('Error checking update status: $e');
      }
    });
  }

  Future<void> completeFlexibleUpdate(BuildContext context) async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
      _showSnackBar(context, 'Update installed successfully!');
    } catch (e) {
      debugPrint('Error completing flexible update: $e');
      _showSnackBar(context, 'Failed to install update');
      throw Exception('Error completing flexible update: $e');
    }
  }

  Future<void> startImmediateUpdate(BuildContext context) async {
    try {
      await InAppUpdate.performImmediateUpdate();
      _showSnackBar(context, 'Update completed successfully!');
    } catch (e) {
      debugPrint('Error performing immediate update: $e');
      _showSnackBar(context, 'Failed to perform immediate update');
      throw Exception('Error performing immediate update: $e');
    }
  }

  void _showUpdateReadyDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Ready'),
          content: const Text(
            'The update has been downloaded and is ready to install. '
            'The app will restart after installation.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                completeFlexibleUpdate(context);
              },
              child: const Text('Install Now'),
            ),
          ],
        );
      },
    );
  }

  // Show dialog for mandatory updates
  void _showMandatoryUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Required'),
          content: const Text(
            'A mandatory update is available. Please update to continue using the app.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                startImmediateUpdate(context);
              },
              child: const Text('Update Now'),
            ),
          ],
        );
      },
    );
  }

  // Main function to handle update logic with different strategies
  Future<void> handleAppUpdate(
    BuildContext context, {
    bool forceMandatory = false,
    bool showNoUpdateMessage = false,
  }) async {
    try {
      final updateInfo = await checkForUpdate();

      if (updateInfo == null) {
        if (showNoUpdateMessage) {
          _showSnackBar(
              context, 'Already checked recently. No updates available.');
        }
        return;
      }

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        // Check if this is a mandatory update based on your criteria
        bool isMandatory =
            forceMandatory || _shouldForceMandatoryUpdate(updateInfo);

        if (isMandatory) {
          _showMandatoryUpdateDialog(context);
        } else {
          _showOptionalUpdateDialog(context, updateInfo);
        }
      } else {
        if (showNoUpdateMessage) {
          _showSnackBar(context, 'No updates available.');
        }
      }
    } catch (e) {
      debugPrint('Error handling app update: $e');
      _showSnackBar(context, 'Unable to check for updates');
    }
  }

  // Show dialog for optional updates
  void _showOptionalUpdateDialog(
      BuildContext context, AppUpdateInfo updateInfo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Available'),
          content: const Text(
            'A new version of the app is available. Would you like to update now?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                startFlexibleUpdate(context);
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  bool _shouldForceMandatoryUpdate(AppUpdateInfo updateInfo) {
    return false;
  }

  void _showSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // to add in the  setting section to checck for updates(manually)
  Future<void> manualUpdateCheck(BuildContext context) async {
    _showSnackBar(context, 'Checking for updates...');
    await handleAppUpdate(context, showNoUpdateMessage: true);
  }
}
