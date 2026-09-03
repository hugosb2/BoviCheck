import 'package:flutter/material.dart';

class TituloSecao extends StatelessWidget {
  final String text;
  const TituloSecao(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(text.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Theme.of(context).colorScheme.primary)),
    );
  }
}
