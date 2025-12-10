using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using MockQueryable;
using MockQueryable.Moq;
using Moq;
using Talabi.Api.Controllers;
using Talabi.Api.Tests.Helpers;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Core.Interfaces;
using Xunit;

namespace Talabi.Api.Tests.Unit.Controllers;

public class UserPreferencesControllerTests
{
    private readonly Mock<IUnitOfWork> _mockUnitOfWork;
    private readonly Mock<ILocalizationService> _mockLocalizationService;
    private readonly Mock<IUserContextService> _mockUserContextService;
    private readonly UserPreferencesController _controller;

    public UserPreferencesControllerTests()
    {
        _mockUnitOfWork = ControllerTestHelpers.CreateMockUnitOfWork();
        _mockLocalizationService = ControllerTestHelpers.CreateMockLocalizationService();
        _mockUserContextService = ControllerTestHelpers.CreateMockUserContextService();
        var logger = ControllerTestHelpers.CreateMockLogger<UserPreferencesController>();

        _controller = new UserPreferencesController(
            _mockUnitOfWork.Object,
            logger,
            _mockLocalizationService.Object,
            _mockUserContextService.Object
        )
        {
            ControllerContext = ControllerTestHelpers.CreateControllerContext()
        };
    }

    [Fact]
    public async Task GetPreferences_WhenPreferencesExist_ReturnsPreferences()
    {
        // Arrange
        var userId = "user-1";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        var preferences = new List<UserPreferences>
        {
            new UserPreferences
            {
                UserId = userId,
                Language = "tr",
                Currency = "TRY",
                TimeFormat = "12h"
            }
        };

        var mockRepo = new Mock<IRepository<UserPreferences>>();
        var mockQueryable = preferences.BuildMock();
        mockRepo.Setup(x => x.Query()).Returns(mockQueryable);

        _mockUnitOfWork.Setup(x => x.UserPreferences).Returns(mockRepo.Object);

        // Act
        var result = await _controller.GetPreferences();

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<UserPreferencesDto>>().Subject;

        apiResponse.Data.Language.Should().Be("tr");
        apiResponse.Data.Currency.Should().Be("TRY");
        apiResponse.Data.TimeFormat.Should().Be("12h");
    }

    [Fact]
    public async Task GetPreferences_WhenPreferencesDoNotExist_CreatesDefaultAndReturns()
    {
        // Arrange
        var userId = "user-1";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        var preferences = new List<UserPreferences>(); // Empty

        var mockRepo = new Mock<IRepository<UserPreferences>>();
        var mockQueryable = preferences.BuildMock();
        mockRepo.Setup(x => x.Query()).Returns(mockQueryable);

        _mockUnitOfWork.Setup(x => x.UserPreferences).Returns(mockRepo.Object);

        // Act
        var result = await _controller.GetPreferences();

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<UserPreferencesDto>>().Subject;

        // Default values
        apiResponse.Data.Language.Should().Be("tr");
        apiResponse.Data.Currency.Should().Be("TRY");
        apiResponse.Data.TimeFormat.Should().Be("24h");
        apiResponse.Data.DateFormat.Should().Be("dd/MM/yyyy");

        // Verify creation
        _mockUnitOfWork.Verify(x => x.UserPreferences.AddAsync(It.Is<UserPreferences>(p => p.UserId == userId), It.IsAny<CancellationToken>()), Times.Once);
        _mockUnitOfWork.Verify(x => x.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task UpdatePreferences_WhenPreferencesExist_UpdatesPreferences()
    {
        // Arrange
        var userId = "user-1";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        var existingPref = new UserPreferences
        {
            UserId = userId,
            Language = "tr"
        };
        var preferences = new List<UserPreferences> { existingPref };

        var mockRepo = new Mock<IRepository<UserPreferences>>();
        var mockQueryable = preferences.BuildMock();
        mockRepo.Setup(x => x.Query()).Returns(mockQueryable);
        _mockUnitOfWork.Setup(x => x.UserPreferences).Returns(mockRepo.Object);

        var updateDto = new UpdateUserPreferencesDto
        {
            Language = "en",
            Currency = "USDT"
        };

        // Act
        var result = await _controller.UpdatePreferences(updateDto);

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();

        // Verify property update on the existing object
        existingPref.Language.Should().Be("en");
        existingPref.Currency.Should().Be("USDT");

        _mockUnitOfWork.Verify(x => x.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task UpdatePreferences_WhenPreferencesDoNotExist_CreatesAndUpdatesPreferences()
    {
        // Arrange
        var userId = "user-1";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        var preferences = new List<UserPreferences>(); // Empty

        var mockRepo = new Mock<IRepository<UserPreferences>>();
        var mockQueryable = preferences.BuildMock();
        mockRepo.Setup(x => x.Query()).Returns(mockQueryable);
        _mockUnitOfWork.Setup(x => x.UserPreferences).Returns(mockRepo.Object);

        var updateDto = new UpdateUserPreferencesDto
        {
            Language = "en",
            TimeFormat = "12h"
        };

        // Act
        var result = await _controller.UpdatePreferences(updateDto);

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();

        _mockUnitOfWork.Verify(x => x.UserPreferences.AddAsync(
            It.Is<UserPreferences>(p => p.UserId == userId && p.Language == "en" && p.TimeFormat == "12h"),
            It.IsAny<CancellationToken>()
        ), Times.Once);
        _mockUnitOfWork.Verify(x => x.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public void GetSupportedLanguages_WhenCalled_ReturnsLanguages()
    {
        // Act
        var result = _controller.GetSupportedLanguages();

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<List<SupportedLanguageDto>>>().Subject;

        apiResponse.Data.Should().HaveCount(3);
        apiResponse.Data.Should().Contain(l => l.Code == "tr");
        apiResponse.Data.Should().Contain(l => l.Code == "en");
    }

    [Fact]
    public void GetSupportedCurrencies_WhenCalled_ReturnsCurrencies()
    {
        // Act
        var result = _controller.GetSupportedCurrencies();

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<List<SupportedCurrencyDto>>>().Subject;

        apiResponse.Data.Should().HaveCount(2);
        apiResponse.Data.Should().Contain(c => c.Code == "TRY");
    }
}
