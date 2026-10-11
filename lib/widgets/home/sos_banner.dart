
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFFD9292F),
                child: Icon(
                  Icons.shield_outlined,
                  color: Colors.white,
                  size: 27,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  'Encontrou um animal em risco?',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? const Color(0xFFFFDADB)
                        : const Color(0xFF731C20),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              FilledButton.icon(
                onPressed: onSosTap,
                icon: const Icon(
                  Icons.phone,
                  size: 18,
                ),
                label: const Text('SOS'),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      const Color(0xFFD9292F),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(88, 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            'Acesse orientações de resgate e contatos de órgãos competentes.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: isDark
                  ? const Color(0xFFF0BEC1)
                  : const Color(0xFF805052),
            ),
          ),
        ],
      ),
    );
  }
}
