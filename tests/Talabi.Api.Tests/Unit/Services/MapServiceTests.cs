using System.Net;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Moq;
using Moq.Protected;
using Talabi.Core.Options;
using Talabi.Infrastructure.Services;
using Xunit;

namespace Talabi.Api.Tests.Unit.Services;

public class MapServiceTests
{
    private readonly Mock<IOptions<GoogleMapsOptions>> _mockOptions;
    private readonly Mock<ILogger<GoogleMapService>> _mockLogger;

    public MapServiceTests()
    {
        _mockOptions = new Mock<IOptions<GoogleMapsOptions>>();
        _mockLogger = new Mock<ILogger<GoogleMapService>>();

        _mockOptions.Setup(o => o.Value).Returns(new GoogleMapsOptions { ApiKey = "test-api-key" });
    }

    [Fact]
    public async Task GetRoadDistanceAsync_ReturnsDistance_WhenApiSucceeds()
    {
        // Arrange
        var jsonResponse = @"
        {
            ""status"": ""OK"",
            ""rows"": [
                {
                    ""elements"": [
                        {
                            ""status"": ""OK"",
                            ""distance"": {
                                ""value"": 5200
                            }
                        }
                    ]
                }
            ]
        }";

        var mockHttpMessageHandler = new Mock<HttpMessageHandler>();
        mockHttpMessageHandler.Protected()
            .Setup<Task<HttpResponseMessage>>(
                "SendAsync",
                ItExpr.IsAny<HttpRequestMessage>(),
                ItExpr.IsAny<CancellationToken>())
            .ReturnsAsync(new HttpResponseMessage
            {
                StatusCode = HttpStatusCode.OK,
                Content = new StringContent(jsonResponse)
            });

        var httpClient = new HttpClient(mockHttpMessageHandler.Object);
        var service = new GoogleMapService(httpClient, _mockOptions.Object, _mockLogger.Object);

        // Act
        var result = await service.GetRoadDistanceAsync(0, 0, 1, 1);

        // Assert
        result.Should().Be(5.2);
    }

    [Fact]
    public async Task GetRoadDistanceAsync_ReturnsNegativeOne_WhenApiFails()
    {
        // Arrange
        var jsonResponse = @"{ ""status"": ""REQUEST_DENIED"" }";

        var mockHttpMessageHandler = new Mock<HttpMessageHandler>();
        mockHttpMessageHandler.Protected()
            .Setup<Task<HttpResponseMessage>>(
                "SendAsync",
                ItExpr.IsAny<HttpRequestMessage>(),
                ItExpr.IsAny<CancellationToken>())
            .ReturnsAsync(new HttpResponseMessage
            {
                StatusCode = HttpStatusCode.OK,
                Content = new StringContent(jsonResponse)
            });

        var httpClient = new HttpClient(mockHttpMessageHandler.Object);
        var service = new GoogleMapService(httpClient, _mockOptions.Object, _mockLogger.Object);

        // Act
        var result = await service.GetRoadDistanceAsync(0, 0, 1, 1);

        // Assert
        result.Should().Be(-1);
    }

    [Fact]
    public async Task GetRoadDistanceAsync_ReturnsZero_WhenApiKeyMissing()
    {
        // Arrange
        _mockOptions.Setup(o => o.Value).Returns(new GoogleMapsOptions { ApiKey = "" });
        var httpClient = new HttpClient();
        var service = new GoogleMapService(httpClient, _mockOptions.Object, _mockLogger.Object);

        // Act
        var result = await service.GetRoadDistanceAsync(0, 0, 1, 1);

        // Assert
        result.Should().Be(0);
    }
}
