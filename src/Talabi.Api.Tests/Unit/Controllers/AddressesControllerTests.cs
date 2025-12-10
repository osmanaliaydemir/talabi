using System.Globalization;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Moq;
using MockQueryable.Moq;
using MockQueryable;
using Talabi.Api.Controllers;
using Talabi.Api.Tests.Helpers;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Core.Interfaces;
using Xunit;
using System.Linq;
using System.Threading;

namespace Talabi.Api.Tests.Unit.Controllers;

/// <summary>
/// AddressesController için unit testler
/// </summary>
public class AddressesControllerTests
{
    private readonly Mock<IUnitOfWork> _mockUnitOfWork;
    private readonly ILogger<AddressesController> _logger;
    private readonly Mock<ILocalizationService> _mockLocalizationService;
    private readonly Mock<IUserContextService> _mockUserContextService;
    private readonly AddressesController _controller;

    public AddressesControllerTests()
    {
        _mockUnitOfWork = ControllerTestHelpers.CreateMockUnitOfWork();
        _logger = ControllerTestHelpers.CreateMockLogger<AddressesController>();
        _mockLocalizationService = ControllerTestHelpers.CreateMockLocalizationService();
        _mockUserContextService = ControllerTestHelpers.CreateMockUserContextService();

        _controller = new AddressesController(
            _mockUnitOfWork.Object,
            _logger,
            _mockLocalizationService.Object,
            _mockUserContextService.Object
        )
        {
            ControllerContext = ControllerTestHelpers.CreateControllerContext()
        };
    }

    [Fact]
    public async Task GetAddresses_WhenUserNotAuthorized_ReturnsUnauthorized()
    {
        // Arrange
        var mockUserService = ControllerTestHelpers.CreateMockUserContextService(null);
        mockUserService.Setup(x => x.GetUserId()).Returns((string?)null);

        var controller = new AddressesController(
            _mockUnitOfWork.Object,
            _logger,
            _mockLocalizationService.Object,
            mockUserService.Object
        );

        // Act
        var result = await controller.GetAddresses();

        // Assert
        result.Result.Should().BeOfType<UnauthorizedResult>();
    }

    [Fact]
    public async Task GetAddresses_WhenUserHasAddresses_ReturnsOkWithAddresses()
    {
        // Arrange
        var userId = "user-1";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        var addresses = new List<UserAddress>
        {
            new UserAddress { Id = Guid.NewGuid(), UserId = userId, Title = "Home", IsDefault = true, FullAddress = "Address 1", City = "Ist", District = "Sisli" },
            new UserAddress { Id = Guid.NewGuid(), UserId = userId, Title = "Work", IsDefault = false, FullAddress = "Address 2", City = "Ist", District = "Besiktas" }
        };

        var mockRepository = new Mock<IRepository<UserAddress>>();
        var mockQueryable = addresses.BuildMock();
        mockRepository.Setup(x => x.Query()).Returns(mockQueryable);

        _mockUnitOfWork.Setup(x => x.UserAddresses).Returns(mockRepository.Object);

        // Act
        var result = await _controller.GetAddresses();

        // Assert
        result.Should().NotBeNull();
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<List<AddressDto>>>().Subject;

        apiResponse.Success.Should().BeTrue();
        apiResponse.Data.Should().HaveCount(2);
        apiResponse.Data.First().IsDefault.Should().BeTrue(); // Should be ordered by IsDefault desc
    }

    [Fact]
    public async Task CreateAddress_WhenFirstAddress_SetsAsDefault()
    {
        // Arrange
        var userId = "user-1";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        // No existing addresses
        var existingAddresses = new List<UserAddress>();
        var mockRepository = new Mock<IRepository<UserAddress>>();
        var mockQueryable = existingAddresses.BuildMock();
        mockRepository.Setup(x => x.Query()).Returns(mockQueryable);
        _mockUnitOfWork.Setup(x => x.UserAddresses).Returns(mockRepository.Object);

        var createDto = new CreateAddressDto
        {
            Title = "Home",
            FullAddress = "Test Address",
            City = "Istanbul",
            District = "Kadikoy",
            PostalCode = "34000",
            Latitude = 41.0,
            Longitude = 29.0
        };

        // Act
        var result = await _controller.CreateAddress(createDto);

        // Assert
        var createdResult = result.Result.Should().BeOfType<CreatedAtActionResult>().Subject;
        var apiResponse = createdResult.Value.Should().BeOfType<ApiResponse<AddressDto>>().Subject;

        apiResponse.Data.IsDefault.Should().BeTrue();

        _mockUnitOfWork.Verify(x => x.UserAddresses.AddAsync(It.Is<UserAddress>(a => a.IsDefault == true), It.IsAny<CancellationToken>()), Times.Once);
        _mockUnitOfWork.Verify(x => x.SaveChangesAsync(default), Times.Once);
    }

