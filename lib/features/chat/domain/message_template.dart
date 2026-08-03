class MessageTemplate {
  const MessageTemplate({required this.title, required this.icon, required this.build});

  final String title;
  final String icon;
  final String Function(String listingTitle) build;
}

final List<MessageTemplate> messageTemplates = [
  MessageTemplate(
    title: 'Kendimi Tanıtayım',
    icon: '👋',
    build: (listingTitle) =>
        'Merhaba, "$listingTitle" ilanınız için yazıyorum. Bu alanda deneyimim var ve pozisyonla ilgileniyorum. Uygun olduğunuzda konuşabilir miyiz?',
  ),
  MessageTemplate(
    title: 'Müsaitlik Bildireyim',
    icon: '📅',
    build: (listingTitle) =>
        'Merhaba, "$listingTitle" ilanınızla ilgileniyorum. Hemen başlayabilecek durumdayım, uygun olduğunuz bir zamanda görüşebilir miyiz?',
  ),
  MessageTemplate(
    title: 'Deneyimimi Özetleyeyim',
    icon: '💼',
    build: (listingTitle) =>
        'Merhaba, "$listingTitle" pozisyonu için başvurmak istiyorum. Bu alanda daha önce çalıştım ve gerekli deneyime sahibim. Detayları konuşabilir miyiz?',
  ),
  MessageTemplate(
    title: 'Maaş Hakkında Soru Sorayım',
    icon: '💰',
    build: (listingTitle) =>
        'Merhaba, "$listingTitle" ilanınız ilgimi çekti. Maaş ve çalışma koşulları hakkında biraz daha bilgi alabilir miyim?',
  ),
];
