using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Cember.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddChallenges : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "ChallengeTemplateId",
                table: "Circles",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "ChallengeTemplates",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Slug = table.Column<string>(type: "character varying(80)", maxLength: 80, nullable: false),
                    Title = table.Column<string>(type: "character varying(80)", maxLength: 80, nullable: false),
                    Tagline = table.Column<string>(type: "character varying(160)", maxLength: 160, nullable: false),
                    Description = table.Column<string>(type: "character varying(600)", maxLength: 600, nullable: false),
                    Emoji = table.Column<string>(type: "character varying(16)", maxLength: 16, nullable: false),
                    Category = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    GradientStartHex = table.Column<string>(type: "character varying(9)", maxLength: 9, nullable: false),
                    GradientEndHex = table.Column<string>(type: "character varying(9)", maxLength: 9, nullable: false),
                    UploadMode = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    RevealAfterDays = table.Column<int>(type: "integer", nullable: true),
                    RevealHour = table.Column<int>(type: "integer", nullable: false),
                    Prompts = table.Column<List<string>>(type: "text[]", nullable: false),
                    CreatorName = table.Column<string>(type: "character varying(80)", maxLength: 80, nullable: true),
                    CreatorHandle = table.Column<string>(type: "character varying(60)", maxLength: 60, nullable: true),
                    CreatorVerified = table.Column<bool>(type: "boolean", nullable: false),
                    IsFeatured = table.Column<bool>(type: "boolean", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    SortOrder = table.Column<int>(type: "integer", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ChallengeTemplates", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Circles_ChallengeTemplateId",
                table: "Circles",
                column: "ChallengeTemplateId");

            migrationBuilder.CreateIndex(
                name: "IX_ChallengeTemplates_Slug",
                table: "ChallengeTemplates",
                column: "Slug",
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_Circles_ChallengeTemplates_ChallengeTemplateId",
                table: "Circles",
                column: "ChallengeTemplateId",
                principalTable: "ChallengeTemplates",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Circles_ChallengeTemplates_ChallengeTemplateId",
                table: "Circles");

            migrationBuilder.DropTable(
                name: "ChallengeTemplates");

            migrationBuilder.DropIndex(
                name: "IX_Circles_ChallengeTemplateId",
                table: "Circles");

            migrationBuilder.DropColumn(
                name: "ChallengeTemplateId",
                table: "Circles");
        }
    }
}