    [Fact]
    public async Task CreateAddress_WhenNotFirstAddress_SetsAsNonDefault()
    {
        // Arrange
        var userId = "user-1";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        // Existing address
        var existingAddresses = new List<UserAddress>
        {
            new UserAddress { Id = Guid.NewGuid(), UserId = userId, Title = "Existing", IsDefault = true }
        };
        var mockRepository = new Mock<IRepository<UserAddress>>();
        var mockQueryable = existingAddresses.BuildMock();
        mockRepository.Setup(x => x.Query()).Returns(mockQueryable);
        _mockUnitOfWork.Setup(x => x.UserAddresses).Returns(mockRepository.Object);

        var createDto = new CreateAddressDto
        {
            Title = "Work",
            FullAddress = "Test Address 2",
            City = "Istanbul",
            District = "Sisli"
        };

        // Act
        var result = await _controller.CreateAddress(createDto);

        // Assert
        var createdResult = result.Result.Should().BeOfType<CreatedAtActionResult>().Subject;
        var apiResponse = createdResult.Value.Should().BeOfType<ApiResponse<AddressDto>>().Subject;

        // Response DTO might show IsDefault false based on input logic, 
        // but verifying AddAsync call is more precise
        _mockUnitOfWork.Verify(x => x.UserAddresses.AddAsync(It.Is<UserAddress>(a => a.IsDefault == false), It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task UpdateAddress_WhenAddressNotFound_ReturnsNotFound()
    {
        // Arrange
        var userId = "user-1";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);
        var addressId = Guid.NewGuid();

        var existingAddresses = new List<UserAddress>();
        var mockRepository = new Mock<IRepository<UserAddress>>();
        var mockQueryable = existingAddresses.BuildMock();
        mockRepository.Setup(x => x.Query()).Returns(mockQueryable);
        _mockUnitOfWork.Setup(x => x.UserAddresses).Returns(mockRepository.Object);

        var updateDto = new UpdateAddressDto { Title = "Updated" };

        // Act
        var result = await _controller.UpdateAddress(addressId, updateDto);

        // Assert
        var notFoundResult = result.Result.Should().BeOfType<NotFoundObjectResult>().Subject;
        var apiResponse = notFoundResult.Value.Should().BeOfType<ApiResponse<object>>().Subject;
        apiResponse.ErrorCode.Should().Be("ADDRESS_NOT_FOUND");
    }

    [Fact]
    public async Task SetDefaultAddress_WhenCalled_UpdatesDefaultStatus()
    {
        // Arrange
        var userId = "user-1";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        var addr1Id = Guid.NewGuid();
        var addr2Id = Guid.NewGuid();

        var initialAddresses = new List<UserAddress>
        {
            new UserAddress { Id = addr1Id, UserId = userId, IsDefault = true, Title = "Old Default" },
            new UserAddress { Id = addr2Id, UserId = userId, IsDefault = false, Title = "New Default" }
        };

        var mockRepository = new Mock<IRepository<UserAddress>>();
        var mockQueryable = initialAddresses.BuildMock();
        mockRepository.Setup(x => x.Query()).Returns(mockQueryable);
        _mockUnitOfWork.Setup(x => x.UserAddresses).Returns(mockRepository.Object);

        // Act
        var result = await _controller.SetDefaultAddress(addr2Id);

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();

        // Verify update calls
        _mockUnitOfWork.Verify(x => x.UserAddresses.Update(It.Is<UserAddress>(a => a.Id == addr1Id && a.IsDefault == false)), Times.Once); // Old default becomes false
        _mockUnitOfWork.Verify(x => x.UserAddresses.Update(It.Is<UserAddress>(a => a.Id == addr2Id && a.IsDefault == true)), Times.Once); // New default becomes true
        _mockUnitOfWork.Verify(x => x.SaveChangesAsync(default), Times.Once);
    }

    [Fact]
    public async Task DeleteAddress_WhenDefaultAddressDeleted_AssignsNewDefault()
    {
        // Arrange
        var userId = "user-1";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        var addr1Id = Guid.NewGuid(); // To be deleted default
        var addr2Id = Guid.NewGuid(); // Should become new default

        var initialAddresses = new List<UserAddress>
        {
            new UserAddress { Id = addr1Id, UserId = userId, IsDefault = true, Title = "To Delete" },
            new UserAddress { Id = addr2Id, UserId = userId, IsDefault = false, Title = "Next Default" }
        };

        var mockRepository = new Mock<IRepository<UserAddress>>();

        var mockQueryable = initialAddresses.BuildMock();
        mockRepository.Setup(x => x.Query()).Returns(mockQueryable);
        mockRepository.Setup(x => x.Remove(It.IsAny<UserAddress>()))
            .Callback<UserAddress>(a => initialAddresses.Remove(a));

        _mockUnitOfWork.Setup(x => x.UserAddresses).Returns(mockRepository.Object);

        // Act
        var result = await _controller.DeleteAddress(addr1Id);

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();

        _mockUnitOfWork.Verify(x => x.UserAddresses.Remove(It.Is<UserAddress>(a => a.Id == addr1Id)), Times.Once);
        // Should update addr2 to be default
        _mockUnitOfWork.Verify(x => x.UserAddresses.Update(It.Is<UserAddress>(a => a.Id == addr2Id && a.IsDefault == true)), Times.Once);
    }
}
