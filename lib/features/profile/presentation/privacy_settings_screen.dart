import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../shared/services/auth_service.dart';
import '../../../shared/services/chat_service.dart';
import '../../../shared/services/listing_service.dart';
import '../../../shared/services/profile_service.dart';

class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  Future<void> _exportUserData(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    try {
      final profile = await ref.read(profileServiceProvider).getUserProfile(user.uid);
      final listings = await ref.read(listingServiceProvider).watchMyListings(user.uid).first;
      final conversations = await ref.read(chatServiceProvider).watchConversations(user.uid).first;

      final dataMap = {
        'exportDate': DateTime.now().toIso8601String(),
        'user': {
          'uid': user.uid,
          'email': user.email,
          'displayName': profile?.displayName,
          'phoneNumber': profile?.phoneNumber,
          'userType': profile?.userType,
          'hotelName': profile?.hotelName,
          'position': profile?.position,
          'bio': profile?.bio,
        },
        'listingsCount': listings.length,
        'listings': listings
            .map((l) => {
                  'id': l.id,
                  'title': l.title,
                  'category': l.category,
                  'location': l.location,
                  'salary': l.salary,
                  'status': l.status.name,
                  'createdAt': l.createdAt?.toIso8601String(),
                })
            .toList(),
        'conversationsCount': conversations.length,
        'conversations': conversations
            .map((c) => {
                  'id': c.id,
                  'listingTitle': c.listingTitle,
                  'lastMessage': c.lastMessage,
                })
            .toList(),
      };

      const encoder = JsonEncoder.withIndent('  ');
      final jsonString = encoder.convert(dataMap);

      await SharePlus.instance.share(ShareParams(
        text: jsonString,
        subject: 'Otelcim_Kisisel_Verilerim.json',
      ));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kişisel verileriniz hazırlandı.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veri dışa aktarma hatası: $e')),
        );
      }
    }
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    final passwordController = TextEditingController();
    final confirmTextController = TextEditingController();
    bool isDeleting = false;

    unawaited(showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hesabınızı Silin',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BU İŞLEM GERİ ALINAMAZ!\n\nHesabınız, oluşturduğunuz tüm ilanlar, mesaj geçmişiniz, öne çıkarma ve doğrulama kayıtlarınız kalıcı olarak silinecektir.',
                      style: TextStyle(fontSize: 13, height: 1.4, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Doğrulama için hesap şifrenizi girin:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'Şifreniz',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Onaylamak için aşağıya "SİL" yazın:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: confirmTextController,
                      decoration: const InputDecoration(
                        hintText: 'SİL',
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: isDeleting
                      ? null
                      : () async {
                          final password = passwordController.text.trim();
                          final confirmText = confirmTextController.text.trim();

                          if (password.isEmpty) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(content: Text('Lütfen şifrenizi girin.')),
                            );
                            return;
                          }

                          if (confirmText != 'SİL') {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(content: Text('Lütfen onay kutusuna büyük harflerle "SİL" yazın.')),
                            );
                            return;
                          }

                          setDialogState(() => isDeleting = true);

                          try {
                            await ref.read(authServiceProvider).deleteAccount(password: password);

                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: Colors.red,
                                  content: Text('Hesabınız ve tüm verileriniz kalıcı olarak silindi.'),
                                ),
                              );
                              context.go('/login');
                            }
                          } catch (e) {
                            setDialogState(() => isDeleting = false);
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(content: Text('Hesap silme başarısız: Şifrenizi kontrol edin ($e)')),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: isDeleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Hesabımı Kalıcı Olarak Sil'),
                ),
              ],
            );
          },
        );
      },
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gizlilik ve Veri Ayarları'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Data Storage Summary Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield_outlined, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 10),
                      const Text(
                        'Kişisel Verileriniz ve KVKK',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'KVKK (6698 Sayılı Kanun) kapsamında Otelcim uygulamasında profil bilgileriniz, yayınladığınız ilanlar ve mesaj geçmişiniz güvenle saklanır. Verileriniz izniniz olmadan üçüncü taraflarla paylaşılmaz.',
                    style: TextStyle(fontSize: 13, height: 1.4, color: Colors.grey.shade800),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Privacy Policy Tile
          Card(
            child: ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('KVKK ve Gizlilik Politikası'),
              subtitle: const Text('Veri işleme ilkeleri ve yasal haklarınız'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/profile/privacy/policy'),
            ),
          ),

          const SizedBox(height: 12),

          // Export Data Tile
          Card(
            child: ListTile(
              leading: Icon(Icons.download_rounded, color: Theme.of(context).primaryColor),
              title: const Text('Verilerimi İndir / Dışa Aktar'),
              subtitle: const Text('Profil, ilan ve mesaj bilgilerinizi JSON olarak aktarın'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _exportUserData(context, ref),
            ),
          ),

          const SizedBox(height: 24),

          // Delete Account Section
          Card(
            color: Colors.red.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.red.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        'Hesabımı Kalıcı Olarak Sil',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red.shade900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hesabınızı sildiğinizde profiliniz, oluşturduğunuz tüm ilanlar, mesajlaşmalarınız ve sistem kayıtlarınız kalıcı olarak silinir.',
                    style: TextStyle(fontSize: 12, color: Colors.red.shade900),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showDeleteAccountDialog(context, ref),
                      icon: const Icon(Icons.delete_forever_rounded, size: 18),
                      label: const Text('Hesabımı Sil'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
