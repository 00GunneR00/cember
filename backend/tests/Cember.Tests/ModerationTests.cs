using Cember.Application.Common;
using Cember.Application.Dtos;
using Cember.Domain.Entities;
using Cember.Tests.Infrastructure;

namespace Cember.Tests;

[Collection(DatabaseCollection.Name)]
public class ModerationTests(PostgresFixture fixture)
{
    [Fact]
    public async Task Only_the_uploader_or_the_circle_owner_can_delete_a_photo()
    {
        using var world = new TestWorld(fixture);
        var host = await world.CreateHostAsync();
        var circleId = await world.CreateCircleAsync(host);
        var uploader = await world.JoinAsGuestAsync(circleId, "Ayşe");
        var other = await world.JoinAsGuestAsync(circleId, "Mehmet");
        var first = await world.UploadAsync(uploader, circleId);
        var second = await world.UploadAsync(uploader, circleId);

        await Assert.ThrowsAsync<ForbiddenAppException>(() => world.Photos.DeletePhotoAsync(first, other));

        await world.Photos.DeletePhotoAsync(first, uploader);
        await world.Photos.DeletePhotoAsync(second, host);
        Assert.Equal(0, await world.VisiblePhotoCountAsync(host, circleId));
        Assert.DoesNotContain(world.Storage.Objects.Keys, k => k.Contains(circleId.ToString()));
    }

    [Fact]
    public async Task Photo_list_tells_the_viewer_which_photos_they_may_delete()
    {
        using var world = new TestWorld(fixture);
        var host = await world.CreateHostAsync();
        var circleId = await world.CreateCircleAsync(host);
        var guest = await world.JoinAsGuestAsync(circleId, "Ayşe");
        await world.UploadAsync(host, circleId);
        await world.UploadAsync(guest, circleId);

        var asGuest = (await world.Photos.GetPhotosAsync(circleId, guest, null, 10)).Photos;
        Assert.Equal(1, asGuest.Count(p => p.ViewerCanDelete));
        var asHost = (await world.Photos.GetPhotosAsync(circleId, host, null, 10)).Photos;
        Assert.All(asHost, p => Assert.True(p.ViewerCanDelete));
    }

    [Fact]
    public async Task Reporting_hides_the_photo_for_the_reporter_and_three_reports_hide_it_for_everyone()
    {
        using var world = new TestWorld(fixture);
        var host = await world.CreateHostAsync();
        var circleId = await world.CreateCircleAsync(host);
        var guests = new List<CurrentActor>();
        foreach (var name in new[] { "A", "B", "C", "D" }) guests.Add(await world.JoinAsGuestAsync(circleId, name));
        var photoId = await world.UploadAsync(host, circleId);

        await world.Moderation.ReportPhotoAsync(photoId, guests[0], new ReportPhotoRequest(ReportReason.Inappropriate));
        Assert.Equal(0, await world.VisiblePhotoCountAsync(guests[0], circleId));
        Assert.Equal(1, await world.VisiblePhotoCountAsync(guests[1], circleId));

        // Reporting twice still counts once.
        await world.Moderation.ReportPhotoAsync(photoId, guests[0], new ReportPhotoRequest(ReportReason.Spam));
        await world.Moderation.ReportPhotoAsync(photoId, guests[1], new ReportPhotoRequest(ReportReason.Violence));
        Assert.Equal(1, await world.VisiblePhotoCountAsync(host, circleId));

        await world.Moderation.ReportPhotoAsync(photoId, guests[2], new ReportPhotoRequest(ReportReason.Other, "rahatsız edici"));
        Assert.Equal(0, await world.VisiblePhotoCountAsync(host, circleId));
        Assert.Equal(0, await world.VisiblePhotoCountAsync(guests[3], circleId));

        var reported = (await world.Moderation.ListOpenReportsAsync()).Single(r => r.PhotoId == photoId);
        Assert.Equal(3, reported.ReportCount);
        Assert.True(reported.IsHidden);
        Assert.Contains("rahatsız edici", reported.Notes);
    }

