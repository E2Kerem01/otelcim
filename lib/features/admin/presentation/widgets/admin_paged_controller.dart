import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../../shared/error/error_reporter.dart';

/// Cursor-based pagination over a Firestore query for admin lists.
///
/// Loads [pageSize] documents at a time with `startAfterDocument`, so a
/// collection with 100k documents costs one page of reads per scroll step
/// instead of streaming the whole collection. Also tracks a selection (by
/// [idOf]) for bulk actions.
///
/// Changing the query (a filter tab, a search) calls [setQuery], which bumps
/// a generation counter so a slow response for the previous query can never
/// land in the new list.
class AdminPagedController<T> extends ChangeNotifier {
  AdminPagedController({
    required this.fromDoc,
    required this.idOf,
    this.pageSize = 20,
  });

  final T Function(DocumentSnapshot<Map<String, dynamic>> doc) fromDoc;
  final String Function(T item) idOf;
  final int pageSize;

  Query<Map<String, dynamic>>? _query;
  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  int _generation = 0;
  bool _disposed = false;

  final List<T> _items = [];
  final Set<String> _selected = {};
  bool _loading = false;
  bool _hasMore = true;
  Object? _error;

  List<T> get items => List.unmodifiable(_items);
  bool get isLoading => _loading;
  bool get hasMore => _hasMore;
  Object? get error => _error;
  bool get isEmpty => _items.isEmpty && !_loading && !_hasMore;

  Set<String> get selectedIds => Set.unmodifiable(_selected);
  List<T> get selectedItems =>
      _items.where((item) => _selected.contains(idOf(item))).toList();
  bool isSelected(T item) => _selected.contains(idOf(item));

  /// Replaces the query (new filter/search) and loads its first page.
  Future<void> setQuery(Query<Map<String, dynamic>> query) {
    _query = query;
    return refresh();
  }

  /// Drops loaded pages and the selection, then loads the first page again.
  Future<void> refresh() {
    _generation++;
    _items.clear();
    _selected.clear();
    _cursor = null;
    _hasMore = true;
    _error = null;
    _loading = false;
    _notify();
    return loadMore();
  }

  Future<void> loadMore() async {
    final query = _query;
    if (query == null || _loading || !_hasMore) return;
    final generation = _generation;
    _loading = true;
    _notify();
    try {
      // Cursor first, then limit (order is irrelevant to Firestore but not to
      // fake_cloud_firestore). One extra document tells us whether another
      // page exists without a second round trip.
      var pageQuery = query;
      final cursor = _cursor;
      if (cursor != null) pageQuery = pageQuery.startAfterDocument(cursor);
      pageQuery = pageQuery.limit(pageSize + 1);
      final snap = await pageQuery.get();
      if (generation != _generation) return;
      final docs = snap.docs;
      _hasMore = docs.length > pageSize;
      final page = docs.take(pageSize).toList();
      if (page.isNotEmpty) _cursor = page.last;
      _items.addAll(page.map(fromDoc));
    } catch (error, stackTrace) {
      if (generation != _generation) return;
      _error = error;
      _hasMore = false;
      logError(error, stackTrace, context: 'AdminPagedController.loadMore');
    } finally {
      if (generation == _generation) {
        _loading = false;
        _notify();
      }
    }
  }

  void toggleSelected(T item) {
    final id = idOf(item);
    if (!_selected.remove(id)) _selected.add(id);
    _notify();
  }

  void selectAllLoaded() {
    _selected.addAll(_items.map(idOf));
    _notify();
  }

  void clearSelection() {
    if (_selected.isEmpty) return;
    _selected.clear();
    _notify();
  }

  /// Removes items (e.g. after a bulk dismiss) without reloading the page.
  void removeWhere(bool Function(T item) test) {
    _items.removeWhere((item) {
      final remove = test(item);
      if (remove) _selected.remove(idOf(item));
      return remove;
    });
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
