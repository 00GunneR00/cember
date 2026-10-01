using Cember.Application.Dtos;
using Cember.Application.Interfaces;
using Cember.Domain.Entities;
using Microsoft.AspNetCore.Http.Features;
using Microsoft.AspNetCore.Mvc;

namespace Cember.Api.Controllers;

[Route("api/v1")]
public class PhotosController(IPhotoService photoService, IModerationService moderationService) : CemberControllerBase
{
    [HttpDelete("photos/{photoId:guid}")]
    public async Task<IActionResult> Delete(Guid photoId, CancellationToken ct)
    {
        await photoService.DeletePhotoAsync(photoId, Actor, ct);
        return NoContent();
    }

    [HttpPost("photos/{photoId:guid}/report")]
    public async Task<IActionResult> Report(Guid photoId, ReportPhotoRequest request, CancellationToken ct)
    {
        await moderationService.ReportPhotoAsync(photoId, Actor, request, ct);
        return NoContent();
    }

    /// <summary>Blocks whoever uploaded this photo — the app's "Bu kişiyi engelle" action on a photo.</summary>
    [HttpPost("photos/{photoId:guid}/block-uploader")]
    public async Task<ActionResult<BlockedUserDto>> BlockUploader(Guid photoId, CancellationToken ct)
    {
        return Ok(await moderationService.BlockUploaderAsync(photoId, Actor, ct));
    }

    [HttpPost("circles/{circleId:guid}/photos")]
    [RequestSizeLimit(200_000_000)]
    public async Task<ActionResult<UploadPhotoResultDto>> Upload(Guid circleId, [FromForm] List<IFormFile> files, [FromForm] string? source, [FromForm] bool commercialConsent, CancellationToken ct)
    {
        var uploaded = files.Select(f => new UploadedFile(f.FileName, f.ContentType, f.OpenReadStream(), f.Length)).ToList();
        var parsedSource = Enum.TryParse<PhotoSource>(source, ignoreCase: true, out var s) ? s : PhotoSource.Gallery;
        var result = await photoService.UploadAsync(circleId, Actor, uploaded, parsedSource, commercialConsent, ct);
        return Created(string.Empty, result);
    }

    [HttpGet("circles/{circleId:guid}/photos")]
    public async Task<ActionResult<PhotoPageDto>> GetPhotos(Guid circleId, [FromQuery] string? cursor, [FromQuery] int pageSize, [FromQuery] string? source, CancellationToken ct)
    {
        PhotoSource? parsedSource = Enum.TryParse<PhotoSource>(source, ignoreCase: true, out var s) ? s : null;
        var result = await photoService.GetPhotosAsync(circleId, Actor, cursor, pageSize <= 0 ? 40 : pageSize, parsedSource, ct);
        return Ok(result);
    }

    [HttpPost("photos/{photoId:guid}/reactions")]
    public async Task<ActionResult<ReactionResultDto>> ToggleReaction(Guid photoId, CancellationToken ct)
    {
        return Ok(await photoService.ToggleReactionAsync(photoId, Actor, ct));
    }

    [HttpPost("photos/{photoId:guid}/comments")]
    public async Task<ActionResult<CommentDto>> AddComment(Guid photoId, AddCommentRequest request, CancellationToken ct)
    {
        var result = await photoService.AddCommentAsync(photoId, Actor, request, ct);
        return Created(string.Empty, result);
    }

    [HttpGet("photos/{photoId:guid}/comments")]
    public async Task<ActionResult<CommentPageDto>> GetComments(Guid photoId, [FromQuery] string? cursor, [FromQuery] int pageSize, CancellationToken ct)
    {
        return Ok(await photoService.GetCommentsAsync(photoId, Actor, cursor, pageSize <= 0 ? 40 : pageSize, ct));
    }

    [HttpGet("circles/{circleId:guid}/export.zip")]
    public async Task ExportZip(Guid circleId, CancellationToken ct)
    {
        var syncIoFeature = HttpContext.Features.Get<IHttpBodyControlFeature>();
        if (syncIoFeature is not null)
        {
            syncIoFeature.AllowSynchronousIO = true;
        }

        Response.ContentType = "application/zip";
        Response.Headers.ContentDisposition = $"attachment; filename=\"cember-{circleId}.zip\"";
        await photoService.ExportZipAsync(circleId, Actor, Response.Body, ct);
    }
}
