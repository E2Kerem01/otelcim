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
          const SnackBar(
            content: Text('Bildirim tercihleri güncellendi.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'NotificationSettingsScreen._updatePreference');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mapToFailure(error).message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _selectQuietHour(
    BuildContext context,
    bool isStart,
    UserProfile profile,
  ) async {
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
          ? 'Sessiz Saat Başlangıcı Seçin'
          : 'Sessiz Saat Bitişi Seçin',
      confirmText: 'SEÇ',
      cancelText: 'İPTAL',
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
            const SnackBar(
              content: Text('Sessiz saatler güncellendi.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (error, stackTrace) {
        logError(error, stackTrace, context: 'NotificationSettingsScreen._selectQuietHour');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(mapToFailure(error).message),
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
          const SnackBar(
            content: Text('Sessiz saatler temizlendi.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'NotificationSettingsScreen._clearQuietHours');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(mapToFailure(error).message)));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bildirim Ayarları')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Hata: $err')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Kullanıcı profili bulunamadı.'));
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
                        const Expanded(
                          child: Text(
                            'Almak istediğiniz bildirim türlerini ve sessiz saatlerinizi buradan yönetebilirsiniz.',
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
                  'Bildirim Tercihleri',
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
                        title: const Text(
                          'Mesajlar',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: const Text(
                          'Yeni sohbet mesajları için bildirim al',
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
                        title: const Text(
                          'İlan Bildirimleri',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: const Text(
                          'İlgilendiğiniz kategorilerde yeni ilanlar eklendiğinde haberiniz olsun',
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
                        title: const Text(
                          'Sezonluk Hatırlatıcılar',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: const Text(
                          'Sezonluk iş fırsatları ve öne çıkan dönemler hakkında bilgilendirmeler',
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
                          AppLocalizations.of(
                            context,
                          )!.urgentNotificationsTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          AppLocalizations.of(
                            context,
                          )!.urgentNotificationsDescription,
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
                        title: const Text(
                          'Pazarlama ve Duyurular',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: const Text(
                          'Kampanyalar, yenilikler ve özel teklifler hakkında bilgi al',
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
                  'Sessiz Saatler (Quiet Hours)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Belirlediğiniz zaman diliminde rahatsız edilmemek için sessiz saatler ayarlayabilirsiniz.',
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
                        title: const Text('Sessiz Saat Başlangıcı'),
                        subtitle: Text(
                          profile.quietHoursStart ?? 'Belirtilmedi',
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
                        onTap: () => _selectQuietHour(context, true, profile),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.wb_sunny_outlined,
                          color: Colors.orange,
                        ),
                        title: const Text('Sessiz Saat Bitişi'),
                        subtitle: Text(
                          profile.quietHoursEnd ?? 'Belirtilmedi',
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
                        onTap: () => _selectQuietHour(context, false, profile),
                      ),
                      if (hasQuietHours) ...[
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(
                            Icons.clear_rounded,
                            color: Colors.red,
                          ),
                          title: const Text(
                            'Sessiz Saatleri Temizle',
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
