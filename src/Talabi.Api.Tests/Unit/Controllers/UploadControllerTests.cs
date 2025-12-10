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
using Xunit;

namespace Talabi.Api.Tests.Unit.Controllers;

public class UploadControllerTests
{
    private readonly Mock<IUnitOfWork> _mockUnitOfWork;
    private readonly Mock<ILocalizationService> _mockLocalizationService;
    private readonly Mock<IUserContextService> _mockUserContextService;
    private readonly Mock<IWebHostEnvironment> _mockEnvironment;
    private readonly UploadController _controller;

    public UploadControllerTests()
    {
        _mockUnitOfWork = ControllerTestHelpers.CreateMockUnitOfWork();
        _mockLocalizationService = ControllerTestHelpers.CreateMockLocalizationService();
        _mockUserContextService = ControllerTestHelpers.CreateMockUserContextService();
        _mockEnvironment = new Mock<IWebHostEnvironment>();

        // Mock web root path
        _mockEnvironment.Setup(x => x.WebRootPath).Returns(Path.GetTempPath());

        var logger = ControllerTestHelpers.CreateMockLogger<UploadController>();

        _controller = new UploadController(
            _mockUnitOfWork.Object,
            logger,
            _mockLocalizationService.Object,
            _mockUserContextService.Object,
            _mockEnvironment.Object
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
        var fileName = "test.jpg";
        var memoryStream = new MemoryStream();
        var writer = new StreamWriter(memoryStream);
        writer.Write(content);
        writer.Flush();
        memoryStream.Position = 0;

        var mockFile = new Mock<IFormFile>();
        mockFile.Setup(x => x.FileName).Returns(fileName);
        mockFile.Setup(x => x.Length).Returns(memoryStream.Length);
        mockFile.Setup(x => x.OpenReadStream()).Returns(memoryStream);
        mockFile.Setup(x => x.CopyToAsync(It.IsAny<Stream>(), It.IsAny<System.Threading.CancellationToken>()))
                .Callback<Stream, System.Threading.CancellationToken>((s, c) => memoryStream.CopyTo(s))
                .Returns(Task.CompletedTask);

        // Act
        var result = await _controller.Upload(mockFile.Object);

        // Assert
        var okResult = result.Should().BeOfType<OkObjectResult>().Subject;
        var value = okResult.Value;

        // We can use reflection or dynamic to check 'Url' property
        value.Should().NotBeNull();
        var type = value.GetType();
        var urlProp = type.GetProperty("Url");
        urlProp.Should().NotBeNull();

        var urlValue = urlProp.GetValue(value) as string;
        urlValue.Should().StartWith("http://localhost/images/");
        urlValue.Should().EndWith(".jpg");
    }
}
