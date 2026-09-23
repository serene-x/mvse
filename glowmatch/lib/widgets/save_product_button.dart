import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/catalog.dart';
import '../data/models/models.dart';
import '../providers/saved_products.dart';

class SaveProductButton extends ConsumerStatefulWidget {
  final Product product;
  const SaveProductButton({super.key, required this.product});
  @override
  ConsumerState<SaveProductButton> createState() => _SaveProductButtonState();
}

class _SaveProductButtonState extends ConsumerState<SaveProductButton> {
  bool _busy = false;
  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(savedProductsProvider);
    final selected =
        saved.valueOrNull?.contains(BundledCatalog.key(widget.product)) ??
            false;
    return IconButton(
      tooltip: selected ? 'Remove from your shelf' : 'Save to your shelf',
      isSelected: selected,
      icon: Icon(selected ? Icons.bookmark : Icons.bookmark_border, size: 22),
      onPressed: _busy || saved.isLoading
          ? null
          : () async {
              if (ref.read(currentUserIdProvider) == null) {
                context.push('/auth/sign-in');
                return;
              }
              setState(() => _busy = true);
              try {
                await ref
                    .read(savedProductsProvider.notifier)
                    .toggle(widget.product);
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Couldn’t save to your account. Please try again.')),
                  );
                }
              } finally {
                if (mounted) setState(() => _busy = false);
              }
            },
    );
  }
}
