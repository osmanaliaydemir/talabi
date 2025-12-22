import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:get_it/get_it.dart';

class VersionCheckService {
  final ApiService _apiService = GetIt.I<ApiService>();
  final LoggerService _logger = LoggerService();

  Future<void> checkVersion(BuildContext context) async {
    try {
      final settings = await _apiService.getVersionSettings();
      if (settings == null) return;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      String minVersion = '0.0.0';
      if (Platform.isAndroid) {
        minVersion = settings.minVersionAndroid;
      } else if (Platform.isIOS) {
        minVersion = settings.minVersionIOS;
      }

      if (_isVersionLower(currentVersion, minVersion)) {
        if (context.mounted) {
          _showUpdateDialog(context, settings, settings.forceUpdate);
        }
      }
    } catch (e) {
      _logger.error('Version check failed', e);
    }
  }

  bool _isVersionLower(String current, String min) {
    try {
      final List<int> cParts = current.split('.').map(int.parse).toList();
      final List<int> mParts = min.split('.').map(int.parse).toList();

      for (int i = 0; i < 3; i++) {
        final int c = (i < cParts.length) ? cParts[i] : 0;
        final int m = (i < mParts.length) ? mParts[i] : 0;
        if (c < m) return true;
        if (c > m) return false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void _showUpdateDialog(BuildContext context, dynamic settings, bool force) {
    // Determine language from context or system?
    // Using simple fallback for now or context locale if possible.
    // Assuming 'tr' as default or checking locale.
    final locale = Localizations.localeOf(context).languageCode;
    String title = settings.titleEn;
    String body = settings.bodyEn;

    if (locale == 'tr') {
      title = settings.titleTr;
      body = settings.bodyTr;
    } else if (locale == 'ar') {
      title = settings.titleAr;
      body = settings.bodyAr;
    }

    // Fallback if empty
    if (title.isEmpty) title = 'Update Available';
    if (body.isEmpty) body = 'A new version is available. Please update.';

    showDialog(
      context: context,
      barrierDismissible: !force,
      builder: (BuildContext context) {
        return PopScope(
          canPop: !force,
          onPopInvokedWithResult: (bool didPop, dynamic result) async {
            if (didPop) return;
          },
          child: AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: <Widget>[
              if (!force)
                TextButton(
                  child: Text(
                    locale == 'tr'
                        ? 'Daha Sonra'
                        : (locale == 'ar' ? 'لاحقاً' : 'Later'),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              TextButton(
                child: Text(
                  locale == 'tr'
                      ? 'Güncelle'
                      : (locale == 'ar' ? 'تحديث' : 'Update'),
                ),
                onPressed: () {
                  _launchStore();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _launchStore() async {
    // Add logic to open store based on ID
    // For now opening a generic search/url
    // In real app, packageName is used
    final packageInfo = await PackageInfo.fromPlatform();
    final packageName = packageInfo.packageName;

    Uri url;
    if (Platform.isAndroid) {
      url = Uri.parse('market://details?id=$packageName');
    } else {
      url = Uri.parse(
        'https://apps.apple.com/app/idYOUR_APP_ID',
      ); // TODO: Need App ID
    }

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      // Fallback web url
      if (Platform.isAndroid) {
        await launchUrl(
          Uri.parse(
            'https://play.google.com/store/apps/details?id=$packageName',
          ),
        );
      }
    }
  }
}
