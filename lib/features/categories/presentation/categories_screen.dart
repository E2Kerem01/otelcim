import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/constants/categories.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kategoriler')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ListingCategory.values.length,
        itemBuilder: (context, index) {
          final category = ListingCategory.values[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                child: Icon(listingCategoryIcons[category], color: Theme.of(context).primaryColor),
              ),
              title: Text(
                listingCategoryLabels[category]!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                ref.read(selectedCategoryFilterProvider.notifier).state = category;
                context.go('/');
              },
            ),
          );
        },
      ),
    );
  }
}
