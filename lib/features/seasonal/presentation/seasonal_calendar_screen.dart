import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/categories.dart';
import '../../../shared/constants/listing_filters.dart';
import '../../../shared/services/auth_service.dart';
import '../../listings/presentation/season_utils.dart';
import '../services/seasonal_service.dart';

class SeasonalCalendarScreen extends ConsumerStatefulWidget {
  const SeasonalCalendarScreen({super.key});

  @override
  ConsumerState<SeasonalCalendarScreen> createState() =>
      _SeasonalCalendarScreenState();
}

class _SeasonalCalendarScreenState
    extends ConsumerState<SeasonalCalendarScreen> {
  void _openAddSubscriptionModal(BuildContext context, String uid) {
    String? selectedCity;
    String? selectedCategory;
    String selectedSeason = ListingSeason.values.first.code;

    unawaited(
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (modalContext) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              final l10n = AppLocalizations.of(context)!;
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  MediaQuery.viewInsetsOf(context).bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.coreSeasonalAddAlertTitle,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(modalContext),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.coreSeasonalAddAlertDesc,
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String?>(
                        initialValue: selectedCity,
                        decoration: InputDecoration(
                          labelText: l10n.coreSeasonalRegionCityLabel,
                          prefixIcon: const Icon(Icons.location_city),
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(l10n.coreSeasonalAllRegions),
                          ),
                          ...turkishTourismCities.map(
                            (city) => DropdownMenuItem(
                              value: city,
                              child: Text(city),
                            ),
                          ),
                        ],
                        onChanged: (val) =>
                            setModalState(() => selectedCity = val),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String?>(
                        initialValue: selectedCategory,
                        decoration: InputDecoration(
                          labelText: l10n.coreSeasonalCategoryLabel,
                          prefixIcon: const Icon(Icons.work_outline),
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(l10n.coreSeasonalAllCategories),
                          ),
                          ...ListingCategory.values.map(
                            (cat) => DropdownMenuItem(
                              value: cat.name,
                              child: Text(listingCategoryLabel(cat, l10n)),
                            ),
                          ),
                        ],
                        onChanged: (val) =>
                            setModalState(() => selectedCategory = val),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: selectedSeason,
                        decoration: InputDecoration(
                          labelText: l10n.coreSeasonalTargetSeasonLabel,
                          prefixIcon: const Icon(Icons.date_range),
                        ),
                        items: ListingSeason.values
                            .map(
                              (season) => DropdownMenuItem(
                                value: season.code,
                                child: Text(
                                  listingSeasonLabel(l10n, season.code),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => selectedSeason = val);
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.notifications_active),
                          label: Text(l10n.coreSeasonalCreateAlertAction),
                          onPressed: () async {
                            await ref
                                .read(seasonalServiceProvider)
                                .addSubscription(
                                   userId: uid,
                                   city: selectedCity,
                                   category: selectedCategory,
                                   season: selectedSeason,
                                 );
                            if (modalContext.mounted) {
                              Navigator.pop(modalContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.coreSeasonalAlertCreatedSuccess),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.coreSeasonalCalendarTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Intro Card
            Card(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      size: 40,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.coreSeasonalIntroTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.coreSeasonalIntroDesc,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Seasonal Windows List
            Text(
              l10n.coreSeasonalWindowsHeading,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            ...SeasonalService.seasonalWindows.map(
              (window) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              window.localizedTitle(l10n),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.beach_access,
                            size: 20,
                            color: Colors.orange,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.coreSeasonalRecruitmentPeakLabel,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  window.localizedRecruitmentPeriod(l10n),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.coreSeasonalActivePeriodLabel,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  window.localizedActiveMonths(l10n),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        window.localizedDescription(l10n),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Subscription Section Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.coreSeasonalRemindersHeading,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (user != null)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.coreAddAction),
                    onPressed: () =>
                        _openAddSubscriptionModal(context, user.uid),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (user == null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        size: 36,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.coreSeasonalSignInPrompt,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => context.push('/login'),
                        child: Text(l10n.loginButton),
                      ),
                    ],
                  ),
                ),
              )
            else
              Consumer(
                builder: (context, ref, child) {
                  final subsAsync = ref.watch(
                    userSeasonalSubscriptionsProvider(user.uid),
                  );

                  return subsAsync.when(
                    data: (subs) {
                      if (subs.isEmpty) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Center(
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.notifications_none,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.coreSeasonalNoAlerts,
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  const SizedBox(height: 12),
                                  FilledButton.icon(
                                    icon: const Icon(Icons.add_alert),
                                    label: Text(l10n.coreSeasonalCreateFirstAlert),
                                    onPressed: () => _openAddSubscriptionModal(
                                      context,
                                      user.uid,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: subs.map((sub) {
                          final seasonObj = ListingSeason.fromCode(sub.season);
                          final seasonLabel =
                              seasonObj != null ? listingSeasonLabel(l10n, seasonObj.code) : (sub.season ?? l10n.coreSeasonalAllSeasons);
                          final cityText =
                              sub.city ?? l10n.coreSeasonalAllRegions;
                          final catText = sub.category != null
                              ? localizedListingCategoryName(sub.category!, l10n)
                              : l10n.coreSeasonalAllCategories;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: sub.enabled
                                    ? Theme.of(
                                        context,
                                      ).primaryColor.withValues(alpha: 0.15)
                                    : Colors.grey.shade200,
                                child: Icon(
                                  sub.enabled
                                      ? Icons.notifications_active
                                      : Icons.notifications_off,
                                  color: sub.enabled
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey,
                                ),
                              ),
                              title: Text('$cityText - $catText'),
                              subtitle: Text(
                                '${l10n.coreSeasonLabel}: $seasonLabel',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Switch(
                                    value: sub.enabled,
                                    onChanged: (val) {
                                      unawaited(
                                        ref
                                            .read(seasonalServiceProvider)
                                            .toggleSubscription(
                                              userId: user.uid,
                                              subscriptionId: sub.id,
                                              enabled: val,
                                            ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () async {
                                      await ref
                                          .read(seasonalServiceProvider)
                                          .deleteSubscription(
                                            userId: user.uid,
                                            subscriptionId: sub.id,
                                          );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Text(
                      l10n.coreSeasonalAlertsLoadError('$e'),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
