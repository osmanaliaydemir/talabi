using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Talabi.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddCourierSystemEntities : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_CourierEarning_Couriers_CourierId",
                table: "CourierEarning");

            migrationBuilder.DropForeignKey(
                name: "FK_CourierEarning_Orders_OrderId",
                table: "CourierEarning");

            migrationBuilder.DropForeignKey(
                name: "FK_DeliveryProof_Orders_OrderId",
                table: "DeliveryProof");

            migrationBuilder.DropPrimaryKey(
                name: "PK_DeliveryProof",
                table: "DeliveryProof");

            migrationBuilder.DropPrimaryKey(
                name: "PK_CourierEarning",
                table: "CourierEarning");

            migrationBuilder.RenameTable(
                name: "DeliveryProof",
                newName: "DeliveryProofs");

            migrationBuilder.RenameTable(
                name: "CourierEarning",
                newName: "CourierEarnings");

            migrationBuilder.RenameIndex(
                name: "IX_DeliveryProof_OrderId",
                table: "DeliveryProofs",
                newName: "IX_DeliveryProofs_OrderId");

            migrationBuilder.RenameIndex(
                name: "IX_CourierEarning_OrderId",
                table: "CourierEarnings",
                newName: "IX_CourierEarnings_OrderId");

            migrationBuilder.RenameIndex(
                name: "IX_CourierEarning_CourierId",
                table: "CourierEarnings",
                newName: "IX_CourierEarnings_CourierId");

            migrationBuilder.AddPrimaryKey(
                name: "PK_DeliveryProofs",
                table: "DeliveryProofs",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_CourierEarnings",
                table: "CourierEarnings",
                column: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_CourierEarnings_Couriers_CourierId",
                table: "CourierEarnings",
                column: "CourierId",
                principalTable: "Couriers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_CourierEarnings_Orders_OrderId",
                table: "CourierEarnings",
                column: "OrderId",
                principalTable: "Orders",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_DeliveryProofs_Orders_OrderId",
                table: "DeliveryProofs",
                column: "OrderId",
                principalTable: "Orders",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_CourierEarnings_Couriers_CourierId",
                table: "CourierEarnings");

            migrationBuilder.DropForeignKey(
                name: "FK_CourierEarnings_Orders_OrderId",
                table: "CourierEarnings");

            migrationBuilder.DropForeignKey(
                name: "FK_DeliveryProofs_Orders_OrderId",
                table: "DeliveryProofs");

            migrationBuilder.DropPrimaryKey(
                name: "PK_DeliveryProofs",
                table: "DeliveryProofs");

            migrationBuilder.DropPrimaryKey(
                name: "PK_CourierEarnings",
                table: "CourierEarnings");

            migrationBuilder.RenameTable(
                name: "DeliveryProofs",
                newName: "DeliveryProof");

            migrationBuilder.RenameTable(
                name: "CourierEarnings",
                newName: "CourierEarning");

            migrationBuilder.RenameIndex(
                name: "IX_DeliveryProofs_OrderId",
                table: "DeliveryProof",
                newName: "IX_DeliveryProof_OrderId");

            migrationBuilder.RenameIndex(
                name: "IX_CourierEarnings_OrderId",
                table: "CourierEarning",
                newName: "IX_CourierEarning_OrderId");

            migrationBuilder.RenameIndex(
                name: "IX_CourierEarnings_CourierId",
                table: "CourierEarning",
                newName: "IX_CourierEarning_CourierId");

            migrationBuilder.AddPrimaryKey(
                name: "PK_DeliveryProof",
                table: "DeliveryProof",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_CourierEarning",
                table: "CourierEarning",
                column: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_CourierEarning_Couriers_CourierId",
                table: "CourierEarning",
                column: "CourierId",
                principalTable: "Couriers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_CourierEarning_Orders_OrderId",
                table: "CourierEarning",
                column: "OrderId",
                principalTable: "Orders",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_DeliveryProof_Orders_OrderId",
                table: "DeliveryProof",
                column: "OrderId",
                principalTable: "Orders",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
