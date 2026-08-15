import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/constants/categories.dart';
import '../../../../shared/constants/listing_filters.dart';
import '../../../boosts/presentation/widgets/boost_badge.dart';
import '../../domain/listing_model.dart';
import '../listing_requirement_labels.dart';
import '../whatsapp_utils.dart';

/// Presentational sections of [ListingDetailScreen] (see that file) split
/// out to keep its build method focused on layout rather than the markup
/// for each card. Sections that need to call back into screen state
/// (reporting, revealing contact info) take callbacks; the rest are pure
/// functions of a [Listing].

class ListingHeaderInfo extends StatelessWidget {
  const ListingHeaderInfo({
    super.key,
    required this.listing,
    required this.isBoostedActive,
  });

  final Listing listing;
  final bool isBoostedActive;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Chip(
              label: Text(listingCategoryLabel(listing.category)),
              backgroundColor:
                  Theme.of(context).primaryColor.withValues(alpha: 0.1),
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
      ],
    );
  }
}

class ListingSalaryCard extends StatelessWidget {
  const ListingSalaryCard({super.key, required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
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

class ListingRequirementsCard extends StatelessWidget {
  const ListingRequirementsCard({
    super.key,
    required this.experience,
    required this.education,
    required this.l10n,
  });

  final ExperienceLevel? experience;
  final EducationLevel? education;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (experience != null)
              _RequirementRow(
                icon: Icons.work_history_outlined,
                label: l10n.experienceLevelLabel,
                value: experienceLevelLabel(l10n, experience!),
              ),
            if (experience != null && education != null)
              const Divider(height: 24),
            if (education != null)
              _RequirementRow(
                icon: Icons.school_outlined,
                label: l10n.educationLevelLabel,
                value: educationLevelLabel(l10n, education!),
              ),
          ],
        ),
      ),
    );
  }
}

class ListingDescriptionSection extends StatelessWidget {
  const ListingDescriptionSection({super.key, required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'İlan Açıklaması',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          listing.description,
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
      ],
    );
  }
}

class ListingHousingCard extends StatelessWidget {
  const ListingHousingCard({
    super.key,
    required this.listing,
    required this.l10n,
  });

  final Listing listing;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Card(
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
                  l10n.housingTitle,
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
                          ? l10n.housingSingleRoom
                          : l10n.housingSharedRoom,
                    ),
                  ),
                if (listing.housingHasAc == true)
                  Chip(
                    avatar: const Icon(
                      Icons.ac_unit_outlined,
                      size: 18,
                    ),
                    label: Text(l10n.housingHasAc),
                  ),
                if (listing.housingHasWifi == true)
                  Chip(
                    avatar: const Icon(Icons.wifi, size: 18),
                    label: Text(l10n.housingHasWifi),
                  ),
                if (listing.housingMealsIncluded != null)
                  Chip(
                    avatar: const Icon(
                      Icons.restaurant_outlined,
                      size: 18,
                    ),
                    label: Text(
                      '${l10n.housingMealsIncluded}: ${listing.housingMealsIncluded}',
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
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: listing.housingImages[index],
                      width: 160,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => const Icon(Icons.broken_image),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ListingStaffShuttleCard extends StatelessWidget {
  const ListingStaffShuttleCard({
    super.key,
    required this.listing,
    required this.l10n,
  });

  final Listing listing;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_bus_outlined),
                const SizedBox(width: 8),
                Text(
                  l10n.staffShuttleRouteLabel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(listing.staffShuttleRoute!),
          ],
        ),
      ),
    );
  }
}

class ListingPosterCard extends StatelessWidget {
  const ListingPosterCard({
    super.key,
    required this.listing,
    required this.myUid,
    required this.revealContactInfo,
    required this.onRevealContact,
  });

  final Listing listing;
  final String? myUid;
  final bool revealContactInfo;
  final VoidCallback onRevealContact;

