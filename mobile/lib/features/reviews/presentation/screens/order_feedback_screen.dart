import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/features/orders/data/models/order_detail.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/widgets/toast_message.dart';
import 'package:get_it/get_it.dart';
import 'package:mobile/features/home/presentation/widgets/shared_header.dart';
import 'package:mobile/widgets/cached_network_image_widget.dart';

class OrderFeedbackScreen extends StatefulWidget {
  const OrderFeedbackScreen({
    super.key,
    required this.orderDetail,
    this.reviewStatus,
  });

  final OrderDetail orderDetail;
  final Map<String, dynamic>? reviewStatus;

  @override
  State<OrderFeedbackScreen> createState() => _OrderFeedbackScreenState();
}

class _OrderFeedbackScreenState extends State<OrderFeedbackScreen> {
  late final ApiService _apiService;
  bool _isLoading = false;

  // Courier
  double _courierRating = 5;
  final TextEditingController _courierCommentController =
      TextEditingController();

  // Vendor
  double _vendorRating = 5;
  final TextEditingController _vendorCommentController =
      TextEditingController();

  // Products
  // Map of productId -> rating/comment
  final Map<String, double> _productRatings = {};
  final Map<String, TextEditingController> _productComments = {};

  // Maps to track what is already reviewed
  bool _isCourierAlreadyRated = false;
  bool _isVendorAlreadyReviewed = false;
  final Set<String> _alreadyReviewedProductIds = {};

  // Approval statuses for view mode
  bool _isCourierApproved = true;
  bool _isVendorApproved = true;
  final Map<String, bool> _productApprovalStatuses = {};

