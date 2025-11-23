using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.DTOs;
using Talabi.Infrastructure.Data;

namespace Talabi.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
public class SearchController : ControllerBase
{
    private readonly TalabiDbContext _context;

    public SearchController(TalabiDbContext context)
    {
        _context = context;
    }

    // Autocomplete for products and vendors
    [HttpGet("autocomplete")]
    public async Task<ActionResult<List<AutocompleteResultDto>>> Autocomplete([FromQuery] string query)
    {
        if (string.IsNullOrWhiteSpace(query))
        {
            return Ok(new List<AutocompleteResultDto>());
        }

        var productResults = await _context.Products
            .Where(p => p.Name.Contains(query))
            .Take(5)
            .Select(p => new AutocompleteResultDto
            {
                Id = p.Id,
                Name = p.Name,
                Type = "product"
            })
            .ToListAsync();

        var vendorResults = await _context.Vendors
            .Where(v => v.Name.Contains(query))
            .Take(5)
            .Select(v => new AutocompleteResultDto
            {
                Id = v.Id,
                Name = v.Name,
                Type = "vendor"
            })
            .ToListAsync();

        var combined = productResults.Concat(vendorResults).ToList();
        return Ok(combined);
    }
}