    [Fact]
    public async Task Admin_can_restore_a_hidden_photo_but_it_stays_hidden_for_those_who_reported_it()
    {
        using var world = new TestWorld(fixture);
        var host = await world.CreateHostAsync();
        var circleId = await world.CreateCircleAsync(host);
        var reporters = new List<CurrentActor>();
        foreach (var name in new[] { "A", "B", "C" }) reporters.Add(await world.JoinAsGuestAsync(circleId, name));
        var bystander = await world.JoinAsGuestAsync(circleId, "D");
        var photoId = await world.UploadAsync(host, circleId);
        foreach (var reporter in reporters) await world.Moderation.ReportPhotoAsync(photoId, reporter, new ReportPhotoRequest(ReportReason.Spam));

        await world.Moderation.ResolveReportsAsync(photoId, removePhoto: false);

        Assert.Equal(1, await world.VisiblePhotoCountAsync(bystander, circleId));
        Assert.Equal(0, await world.VisiblePhotoCountAsync(reporters[0], circleId));
        Assert.DoesNotContain(await world.Moderation.ListOpenReportsAsync(), r => r.PhotoId == photoId);
    }

    [Fact]
    public async Task You_cannot_report_your_own_photo()
    {
        using var world = new TestWorld(fixture);
        var host = await world.CreateHostAsync();
        var circleId = await world.CreateCircleAsync(host);
        var photoId = await world.UploadAsync(host, circleId);

        await Assert.ThrowsAsync<ValidationAppException>(() =>
            world.Moderation.ReportPhotoAsync(photoId, host, new ReportPhotoRequest(ReportReason.Spam)));
    }

    [Fact]
    public async Task Blocking_hides_the_uploaders_photos_and_comments_until_unblocked()
    {
        using var world = new TestWorld(fixture);
        var host = await world.CreateHostAsync();
        var circleId = await world.CreateCircleAsync(host, name: "Bodrum");
        var rude = await world.JoinAsGuestAsync(circleId, "Kaba");
        var viewer = await world.JoinAsGuestAsync(circleId, "İzleyici");
        var rudePhoto = await world.UploadAsync(rude, circleId);
        var hostPhoto = await world.UploadAsync(host, circleId);
        await world.Photos.AddCommentAsync(hostPhoto, rude, new AddCommentRequest("kötü yorum"));

        var block = await world.Moderation.BlockUploaderAsync(rudePhoto, viewer);

        Assert.Equal(1, await world.VisiblePhotoCountAsync(viewer, circleId));
        Assert.Empty((await world.Photos.GetCommentsAsync(hostPhoto, viewer, null, 10)).Comments);
        Assert.Equal(2, await world.VisiblePhotoCountAsync(host, circleId));

        var listed = Assert.Single(await world.Moderation.ListBlocksAsync(viewer));
        Assert.Equal("Kaba", listed.DisplayName);
        Assert.Equal("Bodrum", listed.CircleName);

        await world.Moderation.UnblockAsync(block.Id, viewer);
        Assert.Equal(2, await world.VisiblePhotoCountAsync(viewer, circleId));
    }

    [Fact]
    public async Task Deleting_a_photo_rerenders_the_recap_or_drops_it_when_too_few_remain()
    {
        using var world = new TestWorld(fixture);
        var host = await world.CreateHostAsync();
        var circleId = await world.CreateCircleAsync(host);
        var photos = new List<Guid>();
        for (var i = 0; i < 4; i++) photos.Add(await world.UploadAsync(host, circleId));
        await MarkRecapReadyAsync(world, circleId, "circles/recap-a.mp4");

        await world.Photos.DeletePhotoAsync(photos[0], host);
        var circle = await world.Db.Circles.FindAsync(circleId);
        await world.Db.Entry(circle!).ReloadAsync();
        Assert.Equal(RecapStatus.Pending, circle!.RecapStatus);

        await MarkRecapReadyAsync(world, circleId, "circles/recap-b.mp4");
        await world.Photos.DeletePhotoAsync(photos[1], host);
        await world.Db.Entry(circle).ReloadAsync();
        Assert.Equal(RecapStatus.None, circle.RecapStatus);
        Assert.Null(circle.RecapKey);
        Assert.False(world.Storage.Objects.ContainsKey("circles/recap-b.mp4"));
    }

    private static async Task MarkRecapReadyAsync(TestWorld world, Guid circleId, string key)
    {
        await world.Storage.PutObjectAsync(key, new MemoryStream([1, 2, 3]), "video/mp4");
        var circle = await world.Db.Circles.FindAsync(circleId);
        await world.Db.Entry(circle!).ReloadAsync();
        circle!.RecapStatus = RecapStatus.Ready;
        circle.RecapKey = key;
        await world.Db.SaveChangesAsync();
    }
}
