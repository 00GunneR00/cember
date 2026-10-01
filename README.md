# Çember

Bir etkinliğin fotoğraflarını tek albümde toplayan uygulama. Düğün, doğum günü, gezi ya da buluşma için bir "çember" açarsın; davetliler QR kodla ya da bağlantıyla katılır ve herkes çektiği fotoğrafları aynı albüme yükler. Etkinlik bitince fotoğraflar kimsenin telefonunda dağınık kalmaz.

Depo üç parçadan oluşur: Flutter mobil uygulaması, ASP.NET Core API ve yönetim paneli.

## Özellikler

**Çemberler**
- Çember oluşturma: ad, etkinlik tarihi, kapak fotoğrafı, kurallar
- QR kod ve davet bağlantısıyla katılım; bağlantı uygulamayı doğrudan ilgili çemberde açar
- Misafirler hesap açmadan katılabilir
- Yükleme modu çember sahibince seçilir: yalnızca anlık çekim, yalnızca galeri ya da ikisi birden

**Banyo modu**
- Fotoğraflar belirlenen ana kadar çember sahibi dahil herkesten gizli kalır, sonra hepsi birlikte açılır (film banyosu gibi)
- Açılma anında çemberdekilere bildirim gider

**Özet videosu**
- Çemberin en çok beğenilen fotoğraflarından dikey (9:16) bir özet videosu üretilir
- Video sunucuda arka planda hazırlanır; hazır olunca bildirim gelir ve uygulamada oynatılır

**Etkileşim**
- Fotoğraflara tepki ve yorum
- Bildirimler: yeni fotoğraf, yorum, tepki, katılan misafir
- Fotoğraf indirme izni çember sahibinin kontrolünde

**Keşfet**
- Herkese açık çemberler
- Fotoğraf görevleri içeren hazır meydan okuma şablonları
- Marka sponsorlu çemberler

**Güvenlik ve gizlilik**
- Fotoğraf şikâyet etme, kullanıcı engelleme
- Çember silme talebi ve oylaması
- Hesap silme
- Google hesabı bağlayarak çemberleri başka cihazda geri getirme

**Yönetim paneli**
- Şikâyetlerin incelenmesi, çember ve marka profili yönetimi

## Teknolojiler

| Katman | Kullanılanlar |
|---|---|
| Mobil | Flutter, GetX, Dio, camera, mobile_scanner, qr_flutter, video_player, app_links, Firebase Messaging, Google Sign-In |
| API | ASP.NET Core 9, Entity Framework Core, arka plan işçileri (bildirim gönderimi, banyo açılışı, video üretimi) |
| Yönetim paneli | ASP.NET Core Razor Pages |
| Veritabanı | PostgreSQL 16 |
| Dosya depolama | S3 uyumlu nesne depolama (yerelde RustFS), imzalı bağlantılar |
| Görsel ve video | ImageSharp, ffmpeg |
| Test | xUnit, Testcontainers (PostgreSQL) |

## Klasör yapısı

```
lib/                       Flutter uygulaması
  screens/                 Ekranlar
  controllers/             Ekran durumları (GetX)
  data/                    Depo arayüzleri ve HTTP uygulamaları
  models/ widgets/ core/   Modeller, bileşenler, ağ ve yardımcılar
backend/
  src/Cember.Domain/         Varlıklar
  src/Cember.Application/    Arayüzler, DTO'lar, kurallar
  src/Cember.Infrastructure/ EF Core, depolama, bildirim, görsel işleme, video
  src/Cember.Api/            Uç noktalar ve arka plan işçileri
  src/Cember.Admin/          Yönetim paneli
  tests/Cember.Tests/        Testler
  docker-compose.yml         Yerel PostgreSQL ve nesne depolama
scripts/                   Gerçek telefonda çalıştırma betiği
config/                    Firebase ayar şablonu
```

## Kurulum

Gerekenler: Flutter SDK, .NET 9 SDK, Docker. Özet videosu için sunucuda `ffmpeg` kurulu olmalı.

### 1. Altyapı ve API

```sh
cd backend
docker compose up -d
dotnet run --project src/Cember.Api
```

API `http://localhost:5080` adresinde çalışır. Geliştirme ortamında veritabanı göçleri açılışta kendiliğinden uygulanır.

Yönetim paneli için:

```sh
dotnet run --project src/Cember.Admin
```

Panel `http://localhost:5090` adresinde açılır.

### 2. Mobil uygulama

Android emülatöründe:

```sh
flutter pub get
flutter run
```

USB ile bağlı gerçek telefonda, yerel API'ye bağlanmak için:

```powershell
.\scripts\run_on_device.ps1
```

### 3. Bildirimler (isteğe bağlı)

`config/firebase.example.json` dosyasını `config/firebase.json` olarak kopyalayıp Firebase projenin değerleriyle doldur. Bu dosya olmadan uygulama bildirimler kapalı çalışır.

### Testler

```sh
cd backend
dotnet test        # Docker çalışıyor olmalı
```

```sh
flutter test
```

## Lisans

Tüm hakları saklıdır. Bu depodaki kod izinsiz kopyalanamaz, dağıtılamaz ve kullanılamaz.
