import 'package:flutter/material.dart';
import 'package:url_launcher/link.dart';
import 'package:url_launcher/url_launcher.dart';

/// Real web links preserve browser navigation, keyboard access and popup rules.
class SourceLink extends StatelessWidget {
  final String url, label;
  const SourceLink({super.key, required this.url, required this.label});
  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return const SizedBox.shrink();
    }
    return Link(
        uri: uri,
        target: LinkTarget.self,
        builder: (context, follow) => TextButton.icon(
            onPressed: () async {
              try {
                final opened = await launchUrl(uri,
                    mode: LaunchMode.externalApplication,
                    webOnlyWindowName: '_self');
                if (!opened) throw StateError('Link unavailable');
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content:
                          Text('Could not open the link. Please try again.')));
                }
              }
            },
            label: Text(label),
            icon: const Icon(Icons.north_east, size: 15),
            iconAlignment: IconAlignment.end));
  }
}

class BuyButtons extends StatelessWidget {
  final String? sephoraUrl, ultaUrl, brandUrl;
  final String? searchTerm;
  const BuyButtons(
      {super.key,
      this.sephoraUrl,
      this.ultaUrl,
      this.brandUrl,
      this.searchTerm});
  @override
  Widget build(BuildContext context) =>
      Wrap(spacing: 12, runSpacing: 8, children: [
        if (brandUrl?.isNotEmpty ?? false)
          SourceLink(url: brandUrl!, label: 'View at the brand'),
        if (sephoraUrl?.isNotEmpty ?? false)
          SourceLink(url: sephoraUrl!, label: 'View at Sephora')
        else if (searchTerm?.isNotEmpty ?? false)
          SourceLink(
              url: Uri.https(
                      'www.sephora.com', '/search', {'keyword': searchTerm!})
                  .toString(),
              label: 'Search Sephora'),
        if (ultaUrl?.isNotEmpty ?? false)
          SourceLink(url: ultaUrl!, label: 'View at Ulta'),
      ]);
}
