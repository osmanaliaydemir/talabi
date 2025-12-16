import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/l10n/app_localizations.dart';
import '../providers/auth_provider.dart';

class PendingApprovalWidget extends StatelessWidget {
  const PendingApprovalWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.hourglass_top_rounded,
                  size: 64,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                localizations.accountPendingApprovalTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                localizations.accountPendingApprovalMessage,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: colorScheme.error),
                    foregroundColor: colorScheme.error,
                  ),
                  onPressed: () async {
                    final authProvider = context.read<AuthProvider>();
                    final role = await authProvider.logout();

                    if (context.mounted) {
                      String targetRoute = '/login';
                      if (role == 'Vendor') {
                        targetRoute = '/vendor/login';
                      } else if (role == 'Courier') {
                        targetRoute = '/courier/login';
                      }

                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil(targetRoute, (route) => false);
                    }
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(localizations.logout),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
