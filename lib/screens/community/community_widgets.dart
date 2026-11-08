import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../data/community_repository.dart';
import '../../models/sighting.dart';
import '../../widgets/eco_spinner.dart';

const municipalPrecision =
    'Localização aproximada: referência do município, nunca o local exato do avistamento. Não armazenamos GPS.';

class CommunityPhoto extends StatefulWidget {
  final CommunityRepository repository;
  final String path;
  final double height;
  final BoxFit fit;
  const CommunityPhoto({
    super.key,
    required this.repository,
    required this.path,
    this.height = 200,
    this.fit = BoxFit.contain,
  });
  @override
  State<CommunityPhoto> createState() => _CommunityPhotoState();
}

class _CommunityPhotoState extends State<CommunityPhoto> {
  late Future<Uint8List> _future;
  @override
  void initState() {
    super.initState();
    _future = widget.repository.photo(widget.path);
  }

  @override
  void didUpdateWidget(covariant CommunityPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _future = widget.repository.photo(widget.path);
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: widget.height,
    width: double.infinity,
    child: FutureBuilder<Uint8List>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: TextButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar carregar foto novamente'),
              onPressed: () => setState(() {
                _future = widget.repository.photo(widget.path);
              }),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: EcoSpinner());
        }
        return Image.memory(
          snapshot.data!,
          fit: widget.fit,
          semanticLabel:
              'Foto publicada pela comunidade; identificação não verificada',
          errorBuilder: (_, _, _) =>
              const Center(child: Text('Foto indisponível')),
        );
      },
    ),
  );
}

Future<Municipality?> chooseMunicipality(
  BuildContext context,
  List<Municipality> municipalities,
) => showModalBottomSheet<Municipality>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _MunicipalityPicker(municipalities),
);

class _MunicipalityPicker extends StatefulWidget {
  final List<Municipality> municipalities;
  const _MunicipalityPicker(this.municipalities);
  @override
  State<_MunicipalityPicker> createState() => _MunicipalityPickerState();
}

class _MunicipalityPickerState extends State<_MunicipalityPicker> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final items = widget.municipalities
        .where((e) => e.label.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .85,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Buscar município de São Paulo',
                ),
                onChanged: (value) => setState(() {
                  query = value;
                }),
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text('Nenhum município encontrado.'))
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) => ListTile(
                        title: Text(items[index].label),
                        onTap: () => Navigator.pop(context, items[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
