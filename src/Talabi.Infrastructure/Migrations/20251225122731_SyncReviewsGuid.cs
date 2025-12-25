using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Talabi.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class SyncReviewsGuid : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "CourierId",
                table: "Reviews",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "OrderId",
                table: "Reviews",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Reviews_CourierId",
                table: "Reviews",
                column: "CourierId");

            migrationBuilder.CreateIndex(
                name: "IX_Reviews_OrderId",
                table: "Reviews",
                column: "OrderId");

            migrationBuilder.AddForeignKey(
                name: "FK_Reviews_Couriers_CourierId",
                table: "Reviews",
                column: "CourierId",
                principalTable: "Couriers",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Reviews_Orders_OrderId",
                table: "Reviews",
                column: "OrderId",
                principalTable: "Orders",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Reviews_Couriers_CourierId",
                table: "Reviews");

            migrationBuilder.DropForeignKey(
                name: "FK_Reviews_Orders_OrderId",
                table: "Reviews");

            migrationBuilder.DropIndex(
                name: "IX_Reviews_CourierId",
                table: "Reviews");

            migrationBuilder.DropIndex(
                name: "IX_Reviews_OrderId",
                table: "Reviews");

            migrationBuilder.DropColumn(
                name: "CourierId",
                table: "Reviews");

            migrationBuilder.DropColumn(
                name: "OrderId",
                table: "Reviews");
        }
    }
}
