namespace Cember.Infrastructure.Storage;

public class S3Options
{
    public const string SectionName = "S3";

    public required string Endpoint { get; set; }
    public required string AccessKey { get; set; }
    public required string SecretKey { get; set; }
    public required string Bucket { get; set; }
    public bool ForcePathStyle { get; set; } = true;
}
