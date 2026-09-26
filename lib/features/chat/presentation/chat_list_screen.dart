import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design_tokens.dart';
import '../../../core/responsive/max_width_container.dart';
import '../../../shared/models/conversation.dart';
import '../../../shared/providers/profile_provider.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/chat_service.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  static String _relativeTime(DateTime? time) {
    if (time == null) return '';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'şimdi';
    if (diff.inHours < 1) return '${diff.inMinutes}dk';
    if (diff.inDays < 1) return '${diff.inHours}sa';
    return '${diff.inDays}g';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authServiceProvider).currentUser;
    final isDesktop = MediaQuery.sizeOf(context).width >= 768;

    if (currentUser == null) {
      return Scaffold(
        appBar: isDesktop ? null : AppBar(title: const Text('Mesajlarım')),
        body: MaxWidthContainer(
          maxWidth: AppBreakpoints.contentMaxWidth,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isDesktop) ...[
                    Text(
                      'Mesajlarım',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Mesajlaşmak İçin Giriş Yapın',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'İlan sahipleriyle iletişime geçmek ve gelen mesajlarınızı görmek için lütfen hesabınıza giriş yapın.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/login'),
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Giriş Yap / Kayıt Ol'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final conversationsAsync =
        ref.watch(chatServiceProvider).watchConversations(currentUser.uid);

    return Scaffold(
      appBar: isDesktop ? null : AppBar(title: const Text('Mesajlarım')),
      body: MaxWidthContainer(
        maxWidth: AppBreakpoints.contentMaxWidth,
        child: StreamBuilder<List<Conversation>>(
          stream: conversationsAsync,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Hata: ${snapshot.error}'));
            }
            final conversations = snapshot.data ?? [];
            if (conversations.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isDesktop) ...[
                        Text(
                          'Mesajlarım',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      Icon(
                        Icons.mark_email_unread_outlined,
                        size: 64,
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Henüz Mesajınız Yok',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'İlan detay sayfasından ilan sahibine mesaj göndererek hemen iletişim başlatabilirsiniz.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: isDesktop
                  ? const EdgeInsets.fromLTRB(16, 24, 16, 16)
                  : const EdgeInsets.all(0),
              itemCount: conversations.length + (isDesktop ? 1 : 0),
              separatorBuilder: (context, index) =>
                  (isDesktop && index == 0)
                      ? const SizedBox(height: 12)
                      : const Divider(height: 1),
              itemBuilder: (context, index) {
                if (isDesktop && index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Mesajlarım',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  );
                }
                final convIndex = isDesktop ? index - 1 : index;
                final conversation = conversations[convIndex];
                return _ChatTile(
                  conversation: conversation,
                  currentUserId: currentUser.uid,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ChatTile extends ConsumerWidget {
  const _ChatTile({
    required this.conversation,
    required this.currentUserId,
  });

  final Conversation conversation;
  final String currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherUid = conversation.otherParticipant(currentUserId);
    final otherProfile = ref.watch(userProfileProvider(otherUid)).value;
    final isOtherAvailableImmediately = otherProfile != null &&
        otherProfile.userType != 'employer' &&
        otherProfile.availableImmediately;

    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundColor: colorScheme.primary,
            child: Text(
              conversation.listingTitle.isNotEmpty
                  ? conversation.listingTitle[0].toUpperCase()
                  : '?',
              style: TextStyle(color: colorScheme.onPrimary),
            ),
          ),
          if (isOtherAvailableImmediately)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.bolt_rounded,
                  size: 14,
                  color: Colors.green.shade700,
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.listingTitle,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isOtherAvailableImmediately) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Text(
                'Hemen Başlayabilir',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        conversation.lastMessage.isEmpty
            ? 'Henüz mesaj yok'
            : conversation.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        ChatListScreen._relativeTime(conversation.updatedAt),
        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
      ),
      onTap: () => context.push('/chat/${conversation.id}'),
    );
  }
}
