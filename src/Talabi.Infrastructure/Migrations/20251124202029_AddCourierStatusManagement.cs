using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Talabi.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddCourierStatusManagement : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<double>(
                name: "AverageRating",
                table: "Couriers",
                type: "float",
                nullable: false,
                defaultValue: 0.0);

            migrationBuilder.AddColumn<int>(
                name: "CurrentActiveOrders",
                table: "Couriers",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<decimal>(
                name: "CurrentDayEarnings",
                table: "Couriers",
                type: "decimal(18,2)",
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<bool>(
                name: "IsWithinWorkingHours",
                table: "Couriers",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTime>(
                name: "LastActiveAt",
                table: "Couriers",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "LastEarningsReset",
                table: "Couriers",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "MaxActiveOrders",
                table: "Couriers",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "Status",
                table: "Couriers",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "TotalDeliveries",
                table: "Couriers",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<decimal>(
                name: "TotalEarnings",
                table: "Couriers",
                type: "decimal(18,2)",
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<int>(
                name: "TotalRatings",
                table: "Couriers",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<TimeSpan>(
                name: "WorkingHoursEnd",
                table: "Couriers",
                type: "time",
                nullable: true);

            migrationBuilder.AddColumn<TimeSpan>(
                name: "WorkingHoursStart",
                table: "Couriers",
                type: "time",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "AverageRating",
                table: "Couriers");

            migrationBuilder.DropColumn(
                name: "CurrentActiveOrders",
                table: "Couriers");

            migrationBuilder.DropColumn(
                name: "CurrentDayEarnings",
                table: "Couriers");

            migrationBuilder.DropColumn(
                name: "IsWithinWorkingHours",
                table: "Couriers");

            migrationBuilder.DropColumn(
                name: "LastActiveAt",
                table: "Couriers");

            migrationBuilder.DropColumn(
                name: "LastEarningsReset",
                table: "Couriers");

            migrationBuilder.DropColumn(
                name: "MaxActiveOrders",
                table: "Couriers");

            migrationBuilder.DropColumn(
                name: "Status",
                table: "Couriers");

            migrationBuilder.DropColumn(
                name: "TotalDeliveries",
                table: "Couriers");

            migrationBuilder.DropColumn(
                name: "TotalEarnings",
                table: "Couriers");

            migrationBuilder.DropColumn(
                name: "TotalRatings",
                table: "Couriers");

            migrationBuilder.DropColumn(
                name: "WorkingHoursEnd",
                table: "Couriers");

            migrationBuilder.DropColumn(
                name: "WorkingHoursStart",
                table: "Couriers");
        }
    }
}
