using System;
using System.IO;
using System.Threading.Tasks;
using FluentAssertions;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Moq;
using Talabi.Api.Controllers;
using Talabi.Api.Tests.Helpers;
using Talabi.Core.Interfaces;
using Talabi.Core.Services;
using Talabi.Core.DTOs;
using Xunit;

namespace Talabi.Api.Tests.Unit.Controllers;

public class UploadControllerTests
{
    private readonly UploadController _controller;

    public UploadControllerTests()
    {
        var mockUnitOfWork = ControllerTestHelpers.CreateMockUnitOfWork();
        var mockLocalizationService = ControllerTestHelpers.CreateMockLocalizationService();
        var mockUserContextService = ControllerTestHelpers.CreateMockUserContextService();
        var mockEnvironment = new Mock<IWebHostEnvironment>();
        var mockSecurityService = new Mock<IFileUploadSecurityService>();

        // Mock web root path
        mockEnvironment.Setup(x => x.WebRootPath).Returns(Path.GetTempPath());

        // Mock security service
        mockSecurityService.Setup(x => x.IsAllowedExtension(It.IsAny<string>())).Returns(true);
        mockSecurityService.Setup(x => x.IsValidFileSize(It.IsAny<long>())).Returns(true);
        mockSecurityService.Setup(x => x.IsValidFileContentAsync(It.IsAny<Stream>(), It.IsAny<string>()))
            .ReturnsAsync(true);
        mockSecurityService.Setup(x => x.SanitizeFileName(It.IsAny<string>())).Returns<string>(x => x);

        var logger = ControllerTestHelpers.CreateMockLogger<UploadController>();

        _controller = new UploadController(
            mockUnitOfWork.Object,
            logger,
            mockLocalizationService.Object,
            mockUserContextService.Object,
            mockEnvironment.Object,
            mockSecurityService.Object
        )
        {
            ControllerContext = ControllerTestHelpers.CreateControllerContext()
        };

        // Setup HttpContext
        var httpContext = new DefaultHttpContext();
        httpContext.Request.Scheme = "http";
        httpContext.Request.Host = new HostString("localhost");
        _controller.ControllerContext.HttpContext = httpContext;
    }

    [Fact]
    public async Task Upload_WhenFileIsNull_ReturnsBadRequest()
    {
        // Act
        var result = await _controller.Upload(null!);

        // Assert
        result.Should().BeOfType<BadRequestObjectResult>();
    }

    [Fact]
    public async Task Upload_WhenFileIsEmpty_ReturnsBadRequest()
    {
        // Arrange
        var mockFile = new Mock<IFormFile>();
        mockFile.Setup(x => x.Length).Returns(0);

        // Act
        var result = await _controller.Upload(mockFile.Object);

        // Assert
        result.Should().BeOfType<BadRequestObjectResult>();
    }

    [Fact]
    public async Task Upload_WhenFileIsValid_ReturnsOkWithUrl()
    {
        // Arrange
        var content = "test content";
        var bytes = System.Text.Encoding.UTF8.GetBytes(content);

        var mockFile = new Mock<IFormFile>();
        mockFile.Setup(x => x.FileName).Returns("test.jpg");
        mockFile.Setup(x => x.Length).Returns(bytes.Length);
        mockFile.Setup(x => x.OpenReadStream()).Returns(() => new MemoryStream(bytes));

        // Act
        var result = await _controller.Upload(mockFile.Object);

        // Assert
        var okResult = result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<object>>().Subject;
        var data = apiResponse.Data;

        // We can use reflection or dynamic to check 'Url' property on Data object
        data.Should().NotBeNull();
        var type = data!.GetType();
        var urlProp = type.GetProperty("Url");
        urlProp.Should().NotBeNull();

        var urlValue = urlProp!.GetValue(data) as string;
        urlValue.Should().StartWith("http://localhost/images/");
        urlValue.Should().EndWith(".jpg");
    }
}
