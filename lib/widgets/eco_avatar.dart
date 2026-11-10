import 'package:flutter/material.dart';

/// Avatares do próprio app (sem foto), para o perfil público.
/// As chaves são as mesmas aceitas pela tabela public_profiles.
class EcoAvatars {
  static const options = <String, (IconData, Color, String)>{
    'pegada': (Icons.pets, Color(0xFFB45309), 'Pegada'),
    'coelho': (Icons.cruelty_free, Color(0xFF6D4C41), 'Coelho'),
    'borboleta': (Icons.emoji_nature, Color(0xFF8E24AA), 'Borboleta'),
    'abelha': (Icons.hive_outlined, Color(0xFFF9A825), 'Abelha'),
    'peixe': (Icons.set_meal_outlined, Color(0xFF00838F), 'Peixe'),
    'flor': (Icons.local_florist, Color(0xFFD81B60), 'Flor'),
    'arvore': (Icons.park, Color(0xFF2E7D32), 'Árvore'),
    'folha': (Icons.eco, Color(0xFF7CB342), 'Folha'),
    'lotus': (Icons.spa, Color(0xFFEC407A), 'Lótus'),
    'grama': (Icons.grass, Color(0xFF558B2F), 'Mato'),
    'montanha': (Icons.landscape, Color(0xFF546E7A), 'Montanha'),
    'sol': (Icons.wb_sunny_outlined, Color(0xFFFB8C00), 'Sol'),
  };

  static bool isValid(String? key) => options.containsKey(key);
}

class EcoAvatar extends StatelessWidget {
  final String? avatar;
  final double radius;

  const EcoAvatar({super.key, required this.avatar, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    final option = EcoAvatars.options[avatar];
    final colors = Theme.of(context).colorScheme;
    final color = option?.$2 ?? colors.primary;
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: .18),
      child: Icon(
        option?.$1 ?? Icons.person,
        size: radius * 1.1,
        color: color,
        semanticLabel: option == null ? 'Sem avatar' : 'Avatar ${option.$3}',
      ),
    );
  }
}
