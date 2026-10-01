using System.Diagnostics;
using System.Globalization;
using System.Text;
using Cember.Application.Common;
using Cember.Application.Interfaces;
using Cember.Domain.Entities;
using Cember.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using SixLabors.Fonts;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Drawing.Processing;
using SixLabors.ImageSharp.Formats.Jpeg;
using SixLabors.ImageSharp.PixelFormats;
using SixLabors.ImageSharp.Processing;

namespace Cember.Infrastructure.Media;

/// <summary>A failure whose message can be shown to the user as-is.</summary>
public class RecapRenderException(string message, Exception? inner = null) : Exception(message, inner);

/// <summary>
/// Renders a circle's recap: a vertical (1080×1920, 9:16) MP4 — a title card, the circle's most-liked
/// photos in the order they were taken (each on a blurred backdrop, slowly zooming, cross-fading into the
/// next), and a closing card. Frames are composed with ImageSharp; ffmpeg does motion, fades and encoding.
/// </summary>
public class RecapVideoRenderer(
    CemberDbContext db,
    IObjectStorageService storage,
    IConfiguration configuration,
    ILogger<RecapVideoRenderer> logger)
{
    private const int Width = 1080;
    private const int Height = 1920;
    private const int Fps = 30;
    private const double ClipSeconds = 2.5;
    private const double FadeSeconds = 0.5;

    private static readonly Color Background = Color.ParseHex("141014");
    private static readonly Color Accent = Color.ParseHex("FF4FA8"); // the app's sunset pink
    private static readonly Color Muted = Color.ParseHex("A1A1AA");

    private static readonly string[] MonthNames =
        ["Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran", "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"];

    /// <summary>Renders the recap for <paramref name="circle"/>, uploads it and returns its storage key.</summary>
    public async Task<string> RenderAsync(Circle circle, CancellationToken ct)
    {
        var photos = await SelectPhotosAsync(circle.Id, ct);
        if (photos.Count < RecapLimits.MinPhotoCount)
        {
            throw new RecapRenderException($"Özet video için en az {RecapLimits.MinPhotoCount} fotoğraf gerekli.");
        }

        var participantCount = await db.GuestSessions.CountAsync(g => g.CircleId == circle.Id, ct) + 1;
        var totalPhotoCount = await db.Photos.CountAsync(p => p.CircleId == circle.Id && p.IsPublished, ct);

        var workDir = Directory.CreateTempSubdirectory("cember-recap-");
        try
        {
            var fonts = LoadFonts();
            var frames = new List<string>();

            frames.Add(await SaveFrameAsync(workDir, frames.Count, RenderTitleCard(circle, fonts), ct));
            foreach (var photo in photos)
            {
                await using var original = await storage.OpenReadAsync(photo.OriginalKey, ct);
                var frame = await RenderPhotoFrameAsync(original, photo.UploaderName, fonts, ct);
                frames.Add(await SaveFrameAsync(workDir, frames.Count, frame, ct));
            }
            frames.Add(await SaveFrameAsync(workDir, frames.Count, RenderClosingCard(totalPhotoCount, participantCount, fonts), ct));

            var outputPath = Path.Combine(workDir.FullName, "recap.mp4");
            await RunFfmpegAsync(frames, outputPath, ct);

            var key = $"circles/{circle.Id}/recap/{Guid.NewGuid()}.mp4";
            await using (var video = File.OpenRead(outputPath))
            {
                await storage.PutObjectAsync(key, video, "video/mp4", ct);
            }
            return key;
        }
        finally
        {
            try
            {
                workDir.Delete(recursive: true);
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "Özet video geçici klasörü silinemedi: {Dir}", workDir.FullName);
            }
        }
    }

    private record RecapPhoto(string OriginalKey, string UploaderName);

    /// The most-liked photos, then put back in the order they were taken so the video tells the evening's story.
    private async Task<List<RecapPhoto>> SelectPhotosAsync(Guid circleId, CancellationToken ct)
    {
        var rows = await db.Photos
            .Where(p => p.CircleId == circleId && p.IsPublished)
            .OrderByDescending(p => p.Reactions.Count)
            .ThenByDescending(p => p.CreatedAt)
            .Take(RecapLimits.MaxPhotoCount)
            .Select(p => new
            {
                p.OriginalKey,
                p.CreatedAt,
                UploaderName = p.UploadedByUser != null ? p.UploadedByUser.DisplayName : (p.UploadedByGuestSession != null ? p.UploadedByGuestSession.DisplayName : ""),
            })
            .ToListAsync(ct);

        return rows.OrderBy(r => r.CreatedAt).Select(r => new RecapPhoto(r.OriginalKey, r.UploaderName)).ToList();
    }

    private sealed record RecapFonts(FontFamily? Family)
    {
        public Font? Create(float size, FontStyle style = FontStyle.Regular) => Family?.CreateFont(size, style);
    }

    /// Text is decoration — if the machine has no usable font, the video is still rendered, just without captions.
    private RecapFonts LoadFonts()
    {
        foreach (var name in new[] { "Plus Jakarta Sans", "Inter", "Segoe UI", "Arial", "Helvetica", "DejaVu Sans", "Liberation Sans", "Noto Sans" })
        {
            if (SystemFonts.TryGet(name, out var family))
            {
                return new RecapFonts(family);
            }
        }
        var any = SystemFonts.Families.FirstOrDefault();
        if (any.Name is null)
        {
            logger.LogWarning("Sistemde yazı tipi bulunamadı; özet video yazısız hazırlanacak.");
            return new RecapFonts(null);
        }
        return new RecapFonts(any);
    }

    private static async Task<Image<Rgb24>> RenderPhotoFrameAsync(Stream original, string uploaderName, RecapFonts fonts, CancellationToken ct)
    {
        using var photo = await Image.LoadAsync<Rgb24>(original, ct);
        photo.Mutate(x => x.AutoOrient());

        // Backdrop: the same photo, cropped to fill the frame, heavily blurred and darkened. Blurring a
        // small copy and scaling it up looks the same as blurring full-size, at a fraction of the cost.
        var frame = photo.Clone(x => x
            .Resize(new ResizeOptions { Size = new Size(Width / 4, Height / 4), Mode = ResizeMode.Crop })
            .GaussianBlur(10)
            .Brightness(0.45f)
            .Resize(Width, Height));

        using var foreground = photo.Clone(x => x.Resize(new ResizeOptions
        {
            Size = new Size(Width - 96, Height - 420),
            Mode = ResizeMode.Max,
        }));
        var position = new Point((Width - foreground.Width) / 2, (Height - foreground.Height) / 2 - 40);
        frame.Mutate(x => x.DrawImage(foreground, position, 1f));

        if (!string.IsNullOrWhiteSpace(uploaderName) && fonts.Create(40, FontStyle.Bold) is { } font)
        {
            var captionY = Math.Min(position.Y + foreground.Height + 70, Height - 120);
            DrawCenteredText(frame, $"— {uploaderName}", font, Color.White, captionY);
        }
        return frame;
    }

    private static Image<Rgb24> RenderTitleCard(Circle circle, RecapFonts fonts)
    {
        var card = new Image<Rgb24>(Width, Height, Background.ToPixel<Rgb24>());
        if (fonts.Create(34, FontStyle.Bold) is { } brand)
        {
            DrawCenteredText(card, "Ç E M B E R", brand, Accent, 300);
        }
        if (fonts.Create(96, FontStyle.Bold) is { } title)
        {
            DrawCenteredText(card, circle.Name, title, Color.White, Height / 2 - 60, wrapWidth: Width - 160);
        }
        var date = circle.EventDate is { } d
            ? $"{d.Day} {MonthNames[d.Month - 1]} {d.Year}"
            : FormatDate(circle.CreatedAt);
        if (fonts.Create(44) is { } subtitle)
        {
            DrawCenteredText(card, date, subtitle, Muted, Height / 2 + 150);
        }
        return card;
    }

    private static Image<Rgb24> RenderClosingCard(int photoCount, int participantCount, RecapFonts fonts)
    {
        var card = new Image<Rgb24>(Width, Height, Background.ToPixel<Rgb24>());
        if (fonts.Create(56, FontStyle.Bold) is { } stats)
        {
            DrawCenteredText(card, $"{photoCount} kare · {participantCount} kişi", stats, Color.White, Height / 2 - 60);
        }
        if (fonts.Create(44, FontStyle.Bold) is { } madeWith)
        {
            DrawCenteredText(card, "Çember ile yapıldı", madeWith, Accent, Height / 2 + 60);
        }
        return card;
    }

    private static string FormatDate(DateTimeOffset value)
    {
        var local = value.ToOffset(TimeSpan.FromHours(3)); // Türkiye saati
        return $"{local.Day} {MonthNames[local.Month - 1]} {local.Year}";
    }

    private static void DrawCenteredText(Image<Rgb24> image, string text, Font font, Color color, float centerY, float wrapWidth = Width - 120)
    {
        var options = new RichTextOptions(font)
        {
            Origin = new PointF(Width / 2f, centerY),
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
            TextAlignment = TextAlignment.Center,
            WrappingLength = wrapWidth,
        };
        image.Mutate(x => x.DrawText(options, text, color));
    }

    private static async Task<string> SaveFrameAsync(DirectoryInfo dir, int index, Image<Rgb24> frame, CancellationToken ct)
    {
        var path = Path.Combine(dir.FullName, $"frame_{index:D3}.jpg");
        using (frame)
        {
            await frame.SaveAsJpegAsync(path, new JpegEncoder { Quality = 92 }, ct);
        }
        return path;
    }

    private async Task RunFfmpegAsync(IReadOnlyList<string> frames, string outputPath, CancellationToken ct)
    {
        var clipFrames = (int)(ClipSeconds * Fps);
        var totalSeconds = frames.Count * ClipSeconds - (frames.Count - 1) * FadeSeconds;

        var args = new List<string> { "-y", "-hide_banner", "-loglevel", "error" };
        foreach (var frame in frames)
        {
            args.AddRange(["-i", frame]);
        }
        // A silent audio track: some apps (Instagram, WhatsApp status) handle video-with-audio more reliably.
        args.AddRange(["-f", "lavfi", "-t", totalSeconds.ToString(CultureInfo.InvariantCulture), "-i", "anullsrc=r=44100:cl=stereo"]);

        var filter = new StringBuilder();
        for (var i = 0; i < frames.Count; i++)
        {
            // Upscaling before zoompan keeps the slow push-in smooth instead of jittering between whole pixels.
            filter.Append($"[{i}:v]scale={Width * 3 / 2}:{Height * 3 / 2},")
                .Append($"zoompan=z='min(zoom+0.0007,1.06)':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d={clipFrames}:s={Width}x{Height}:fps={Fps},")
                .Append($"setsar=1,format=yuv420p[v{i}];");
        }
        var previous = "v0";
        for (var i = 1; i < frames.Count; i++)
        {
            var offset = (i * (ClipSeconds - FadeSeconds)).ToString(CultureInfo.InvariantCulture);
            var label = i == frames.Count - 1 ? "out" : $"x{i}";
            filter.Append($"[{previous}][v{i}]xfade=transition=fade:duration={FadeSeconds.ToString(CultureInfo.InvariantCulture)}:offset={offset}[{label}];");
            previous = label;
        }

        args.AddRange(["-filter_complex", filter.ToString().TrimEnd(';')]);
        args.AddRange(["-map", "[out]", "-map", $"{frames.Count}:a"]);
        args.AddRange(["-c:v", "libx264", "-preset", "veryfast", "-crf", "23", "-pix_fmt", "yuv420p", "-r", Fps.ToString(CultureInfo.InvariantCulture)]);
        args.AddRange(["-c:a", "aac", "-b:a", "64k", "-shortest", "-movflags", "+faststart", outputPath]);

        var ffmpegPath = configuration["Recap:FfmpegPath"] is { Length: > 0 } configured ? configured : "ffmpeg";
        var startInfo = new ProcessStartInfo(ffmpegPath)
        {
            RedirectStandardError = true,
            RedirectStandardOutput = true,
            UseShellExecute = false,
            CreateNoWindow = true,
        };
        foreach (var arg in args)
        {
            startInfo.ArgumentList.Add(arg);
        }

        Process process;
        try
        {
            process = Process.Start(startInfo) ?? throw new InvalidOperationException("ffmpeg başlatılamadı.");
        }
        catch (Exception ex) when (ex is System.ComponentModel.Win32Exception or InvalidOperationException)
        {
            throw new RecapRenderException("Video oluşturucu (ffmpeg) sunucuda kurulu değil.", ex);
        }

        using (process)
        {
            // Read both streams concurrently so a chatty ffmpeg can't fill a pipe buffer and deadlock.
            var stderrTask = process.StandardError.ReadToEndAsync(ct);
            var stdoutTask = process.StandardOutput.ReadToEndAsync(ct);

            using var timeout = CancellationTokenSource.CreateLinkedTokenSource(ct);
            timeout.CancelAfter(TimeSpan.FromMinutes(5));
            try
            {
                await process.WaitForExitAsync(timeout.Token);
            }
            catch (OperationCanceledException)
            {
                process.Kill(entireProcessTree: true);
                if (ct.IsCancellationRequested) throw;
                throw new RecapRenderException("Özet video zamanında hazırlanamadı.");
            }

            var stderr = await stderrTask;
            await stdoutTask;
            if (process.ExitCode != 0)
            {
                logger.LogError("ffmpeg {ExitCode} koduyla çıktı: {Stderr}", process.ExitCode, stderr);
                throw new RecapRenderException("Özet video hazırlanırken bir hata oluştu.");
            }
        }
    }
}
