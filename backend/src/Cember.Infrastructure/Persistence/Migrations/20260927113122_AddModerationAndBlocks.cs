using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Cember.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddModerationAndBlocks : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "ModerationHiddenAt",
                table: "Photos",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "PhotoReports",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    PhotoId = table.Column<Guid>(type: "uuid", nullable: false),
                    ReporterUserId = table.Column<Guid>(type: "uuid", nullable: true),
                    ReporterGuestSessionId = table.Column<Guid>(type: "uuid", nullable: true),
                    Reason = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    Note = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    ResolvedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PhotoReports", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PhotoReports_GuestSessions_ReporterGuestSessionId",
                        column: x => x.ReporterGuestSessionId,
                        principalTable: "GuestSessions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_PhotoReports_Photos_PhotoId",
                        column: x => x.PhotoId,
                        principalTable: "Photos",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_PhotoReports_Users_ReporterUserId",
                        column: x => x.ReporterUserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "UserBlocks",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    BlockerUserId = table.Column<Guid>(type: "uuid", nullable: true),
                    BlockerGuestSessionId = table.Column<Guid>(type: "uuid", nullable: true),
                    BlockedUserId = table.Column<Guid>(type: "uuid", nullable: true),
                    BlockedGuestSessionId = table.Column<Guid>(type: "uuid", nullable: true),
                    BlockedDisplayName = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserBlocks", x => x.Id);
                    table.ForeignKey(
                        name: "FK_UserBlocks_GuestSessions_BlockedGuestSessionId",
                        column: x => x.BlockedGuestSessionId,
                        principalTable: "GuestSessions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_UserBlocks_GuestSessions_BlockerGuestSessionId",
                        column: x => x.BlockerGuestSessionId,
                        principalTable: "GuestSessions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_UserBlocks_Users_BlockedUserId",
                        column: x => x.BlockedUserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_UserBlocks_Users_BlockerUserId",
                        column: x => x.BlockerUserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_PhotoReports_PhotoId_ReporterGuestSessionId",
                table: "PhotoReports",
                columns: new[] { "PhotoId", "ReporterGuestSessionId" },
                unique: true,
                filter: "\"ReporterGuestSessionId\" IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_PhotoReports_PhotoId_ReporterUserId",
                table: "PhotoReports",
                columns: new[] { "PhotoId", "ReporterUserId" },
                unique: true,
                filter: "\"ReporterUserId\" IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_PhotoReports_ReporterGuestSessionId",
                table: "PhotoReports",
                column: "ReporterGuestSessionId");

            migrationBuilder.CreateIndex(
                name: "IX_PhotoReports_ReporterUserId",
                table: "PhotoReports",
                column: "ReporterUserId");

            migrationBuilder.CreateIndex(
                name: "IX_PhotoReports_ResolvedAt",
                table: "PhotoReports",
                column: "ResolvedAt");

            migrationBuilder.CreateIndex(
                name: "IX_UserBlocks_BlockedGuestSessionId",
                table: "UserBlocks",
                column: "BlockedGuestSessionId");

            migrationBuilder.CreateIndex(
                name: "IX_UserBlocks_BlockedUserId",
                table: "UserBlocks",
                column: "BlockedUserId");

            migrationBuilder.CreateIndex(
                name: "IX_UserBlocks_BlockerGuestSessionId",
                table: "UserBlocks",
                column: "BlockerGuestSessionId");

            migrationBuilder.CreateIndex(
                name: "IX_UserBlocks_BlockerUserId",
                table: "UserBlocks",
                column: "BlockerUserId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "PhotoReports");

            migrationBuilder.DropTable(
                name: "UserBlocks");

            migrationBuilder.DropColumn(
                name: "ModerationHiddenAt",
                table: "Photos");
        }
    }
}
