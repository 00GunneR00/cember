using Cember.Application.Common;
using Cember.Application.Dtos;
using Cember.Tests.Infrastructure;

namespace Cember.Tests;

[Collection(DatabaseCollection.Name)]
public class BanyoModeTests(PostgresFixture fixture)
{
    [Fact]
    public async Task Photos_stay_hidden_from_everyone_until_the_reveal()
    {
        using var world = new TestWorld(fixture);
        var host = await world.CreateHostAsync();
        var circleId = await world.CreateCircleAsync(host, revealAt: DateTimeOffset.UtcNow.AddHours(12));
        var guest = await world.JoinAsGuestAsync(circleId, "Ayşe");
        await world.UploadAsync(host, circleId);
        await world.UploadAsync(guest, circleId);

        Assert.Equal(0, await world.VisiblePhotoCountAsync(host, circleId));
        Assert.Equal(0, await world.VisiblePhotoCountAsync(guest, circleId));

        var detail = await world.Circles.GetDetailAsync(circleId, guest);
        Assert.True(detail.IsDeveloping);
        Assert.Equal(2, detail.MemoryCount);
        Assert.Equal(1, detail.ViewerUploadCount);

        await world.RevealAsync(circleId);

        Assert.Equal(2, await world.VisiblePhotoCountAsync(host, circleId));
        Assert.Equal(2, await world.VisiblePhotoCountAsync(guest, circleId));
        Assert.False((await world.Circles.GetDetailAsync(circleId, host)).IsDeveloping);
    }

    [Fact]
    public async Task Reactions_comments_downloads_and_recaps_are_blocked_while_developing()
    {
        using var world = new TestWorld(fixture);
        var host = await world.CreateHostAsync();
        var circleId = await world.CreateCircleAsync(host, revealAt: DateTimeOffset.UtcNow.AddHours(1));
        var photoId = await world.UploadAsync(host, circleId);

        await Assert.ThrowsAsync<ForbiddenAppException>(() => world.Photos.ToggleReactionAsync(photoId, host));
        await Assert.ThrowsAsync<ForbiddenAppException>(() => world.Photos.AddCommentAsync(photoId, host, new AddCommentRequest("Harika!")));
        await Assert.ThrowsAsync<ForbiddenAppException>(() => world.Photos.GetCommentsAsync(photoId, host, null, 10));
        await Assert.ThrowsAsync<ForbiddenAppException>(() => world.Photos.ExportZipAsync(circleId, host, new MemoryStream()));
        await Assert.ThrowsAsync<ValidationAppException>(() => world.Circles.RequestRecapAsync(circleId, host.Id));
    }

    [Fact]
    public async Task Reveal_time_must_be_in_the_future_and_within_thirty_days()
    {
        using var world = new TestWorld(fixture);
        var host = await world.CreateHostAsync();

        await Assert.ThrowsAsync<ValidationAppException>(() => world.CreateCircleAsync(host, revealAt: DateTimeOffset.UtcNow.AddMinutes(-5)));
        await Assert.ThrowsAsync<ValidationAppException>(() => world.CreateCircleAsync(host, revealAt: DateTimeOffset.UtcNow.AddDays(31)));
    }

    [Fact]
    public async Task Host_can_reveal_early()
    {
        using var world = new TestWorld(fixture);
        var host = await world.CreateHostAsync();
        var circleId = await world.CreateCircleAsync(host, revealAt: DateTimeOffset.UtcNow.AddDays(1));
        await world.UploadAsync(host, circleId);

        await world.Circles.UpdateAsync(circleId, host.Id, new UpdateCircleRequest(null, null, null, null, null, null, null, RevealNow: true));

        Assert.Equal(1, await world.VisiblePhotoCountAsync(host, circleId));
    }

    [Fact]
    public async Task Photos_everyone_has_seen_cannot_be_put_back_in_the_darkroom()
    {
        using var world = new TestWorld(fixture);
        var host = await world.CreateHostAsync();
        var circleId = await world.CreateCircleAsync(host);
        await world.UploadAsync(host, circleId);

        var request = new UpdateCircleRequest(null, null, null, null, null, null, null, RevealAt: DateTimeOffset.UtcNow.AddHours(3));
        await Assert.ThrowsAsync<ValidationAppException>(() => world.Circles.UpdateAsync(circleId, host.Id, request));
    }

    [Fact]
    public async Task A_recap_needs_at_least_three_photos()
    {
        using var world = new TestWorld(fixture);
        var host = await world.CreateHostAsync();
        var circleId = await world.CreateCircleAsync(host);
        await world.UploadAsync(host, circleId);
        await world.UploadAsync(host, circleId);

        await Assert.ThrowsAsync<ValidationAppException>(() => world.Circles.RequestRecapAsync(circleId, host.Id));

        await world.UploadAsync(host, circleId);
        var detail = await world.Circles.RequestRecapAsync(circleId, host.Id);
        Assert.Equal(Domain.Entities.RecapStatus.Pending, detail.RecapStatus);
    }
}
