import 'package:flutter/material.dart';

import '../../domain/message_template.dart';

/// Bottom sheet shown before the first message of a new conversation.
/// Returns the chosen (and possibly edited) message text, or null if the
/// user dismissed the sheet / chose to write their own message from scratch.
class MessageTemplateSheet extends StatelessWidget {
  const MessageTemplateSheet({super.key, required this.listingTitle});

  final String listingTitle;

  static Future<String?> show(BuildContext context, {required String listingTitle}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => MessageTemplateSheet(listingTitle: listingTitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'İlk mesajını hazırlayalım',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Bir şablon seç, göndermeden önce düzenleyebilirsin.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ...messageTemplates.map(
                (template) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Text(template.icon, style: const TextStyle(fontSize: 22)),
                    title: Text(template.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      template.build(listingTitle),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 12.5),
                    ),
                    onTap: () => Navigator.pop(context, template.build(listingTitle)),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              OutlinedButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Kendi mesajımı yazacağım'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
