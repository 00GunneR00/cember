namespace Cember.Domain.Entities;

public class User
{
    public Guid Id { get; set; }
    public required string DisplayName { get; set; }
    public required string ApiKeyHash { get; set; }
    public bool OnlyUploadOnWifi { get; set; }
    public bool NotifyOnPhotoAdded { get; set; } = true;
    public bool NotifyOnComment { get; set; } = true;
    public bool NotifyOnReaction { get; set; } = true;
    public bool NotifyOnGuestJoined { get; set; } = true;
    public bool IsAdmin { get; set; }
    public DateTimeOffset CreatedAt { get; set; }

    public ICollection<Circle> OwnedCircles { get; set; } = new List<Circle>();
}
