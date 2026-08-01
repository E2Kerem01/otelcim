import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentChatIdProvider.notifier).state = widget.conversationId;
    });
    _loadOtherParticipant();
  }

  Future<void> _loadOtherParticipant() async {
    final myUid = ref.read(authStateProvider).value?.uid;
    if (myUid == null) return;
    final conversation = await ref.read(chatServiceProvider).getConversation(widget.conversationId);
    if (conversation != null && mounted) {
      setState(() => _otherParticipantId = conversation.otherParticipant(myUid));
    }
  }

  @override
  void dispose() {
    ref.read(currentChatIdProvider.notifier).state = null;
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
        targetType: TargetType.user,
        targetId: _otherParticipantId!,
        targetName: 'Kullanıcı', // Generic name since we don't have user details loaded
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
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.flag_outlined),
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
