import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/design_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/app_localizations_tr.dart';
import '../../../../shared/constants/categories.dart';
import '../../../../shared/constants/listing_filters.dart';
import '../../../../shared/error/error_mapper.dart';
import '../../../../shared/error/error_reporter.dart';
import '../../../../shared/services/analytics_service.dart';
import '../../../../shared/services/auth_service.dart';
import '../../../../shared/services/chat_service.dart';
import '../../../../shared/services/listing_service.dart';
import '../../../boosts/presentation/widgets/boost_badge.dart';
import '../../../chat/presentation/widgets/message_template_sheet.dart';
import '../../../favorites/services/favorite_service.dart';
import '../../domain/listing_model.dart';
import '../whatsapp_utils.dart';
import 'listing_detail_widgets.dart';

/// Helper to dynamically resolve localized strings added for the preview pane
/// with graceful fallback if the coordinator has not yet regenerated
/// AppLocalizations.
String _previewString(AppLocalizations? l10n, String key, String fallback) {
  if (l10n != null) {
    try {
      final dyn = l10n;
      switch (key) {
        case 'openFullPage':
          return dyn.listingPreviewOpenFullPage;
        case 'close':
          return dyn.listingPreviewClose;
        case 'showMore':
          return dyn.listingPreviewShowMore;
        case 'showLess':
          return dyn.listingPreviewShowLess;
        case 'notFound':
          return dyn.listingPreviewNotFound;
        case 'editListing':
          return dyn.listingPreviewEditListing;
        case 'loginToContact':
          return dyn.listingPreviewLoginToContact;
        case 'sendMessage':
          return dyn.listingPreviewSendMessage;
        case 'error':
          return dyn.listingPreviewError;
        case 'retry':
          return dyn.listingPreviewRetry;
      }
    } catch (_) {}
  }
  return fallback;
}

/// A ~440px-wide right-hand preview of a job listing, shown next to the feed
/// on desktop.
class ListingPreviewPane extends ConsumerStatefulWidget {
  const ListingPreviewPane({
    super.key,
    required this.listingId,
    this.onClose,
  });

  final String listingId;
  final VoidCallback? onClose;

  @override
  ConsumerState<ListingPreviewPane> createState() => _ListingPreviewPaneState();
}

