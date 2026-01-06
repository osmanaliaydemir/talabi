using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Talabi.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddCartItemOptions : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "SelectedOptions",
                table: "CartItems",
                type: "nvarchar(max)",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "SelectedOptions",
                table: "CartItems");
        }
    }
}
