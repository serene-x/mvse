import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme.dart';

class BuyButtons extends StatelessWidget {
  final String? sephoraUrl;
  final String? ultaUrl;
  const BuyButtons({super.key, this.sephoraUrl, this.ultaUrl});

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    if (sephoraUrl != null && sephoraUrl!.isNotEmpty) {
      children.add(Expanded(child: _BuyButton(label: 'Sephora', onTap: () => _open(sephoraUrl!))));
    }
    if (ultaUrl != null && ultaUrl!.isNotEmpty) {
      if (children.isNotEmpty) children.add(const SizedBox(width: 10));
      children.add(Expanded(child: _BuyButton(label: 'Ulta', onTap: () => _open(ultaUrl!), tone: ButtonTone.outline)));
    }
    if (children.isEmpty) return const SizedBox.shrink();
    return Row(children: children);
  }
}

enum ButtonTone { filled, outline }

class _BuyButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final ButtonTone tone;
  const _BuyButton({required this.label, required this.onTap, this.tone = ButtonTone.filled});

  @override
  Widget build(BuildContext context) {
    if (tone == ButtonTone.outline) {
      return OutlinedButton(onPressed: onTap, child: Text('Buy at $label'));
    }
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppPalette.text,
      ),
      child: Text('Buy at $label'),
    );
  }
}
