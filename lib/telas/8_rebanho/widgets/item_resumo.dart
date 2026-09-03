import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ItemResumo extends StatelessWidget {
  final String label;
  final String valor;
  final IconData? icon;
  final String? svgIcon;
  final bool isUltimo;

  const ItemResumo({super.key, required this.label, required this.valor, this.icon, this.svgIcon, this.isUltimo = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              if (svgIcon != null)
                SvgPicture.asset(
                  svgIcon!,
                  width: 18,
                  height: 18,
                  colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                )
              else if (icon != null)
                Icon(icon, size: 18, color: Colors.grey),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const Spacer(),
              Text(valor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
        if (!isUltimo) Divider(color: Colors.grey.withValues(alpha: 0.1)),
      ],
    );
  }
}
