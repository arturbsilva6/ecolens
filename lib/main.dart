import 'package:flutter/material.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // A Home e o SOS não dependem da inicialização dos serviços online.
  runApp(const EcoLensApp());
}
