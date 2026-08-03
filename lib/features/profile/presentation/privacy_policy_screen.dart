import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KVKK ve Gizlilik Politikası'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, 'Kişisel Verilerin Korunması ve Aydınlatma Metni'),
            const SizedBox(height: 8),
            Text(
              'Son Güncelleme: ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              context,
              title: '1. Veri Sorumlusu Hakkında',
              content:
                  '6698 sayılı Kişisel Verilerin Korunması Kanunu ("KVKK") uyarınca, Otelcim mobil uygulaması ("Otelcim") olarak kişisel verilerinizi aşağıda açıklanan amaçlar doğrultusunda; hukuka ve dürüstlük kurallarına uygun olarak işlemekte, muhafaza etmekte ve korumaktayız.',
            ),
            const SizedBox(height: 12),
            _buildSectionCard(
              context,
              title: '2. İşlenen Kişisel Verileriniz',
              content:
                  'Otelcim platformunu kullanırken aşağıdaki kişisel verileriniz işlenmektedir:\n\n'
                  '• Kimlik ve İletişim Bilgileri: Ad-soyad, e-posta adresi, telefon numarası.\n'
                  '• Profil Verileri: Profil fotoğrafı, konum, biyografi, iş tecrübeleri ve unvan bilgileri.\n'
                  '• İlan ve Başvuru Verileri: Oluşturduğunuz otel iş ilanları, ilan detayları ve aday mesajlaşmaları.\n'
                  '• Teknik ve Kullanım Verileri: Cihaz bilgileri, uygulama içi oturum ve işlem geçmişi.',
            ),
            const SizedBox(height: 12),
            _buildSectionCard(
              context,
              title: '3. Verilerin İşlenme Amaçları ve Hukuki Sebepler',
              content:
                  'Kişisel verileriniz, KVKK\'nın 5. ve 6. maddelerinde belirtilen hukuki sebeplere dayanarak aşağıdaki amaçlarla işlenir:\n\n'
                  '• Otel otomasyonu ve turizm iş ilanları platformu hizmetlerinin sunulması,\n'
                  '• İşveren ve iş arayanlar arasındaki iletişimin güvenli şekilde sağlanması,\n'
                  '• İşveren kimlik ve belge doğrulama süreçlerinin yürütülmesi,\n'
                  '• İlan öne çıkarma (Boost) ve satın alma işlemlerinin takibi,\n'
                  '• Yasal yükümlülüklerin yerine getirilmesi ve uyuşmazlıkların çözümü.',
            ),
            const SizedBox(height: 12),
            _buildSectionCard(
              context,
              title: '4. Kişisel Verilerin Aktarılması',
              content:
                  'Kişisel verileriniz, açık rızanız olmaksızın üçüncü şahıslara veya reklam ortaklarına aktarılmaz. Yalnızca yasal zorunluluk hallerinde yetkili kamu kurum ve kuruluşları ile paylaşılabilir.',
            ),
            const SizedBox(height: 12),
            _buildSectionCard(
              context,
              title: '5. KVKK Madde 11 Kapsamındaki Haklarınız',
              content:
                  'KVKK\'nın 11. maddesi uyarınca veri sahibi olarak aşağıdaki haklara sahipsiniz:\n\n'
                  '• Kişisel verilerinizin işlenip işlenmediğini öğrenme,\n'
                  '• İşlenmişse buna ilişkin bilgi talep etme,\n'
                  '• Verilerinizin işlenme amacını ve amacına uygun kullanılıp kullanılmadığını öğrenme,\n'
                  '• Eksik veya yanlış işlenmişse düzeltilmesini isteme,\n'
                  '• Verilerinizin silinmesini veya yok edilmesini talep etme (Hesabımı Sil mekanizması ile),\n'
                  '• Verilerinizin taşınabilirliğini talep etme (Verilerimi İndir mekanizması ile).',
            ),
            const SizedBox(height: 12),
            _buildSectionCard(
              context,
              title: '6. Veri Güvenliği ve İletişim',
              content:
                  'Verilerinizin güvenliğini sağlamak amacıyla güncel teknik ve idari tedbirler uygulanmaktadır. Haklarınıza ilişkin taleplerinizi "Gizlilik ve Veri Ayarları" ekranından veya destek@otelcim.app adresi üzerinden iletebilirsiniz.',
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
