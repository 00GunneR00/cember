using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Cember.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddBanyoModeAndRecap : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "RecapError",
                table: "Circles",
                type: "character varying(300)",
                maxLength: 300,
                nullable: true);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "RecapGeneratedAt",
                table: "Circles",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "RecapKey",
                table: "Circles",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "RecapStatus",
                table: "Circles",
                type: "character varying(20)",
                maxLength: 20,
                nullable: false,
                defaultValue: "None");

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "RevealAt",
                table: "Circles",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "RevealNotifiedAt",
                table: "Circles",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Circles_RecapStatus",
                table: "Circles",
                column: "RecapStatus");

            migrationBuilder.CreateIndex(
                name: "IX_Circles_RevealAt",
                table: "Circles",
                column: "RevealAt",
                filter: "\"RevealNotifiedAt\" IS NULL");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Circles_RecapStatus",
                table: "Circles");

            migrationBuilder.DropIndex(
                name: "IX_Circles_RevealAt",
                table: "Circles");

            migrationBuilder.DropColumn(
                name: "RecapError",
                table: "Circles");

            migrationBuilder.DropColumn(
                name: "RecapGeneratedAt",
                table: "Circles");

            migrationBuilder.DropColumn(
                name: "RecapKey",
                table: "Circles");

            migrationBuilder.DropColumn(
                name: "RecapStatus",
                table: "Circles");

            migrationBuilder.DropColumn(
                name: "RevealAt",
                table: "Circles");

            migrationBuilder.DropColumn(
                name: "RevealNotifiedAt",
                table: "Circles");
        }
    }
}
