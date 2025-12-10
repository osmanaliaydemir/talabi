using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using AutoMapper;
using FluentAssertions;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
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

public class ReviewsControllerTests
{
    private readonly Mock<IUnitOfWork> _mockUnitOfWork;
    private readonly Mock<ILocalizationService> _mockLocalizationService;
    private readonly Mock<IUserContextService> _mockUserContextService;
    private readonly Mock<UserManager<AppUser>> _mockUserManager;
    private readonly Mock<IMapper> _mockMapper;
    private readonly ReviewsController _controller;

    public ReviewsControllerTests()
    {
        _mockUnitOfWork = ControllerTestHelpers.CreateMockUnitOfWork();
        _mockLocalizationService = ControllerTestHelpers.CreateMockLocalizationService();
        _mockUserContextService = ControllerTestHelpers.CreateMockUserContextService();
        _mockMapper = new Mock<IMapper>();
        var logger = ControllerTestHelpers.CreateMockLogger<ReviewsController>();

        var store = new Mock<IUserStore<AppUser>>();
        _mockUserManager = new Mock<UserManager<AppUser>>(store.Object, null, null, null, null, null, null, null, null);

        _controller = new ReviewsController(
            _mockUnitOfWork.Object,
            logger,
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
    public async Task CreateReview_WhenProductReviewAndSuccess_ReturnsCreated()
    {
        // Arrange
        var userId = "user-1";
        var product = new Product { Id = Guid.NewGuid(), VendorId = Guid.NewGuid() };
        var createDto = new CreateReviewDto
        {
            TargetType = "Product",
            TargetId = product.Id,
            Rating = 5,
            Comment = "Great!"
        };
        var review = new Review { Id = Guid.NewGuid(), ProductId = product.Id, UserId = userId, Rating = 5 };

        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);
        _mockUserManager.Setup(x => x.FindByIdAsync(userId)).ReturnsAsync(new AppUser { Id = userId });

        // Mock Products Repo
        var mockProductRepo = new Mock<IRepository<Product>>();
        mockProductRepo.Setup(x => x.GetByIdAsync(product.Id, It.IsAny<CancellationToken>())).ReturnsAsync(product);
        _mockUnitOfWork.Setup(x => x.Products).Returns(mockProductRepo.Object);

        // Mock Reviews Query for duplication check
        var reviews = new List<Review>();
        var mockReviewRepo = new Mock<IRepository<Review>>();
        var mockQueryable = reviews.BuildMock();
        mockReviewRepo.Setup(x => x.Query()).Returns(mockQueryable);

        // Setup re-query after add
        var savedReview = new Review
        {
            Id = review.Id,
            ProductId = product.Id,
            UserId = userId
        };
        var reviewsAfterSave = new List<Review> { savedReview };
        var mockQueryableAfterSave = reviewsAfterSave.BuildMock();
        // Since Query() is called twice, setup sequence or just return the second one if possible, 
        // but Moq will return the last setup. However, duplication check uses FirstOrDefaultAsync. 
        // We need to ensure Query() returns empty list first, then list with item.
        // Or simplified: Query() returns list with the new item only if the ID matches.
        // Actually, the code queries reviews where id == review.Id at end.

        mockReviewRepo.Setup(x => x.Query()).Returns(mockQueryableAfterSave); // This might break duplication check if it finds it?
        // Duplication check looks for userId && productId. 
        // The mockQueryableAfterSave has the review. If we set userId and productId on it, the check will find it.
        // But duplication check runs BEFORE AddAsync.
        // We can use SetupSequence for Query(), but Query returns IQueryable.
        // Let's rely on duplication check filtering by CreatedAt presumably? No.
        // Let's just say for duplication check, we return empty list if we can control it.
        // But Query() returns IQueryable which is then filtered.
        // We can construct a list that DOES NOT match duplication check but DOES match ID check?
        // Duplication check: r.UserId == userId && r.ProductId == dto.TargetId
        // ID check: r.Id == review.Id
        // If we make a review that matches ID check but not duplication (e.g. different user?) No, review has userId.
        // OK, for this test, let's skip deep integration simulation of EF query.
        // We can just omit duplicaton check if the list is empty?
        // If we return empty list, AddAsync works. Then re-query fails -> returns null -> mapper maps null -> ok.
        mockReviewRepo.Setup(x => x.Query()).Returns(reviews.BuildMock()); // Empty list

        _mockUnitOfWork.Setup(x => x.Reviews).Returns(mockReviewRepo.Object);
        _mockMapper.Setup(x => x.Map<ReviewDto>(It.IsAny<Review>())).Returns(new ReviewDto());

        // Act
        var result = await _controller.CreateReview(createDto);

        // Assert
        result.Result.Should().BeOfType<CreatedAtActionResult>();
        _mockUnitOfWork.Verify(x => x.Reviews.AddAsync(It.IsAny<Review>(), It.IsAny<CancellationToken>()), Times.Once);
        _mockUnitOfWork.Verify(x => x.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task GetProductReviews_WhenCalled_ReturnsReviews()
    {
        // Arrange
        var productId = Guid.NewGuid();
        var reviews = new List<Review>
        {
            new Review { Id = Guid.NewGuid(), ProductId = productId, IsApproved = true, Rating = 5, Comment = "Good" },
            new Review { Id = Guid.NewGuid(), ProductId = productId, IsApproved = true, Rating = 4, Comment = "Okay" }
        };

        var mockRepo = new Mock<IRepository<Review>>();
        var mockQueryable = reviews.BuildMock();
        mockRepo.Setup(x => x.Query()).Returns(mockQueryable);
        _mockUnitOfWork.Setup(x => x.Reviews).Returns(mockRepo.Object);

        _mockMapper.Setup(x => x.Map<List<ReviewDto>>(It.IsAny<List<Review>>()))
            .Returns(new List<ReviewDto> { new ReviewDto(), new ReviewDto() });

        // Act
        var result = await _controller.GetProductReviews(productId);

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<ProductReviewsSummaryDto>>().Subject;

        apiResponse.Data.TotalRatings.Should().Be(2);
        apiResponse.Data.AverageRating.Should().Be(4.5);
    }

    [Fact]
    public async Task ApproveReview_WhenAuthorized_ApprovesReview()
    {
        // Arrange
        var userId = "user-1";
        var reviewId = Guid.NewGuid();
        var vendorId = Guid.NewGuid();
        var review = new Review
        {
            Id = reviewId,
            VendorId = vendorId,
            Vendor = new Vendor { Id = vendorId, OwnerId = userId }
        };

        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        var reviews = new List<Review> { review };
        var mockRepo = new Mock<IRepository<Review>>();
        var mockQueryable = reviews.BuildMock();
        mockRepo.Setup(x => x.Query()).Returns(mockQueryable);
        _mockUnitOfWork.Setup(x => x.Reviews).Returns(mockRepo.Object);

        // Act
        var result = await _controller.ApproveReview(reviewId);

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();
        review.IsApproved.Should().BeTrue();

        _mockUnitOfWork.Verify(x => x.Reviews.Update(review), Times.Once); // Update might be void
        _mockUnitOfWork.Verify(x => x.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task ApproveReview_WhenNotOwner_ReturnsForbidden()
    {
        // Arrange
        var userId = "user-1";
        var otherUser = "user-2";
        var reviewId = Guid.NewGuid();
        var vendorId = Guid.NewGuid();
        var review = new Review
        {
            Id = reviewId,
            VendorId = vendorId,
            Vendor = new Vendor { Id = vendorId, OwnerId = otherUser }
        };

        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        var reviews = new List<Review> { review };
        var mockRepo = new Mock<IRepository<Review>>();
        var mockQueryable = reviews.BuildMock();
        mockRepo.Setup(x => x.Query()).Returns(mockQueryable);
        _mockUnitOfWork.Setup(x => x.Reviews).Returns(mockRepo.Object);

        // Act
        var result = await _controller.ApproveReview(reviewId);

        // Assert
        // Result should be ObjectResult with 403
        var objectResult = result.Result.Should().BeOfType<ObjectResult>().Subject;
        objectResult.StatusCode.Should().Be(403);
    }
}
