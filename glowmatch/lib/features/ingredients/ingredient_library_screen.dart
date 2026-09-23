import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../theme.dart';
import '../../widgets/evidence_labels.dart';

class IngredientLibraryScreen extends ConsumerStatefulWidget {
  const IngredientLibraryScreen({super.key});
  @override
  ConsumerState<IngredientLibraryScreen> createState() =>
      _IngredientLibraryScreenState();
}

class _IngredientLibraryScreenState
    extends ConsumerState<IngredientLibraryScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(ingredientListProvider(_query));

    return Scaffold(
      appBar: AppBar(title: const Text('Ingredients')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _controller,
              onChanged: _onChanged,
              decoration: const InputDecoration(
                hintText: 'Search by name. e.g. niacinamide, retinol…',
                prefixIcon: Icon(Icons.search, color: AppPalette.textMuted),
              ),
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Couldn\'t load ingredients: $e',
                    style: const TextStyle(color: Colors.redAccent)),
              ),
              data: (ingredients) => ingredients.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No ingredients match that yet.',
                            style: TextStyle(color: AppPalette.textMuted)),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: ingredients.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) =>
                          _IngredientCard(ingredient: ingredients[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientCard extends StatelessWidget {
  final Ingredient ingredient;
  const _IngredientCard({required this.ingredient});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push('/ingredient/${ingredient.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(ingredient.displayName,
                        style: const TextStyle(
                            fontSize: 15.5, fontWeight: FontWeight.w600)),
                  ),
                  if (ingredient.evidenceLevel != null)
                    EvidenceChip(level: ingredient.evidenceLevel!),
                ],
              ),
              if (ingredient.whatItDoes != null) ...[
                const SizedBox(height: 5),
                Text(ingredient.whatItDoes!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: AppPalette.textMuted)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
