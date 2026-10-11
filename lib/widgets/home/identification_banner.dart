import 'package:flutter/material.dart';

class IdentificationBanner extends StatelessWidget {
  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;

  const IdentificationBanner({
    super.key,
    required this.onCameraTap,
    required this.onGalleryTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textoAmpliado = MediaQuery.textScalerOf(context).scale(1) > 1.3;

        final botoesVerticais = constraints.maxWidth < 340 || textoAmpliado;

        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Fotografia de fundo
              Positioned.fill(
                child: Image.asset(
                  'assets/images/sagui_banner.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  excludeFromSemantics: true,
                ),
              ),

              // Gradiente para melhorar a leitura
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xF20B3022),
                        Color(0xDB0B3022),
                        Color(0x660B3022),
                      ],
                    ),
                  ),
                ),
              ),

              // Conteúdo do banner
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.eco_outlined,
                      color: Color(0xFFB8E5A2),
                      size: 28,
                    ),

                    const SizedBox(height: 14),

                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 270),
                      child: Text(
                        'Identifique fauna e flora com segurança',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                          height: 1.15,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      'Conhecimento hoje para um amanhã mais seguro.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 55),

                    // Botões responsivos
                    if (botoesVerticais)
                      Column(
                        children: [
                          _botao(
                            Icons.camera_alt_outlined,
                            'Abrir câmera',
                            onCameraTap,
                            true,
                          ),
                          const SizedBox(height: 12),
                          _botao(
                            Icons.photo_library_outlined,
                            'Enviar foto',
                            onGalleryTap,
                            false,
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: _botao(
                              Icons.camera_alt_outlined,
                              'Abrir câmera',
                              onCameraTap,
                              true,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _botao(
                              Icons.photo_library_outlined,
                              'Enviar foto',
                              onGalleryTap,
                              false,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _botao(
    IconData icone,
    String titulo,
    VoidCallback acao,
    bool principal,
  ) {
    final corTexto = principal ? Colors.white : const Color(0xFF174B35);

    return Material(
      color: principal ? const Color(0xE612503A) : const Color(0xF2FFFFFF),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: acao,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: principal ? Colors.white70 : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icone, color: corTexto, size: 24),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  titulo,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    color: corTexto,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
