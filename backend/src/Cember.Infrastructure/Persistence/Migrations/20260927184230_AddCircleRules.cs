using System.Collections.Generic;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Cember.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddCircleRules : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<List<string>>(
                name: "Rules",
                table: "Circles",
                type: "text[]",
                nullable: false,
                defaultValueSql: "'{}'::text[]");

            // Circles already started from a challenge get its prompts as their rules.
            migrationBuilder.Sql("""
                UPDATE "Circles" AS c
                SET "Rules" = t."Prompts"
                FROM "ChallengeTemplates" AS t
                WHERE c."ChallengeTemplateId" = t."Id";
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Rules",
                table: "Circles");
        }
    }
}