  @override
  Widget build(BuildContext context) {
    return Card(
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
                  else if (myUid == listing.posterId || revealContactInfo)
                    Text(
                      listing.contactInfo,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    )
                  else
                    InkWell(
                      onTap: onRevealContact,
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
    );
  }
}

class ListingSafetyTipsCard extends StatelessWidget {
  const ListingSafetyTipsCard({
    super.key,
    required this.l10n,
    required this.onReport,
  });

  final AppLocalizations l10n;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.shield_outlined,
              color: Theme.of(context).colorScheme.onTertiaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.listingSafetyTipsTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.listingSafetyTipsBody,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onTertiaryContainer,
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: onReport,
                    icon: const Icon(Icons.flag_outlined),
                    label: Text(l10n.listingSafetyReportAction),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ListingImageGallery extends StatefulWidget {
  final Listing listing;

  const ListingImageGallery({super.key, required this.listing});

  @override
  State<ListingImageGallery> createState() => _ListingImageGalleryState();
}

class _ListingImageGalleryState extends State<ListingImageGallery> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.listing.images.isEmpty) {
      final categoryEnum = ListingCategory.values.firstWhere(
        (c) => c.name == widget.listing.category,
        orElse: () => ListingCategory.diger,
      );
      final categoryIcon = listingCategoryIcons[categoryEnum] ?? Icons.hotel;
      final categoryColor =
          listingCategoryColors[categoryEnum] ?? Theme.of(context).primaryColor;

      return Container(
        width: double.infinity,
        height: 180,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [categoryColor, categoryColor.withValues(alpha: 0.72)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                categoryIcon,
                size: 56,
                color: Colors.white.withValues(alpha: 0.92),
              ),
              const SizedBox(height: 8),
              Text(
                listingCategoryLabels[categoryEnum] ?? 'Otelcim İlanı',
                style: const TextStyle(
                  color: Colors.white,
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

class ListingRightStickyActionCard extends StatelessWidget {
  const ListingRightStickyActionCard({
    super.key,
    required this.listing,
    required this.myUid,
    required this.startingChat,
    required this.revealContactInfo,
    required this.onMessageOwner,
    required this.onOpenWhatsApp,
    required this.onRevealContact,
    required this.onReport,
  });

  final Listing listing;
  final String? myUid;
  final bool startingChat;
  final bool revealContactInfo;
  final VoidCallback onMessageOwner;
  final VoidCallback onOpenWhatsApp;
  final VoidCallback onRevealContact;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final isOwner = myUid == listing.posterId;
    final isBoostedActive = BoostBadge.isBoostActive(listing);
    final phone = parsePhoneNumber(listing.contactInfo);
    final hasWhatsApp = phone != null;
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.work_outline_rounded,
                  color: Theme.of(context).primaryColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  isOwner ? 'İlan Yönetimi' : 'İş Başvurusu & İletişim',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Maaş / Ücret',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    listing.salary,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (isOwner) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/listing/${listing.id}/boost'),
                  icon: const Icon(Icons.rocket_launch_rounded),
                  label: Text(
                    isBoostedActive ? 'Öne Çıkarma' : 'İlanı Öne Çıkar',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      context.push('/listing/${listing.id}/qr-poster'),
                  icon: const Icon(Icons.qr_code_2_rounded),
                  label: Text(l10n.createQrPosterAction),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: startingChat ? null : onMessageOwner,
                  icon: startingChat
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.message_outlined),
                  label: const Text('Başvur / Mesaj Gönder'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              if (hasWhatsApp) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onOpenWhatsApp,
                    icon: const Icon(Icons.chat_rounded),
                    label: Text(l10n.sendWhatsAppAction),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ],
            const Divider(height: 28),
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
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
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.posterName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'İlan Sahibi',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
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
            else if (myUid == listing.posterId || revealContactInfo)
              SelectableText(
                listing.contactInfo,
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              )
            else
              InkWell(
                onTap: onRevealContact,
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
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 16,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Otelcim ile doğrudan ve ücretsiz iş başvurusu',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
