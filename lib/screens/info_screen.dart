import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class InfoSection {
  const InfoSection({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;
}

/// A read-only page of titled paragraphs — backs "Gizlilik & İzinler",
/// "Yardım & Geri Bildirim" and "Topluluk & Güvenlik" on Profil.
class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key, required this.title, required this.sections, this.footer});

  final String title;
  final List<InfoSection> sections;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: Text(title, style: AppTextStyles.headlineSm.copyWith(color: colors.primary)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.marginMobile),
        children: [
          for (final section in sections)
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: colors.surfaceContainerLowest, borderRadius: BorderRadius.circular(AppRadius.cardLarge)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(section.icon, color: colors.secondary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(section.title, style: AppTextStyles.labelLg.copyWith(color: colors.primary)),
                        const SizedBox(height: 4),
                        Text(section.body, style: AppTextStyles.bodySm.copyWith(color: colors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (footer != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              footer!,
              style: AppTextStyles.labelSm.copyWith(color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

const privacyInfoSections = [
  InfoSection(
    icon: Icons.group_outlined,
    title: 'Fotoğraflarını kimler görür?',
    body: 'Bir çembere eklediğin fotoğrafları o çemberin sahibi ve çembere katılan herkes görebilir.',
  ),
  InfoSection(
    icon: Icons.public,
    title: 'Herkese açık çemberler',
    body:
        'Herkese açık çemberler Keşfet\'te listelenir ve isteyen herkes katılabilir. '
        'Yalnızca davet ettiğin kişilerin görmesini istiyorsan çemberi Kilitli oluştur.',
  ),
  InfoSection(
    icon: Icons.location_on_outlined,
    title: 'Fotoğraf bilgileri',
    body:
        'Telefonlar fotoğrafa çekildiği yer ve cihaz gibi gizli bilgiler ekler. Çember bu bilgilerin hepsini '
        'yükleme sırasında siler; çemberdekiler fotoğrafın nerede çekildiğini göremez.',
  ),
  InfoSection(
    icon: Icons.photo_camera_outlined,
    title: 'İzinler',
    body:
        'Kamera izni Şipşak ve QR ile katılma için, galeri izni fotoğraf seçmek için kullanılır. '
        'İzinleri istediğin zaman telefonunun Ayarlar > Uygulamalar > Çember bölümünden değiştirebilirsin.',
  ),
  InfoSection(
    icon: Icons.delete_outline,
    title: 'Çember silme',
    body: 'Bir çemberin silinmesi katılımcıların onayına sunulur; yeterli onay gelince çember ve fotoğrafları kaldırılır.',
  ),
  InfoSection(
    icon: Icons.person_remove_outlined,
    title: 'Hesabını silmek',
    body: 'Profil > Hesabı Sil ile hesabını, çemberlerini, fotoğraflarını ve yorumlarını kalıcı olarak silebilirsin.',
  ),
];

const helpInfoSections = [
  InfoSection(
    icon: Icons.add_circle_outline,
    title: 'Nasıl çember oluştururum?',
    body: 'Albümler sekmesinde "Yeni Çember"e dokun, etkinlik adını ve tarihini gir, fotoğraf yükleme yöntemini seç.',
  ),
  InfoSection(
    icon: Icons.qr_code_2,
    title: 'Arkadaşlarımı nasıl davet ederim?',
    body: 'Çemberin sayfasından QR davetini aç. Arkadaşların Albümler\'deki "QR ile Katıl" ile kodu okutarak çembere katılabilir.',
  ),
  InfoSection(
    icon: Icons.add_a_photo_outlined,
    title: 'Fotoğraf nasıl eklerim?',
    body:
        'Alttaki + butonuna dokun ve çemberi seç ya da çemberin sayfasından ekle. '
        'Şipşak ile çektiğin fotoğraf anında yüklenir.',
  ),
  InfoSection(
    icon: Icons.folder_zip_outlined,
    title: 'Fotoğrafları nasıl indiririm?',
    body: 'Çemberin sayfasındaki indirme seçeneğiyle tüm fotoğrafları tek bir ZIP dosyası olarak alabilirsin.',
  ),
  InfoSection(
    icon: Icons.account_circle_outlined,
    title: 'Telefonumu değiştirirsem?',
    body: 'Profil > Bağlı Hesaplar\'dan Google hesabını bağla. Yeni telefonda "Google ile devam et" ile çemberlerine geri dönersin.',
  ),
];

const communityInfoSections = [
  InfoSection(
    icon: Icons.favorite_outline,
    title: 'Saygılı ol',
    body: 'Çemberler ortak anılar içindir. Başkalarını rahatsız edecek, aşağılayıcı ya da nefret içeren paylaşımlar yapma.',
  ),
  InfoSection(
    icon: Icons.privacy_tip_outlined,
    title: 'İzin al',
    body: 'Birinin fotoğrafını paylaşmadan önce onun da bunu isteyeceğinden emin ol; özellikle çocukların fotoğraflarında dikkatli ol.',
  ),
  InfoSection(
    icon: Icons.block,
    title: 'Yasak içerik',
    body: 'Müstehcen, şiddet içeren, yasa dışı ya da başkasının telif hakkını ihlal eden içerikler paylaşılamaz.',
  ),
  InfoSection(
    icon: Icons.flag_outlined,
    title: 'Şikayet et ve engelle',
    body: 'Bir fotoğrafın ⋯ menüsünden onu şikayet edebilir ya da paylaşan kişiyi engelleyebilirsin. '
        'Şikayet ettiğin fotoğrafı artık görmezsin; birkaç kişi şikayet ettiğinde fotoğraf herkesten gizlenir ve ekibimiz inceler. '
        'Kendi fotoğraflarını aynı menüden silebilirsin.',
  ),
  InfoSection(
    icon: Icons.storefront_outlined,
    title: 'Marka çemberleri',
    body: 'Markalı çemberlerde fotoğrafının ticari kullanımına izin verip vermemek tamamen senin tercihindir.',
  ),
];
