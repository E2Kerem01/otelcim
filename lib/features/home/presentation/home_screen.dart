import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/constants/categories.dart';
import '../../../shared/constants/listing_filters.dart';
import '../../../shared/providers/paginated_listings_provider.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/listing_service.dart';
import '../../ads/presentation/widgets/banner_ad_carousel.dart';
import '../../boosts/presentation/widgets/boost_badge.dart';
import '../../favorites/services/favorite_service.dart';
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
  _AdvancedFilters _filters = const _AdvancedFilters();
  PaginationParams _currentParams = (
    category: null,
    searchQuery: '',
    city: null,
    minSalaryTl: null,
    maxSalaryTl: null,
    dateFilter: ListingDateFilter.all,
    employmentType: null,
    sortOrder: ListingSortOrder.newest,
  );

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

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<_AdvancedFilters>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _FilterSheet(initial: _filters),
    );
    if (result != null && mounted) setState(() => _filters = result);
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = ref.watch(selectedCategoryFilterProvider);
    _currentParams = (
      category: selectedCategory?.name,
      searchQuery: _searchQuery,
      city: _filters.city,
      minSalaryTl: _filters.minSalaryTl,
      maxSalaryTl: _filters.maxSalaryTl,
      dateFilter: _filters.dateFilter,
      employmentType: _filters.employmentType,
      sortOrder: _filters.sortOrder,
    );
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
              child: Row(children: [
                Expanded(child: Container(
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
                    onChanged: (value) => setState(() => _searchQuery = value.trim()),
                  ),
                )),
                const SizedBox(width: 10),
                Badge(
                  isLabelVisible: _filters.activeCount > 0,
                  label: Text('${_filters.activeCount}'),
                  child: IconButton.filledTonal(
                    onPressed: _openFilters,
                    tooltip: 'Filtreler',
                    icon: const Icon(Icons.tune_rounded),
                  ),
                ),
              ]),
            ),
          ),
          if (_filters.activeCount > 0)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  children: [
                    if (_filters.city != null) _filterChip(_filters.city!, () => setState(() => _filters = _filters.copyWith(clearCity: true))),
                    if (_filters.minSalaryTl != null || _filters.maxSalaryTl != null) _filterChip(_filters.salaryLabel, () => setState(() => _filters = _filters.copyWith(clearSalary: true))),
                    if (_filters.dateFilter != ListingDateFilter.all) _filterChip(_filters.dateFilter.label, () => setState(() => _filters = _filters.copyWith(dateFilter: ListingDateFilter.all))),
                    if (_filters.employmentType != null) _filterChip(_filters.employmentType!.label, () => setState(() => _filters = _filters.copyWith(clearEmploymentType: true))),
                    if (_filters.sortOrder != ListingSortOrder.newest) _filterChip(_filters.sortOrder.label, () => setState(() => _filters = _filters.copyWith(sortOrder: ListingSortOrder.newest))),
                    TextButton(onPressed: () => setState(() => _filters = const _AdvancedFilters()), child: const Text('Temizle')),
                  ],
                ),
              ),
            ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: BannerAdCarousel(),
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Text('${paginationState.listings.length} sonuç', style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
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

  Widget _filterChip(String label, VoidCallback onDeleted) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: InputChip(label: Text(label), onDeleted: onDeleted),
      );
}

class _AdvancedFilters {
  const _AdvancedFilters({
    this.city,
    this.minSalaryTl,
    this.maxSalaryTl,
    this.dateFilter = ListingDateFilter.all,
    this.employmentType,
    this.sortOrder = ListingSortOrder.newest,
  });

  final String? city;
  final int? minSalaryTl;
  final int? maxSalaryTl;
  final ListingDateFilter dateFilter;
  final EmploymentType? employmentType;
  final ListingSortOrder sortOrder;

  int get activeCount => [
        city != null,
        minSalaryTl != null || maxSalaryTl != null,
        dateFilter != ListingDateFilter.all,
        employmentType != null,
        sortOrder != ListingSortOrder.newest,
      ].where((active) => active).length;

  String get salaryLabel {
    if (minSalaryTl != null && maxSalaryTl != null) return '$minSalaryTl - $maxSalaryTl TL';
    if (minSalaryTl != null) return '$minSalaryTl TL ve üzeri';
    return '$maxSalaryTl TL ve altı';
  }

