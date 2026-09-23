import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Anchored below the field; long ranges scroll within the available space.
class ShadeDropdown extends StatefulWidget {
  final List<String> shades;
  final String? value;
  final String label;
  final ValueChanged<String?> onChanged;
  const ShadeDropdown(
      {super.key,
      required this.shades,
      required this.onChanged,
      this.value,
      this.label = 'Select your shade'});
  @override
  State<ShadeDropdown> createState() => _ShadeDropdownState();
}

class _ShadeDropdownState extends State<ShadeDropdown> {
  final _field = GlobalKey();
  double _menuHeight = 260;
  void _fitBelow() {
    final box = _field.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final media = MediaQuery.of(context);
    final bottom = box.localToGlobal(Offset(0, box.size.height)).dy;
    final available = media.size.height -
        media.viewInsets.bottom -
        media.padding.bottom -
        bottom -
        16;
    final height = math.min(260.0, math.max(48.0, available));
    if (height != _menuHeight) setState(() => _menuHeight = height);
  }

  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: (_) => _fitBelow(),
        child: Focus(
            onFocusChange: (focused) {
              if (focused) _fitBelow();
            },
            child: Semantics(
                label: widget.label,
                child: SizedBox(
                    key: _field,
                    child: DropdownMenu<String>(
                      key: ValueKey(widget.value),
                      initialSelection: widget.shades.contains(widget.value)
                          ? widget.value
                          : null,
                      label: Text(widget.label),
                      expandedInsets: EdgeInsets.zero,
                      menuHeight: _menuHeight,
                      selectOnly: true,
                      requestFocusOnTap: false,
                      menuStyle: const MenuStyle(
                          alignment: AlignmentDirectional.bottomStart,
                          backgroundColor:
                              WidgetStatePropertyAll(Colors.white)),
                      alignmentOffset: const Offset(0, 4),
                      dropdownMenuEntries: [
                        for (final s in widget.shades)
                          DropdownMenuEntry(value: s, label: s)
                      ],
                      onSelected: widget.onChanged,
                    )))),
      );
}
