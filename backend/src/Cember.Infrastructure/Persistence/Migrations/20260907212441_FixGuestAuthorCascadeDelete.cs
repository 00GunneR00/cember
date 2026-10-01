using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Cember.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class FixGuestAuthorCascadeDelete : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Comments_GuestSessions_GuestSessionId",
                table: "Comments");

            migrationBuilder.DropForeignKey(
                name: "FK_Comments_Users_UserId",
                table: "Comments");

            migrationBuilder.DropForeignKey(
                name: "FK_Photos_GuestSessions_UploadedByGuestSessionId",
                table: "Photos");

            migrationBuilder.DropForeignKey(
                name: "FK_Photos_Users_UploadedByUserId",
                table: "Photos");

            migrationBuilder.AddForeignKey(
                name: "FK_Comments_GuestSessions_GuestSessionId",
                table: "Comments",
                column: "GuestSessionId",
                principalTable: "GuestSessions",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Comments_Users_UserId",
                table: "Comments",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Photos_GuestSessions_UploadedByGuestSessionId",
                table: "Photos",
                column: "UploadedByGuestSessionId",
                principalTable: "GuestSessions",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Photos_Users_UploadedByUserId",
                table: "Photos",
                column: "UploadedByUserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Comments_GuestSessions_GuestSessionId",
                table: "Comments");

            migrationBuilder.DropForeignKey(
                name: "FK_Comments_Users_UserId",
                table: "Comments");

            migrationBuilder.DropForeignKey(
                name: "FK_Photos_GuestSessions_UploadedByGuestSessionId",
                table: "Photos");

            migrationBuilder.DropForeignKey(
                name: "FK_Photos_Users_UploadedByUserId",
                table: "Photos");

            migrationBuilder.AddForeignKey(
                name: "FK_Comments_GuestSessions_GuestSessionId",
                table: "Comments",
                column: "GuestSessionId",
                principalTable: "GuestSessions",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_Comments_Users_UserId",
                table: "Comments",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_Photos_GuestSessions_UploadedByGuestSessionId",
                table: "Photos",
                column: "UploadedByGuestSessionId",
                principalTable: "GuestSessions",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_Photos_Users_UploadedByUserId",
                table: "Photos",
                column: "UploadedByUserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }
    }
}
