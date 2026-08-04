import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/features/listings/presentation/listing_qr_poster_screen.dart';
import 'package:otelcim/features/listings/presentation/whatsapp_utils.dart';

void main() {
  group('WhatsApp & Phone Parsing Helper Tests (Spec 035)', () {
    test('parsePhoneNumber correctly parses Turkish mobile phone numbers', () {
      expect(parsePhoneNumber('0532 123 45 67'), equals('905321234567'));
      expect(parsePhoneNumber('+90 555 987 65 43'), equals('905559876543'));
      expect(parsePhoneNumber('5441112233'), equals('905441112233'));
      expect(parsePhoneNumber('0544-333-2211'), equals('905443332211'));
      expect(parsePhoneNumber('İletişim Tel: 05321234567'), equals('905321234567'));
    });

    test('parsePhoneNumber returns null for strings without valid phone number', () {
      expect(parsePhoneNumber(null), isNull);
      expect(parsePhoneNumber(''), isNull);
      expect(parsePhoneNumber('   '), isNull);
      expect(parsePhoneNumber('Sadece e-posta: info@hotel.com'), isNull);
      expect(parsePhoneNumber('123'), isNull);
    });

    test('buildWhatsAppUrl generates correct URL encoded WhatsApp link', () {
      final urlTr = buildWhatsAppUrl(
        phone: '905321234567',
        listingTitle: 'Resepsiyonist',
        posterName: 'Hilton Hotel',
        languageCode: 'tr',
      );

      expect(urlTr, startsWith('https://wa.me/905321234567?text='));
      expect(urlTr, contains(Uri.encodeComponent('Resepsiyonist')));
      expect(urlTr, contains(Uri.encodeComponent('Hilton Hotel')));

      final urlEn = buildWhatsAppUrl(
        phone: '905321234567',
        listingTitle: 'Receptionist',
        posterName: 'Hilton Hotel',
        languageCode: 'en',
      );

      expect(urlEn, startsWith('https://wa.me/905321234567?text='));
      expect(urlEn, contains(Uri.encodeComponent('Receptionist')));
    });

    test('ListingQrPosterScreen generates public listing URL correctly', () {
      const screen = ListingQrPosterScreen(listingId: 'listing_123');
      expect(screen.getPublicListingUrl('listing_123'), equals('https://otelcim.app/listing/listing_123'));
    });
  });
}
