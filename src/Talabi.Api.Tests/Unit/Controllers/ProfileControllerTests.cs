using AutoMapper;
using FluentAssertions;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Moq;
using Talabi.Api.Controllers;
using Talabi.Api.Tests.Helpers;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Core.Interfaces;
using Xunit;

namespace Talabi.Api.Tests.Unit.Controllers;

public class ProfileControllerTests
{
    private readonly Mock<IUnitOfWork> _mockUnitOfWork;
    private readonly Mock<ILocalizationService> _mockLocalizationService;
    private readonly Mock<IUserContextService> _mockUserContextService;
    private readonly Mock<UserManager<AppUser>> _mockUserManager;
    private readonly Mock<IMapper> _mockMapper;
    private readonly ILogger<ProfileController> _logger;
    private readonly ProfileController _controller;

    public ProfileControllerTests()
    {
        _mockUnitOfWork = ControllerTestHelpers.CreateMockUnitOfWork();
        _mockLocalizationService = ControllerTestHelpers.CreateMockLocalizationService();
        _mockUserContextService = ControllerTestHelpers.CreateMockUserContextService();
        _mockMapper = new Mock<IMapper>();
        _logger = ControllerTestHelpers.CreateMockLogger<ProfileController>();

        var store = new Mock<IUserStore<AppUser>>();
        _mockUserManager = new Mock<UserManager<AppUser>>(store.Object, null, null, null, null, null, null, null, null);

        _controller = new ProfileController(
            _mockUnitOfWork.Object,
            _logger,
            _mockLocalizationService.Object,
            _mockUserContextService.Object,
            _mockUserManager.Object,
            _mockMapper.Object
        )
        {
            ControllerContext = ControllerTestHelpers.CreateControllerContext()
        };
    }

    [Fact]
    public async Task GetProfile_WhenUserFound_ReturnsOk()
    {
        // Arrange
        var userId = "user-1";
        var user = new AppUser { Id = userId, FullName = "Test User" };
        var profileDto = new UserProfileDto { FullName = "Test User" };

        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);
        _mockUserManager.Setup(x => x.FindByIdAsync(userId)).ReturnsAsync(user);
        _mockMapper.Setup(x => x.Map<UserProfileDto>(user)).Returns(profileDto);

        // Act
        var result = await _controller.GetProfile();

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<UserProfileDto>>().Subject;
        apiResponse.Data.FullName.Should().Be("Test User");
    }

    [Fact]
    public async Task GetProfile_WhenUserNotFound_ReturnsNotFound()
    {
        // Arrange
        var userId = "user-1";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);
        _mockUserManager.Setup(x => x.FindByIdAsync(userId)).ReturnsAsync((AppUser?)null);

        // Act
        var result = await _controller.GetProfile();

        // Assert
        var notFoundResult = result.Result.Should().BeOfType<NotFoundObjectResult>().Subject;
        var apiResponse = notFoundResult.Value.Should().BeOfType<ApiResponse<UserProfileDto>>().Subject;
        apiResponse.ErrorCode.Should().Be("USER_NOT_FOUND");
    }

    [Fact]
    public async Task UpdateProfile_WhenSuccessful_ReturnsOk()
    {
        // Arrange
        var userId = "user-1";
        var user = new AppUser { Id = userId, FullName = "Old Name" };
        var updateDto = new UpdateProfileDto { FullName = "New Name" };

        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);
        _mockUserManager.Setup(x => x.FindByIdAsync(userId)).ReturnsAsync(user);
        _mockUserManager.Setup(x => x.UpdateAsync(user)).ReturnsAsync(IdentityResult.Success);

        // Act
        var result = await _controller.UpdateProfile(updateDto);

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();
        user.FullName.Should().Be("New Name"); // Verify property update
    }

    [Fact]
    public async Task UpdateProfile_WhenUpdateFails_ReturnsBadRequest()
    {
        // Arrange
        var userId = "user-1";
        var user = new AppUser { Id = userId };
        var updateDto = new UpdateProfileDto { FullName = "New Name" };

        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);
        _mockUserManager.Setup(x => x.FindByIdAsync(userId)).ReturnsAsync(user);
        _mockUserManager.Setup(x => x.UpdateAsync(user))
            .ReturnsAsync(IdentityResult.Failed(new IdentityError { Description = "Update failed" }));

        // Act
        var result = await _controller.UpdateProfile(updateDto);

        // Assert
        var badRequestResult = result.Result.Should().BeOfType<BadRequestObjectResult>().Subject;
        var apiResponse = badRequestResult.Value.Should().BeOfType<ApiResponse<object>>().Subject;
        apiResponse.ErrorCode.Should().Be("PROFILE_UPDATE_FAILED");
        apiResponse.Errors.Should().Contain("Update failed");
    }

    [Fact]
    public async Task ChangePassword_WhenSuccessful_ReturnsOk()
    {
        // Arrange
        var userId = "user-1";
        var user = new AppUser { Id = userId };
        var changePassDto = new ChangePasswordDto { CurrentPassword = "old", NewPassword = "new" };

        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);
        _mockUserManager.Setup(x => x.FindByIdAsync(userId)).ReturnsAsync(user);
        _mockUserManager.Setup(x => x.ChangePasswordAsync(user, changePassDto.CurrentPassword, changePassDto.NewPassword))
            .ReturnsAsync(IdentityResult.Success);

        // Act
        var result = await _controller.ChangePassword(changePassDto);

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();
    }

    [Fact]
    public async Task ChangePassword_WhenUserNotFound_ReturnsNotFound()
    {
        // Arrange
        var userId = "user-1";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);
        _mockUserManager.Setup(x => x.FindByIdAsync(userId)).ReturnsAsync((AppUser?)null);
        var changePassDto = new ChangePasswordDto();

        // Act
        var result = await _controller.ChangePassword(changePassDto);

        // Assert
        var notFoundResult = result.Result.Should().BeOfType<NotFoundObjectResult>().Subject;
        var apiResponse = notFoundResult.Value.Should().BeOfType<ApiResponse<object>>().Subject;
        apiResponse.ErrorCode.Should().Be("USER_NOT_FOUND");
    }
}
