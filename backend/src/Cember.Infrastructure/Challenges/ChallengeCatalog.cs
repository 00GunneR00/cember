using Cember.Domain.Entities;
using Cember.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Cember.Infrastructure.Challenges;

/// <summary>
/// The starter set of Keşfet challenges. Seeded on startup by slug and only inserted when missing,
/// so edits made later (e.g. from the admin panel) are never overwritten.
/// </summary>
public static class ChallengeCatalog
{
    public static IReadOnlyList<ChallengeTemplate> Starters { get; } =
    [
        Make("tek-kullanimlik-gece", "🎞️", "Tek Kullanımlık Gece", ChallengeCategory.Gece,
            "Bu gece çek, yarın sabah hepsini birlikte gör.",
            "Herkes gece boyunca Şipşak ile çeker, galeriden yükleme yok. Kimse fotoğrafları göremez; ertesi sabah 10:00'da hepsi aynı anda açılır ve gecenin özet videosu hazır olur.",
            "#D6197E", "#F2552C", PhotoUploadMode.QuickCaptureOnly, revealAfterDays: 1, revealHour: 10, featured: true,
            ["Gecenin ilk karesi", "Grubun en komik yüzü", "Kimsenin fark etmediği bir an", "Dans pistinden bir kare", "Gecenin en güzel manzarası", "Sabaha karşı son kare"]),

        Make("dogum-gunu-surprizi", "🎂", "Doğum Günü Sürprizi", ChallengeCategory.Kutlama,
            "Doğum günü sahibinden gizli bir anı duvarı.",
            "Arkadaşlar doğum günü sahibiyle eski fotoğraflarını yükler. Banyo modu sayesinde kimse, doğum günü sahibi de dahil, göremez; pasta anında hepsi birden açılır. Açılış saatini partinin saatine göre ayarla.",
            "#FF8A3D", "#E0445A", PhotoUploadMode.Both, revealAfterDays: 0, revealHour: 21, featured: true,
            ["Onunla ilk fotoğrafınız", "En utanç verici ortak anınız", "Onu en iyi anlatan kare", "Bu yıl birlikte yaptığınız en güzel şey", "Pasta anı"]),

        Make("tatil-cemberi", "🏖️", "Tatil Çemberi", ChallengeCategory.Gezi,
            "Tatil boyunca herkes çeker, son akşam hepsi açılır.",
            "Tatildeki herkes hem anında çeker hem galerisinden ekler. Fotoğraflar tatil bitene kadar gizli kalır; son akşam yemeğinde birlikte açıp özet videoyu izlersiniz. Açılış gününü tatilinin süresine göre ayarla.",
            "#0891B2", "#22C55E", PhotoUploadMode.Both, revealAfterDays: 5, revealHour: 20, featured: true,
            ["Yola çıkış", "İlk deniz", "En güzel gün batımı", "Yerel bir lezzet", "Grubun kaybolduğu an", "Son akşam yemeği"]),

        Make("otuz-gun-otuz-kare", "📅", "30 Gün, 30 Kare", ChallengeCategory.Gunluk,
            "Bir ay boyunca her gün bir kare, ay sonunda hepsi birden.",
            "Herkes her gün tek bir anı Şipşak ile çeker. Bir ay boyunca kimse kimsenin karesini görmez; 30. gün hepsi açılır ve ayınızın özet videosu çıkar.",
            "#7C3AED", "#D6197E", PhotoUploadMode.QuickCaptureOnly, revealAfterDays: 30, revealHour: 20, featured: false,
            ["Her gün aynı saatte bir kare", "Haftada bir: grubun ortak karesi", "Ayın son günü: bugünkü halin"]),

        Make("pazar-kahvaltisi", "🍳", "Pazar Kahvaltısı Kulübü", ChallengeCategory.Gunluk,
            "Sofra kuruldu, kareler hazır.",
            "Her pazar aynı çemberde buluşun. Banyo yok, fotoğraflar anında görünür; haftanın sofrasını beğenilerle birlikte seçin.",
            "#F59E0B", "#EF4444", PhotoUploadMode.Both, revealAfterDays: null, revealHour: 10, featured: false,
            ["Sofranın tamamı", "Kahvaltının yıldızı", "Çay ya da kahve anı", "Masadaki herkes"]),

        Make("konser-gecesi", "🎤", "Konser Gecesi", ChallengeCategory.Gece,
            "Sahneyi değil, birbirinizi çekin.",
            "Konser boyunca sadece Şipşak. Fotoğraflar ertesi sabah 11:00'de açılır; sahneden çok sizin yüzlerinizin olduğu bir albüm çıkar.",
            "#2F54EB", "#FF4DAE", PhotoUploadMode.QuickCaptureOnly, revealAfterDays: 1, revealHour: 11, featured: false,
            ["Kapıdaki sıra", "İlk şarkıda yüzler", "Işıkların altında grup", "Bis anı", "Konser sonrası sokak"]),

        Make("mac-gunu", "⚽", "Maç Günü", ChallengeCategory.Spor,
            "Tribünde, evde ya da kafede: maçın hikâyesi sizin karelerinizde.",
            "Maç boyunca herkes Şipşak ile çeker. Sonuç ne olursa olsun, kareler maçtan sonra gece 23:30'da açılır.",
            "#16A34A", "#0EA5E9", PhotoUploadMode.QuickCaptureOnly, revealAfterDays: 0, revealHour: 23, featured: false,
            ["Formalar giyildi", "İlk düdük", "Gol anındaki yüzler", "Devre arası", "Maç sonu"]),

        Make("kamp-atesi", "🔥", "Kamp Ateşi", ChallengeCategory.Gezi,
            "Doğada bir hafta sonu, dönüşte açılan anılar.",
            "Kampta herkes çeker; çekim yerinde internet yoksa fotoğraflarını sonra galeriden ekleyebilirsin. Anılar iki gün sonra, eve dönünce birlikte açılır.",
            "#EA580C", "#65A30D", PhotoUploadMode.Both, revealAfterDays: 2, revealHour: 20, featured: false,
            ["Çadır kurma mücadelesi", "Ateş başı", "Yıldızlar", "Sabah kahvesi", "Doğadan bir detay"]),

        Make("kina-gecesi", "💃", "Kına Gecesi", ChallengeCategory.Dugun,
            "Gelinin en eğlenceli gecesi, misafirlerin gözünden.",
            "Masalara QR kodu koy, misafirler katılsın. Gece boyunca çekilenler ertesi sabah 10:00'da açılır ve gelin için bir özet video hazırlanır.",
            "#BE123C", "#F59E0B", PhotoUploadMode.Both, revealAfterDays: 1, revealHour: 10, featured: true,
            ["Kına tepsisi", "Gelinin ilk dansı", "Halay zinciri", "Anne-kız karesi", "Masanızdaki herkes"]),

        Make("masadan-anilar", "💍", "Masadan Anılar", ChallengeCategory.Dugun,
            "Her masa kendi hikâyesini çeker.",
            "Düğünde her masada bir QR kod. Misafirler görevleri tamamlar, fotoğraflar ertesi sabah 10:00'da gelin ve damatla birlikte herkese açılır.",
            "#D6197E", "#FFC53D", PhotoUploadMode.Both, revealAfterDays: 1, revealHour: 10, featured: false,
            ["Gelin ve damatla selfie", "Masanızın grup fotoğrafı", "Pistteki en iyi dans", "Gözden kaçan bir detay", "Gecenin en duygusal anı"]),

        Make("mezuniyet-gunu", "🎓", "Mezuniyet Günü", ChallengeCategory.Kutlama,
            "Kep atmadan önce, attıktan sonra.",
            "Sınıfın, ailelerin ve hocaların çektiği her şey tek çemberde toplanır; törenin akşamı 22:00'de hepsi açılır.",
            "#1E3A8A", "#7C3AED", PhotoUploadMode.Both, revealAfterDays: 0, revealHour: 22, featured: false,
            ["Cübbeyle ilk kare", "Kep atışı", "Hocanla bir kare", "Ailenle", "Sınıfın son fotoğrafı"]),

        Make("yilbasi-geri-sayimi", "🎆", "Yılbaşı Geri Sayımı", ChallengeCategory.Kutlama,
            "Eski yılın son, yeni yılın ilk kareleri.",
            "Yılbaşı gecesi sadece Şipşak. Yeni yılın ilk öğlesinde, 12:00'de hepsi birden açılır.",
            "#312E81", "#D6197E", PhotoUploadMode.QuickCaptureOnly, revealAfterDays: 1, revealHour: 12, featured: false,
            ["Hazırlık", "Hediye anı", "Geri sayım", "Gece yarısı sarılmaları", "Yeni yılın ilk karesi"]),
    ];

