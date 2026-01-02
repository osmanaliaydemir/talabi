import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/reviews/data/models/review.dart';
import 'package:mobile/features/home/presentation/widgets/shared_header.dart';
import 'package:mobile/services/api_service.dart';
import 'package:intl/intl.dart';

class UserReviewDetailScreen extends StatefulWidget {
  const UserReviewDetailScreen({super.key, this.review, this.reviewId});

  final Review? review;
  final String? reviewId;

  @override
  State<UserReviewDetailScreen> createState() => _UserReviewDetailScreenState();
}

class _UserReviewDetailScreenState extends State<UserReviewDetailScreen> {
  Review? _review;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _review = widget.review;
    if (_review == null && widget.reviewId != null) {
      _loadReview();
    }
  }

  Future<void> _loadReview() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = ApiService(); // Or get from provider/locator
      final review = await apiService.getReviewById(widget.reviewId!);
      if (mounted) {
        setState(() {
          _review = review;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _review == null
        ? _buildLoadingOrError(context)
        : _buildContent(context, _review!);
  }

  Widget _buildLoadingOrError(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SharedHeader(
            title: l10n.reviewDetail,
            showBackButton: true,
            showSearch: false,
            showNotifications: true,
            showCart: true,
          ),
          Expanded(
            child: Center(
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : _error != null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _error!.replaceAll('Exception: ', ''),
                        ), // Simple error cleanup
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadReview,
                          child: Text(l10n.retry),
                        ),
                      ],
                    )
                  : const SizedBox(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, Review review) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat.yMMMMd(
      Localizations.localeOf(context).languageCode,
    );
    final timeFormat = DateFormat.Hm(
      Localizations.localeOf(context).languageCode,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SharedHeader(
            title: l10n.reviewDetail,
            showBackButton: true,
            showSearch: false,
            showNotifications: true,
            showCart: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rating and Date Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildRatingBadge(review.rating),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            dateFormat.format(review.createdAt),
                            style: AppTheme.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            timeFormat.format(review.createdAt),
                            style: AppTheme.poppins(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Entity Info (Product/Vendor)
                  Text(
                    l10n.vendors, // Using vendors as a general label for now
                    style: AppTheme.poppins(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    review.vendorName ?? l10n.reviewDetail,
                    style: AppTheme.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Approval Status
                  Text(
                    l10n.status,
                    style: AppTheme.poppins(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStatusBadge(review.isApproved, l10n),
                  const SizedBox(height: 32),

                  // Comment Section
                  Text(
                    l10n.comment,
                    style: AppTheme.poppins(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF3F4F6)),
                    ),
                    child: Text(
                      review.comment.isNotEmpty
                          ? review.comment
                          : l10n.noComment,
                      style: AppTheme.poppins(
                        fontSize: 16,
                        height: 1.6,
                        color: const Color(0xFF374151),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBadge(int rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primaryOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: AppTheme.primaryOrange, size: 24),
          const SizedBox(width: 8),
          Text(
            rating.toString(),
            style: AppTheme.poppins(
              color: AppTheme.primaryOrange,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '/ 5',
            style: AppTheme.poppins(
              color: AppTheme.primaryOrange.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isApproved, AppLocalizations l10n) {
    final color = isApproved ? Colors.green : Colors.orange;
    final icon = isApproved ? Icons.check_circle : Icons.access_time;
    final text = isApproved ? l10n.approved : l10n.pendingApproval;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(
            text,
            style: AppTheme.poppins(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
