import 'dart:async';

import 'package:flutter/material.dart';

import 'admin_paged_controller.dart';

/// One column of the wide-screen table layout.
class AdminColumn<T> {
  const AdminColumn({required this.label, required this.cell, this.flex = 1});

  final String label;
  final Widget Function(BuildContext context, T item) cell;
  final int flex;
}

/// Renders an [AdminPagedController] as a table on wide screens (>= 900 px,
/// when [columns] are given) and as cards otherwise. Loads the next page as
/// the user nears the end, supports pull-to-refresh, and shows selection
/// checkboxes when [selectable] is true (for bulk actions).
class AdminPagedView<T> extends StatelessWidget {
  const AdminPagedView({
    super.key,
    required this.controller,
    required this.cardBuilder,
    this.columns,
    this.onRowTap,
    this.selectable = false,
    this.emptyText = 'Kayıt bulunamadı.',
    this.errorText = 'Kayıtlar yüklenemedi.',
  });

  static const double tableBreakpoint = 900;

  final AdminPagedController<T> controller;
  final Widget Function(BuildContext context, T item) cardBuilder;
  final List<AdminColumn<T>>? columns;
  final void Function(T item)? onRowTap;
  final bool selectable;
  final String emptyText;
  final String errorText;

  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.extentAfter < 400) unawaited(controller.loadMore());
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final items = controller.items;
        if (items.isEmpty) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: controller.refresh,
            child: ListView(
              children: [
                const SizedBox(height: 120),
                Center(
                  child: Text(controller.error != null ? errorText : emptyText),
                ),
              ],
            ),
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final useTable = columns != null &&
                constraints.maxWidth >= tableBreakpoint;
            return NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: RefreshIndicator(
                onRefresh: controller.refresh,
                child: useTable ? _table(context, items) : _cards(context, items),
              ),
            );
          },
        );
      },
    );
  }

  Widget _cards(BuildContext context, List<T> items) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == items.length) return _footer(context);
        final item = items[index];
        final card = cardBuilder(context, item);
        if (!selectable) return card;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: controller.isSelected(item),
              onChanged: (_) => controller.toggleSelected(item),
            ),
            Expanded(child: card),
          ],
        );
      },
    );
  }

  Widget _table(BuildContext context, List<T> items) {
    final theme = Theme.of(context);
    final cols = columns!;
    Widget row(List<Widget> cells, {Widget? leading, VoidCallback? onTap, bool header = false}) {
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (selectable) SizedBox(width: 48, child: leading),
              for (var i = 0; i < cols.length; i++)
                Expanded(
                  flex: cols[i].flex,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(end: 12),
                    child: header
                        ? DefaultTextStyle.merge(
                            style: theme.textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                            child: cells[i],
                          )
                        : cells[i],
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final allSelected = items.isNotEmpty &&
        items.every(controller.isSelected);
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: items.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Material(
            color: theme.colorScheme.surfaceContainerHighest,
            child: row(
              [for (final c in cols) Text(c.label)],
              header: true,
              leading: Checkbox(
                value: allSelected,
                onChanged: (_) => allSelected
                    ? controller.clearSelection()
                    : controller.selectAllLoaded(),
              ),
            ),
          );
        }
        if (index == items.length + 1) return _footer(context);
        final item = items[index - 1];
        return DecoratedBox(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: theme.dividerColor)),
          ),
          child: row(
            [for (final c in cols) c.cell(context, item)],
            onTap: onRowTap == null ? null : () => onRowTap!(item),
            leading: Checkbox(
              value: controller.isSelected(item),
              onChanged: (_) => controller.toggleSelected(item),
            ),
          ),
        );
      },
    );
  }

  Widget _footer(BuildContext context) {
    if (controller.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (controller.error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: TextButton.icon(
            onPressed: controller.refresh,
            icon: const Icon(Icons.refresh),
            label: Text(errorText),
          ),
        ),
      );
    }
    if (controller.hasMore) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: OutlinedButton(
            onPressed: controller.loadMore,
            child: const Text('Daha fazla yükle'),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          '${controller.items.length} kayıt',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}

/// A filter option for [AdminFilterBar].
class AdminFilter {
  const AdminFilter(this.id, this.label, {this.icon});

  final String id;
  final String label;
  final IconData? icon;
}

/// Horizontally scrollable single-select filter chips.
class AdminFilterBar extends StatelessWidget {
  const AdminFilterBar({
    super.key,
    required this.filters,
    required this.selectedId,
    required this.onSelected,
  });

  final List<AdminFilter> filters;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final filter in filters)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                avatar: filter.icon == null ? null : Icon(filter.icon, size: 18),
                label: Text(filter.label),
                selected: filter.id == selectedId,
                onSelected: (_) => onSelected(filter.id),
              ),
            ),
        ],
      ),
    );
  }
}
