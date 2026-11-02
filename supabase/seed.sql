-- EcoLens: dados iniciais do catálogo (registro de referência).
-- Reexecutável: não altera fichas já cadastradas.
-- O catálogo público é protegido por RLS e só expõe is_published = true.
-- Fontes oficiais específicas estão em cada source_url.
-- Fotografias exibidas devem ter autoria e licença verificadas
-- (ver docs/IMAGE_CREDITS.md para a jararaca).
-- NÃO executar com credenciais administrativas no aplicativo Flutter.

INSERT INTO public.species (
  slug, common_name, scientific_name, status, description, characteristics, habitat, risk_description, safety_advice, source_name, source_url, image_url, is_published
) VALUES
  ('bothrops-jararaca',
    'Jararaca',
    'Bothrops jararaca',
    'danger',
    'A jararaca (Bothrops jararaca) é uma serpente peçonhenta da família Viperidae. É uma espécie encontrada principalmente na Mata Atlântica, e sua observação deve ser feita à distância.',
    'A coloração varia entre tons marrons, esverdeados, amarelados e acinzentados. Manchas laterais frequentemente lembram ferraduras. A aparência isoladamente não permite identificação segura por pessoas sem treinamento.',
    'Ocorre especialmente na Mata Atlântica, com registros desde a Bahia até o Rio Grande do Sul. Tem hábitos predominantemente terrestres e caça principalmente à noite.',
    'Serpente peçonhenta. Uma picada pode provocar dor, inchaço, manchas arroxeadas e sangramentos. Em casos graves, podem ocorrer necrose e comprometimento renal. A aparência de uma fotografia não confirma a espécie.',
    'Mantenha distância e não tente tocar, capturar ou manipular a serpente. Em caso de picada, procure atendimento médico imediatamente. Mantenha a pessoa em repouso e o membro atingido elevado; retire acessórios apertados e, se possível sem atrasar o atendimento, lave o local com água e sabão. Não faça torniquete, cortes, sucção nem aplique substâncias. Em emergências, acione o SAMU 192.',
    'Instituto Butantan e Ministério da Saúde',
    'https://butantan.gov.br/bubutantan/uma-jararaca-nada-comum-conheca-a-maior-causadora-de-acidentes-com-cobras-do-brasil',
    'https://upload.wikimedia.org/wikipedia/commons/8/88/Bothrops_jararaca_1.jpg',
    TRUE),
  ('leucaena-leucocephala',
    'Leucena',
    'Leucaena leucocephala',
    'invasive',
    'A leucena é uma árvore ou arbusto da família Fabaceae, de origem centro-americana, introduzida no Brasil. Em determinadas áreas, prolifera rapidamente e prejudica o desenvolvimento de plantas nativas.',
    'Tem folhas divididas em numerosos folíolos pequenos (bipinadas), inflorescências globosas esbranquiçadas e frutos em vagens achatadas e escuras.',
    'É encontrada em ambientes modificados e áreas perturbadas, com registros em diferentes regiões brasileiras, inclusive no estado de São Paulo.',
    'O principal risco considerado nesta ficha é ecológico: pode formar agrupamentos densos, competir com a flora nativa e dificultar a regeneração vegetal. Ser uma espécie invasora não é sinônimo de ser venenosa.',
    'Evite plantar, transportar sementes ou disseminar exemplares em áreas naturais. Para manejo ou remoção, consulte o órgão ambiental local e respeite eventuais restrições de áreas protegidas. Não use apenas imagens para confirmar a identificação.',
    'Instituto Água e Terra do Paraná — Flora Exótica',
    'https://www.iat.pr.gov.br/Pagina/Flora-Exotica',
    NULL,
    TRUE),
  ('sus-scrofa',
    'Javali',
    'Sus scrofa',
    'invasive',
    'O javali é um mamífero originário da Europa, Ásia e norte da África, introduzido no Brasil. O Ibama reconhece sua condição de espécie exótica invasora devido aos impactos ambientais e socioeconômicos.',
    'É um suídeo de grande porte e adaptável a diferentes ambientes. Sua reprodução e dispersão favorecem a expansão populacional. Não confunda animais semelhantes apenas por fotografias.',
    'Há registros de javalis em várias unidades federativas brasileiras, incluindo São Paulo. Podem ocupar áreas rurais, mosaicos de vegetação e ambientes próximos de atividades agrícolas.',
    'A espécie pode apresentar comportamento agressivo e causar danos ambientais e agrícolas. A classificação como invasora descreve um impacto ecológico; não significa que toda aproximação resultará em ataque.',
    'Não se aproxime, não tente alimentar, perseguir ou capturar javalis. Afaste-se com calma e mantenha crianças e animais domésticos a uma distância segura. Ações de manejo e controle devem obedecer à regulamentação do Ibama e à orientação dos órgãos responsáveis.',
    'Ibama — Manejo e controle do javali',
    'https://www.gov.br/ibama/pt-br/assuntos/biodiversidade/especies-exoticas-invasoras/manejo-e-controle-do-javali',
    NULL,
    TRUE),
  ('tityus-serrulatus',
    'Escorpião-amarelo',
    'Tityus serrulatus',
    'danger',
    'O escorpião-amarelo é um aracnídeo peçonhento de importância médica no Brasil. Seu veneno pode provocar acidentes graves, especialmente em crianças. A fotografia de um animal não confirma a espécie.',
    'Possui pernas e cauda amareladas e tronco mais escuro. Pode atingir aproximadamente 7 cm; a parte final da cauda apresenta serrilhas características. Esses sinais não permitem identificação segura por pessoas sem treinamento.',
    'Pode ocorrer em áreas urbanas e rurais. Procura abrigo durante o dia em frestas, entulhos, ralos e outros locais escuros; tem hábitos principalmente noturnos.',
    'A ferroada costuma causar dor imediata e intensa. Em casos graves, podem ocorrer vômitos, sudorese e alterações cardíacas e respiratórias, especialmente em crianças. É necessária avaliação médica sem demora.',
    'Não toque no escorpião nem tente capturá-lo com as mãos. Em caso de ferroada, afaste a pessoa do animal, lave o local com água e sabão e procure atendimento médico imediatamente. Não faça torniquete, cortes, sucção nem utilize produtos caseiros. Se necessário, acione o SAMU 192.',
    'Instituto Butantan e Ministério da Saúde',
    'https://www.butantan.gov.br/bubutantan/resistentes-e-antigos-no-planeta-terra-conheca-9-curiosidades-dos-escorpioes',
    NULL,
    TRUE)
ON CONFLICT (slug) DO NOTHING;
