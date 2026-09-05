import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/services/auth_service.dart';
import '../../talent_pool/domain/talent_pool_item.dart';
import '../../talent_pool/services/talent_pool_service.dart';

class TalentPoolScreen extends ConsumerWidget {
  const TalentPoolScreen({super.key});

  void _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    String employerId,
    TalentPoolItem item,
  ) {
    unawaited(showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adayı Havuzdan Çıkar'),
        content: Text(
          '${item.candidateName} kişisini yetenek havuzunuzdan çıkarmak istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(talentPoolServiceProvider).removeFromTalentPool(
                    employerId: employerId,
                    candidateId: item.candidateId,
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Aday yetenek havuzundan çıkarıldı.'),
                  ),
                );
              }
            },
            child: const Text('Çıkar'),
          ),
        ],
      ),
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Yetenek Havuzu')),
        body: const Center(child: Text('Giriş yapmanız gerekiyor.')),
      );
    }

    final talentPoolAsync = ref.watch(talentPoolStreamProvider(user.uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yetenek Havuzu'),
      ),
      body: talentPoolAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.folder_shared_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Henüz Yetenek Havuzunuzda Aday Yok',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'İş arayanlarla yaptığınız sohbetlerde detay menüsünden "Yetenek Havuzuna Ekle" seçeneği ile adayları buraya kaydedebilirsiniz.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              final initial = item.candidateName.isNotEmpty
                  ? item.candidateName[0].toUpperCase()
                  : '?';
              final formattedDate = item.addedAt != null
                  ? '${item.addedAt!.day.toString().padLeft(2, '0')}.${item.addedAt!.month.toString().padLeft(2, '0')}.${item.addedAt!.year}'
                  : '';

              return Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.candidateName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (formattedDate.isNotEmpty)
                                  Text(
                                    'Eklenme: $formattedDate',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.redAccent,
                            ),
                            tooltip: 'Havuzdan Çıkar',
                            onPressed: () => _confirmRemove(
                              context,
                              ref,
                              user.uid,
                              item,
                            ),
                          ),
                        ],
                      ),
                      if (item.note != null && item.note!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.note_alt_outlined,
                                size: 16,
                                color: Colors.amber.shade900,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  item.note!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (item.conversationId != null &&
                          item.conversationId!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              unawaited(context.push('/chat/${item.conversationId}'));
                            },
                            icon: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 16,
                            ),
                            label: const Text('Sohbete Dön'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Yetenek havuzu yüklenirken hata oluştu: $err'),
        ),
      ),
    );
  }
}
