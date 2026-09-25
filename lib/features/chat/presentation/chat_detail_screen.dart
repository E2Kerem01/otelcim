import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/error/error_mapper.dart';
import '../../../shared/error/error_reporter.dart';
import '../../../shared/models/conversation.dart';
import '../../../shared/models/report.dart';
import '../../../shared/providers/profile_provider.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/chat_service.dart';
import '../../../shared/widgets/report_dialog.dart';
import '../../talent_pool/services/talent_pool_service.dart';
import 'widgets/chat_detail_widgets.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.coreMarkHiredDialogTitle),
        content: Text(l10n.coreMarkHiredDialogDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.coreConfirmAction),
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
          SnackBar(content: Text(l10n.coreConversationMarkedHiredSuccess)),
        );
      }
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'ChatDetailScreen._markHired');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mapToFailure(error, l10n).message)),
        );
      }
    } finally {
      if (mounted) setState(() => _markingHired = false);
    }
  }

  @override
  void dispose() {
    ref.read(currentChatIdProvider.notifier).state = null;
    unawaited(_conversationSubscription?.cancel() ?? Future.value());
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return;
    _messageController.clear();
    try {
      await ref.read(chatServiceProvider).sendMessage(
            conversationId: widget.conversationId,
            senderId: uid,
            text: text,
          );
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'ChatDetailScreen._send');
      if (mounted) {
        // Give the text back so nothing typed is lost on failure.
        _messageController.text = text;
        final l10n = AppLocalizations.of(context);
        final errorMsg = mapToFailure(error, l10n).message;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n?.coreMessageSendFailed(errorMsg) ?? 'Mesaj gönderilemedi: $errorMsg')),
        );
      }
    }
  }

  void _showReportDialog() {
    if (_otherParticipantId == null) return;
    final l10n = AppLocalizations.of(context);
    unawaited(showDialog(
      context: context,
      builder: (context) => ReportDialog(
        targetType: ReportTargetType.user,
        targetId: _otherParticipantId!,
        targetName: l10n?.coreUserLabel ?? 'Kullanıcı',
      ),
    ));
  }

  Future<void> _addToTalentPool() async {
    if (_otherParticipantId == null) return;
    final myUid = ref.read(authStateProvider).value?.uid;
    if (myUid == null) return;
    final l10n = AppLocalizations.of(context);

    final otherProfile = ref.read(userProfileProvider(_otherParticipantId!)).value;
    final defaultCandidate = l10n?.coreCandidateLabel ?? 'Aday';
    final candidateName = (otherProfile?.displayName?.isNotEmpty == true)
        ? otherProfile!.displayName!
        : (otherProfile?.email.isNotEmpty == true ? otherProfile!.email : defaultCandidate);

    final noteController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.addToTalentPool ?? 'Yetenek Havuzuna Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.coreAddToTalentPoolPrompt(candidateName) ??
                  '$candidateName kişisini gelecek sezon yetenek havuzunuza eklemek üzeresiniz.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                labelText: l10n?.coreAddNoteOptional ?? 'Not Ekle (İsteğe Bağlı)',
                hintText: l10n?.coreAddNoteHint ?? 'Örn: Resepsiyon için 2026 yaz dönemi adayı',
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n?.cancelButton ?? 'Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n?.coreAddAction ?? 'Ekle'),
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
          SnackBar(content: Text(l10n?.candidateAddedToTalentPool ?? 'Aday yetenek havuzunuza eklendi.')),
        );
      }
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'ChatDetailScreen._addToTalentPool');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mapToFailure(error, l10n).message)),
        );
      }
    }
  }

  Future<void> _showProposeInterviewDialog() async {
    final myUid = ref.read(authStateProvider).value?.uid;
    if (myUid == null) return;
    final l10n = AppLocalizations.of(context);

    final selectedSlots = <DateTime>[];

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(l10n?.proposeInterview ?? 'Mülakat Saati Öner'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n?.coreInterviewSlotsInstruction ?? 'Adaya sunmak için 1-3 adet tarih ve saat önerisi ekleyin:'),
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
                            context: dialogContext,
                            initialDate: DateTime.now().add(const Duration(days: 1)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 30)),
                          );
                          if (date == null || !dialogContext.mounted) return;

                          final time = await showTimePicker(
                            context: dialogContext,
                            initialTime: const TimeOfDay(hour: 10, minute: 0),
                          );
                          if (time == null) return;

                          final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                          setDialogState(() {
                            selectedSlots.add(dt);
                          });
                        },
                        icon: const Icon(Icons.add_alarm),
                        label: Text(l10n?.coreAddDateTimeAction ?? 'Tarih/Saat Ekle'),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(l10n?.cancelButton ?? 'Vazgeç'),
                ),
                FilledButton(
                  onPressed: selectedSlots.isEmpty
                      ? null
                      : () async {
                          Navigator.pop(dialogContext);
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
                  child: Text(l10n?.coreSendProposalsAction ?? 'Önerileri Gönder'),
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
    final otherProfile = _otherParticipantId != null
        ? ref.watch(userProfileProvider(_otherParticipantId!)).value
        : null;

    return Scaffold(
      appBar: AppBar(
        title: ChatAppBarTitle(otherProfile: otherProfile),
        actions: [
          if (_otherParticipantId != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'report') {
                  _showReportDialog();
                } else if (value == 'hired') {
                  unawaited(_markAsHired());
                } else if (value == 'talent_pool') {
                  unawaited(_addToTalentPool());
                } else if (value == 'propose_interview') {
                  unawaited(_showProposeInterviewDialog());
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
                  PopupMenuItem(
                    value: 'talent_pool',
                    child: Row(
                      children: [
                        const Icon(Icons.person_add_alt_1_outlined),
                        const SizedBox(width: 12),
                        Text(l10n?.addToTalentPool ?? 'Yetenek Havuzuna Ekle'),
                      ],
                    ),
                  ),
                if (_conversation?.hired != true)
                  PopupMenuItem(
                    value: 'hired',
                    child: Row(
                      children: [
                        const Icon(Icons.handshake_outlined),
                        const SizedBox(width: 12),
                        Text(l10n?.coreMarkAsHiredAction ?? 'İşe Alındı Olarak İşaretle'),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      const Icon(Icons.flag_outlined, color: Colors.red),
                      const SizedBox(width: 12),
                      Text(l10n?.coreReportUserAction ?? 'Kullanıcıyı Bildir'),
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
            ChatHiredBanner(conversationId: widget.conversationId),
          InterviewSlotBanner(
            conversationId: widget.conversationId,
            myUid: myUid,
          ),
          Expanded(
            child: ChatMessageList(
              conversationId: widget.conversationId,
              myUid: myUid,
            ),
          ),
          ChatMessageComposer(
            controller: _messageController,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}
