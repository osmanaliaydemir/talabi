using System;
using System.Collections.Generic;
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

public class VendorProfileControllerTests
{
    private readonly Mock<IUnitOfWork> _mockUnitOfWork;
    private readonly Mock<ILocalizationService> _mockLocalizationService;
    private readonly Mock<IUserContextService> _mockUserContextService;
    private readonly VendorProfileController _controller;

    public VendorProfileControllerTests()
    {
        _mockUnitOfWork = ControllerTestHelpers.CreateMockUnitOfWork();
        _mockLocalizationService = ControllerTestHelpers.CreateMockLocalizationService();
        _mockUserContextService = ControllerTestHelpers.CreateMockUserContextService();
        var logger = ControllerTestHelpers.CreateMockLogger<VendorProfileController>();

        _controller = new VendorProfileController(
            _mockUnitOfWork.Object,
            logger,
            _mockLocalizationService.Object,
            _mockUserContextService.Object
        )
        {
            ControllerContext = ControllerTestHelpers.CreateControllerContext()
        };
    }

    private void SetupVendor(string userId, Guid vendorId)
    {
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        var vendor = new Vendor
        {
            Id = vendorId,
            OwnerId = userId,
            Name = "Test Vendor",
            Address = "Test Address"
        };
        var vendors = new List<Vendor> { vendor };
        var mockRepo = new Mock<IRepository<Vendor>>();
        mockRepo.Setup(x => x.Query()).Returns(vendors.BuildMock());
        _mockUnitOfWork.Setup(x => x.Vendors).Returns(mockRepo.Object);
    }

    [Fact]
    public async Task GetProfile_WhenVendorFound_ReturnsProfile()
    {
        // Arrange
        var userId = "user-1";
        var vendorId = Guid.NewGuid();
        SetupVendor(userId, vendorId);

        // Act
        var result = await _controller.GetProfile();

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<VendorProfileDto>>().Subject;

        apiResponse.Data.Id.Should().Be(vendorId);
        apiResponse.Data.Name.Should().Be("Test Vendor");
    }

    [Fact]
    public async Task UpdateProfile_WhenVendorFound_UpdatesProfile()
    {
        // Arrange
        var userId = "user-1";
        var vendorId = Guid.NewGuid();
        SetupVendor(userId, vendorId);

        var dto = new UpdateVendorProfileDto { Name = "New Name" };

        // Act
        var result = await _controller.UpdateProfile(dto);

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();

        _mockUnitOfWork.Verify(x => x.Vendors.Update(It.Is<Vendor>(v => v.Name == "New Name")), Times.Once);
        _mockUnitOfWork.Verify(x => x.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task UpdateImage_WhenVendorFound_UpdatesImage()
    {
        // Arrange
        var userId = "user-1";
        var vendorId = Guid.NewGuid();
        SetupVendor(userId, vendorId);

        var dto = new UpdateVendorImageDto { ImageUrl = "new-image.jpg" };

        // Act
        var result = await _controller.UpdateImage(dto);

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();

        _mockUnitOfWork.Verify(x => x.Vendors.Update(It.Is<Vendor>(v => v.ImageUrl == "new-image.jpg")), Times.Once);
        _mockUnitOfWork.Verify(x => x.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task GetSettings_WhenVendorFound_ReturnsSettings()
    {
        // Arrange
        var userId = "user-1";
        var vendorId = Guid.NewGuid();
        SetupVendor(userId, vendorId);

        // Act
        var result = await _controller.GetSettings();

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<VendorSettingsDto>>().Subject;

        apiResponse.Data.Should().NotBeNull();
    }

    [Fact]
    public async Task UpdateSettings_WhenVendorFound_UpdatesSettings()
    {
        // Arrange
        var userId = "user-1";
        var vendorId = Guid.NewGuid();
        SetupVendor(userId, vendorId);

        var dto = new UpdateVendorSettingsDto { MinimumOrderAmount = 150 };

        // Act
        var result = await _controller.UpdateSettings(dto);

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();

        _mockUnitOfWork.Verify(x => x.Vendors.Update(It.Is<Vendor>(v => v.MinimumOrderAmount == 150)), Times.Once);
        _mockUnitOfWork.Verify(x => x.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task UpdateActiveStatus_WhenVendorFound_UpdatesStatus()
    {
        // Arrange
        var userId = "user-1";
        var vendorId = Guid.NewGuid();
        SetupVendor(userId, vendorId);

        var dto = new UpdateVendorActiveStatusDto { IsActive = false };

        // Act
        var result = await _controller.UpdateActiveStatus(dto);

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();

        _mockUnitOfWork.Verify(x => x.Vendors.Update(It.Is<Vendor>(v => v.IsActive == false)), Times.Once);
        _mockUnitOfWork.Verify(x => x.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }
}
