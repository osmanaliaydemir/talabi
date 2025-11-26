using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Talabi.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddVendorProfileFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<decimal>(
                name: "DeliveryFee",
                table: "Vendors",
                type: "decimal(18,2)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Description",
                table: "Vendors",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "EstimatedDeliveryTime",
                table: "Vendors",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsActive",
                table: "Vendors",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<decimal>(
                name: "MinimumOrderAmount",
                table: "Vendors",
                type: "decimal(18,2)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "OpeningHours",
                table: "Vendors",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PhoneNumber",
                table: "Vendors",
                type: "nvarchar(max)",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "DeliveryFee",
                table: "Vendors");

            migrationBuilder.DropColumn(
                name: "Description",
                table: "Vendors");

            migrationBuilder.DropColumn(
                name: "EstimatedDeliveryTime",
                table: "Vendors");

            migrationBuilder.DropColumn(
                name: "IsActive",
                table: "Vendors");

            migrationBuilder.DropColumn(
                name: "MinimumOrderAmount",
                table: "Vendors");

            migrationBuilder.DropColumn(
                name: "OpeningHours",
                table: "Vendors");

            migrationBuilder.DropColumn(
                name: "PhoneNumber",
                table: "Vendors");
        }
    }
}
