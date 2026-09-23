import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/catalog.dart';
import '../../data/models/models.dart';
import '../../data/beauty_details.dart';
import '../../logic/beauty_book.dart';
import '../../providers/beauty_book.dart';
import '../../providers/providers.dart';
import '../../widgets/shade_dropdown.dart';

Future<void> showWearNote(
    BuildContext context, WidgetRef ref, Product p, BrandShade? shade,
    {WearNote? note}) async {
  if (ref.read(currentUserIdProvider) == null) {
    context.push('/auth/sign-in');
    return;
  }
  final book = await ref.read(beautyBookProvider.future);
  final key = BundledCatalog.key(p);
  final details = await ref.read(beautyDetailsProvider.future);
  final detail = detailsFor(p, details);
  final existing = note ??
      book.notes
          .where((n) => n.productKey == key && n.shade == (shade?.name ?? ''))
          .firstOrNull;
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _NoteEditor(
          product: p, shade: shade, existing: existing, detail: detail));
}

class _NoteEditor extends ConsumerStatefulWidget {
  final Product product;
  final BrandShade? shade;
  final WearNote? existing;
  final BeautyDetails detail;
  const _NoteEditor(
      {required this.product, this.shade, this.existing, required this.detail});
  @override
  ConsumerState<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends ConsumerState<_NoteEditor> {
  late final TextEditingController shade;
  late String fit, reaction, family;
  late int frequency;
  bool get hasShades =>
      !isSkincare(widget.product.category) && widget.detail.shades.isNotEmpty;
  bool saving = false;
  String? error;
  @override
  void initState() {
    super.initState();
    final n = widget.existing;
    shade = TextEditingController(text: n?.shade ?? widget.shade?.name ?? '');
    fit = n?.fit ?? '';
    reaction = n?.reaction ?? '';
    family = n?.family ??
        familyFromDescription(widget.detail.description(shade.text));
    frequency = n?.frequency ?? 1;
  }

  @override
  void dispose() {
    shade.dispose();
    super.dispose();
  }

  Widget field(String label, String value, List<String> values,
          void Function(String) onChange) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: DropdownButtonFormField<String>(
              initialValue: values.contains(value) ? value : '',
              isExpanded: true,
              decoration: InputDecoration(labelText: label),
              items: [
                const DropdownMenuItem(value: '', child: Text('Not recorded')),
                for (final v in values.where((v) => v.isNotEmpty))
                  DropdownMenuItem(value: v, child: Text(v))
              ],
              onChanged: (v) => setState(() => onChange(v ?? ''))));
  @override
  Widget build(BuildContext context) => Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                Text('Your wear notes',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text('${widget.product.brand} / ${widget.product.name}'),
                const SizedBox(height: 20),
                if (hasShades) ...[
                  ShadeDropdown(
                      label: 'Shade name',
                      value: shade.text,
                      shades: {
                        ...widget.detail.shades.map((s) => s.name),
                        if (shade.text.isNotEmpty) shade.text
                      }.toList(),
                      onChanged: (v) => setState(() {
                            shade.text = v ?? '';
                            family = familyFromDescription(
                                widget.detail.description(shade.text));
                          })),
                  const SizedBox(height: 14),
                  field(
                      'How does this shade look on you?',
                      fit,
                      ['Skin match', 'Flattering colour', 'Poor match'],
                      (v) => fit = v),
                ],
                field(
                    'Your skin’s response',
                    reaction,
                    ['Tolerated', 'Breakout', 'Irritation', 'Unsure'],
                    (v) => reaction = v),
                const Text('Tolerated: used repeatedly without a reaction.',
                    style: TextStyle(fontSize: 12, height: 1.5)),
                const SizedBox(height: 14),
                if (hasShades &&
                    ![ProductCategory.foundation, ProductCategory.concealer]
                        .contains(widget.product.category))
                  field('Colour family (check against your shade)', family,
                      paletteFamilies.keys.toList(), (v) => family = v),
                DropdownButtonFormField<int>(
                    initialValue: frequency,
                    decoration: const InputDecoration(
                        labelText: 'How often do you use it?'),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Occasionally')),
                      DropdownMenuItem(value: 2, child: Text('Weekly')),
                      DropdownMenuItem(value: 3, child: Text('Most days'))
                    ],
                    onChanged: (v) => frequency = v ?? 1),
                const SizedBox(height: 14),
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Saved to your account.',
                        style: TextStyle(fontSize: 12, height: 1.5))),
                if (error != null)
                  Text(error!, style: const TextStyle(color: Colors.red)),
                FilledButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (hasShades &&
                                fit.isNotEmpty &&
                                shade.text.trim().isEmpty) {
                              setState(() => error =
                                  'Add the shade name before recording its colour fit.');
                              return;
                            }
                            setState(() {
                              saving = true;
                              error = null;
                            });
                            try {
                              await ref.read(beautyBookProvider.notifier).note(
                                  WearNote(
                                      productKey:
                                          BundledCatalog.key(widget.product),
                                      shade: hasShades ? shade.text.trim() : '',
                                      fit: hasShades ? fit : '',
                                      reaction: reaction,
                                      family: hasShades ? family : '',
                                      frequency: frequency),
                                  replaces: widget.existing);
                              if (context.mounted) Navigator.pop(context);
                            } catch (_) {
                              setState(() {
                                saving = false;
                                error = 'Could not save. Please try again.';
                              });
                            }
                          },
                    child: Text(saving ? 'Saving…' : 'Save wear note')),
              ]))));
}
