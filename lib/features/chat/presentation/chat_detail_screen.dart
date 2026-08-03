import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models/conversation.dart';
import '../../../shared/models/message.dart';
import '../../../shared/models/report.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/chat_service.dart';
import '../../../shared/widgets/report_dialog.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  const ChatDetailScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _messageController = TextEditingController();
  String? _otherParticipantId;
  Conversation? _conversation;
  bool _markingHired = false;
  StreamSubscription<Conversation?>? _conversationSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentChatIdProvider.notifier).state = widget.conversationId;
    });
    _listenToConversation();
  }

  void _listenToConversation() {
    _conversationSubscription = ref
        .read(chatServiceProvider)
        .watchConversation(widget.conversationId)
        .listen((conversation) {
      final myUid = ref.read(authStateProvider).value?.uid;
      if (conversation != null && myUid != null && mounted) {
        if (myUid != conversation.posterId && myUid != conversation.seekerId) {
          context.go('/');
          return;
        }
        setState(() {
          _conversation = conversation;
          _otherParticipantId = conversation.otherParticipant(myUid);
        });
      }
    });
  }

  Future<void> _markAsHired() async {
    if (_conversation?.hired == true || _markingHired) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İşe alındı olarak işaretle'),
        content: const Text(
          'Bu görüşmede işe alımın gerçekleştiğini onaylıyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Onayla'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _markingHired = true);
    try {
      await ref
          .read(chatServiceProvider)
          .markConversationHired(widget.conversationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Görüşme işe alındı olarak işaretlendi.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İşlem tamamlanamadı. Tekrar deneyin.')),
        );
      }
    } finally {
      if (mounted) setState(() => _markingHired = false);
    }
  }

  @override
  void dispose() {
    ref.read(currentChatIdProvider.notifier).state = null;
    _conversationSubscription?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return;
    _messageController.clear();
    await ref.read(chatServiceProvider).sendMessage(
          conversationId: widget.conversationId,
          senderId: uid,
          text: text,
        );
  }

  void _showReportDialog() {
    if (_otherParticipantId == null) return;
    showDialog(
      context: context,
      builder: (context) => ReportDialog(
        targetType: ReportTargetType.user,
        targetId: _otherParticipantId!,
        targetName: 'Kullanıcı',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myUid = ref.watch(authStateProvider).value?.uid;
    final messagesStream = ref.watch(chatServiceProvider).watchMessages(widget.conversationId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sohbet'),
        actions: [
          if (_otherParticipantId != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'report') {
                  _showReportDialog();
                } else if (value == 'hired') {
                  _markAsHired();
                }
              },
              itemBuilder: (context) => [
                if (_conversation?.hired != true)
                  const PopupMenuItem(
                    value: 'hired',
                    child: Row(
                      children: [
                        Icon(Icons.handshake_outlined),
                        SizedBox(width: 12),
                        Text('İşe Alındı Olarak İşaretle'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.flag_outlined, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Kullanıcıyı Bildir'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          if (_conversation?.hired == true && _otherParticipantId != null)
            Material(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.verified_outlined,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text('Bu görüşmede işe alım gerçekleşti.'),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () async {
                          await context.push('/chat/${widget.conversationId}/rate');
                        },
                        child: const Text('Deneyimini Değerlendir'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return const Center(child: Text('Henüz mesaj yok, ilk mesajı gönderin.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == myUid;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? Theme.of(context).primaryColor : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
                        ),
                        child: Text(
                          message.text,
                          style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 14),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Mesajınızı yazın...',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send_rounded, color: Theme.of(context).primaryColor),
                  onPressed: _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
