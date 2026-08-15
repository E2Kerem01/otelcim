import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/constants/categories.dart';
import '../../../shared/constants/listing_filters.dart';
import '../../../shared/services/auth_service.dart';
import '../services/seasonal_service.dart';

class SeasonalCalendarScreen extends ConsumerStatefulWidget {
  const SeasonalCalendarScreen({super.key});

  @override
  ConsumerState<SeasonalCalendarScreen> createState() => _SeasonalCalendarScreenState();
}

class _SeasonalCalendarScreenState extends ConsumerState<SeasonalCalendarScreen> {
  void _openAddSubscriptionModal(BuildContext context, String uid) {
    String? selectedCity;
    String? selectedCategory;
    String selectedSeason = ListingSeason.yaz2025.code;

    unawaited(showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Sezon İlanı Hatırlatıcı Ekle',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(modalContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Sezon başlamadan önce belirlediğiniz şehir ve kategorideki ilanlardan haberdar olun.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String?>(
                      initialValue: selectedCity,
                      decoration: const InputDecoration(
                        labelText: 'Bölge / Şehir',
                        prefixIcon: Icon(Icons.location_city),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Tüm Bölgeler'),
                        ),
                        ...turkishTourismCities.map(
                          (city) => DropdownMenuItem(value: city, child: Text(city)),
                        ),
                      ],
                      onChanged: (val) => setModalState(() => selectedCity = val),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String?>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Kategori',
                        prefixIcon: Icon(Icons.work_outline),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Tüm Kategoriler'),
                        ),
                        ...ListingCategory.values.map(
                          (cat) => DropdownMenuItem(
                            value: cat.name,
                            child: Text(listingCategoryLabels[cat]!),
                          ),
                        ),
                      ],
                      onChanged: (val) => setModalState(() => selectedCategory = val),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: selectedSeason,
                      decoration: const InputDecoration(
                        labelText: 'Hedef Sezon',
                        prefixIcon: Icon(Icons.date_range),
                      ),
                      items: ListingSeason.values.map(
                        (season) => DropdownMenuItem(
                          value: season.code,
                          child: Text(season.label),
                        ),
                      ).toList(),
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
                        label: const Text('Hatırlatıcı Oluştur'),
                        onPressed: () async {
                          await ref.read(seasonalServiceProvider).addSubscription(
                                userId: uid,
                                city: selectedCity,
                                category: selectedCategory,
                                season: selectedSeason,
                              );
                          if (modalContext.mounted) {
                            Navigator.pop(modalContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Sezonluk hatırlatıcı başarıyla oluşturuldu.')),
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
    ));
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final isEn = Localizations.localeOf(context).languageCode == 'en';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEn ? 'Seasonal Hiring Calendar' : 'Sezonluk İşe Alım Takvimi'),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                            isEn ? 'Tourism Season Hiring Periods' : 'Turizm Sezonu İşe Alım Dönemleri',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isEn
                                ? 'Track peak recruitment windows and set alerts for your preferred region & job category.'
                                : 'Yoğun işe alım dönemlerini takip edin ve bölge/kategori bazlı sezon hatırlatıcıları kurun.',
                            style: const TextStyle(fontSize: 12, color: Colors.black87),
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
              isEn ? 'Seasonal Recruitment Windows' : 'Sezonluk İşe Alım Dönemleri',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            ...SeasonalService.seasonalWindows.map(
              (window) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isEn ? window.titleEn : window.titleTr,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.beach_access, size: 20, color: Colors.orange),
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
                                  isEn ? 'Recruitment Peak' : 'İşe Alım Yoğunluğu',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isEn ? window.recruitmentPeriodEn : window.recruitmentPeriodTr,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEn ? 'Active Work Period' : 'Çalışma Dönemi',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isEn ? window.activeMonthsEn : window.activeMonthsTr,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isEn ? window.descriptionEn : window.descriptionTr,
                        style: const TextStyle(fontSize: 13, color: Colors.black87),
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
                    isEn ? 'Seasonal Reminders' : 'Sezonluk Hatırlatıcılarım',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                if (user != null)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(isEn ? 'Add Alert' : 'Ekle'),
                    onPressed: () => _openAddSubscriptionModal(context, user.uid),
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
                      const Icon(Icons.lock_outline, size: 36, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(
                        isEn
                            ? 'Please sign in to set seasonal hiring reminders.'
                            : 'Sezonluk işe alım hatırlatıcıları kurmak için lütfen giriş yapın.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => context.push('/login'),
                        child: Text(isEn ? 'Sign In' : 'Giriş Yap'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Consumer(
                builder: (context, ref, child) {
                  final subsAsync = ref.watch(userSeasonalSubscriptionsProvider(user.uid));

                  return subsAsync.when(
                    data: (subs) {
                      if (subs.isEmpty) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Center(
                              child: Column(
                                children: [
                                  const Icon(Icons.notifications_none, size: 40, color: Colors.grey),
                                  const SizedBox(height: 8),
                                  Text(
                                    isEn
                                        ? 'No active seasonal alerts set yet.'
                                        : 'Henüz kurulmuş bir sezon hatırlatıcısı yok.',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  const SizedBox(height: 12),
                                  FilledButton.icon(
                                    icon: const Icon(Icons.add_alert),
                                    label: Text(isEn ? 'Create First Alert' : 'İlk Hatırlatıcıyı Oluştur'),
                                    onPressed: () => _openAddSubscriptionModal(context, user.uid),
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
                          final seasonLabel = seasonObj?.label ?? sub.season ?? 'Tüm Sezonlar';
                          final cityText = sub.city ?? (isEn ? 'All Regions' : 'Tüm Bölgeler');
                          final catText = sub.category != null
                              ? (listingCategoryLabels[ListingCategory.values.firstWhere(
                                  (c) => c.name == sub.category,
                                  orElse: () => ListingCategory.diger,
                                )] ??
                                  sub.category!)
                              : (isEn ? 'All Categories' : 'Tüm Kategoriler');

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: sub.enabled
                                    ? Theme.of(context).primaryColor.withValues(alpha: 0.15)
                                    : Colors.grey.shade200,
                                child: Icon(
                                  sub.enabled ? Icons.notifications_active : Icons.notifications_off,
                                  color: sub.enabled ? Theme.of(context).primaryColor : Colors.grey,
                                ),
                              ),
                              title: Text('$cityText - $catText'),
                              subtitle: Text(
                                '${isEn ? 'Season' : 'Sezon'}: $seasonLabel',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Switch(
                                    value: sub.enabled,
                                    onChanged: (val) {
                                      unawaited(ref.read(seasonalServiceProvider).toggleSubscription(
                                            userId: user.uid,
                                            subscriptionId: sub.id,
                                            enabled: val,
                                          ));
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () async {
                                      await ref.read(seasonalServiceProvider).deleteSubscription(
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
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Text(isEn ? 'Error loading alerts: $e' : 'Hatırlatıcılar yüklenemedi: $e'),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