  _AdvancedFilters copyWith({
    String? city,
    int? minSalaryTl,
    int? maxSalaryTl,
    ListingDateFilter? dateFilter,
    EmploymentType? employmentType,
    ListingSortOrder? sortOrder,
    bool clearCity = false,
    bool clearSalary = false,
    bool clearEmploymentType = false,
  }) => _AdvancedFilters(
        city: clearCity ? null : city ?? this.city,
        minSalaryTl: clearSalary ? null : minSalaryTl ?? this.minSalaryTl,
        maxSalaryTl: clearSalary ? null : maxSalaryTl ?? this.maxSalaryTl,
        dateFilter: dateFilter ?? this.dateFilter,
        employmentType: clearEmploymentType ? null : employmentType ?? this.employmentType,
        sortOrder: sortOrder ?? this.sortOrder,
      );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});
  final _AdvancedFilters initial;
  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String? _city;
  late final TextEditingController _minController;
  late final TextEditingController _maxController;
  late ListingDateFilter _date;
  EmploymentType? _employmentType;
  late ListingSortOrder _sort;

  @override
  void initState() {
    super.initState();
    _city = widget.initial.city;
    _minController = TextEditingController(text: widget.initial.minSalaryTl?.toString() ?? '');
    _maxController = TextEditingController(text: widget.initial.maxSalaryTl?.toString() ?? '');
    _date = widget.initial.dateFilter;
    _employmentType = widget.initial.employmentType;
    _sort = widget.initial.sortOrder;
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [const Expanded(child: Text('Gelişmiş filtreler', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))), IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))]),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _city,
              decoration: const InputDecoration(labelText: 'Şehir / bölge'),
              items: [const DropdownMenuItem<String?>(value: null, child: Text('Tüm şehirler')), ...turkishTourismCities.map((city) => DropdownMenuItem(value: city, child: Text(city)))],
              onChanged: (value) => setState(() => _city = value),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: TextField(controller: _minController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'En düşük maaş'))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: _maxController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'En yüksek maaş'))),
            ]),
            const SizedBox(height: 14),
            DropdownButtonFormField<ListingDateFilter>(initialValue: _date, decoration: const InputDecoration(labelText: 'İlan tarihi'), items: ListingDateFilter.values.map((value) => DropdownMenuItem(value: value, child: Text(value.label))).toList(), onChanged: (value) { if (value != null) setState(() => _date = value); }),
            const SizedBox(height: 14),
            DropdownButtonFormField<EmploymentType?>(initialValue: _employmentType, decoration: const InputDecoration(labelText: 'Çalışma tipi'), items: [const DropdownMenuItem<EmploymentType?>(value: null, child: Text('Tüm çalışma tipleri')), ...EmploymentType.values.map((value) => DropdownMenuItem(value: value, child: Text(value.label)))], onChanged: (value) => setState(() => _employmentType = value)),
            const SizedBox(height: 14),
            DropdownButtonFormField<ListingSortOrder>(initialValue: _sort, decoration: const InputDecoration(labelText: 'Sıralama'), items: ListingSortOrder.values.map((value) => DropdownMenuItem(value: value, child: Text(value.label))).toList(), onChanged: (value) { if (value != null) setState(() => _sort = value); }),
            const SizedBox(height: 22),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context, const _AdvancedFilters()), child: const Text('Temizle'))),
              const SizedBox(width: 12),
              Expanded(child: FilledButton(onPressed: () {
                final min = int.tryParse(_minController.text.trim());
                final max = int.tryParse(_maxController.text.trim());
                if (min != null && max != null && min > max) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maaş aralığını kontrol edin.'))); return; }
                Navigator.pop(context, _AdvancedFilters(city: _city, minSalaryTl: min, maxSalaryTl: max, dateFilter: _date, employmentType: _employmentType, sortOrder: _sort));
              }, child: const Text('Filtreleri uygula'))),
            ]),
          ]),
        ),
      );
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

class _ListingCard extends ConsumerWidget {
  const _ListingCard({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBoostedActive = BoostBadge.isBoostActive(listing);
    final uid = ref.watch(authStateProvider).value?.uid;
    final isFavorite = uid == null
        ? false
        : ref.watch(favoriteIdsProvider(uid)).valueOrNull?.contains(listing.id) ?? false;

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
                    AnimatedScale(
                      scale: isFavorite ? 1.15 : 1,
                      duration: const Duration(milliseconds: 180),
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: isFavorite ? 'Favorilerden çıkar' : 'Favorilere ekle',
                        onPressed: () {
                          if (uid == null) {
                            context.push('/login');
                            return;
                          }
                          ref.read(favoriteServiceProvider).toggleFavorite(uid, listing.id);
                        },
                        icon: Icon(
                          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFavorite ? Colors.red : Colors.grey.shade600,
                        ),
                      ),
                    ),
                    if (listing.createdAt != null)
                      Text(
                        '${listing.createdAt!.day}.${listing.createdAt!.month}.${listing.createdAt!.year}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (listing.images.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: listing.images.first,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: Colors.grey.shade200, width: 60, height: 60),
                          errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 24, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            listing.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
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
                        ],
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
