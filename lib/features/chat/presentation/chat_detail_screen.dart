import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/conversation.dart';
import '../../../shared/models/message.dart';
import '../../../shared/models/report.dart';
import '../../../shared/providers/profile_provider.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/chat_service.dart';
import '../../../shared/widgets/report_dialog.dart';
import '../../../shared/widgets/video_player_dialog.dart';
import '../../talent_pool/services/talent_pool_service.dart';
import '../domain/interview_slot_model.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  const ChatDetailScreen({super.key, required this.conversationId, this.initialText});

  final String conversationId;
  final String? initialText;

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
    if (widget.initialText != null && widget.initialText!.isNotEmpty) {
      _messageController.text = widget.initialText!;
    }
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

  Future<void> _addToTalentPool() async {
    if (_otherParticipantId == null) return;
    final myUid = ref.read(authStateProvider).value?.uid;
    if (myUid == null) return;

    final otherProfile = ref.read(userProfileProvider(_otherParticipantId!)).value;
    final candidateName = (otherProfile?.displayName?.isNotEmpty == true)
        ? otherProfile!.displayName!
        : (otherProfile?.email.isNotEmpty == true ? otherProfile!.email : 'Aday');

    final noteController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yetenek Havuzuna Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$candidateName kişisini gelecek sezon yetenek havuzunuza eklemek üzeresiniz.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Not Ekle (İsteğe Bağlı)',
                hintText: 'Örn: Resepsiyon için 2026 yaz dönemi adayı',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(talentPoolServiceProvider).addToTalentPool(
            employerId: myUid,
            candidateId: _otherParticipantId!,
            candidateName: candidateName,
            note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
            conversationId: widget.conversationId,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aday yetenek havuzunuza eklendi.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İşlem tamamlanamadı. Tekrar deneyin.')),
        );
      }
    }
  }

  Future<void> _showProposeInterviewDialog() async {
    final myUid = ref.read(authStateProvider).value?.uid;
    if (myUid == null) return;
    final l10n = AppLocalizations.of(context);

    final selectedSlots = <DateTime>[];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n?.proposeInterview ?? 'Mülakat Saati Öner'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Adaya sunmak için 1-3 adet tarih ve saat önerisi ekleyin:'),
                    const SizedBox(height: 12),
                    ...selectedSlots.map(
                      (slot) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.event),
                        title: Text(DateFormat('dd MMMM yyyy HH:mm').format(slot)),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            setDialogState(() {
                              selectedSlots.remove(slot);
                            });
                          },
                        ),
                      ),
                    ),
                    if (selectedSlots.length < 3)
                      OutlinedButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(const Duration(days: 1)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 30)),
                          );
                          if (date == null || !context.mounted) return;

                          final time = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 10, minute: 0),
                          );
                          if (time == null) return;

                          final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                          setDialogState(() {
                            selectedSlots.add(dt);
                          });
                        },
                        icon: const Icon(Icons.add_alarm),
                        label: const Text('Tarih/Saat Ekle'),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n?.cancelButton ?? 'Vazgeç'),
                ),
                FilledButton(
                  onPressed: selectedSlots.isEmpty
                      ? null
                      : () async {
                          Navigator.pop(context);
                          await ref.read(chatServiceProvider).proposeInterviewSlots(
                                conversationId: widget.conversationId,
                                proposedBy: myUid,
                                slots: selectedSlots,
                              );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n?.interviewSlotsProposedSuccess ?? 'Mülakat saatleri gönderildi.'),
                              ),
                            );
                          }
                        },
                  child: const Text('Önerileri Gönder'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final myUid = ref.watch(authStateProvider).value?.uid;
    final myProfile = ref.watch(currentUserProfileProvider).value;
    final isEmployer = myProfile?.userType == 'employer';
    final l10n = AppLocalizations.of(context);
    final messagesStream = ref.watch(chatServiceProvider).watchMessages(widget.conversationId);
    final interviewSlotsStream = ref.watch(chatServiceProvider).watchInterviewSlots(widget.conversationId);
    final otherProfile = _otherParticipantId != null
        ? ref.watch(userProfileProvider(_otherParticipantId!)).value
        : null;
    final isOtherAvailableImmediately = otherProfile != null &&
        otherProfile.userType != 'employer' &&
        otherProfile.availableImmediately;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Sohbet'),
            if (isOtherAvailableImmediately) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt_rounded, size: 14, color: Colors.green.shade700),
                    const SizedBox(width: 2),
                    Text(
                      'Hemen Başlayabilir',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (otherProfile?.introVideoUrl != null && otherProfile!.introVideoUrl!.isNotEmpty) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => VideoPlayerDialog.show(
                  context,
                  videoUrl: otherProfile.introVideoUrl!,
                  title: '${otherProfile.displayName ?? "Tanıtım"} - Video',
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_circle_fill_rounded, size: 14, color: Colors.blue.shade700),
                      const SizedBox(width: 3),
                      Text(
                        'Tanıtım Videosu',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_otherParticipantId != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'report') {
                  _showReportDialog();
                } else if (value == 'hired') {
                  _markAsHired();
                } else if (value == 'talent_pool') {
                  _addToTalentPool();
                } else if (value == 'propose_interview') {
                  _showProposeInterviewDialog();
                }
              },
              itemBuilder: (context) => [
                if (isEmployer || _conversation?.posterId == myUid)
                  PopupMenuItem(
                    value: 'propose_interview',
                    child: Row(
                      children: [
                        const Icon(Icons.event_available_outlined, color: Colors.blue),
                        const SizedBox(width: 12),
                        Text(l10n?.proposeInterview ?? 'Mülakat Saati Öner'),
                      ],
                    ),
                  ),
                if (isEmployer)
                  const PopupMenuItem(
                    value: 'talent_pool',
                    child: Row(
                      children: [
                        Icon(Icons.person_add_alt_1_outlined),
                        SizedBox(width: 12),
                        Text('Yetenek Havuzuna Ekle'),
                      ],
                    ),
                  ),
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
          StreamBuilder<List<InterviewSlot>>(
            stream: interviewSlotsStream,
            builder: (context, snapshot) {
              final slots = snapshot.data ?? [];
              if (slots.isEmpty) return const SizedBox.shrink();
              final latest = slots.first;

              final isConfirmed = latest.status == 'confirmed';
              final isProposedByMe = latest.proposedBy == myUid;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isConfirmed ? Colors.green.shade50 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isConfirmed ? Colors.green.shade300 : Colors.blue.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isConfirmed ? Icons.check_circle : Icons.event_available,
                          color: isConfirmed ? Colors.green.shade700 : Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isConfirmed
                              ? (l10n?.interviewConfirmedTitle ?? 'Mülakat Onaylandı')
                              : (l10n?.interviewProposalTitle ?? 'Mülakat Zamanı Önerisi'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isConfirmed ? Colors.green.shade900 : Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (isConfirmed && latest.selectedSlot != null)
                      Text(
                        'Randevu Zamanı: ${DateFormat('dd MMMM yyyy - HH:mm').format(latest.selectedSlot!)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade900,
                        ),
                      )
                    else if (isProposedByMe)
                      Text(
                        l10n?.waitingCandidateSelection ?? 'Adayın mülakat saati seçimi bekleniyor...',
                        style: TextStyle(fontSize: 13, color: Colors.blue.shade900),
                      )
                    else ...[
                      const Text(
                        'Lütfen uygun olduğunuz mülakat saatini seçin:',
                        style: TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: latest.slots.map((slot) {
                          final label = DateFormat('dd MMM HH:mm').format(slot);
                          return ChoiceChip(
                            label: Text(label),
                            selected: false,
                            onSelected: (_) async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(l10n?.interviewConfirmedTitle ?? 'Mülakat Saatini Onayla'),
                                  content: Text('$label zamanını onaylıyor musunuz?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: Text(l10n?.cancelButton ?? 'Vazgeç'),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Onayla'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await ref.read(chatServiceProvider).confirmInterviewSlot(
                                      conversationId: widget.conversationId,
                                      slotId: latest.id,
                                      selectedSlot: slot,
                                    );
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              );
            },
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
