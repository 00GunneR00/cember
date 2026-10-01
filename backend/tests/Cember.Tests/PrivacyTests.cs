using Cember.Application.Common;
using Cember.Infrastructure.Imaging;
using Cember.Tests.Infrastructure;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using SixLabors.ImageSharp;

namespace Cember.Tests;

public class ImageProcessingTests
{
    [Fact]
    public async Task Uploads_lose_gps_and_all_other_embedded_metadata()
    {
        var withGps = TestWorld.JpegBytes(withGps: true);
        Assert.NotNull(Image.Identify(withGps).Metadata.ExifProfile);

        var processed = await new ImageSharpProcessingService().ProcessAsync(new MemoryStream(withGps));

        Assert.False(MetadataBackfill.HasMetadata(processed.Original));
        Assert.False(MetadataBackfill.HasMetadata(processed.Thumbnail));
    }
}

[Collection(DatabaseCollection.Name)]
public class PrivacyTests(PostgresFixture fixture)
{
    [Fact]
    public async Task Backfill_cleans_files_stored_with_metadata_and_is_safe_to_rerun()
    {
        using var world = new TestWorld(fixture);
        var host = await world.CreateHostAsync();
        var circleId = await world.CreateCircleAsync(host);
        var photoId = await world.UploadAsync(host, circleId);

        // Simulate a file stored before uploads were cleaned.
        var photo = await world.Db.Photos.SingleAsync(p => p.Id == photoId);
        await world.Storage.PutObjectAsync(photo.OriginalKey, new MemoryStream(TestWorld.JpegBytes(withGps: true)), "image/jpeg");

        // The database is shared across tests, so the run also meets other tests' photos whose files live in
        // their own in-memory storage — assert on this test's photo rather than on the totals.
        var backfill = new MetadataBackfill(world.Db, world.Storage, world.Imaging, NullLogger<MetadataBackfill>.Instance);
        var first = await backfill.RunAsync(CancellationToken.None);
        Assert.True(first.Cleaned >= 1);
        var cleaned = world.Storage.Objects[photo.OriginalKey].Bytes;
        Assert.False(MetadataBackfill.HasMetadata(cleaned));

        // A second run leaves an already-clean file byte-for-byte untouched.
        await backfill.RunAsync(CancellationToken.None);
        Assert.Equal(cleaned, world.Storage.Objects[photo.OriginalKey].Bytes);
    }

    [Fact]
    public async Task Deleting_an_account_removes_its_circles_its_photos_elsewhere_and_their_files()
    {
        using var world = new TestWorld(fixture);
        var leaving = await world.CreateHostAsync("Gidecek");
        var ownCircle = await world.CreateCircleAsync(leaving);
        await world.UploadAsync(leaving, ownCircle);

        var friend = await world.CreateHostAsync("Arkadaş");
        var friendsCircle = await world.CreateCircleAsync(friend);
        await world.UploadAsync(friend, friendsCircle);
        var leavingAsGuest = await world.JoinAsGuestAsync(friendsCircle, "Gidecek");
        await world.UploadAsync(leavingAsGuest, friendsCircle);

        await world.Profiles.DeleteGuestSessionAsync(leavingAsGuest.Id);
        await world.Profiles.DeleteAccountAsync(leaving.Id);

        Assert.False(await world.Db.Users.AnyAsync(u => u.Id == leaving.Id));
        Assert.False(await world.Db.Circles.AnyAsync(c => c.Id == ownCircle));
        Assert.DoesNotContain(world.Storage.Objects.Keys, k => k.Contains(ownCircle.ToString()));
        // The friend's circle keeps only the friend's own photo.
        Assert.Equal(1, await world.VisiblePhotoCountAsync(friend, friendsCircle));
    }

    [Fact]
    public async Task Comments_on_a_photo_are_only_readable_by_people_in_its_circle()
    {
        using var world = new TestWorld(fixture);
        var host = await world.CreateHostAsync();
        var circleId = await world.CreateCircleAsync(host);
        var photoId = await world.UploadAsync(host, circleId);
        var stranger = await world.CreateHostAsync("Yabancı");

        await Assert.ThrowsAsync<ForbiddenAppException>(() => world.Photos.GetCommentsAsync(photoId, stranger, null, 10));
    }
}
