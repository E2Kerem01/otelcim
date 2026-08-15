import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/message.dart';
import '../../../../shared/models/user_profile.dart';
import '../../../../shared/services/chat_service.dart';
import '../../../../shared/widgets/video_player_dialog.dart';
import '../../domain/interview_slot_model.dart';

/// Presentational pieces of [ChatDetailScreen] (see that file) split out to
/// keep the screen's build method focused on layout/wiring rather than the
/// markup for each section.

/// AppBar title: "Sohbet" plus the other participant's availability/intro
/// video badges, when applicable.
class ChatAppBarTitle extends StatelessWidget {
  const ChatAppBarTitle({super.key, required this.otherProfile});

  final UserProfile? otherProfile;

  @override
  Widget build(BuildContext context) {
    final profile = otherProfile;
    final isOtherAvailableImmediately = profile != null &&
        profile.userType != 'employer' &&
        profile.availableImmediately;
    final hasIntroVideo =
        profile?.introVideoUrl != null && profile!.introVideoUrl!.isNotEmpty;

    return Row(
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
        if (hasIntroVideo) ...[
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => VideoPlayerDialog.show(
              context,
              videoUrl: profile.introVideoUrl!,
              title: '${profile.displayName ?? "Tanıtım"} - Video',
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
    );
  }
}

/// Banner shown once a conversation is marked as hired, with a link to rate
/// the experience.
class ChatHiredBanner extends StatelessWidget {
  const ChatHiredBanner({super.key, required this.conversationId});

  final String conversationId;

  @override
  Widget build(BuildContext context) {
    return Material(
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
                  await context.push('/chat/$conversationId/rate');
                },
                child: const Text('Deneyimini Değerlendir'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Latest interview slot proposal/confirmation banner. Watches its own
/// stream so the parent screen doesn't need to plumb it through.
class InterviewSlotBanner extends ConsumerWidget {
  const InterviewSlotBanner({
    super.key,
    required this.conversationId,
    required this.myUid,
  });

  final String conversationId;
  final String? myUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<List<InterviewSlot>>(
      stream: ref.watch(chatServiceProvider).watchInterviewSlots(conversationId),
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
                                conversationId: conversationId,
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
    );
  }
}

/// The scrolling message list, watching its own messages stream.
class ChatMessageList extends ConsumerWidget {
  const ChatMessageList({
    super.key,
    required this.conversationId,
    required this.myUid,
  });

  final String conversationId;
  final String? myUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<Message>>(
      stream: ref.watch(chatServiceProvider).watchMessages(conversationId),
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
    );
  }
}

/// Bottom text field + send button.
class ChatMessageComposer extends StatelessWidget {
  const ChatMessageComposer({
    super.key,
    required this.controller,
    required this.onSend,
  });

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Mesajınızı yazın...',
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.send_rounded, color: Theme.of(context).primaryColor),
            onPressed: onSend,
          ),
        ],
      ),
    );
  }
}
