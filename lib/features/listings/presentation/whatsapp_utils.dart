String? parsePhoneNumber(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;

  final regExp = RegExp(
    r'(?:\+?90|0)?\s*([5][0-9]{2}[\s.-]*[0-9]{3}[\s.-]*[0-9]{2}[\s.-]*[0-9]{2})',
  );
  final match = regExp.firstMatch(raw);

  if (match != null) {
    final digits = match.group(1)!.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) {
      return '90$digits';
    }
  }

  final allDigits = raw.replaceAll(RegExp(r'\D'), '');
  if (allDigits.length == 10 && allDigits.startsWith('5')) {
    return '90$allDigits';
  } else if (allDigits.length == 11 && allDigits.startsWith('05')) {
    return '90${allDigits.substring(1)}';
  } else if (allDigits.length == 12 && allDigits.startsWith('905')) {
    return allDigits;
  }

  return null;
}

String buildWhatsAppUrl({
  required String phone,
  required String message,
}) {
  return 'https://wa.me/$phone?text=${Uri.encodeComponent(message)}';
}
