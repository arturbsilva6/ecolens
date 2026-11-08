import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/supabase_species_repository.dart';
import '../../models/species_model.dart';
import '../../models/species_status_style.dart';
import '../species_photo.dart';

/// Carrossel "Cuidado na região": espécies perigosas e de cautela do
/// catálogo, com foto. Avança sozinho, para quando a pessoa interage e
/// respeita a opção do Android de remover animações.
class RegionAlertCarousel extends StatefulWidget {
  final Future<List<SpeciesModel>> Function()? fetchPublishedSpecies;
  final ValueChanged<SpeciesModel> onSpeciesTap;
  final VoidCallback onViewAllTap;
  final Duration interval;

  const RegionAlertCarousel({
    super.key,
    this.fetchPublishedSpecies,
    required this.onSpeciesTap,
    required this.onViewAllTap,
    this.interval = const Duration(seconds: 5),
  });

  /// Até 8 espécies com foto: primeiro as perigosas, depois as de cautela.
  static List<SpeciesModel> pick(List<SpeciesModel> species) {
    int rank(SpeciesModel s) => s.status == SpeciesStatus.danger ? 0 : 1;
    final alerts =
        species
            .where(
              (s) =>
                  s.imageUrl != null &&
                  (s.status == SpeciesStatus.danger ||
                      s.status == SpeciesStatus.caution),
            )
            .toList()
          ..sort((a, b) {
            final byRank = rank(a).compareTo(rank(b));
            return byRank != 0 ? byRank : a.commonName.compareTo(b.commonName);
          });
    return alerts.take(8).toList(growable: false);
  }

  @override
  State<RegionAlertCarousel> createState() => _RegionAlertCarouselState();
}

class _RegionAlertCarouselState extends State<RegionAlertCarousel> {
  final _controller = PageController(viewportFraction: .88);
  late final Future<List<SpeciesModel>> _future;
  Timer? _timer;
  int _page = 0, _count = 0;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<SpeciesModel>> _load() async {
    try {
      final all = await (widget.fetchPublishedSpecies ??
          SupabaseSpeciesRepository().fetchPublishedSpecies)();
      return RegionAlertCarousel.pick(all);
    } catch (_) {
      // Sem catálogo, a seção simplesmente não aparece.
      return const [];
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _restartTimer() {
    _timer?.cancel();
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion || _count < 2) return;
    _timer = Timer.periodic(widget.interval, (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_page + 1) % _count;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<SpeciesModel>>(
      future: _future,
      builder: (context, snapshot) {
        final species = snapshot.data ?? const <SpeciesModel>[];
        if (species.isEmpty) return const SizedBox.shrink();
        if (_count != species.length) {
          _count = species.length;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _restartTimer();
          });
        }
        final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
        final height = 168 + 86 * scale;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Cuidado na região',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: widget.onViewAllTap,
                  child: const Text('Ver todas'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: height,
              child: Listener(
                // Toque ou arraste pausa o avanço automático por um ciclo.
                onPointerDown: (_) => _restartTimer(),
                child: PageView.builder(
                  controller: _controller,
                  padEnds: false,
                  itemCount: species.length,
                  onPageChanged: (page) => setState(() => _page = page),
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _AlertCard(
                      species: species[index],
                      onTap: () => widget.onSpeciesTap(species[index]),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Semantics(
                label: 'Espécie ${_page + 1} de ${species.length}',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < species.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _page ? 18 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: i == _page
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AlertCard extends StatelessWidget {
  final SpeciesModel species;
  final VoidCallback onTap;

  const _AlertCard({required this.species, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final status = species.status;
    Widget placeholder() => Container(
      color: colors.primaryContainer,
      alignment: Alignment.center,
      child: Icon(Icons.eco_outlined, size: 44, color: colors.primary),
    );
    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  SpeciesPhoto(
                    species.imageUrl!,
                    fit: BoxFit.cover,
                    semanticLabel: 'Foto de ${species.commonName}',
                    loadingBuilder: (context, child, progress) =>
                        progress == null ? child : placeholder(),
                    errorBuilder: (_, _, _) => placeholder(),
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: status.color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(status.icon, size: 16, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            status.shortLabel,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          species.commonName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          species.scientificName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
