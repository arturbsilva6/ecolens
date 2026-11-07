import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'data/offline_catalog_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Prepara o catálogo salvo no aparelho sem atrasar a primeira tela.
  unawaited(OfflineCatalogStore.instance.init());
  // A Home e o SOS não dependem da inicialização dos serviços online.
  runApp(const EcoLensApp());
}
