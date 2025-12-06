using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Talabi.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddVendorType : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Add VendorType column to Vendors table (nullable first, then update, then make not null)
            migrationBuilder.AddColumn<int>(
                name: "Type",
                table: "Vendors",
                type: "int",
                nullable: true);

            // Update existing vendors to Restaurant (1)
            migrationBuilder.Sql("UPDATE Vendors SET Type = 1 WHERE Type IS NULL");

            // Make column not null with default value
            migrationBuilder.AlterColumn<int>(
                name: "Type",
                table: "Vendors",
                type: "int",
                nullable: false,
                defaultValue: 1);

            // Add VendorType column to Categories table (nullable first, then update, then make not null)
            migrationBuilder.AddColumn<int>(
                name: "VendorType",
                table: "Categories",
                type: "int",
                nullable: true);

            // Update existing categories to Restaurant (1)
            migrationBuilder.Sql("UPDATE Categories SET VendorType = 1 WHERE VendorType IS NULL");

            // Make column not null with default value
            migrationBuilder.AlterColumn<int>(
                name: "VendorType",
                table: "Categories",
                type: "int",
                nullable: false,
                defaultValue: 1);

            // Create index for performance
            migrationBuilder.CreateIndex(
                name: "IX_Vendors_Type",
                table: "Vendors",
                column: "Type");

            migrationBuilder.CreateIndex(
                name: "IX_Categories_VendorType",
                table: "Categories",
                column: "VendorType");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Vendors_Type",
                table: "Vendors");

            migrationBuilder.DropIndex(
                name: "IX_Categories_VendorType",
                table: "Categories");

            migrationBuilder.DropColumn(
                name: "Type",
                table: "Vendors");

            migrationBuilder.DropColumn(
                name: "VendorType",
                table: "Categories");
        }
    }
}
