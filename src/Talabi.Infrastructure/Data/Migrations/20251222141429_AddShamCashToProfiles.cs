using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Talabi.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddShamCashToProfiles : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "ShamCashAccountNumber",
                table: "Vendors",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ShamCashAccountNumber",
                table: "Couriers",
                type: "nvarchar(max)",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ShamCashAccountNumber",
                table: "Vendors");

            migrationBuilder.DropColumn(
                name: "ShamCashAccountNumber",
                table: "Couriers");
        }
    }
}
