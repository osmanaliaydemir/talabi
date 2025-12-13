using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Talabi.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class RefactorUserAddressToRelational : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "City",
                table: "UserAddresses");

            migrationBuilder.DropColumn(
                name: "District",
                table: "UserAddresses");

            migrationBuilder.AddColumn<Guid>(
                name: "CityId",
                table: "UserAddresses",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "CountryId",
                table: "UserAddresses",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "DistrictId",
                table: "UserAddresses",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "LocalityId",
                table: "UserAddresses",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_UserAddresses_CityId",
                table: "UserAddresses",
                column: "CityId");

            migrationBuilder.CreateIndex(
                name: "IX_UserAddresses_CountryId",
                table: "UserAddresses",
                column: "CountryId");

            migrationBuilder.CreateIndex(
                name: "IX_UserAddresses_DistrictId",
                table: "UserAddresses",
                column: "DistrictId");

            migrationBuilder.CreateIndex(
                name: "IX_UserAddresses_LocalityId",
                table: "UserAddresses",
                column: "LocalityId");

            migrationBuilder.AddForeignKey(
                name: "FK_UserAddresses_Cities_CityId",
                table: "UserAddresses",
                column: "CityId",
                principalTable: "Cities",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_UserAddresses_Countries_CountryId",
                table: "UserAddresses",
                column: "CountryId",
                principalTable: "Countries",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_UserAddresses_Districts_DistrictId",
                table: "UserAddresses",
                column: "DistrictId",
                principalTable: "Districts",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_UserAddresses_Localities_LocalityId",
                table: "UserAddresses",
                column: "LocalityId",
                principalTable: "Localities",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_UserAddresses_Cities_CityId",
                table: "UserAddresses");

            migrationBuilder.DropForeignKey(
                name: "FK_UserAddresses_Countries_CountryId",
                table: "UserAddresses");

            migrationBuilder.DropForeignKey(
                name: "FK_UserAddresses_Districts_DistrictId",
                table: "UserAddresses");

            migrationBuilder.DropForeignKey(
                name: "FK_UserAddresses_Localities_LocalityId",
                table: "UserAddresses");

            migrationBuilder.DropIndex(
                name: "IX_UserAddresses_CityId",
                table: "UserAddresses");

            migrationBuilder.DropIndex(
                name: "IX_UserAddresses_CountryId",
                table: "UserAddresses");

            migrationBuilder.DropIndex(
                name: "IX_UserAddresses_DistrictId",
                table: "UserAddresses");

            migrationBuilder.DropIndex(
                name: "IX_UserAddresses_LocalityId",
                table: "UserAddresses");

            migrationBuilder.DropColumn(
                name: "CityId",
                table: "UserAddresses");

            migrationBuilder.DropColumn(
                name: "CountryId",
                table: "UserAddresses");

            migrationBuilder.DropColumn(
                name: "DistrictId",
                table: "UserAddresses");

            migrationBuilder.DropColumn(
                name: "LocalityId",
                table: "UserAddresses");

            migrationBuilder.AddColumn<string>(
                name: "City",
                table: "UserAddresses",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "District",
                table: "UserAddresses",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");
        }
    }
}
