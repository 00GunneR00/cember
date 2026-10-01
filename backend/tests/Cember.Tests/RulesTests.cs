using Cember.Application.Common;
using Cember.Application.Dtos;
using Cember.Infrastructure.Challenges;
using Cember.Tests.Infrastructure;

namespace Cember.Tests;

[Collection(DatabaseCollection.Name)]
public class RulesTests(PostgresFixture fixture)
{
    [Fact]
    public async Task Rules_are_saved_cleaned_and_shown_to_guests()
    {
        using var world = new TestWorld(fixture);
        var host = await world.CreateHostAsync();
        var created = await world.Circles.CreateAsync(host.Id,
            new CreateCircleRequest("Kurallı", null, IsOpenJoin: false, Rules: ["  En az 3 kare  ", "", "Sadece gülen yüzler"]));
        var guest = await world.JoinAsGuestAsync(created.Id, "Ayşe");

        var detail = await world.Circles.GetDetailAsync(created.Id, guest);
        Assert.Equal(["En az 3 kare", "Sadece gülen yüzler"], detail.Rules);
    }

    [Fact]
    public async Task A_challenge_circle_starts_with_the_challenge_prompts_as_rules()
    {
        using var world = new TestWorld(fixture);
        await ChallengeCatalog.SeedAsync(world.Db);
        var challenge = (await new ChallengeService(world.Db).ListAsync()).First();
        var host = await world.CreateHostAsync();

        var created = await world.Circles.CreateAsync(host.Id,
            new CreateCircleRequest("Cuma", null, IsOpenJoin: false, ChallengeTemplateId: challenge.Id));

        Assert.Equal(challenge.Prompts, (await world.Circles.GetDetailAsync(created.Id, host)).Rules);
    }

    [Fact]
    public async Task The_host_can_replace_or_clear_rules_within_limits()
    {
        using var world = new TestWorld(fixture);
        var host = await world.CreateHostAsync();
        var created = await world.Circles.CreateAsync(host.Id, new CreateCircleRequest("x", null, IsOpenJoin: false, Rules: ["Eski"]));
        UpdateCircleRequest WithRules(List<string> rules) => new(null, null, null, null, null, null, null, Rules: rules);

        await world.Circles.UpdateAsync(created.Id, host.Id, WithRules(["Yeni"]));
        Assert.Equal(["Yeni"], (await world.Circles.GetDetailAsync(created.Id, host)).Rules);

        await world.Circles.UpdateAsync(created.Id, host.Id, WithRules([]));
        Assert.Empty((await world.Circles.GetDetailAsync(created.Id, host)).Rules!);

        await Assert.ThrowsAsync<ValidationAppException>(() =>
            world.Circles.UpdateAsync(created.Id, host.Id, WithRules([.. Enumerable.Range(1, 11).Select(i => $"Kural {i}")])));
        await Assert.ThrowsAsync<ValidationAppException>(() =>
            world.Circles.UpdateAsync(created.Id, host.Id, WithRules([new string('x', 141)])));
    }
}
