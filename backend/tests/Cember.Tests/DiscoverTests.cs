using Cember.Application.Common;
using Cember.Application.Dtos;
using Cember.Domain.Entities;
using Cember.Infrastructure.Challenges;
using Cember.Tests.Infrastructure;
using Microsoft.EntityFrameworkCore;

namespace Cember.Tests;

[Collection(DatabaseCollection.Name)]
public class DiscoverTests(PostgresFixture fixture)
{
    [Fact]
    public async Task The_starter_catalog_seeds_once_and_featured_challenges_come_first()
    {
        using var world = new TestWorld(fixture);
        await ChallengeCatalog.SeedAsync(world.Db);
        await ChallengeCatalog.SeedAsync(world.Db);

        foreach (var starter in ChallengeCatalog.Starters)
        {
            Assert.Equal(1, await world.Db.ChallengeTemplates.CountAsync(t => t.Slug == starter.Slug));
        }

        var listed = await new ChallengeService(world.Db).ListAsync();
        Assert.True(listed.Count >= ChallengeCatalog.Starters.Count);
        var firstNonFeatured = listed.ToList().FindIndex(c => !c.IsFeatured);
        Assert.True(firstNonFeatured < 0 || listed.Skip(firstNonFeatured).All(c => !c.IsFeatured));
        Assert.All(listed, c => Assert.NotEmpty(c.Prompts));
    }

    [Fact]
    public async Task Starting_a_challenge_links_the_circle_to_its_prompts_and_counts_it()
    {
        using var world = new TestWorld(fixture);
        await ChallengeCatalog.SeedAsync(world.Db);
        var service = new ChallengeService(world.Db);
        var challenge = (await service.ListAsync()).First(c => c.Slug == "tek-kullanimlik-gece");
        var host = await world.CreateHostAsync();

        var created = await world.Circles.CreateAsync(host.Id, new CreateCircleRequest(
            "Cuma gecesi", null, IsOpenJoin: false, UploadMode: challenge.UploadMode, ChallengeTemplateId: challenge.Id));

        var detail = await world.Circles.GetDetailAsync(created.Id, host);
        Assert.NotNull(detail.Challenge);
        Assert.Equal(challenge.Title, detail.Challenge!.Title);
        Assert.Equal(challenge.Prompts, detail.Challenge.Prompts);
        Assert.Equal(PhotoUploadMode.QuickCaptureOnly, detail.UploadMode);

        var after = (await service.ListAsync()).First(c => c.Id == challenge.Id);
        Assert.Equal(challenge.StartedCount + 1, after.StartedCount);
    }

    [Fact]
    public async Task A_retired_challenge_cannot_be_started()
    {
        using var world = new TestWorld(fixture);
        var retired = new ChallengeTemplate
        {
            Id = Guid.NewGuid(),
            Slug = $"eski-{Guid.NewGuid():N}",
            Title = "Eski",
            Tagline = "x",
            Description = "x",
            Emoji = "🕰️",
            GradientStartHex = "#000000",
            GradientEndHex = "#FFFFFF",
            IsActive = false,
            CreatedAt = DateTimeOffset.UtcNow,
        };
        world.Db.ChallengeTemplates.Add(retired);
        await world.Db.SaveChangesAsync();
        var host = await world.CreateHostAsync();

        await Assert.ThrowsAsync<ValidationAppException>(() =>
            world.Circles.CreateAsync(host.Id, new CreateCircleRequest("x", null, IsOpenJoin: false, ChallengeTemplateId: retired.Id)));
        Assert.DoesNotContain(await new ChallengeService(world.Db).ListAsync(), c => c.Id == retired.Id);
    }

    [Fact]
    public async Task Discover_lists_only_open_brand_circles_with_their_brand()
    {
        using var world = new TestWorld(fixture);
        var brand = new BrandProfile { Id = Guid.NewGuid(), Name = $"Nova {Guid.NewGuid():N}"[..12], PrimaryColorHex = "#E8462F", CreatedAt = DateTimeOffset.UtcNow };
        world.Db.BrandProfiles.Add(brand);
        await world.Db.SaveChangesAsync();

        var brandOwner = await world.CreateHostAsync("Marka Hesabı");
        var brandCircle = await world.Circles.CreateAsync(brandOwner.Id, new CreateCircleRequest("Kanatlandığın an", null, IsOpenJoin: true, Description: "Enerjini göster"));
        await world.Circles.AssignBrandAsync(brandCircle.Id, brand.Id);

        var friend = await world.CreateHostAsync("Arkadaş");
        var friendsOpenCircle = await world.Circles.CreateAsync(friend.Id, new CreateCircleRequest("Açık doğum günü", null, IsOpenJoin: true));

        var viewer = await world.CreateHostAsync("İzleyici");
        var page = await world.Circles.DiscoverAsync(viewer.Id, null, null, 100);

        var listed = Assert.Single(page.Items, c => c.Id == brandCircle.Id);
        Assert.Equal(brand.Name, listed.Brand?.Name);
        Assert.Equal("Enerjini göster", listed.Description);
        Assert.DoesNotContain(page.Items, c => c.Id == friendsOpenCircle.Id);
    }
}
