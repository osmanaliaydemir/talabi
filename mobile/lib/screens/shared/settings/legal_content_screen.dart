import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/widgets/common/connectivity_banner.dart';
import 'package:mobile/screens/customer/widgets/shared_header.dart';

class LegalContentScreen extends StatefulWidget {
  final String documentType;
  final String title;

  const LegalContentScreen({
    super.key,
    required this.documentType,
    required this.title,
  });

  @override
  State<LegalContentScreen> createState() => _LegalContentScreenState();
}

class _LegalContentScreenState extends State<LegalContentScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _content;
  String? _error;
  bool _isFirstLoad = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load content only on first build when context is ready
    if (_isFirstLoad) {
      _isFirstLoad = false;
      _loadContent();
    }
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final locale = Localizations.localeOf(context).languageCode;
      final response = await _apiService.getLegalContent(
        widget.documentType,
        locale,
      );
      setState(() {
        _content = response['content'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey[100],

      body: Column(
        children: [
          // Header
          SharedHeader(
            title: widget.title,
            subtitle: l10n.legalDocuments,
            showBackButton: true,
            action: const SizedBox.shrink(),
          ),
          // Content
          Expanded(
            child: Stack(
              children: [
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.contentNotAvailable,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _loadContent,
                              child: Text(l10n.retry),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Html(data: _content ?? ''),
                        ),
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
}
