import '../../../data/platform/app_lock_channel.dart';

/// Service coordinating native Android Recent Apps Privacy mechanisms:
/// FLAG_SECURE and setRecentsScreenshotEnabled(false) to safeguard app switcher previews.
class RecentAppsPrivacyService {
  Future<void> setRecentAppsPrivacy(bool enabled) async {
    await AppLockChannel.setRecentAppsBlur(enabled);
  }
}
