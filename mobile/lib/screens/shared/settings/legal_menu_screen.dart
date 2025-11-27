import 'package:flutter/material.dart';
import 'package:mobile/screens/shared/settings/legal_content_screen.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/widgets/connectivity_banner.dart';
import 'package:mobile/widgets/persistent_bottom_nav_bar.dart';

class LegalMenuScreen extends StatelessWidget {
  const LegalMenuScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final legalDocuments = [
      {
        'type': 'terms-of-use',
        'title': l10n.termsOfUse,
        'icon': Icons.description,
      },
      {
        'type': 'privacy-policy',
        'title': l10n.privacyPolicy,
        'icon': Icons.privacy_tip,
      },
      {
        'type': 'refund-policy',
        'title': l10n.refundPolicy,
        'icon': Icons.assignment_return,
      },
      {
        'type': 'distance-sales-agreement',
        'title': l10n.distanceSalesAgreement,
        'icon': Icons.shopping_bag,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      bottomNavigationBar: const PersistentBottomNavBar(),
      body: Column(
        children: [
          // Header
          _buildHeader(context, l10n),
          // Content
          Expanded(
            child: Stack(
              children: [
                ListView.builder(
                  itemCount: legalDocuments.length,
                  itemBuilder: (context, index) {
                    final doc = legalDocuments[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            doc['icon'] as IconData,
                            color: Colors.orange,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          doc['title'] as String,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LegalContentScreen(
                                documentType: doc['type'] as String,
                                title: doc['title'] as String,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ConnectivityBanner(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.shade400,
            Colors.orange.shade600,
            Colors.orange.shade800,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // Back Button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.gavel, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.legalDocuments,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sözleşmeler ve Politikalar',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
