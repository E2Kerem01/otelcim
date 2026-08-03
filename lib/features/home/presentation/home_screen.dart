import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/constants/categories.dart';
import '../../../shared/providers/paginated_listings_provider.dart';
import '../../../shared/services/listing_service.dart';
import '../../boosts/presentation/widgets/boost_badge.dart';
import '../../listings/domain/listing_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _searchQuery = '';
  ({String? category, String? searchQuery}) _currentParams = (category: null, searchQuery: '');

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
      ref.read(paginatedListingsProvider(_currentParams).notifier).loadMore();
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(paginatedListingsProvider(_currentParams).notifier).refresh();

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = ref.watch(selectedCategoryFilterProvider);
    _currentParams = (category: selectedCategory?.name, searchQuery: _searchQuery);
    final paginationState = ref.watch(paginatedListingsProvider(_currentParams));

    if (paginationState.listings.isEmpty && !paginationState.isLoading && paginationState.hasMore) {
      final notifier = ref.read(paginatedListingsProvider(_currentParams).notifier);
      Future.microtask(notifier.loadInitial);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Otelcim'),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'İş ilanı ara...',
                    prefixIcon: Icon(Icons.search_rounded, color: Colors.grey),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 48,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: ListingCategory.values.length + 1,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final isSelected = selectedCategory == null;
                    return ChoiceChip(
                      label: const Text('Tümü'),
                      selected: isSelected,
                      onSelected: (_) => ref.read(selectedCategoryFilterProvider.notifier).state = null,
                      selectedColor: Theme.of(context).primaryColor,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                    );
                  }
                  final category = ListingCategory.values[index - 1];
                  final isSelected = category == selectedCategory;
                  return ChoiceChip(
                    label: Text(listingCategoryLabels[category]!),
                    selected: isSelected,
                    onSelected: (_) => ref.read(selectedCategoryFilterProvider.notifier).state = category,
                    selectedColor: Theme.of(context).primaryColor,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          if (paginationState.isLoading && paginationState.listings.isEmpty)
            const _ListingsSkeletonSliver()
          else if (paginationState.listings.isEmpty)
            _buildEmptyState(context)
          else ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ListingCard(listing: paginationState.listings[index]),
                  ),
                  childCount: paginationState.listings.length,
                ),
              ),
            ),
            if (paginationState.isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    // Auto seed sample listings into Firestore if database is empty
    Future.microtask(() => ref.read(listingServiceProvider).seedSampleListings());
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hotel_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'Henüz İlan Bulunmuyor',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Sistemde aktif ilan bulunmamaktadır. Örnek ilanları veritabanına ekleyebilir veya yeni bir ilan oluşturabilirsiniz.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  await ref.read(listingServiceProvider).seedSampleListings();
                },
                icon: const Icon(Icons.download_rounded),
                label: const Text('Örnek İlanları Veritabanına Yükle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.push('/create-listing'),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('İlk İlanı Sen Oluştur'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton placeholder cards shown while the initial page of listings loads.
class _ListingsSkeletonSliver extends StatelessWidget {
  const _ListingsSkeletonSliver();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SkeletonCard(),
          ),
          childCount: 4,
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = 0.4 + (_controller.value * 0.3);
        return Opacity(opacity: opacity, child: child);
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 80, height: 16, color: Colors.grey.shade300),
              const SizedBox(height: 10),
              Container(width: double.infinity, height: 14, color: Colors.grey.shade300),
              const SizedBox(height: 8),
              Container(width: 160, height: 12, color: Colors.grey.shade300),
              const SizedBox(height: 8),
              Container(width: 100, height: 14, color: Colors.grey.shade300),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final isBoostedActive = BoostBadge.isBoostActive(listing);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: isBoostedActive ? 3 : 1,
      shape: isBoostedActive
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.amber.shade400, width: 1.5),
            )
          : null,
      child: InkWell(
        onTap: () => context.push('/listing/${listing.id}'),
        child: Container(
          decoration: isBoostedActive
              ? BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.shade50.withValues(alpha: 0.35),
                      Colors.white,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        listingCategoryLabel(listing.category),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    if (isBoostedActive) ...[
                      const SizedBox(width: 8),
                      const BoostBadge(isCompact: true),
                    ],
                    const Spacer(),
                    if (listing.createdAt != null)
                      Text(
                        '${listing.createdAt!.day}.${listing.createdAt!.month}.${listing.createdAt!.year}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  listing.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        listing.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  listing.salary,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
