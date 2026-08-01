import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models/conversation.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/chat_service.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  String _relativeTime(DateTime? time) {
    if (time == null) return '';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'şimdi';
    if (diff.inHours < 1) return '${diff.inMinutes}dk';
    if (diff.inDays < 1) return '${diff.inHours}sa';
    return '${diff.inDays}g';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authStateProvider).value?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final conversationsAsync = ref.watch(chatServiceProvider).watchConversations(uid);

    return Scaffold(
      appBar: AppBar(title: const Text('Mesajlarım')),
      body: StreamBuilder<List<Conversation>>(
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
            return const Center(child: Text('Henüz mesajınız yok.'));
          }
          return ListView.separated(
            itemCount: conversations.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    conversation.listingTitle.isNotEmpty ? conversation.listingTitle[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(conversation.listingTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  conversation.lastMessage.isEmpty ? 'Henüz mesaj yok' : conversation.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(_relativeTime(conversation.updatedAt), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                onTap: () => context.push('/chat/${conversation.id}'),
              );
            },
          );
        },
      ),
    );
  }
}
