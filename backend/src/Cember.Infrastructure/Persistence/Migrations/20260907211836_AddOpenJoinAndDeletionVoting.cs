using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Cember.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddOpenJoinAndDeletionVoting : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "DeletionRequestedAt",
                table: "Circles",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsOpenJoin",
                table: "Circles",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.CreateTable(
                name: "CircleDeletionVotes",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CircleId = table.Column<Guid>(type: "uuid", nullable: false),
                    VoterUserId = table.Column<Guid>(type: "uuid", nullable: true),
                    VoterGuestSessionId = table.Column<Guid>(type: "uuid", nullable: true),
                    Approved = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CircleDeletionVotes", x => x.Id);
                    table.CheckConstraint("CK_CircleDeletionVote_ExactlyOneVoter", "(\"VoterUserId\" IS NOT NULL) <> (\"VoterGuestSessionId\" IS NOT NULL)");
                    table.ForeignKey(
                        name: "FK_CircleDeletionVotes_Circles_CircleId",
                        column: x => x.CircleId,
                        principalTable: "Circles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_CircleDeletionVotes_GuestSessions_VoterGuestSessionId",
                        column: x => x.VoterGuestSessionId,
                        principalTable: "GuestSessions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_CircleDeletionVotes_Users_VoterUserId",
                        column: x => x.VoterUserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_CircleDeletionVotes_CircleId_VoterGuestSessionId",
                table: "CircleDeletionVotes",
                columns: new[] { "CircleId", "VoterGuestSessionId" },
                unique: true,
                filter: "\"VoterGuestSessionId\" IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_CircleDeletionVotes_CircleId_VoterUserId",
                table: "CircleDeletionVotes",
                columns: new[] { "CircleId", "VoterUserId" },
                unique: true,
                filter: "\"VoterUserId\" IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_CircleDeletionVotes_VoterGuestSessionId",
                table: "CircleDeletionVotes",
                column: "VoterGuestSessionId");

            migrationBuilder.CreateIndex(
                name: "IX_CircleDeletionVotes_VoterUserId",
                table: "CircleDeletionVotes",
                column: "VoterUserId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "CircleDeletionVotes");

            migrationBuilder.DropColumn(
                name: "DeletionRequestedAt",
                table: "Circles");

            migrationBuilder.DropColumn(
                name: "IsOpenJoin",
                table: "Circles");
        }
    }
}
