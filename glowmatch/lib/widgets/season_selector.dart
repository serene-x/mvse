import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import 'shade_dropdown.dart';

const browseSeasons = ['Spring', 'Summer', 'Fall', 'Winter'];

// A browsing filter only: never persisted or used to update a colour profile.
final browseSeasonProvider = StateProvider<String?>((ref) {
  ref.watch(currentUserIdProvider);
  return null;
});

class SeasonSelector extends ConsumerWidget {
  const SeasonSelector({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
              child: ShadeDropdown(
                  label: 'Choose a season',
                  value: ref.watch(browseSeasonProvider),
                  shades: browseSeasons,
                  onChanged: (value) =>
                      ref.read(browseSeasonProvider.notifier).state = value)),
          if (ref.watch(browseSeasonProvider) != null)
            IconButton(
                tooltip: 'Clear season',
                onPressed: () =>
                    ref.read(browseSeasonProvider.notifier).state = null,
                icon: const Icon(Icons.close, size: 18)),
        ],
      );
}
