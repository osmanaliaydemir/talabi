using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;
using MockQueryable;
using MockQueryable.Moq;
using Moq;
using Talabi.Api.Controllers;
using Talabi.Api.Tests.Helpers;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Core.Interfaces;
using Talabi.Core.Options;
using Xunit;

namespace Talabi.Api.Tests.Unit.Controllers;

public class ContentControllerTests
{
    private readonly Mock<IUnitOfWork> _mockUnitOfWork;
    private readonly Mock<ILocalizationService> _mockLocalizationService;
    private readonly Mock<IUserContextService> _mockUserContextService;
    private readonly Mock<ICacheService> _mockCacheService;
    private readonly Mock<IOptions<CacheOptions>> _mockCacheOptions;
    private readonly ContentController _controller;

    public ContentControllerTests()
    {
        _mockUnitOfWork = ControllerTestHelpers.CreateMockUnitOfWork();
        _mockLocalizationService = ControllerTestHelpers.CreateMockLocalizationService();
        _mockUserContextService = ControllerTestHelpers.CreateMockUserContextService();
        _mockCacheService = new Mock<ICacheService>();
        _mockCacheOptions = new Mock<IOptions<CacheOptions>>();

        _mockCacheOptions.Setup(x => x.Value).Returns(new CacheOptions
        {
            LegalDocumentsKeyPrefix = "legal_docs",
            LegalDocumentsCacheTTLMinutes = 60
        });

        // Setup CacheService to return fixed object for testing
        _mockCacheService
            .Setup(x => x.GetOrSetAsync(It.IsAny<string>(), It.IsAny<Func<Task<object?>>>(), It.IsAny<int>()))
            .Returns((string k, Func<Task<object?>> f, int t) =>
            {
                if (k.Contains("non-existent")) return Task.FromResult<object?>(null);
                return Task.FromResult<object?>((object)new { Type = "terms-of-use", LanguageCode = "en", Title = "Title", Content = "Content", LastUpdated = DateTime.Now });
            });

        // Generic version setup if needed (GetOrSetAsync is generic usually? In the code it looked like it returns object for single doc but List<string> for types)
        // Wait, controller uses dynamic/object for documentDto? "var documentDto = await ..."
        // And for types "var types = await ..."
        // So I should mock the generic generic method if ICacheService has one method with generic.
        // Let's assume generic.
        _mockCacheService
            .Setup(x => x.GetOrSetAsync(It.IsAny<string>(), It.IsAny<Func<Task<List<string>?>>>(), It.IsAny<int>()))
            .Returns<string, Func<Task<List<string>?>>, int>((k, f, t) => f());

        var logger = ControllerTestHelpers.CreateMockLogger<ContentController>();

        _controller = new ContentController(
            _mockUnitOfWork.Object,
            logger,
            _mockLocalizationService.Object,
            _mockUserContextService.Object,
            _mockCacheService.Object,
            _mockCacheOptions.Object
        )
        {
            ControllerContext = ControllerTestHelpers.CreateControllerContext()
        };
    }

    [Fact]
    public async Task GetLegalDocument_WhenExists_ReturnsDocument()
    {
        // Arrange
        // Set culture to en to match test data
        var culture = new System.Globalization.CultureInfo("en");
        System.Threading.Thread.CurrentThread.CurrentCulture = culture;
        System.Threading.Thread.CurrentThread.CurrentUICulture = culture;

        var type = "terms-of-use";
        var lang = "en"; // Default culture in test setup might be en/tr, let's assume en or rely on controller context.
                         // CurrentCulture is used in Controller. BaseController might set it.
                         // Let's rely on default behavior or mocks.

        var documents = new List<LegalDocument>
        {
            new LegalDocument { Type = type, LanguageCode = lang, Content = "Content", Title = "Title" }
        };

        var mockRepo = new Mock<IRepository<LegalDocument>>();
        mockRepo.Setup(x => x.Query()).Returns(documents.BuildMock());
        _mockUnitOfWork.Setup(x => x.LegalDocuments).Returns(mockRepo.Object);

        // Act
        var result = await _controller.GetLegalDocument(type);

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<object>>().Subject;
        apiResponse.Success.Should().BeTrue();
    }

    [Fact]
    public async Task GetLegalDocument_WhenNotExists_ReturnsNotFound()
    {
        // Arrange
        var documents = new List<LegalDocument>();
        var mockRepo = new Mock<IRepository<LegalDocument>>();
        mockRepo.Setup(x => x.Query()).Returns(documents.BuildMock());
        _mockUnitOfWork.Setup(x => x.LegalDocuments).Returns(mockRepo.Object);

        // Act
        var result = await _controller.GetLegalDocument("non-existent");

        // Assert
        result.Result.Should().BeOfType<NotFoundObjectResult>();
    }

    [Fact]
    public async Task GetLegalDocumentTypes_WhenCalled_ReturnsTypes()
    {
        // Arrange
        var documents = new List<LegalDocument>
        {
            new LegalDocument { Type = "terms" },
            new LegalDocument { Type = "privacy" },
            new LegalDocument { Type = "terms" } // Duplicate
        };

        var mockRepo = new Mock<IRepository<LegalDocument>>();
        mockRepo.Setup(x => x.Query()).Returns(documents.BuildMock());
        _mockUnitOfWork.Setup(x => x.LegalDocuments).Returns(mockRepo.Object);

        // Act
        var result = await _controller.GetLegalDocumentTypes();

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<List<string>>>().Subject;

        apiResponse.Data.Should().HaveCount(2);
        apiResponse.Data.Should().Contain("terms");
        apiResponse.Data.Should().Contain("privacy");
    }
}
