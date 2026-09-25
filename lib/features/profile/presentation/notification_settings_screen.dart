import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/error/error_mapper.dart';
import '../../../shared/error/error_reporter.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/providers/profile_provider.dart';
import '../../../shared/services/notification_service.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _isSaving = false;

  Future<void> _updatePreference(
    String key,
    bool value,
    UserProfile profile,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final currentPrefs = Map<String, bool>.from(
      profile.notificationPreferences,
    );
    currentPrefs[key] = value;

    final updatedProfile = profile.copyWith(
      notificationPreferences: currentPrefs,
      updatedAt: DateTime.now(),
    );

    setState(() => _isSaving = true);
    try {
      await ref.read(profileServiceProvider).updateUserProfile(updatedProfile);
      if (key == 'urgentListings') {
        await ref
            .read(notificationServiceProvider)
            .setUrgentListingsPreference(value);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.notificationsUpdatedMessage),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'NotificationSettingsScreen._updatePreference');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mapToFailure(error, l10n).message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _selectQuietHour(
    bool isStart,
    UserProfile profile,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final currentString = isStart
        ? profile.quietHoursStart
        : profile.quietHoursEnd;
    TimeOfDay initialTime = isStart
        ? const TimeOfDay(hour: 22, minute: 0)
        : const TimeOfDay(hour: 8, minute: 0);

    if (currentString != null && currentString.contains(':')) {
      final parts = currentString.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour != null && minute != null) {
          initialTime = TimeOfDay(hour: hour, minute: minute);
        }
      }
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: isStart
          ? l10n.quietHoursStartPickerTitle
          : l10n.quietHoursEndPickerTitle,
      confirmText: l10n.selectSlot,
      cancelText: l10n.cancelButton,
    );

    if (picked != null) {
      final formattedHour = picked.hour.toString().padLeft(2, '0');
      final formattedMinute = picked.minute.toString().padLeft(2, '0');
      final formatted = '$formattedHour:$formattedMinute';

      final updatedProfile = profile.copyWith(
        quietHoursStart: isStart ? formatted : profile.quietHoursStart,
        quietHoursEnd: isStart ? profile.quietHoursEnd : formatted,
        updatedAt: DateTime.now(),
      );

      setState(() => _isSaving = true);
      try {
        await ref
            .read(profileServiceProvider)
            .updateUserProfile(updatedProfile);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.quietHoursUpdatedMessage),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (error, stackTrace) {
        logError(error, stackTrace, context: 'NotificationSettingsScreen._selectQuietHour');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(mapToFailure(error, l10n).message),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  Future<void> _clearQuietHours(UserProfile profile) async {
    final l10n = AppLocalizations.of(context)!;
    final updatedProfile = profile.copyWith(
      quietHoursStart: null,
      quietHoursEnd: null,
      updatedAt: DateTime.now(),
    );

    setState(() => _isSaving = true);
    try {
      await ref.read(profileServiceProvider).updateUserProfile(updatedProfile);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.quietHoursClearedMessage),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'NotificationSettingsScreen._clearQuietHours');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(mapToFailure(error, l10n).message)));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notificationsTitle)),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text(l10n.notificationsLoadError)),
        data: (profile) {
          if (profile == null) {
            return Center(child: Text(l10n.profileNotFoundError));
          }

          final prefs = profile.notificationPreferences;
          final messagesEnabled = prefs['messages'] ?? true;
          final listingAlertsEnabled = prefs['listingAlerts'] ?? true;
          final seasonalRemindersEnabled = prefs['seasonalReminders'] ?? false;
          final urgentListingsEnabled = prefs['urgentListings'] ?? true;
          final marketingEnabled = prefs['marketing'] ?? false;

          final hasQuietHours =
              profile.quietHoursStart != null || profile.quietHoursEnd != null;

          return IgnorePointer(
            ignoring: _isSaving,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Info Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notifications_active_outlined,
                          color: Theme.of(context).primaryColor,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.notificationsDescription,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Category Title
                Text(
                  l10n.notificationPreferencesTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 10),

                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: Theme.of(context).primaryColor,
                        ),
                        title: Text(
                          l10n.notificationMessagesTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          l10n.notificationMessagesSubtitle,
                        ),
                        value: messagesEnabled,
                        onChanged: (val) =>
                            _updatePreference('messages', val, profile),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: Icon(
                          Icons.notifications_active_outlined,
                          color: Theme.of(context).primaryColor,
                        ),
                        title: Text(
                          l10n.notificationListingsTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          l10n.notificationListingsSubtitle,
                        ),
                        value: listingAlertsEnabled,
                        onChanged: (val) =>
                            _updatePreference('listingAlerts', val, profile),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: Icon(
                          Icons.calendar_month_outlined,
                          color: Theme.of(context).primaryColor,
                        ),
                        title: Text(
                          l10n.notificationSeasonalTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          l10n.notificationSeasonalSubtitle,
                        ),
                        value: seasonalRemindersEnabled,
                        onChanged: (val) => _updatePreference(
                          'seasonalReminders',
                          val,
                          profile,
                        ),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: Icon(
                          Icons.bolt,
                          color: Colors.deepOrange.shade700,
                        ),
                        title: Text(
                          l10n.urgentNotificationsTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          l10n.urgentNotificationsDescription,
                        ),
                        value: urgentListingsEnabled,
                        onChanged: (val) =>
                            _updatePreference('urgentListings', val, profile),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: Icon(
                          Icons.campaign_outlined,
                          color: Theme.of(context).primaryColor,
                        ),
                        title: Text(
                          l10n.notificationMarketingTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          l10n.notificationMarketingSubtitle,
                        ),
                        value: marketingEnabled,
                        onChanged: (val) =>
                            _updatePreference('marketing', val, profile),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Quiet Hours Section Title
                Text(
                  l10n.quietHoursSectionTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.quietHoursDescription,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 10),

                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.bedtime_outlined,
                          color: Colors.indigo,
                        ),
                        title: Text(l10n.quietHoursStartTitle),
                        subtitle: Text(
                          profile.quietHoursStart ?? l10n.notSpecified,
                          style: TextStyle(
                            fontWeight: profile.quietHoursStart != null
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: profile.quietHoursStart != null
                                ? Colors.black87
                                : Colors.grey,
                          ),
                        ),
                        trailing: const Icon(Icons.access_time_rounded),
                        onTap: () => _selectQuietHour(true, profile),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.wb_sunny_outlined,
                          color: Colors.orange,
                        ),
                        title: Text(l10n.quietHoursEndTitle),
                        subtitle: Text(
                          profile.quietHoursEnd ?? l10n.notSpecified,
                          style: TextStyle(
                            fontWeight: profile.quietHoursEnd != null
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: profile.quietHoursEnd != null
                                ? Colors.black87
                                : Colors.grey,
                          ),
                        ),
                        trailing: const Icon(Icons.access_time_rounded),
                        onTap: () => _selectQuietHour(false, profile),
                      ),
                      if (hasQuietHours) ...[
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(
                            Icons.clear_rounded,
                            color: Colors.red,
                          ),
                          title: Text(
                            l10n.clearQuietHoursAction,
                            style: TextStyle(color: Colors.red),
                          ),
                          onTap: () => _clearQuietHours(profile),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
