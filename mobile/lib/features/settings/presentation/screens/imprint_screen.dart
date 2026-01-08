import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/home/presentation/widgets/shared_header.dart';
import 'package:mobile/services/api_service.dart';

class ImprintScreen extends StatefulWidget {
  const ImprintScreen({super.key});

  @override
  State<ImprintScreen> createState() => _ImprintScreenState();
}

class _ImprintScreenState extends State<ImprintScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, String> _imprintData = {};

  @override
  void initState() {
    super.initState();
    _loadImprintData();
  }

  Future<void> _loadImprintData() async {
    try {
      // Mock data or fetch from API settings if available
      // In a real app, these would come from ApiService.getSystemSetting(...)
      final title =
          await _apiService.getSystemSetting('CompanyTitle') ??
          'Talabi Teknoloji A.Ş.';
      final mersis =
          await _apiService.getSystemSetting('CompanyMersisNo') ??
          '0123456789012345';
      final email =
          await _apiService.getSystemSetting('CompanyEmail') ??
          'info@talabi.com';
      final phone =
          await _apiService.getSystemSetting('CompanyPhone') ??
          '+90 212 123 45 67';
      final address =
          await _apiService.getSystemSetting('CompanyAddress') ??
          'İstanbul, Türkiye';

      if (mounted) {
        setState(() {
          _imprintData = {
            'title': title,
            'mersis': mersis,
            'email': email,
            'phone': phone,
            'address': address,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          SharedHeader(
            title: l10n.imprint,
            subtitle: l10n.legalDocuments,
            showBackButton: true,
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.spacingMedium),
                    child: Column(
                      children: [
                        _buildInfoCard(
                          context,
                          l10n.companyTitle,
                          _imprintData['title'] ?? '-',
                          Icons.business,
                        ),
                        _buildInfoCard(
                          context,
                          l10n.mersisNo,
                          _imprintData['mersis'] ?? '-',
                          Icons.fingerprint,
                        ),
                        _buildInfoCard(
                          context,
                          l10n.contactEmail,
                          _imprintData['email'] ?? '-',
                          Icons.email_outlined,
                        ),
                        _buildInfoCard(
                          context,
                          l10n.contactPhone,
                          _imprintData['phone'] ?? '-',
                          Icons.phone_outlined,
                        ),
                        _buildInfoCard(
                          context,
                          l10n.officialAddress,
                          _imprintData['address'] ?? '-',
                          Icons.location_on_outlined,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: AppTheme.cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingSmall),
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(icon, color: AppTheme.primaryOrange, size: 20),
          ),
          const SizedBox(width: AppTheme.spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTheme.poppins(
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
