using System.Security.Cryptography;

namespace Cember.Infrastructure.Security;

public static class SecretTokens
{
    public static string GenerateOpaqueToken()
    {
        var bytes = RandomNumberGenerator.GetBytes(32);
        return Convert.ToBase64String(bytes).Replace("+", "-").Replace("/", "_").Replace("=", "");
    }

    public static string Hash(string secret)
    {
        var bytes = SHA256.HashData(System.Text.Encoding.UTF8.GetBytes(secret));
        return Convert.ToHexString(bytes);
    }
}
