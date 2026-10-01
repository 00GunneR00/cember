using Cember.Application.Dtos;
using Cember.Application.Interfaces;
using Cember.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Cember.Infrastructure.Challenges;

public class ChallengeService(CemberDbContext db) : IChallengeService
{
    public async Task<IReadOnlyList<ChallengeTemplateDto>> ListAsync(CancellationToken ct = default)
    {
        var rows = await db.ChallengeTemplates
            .Where(t => t.IsActive)
            .OrderByDescending(t => t.IsFeatured)
            .ThenBy(t => t.SortOrder)
            .Select(t => new
            {
                Template = t,
                StartedCount = db.Circles.Count(c => c.ChallengeTemplateId == t.Id),
            })
            .ToListAsync(ct);

        return rows.Select(r => new ChallengeTemplateDto(
            Id: r.Template.Id,
            Slug: r.Template.Slug,
            Title: r.Template.Title,
            Tagline: r.Template.Tagline,
            Description: r.Template.Description,
            Emoji: r.Template.Emoji,
            Category: r.Template.Category,
            GradientStartHex: r.Template.GradientStartHex,
            GradientEndHex: r.Template.GradientEndHex,
            UploadMode: r.Template.UploadMode,
            RevealAfterDays: r.Template.RevealAfterDays,
            RevealHour: r.Template.RevealHour,
            Prompts: r.Template.Prompts,
            CreatorName: r.Template.CreatorName,
            CreatorHandle: r.Template.CreatorHandle,
            CreatorVerified: r.Template.CreatorVerified,
            IsFeatured: r.Template.IsFeatured,
            StartedCount: r.StartedCount
        )).ToList();
    }
}
