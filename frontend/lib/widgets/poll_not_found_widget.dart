import 'package:flutter/material.dart';
import 'package:pollino/core/localization/i18n_service.dart';
import 'package:routemaster/routemaster.dart';

/// Friendly empty state shown when a poll is not found or has been deleted.
class PollNotFoundWidget extends StatelessWidget {
  const PollNotFoundWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 40.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 56,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              I18nService.instance.translate('poll.notFound.title'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              I18nService.instance.translate('poll.notFound.message'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // Default behaviour: go back to previous screen
                    Navigator.of(context).maybePop();
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: Text(I18nService.instance.translate('poll.notFound.back')),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {
                    // Use Routemaster for app routing so navigation works with the app shell
                    try {
                      Routemaster.of(context).push('/');
                    } catch (_) {
                      // Fallback to Navigator if Routemaster not available in this context
                      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                    }
                  },
                  child: Text(I18nService.instance.translate('poll.notFound.home')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
