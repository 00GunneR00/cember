using Cember.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Testcontainers.PostgreSql;

namespace Cember.Tests.Infrastructure;

/// <summary>
/// One throwaway PostgreSQL (in Docker) for the whole test run, created from the real migrations —
/// so a broken migration fails the tests too. Tests share it and isolate themselves by creating their own users and circles.
/// </summary>
public sealed class PostgresFixture : IAsyncLifetime
{
    private readonly PostgreSqlContainer _container = new PostgreSqlBuilder().WithImage("postgres:16-alpine").Build();

    public string ConnectionString => _container.GetConnectionString();

    public async Task InitializeAsync()
    {
        await _container.StartAsync();
        await using var db = CreateDbContext();
        await db.Database.MigrateAsync();
    }

    public Task DisposeAsync() => _container.DisposeAsync().AsTask();

    public CemberDbContext CreateDbContext() =>
        new(new DbContextOptionsBuilder<CemberDbContext>().UseNpgsql(ConnectionString).Options);
}

[CollectionDefinition(Name)]
public class DatabaseCollection : ICollectionFixture<PostgresFixture>
{
    public const string Name = "database";
}
