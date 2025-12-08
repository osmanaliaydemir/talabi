using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Talabi.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddOrderCouriersTable : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Create OrderCouriers table
            migrationBuilder.CreateTable(
                name: "OrderCouriers",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    OrderId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CourierId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CourierAssignedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    CourierAcceptedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    CourierRejectedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    RejectReason = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    PickedUpAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    OutForDeliveryAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    DeliveredAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    DeliveryFee = table.Column<decimal>(type: "decimal(18,2)", nullable: false, defaultValue: 0m),
                    CourierTip = table.Column<decimal>(type: "decimal(18,2)", nullable: true),
                    IsActive = table.Column<bool>(type: "bit", nullable: false, defaultValue: true),
                    Status = table.Column<int>(type: "int", nullable: false, defaultValue: 0),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_OrderCouriers", x => x.Id);
                    table.ForeignKey(
                        name: "FK_OrderCouriers_Orders_OrderId",
                        column: x => x.OrderId,
                        principalTable: "Orders",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.NoAction);
                    table.ForeignKey(
                        name: "FK_OrderCouriers_Couriers_CourierId",
                        column: x => x.CourierId,
                        principalTable: "Couriers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.NoAction);
                });

            // Create indexes
            migrationBuilder.CreateIndex(
                name: "IX_OrderCouriers_OrderId",
                table: "OrderCouriers",
                column: "OrderId");

            migrationBuilder.CreateIndex(
                name: "IX_OrderCouriers_CourierId",
                table: "OrderCouriers",
                column: "CourierId");

            migrationBuilder.CreateIndex(
                name: "IX_OrderCouriers_OrderId_IsActive",
                table: "OrderCouriers",
                columns: new[] { "OrderId", "IsActive" },
                filter: "[IsActive] = 1");

            // Migrate existing data from Orders to OrderCouriers
            migrationBuilder.Sql(@"
                INSERT INTO OrderCouriers (
                    Id, OrderId, CourierId,
                    CourierAssignedAt, CourierAcceptedAt, PickedUpAt, 
                    OutForDeliveryAt, DeliveredAt,
                    DeliveryFee, CourierTip,
                    IsActive, Status, CreatedAt, UpdatedAt
                )
                SELECT 
                    NEWID() AS Id,
                    Id AS OrderId,
                    CourierId,
                    CourierAssignedAt,
                    CourierAcceptedAt,
                    PickedUpAt,
                    OutForDeliveryAt,
                    DeliveredAt,
                    DeliveryFee,
                    CourierTip,
                    1 AS IsActive,
                    CASE 
                        WHEN DeliveredAt IS NOT NULL THEN 5
                        WHEN OutForDeliveryAt IS NOT NULL THEN 4
                        WHEN PickedUpAt IS NOT NULL THEN 3
                        WHEN CourierAcceptedAt IS NOT NULL THEN 1
                        WHEN CourierAssignedAt IS NOT NULL THEN 0
                        ELSE 0
                    END AS Status,
                    CreatedAt,
                    UpdatedAt
                FROM Orders
                WHERE CourierId IS NOT NULL;
            ");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "OrderCouriers");
        }
    }
}

