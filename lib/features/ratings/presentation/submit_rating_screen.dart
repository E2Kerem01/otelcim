import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/error/error_mapper.dart';
import '../../../shared/error/error_reporter.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/chat_service.dart';
import '../domain/rating_model.dart';
import '../services/rating_service.dart';

class SubmitRatingScreen extends ConsumerStatefulWidget {
  const SubmitRatingScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<SubmitRatingScreen> createState() =>
      _SubmitRatingScreenState();
}

class _SubmitRatingScreenState extends ConsumerState<SubmitRatingScreen> {
  final _reviewController = TextEditingController();
  int _stars = 0;
  bool _submitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_stars == 0 || _submitting) {
      if (_stars == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen bir yıldız puanı seçin.')),
        );
      }
      return;
    }

    final uid = ref.read(authStateProvider).value?.uid;
    final conversation = await ref
        .read(chatServiceProvider)
        .getConversation(widget.conversationId);
    if (!mounted) return;
    if (uid == null || conversation == null || !conversation.hired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu görüşme değerlendirilemiyor.')),
      );
      return;
    }
    if (uid != conversation.posterId && uid != conversation.seekerId) {
      context.go('/');
      return;
    }

    setState(() => _submitting = true);
    final review = _reviewController.text.trim();
    try {
      await ref.read(ratingServiceProvider).submitRating(
            Rating(
              id: '${widget.conversationId}_$uid',
              conversationId: widget.conversationId,
              raterId: uid,
              ratedUserId: conversation.otherParticipant(uid),
              stars: _stars,
              reviewText: review.isEmpty ? null : review,
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Değerlendirmeniz kaydedildi.')),
        );
        context.pop();
      }
    } on StateError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'SubmitRatingScreen._submit');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mapToFailure(error).message)),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Deneyimini Değerlendir')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Deneyimin nasıldı?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          const Text('1 ile 5 arasında bir puan seçin.'),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final value = index + 1;
              return IconButton(
                tooltip: '$value yıldız',
                iconSize: 42,
                onPressed: () => setState(() => _stars = value),
                icon: Icon(
                  value <= _stars ? Icons.star_rounded : Icons.star_border_rounded,
                  color: Colors.amber.shade700,
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _reviewController,
            maxLength: 500,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Yorum (isteğe bağlı)',
              hintText: 'Deneyiminizi kısaca paylaşın',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(_submitting ? 'Gönderiliyor...' : 'Değerlendirmeyi Gönder'),
          ),
        ],
      ),
    );
  }
}
