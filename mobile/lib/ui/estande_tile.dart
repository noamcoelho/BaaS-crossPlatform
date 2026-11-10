import 'package:flutter/material.dart';

import '../domain/estande.dart';

class EstandeTile extends StatelessWidget {
  const EstandeTile({super.key, required this.estande, this.destaque = false});

  final Estande estande;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Card(
      elevation: destaque ? 3 : 0,
      color: destaque ? cores.tertiaryContainer : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: destaque ? cores.tertiary : cores.outlineVariant,
          width: destaque ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    estande.nome,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (destaque)
                  Chip(
                    avatar: const Icon(Icons.star, size: 16),
                    label: const Text('Missão'),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: cores.tertiary,
                    labelStyle: TextStyle(color: cores.onTertiary),
                    iconTheme: IconThemeData(color: cores.onTertiary),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(estande.descricao),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.place, size: 16, color: cores.primary),
                const SizedBox(width: 4),
                Expanded(child: Text(estande.localizacao)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
