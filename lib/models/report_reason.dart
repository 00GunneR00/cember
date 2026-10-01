/// Why a photo is being reported — mirrors the backend's ReportReason.
enum ReportReason {
  inappropriate('Inappropriate', 'Müstehcen ya da uygunsuz'),
  violence('Violence', 'Şiddet, nefret ya da taciz'),
  privacy('Privacy', 'Bu benim, izinsiz paylaşıldı'),
  spam('Spam', 'Spam ya da alakasız'),
  other('Other', 'Başka bir sebep');

  const ReportReason(this.apiValue, this.label);

  final String apiValue;
  final String label;
}
