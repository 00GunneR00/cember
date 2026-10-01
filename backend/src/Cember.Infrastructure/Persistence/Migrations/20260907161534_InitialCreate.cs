using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Cember.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Users",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    DisplayName = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    ApiKeyHash = table.Column<string>(type: "text", nullable: false),
                    OnlyUploadOnWifi = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Users", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Circles",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    OwnerUserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    EventDate = table.Column<DateOnly>(type: "date", nullable: true),
                    CoverPhotoKey = table.Column<string>(type: "text", nullable: true),
                    IsArchived = table.Column<bool>(type: "boolean", nullable: false),
                    AutoPublish = table.Column<bool>(type: "boolean", nullable: false),
                    AllowGuestDownloads = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Circles", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Circles_Users_OwnerUserId",
                        column: x => x.OwnerUserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "InviteTokens",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CircleId = table.Column<Guid>(type: "uuid", nullable: false),
                    Token = table.Column<string>(type: "text", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    RevokedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    ExpiresAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_InviteTokens", x => x.Id);
                    table.ForeignKey(
                        name: "FK_InviteTokens_Circles_CircleId",
                        column: x => x.CircleId,
                        principalTable: "Circles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "GuestSessions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CircleId = table.Column<Guid>(type: "uuid", nullable: false),
                    InviteTokenId = table.Column<Guid>(type: "uuid", nullable: false),
                    DisplayName = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    SessionTokenHash = table.Column<string>(type: "text", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    LastSeenAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_GuestSessions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_GuestSessions_Circles_CircleId",
                        column: x => x.CircleId,
                        principalTable: "Circles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_GuestSessions_InviteTokens_InviteTokenId",
                        column: x => x.InviteTokenId,
                        principalTable: "InviteTokens",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "Photos",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CircleId = table.Column<Guid>(type: "uuid", nullable: false),
                    UploadedByUserId = table.Column<Guid>(type: "uuid", nullable: true),
                    UploadedByGuestSessionId = table.Column<Guid>(type: "uuid", nullable: true),
                    OriginalKey = table.Column<string>(type: "text", nullable: false),
                    ThumbnailKey = table.Column<string>(type: "text", nullable: false),
                    Width = table.Column<int>(type: "integer", nullable: false),
                    Height = table.Column<int>(type: "integer", nullable: false),
                    FileSizeBytes = table.Column<long>(type: "bigint", nullable: false),
                    ContentType = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    IsPublished = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Photos", x => x.Id);
                    table.CheckConstraint("CK_Photo_ExactlyOneUploader", "(\"UploadedByUserId\" IS NOT NULL) <> (\"UploadedByGuestSessionId\" IS NOT NULL)");
                    table.ForeignKey(
                        name: "FK_Photos_Circles_CircleId",
                        column: x => x.CircleId,
                        principalTable: "Circles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Photos_GuestSessions_UploadedByGuestSessionId",
                        column: x => x.UploadedByGuestSessionId,
                        principalTable: "GuestSessions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_Photos_Users_UploadedByUserId",
                        column: x => x.UploadedByUserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateTable(
                name: "Comments",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    PhotoId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: true),
                    GuestSessionId = table.Column<Guid>(type: "uuid", nullable: true),
                    AuthorDisplayName = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    Body = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Comments", x => x.Id);
                    table.CheckConstraint("CK_Comment_ExactlyOneAuthor", "(\"UserId\" IS NOT NULL) <> (\"GuestSessionId\" IS NOT NULL)");
                    table.ForeignKey(
                        name: "FK_Comments_GuestSessions_GuestSessionId",
                        column: x => x.GuestSessionId,
                        principalTable: "GuestSessions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_Comments_Photos_PhotoId",
                        column: x => x.PhotoId,
                        principalTable: "Photos",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Comments_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateTable(
                name: "PhotoReactions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    PhotoId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: true),
                    GuestSessionId = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PhotoReactions", x => x.Id);
                    table.CheckConstraint("CK_PhotoReaction_ExactlyOneAuthor", "(\"UserId\" IS NOT NULL) <> (\"GuestSessionId\" IS NOT NULL)");
                    table.ForeignKey(
                        name: "FK_PhotoReactions_GuestSessions_GuestSessionId",
                        column: x => x.GuestSessionId,
                        principalTable: "GuestSessions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_PhotoReactions_Photos_PhotoId",
                        column: x => x.PhotoId,
                        principalTable: "Photos",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_PhotoReactions_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Circles_OwnerUserId",
                table: "Circles",
                column: "OwnerUserId");

            migrationBuilder.CreateIndex(
                name: "IX_Comments_GuestSessionId",
                table: "Comments",
                column: "GuestSessionId");

            migrationBuilder.CreateIndex(
                name: "IX_Comments_PhotoId_CreatedAt",
                table: "Comments",
                columns: new[] { "PhotoId", "CreatedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_Comments_UserId",
                table: "Comments",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_GuestSessions_CircleId",
                table: "GuestSessions",
                column: "CircleId");

            migrationBuilder.CreateIndex(
                name: "IX_GuestSessions_InviteTokenId",
                table: "GuestSessions",
                column: "InviteTokenId");

            migrationBuilder.CreateIndex(
                name: "IX_GuestSessions_SessionTokenHash",
                table: "GuestSessions",
                column: "SessionTokenHash",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_InviteTokens_CircleId",
                table: "InviteTokens",
                column: "CircleId");

            migrationBuilder.CreateIndex(
                name: "IX_InviteTokens_Token",
                table: "InviteTokens",
                column: "Token",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_PhotoReactions_GuestSessionId",
                table: "PhotoReactions",
                column: "GuestSessionId");

            migrationBuilder.CreateIndex(
                name: "IX_PhotoReactions_PhotoId_GuestSessionId",
                table: "PhotoReactions",
                columns: new[] { "PhotoId", "GuestSessionId" },
                unique: true,
                filter: "\"GuestSessionId\" IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_PhotoReactions_PhotoId_UserId",
                table: "PhotoReactions",
                columns: new[] { "PhotoId", "UserId" },
                unique: true,
                filter: "\"UserId\" IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_PhotoReactions_UserId",
                table: "PhotoReactions",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_Photos_CircleId_CreatedAt",
                table: "Photos",
                columns: new[] { "CircleId", "CreatedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_Photos_UploadedByGuestSessionId",
                table: "Photos",
                column: "UploadedByGuestSessionId");

            migrationBuilder.CreateIndex(
                name: "IX_Photos_UploadedByUserId",
                table: "Photos",
                column: "UploadedByUserId");

            migrationBuilder.CreateIndex(
                name: "IX_Users_ApiKeyHash",
                table: "Users",
                column: "ApiKeyHash",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Comments");

            migrationBuilder.DropTable(
                name: "PhotoReactions");

            migrationBuilder.DropTable(
                name: "Photos");

            migrationBuilder.DropTable(
                name: "GuestSessions");

            migrationBuilder.DropTable(
                name: "InviteTokens");

            migrationBuilder.DropTable(
                name: "Circles");

            migrationBuilder.DropTable(
                name: "Users");
        }
    }
}
