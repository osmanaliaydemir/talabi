using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Talabi.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class UpdateCourierVehicleType : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Data Migration: Convert strings to int values (as strings) before type change
            migrationBuilder.Sql("UPDATE Couriers SET VehicleType = '1' WHERE VehicleType IN ('Motosiklet', 'Motorcycle')");
            migrationBuilder.Sql("UPDATE Couriers SET VehicleType = '2' WHERE VehicleType IN ('Araba', 'Car')");
            migrationBuilder.Sql("UPDATE Couriers SET VehicleType = '3' WHERE VehicleType IN ('Bisiklet', 'Bicycle')");
            // Set default for others
            migrationBuilder.Sql("UPDATE Couriers SET VehicleType = '1' WHERE VehicleType NOT IN ('1', '2', '3') OR VehicleType IS NULL");

            migrationBuilder.AlterColumn<int>(
                name: "VehicleType",
                table: "Couriers",
                type: "int",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)",
                oldNullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<string>(
                name: "VehicleType",
                table: "Couriers",
                type: "nvarchar(max)",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "int");
        }
    }
}
