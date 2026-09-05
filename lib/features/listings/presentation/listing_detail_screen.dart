import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/categories.dart';
import '../../../shared/constants/listing_filters.dart';
import '../../../shared/error/error_mapper.dart';
import '../../../shared/error/error_reporter.dart';
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
import 'whatsapp_utils.dart';
import 'widgets/listing_detail_widgets.dart';

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
        unawaited(context.push('/login'));
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
      if (mounted) {
        unawaited(
          context.push('/chat/${result.conversationId}', extra: prefillText),
        );
      }
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'ListingDetailScreen._messageOwner');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(mapToFailure(error).message)));
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
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'ListingDetailScreen._openWhatsApp');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(mapToFailure(error).message)));
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

İlan sahibi: ${listing.posterName}
İletişim bilgilerini görmek ve başvurmak için Otelcim'de giriş yapın.

🔗 https://otelcim.vercel.app/#/listing/${listing.id}
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
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'ListingDetailScreen._shareListing');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mapToFailure(error).message)),
        );
      }
    }
  }

  void _showReportDialog(Listing listing) {
    unawaited(showDialog(
      context: context,
      builder: (context) => ReportDialog(
        targetType: ReportTargetType.listing,
        targetId: listing.id,
        targetName: listing.title,
      ),
    ));
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
                  unawaited(context.push('/login'));
                  return;
                }
                unawaited(ref
                    .read(favoriteServiceProvider)
                    .toggleFavorite(myUid, widget.listingId));
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
              if (listing == null || listing.posterId == myUid) {
                return const SizedBox.shrink();
              }
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
          final hasHousing = listing.housingRoomType != null ||
              listing.housingHasAc != null ||
              listing.housingHasWifi != null ||
              listing.housingMealsIncluded != null ||
              listing.housingImages.isNotEmpty;
          final hasShuttle = listing.staffShuttleRoute?.trim().isNotEmpty ==
              true;

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 800;

              if (isWide) {
                return Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1140),
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListingImageGallery(listing: listing),
                                  ListingHeaderInfo(listing: listing, isBoostedActive: isBoostedActive),
                                  const SizedBox(height: 16),
                                  if (experience != null || education != null) ...[
                                    ListingRequirementsCard(
                                      experience: experience,
                                      education: education,
                                      l10n: l10n,
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                  ListingDescriptionSection(listing: listing),
                                  if (hasHousing) ...[
                                    const SizedBox(height: 20),
                                    ListingHousingCard(listing: listing, l10n: l10n),
                                  ],
                                  if (hasShuttle) ...[
                                    const SizedBox(height: 20),
                                    ListingStaffShuttleCard(
                                      listing: listing,
                                      l10n: l10n,
                                    ),
                                  ],
                                  const SizedBox(height: 24),
                                  ListingPosterCard(
                                    listing: listing,
                                    myUid: myUid,
                                    revealContactInfo: _revealContactInfo,
                                    onRevealContact: () =>
                                        setState(() => _revealContactInfo = true),
                                  ),
                                  const SizedBox(height: 12),
                                  ListingSafetyTipsCard(
                                    l10n: l10n,
                                    onReport: () => _showReportDialog(listing),
                                  ),
                                  const SizedBox(height: 40),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 360,
                          child: ListingRightStickyActionCard(
                            listing: listing,
                            myUid: myUid,
                            startingChat: _startingChat,
                            revealContactInfo: _revealContactInfo,
                            onMessageOwner: () => _messageOwner(listing),
                            onOpenWhatsApp: () => _openWhatsApp(listing),
                            onRevealContact: () =>
                                setState(() => _revealContactInfo = true),
                            onReport: () => _showReportDialog(listing),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListingImageGallery(listing: listing),
                    ListingHeaderInfo(listing: listing, isBoostedActive: isBoostedActive),
                    const SizedBox(height: 16),
                    ListingSalaryCard(listing: listing),
                    if (experience != null || education != null) ...[
                      const SizedBox(height: 12),
                      ListingRequirementsCard(
                        experience: experience,
                        education: education,
                        l10n: l10n,
                      ),
                    ],
                    const SizedBox(height: 24),
                    ListingDescriptionSection(listing: listing),
                    if (hasHousing) ...[
                      const SizedBox(height: 20),
                      ListingHousingCard(listing: listing, l10n: l10n),
                    ],
                    if (hasShuttle) ...[
                      const SizedBox(height: 20),
                      ListingStaffShuttleCard(listing: listing, l10n: l10n),
                    ],
                    const SizedBox(height: 24),
                    ListingPosterCard(
                      listing: listing,
                      myUid: myUid,
                      revealContactInfo: _revealContactInfo,
                      onRevealContact: () =>
                          setState(() => _revealContactInfo = true),
                    ),
                    const SizedBox(height: 12),
                    ListingSafetyTipsCard(
                      l10n: l10n,
                      onReport: () => _showReportDialog(listing),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Hata: $error')),
      ),
      bottomNavigationBar: MediaQuery.sizeOf(context).width >= 800
          ? null
          : listingAsync.maybeWhen(
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
                              isBoostedActive
                                  ? 'Öne Çıkarma'
                                  : 'İlanı Öne Çıkar',
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
                            onPressed: () => context
                                .push('/listing/${listing.id}/qr-poster'),
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
