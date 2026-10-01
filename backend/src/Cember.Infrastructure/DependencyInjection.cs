using Amazon.Runtime;
using Amazon.S3;
using Cember.Application.Interfaces;
using Cember.Infrastructure.Challenges;
using Cember.Infrastructure.Imaging;
using Cember.Infrastructure.Media;
using Cember.Infrastructure.Persistence;
using Cember.Infrastructure.Push;
using Cember.Infrastructure.Services;
using Cember.Infrastructure.Storage;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Cember.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddCemberInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddDbContext<CemberDbContext>(options =>
            options.UseNpgsql(configuration.GetConnectionString("Postgres")));

        services.Configure<S3Options>(configuration.GetSection(S3Options.SectionName));
        services.AddSingleton<IAmazonS3>(sp =>
        {
            var options = configuration.GetSection(S3Options.SectionName).Get<S3Options>()!;
            var config = new AmazonS3Config
            {
                ServiceURL = options.Endpoint,
                ForcePathStyle = options.ForcePathStyle,
                UseHttp = options.Endpoint.StartsWith("http://"),
            };
            return new AmazonS3Client(new BasicAWSCredentials(options.AccessKey, options.SecretKey), config);
        });

        services.AddScoped<IObjectStorageService, S3ObjectStorageService>();
        services.AddScoped<IImageProcessingService, ImageSharpProcessingService>();
        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<IActorLookupService, ActorLookupService>();
        services.AddScoped<IProfileService, ProfileService>();
        services.AddScoped<ICircleService, CircleService>();
        services.AddScoped<IInviteService, InviteService>();
        services.AddScoped<IPhotoService, PhotoService>();
        services.AddScoped<INotificationService, NotificationService>();
        services.AddScoped<IBrandService, BrandService>();
        services.AddScoped<RecapVideoRenderer>();
        services.AddScoped<PhotoRemover>();
        services.AddScoped<MetadataBackfill>();

        services.AddSingleton<PushQueue>();
        services.AddSingleton<FcmConfig>();
        services.AddHttpClient<IPushTransport, FcmSender>();
        services.AddScoped<PushDispatcher>();
        services.AddScoped<IPushService, PushService>();
        services.AddScoped<IModerationService, ModerationService>();
        services.AddScoped<IChallengeService, ChallengeService>();

        return services;
    }
}