  @override
  void initState() {
    super.initState();
    _apiService = GetIt.instance<ApiService>();

    // Initial values from OrderDetail
    for (final item in widget.orderDetail.items) {
      if (!item.isCancelled) {
        _productRatings[item.productId] = 5;
        _productComments[item.productId] = TextEditingController();
      }
    }

    // Parse existing reviews if available
    if (widget.reviewStatus != null) {
      // Status flags
      _isCourierAlreadyRated =
          widget.reviewStatus!['isCourierRated'] as bool? ?? false;
      _isVendorAlreadyReviewed =
          widget.reviewStatus!['isVendorReviewed'] as bool? ?? false;
      final reviewedIds = (widget.reviewStatus!['reviewedProductIds'] as List?)
          ?.map((e) => e.toString())
          .toSet();
      if (reviewedIds != null) {
        _alreadyReviewedProductIds.addAll(reviewedIds);
      }

      // Review Details
      final reviews = widget.reviewStatus!['reviews'] as List?;
      if (reviews != null) {
        for (final r in reviews) {
          final review = r as Map<String, dynamic>;
          final courierId = review['courierId'];
          final vendorId = review['vendorId'];
          final productId = review['productId'];
          final rating = (review['rating'] as num?)?.toDouble() ?? 5.0;
          final comment = review['comment'] as String? ?? '';

          final isApproved = review['isApproved'] as bool? ?? true;

          if (courierId != null) {
            _courierRating = rating;
            _courierCommentController.text = comment;
            _isCourierApproved = isApproved;
          } else if (vendorId != null) {
            _vendorRating = rating;
            _vendorCommentController.text = comment;
            _isVendorApproved = isApproved;
          } else if (productId != null) {
            final pid = productId.toString();
            _productRatings[pid] = rating;
            _productApprovalStatuses[pid] = isApproved;
            if (_productComments.containsKey(pid)) {
              _productComments[pid]!.text = comment;
            }
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _vendorCommentController.dispose();
    _courierCommentController.dispose();
    for (final controller in _productComments.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    setState(() => _isLoading = true);
    final localizations = AppLocalizations.of(context)!;

    try {
      // Validation
      for (final item in widget.orderDetail.items) {
        if (!item.isCancelled) {
          final comment = _productComments[item.productId]?.text ?? '';
          if (comment.isNotEmpty && comment.length < 10) {
            ToastMessage.show(
              context,
              message: localizations.commentTooShort(10),
              isSuccess: false,
            );
            setState(() => _isLoading = false);
            return;
          }
        }
      }
      if (_courierCommentController.text.isNotEmpty &&
          _courierCommentController.text.length < 10) {
        ToastMessage.show(
          context,
          message: localizations.commentTooShort(10),
          isSuccess: false,
        );
        setState(() => _isLoading = false);
        return;
      }
      if (_vendorCommentController.text.isNotEmpty &&
          _vendorCommentController.text.length < 10) {
        ToastMessage.show(
          context,
          message: localizations.commentTooShort(10),
          isSuccess: false,
        );
        setState(() => _isLoading = false);
        return;
      }

      final productFeedbacks = widget.orderDetail.items
          .where((item) => !item.isCancelled)
          .map(
            (item) => {
              'productId': item.productId,
              'rating': (_productRatings[item.productId] ?? 5).toInt(),
              'comment': _productComments[item.productId]?.text ?? '',
            },
          )
          .toList();

      final feedbackData = {
        'orderId': widget.orderDetail.id,
        'courierRating': _courierRating.toInt(),
        'courierComment': _courierCommentController.text,
        'vendorFeedback': {
          'rating': _vendorRating.toInt(),
          'comment': _vendorCommentController.text,
        },
        'productFeedbacks': productFeedbacks,
      };

      await _apiService.submitOrderFeedback(feedbackData);

      if (mounted) {
        ToastMessage.show(
          context,
          message: localizations.feedbackSubmittedSuccessfully,
          isSuccess: true,
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ToastMessage.show(
          context,
          message: localizations.errorWithMessage(e.toString()),
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildRatingSection({
    required String title,
    required double rating,
    required ValueChanged<double> onRatingUpdate,
    TextEditingController? commentController,
    String? hintText,
    String? imageUrl,
    bool isCircleImage = true,
    bool isReadOnly = false,
    bool isApproved = true,
  }) {
    final localizations = AppLocalizations.of(context)!;
    return Opacity(
      opacity: isReadOnly ? 0.7 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        decoration: AppTheme.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (imageUrl != null) ...[
                  ClipRRect(
                    borderRadius: isCircleImage
                        ? BorderRadius.circular(20)
                        : BorderRadius.circular(8),
                    child: OptimizedCachedImage.productThumbnail(
                      imageUrl: imageUrl,
                      width: 40,
                      height: 40,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMedium),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: AppTheme.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isReadOnly)
                  isApproved
                      ? const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            localizations.pendingApproval,
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            IgnorePointer(
              ignoring: isReadOnly,
              child: Center(
                child: RatingBar.builder(
                  initialRating: rating,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: false,
                  itemCount: 5,
                  itemSize: 32,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                  itemBuilder: (context, _) =>
                      const Icon(Icons.star, color: Colors.amber),
                  onRatingUpdate: onRatingUpdate,
                ),
              ),
            ),
            if (commentController != null) ...[
              const SizedBox(height: AppTheme.spacingMedium),
              IgnorePointer(
                ignoring: isReadOnly,
                child: TextField(
                  controller: commentController,
                  readOnly: isReadOnly,
                  decoration: InputDecoration(
                    hintText: hintText,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                    filled: isReadOnly,
                    fillColor: isReadOnly ? Colors.grey[100] : null,
                  ),
                  maxLines: 2,
                  onChanged: (value) => setState(() {}),
                ),
              ),
              if (!isReadOnly && commentController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    localizations.characterLimitInfo(
                      10,
                      500,
                      commentController.text.length,
                    ),
                    style: TextStyle(
                      fontSize: 10,
                      color: commentController.text.length < 10
                          ? Colors.red
                          : Colors.grey,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          SharedHeader(
            title: widget.reviewStatus != null
                ? localizations.yourOrderFeedback
                : localizations.rateOrder,
            subtitle: localizations.orderNumberWithId(
              widget.orderDetail.customerOrderId,
            ),
            showBackButton: true,
            showSearch: false,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              child: Column(
                children: [
                  // Courier Rating
                  if (widget.orderDetail.activeOrderCourier != null)
                    _buildRatingSection(
                      title: localizations.rateCourier,
                      rating: _courierRating,
                      onRatingUpdate: (val) =>
                          setState(() => _courierRating = val),
                      commentController: _courierCommentController,
                      hintText: localizations.writeReview,
                      imageUrl: null,
                      isReadOnly: _isCourierAlreadyRated,
                      isApproved: _isCourierApproved,
                    ),

                  // Vendor Rating
                  _buildRatingSection(
                    title: widget.orderDetail.vendorName,
                    rating: _vendorRating,
                    onRatingUpdate: (val) =>
                        setState(() => _vendorRating = val),
                    commentController: _vendorCommentController,
                    hintText: localizations.writeReview,
                    imageUrl: widget.orderDetail.vendorImageUrl,
                    isCircleImage: true,
                    isReadOnly: _isVendorAlreadyReviewed,
                    isApproved: _isVendorApproved,
                  ),

                  // Products Rating
                  ...widget.orderDetail.items
                      .where((item) => !item.isCancelled)
                      .map((item) {
                        final isProductReviewed = _alreadyReviewedProductIds
                            .contains(item.productId);
                        return _buildRatingSection(
                          title: item.productName,
                          rating: _productRatings[item.productId] ?? 5,
                          onRatingUpdate: (val) => setState(
                            () => _productRatings[item.productId] = val,
                          ),
                          commentController: _productComments[item.productId],
                          hintText: localizations.writeReview,
                          imageUrl: item.productImageUrl,
                          isCircleImage: false,
                          isReadOnly: isProductReviewed,
                          isApproved:
                              _productApprovalStatuses[item.productId] ?? true,
                        );
                      }),
                ],
              ),
            ),
          ),
          if (!_isVendorAlreadyReviewed ||
              (_isCourierAlreadyRated == false &&
                  widget.orderDetail.activeOrderCourier != null))
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitFeedback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryOrange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            localizations.submit,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
