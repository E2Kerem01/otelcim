import 'package:flutter/material.dart';
import '../../../listings/domain/listing_model.dart';

class BoostBadge extends StatelessWidget {
  final Listing? listing;
  final bool isCompact;
  final String? customText;

  const BoostBadge({
    super.key,
    this.listing,
    this.isCompact = false,
    this.customText,
  });

  /// Check if the listing has an active boost
  static bool isBoostActive(Listing? listing) {
    if (listing == null) return false;
    if (!listing.isBoosted) return false;
    if (listing.boostExpiresAt == null) return false;
    return listing.boostExpiresAt!.isAfter(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    if (listing != null && !isBoostActive(listing)) {
      return const SizedBox.shrink();
    }

    final displayText = customText ?? (isCompact ? 'Öne Çıkan' : 'Öne Çıkarılan İlan');

    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.amber.shade700,
              Colors.orange.shade800,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.bolt_rounded,
              size: 13,
              color: Colors.white,
            ),
            const SizedBox(width: 3),
            Text(
              displayText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade600,
            Colors.orange.shade700,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.rocket_launch_rounded,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            displayText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
