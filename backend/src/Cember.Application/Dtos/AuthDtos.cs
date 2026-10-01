namespace Cember.Application.Dtos;

public record RegisterHostRequest(string DisplayName);

public record RegisterHostResponse(Guid UserId, string ApiKey, bool IsAdmin = false);

public record GoogleSignInRequest(string IdToken);

public record LinkGoogleRequest(string IdToken);

