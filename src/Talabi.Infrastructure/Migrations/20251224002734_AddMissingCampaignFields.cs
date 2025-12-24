using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Talabi.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddMissingCampaignFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "CurrentUsageCount",
                table: "Campaigns",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<bool>(
                name: "IsStackable",
                table: "Campaigns",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<int>(
                name: "MaxUsageCount",
                table: "Campaigns",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "TargetAudience",
                table: "Campaigns",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<decimal>(
                name: "TotalDiscountBudget",
                table: "Campaigns",
                type: "decimal(18,2)",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "UsageLimitPerUser",
                table: "Campaigns",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ValidDaysOfWeek",
                table: "Campaigns",
                type: "nvarchar(max)",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "CurrentUsageCount",
                table: "Campaigns");

            migrationBuilder.DropColumn(
                name: "IsStackable",
                table: "Campaigns");

            migrationBuilder.DropColumn(
                name: "MaxUsageCount",
                table: "Campaigns");

            migrationBuilder.DropColumn(
                name: "TargetAudience",
                table: "Campaigns");

            migrationBuilder.DropColumn(
                name: "TotalDiscountBudget",
                table: "Campaigns");

            migrationBuilder.DropColumn(
                name: "UsageLimitPerUser",
                table: "Campaigns");

            migrationBuilder.DropColumn(
                name: "ValidDaysOfWeek",
                table: "Campaigns");
        }
    }
}
