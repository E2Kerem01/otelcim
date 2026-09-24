import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/utils/search_keywords.dart';

const _adminGlobalSearchLimit = 8;

/// Query seam for global admin user search. A null query means the input does
/// not contain a searchable token yet.
Query<Map<String, dynamic>>? adminGlobalUserQuery(
  FirebaseFirestore db,
  String query,
) {
  final token = searchToken(query);
  if (token == null) return null;
  return db
      .collection('user_profiles')
      .where('searchKeywords', arrayContains: token)
      .limit(_adminGlobalSearchLimit);
}

/// Query seam for global admin listing search. A null query means the input
/// does not contain a searchable token yet.
Query<Map<String, dynamic>>? adminGlobalListingQuery(
  FirebaseFirestore db,
  String query,
) {
  final token = searchToken(query);
  if (token == null) return null;
  return db
      .collection('listings')
      .where('searchKeywords', arrayContains: token)
      .limit(_adminGlobalSearchLimit);
}

/// Opens the global user/listing search dialog used by the admin shell.
Future<void> showAdminGlobalSearch(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (_) => const Dialog(child: _AdminGlobalSearchDialog()),
  );
}

/// Search icon for the wide admin navigation rail.
class AdminGlobalSearchButton extends StatelessWidget {
  const AdminGlobalSearchButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Global arama (Ctrl+K)',
      icon: const Icon(Icons.search),
      onPressed: () => unawaited(showAdminGlobalSearch(context)),
    );
  }
}

class _AdminGlobalSearchDialog extends StatefulWidget {
  const _AdminGlobalSearchDialog();

  @override
  State<_AdminGlobalSearchDialog> createState() => _AdminGlobalSearchDialogState();
}

class _AdminGlobalSearchDialogState extends State<_AdminGlobalSearchDialog> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  int _requestGeneration = 0;
  bool _loading = false;
  String? _error;
  List<_AdminSearchHit> _users = const [];
  List<_AdminSearchHit> _listings = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _requestGeneration++;
    final query = value.trim();
    final token = searchToken(query);
    if (token == null) {
      setState(() {
        _loading = false;
        _error = null;
        _users = const [];
        _listings = const [];
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => unawaited(_search(query)),
    );
  }

  Future<void> _search(String query) async {
    final generation = ++_requestGeneration;
    final db = FirebaseFirestore.instance;
    final userQuery = adminGlobalUserQuery(db, query);
    final listingQuery = adminGlobalListingQuery(db, query);
    if (userQuery == null || listingQuery == null) return;

    try {
      final snapshots = await Future.wait([
        userQuery.get(),
        listingQuery.get(),
      ]);
      if (!mounted || generation != _requestGeneration) return;

      final userDocs = snapshots[0].docs.where((doc) => _matchesQuery(doc, query));
      final listingDocs = snapshots[1].docs.where((doc) => _matchesQuery(doc, query));
      setState(() {
        _loading = false;
        _users = [for (final doc in userDocs) _userHit(doc, query)];
        _listings = [for (final doc in listingDocs) _listingHit(doc)];
      });
    } catch (_) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _loading = false;
        _error = 'Arama yapılamadı.';
        _users = const [];
        _listings = const [];
      });
    }
  }

  bool _matchesQuery(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String query,
  ) {
    final rawKeywords = doc.data()['searchKeywords'];
    final keywords = rawKeywords is List
        ? rawKeywords.whereType<String>().toList()
        : const <String>[];
    return matchesAllWords(keywords, query);
  }

  _AdminSearchHit _userHit(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String query,
  ) {
    final data = doc.data();
    final email = data['email'] as String? ?? '';
    final displayName = (data['displayName'] as String?)?.trim();
    final hotelName = (data['hotelName'] as String?)?.trim();
    return _AdminSearchHit(
      title: displayName?.isNotEmpty == true ? displayName! : email,
      subtitle: [
        if (email.isNotEmpty) email,
        if (hotelName?.isNotEmpty == true) hotelName!,
      ].join(' • '),
      route: Uri(
        path: '/admin/users',
        queryParameters: {'q': query},
      ).toString(),
    );
  }

  _AdminSearchHit _listingHit(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final title = data['title'] as String? ?? 'İlan';
    final posterName = data['posterName'] as String? ?? '';
    final location = data['location'] as String? ?? '';
    return _AdminSearchHit(
      title: title,
      subtitle: [
        if (posterName.isNotEmpty) posterName,
        if (location.isNotEmpty) location,
      ].join(' • '),
      route: '/listing/${Uri.encodeComponent(doc.id)}',
    );
  }

  void _open(_AdminSearchHit hit) {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.go(hit.route);
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim();
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640, maxHeight: 600),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Global arama',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  tooltip: 'Kapat',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Kullanıcı veya ilan ara',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _onChanged,
              textInputAction: TextInputAction.search,
            ),
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(_error!, textAlign: TextAlign.center),
              )
            else if (searchToken(query) == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('Aramak için en az iki karakter yazın.'),
              )
            else
              Flexible(
                child: _results(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _results() {
    if (!_loading && _users.isEmpty && _listings.isEmpty) {
      return const Center(child: Text('Sonuç bulunamadı.'));
    }
    return ListView(
      shrinkWrap: true,
      children: [
        if (_users.isNotEmpty) ...[
          const _SearchSectionTitle('Kullanıcılar'),
          for (final hit in _users) _SearchResultTile(hit: hit, onTap: () => _open(hit)),
        ],
        if (_listings.isNotEmpty) ...[
          const _SearchSectionTitle('İlanlar'),
          for (final hit in _listings) _SearchResultTile(hit: hit, onTap: () => _open(hit)),
        ],
      ],
    );
  }
}

class _AdminSearchHit {
  const _AdminSearchHit({
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final String title;
  final String subtitle;
  final String route;
}

class _SearchSectionTitle extends StatelessWidget {
  const _SearchSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.hit, required this.onTap});

  final _AdminSearchHit hit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.arrow_forward_ios, size: 16),
      title: Text(hit.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: hit.subtitle.isEmpty
          ? null
          : Text(hit.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: onTap,
    );
  }
}
