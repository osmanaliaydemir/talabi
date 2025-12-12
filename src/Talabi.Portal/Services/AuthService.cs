using Microsoft.AspNetCore.Identity;
using Talabi.Core.Entities;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.Interfaces;
using Talabi.Portal.Models;

namespace Talabi.Portal.Services;

public class AuthService : IAuthService
{
    private readonly SignInManager<AppUser> _signInManager;
    private readonly UserManager<AppUser> _userManager;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<AuthService> _logger;

    public AuthService(
        SignInManager<AppUser> signInManager,
        UserManager<AppUser> userManager,
        IUnitOfWork unitOfWork,
        ILogger<AuthService> logger)
    {
        _signInManager = signInManager;
        _userManager = userManager;
        _unitOfWork = unitOfWork;
        _logger = logger;
    }

    public async Task<LoginResponse?> LoginAsync(LoginRequest request, CancellationToken ct = default)
    {
        try
        {
            var user = await _userManager.FindByEmailAsync(request.Email);
            if (user == null)
            {
                _logger.LogWarning("Login failed: User not found {Email}", request.Email);
                return null;
            }

            var result = await _signInManager.PasswordSignInAsync(user, request.Password, request.RememberMe,
                lockoutOnFailure: true);

            if (result.Succeeded)
            {
                // Get Vendor ID
                // Note: Talabi.Core.Entities must have Vendor entity. 
                // Using IUnitOfWork to get Vendor repo.
                // Assuming Vendor has OwnerId or UserId.
                var vendor = await _unitOfWork.Vendors.Query()
                    .FirstOrDefaultAsync(v => v.OwnerId == user.Id, ct);

                return new LoginResponse
                {
                    UserId = user.Id,
                    Email = user.Email!,
                    FullName = $"{user.FullName}",
                    Role = "Vendor", // Logic to get role if needed
                    VendorId = vendor?.Id,
                    Token = "", // No JWT needed for direct access
                    ExpiresAt = DateTime.UtcNow.AddHours(12)
                };
            }

            if (result.IsLockedOut)
            {
                _logger.LogWarning("User account locked out.");
            }

            return null;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during login for user {Email}", request.Email);
            return null;
        }
    }

    public async Task LogoutAsync()
    {
        await _signInManager.SignOutAsync();
    }
}
