using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using AutoMapper;
using FluentAssertions;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using MockQueryable.Moq;
using Moq;
using Talabi.Api.Controllers;
using Talabi.Api.Tests.Helpers;
using Talabi.Core.DTOs;
using Talabi.Core.DTOs.Courier;
using Talabi.Core.Entities;
using Talabi.Core.Enums;
using Talabi.Core.Interfaces;
using Xunit;

namespace Talabi.Api.Tests.Unit.Controllers;

public class CourierControllerTests
{
    private readonly Mock<IUnitOfWork> _mockUnitOfWork;
    private readonly Mock<ILocalizationService> _mockLocalizationService;
    private readonly Mock<IUserContextService> _mockUserContextService;
    private readonly Mock<UserManager<AppUser>> _mockUserManager;
    private readonly Mock<IMapper> _mockMapper;
    private readonly CourierController _controller;

    public CourierControllerTests()
    {
        _mockUnitOfWork = ControllerTestHelpers.CreateMockUnitOfWork();
        _mockLocalizationService = ControllerTestHelpers.CreateMockLocalizationService();
        _mockUserContextService = ControllerTestHelpers.CreateMockUserContextService();
        _mockMapper = new Mock<IMapper>();

        var userStore = new Mock<IUserStore<AppUser>>();
        _mockUserManager = new Mock<UserManager<AppUser>>(userStore.Object, null, null, null, null, null, null, null, null);

        var logger = ControllerTestHelpers.CreateMockLogger<CourierController>();

        _controller = new CourierController(
            _mockUnitOfWork.Object,
            _mockUserManager.Object,
            logger,
            _mockLocalizationService.Object,
            _mockUserContextService.Object,
            _mockMapper.Object
        )
        {
            ControllerContext = ControllerTestHelpers.CreateControllerContext()
        };
    }

    [Fact]
    public async Task GetProfile_WhenCourierExists_ReturnsProfile()
    {
        // Arrange
        var userId = "user123";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        var courier = new Courier
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Name = "Test Courier"
        };

        var mockRepo = new Mock<IRepository<Courier>>();
        mockRepo.Setup(x => x.Query()).Returns(new List<Courier> { courier }.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Couriers).Returns(mockRepo.Object);

        _mockMapper.Setup(x => x.Map<CourierProfileDto>(It.IsAny<Courier>()))
            .Returns(new CourierProfileDto { Name = "Test Courier" });

        // Act
        var result = await _controller.GetProfile();

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<CourierProfileDto>>().Subject;

        apiResponse.Success.Should().BeTrue();
        apiResponse.Data.Name.Should().Be("Test Courier");
    }

    [Fact]
    public async Task GetProfile_WhenCourierDoesNotExist_CreatesAndReturnsProfile()
    {
        // Arrange
        var userId = "user123";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        var user = new AppUser { Id = userId, FullName = "New Courier" };

        var mockRepo = new Mock<IRepository<Courier>>();
        // Empty list initially
        mockRepo.Setup(x => x.Query()).Returns(new List<Courier>().AsQueryable().BuildMock());
        // Verify Add is called
        mockRepo.Setup(x => x.AddAsync(It.IsAny<Courier>())).Returns(Task.CompletedTask);

        _mockUnitOfWork.Setup(x => x.Couriers).Returns(mockRepo.Object);
        _mockUnitOfWork.Setup(x => x.SaveChangesAsync()).Returns(Task.CompletedTask);

        _mockUserManager.Setup(x => x.FindByIdAsync(userId)).ReturnsAsync(user);

        _mockMapper.Setup(x => x.Map<CourierProfileDto>(It.IsAny<Courier>()))
            .Returns(new CourierProfileDto { Name = "New Courier" });

        // Act
        var result = await _controller.GetProfile();

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<CourierProfileDto>>().Subject;

        apiResponse.Success.Should().BeTrue();
        apiResponse.Data.Name.Should().Be("New Courier");
        mockRepo.Verify(x => x.AddAsync(It.IsAny<Courier>()), Times.Once);
    }
}
