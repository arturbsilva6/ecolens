import 'package:flutter/material.dart';

import '../data/offline_catalog_store.dart';

/// Foto de uma espécie: usa o arquivo do pacote offline quando ele já foi
/// baixado e, caso contrário, carrega pela internet.
class SpeciesPhoto extends StatelessWidget {
  final String url;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final String? semanticLabel;
  final ImageLoadingBuilder? loadingBuilder;
  final ImageErrorWidgetBuilder? errorBuilder;
  final OfflineCatalogStore? store;

  const SpeciesPhoto(
    this.url, {
    super.key,
    this.fit,
    this.width,
    this.height,
    this.semanticLabel,
    this.loadingBuilder,
    this.errorBuilder,
    this.store,
  });

  @override
  Widget build(BuildContext context) {
    final file = (store ?? OfflineCatalogStore.instance).cachedPhoto(url);
    if (file != null) {
      return Image.file(
        file,
        fit: fit,
        width: width,
        height: height,
        semanticLabel: semanticLabel,
        errorBuilder: errorBuilder,
      );
    }
    return Image.network(
      url,
      fit: fit,
      width: width,
      height: height,
      semanticLabel: semanticLabel,
      loadingBuilder: loadingBuilder,
      errorBuilder: errorBuilder,
    );
  }
}
