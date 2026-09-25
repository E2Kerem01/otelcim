/// Prefix-search tokens stored on documents as `searchKeywords`, so admin
/// screens can find a user/listing among any number of documents with one
/// indexed `array-contains` query (Firestore has no full-text search).
///
/// Tokens are lowercased and Turkish letters are folded (ş→s, ı→i, ...), so
/// "ayse", "Ayşe" and "AYŞE" all match. Every word contributes its prefixes
/// from [minPrefix] to [maxPrefix] characters; an e-mail also contributes
/// the whole address and its local part.
library;

const int minPrefix = 2;
const int maxPrefix = 15;
const int _maxKeywords = 150;

const Map<String, String> _fold = {
  'ç': 'c', 'ğ': 'g', 'ı': 'i', 'i̇': 'i', 'ö': 'o', 'ş': 's', 'ü': 'u',
  'â': 'a', 'î': 'i', 'û': 'u',
};

/// Lowercases (Turkish-aware for İ/I) and folds diacritics.
String normalizeForSearch(String input) {
  final lower = input.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final ch = String.fromCharCode(rune);
    buffer.write(_fold[ch] ?? ch);
  }
  // Drop combining dot left over from some 'İ' encodings.
  return buffer.toString().replaceAll('̇', '');
}

Iterable<String> _words(String normalized) =>
    normalized.split(RegExp(r'[^a-z0-9@._+-]+')).where((w) => w.isNotEmpty);

/// Keywords for a document built from its searchable [fields]
/// (nulls/empties are ignored). Deterministic and capped in size.
List<String> buildSearchKeywords(Iterable<String?> fields) {
  final out = <String>{};
  for (final field in fields) {
    if (field == null || field.trim().isEmpty) continue;
    final normalized = normalizeForSearch(field.trim());
    if (normalized.contains('@')) {
      out.add(normalized);
      final local = normalized.split('@').first;
      _addPrefixes(out, local);
    }
    for (final word in _words(normalized)) {
      for (final part in word.split(RegExp(r'[@._+-]+'))) {
        _addPrefixes(out, part);
      }
    }
  }
  final list = out.toList()..sort();
  return list.length > _maxKeywords ? list.sublist(0, _maxKeywords) : list;
}

void _addPrefixes(Set<String> out, String word) {
  if (word.length < minPrefix) return;
  final end = word.length < maxPrefix ? word.length : maxPrefix;
  for (var i = minPrefix; i <= end; i++) {
    out.add(word.substring(0, i));
  }
}

/// The single token to query with `array-contains` for a user's search text
/// (the longest word, clipped to [maxPrefix]); the remaining words can be
/// checked client-side with [matchesAllWords]. Null when nothing searchable.
String? searchToken(String query) {
  final normalized = normalizeForSearch(query.trim());
  if (normalized.contains('@') && !normalized.contains(' ')) return normalized;
  final words = _words(normalized).where((w) => w.length >= minPrefix).toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  if (words.isEmpty) return null;
  final w = words.first;
  return w.length > maxPrefix ? w.substring(0, maxPrefix) : w;
}

/// True when every word of [query] is a prefix of some token in [keywords].
bool matchesAllWords(List<String> keywords, String query) {
  final set = keywords.toSet();
  return _words(normalizeForSearch(query.trim()))
      .where((w) => w.length >= minPrefix)
      .every((w) => set.contains(w.length > maxPrefix ? w.substring(0, maxPrefix) : w));
}
