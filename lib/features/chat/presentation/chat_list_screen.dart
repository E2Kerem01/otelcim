import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/conversation.dart';
import '../../../shared/providers/profile_provider.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/chat_service.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  static String _relativeTime(DateTime? time, AppLocalizations l10n) {
    if (time == null) return '';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return l10n.coreTimeJustNow;
    if (diff.inHours < 1) return l10n.coreTimeMinutesAgo(diff.inMinutes);
    if (diff.inDays < 1) return l10n.coreTimeHoursAgo(diff.inHours);
    return l10n.coreTimeDaysAgo(diff.inDays);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = ref.watch(authServiceProvider).currentUser;
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.coreMyMessagesTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline_rounded, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  l10n.coreLoginToChatTitle,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.coreLoginToChatDesc,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => context.push('/login'),
                  icon: const Icon(Icons.login_rounded),
                  label: Text(l10n.coreLoginOrRegisterAction),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final conversationsAsync = ref.watch(chatServiceProvider).watchConversations(currentUser.uid);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.coreMyMessagesTitle)),
      body: StreamBuilder<List<Conversation>>(
        stream: conversationsAsync,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(l10n.coreGenericErrorWithDetail('${snapshot.error}')));
          }
          final conversations = snapshot.data ?? [];
          if (conversations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mark_email_unread_outlined, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      l10n.coreNoMessagesTitle,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.coreNoMessagesDesc,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: conversations.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              return _ChatTile(
                conversation: conversation,
                currentUserId: currentUser.uid,
              );
            },
          );
        },
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
    final l10n = AppLocalizations.of(context)!;
    final otherUid = conversation.otherParticipant(currentUserId);
    final otherProfile = ref.watch(userProfileProvider(otherUid)).value;
    final isOtherAvailableImmediately = otherProfile != null &&
        otherProfile.userType != 'employer' &&
        otherProfile.availableImmediately;

    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor,
            child: Text(
              conversation.listingTitle.isNotEmpty ? conversation.listingTitle[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          if (isOtherAvailableImmediately)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(1),
                decoration: const BoxDecoration(
                  color: Colors.white,
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
                l10n.availableImmediatelyBadge,
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
        conversation.lastMessage.isEmpty ? l10n.coreNoMessagesYet : conversation.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        ChatListScreen._relativeTime(conversation.updatedAt, l10n),
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      onTap: () => context.push('/chat/${conversation.id}'),
    );
  }
}