class _ListingPreviewPaneState extends ConsumerState<ListingPreviewPane> {
  final ScrollController _scrollController = ScrollController();
  bool _startingChat = false;
  bool _revealContactInfo = false;
  bool _isDescriptionExpanded = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
      logError(error, stackTrace, context: 'ListingPreviewPane._messageOwner');
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
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n?.whatsappNotInstalled ?? 'WhatsApp yüklü değil.',
              ),
            ),
          );
        }
      }
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'ListingPreviewPane._openWhatsApp');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(mapToFailure(error).message)));
      }
    }
  }

  Future<void> _shareListing(Listing listing) async {
    final text = '''
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
      logError(error, stackTrace, context: 'ListingPreviewPane._shareListing');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mapToFailure(error).message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final myUid = ref.watch(authStateProvider).valueOrNull?.uid;
    final listingAsync = ref.watch(singleListingProvider(widget.listingId));

    return Container(
      width: 440,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.outlineVariant, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: listingAsync.when(
        loading: () => _buildLoadingState(colorScheme, l10n),
        error: (error, stack) => _buildErrorState(colorScheme, l10n, error),
        data: (listing) {
          if (listing == null ||
              listing.status == ListingStatus.removed ||
              listing.status == ListingStatus.closed) {
            return _buildNotFoundState(colorScheme, l10n);
          }
          return _buildLoadedState(context, listing, myUid, colorScheme, l10n);
        },
      ),
    );
  }

  Widget _buildLoadingState(
    ColorScheme colorScheme,
    AppLocalizations? l10n,
  ) {
    return Column(
      children: [
        if (widget.onClose != null)
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: IconButton(
                key: const Key('listing_preview_close_button'),
                icon: Icon(
                  Icons.close_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
                tooltip: _previewString(l10n, 'close', 'Önizlemeyi kapat'),
                onPressed: widget.onClose,
              ),
            ),
          ),
        const Expanded(
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(
    ColorScheme colorScheme,
    AppLocalizations? l10n,
    Object error,
  ) {
    return Column(
      children: [
        if (widget.onClose != null)
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: IconButton(
                key: const Key('listing_preview_close_button'),
                icon: Icon(
                  Icons.close_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
                tooltip: _previewString(l10n, 'close', 'Önizlemeyi kapat'),
                onPressed: widget.onClose,
              ),
            ),
          ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 44,
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _previewString(
                      l10n,
                      'error',
                      'İlan yüklenirken bir hata oluştu',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: () => ref.invalidate(
                      singleListingProvider(widget.listingId),
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(
                      _previewString(l10n, 'retry', 'Tekrar dene'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotFoundState(
    ColorScheme colorScheme,
    AppLocalizations? l10n,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'İlan bulunamadı.',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              if (widget.onClose != null)
                IconButton(
                  key: const Key('listing_preview_close_button'),
                  icon: Icon(
                    Icons.close_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  tooltip: _previewString(l10n, 'close', 'Önizlemeyi kapat'),
                  onPressed: widget.onClose,
                ),
            ],
          ),
        ),
        Divider(height: 1, thickness: 1, color: colorScheme.outlineVariant),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 48,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'İlan bulunamadı.',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _previewString(
                      l10n,
                      'notFound',
                      'İlan bulunamadı veya kaldırılmış',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadedState(
    BuildContext context,
    Listing listing,
    String? myUid,
    ColorScheme colorScheme,
    AppLocalizations? l10n,
  ) {
    final isFavorite = myUid == null
        ? false
        : ref
                  .watch(favoriteIdsProvider(myUid))
                  .valueOrNull
                  ?.contains(widget.listingId) ??
              false;

    final isBoostedActive = BoostBadge.isBoostActive(listing);
    final experience = ExperienceLevel.fromName(listing.experienceLevel);
    final education = EducationLevel.fromName(listing.educationLevel);
    final hasHousing = listing.housingRoomType != null ||
        listing.housingHasAc != null ||
        listing.housingHasWifi != null ||
        listing.housingMealsIncluded != null ||
        listing.housingImages.isNotEmpty;
    final hasShuttle = listing.staffShuttleRoute?.trim().isNotEmpty == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Pinned Header Row
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          color: colorScheme.surface,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      listing.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (listing.posterName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        listing.posterName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                iconSize: 20,
                tooltip: isFavorite
                    ? (l10n?.removeFromFavorites ?? 'Favorilerden çıkar')
                    : (l10n?.addToFavorites ?? 'Favorilere ekle'),
                onPressed: () {
                  if (myUid == null) {
                    unawaited(context.push('/login'));
                    return;
                  }
                  unawaited(
                    ref
                        .read(favoriteServiceProvider)
                        .toggleFavorite(myUid, listing.id),
                  );
                },
                icon: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFavorite
                      ? colorScheme.error
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              IconButton(
                iconSize: 20,
                tooltip: l10n?.shareCodeAction ?? 'Paylaş',
                icon: Icon(
                  Icons.share_outlined,
                  color: colorScheme.onSurfaceVariant,
                ),
                onPressed: () => _shareListing(listing),
              ),
              IconButton(
                key: const Key('listing_preview_open_full_page_button'),
                iconSize: 20,
                tooltip: _previewString(
                  l10n,
                  'openFullPage',
                  'Tam sayfada aç',
                ),
                icon: Icon(
                  Icons.open_in_new_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
                onPressed: () => context.push('/listing/${listing.id}'),
              ),
              if (widget.onClose != null)
                IconButton(
                  key: const Key('listing_preview_close_button'),
                  iconSize: 20,
                  tooltip: _previewString(
                    l10n,
                    'close',
                    'Önizlemeyi kapat',
                  ),
                  icon: Icon(
                    Icons.close_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onPressed: widget.onClose,
                ),
            ],
          ),
        ),
        Divider(height: 1, thickness: 1, color: colorScheme.outlineVariant),

        // 2. Independently scrollable body
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // First image if present
                  if (listing.images.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: CachedNetworkImage(
                        imageUrl: listing.images.first,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 180,
                          color: colorScheme.surfaceContainerHighest,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 180,
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 40,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Header Info
                  ListingHeaderInfo(
                    listing: listing,
                    isBoostedActive: isBoostedActive,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Salary Card
                  ListingSalaryCard(listing: listing),
                  const SizedBox(height: AppSpacing.lg),

                  // Requirements Card
                  if (experience != null || education != null) ...[
                    ListingRequirementsCard(
                      experience: experience,
                      education: education,
                      l10n: l10n ?? AppLocalizationsTr(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Description Section (clamped to ~8 lines with toggle)
                  ListingDescriptionSection(
                    listing: listing,
                    maxLines: _isDescriptionExpanded ? null : 8,
                    isExpanded: _isDescriptionExpanded,
                    onToggleExpand: () {
                      setState(() {
                        _isDescriptionExpanded = !_isDescriptionExpanded;
                      });
                    },
                    expandLabel: _previewString(
                      l10n,
                      'showMore',
                      'Devamını gör',
                    ),
                    collapseLabel: _previewString(
                      l10n,
                      'showLess',
                      'Daha az göster',
                    ),
                  ),

                  // Housing Card
                  if (hasHousing) ...[
                    const SizedBox(height: AppSpacing.lg),
                    ListingHousingCard(
                      listing: listing,
                      l10n: l10n ?? AppLocalizationsTr(),
                    ),
                  ],

                  // Staff Shuttle Card
                  if (hasShuttle) ...[
                    const SizedBox(height: AppSpacing.lg),
                    ListingStaffShuttleCard(
                      listing: listing,
                      l10n: l10n ?? AppLocalizationsTr(),
                    ),
                  ],

                  // Poster Card
                  const SizedBox(height: AppSpacing.lg),
                  ListingPosterCard(
                    listing: listing,
                    myUid: myUid,
                    revealContactInfo: _revealContactInfo,
                    onRevealContact: () =>
                        setState(() => _revealContactInfo = true),
                  ),

                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
        ),
        Divider(height: 1, thickness: 1, color: colorScheme.outlineVariant),

        // 3. Pinned Bottom Primary Action
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          color: colorScheme.surface,
          child: _buildBottomAction(context, listing, myUid, colorScheme, l10n),
        ),
      ],
    );
  }

  Widget _buildBottomAction(
    BuildContext context,
    Listing listing,
    String? myUid,
    ColorScheme colorScheme,
    AppLocalizations? l10n,
  ) {
    // 1. Logged out: prompt to log in
    if (myUid == null) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => context.push('/login'),
          icon: const Icon(Icons.login_rounded),
          label: Text(
            _previewString(
              l10n,
              'loginToContact',
              'İletişime geçmek için giriş yapın',
            ),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      );
    }

    // 2. Listing owner: edit listing
    if (myUid == listing.posterId) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => context.push('/listing/${listing.id}/edit'),
          icon: const Icon(Icons.edit_outlined),
          label: Text(
            _previewString(
              l10n,
              'editListing',
              'İlanı Düzenle',
            ),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      );
    }

    // 3. Job seeker: message / WhatsApp
    final phone = parsePhoneNumber(listing.contactInfo);
    final hasWhatsApp = phone != null;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _startingChat ? null : () => _messageOwner(listing),
            icon: _startingChat
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onPrimary,
                    ),
                  )
                : const Icon(Icons.message_outlined),
            label: Text(
              _previewString(
                l10n,
                'sendMessage',
                'Mesaj Gönder',
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        if (hasWhatsApp) ...[
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _openWhatsApp(listing),
              icon: const Icon(Icons.chat_rounded),
              label: Text(
                l10n?.sendWhatsAppAction ?? 'WhatsApp',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
