using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Cember.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddPhotoUploadModeAndSource : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Source",
                table: "Photos",
                type: "character varying(20)",
                maxLength: 20,
                nullable: false,
                // Existing photos all predate Şipşak — they were all uploaded through the gallery flow.
                defaultValue: "Gallery");

            migrationBuilder.AddColumn<string>(
                name: "UploadMode",
                table: "Circles",
                type: "character varying(20)",
                maxLength: 20,
                nullable: false,
                // Existing circles predate this restriction — they accepted uploads from anywhere, i.e. Both.
                defaultValue: "Both");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Source",
                table: "Photos");

            migrationBuilder.DropColumn(
                name: "UploadMode",
                table: "Circles");
        }
    }
}
