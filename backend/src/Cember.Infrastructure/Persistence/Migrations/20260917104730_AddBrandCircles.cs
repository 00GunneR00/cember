using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Cember.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddBrandCircles : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "IsAdmin",
                table: "Users",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "CommercialUseConsent",
                table: "Photos",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<Guid>(
                name: "BrandProfileId",
                table: "Circles",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "BrandProfiles",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    LogoKey = table.Column<string>(type: "text", nullable: true),
                    PrimaryColorHex = table.Column<string>(type: "character varying(9)", maxLength: 9, nullable: false),
                    SecondaryColorHex = table.Column<string>(type: "character varying(9)", maxLength: 9, nullable: true),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_BrandProfiles", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Circles_BrandProfileId",
                table: "Circles",
                column: "BrandProfileId");

            migrationBuilder.AddForeignKey(
                name: "FK_Circles_BrandProfiles_BrandProfileId",
                table: "Circles",
                column: "BrandProfileId",
                principalTable: "BrandProfiles",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Circles_BrandProfiles_BrandProfileId",
                table: "Circles");

            migrationBuilder.DropTable(
                name: "BrandProfiles");

            migrationBuilder.DropIndex(
                name: "IX_Circles_BrandProfileId",
                table: "Circles");

            migrationBuilder.DropColumn(
                name: "IsAdmin",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "CommercialUseConsent",
                table: "Photos");

            migrationBuilder.DropColumn(
                name: "BrandProfileId",
                table: "Circles");
        }
    }
}
