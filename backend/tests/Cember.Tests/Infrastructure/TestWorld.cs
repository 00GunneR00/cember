using Cember.Application.Common;
using Cember.Application.Dtos;
using Cember.Domain.Entities;
using Cember.Infrastructure.Imaging;
using Cember.Infrastructure.Persistence;
using Cember.Infrastructure.Services;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging.Abstractions;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Metadata.Profiles.Exif;
using SixLabors.ImageSharp.PixelFormats;

namespace Cember.Tests.Infrastructure;

/// <summary>The real services wired to the test database, in-memory storage and recorded pushes, plus scenario helpers.</summary>
public sealed class TestWorld : IDisposable
{
    public TestWorld(PostgresFixture fixture)
    {
        Db = fixture.CreateDbContext();
        Remover = new PhotoRemover(Db, Storage, NullLogger<PhotoRemover>.Instance);
        Notifications = new NotificationService(Db, Push, NullLogger<NotificationService>.Instance);
        Circles = new CircleService(Db, Storage, Imaging, Notifications, NullLogger<CircleService>.Instance);
        Photos = new PhotoService(Db, Storage, Imaging, Notifications, Remover, new ConfigurationBuilder().Build());
        Moderation = new ModerationService(Db, Storage, Remover);
        Profiles = new ProfileService(Db, Storage, Remover);
    }

    public CemberDbContext Db { get; }
    public InMemoryStorage Storage { get; } = new();
    public RecordingPushService Push { get; } = new();
    public ImageSharpProcessingService Imaging { get; } = new();
    public PhotoRemover Remover { get; }
    public NotificationService Notifications { get; }
    public CircleService Circles { get; }
    public PhotoService Photos { get; }
    public ModerationService Moderation { get; }
    public ProfileService Profiles { get; }

    public async Task<CurrentActor> CreateHostAsync(string name = "Ev Sahibi")
    {
        var user = new User
        {
            Id = Guid.NewGuid(),
            DisplayName = name,
            ApiKeyHash = Guid.NewGuid().ToString("N"),
            CreatedAt = DateTimeOffset.UtcNow,
        };
        Db.Users.Add(user);
        await Db.SaveChangesAsync();
        return new CurrentActor(ActorKind.Host, user.Id, null, name);
    }

    public async Task<Guid> CreateCircleAsync(CurrentActor owner, DateTimeOffset? revealAt = null, string name = "Test Çemberi")
    {
        var circle = await Circles.CreateAsync(owner.Id, new CreateCircleRequest(name, null, IsOpenJoin: false, RevealAt: revealAt));
        return circle.Id;
    }

    /// <summary>Joins as a guest the way an invite does: an invite token plus a guest session.</summary>
    public async Task<CurrentActor> JoinAsGuestAsync(Guid circleId, string name)
    {
        var invite = new InviteToken { Id = Guid.NewGuid(), CircleId = circleId, Token = Guid.NewGuid().ToString("N"), CreatedAt = DateTimeOffset.UtcNow };
        var session = new GuestSession
        {
            Id = Guid.NewGuid(),
            CircleId = circleId,
            InviteTokenId = invite.Id,
            DisplayName = name,
            SessionTokenHash = Guid.NewGuid().ToString("N"),
            CreatedAt = DateTimeOffset.UtcNow,
            LastSeenAt = DateTimeOffset.UtcNow,
        };
        Db.InviteTokens.Add(invite);
        Db.GuestSessions.Add(session);
        await Db.SaveChangesAsync();
        return new CurrentActor(ActorKind.Guest, session.Id, circleId, name);
    }

    public async Task<Guid> UploadAsync(CurrentActor actor, Guid circleId, bool withGps = false)
    {
        var bytes = JpegBytes(withGps);
        var result = await Photos.UploadAsync(
            circleId, actor,
            [new UploadedFile("foto.jpg", "image/jpeg", new MemoryStream(bytes), bytes.Length)],
            PhotoSource.Gallery);
        Assert.Empty(result.Errors);
        return result.Created.Single().Id;
    }

    public async Task<int> VisiblePhotoCountAsync(CurrentActor viewer, Guid circleId) =>
        (await Photos.GetPhotosAsync(circleId, viewer, cursor: null, pageSize: 100)).Photos.Count;

    /// <summary>Moves a Banyo circle's reveal into the past, as if the time had come.</summary>
    public async Task RevealAsync(Guid circleId)
    {
        var circle = await Db.Circles.FindAsync(circleId);
        circle!.RevealAt = DateTimeOffset.UtcNow.AddSeconds(-1);
        await Db.SaveChangesAsync();
    }

    /// <summary>A small JPEG — optionally carrying GPS coordinates like a phone photo.</summary>
    public static byte[] JpegBytes(bool withGps)
    {
        using var image = new Image<Rgb24>(64, 48, Color.CornflowerBlue.ToPixel<Rgb24>());
        if (withGps)
        {
            var exif = new ExifProfile();
            exif.SetValue(ExifTag.GPSLatitudeRef, "N");
            exif.SetValue(ExifTag.GPSLatitude, [new Rational(41, 1), new Rational(1, 1), new Rational(3, 1)]);
            exif.SetValue(ExifTag.Model, "Test Phone");
            image.Metadata.ExifProfile = exif;
        }
        using var stream = new MemoryStream();
        image.SaveAsJpeg(stream);
        return stream.ToArray();
    }

    public void Dispose() => Db.Dispose();
}
