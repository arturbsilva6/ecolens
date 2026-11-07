
import '../models/species_model.dart';

class MockSpeciesRepository {
  // Catálogo temporário para demonstração.
  // Futuramente será substituído por consultas ao banco de dados.

  static const SpeciesModel jararaca = SpeciesModel(
    commonName: 'Jararaca',
    scientificName: 'Bothrops jararaca',
    imagePath: 'assets/images/jararaca.jpg',
    status: SpeciesStatus.danger,

    description:
        'A jararaca é uma serpente peçonhenta '
        'da família Viperidae, encontrada '
        'principalmente no Sudeste e no Sul do Brasil.',

    characteristics:
        'Apresenta coloração variável, incluindo '
        'tons marrons, esverdeados e acinzentados. '
        'Possui manchas laterais que podem lembrar '
        'o formato de ferraduras. Essas características '
        'não garantem uma identificação segura.',

    habitat:
        'É encontrada principalmente na Mata Atlântica, '
        'com distribuição desde a Bahia até o Rio Grande '
        'do Sul. Possui hábitos predominantemente '
        'terrestres e noturnos.',

    riskDescription:
        'É uma serpente peçonhenta. Sua picada pode '
        'causar dor, inchaço, sangramentos e, em '
        'casos graves, complicações como lesões renais.',

    safetyAdvice:
        'Não toque, capture ou se aproxime da serpente. '
        'Em caso de picada, afaste-se do animal, mantenha '
        'a pessoa em repouso, retire acessórios apertados '
        'e procure atendimento médico imediatamente. '
        'Se possível, lave o local com água e sabão. '
        'Não faça torniquetes, cortes ou sucção.',

    sourceName:
        'Instituto Butantan e Ministério da Saúde',

    sourceUrl:
        'https://butantan.gov.br/bubutantan/'
        'uma-jararaca-nada-comum-conheca-a-maior-'
        'causadora-de-acidentes-com-cobras-do-brasil',
  );
}