    /// <summary>Inserts any starter challenge whose slug isn't in the database yet.</summary>
    public static async Task SeedAsync(CemberDbContext db, CancellationToken ct = default)
    {
        var existing = await db.ChallengeTemplates.Select(t => t.Slug).ToListAsync(ct);
        var missing = Starters.Where(t => !existing.Contains(t.Slug)).ToList();
        if (missing.Count == 0) return;

        foreach (var template in missing)
        {
            db.ChallengeTemplates.Add(new ChallengeTemplate
            {
                Id = Guid.NewGuid(),
                Slug = template.Slug,
                Title = template.Title,
                Tagline = template.Tagline,
                Description = template.Description,
                Emoji = template.Emoji,
                Category = template.Category,
                GradientStartHex = template.GradientStartHex,
                GradientEndHex = template.GradientEndHex,
                UploadMode = template.UploadMode,
                RevealAfterDays = template.RevealAfterDays,
                RevealHour = template.RevealHour,
                Prompts = [.. template.Prompts],
                IsFeatured = template.IsFeatured,
                IsActive = true,
                SortOrder = template.SortOrder,
                CreatedAt = DateTimeOffset.UtcNow,
            });
        }
        await db.SaveChangesAsync(ct);
    }

    private static int _order;

    private static ChallengeTemplate Make(
        string slug, string emoji, string title, ChallengeCategory category, string tagline, string description,
        string gradientStart, string gradientEnd, PhotoUploadMode uploadMode, int? revealAfterDays, int revealHour,
        bool featured, List<string> prompts) => new()
    {
        Slug = slug,
        Emoji = emoji,
        Title = title,
        Category = category,
        Tagline = tagline,
        Description = description,
        GradientStartHex = gradientStart,
        GradientEndHex = gradientEnd,
        UploadMode = uploadMode,
        RevealAfterDays = revealAfterDays,
        RevealHour = revealHour,
        IsFeatured = featured,
        Prompts = prompts,
        SortOrder = _order++,
    };
}
