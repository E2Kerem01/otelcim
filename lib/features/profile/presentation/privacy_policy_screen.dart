import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final date = '${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}';
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.privacyPolicyTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, l10n.privacyPolicyHeader),
            const SizedBox(height: 8),
            Text(
              l10n.privacyPolicyLastUpdated(date),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              context,
              title: l10n.privacyPolicySection1Title,
              content: l10n.privacyPolicySection1Content,
            ),
            const SizedBox(height: 12),
            _buildSectionCard(
              context,
              title: l10n.privacyPolicySection2Title,
              content: l10n.privacyPolicySection2Content,
            ),
            const SizedBox(height: 12),
            _buildSectionCard(
              context,
              title: l10n.privacyPolicySection3Title,
              content: l10n.privacyPolicySection3Content,
            ),
            const SizedBox(height: 12),
            _buildSectionCard(
              context,
              title: l10n.privacyPolicySection4Title,
              content: l10n.privacyPolicySection4Content,
            ),
            const SizedBox(height: 12),
            _buildSectionCard(
              context,
              title: l10n.privacyPolicySection5Title,
              content: l10n.privacyPolicySection5Content,
            ),
            const SizedBox(height: 12),
            _buildSectionCard(
              context,
              title: l10n.privacyPolicySection6Title,
              content: l10n.privacyPolicySection6Content,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildSectionCard(BuildContext context, {required String title, required String content}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
