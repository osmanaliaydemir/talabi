using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Talabi.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class FixCouponVendorIdType : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "VendorId",
                table: "Coupons");

            migrationBuilder.AddColumn<Guid>(
                name: "VendorId",
                table: "Coupons",
                type: "uniqueidentifier",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "VendorId",
                table: "Coupons");

            migrationBuilder.AddColumn<int>(
                name: "VendorId",
                table: "Coupons",
                type: "int",
                nullable: true);
        }
    }
}
