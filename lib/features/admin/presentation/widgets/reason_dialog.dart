import 'package:flutter/material.dart';

/// Shows a confirm dialog that optionally collects a moderation reason.
///
/// Returns the trimmed reason (empty when [showReasonField] is false) once
/// the admin confirms, or `null` when the dialog is cancelled or dismissed.
///
/// The dialog owns its [TextEditingController] and disposes it in its own
/// `State.dispose`, i.e. only after the route has finished its exit
/// transition. Disposing a caller-owned controller right after
/// `await showDialog(...)` returned used to tear it down while the closing
/// dialog still rendered the TextField, which tripped
/// `'_dependents.isEmpty'` / wrong-build-scope assertions after every
/// reject/remove/ban action.
Future<String?> showReasonDialog(
  BuildContext context, {
  required String title,
  String? message,
  bool showReasonField = true,
  bool reasonRequired = true,
  String? reasonLabel,
  String? reasonHint,
  String requiredError = 'Sebep girmeniz gerekiyor.',
  String confirmLabel = 'Onayla',
  int maxLines = 2,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _ReasonDialog(
      title: title,
      message: message,
      showReasonField: showReasonField,
      reasonRequired: reasonRequired,
      reasonLabel: reasonLabel ??
          (reasonRequired ? 'Sebep (zorunlu)' : 'Sebep (isteğe bağlı)'),
      reasonHint: reasonHint,
      requiredError: requiredError,
      confirmLabel: confirmLabel,
      maxLines: maxLines,
    ),
  );
}

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({
    required this.title,
    required this.message,
    required this.showReasonField,
    required this.reasonRequired,
    required this.reasonLabel,
    required this.reasonHint,
    required this.requiredError,
    required this.confirmLabel,
    required this.maxLines,
  });

  final String title;
  final String? message;
  final bool showReasonField;
  final bool reasonRequired;
  final String reasonLabel;
  final String? reasonHint;
  final String requiredError;
  final String confirmLabel;
  final int maxLines;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final value = _controller.text.trim();
    if (widget.showReasonField && widget.reasonRequired && value.isEmpty) {
      setState(() => _error = widget.requiredError);
      return;
    }
    Navigator.pop(context, widget.showReasonField ? value : '');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.message != null) Text(widget.message!),
          if (widget.message != null && widget.showReasonField)
            const SizedBox(height: 12),
          if (widget.showReasonField)
            TextField(
              controller: _controller,
              autofocus: true,
              maxLines: widget.maxLines,
              decoration: InputDecoration(
                labelText: widget.reasonLabel,
                hintText: widget.reasonHint,
                errorText: _error,
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        FilledButton(onPressed: _confirm, child: Text(widget.confirmLabel)),
      ],
    );
  }
}
