import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/categories.dart';
import '../../../shared/constants/listing_filters.dart';
import '../../../shared/models/report.dart';
import '../../../shared/services/analytics_service.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/chat_service.dart';
import '../../../shared/services/listing_service.dart';
import '../../../shared/widgets/report_dialog.dart';
import '../../boosts/presentation/widgets/boost_badge.dart';
import '../../chat/presentation/widgets/message_template_sheet.dart';
import '../../favorites/services/favorite_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../domain/listing_model.dart';
import 'listing_requirement_labels.dart';
import 'whatsapp_utils.dart';

final _listingProvider = FutureProvider.family<Listing?, String>((
  ref,
  listingId,
) {
  return ref.watch(listingServiceProvider).getListing(listingId);
});

class ListingDetailScreen extends ConsumerStatefulWidget {
  const ListingDetailScreen({super.key, required this.listingId});

  final String listingId;

  @override
  ConsumerState<ListingDetailScreen> createState() =>
      _ListingDetailScreenState();
}

class _ListingDetailScreenState extends ConsumerState<ListingDetailScreen> {
  bool _startingChat = false;
  bool _revealContactInfo = false;

  Future<void> _messageOwner(Listing listing) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mesaj göndermek için lütfen giriş yapın.'),
          ),
        );
        context.push('/login');
      }
      return;
    }

    if (listing.posterId == user.uid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kendi ilanınıza mesaj gönderemezsiniz.'),
          ),
        );
      }
      return;
    }

    setState(() => _startingChat = true);
    try {
      final result = await ref
          .read(chatServiceProvider)
          .getOrCreateConversation(
            listingId: listing.id,
            listingTitle: listing.title,
            posterId: listing.posterId,
            seekerId: user.uid,
          );
      if (!mounted) return;

      String? prefillText;
      if (result.isNew) {
        prefillText = await MessageTemplateSheet.show(
          context,
          listingTitle: listing.title,
        );
      }
      if (mounted)
        context.push('/chat/${result.conversationId}', extra: prefillText);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sohbet başlatılamadı: $e')));
      }
    } finally {
      if (mounted) setState(() => _startingChat = false);
    }
  }

  Future<void> _openWhatsApp(Listing listing) async {
    final phone = parsePhoneNumber(listing.contactInfo);
    if (phone == null) return;
    final localeCode = Localizations.localeOf(context).languageCode;
    final url = buildWhatsAppUrl(
      phone: phone,
      listingTitle: listing.title,
      posterName: listing.posterName,
      languageCode: localeCode,
    );
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.whatsappNotInstalled),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('WhatsApp açılamadı: $e')));
      }
    }
  }

  Future<void> _shareListing(Listing listing) async {
    final text =
        '''
${listing.title}

📍 ${listing.location}
💰 ${listing.salary}
📂 ${listingCategoryLabel(listing.category)}

${listing.description}

İletişim: ${listing.posterName}
${listing.contactInfo}

🔗 Otelcim Uygulamasını İndir: https://otelcim.app
''';

    try {
      await SharePlus.instance.share(
        ShareParams(text: text, subject: listing.title),
      );
      await ref
          .read(analyticsServiceProvider)
          .logShareListing(
            listingId: listing.id,
            listingTitle: listing.title,
            category: listing.category,
            location: listing.location,
          );
    } catch (e) {
      debugPrint('Error sharing listing: $e');
    }
  }

  void _showReportDialog(Listing listing) {
    showDialog(
      context: context,
      builder: (context) => ReportDialog(
        targetType: ReportTargetType.listing,
        targetId: listing.id,
        targetName: listing.title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listingAsync = ref.watch(_listingProvider(widget.listingId));
    final myUid = ref.watch(authStateProvider).value?.uid;
    final isFavorite = myUid == null
        ? false
        : ref
                  .watch(favoriteIdsProvider(myUid))
                  .valueOrNull
                  ?.contains(widget.listingId) ??
              false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('İlan Detayı'),
        actions: [
          AnimatedScale(
            scale: isFavorite ? 1.15 : 1,
            duration: const Duration(milliseconds: 180),
            child: IconButton(
              tooltip: isFavorite ? 'Favorilerden çıkar' : 'Favorilere ekle',
              onPressed: () {
                if (myUid == null) {
                  context.push('/login');
                  return;
                }
                ref
                    .read(favoriteServiceProvider)
                    .toggleFavorite(myUid, widget.listingId);
              },
              icon: Icon(
                isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: isFavorite ? Colors.red : null,
              ),
            ),
          ),
          listingAsync.maybeWhen(
            data: (listing) {
              if (listing == null) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () => _shareListing(listing),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          listingAsync.maybeWhen(
            data: (listing) {
              if (listing == null || listing.posterId == myUid)
                return const SizedBox.shrink();
              return PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'report') {
                    _showReportDialog(listing);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'report',
                    child: Row(
                      children: [
                        Icon(Icons.flag_outlined, color: Colors.red),
                        SizedBox(width: 12),
                        Text('İlanı Bildir'),
                      ],
                    ),
                  ),
                ],
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: listingAsync.when(
        data: (listing) {
          if (listing == null) {
            return const Center(child: Text('İlan bulunamadı.'));
          }
          final isBoostedActive = BoostBadge.isBoostActive(listing);
          final experience = ExperienceLevel.fromName(listing.experienceLevel);
          final education = EducationLevel.fromName(listing.educationLevel);
          final l10n = AppLocalizations.of(context)!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ListingImageGallery(listing: listing),
                Row(
                  children: [
                    Chip(
                      label: Text(listingCategoryLabel(listing.category)),
                      backgroundColor: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.1),
                      side: BorderSide.none,
                    ),
                    if (isBoostedActive) ...[
                      const SizedBox(width: 8),
                      const BoostBadge(isCompact: false),
                    ],
                    const Spacer(),
                    if (listing.createdAt != null)
                      Text(
                        '${listing.createdAt!.day}.${listing.createdAt!.month}.${listing.createdAt!.year}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  listing.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      listing.location,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Maaş',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        listing.salary,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (experience != null || education != null) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (experience != null)
                            _RequirementRow(
                              icon: Icons.work_history_outlined,
                              label: l10n.experienceLevelLabel,
                              value: experienceLevelLabel(l10n, experience),
                            ),
                          if (experience != null && education != null)
                            const Divider(height: 24),
                          if (education != null)
                            _RequirementRow(
                              icon: Icons.school_outlined,
                              label: l10n.educationLevelLabel,
                              value: educationLevelLabel(l10n, education),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                const Text(
                  'İlan Açıklaması',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  listing.description,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
                if (listing.housingRoomType != null ||
                    listing.housingHasAc != null ||
                    listing.housingHasWifi != null ||
                    listing.housingMealsIncluded != null ||
                    listing.housingImages.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.home_work_outlined),
                              const SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(context)!.housingTitle,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (listing.housingRoomType != null)
                                Chip(
                                  avatar: const Icon(
                                    Icons.bed_outlined,
                                    size: 18,
                                  ),
                                  label: Text(
                                    listing.housingRoomType == 'single'
                                        ? AppLocalizations.of(
                                            context,
                                          )!.housingSingleRoom
                                        : AppLocalizations.of(
                                            context,
                                          )!.housingSharedRoom,
                                  ),
                                ),
                              if (listing.housingHasAc == true)
                                Chip(
                                  avatar: const Icon(
                                    Icons.ac_unit_outlined,
                                    size: 18,
                                  ),
                                  label: Text(
                                    AppLocalizations.of(context)!.housingHasAc,
                                  ),
                                ),
                              if (listing.housingHasWifi == true)
                                Chip(
                                  avatar: const Icon(Icons.wifi, size: 18),
                                  label: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.housingHasWifi,
                                  ),
                                ),
                              if (listing.housingMealsIncluded != null)
                                Chip(
                                  avatar: const Icon(
                                    Icons.restaurant_outlined,
                                    size: 18,
                                  ),
                                  label: Text(
                                    '${AppLocalizations.of(context)!.housingMealsIncluded}: '
                                    '${listing.housingMealsIncluded}',
                                  ),
                                ),
                            ],
                          ),
                          if (listing.housingImages.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 120,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: listing.housingImages.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (context, index) => ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: CachedNetworkImage(
                                    imageUrl: listing.housingImages[index],
                                    width: 160,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, _, _) =>
                                        const Icon(Icons.broken_image),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            listing.posterName.isNotEmpty
                                ? listing.posterName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                listing.posterName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'İlan Sahibi',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (myUid == null)
                                InkWell(
                                  onTap: () => context.push('/login'),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.lock_outline,
                                        size: 14,
                                        color: Colors.orange.shade800,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'İletişim bilgisini görmek için giriş yapın',
                                          style: TextStyle(
                                            color: Colors.orange.shade800,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else if (myUid == listing.posterId ||
                                  _revealContactInfo)
                                Text(
                                  listing.contactInfo,
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 13,
                                  ),
                                )
                              else
                                InkWell(
                                  onTap: () =>
                                      setState(() => _revealContactInfo = true),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.visibility_outlined,
                                        size: 14,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'İletişim Bilgisini Göster',
                                        style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          color: Theme.of(
                            context,
                          ).colorScheme.onTertiaryContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.listingSafetyTipsTitle,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onTertiaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.listingSafetyTipsBody,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onTertiaryContainer,
                                      height: 1.4,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              TextButton.icon(
                                onPressed: () => _showReportDialog(listing),
                                icon: const Icon(Icons.flag_outlined),
                                label: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.listingSafetyReportAction,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Hata: $error')),
      ),
      bottomNavigationBar: listingAsync.maybeWhen(
        data: (listing) {
          if (listing == null) return null;
          final isOwner = myUid == listing.posterId;
          final l10n = AppLocalizations.of(context)!;

          if (isOwner) {
            final isBoostedActive = BoostBadge.isBoostActive(listing);
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          context.push('/listing/${listing.id}/boost'),
                      icon: const Icon(Icons.rocket_launch_rounded),
                      label: Text(
                        isBoostedActive ? 'Öne Çıkarma' : 'İlanı Öne Çıkar',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          context.push('/listing/${listing.id}/qr-poster'),
                      icon: const Icon(Icons.qr_code_2_rounded),
                      label: Text(l10n.createQrPosterAction),
                    ),
                  ),
                ],
              ),
            );
          }

          final phone = parsePhoneNumber(listing.contactInfo);
          final hasWhatsApp = phone != null;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _startingChat
                        ? null
                        : () => _messageOwner(listing),
                    icon: const Icon(Icons.message_outlined),
                    label: const Text('Mesaj Gönder'),
                  ),
                ),
                if (hasWhatsApp) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openWhatsApp(listing),
                      icon: const Icon(Icons.chat_rounded),
                      label: Text(l10n.sendWhatsAppAction),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
        orElse: () => null,
      ),
    );
  }
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 2),
              Text(value, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }
}

class _ListingImageGallery extends StatefulWidget {
  final Listing listing;

  const _ListingImageGallery({required this.listing});

  @override
  State<_ListingImageGallery> createState() => _ListingImageGalleryState();
}

class _ListingImageGalleryState extends State<_ListingImageGallery> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.listing.images.isEmpty) {
      final categoryEnum = ListingCategory.values.firstWhere(
        (c) => c.name == widget.listing.category,
        orElse: () => ListingCategory.diger,
      );
      final categoryIcon = listingCategoryIcons[categoryEnum] ?? Icons.hotel;

      return Container(
        width: double.infinity,
        height: 180,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                categoryIcon,
                size: 56,
                color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 8),
              Text(
                listingCategoryLabels[categoryEnum] ?? 'Otelcim İlanı',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 220,
      margin: const EdgeInsets.only(bottom: 16),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: PageView.builder(
              itemCount: widget.listing.images.length,
              onPageChanged: (idx) => setState(() => _currentIndex = idx),
              itemBuilder: (context, idx) {
                return CachedNetworkImage(
                  imageUrl: widget.listing.images[idx],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(
                      Icons.broken_image,
                      size: 40,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
            ),
          ),
          if (widget.listing.images.length > 1)
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.listing.images.length,
                  (index) => Container(
                    width: _currentIndex == index ? 10 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: _currentIndex == index
                          ? Colors.white
                          : Colors.white54,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
