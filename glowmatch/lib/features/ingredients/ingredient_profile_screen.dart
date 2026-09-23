import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../logic/personalization.dart';
import '../../providers/providers.dart';
import '../../theme.dart';
import '../../widgets/evidence_labels.dart';

class IngredientProfileScreen extends ConsumerWidget {
  const IngredientProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signalsAsync = ref.watch(ingredientProfileProvider);
    final namesAsync = ref.watch(profileIngredientNamesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your ingredient profile'),
        actions: [
          IconButton(
            tooltip: 'Add a known allergy',
            icon: const Icon(Icons.add),
            onPressed: () => _addAllergy(context, ref),
          ),
        ],
      ),
      body: signalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: Colors.redAccent))),
        data: (signals) {
          final names = namesAsync.valueOrNull ?? const {};
          final triggers = signals
              .where((s) => s.state == TriggerState.likelyTrigger)
              .toList();
          final watch =
              signals.where((s) => s.state == TriggerState.watch).toList();
          final tolerated =
              signals.where((s) => s.state == TriggerState.tolerated).toList();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'This is what your logs suggest about how specific ingredients suit you. not generic labels. It gets sharper the more you log.',
                style: TextStyle(color: AppPalette.textMuted, height: 1.5),
              ),
              const SizedBox(height: 20),
              if (signals.isEmpty)
                const DataNote(
                  icon: Icons.science_outlined,
                  text:
                      'Nothing here yet. As you log how products work for you. especially any reactions. we\'ll start spotting ingredient patterns and explain our reasoning here.',
                ),
              if (triggers.isNotEmpty) ...[
                const _GroupHeader('Likely personal triggers',
                    color: Color(0xFF9A6A50)),
                for (final s in triggers)
                  _SignalTile(
                      signal: s, ingredient: names[s.ingredientId], ref: ref),
                const SizedBox(height: 20),
              ],
              if (watch.isNotEmpty) ...[
                const _GroupHeader('Watching quietly',
                    color: AppPalette.textMuted),
                for (final s in watch)
                  _SignalTile(
                      signal: s, ingredient: names[s.ingredientId], ref: ref),
                const SizedBox(height: 20),
              ],
              if (tolerated.isNotEmpty) ...[
                const _GroupHeader('Seem fine for you',
                    color: Color(0xFF4E6B4A)),
                for (final s in tolerated)
                  _SignalTile(
                      signal: s, ingredient: names[s.ingredientId], ref: ref),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _addAllergy(BuildContext context, WidgetRef ref) async {
    final picked = await showModalBottomSheet<Ingredient>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppPalette.warmWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _IngredientPickerSheet(),
    );
    if (picked == null) return;
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    await ref.read(ingredientProfileRepositoryProvider).setFlag(
          userId: uid,
          ingredientId: picked.id,
          flag: 'trigger',
          note: 'known allergy',
        );
    ref.invalidate(ingredientProfileProvider);
    ref.invalidate(profileIngredientNamesProvider);
  }
}

class _SignalTile extends StatelessWidget {
  final IngredientSignal signal;
  final Ingredient? ingredient;
  final WidgetRef ref;
  const _SignalTile(
      {required this.signal, required this.ingredient, required this.ref});

  Future<void> _flag(String flag) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    final repo = ref.read(ingredientProfileRepositoryProvider);
    if (flag == 'clear') {
      await repo.clearFlag(userId: uid, ingredientId: signal.ingredientId);
    } else {
      await repo.setFlag(
          userId: uid, ingredientId: signal.ingredientId, flag: flag);
    }
    ref.invalidate(ingredientProfileProvider);
    ref.invalidate(profileIngredientNamesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final name = ingredient?.displayName ?? 'Ingredient';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              if (signal.state == TriggerState.likelyTrigger && !signal.userSet)
                Text('~${(signal.confidence * 100).round()}% sure',
                    style: const TextStyle(
                        fontSize: 11.5, color: AppPalette.textMuted)),
              if (signal.userSet)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: AppPalette.beige,
                      borderRadius: BorderRadius.circular(999)),
                  child: const Text('you set this',
                      style: TextStyle(
                          fontSize: 10.5,
                          color: AppPalette.textMuted,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(signal.reasoning,
              style: const TextStyle(
                  fontSize: 12.5, height: 1.45, color: AppPalette.text)),
          // Actions: only for engine-suggested triggers/watch, not user-set.
          if (!signal.userSet && signal.state != TriggerState.tolerated) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 8, children: [
              OutlinedButton(
                onPressed: () => _flag('trigger'),
                style: _btn,
                child: const Text('Rings true'),
              ),
              OutlinedButton(
                onPressed: () => _flag('dismissed'),
                style: _btn,
                child: const Text('Not a trigger for me'),
              ),
            ]),
          ],
          if (signal.userSet) ...[
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => _flag('clear'),
              style: _btn,
              child: const Text('Remove'),
            ),
          ],
        ],
      ),
    );
  }

  static final _btn = OutlinedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    foregroundColor: AppPalette.roseDeep,
    side: const BorderSide(color: AppPalette.stroke),
    textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
  );
}

class _GroupHeader extends StatelessWidget {
  final String text;
  final Color color;
  const _GroupHeader(this.text, {required this.color});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(text,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ]),
      );
}

/// Search-to-pick ingredient sheet for adding a known allergy.
class _IngredientPickerSheet extends ConsumerStatefulWidget {
  const _IngredientPickerSheet();
  @override
  ConsumerState<_IngredientPickerSheet> createState() =>
      _IngredientPickerSheetState();
}

class _IngredientPickerSheetState
    extends ConsumerState<_IngredientPickerSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(ingredientListProvider(_query));
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add a known allergy or trigger',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search ingredients…',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 300),
                    () => setState(() => _query = v));
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Text('$e', style: const TextStyle(color: Colors.redAccent)),
                data: (list) => ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(list[i].displayName),
                    subtitle: list[i].whatItDoes != null
                        ? Text(list[i].whatItDoes!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12))
                        : null,
                    trailing: const Icon(Icons.add_circle_outline,
                        color: AppPalette.rose),
                    onTap: () => Navigator.pop(context, list[i]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
