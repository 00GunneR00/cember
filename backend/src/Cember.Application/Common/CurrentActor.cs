namespace Cember.Application.Common;

public enum ActorKind
{
    Host,
    Guest,
}

public record CurrentActor(ActorKind Kind, Guid Id, Guid? GuestCircleId, string DisplayName, bool IsAdmin = false)
{
    public bool IsHost => Kind == ActorKind.Host;
    public bool IsGuest => Kind == ActorKind.Guest;
}
