import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design_tokens.dart';
import '../../../core/responsive/max_width_container.dart';
import '../../../shared/constants/categories.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 768;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: isDesktop ? null : AppBar(title: const Text('Kategoriler')),
      body: MaxWidthContainer(
        maxWidth: AppBreakpoints.contentMaxWidth,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: ListingCategory.values.length + (isDesktop ? 1 : 0),
          itemBuilder: (context, index) {
            if (isDesktop && index == 0) {
              return Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 20),
                child: Text(
                  'Kategoriler',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              );
            }
            final categoryIndex = isDesktop ? index - 1 : index;
            final category = ListingCategory.values[categoryIndex];
            return Card(
              color: colorScheme.surface,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                  child: Icon(
                    listingCategoryIcons[category],
                    color: colorScheme.primary,
                  ),
                ),
                title: Text(
                  listingCategoryLabels[category]!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  ref.read(selectedCategoryFilterProvider.notifier).state =
                      category;
                  context.go('/');
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

