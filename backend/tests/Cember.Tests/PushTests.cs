using Cember.Application.Common;
using Cember.Application.Interfaces;
using Cember.Domain.Entities;
using Cember.Infrastructure.Push;
using Cember.Tests.Infrastructure;
using Microsoft.EntityFrameworkCore;

namespace Cember.Tests;

[Collection(DatabaseCollection.Name)]
public class PushTests(PostgresFixture fixture)
{
    private static readonly PushContent Hello = new("Başlık", "Mesaj", new Dictionary<string, string>());

    [Fact]
    public async Task A_guest_upload_pushes_the_circle_owner()
    {
        using var world = new TestWorld(fixture);
        var host = await world.CreateHostAsync();
        var circleId = await world.CreateCircleAsync(host, name: "Düğün");
        var guest = await world.JoinAsGuestAsync(circleId, "Ayşe");

        await world.UploadAsync(guest, circleId);

        var (userId, content) = Assert.Single(world.Push.ToUsers);
        Assert.Equal(host.Id, userId);
        Assert.Equal("Düğün", content.Title);
        Assert.Contains("Ayşe", content.Body);
        Assert.Equal(circleId.ToString(), content.Data["circleId"]);
    }

    [Fact]
    public async Task Registering_the_same_phone_twice_keeps_one_row_per_identity()
    {
        using var world = new TestWorld(fixture);
        var push = new PushService(world.Db, new PushQueue());
        var host = await world.CreateHostAsync();
        var circleId = await world.CreateCircleAsync(host);
        var guest = await world.JoinAsGuestAsync(circleId, "Ayşe");
        var token = $"token-{Guid.NewGuid()}";

        await push.RegisterDeviceAsync(host, token, "android");
        await push.RegisterDeviceAsync(host, token, "android");
        await push.RegisterDeviceAsync(guest, token, "android");
        Assert.Equal(2, await world.Db.DeviceTokens.CountAsync(d => d.Token == token));

        await push.UnregisterDeviceAsync(host, token);
        Assert.Equal(1, await world.Db.DeviceTokens.CountAsync(d => d.Token == token));
    }

    [Fact]
    public async Task Circle_pushes_reach_guests_once_per_phone_and_forget_dead_tokens()
    {
        using var world = new TestWorld(fixture);
        var push = new PushService(world.Db, new PushQueue());
        var host = await world.CreateHostAsync();
        var circleId = await world.CreateCircleAsync(host);
        var guest = await world.JoinAsGuestAsync(circleId, "Ayşe");
        var otherGuest = await world.JoinAsGuestAsync(circleId, "Mehmet");

        var hostPhone = $"host-{Guid.NewGuid()}";
        var sharedPhone = $"shared-{Guid.NewGuid()}"; // one phone that joined as both guests
        var deadPhone = $"dead-{Guid.NewGuid()}";
        await push.RegisterDeviceAsync(host, hostPhone, "android");
        await push.RegisterDeviceAsync(guest, sharedPhone, "android");
        await push.RegisterDeviceAsync(otherGuest, sharedPhone, "android");
        await push.RegisterDeviceAsync(otherGuest, deadPhone, "android");

        var transport = new RecordingPushTransport();
        transport.DeadTokens.Add(deadPhone);
        var dispatcher = new PushDispatcher(world.Db, transport);

        await dispatcher.DispatchAsync(new QueuedPush(new CirclePushTarget(circleId, IncludeOwner: false), Hello), CancellationToken.None);

        Assert.Equal([sharedPhone], transport.Sent.Select(s => s.Token));
        Assert.False(await world.Db.DeviceTokens.AnyAsync(d => d.Token == deadPhone));

        transport.Sent.Clear();
        await dispatcher.DispatchAsync(new QueuedPush(new CirclePushTarget(circleId, IncludeOwner: true), Hello), CancellationToken.None);
        Assert.Equal(new[] { hostPhone, sharedPhone }.Order(), transport.Sent.Select(s => s.Token).Order());
    }

    [Fact]
    public async Task Pushes_are_off_when_firebase_is_not_configured()
    {
        using var world = new TestWorld(fixture);
        var disabled = new DisabledTransport();
        var dispatcher = new PushDispatcher(world.Db, disabled);

        await dispatcher.DispatchAsync(new QueuedPush(new UserPushTarget(Guid.NewGuid()), Hello), CancellationToken.None);

        Assert.Equal(0, disabled.Calls);
    }

    private sealed class DisabledTransport : IPushTransport
    {
        public int Calls { get; private set; }
        public bool IsEnabled => false;

        public Task<PushSendResult> SendAsync(string deviceToken, PushContent content, CancellationToken ct)
        {
            Calls++;
            return Task.FromResult(PushSendResult.Failed);
        }
    }
}
