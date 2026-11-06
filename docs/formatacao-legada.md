# Pendências de formatação legada — EcoLens

Auditoria separada da revisão de formatação do PR #11, na branch `feat/uiux-home-conceito2`, com Dart **3.13.5**.

A verificação inicial de `lib` e `test` identificou **41 arquivos** fora do padrão: sete pertencem ao redesign e foram formatados; os **34 arquivos abaixo** são legados e não foram alterados nesta revisão.

```bash
dart format --output=none --set-exit-if-changed lib test
```

Após a correção dos sete arquivos do redesign, esse comando ainda retorna **código 1**, com 34 apontamentos. Isso é uma pendência conhecida da auditoria global, não uma falha omitida da validação do PR. `flutter analyze` e a suíte completa (`flutter test`, 169 testes aprovados) continuam sendo executados para todo o projeto.

## Arquivos pendentes

- `lib/controllers/home_controller.dart`
- `lib/controllers/species_controller.dart`
- `lib/data/identification_history_repository.dart`
- `lib/data/mock_species_repository.dart`
- `lib/data/supabase_species_repository.dart`
- `lib/models/ai_identification_result.dart`
- `lib/models/post_model.dart`
- `lib/models/species_model.dart`
- `lib/screens/auth/login_screen.dart, register_screen.dart`
- `lib/screens/community/community_screen.dart`
- `lib/screens/emergency/emergency_screen.dart`
- `lib/screens/identification/identification_history_screen.dart`
- `lib/screens/identification/identification_result_screen.dart`
- `lib/screens/identification/identification_screen.dart`
- `lib/screens/map/heat_map_screen.dart`
- `lib/screens/settings/appearance_screen.dart`
- `lib/screens/settings/settings_screen.dart`
- `lib/screens/sos/sos_screen.dart`
- `lib/screens/species/species_catalog_screen.dart`
- `lib/screens/species/species_detail_screen.dart`
- `lib/services/ai_service.dart`
- `lib/services/api_service.dart`
- `lib/services/camera_service.dart`
- `lib/utils/ai_species_matcher.dart`
- `lib/utils/species_catalog_filter.dart`
- `lib/widgets/home/bottom_nav_bar.dart`
- `lib/widgets/home/sos_banner.dart`
- `lib/widgets/species_card.dart`
- `test/ai_identification_test.dart`
- `test/ai_species_matcher_test.dart`
- `test/identification_history_repository_test.dart`
- `test/identification_history_save_test.dart`
- `test/identification_history_screen_test.dart`
- `test/identification_result_screen_test.dart`

## Tratamento futuro

- Resolver a formatação em uma revisão própria, com diff exclusivamente mecânico e validação completa.
- Manter o escopo de cada PR: qualquer arquivo legado modificado passa a ser verificado pelo job de formatação desse PR.
- Não tratar o job de formatação do PR como prova de que todo o repositório já está formatado.
- Parte dos apontamentos está em arquivos vazios de estrutura inicial; a lista não indica funcionalidades novas nem autoriza sua implementação.
