
import 'package:flutter/material.dart';

class SosBanner extends StatelessWidget {
  final VoidCallback onSosTap;

  const SosBanner({
    super.key,
    required this.onSosTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF3A2227)
            : const Color(0xFFFCE8E8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Ícone de segurança
          const CircleAvatar(
            radius: 25,
            backgroundColor: Color(0xFFD9292F),
            child: Icon(
              Icons.shield_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(width: 12),

          // Informações do SOS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Encontrou um animal em risco?',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? const Color(0xFFFFDADB)
                        : const Color(0xFF731C20),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Acesse orientações de resgate e órgãos competentes.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFFF0BEC1)
                        : const Color(0xFF805052),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Botão SOS
          FilledButton(
            onPressed: onSosTap,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD9292F),
              foregroundColor: Colors.white,
              minimumSize: const Size(64, 48),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'SOS',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
