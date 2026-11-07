-- EcoLens: catálogo curado de fauna e flora da região de São Roque.
-- GERADO por tool/build_species_migration.py a partir de
-- supabase/data/curated_species.json. Não edite à mão: edite o JSON
-- e gere de novo.
-- Requer a migração 20261107050000_species_risk_categories.sql.

begin;

-- Abelha-africanizada (Apis mellifera)
update public.species set slug = 'apis-mellifera'
  where scientific_name = 'Apis mellifera' and slug <> 'apis-mellifera'
  and not exists (select 1 from public.species s where s.slug = 'apis-mellifera');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'apis-mellifera',
  'Abelha-africanizada',
  'Apis mellifera',
  'danger',
  false,
  'inseto',
  array['Abelha-europa', 'Abelha-de-mel', 'Abelha-oropa']::text[],
  array['amarelo-ouro', 'marrom-escuro', 'preto']::text[],
  'Abelha peludinha com listras amarelas-douradas e marrons ou pretas no abdômen.',
  array['Abelha-jataí (Tetragonisca angustula): inofensiva, bem pequenininha, amarelada e não possui ferrão.', 'Abelha-irapuá ou arapuá (Trigona spinipes): toda preta, pequena, não tem ferrão (apenas enrola nos cabelos para defender o ninho).', 'Vespas e marimbondos (família Vespidae): têm o corpo liso, sem pelos e com ''cintura'' bem fina, e não deixam o ferrão preso na pele ao picar.']::text[],
  'É a abelha produtora de mel mais comum no Brasil, resultante do cruzamento de abelhas europeias com africanas. Embora seja essencial para a polinização das plantas, defende sua colmeia de forma extremamente agressiva e em grupo quando incomodada por barulhos fortes, cheiros ou vibrações.',
  'Mede cerca de 1,2 a 1,5 cm, tem o tórax coberto por pelos castanhos e o abdômen listrado de amarelo-alaranjado e marrom-escuro. Ao picar uma pessoa, seu ferrão farpado fica preso na pele junto com a bolsa de veneno, que continua bombeando toxina por alguns minutos enquanto a abelha morre e libera um cheiro que atrai outras abelhas para atacar o mesmo local.',
  'Muito comum em flores de jardins, pomares e matas de toda a região. Costuma fazer colmeias com favos de cera em ocos de árvores, beirais de telhados, forros de casas, caixas de luz, pneus velhos e muros.',
  'Existem dois riscos graves: em pessoas alérgicas, uma única picada pode causar choque anafilático (inchaço na garganta, falta de ar grave e queda de pressão) em poucos minutos. Já em ataques de enxame (dezenas ou centenas de picadas), a grande quantidade de veneno no corpo pode causar destruição muscular, insuficiência renal e morte mesmo em quem não tem alergia.',
  'Nunca mexa em colmeias nem jogue pedras, veneno ou fogo, e evite roçadeiras barulhentas perto de enxames. Se for atacado, saia da área em direção a um local fechado (carro ou casa), protegendo o rosto e o pescoço, sem parar para espantar as abelhas e sem pular na água. Retire os ferrões raspando com uma lâmina ou cartão, sem apertá-los, faça compressa fria e acione o SAMU 192.',
  'Se um enxame se instalar no telhado, muro ou quintal da sua casa, isole a área e chame os Bombeiros pelo 193 ou a Defesa Civil (que costumam acionar apicultores cadastrados para remoção segura).',
  'Instituto Butantan — Animais venenosos (guia educativo)',
  'https://publicacoeseducativas.butantan.gov.br/web/animais-venenosos/pages/pdf/animais_venenosos.pdf',
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Antúrio (Anthurium andraeanum)
update public.species set slug = 'anthurium-andraeanum'
  where scientific_name = 'Anthurium andraeanum' and slug <> 'anthurium-andraeanum'
  and not exists (select 1 from public.species s where s.slug = 'anthurium-andraeanum');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'anthurium-andraeanum',
  'Antúrio',
  'Anthurium andraeanum',
  'caution',
  false,
  'planta',
  array['Flor-de-flamingo']::text[],
  array['vermelho', 'verde-escuro', 'amarelo', 'branco', 'rosa']::text[],
  'Folhas verdes em formato de coração e uma estrutura brilhante colorida (geralmente vermelha) com uma espiga amarela ou branca no meio.',
  array['Copo-de-leite (Zantedeschia aethiopica): tem a parte branca enrolada em formato de funil ou copo, sendo igualmente tóxica se mastigada.', 'Lírio-da-paz (Spathiphyllum wallisii): parecido no formato da flor (que é sempre branca), mas tem folhas mais alongadas e sem recorte de coração na base.']::text[],
  'Planta ornamental muito popular nos jardins sombreados e vasos dentro das casas da região por suas flores duráveis e brilhantes. Apesar de muito bonita e comum, todas as partes da planta possuem cristais irritantes que causam acidentes domésticos em crianças e animais de estimação.',
  'Mede entre 30 e 70 cm de altura, com folhas firmes em formato de coração e hastes longas. O que parece uma pétala grande vermelha, rosa ou branca de aspecto plástico é na verdade uma folha modificada (espata), do centro da qual sai uma espiga cilíndrica amarela ou esbranquiçada que lembra um rabinho. Assim como a comigo-ninguém-pode, contém cristais de oxalato de cálcio em suas folhas, talos e flores.',
  'Cultivada em vasos dentro de residências, varandas, canteiros de meia-sombra em quintais, igrejas e jardins de praças.',
  'A mastigação ou ingestão de pedaços da folha ou da flor provoca queimação imediata, coceira intensa e inchaço nos lábios, na boca e na língua, além de muita salivação. Também pode causar inchaço na garganta e dificuldade para engolir, embora os quadros costumem ser moderados porque a dor imediata faz a criança cuspir a planta rapidamente.',
  'Deixe os vasos fora do alcance de bebês, crianças pequenas e animais. Se alguém mastigar ou engolir parte da planta, retire os restos da boca e enxágue-a com água, sem engolir. Não provoque vômito nem dê leite, óleo ou outros "antídotos" caseiros. Guarde um pedaço da planta para identificação e ligue para o Disque-Intoxicação 0800 722 6001; se houver inchaço na garganta ou falta de ar, acione o SAMU 192.',
  'Não necessário.',
  'Sinitox/Fiocruz — Plantas tóxicas',
  'https://sinitox.icict.fiocruz.br/plantas-toxicas',
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Aranha-armadeira (Phoneutria nigriventer)
update public.species set slug = 'phoneutria-nigriventer'
  where scientific_name = 'Phoneutria nigriventer' and slug <> 'phoneutria-nigriventer'
  and not exists (select 1 from public.species s where s.slug = 'phoneutria-nigriventer');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'phoneutria-nigriventer',
  'Aranha-armadeira',
  'Phoneutria nigriventer',
  'danger',
  false,
  'aranha',
  array['Aranha-da-banana', 'Aranha-macaca']::text[],
  array['marrom', 'cinza', 'avermelhado']::text[],
  'Aranha grande que levanta as duas patas da frente quando ameaçada, mostrando pelos avermelhados na boca e fileiras de pontos claros no abdômen.',
  array['Aranha-lobo ou aranha-de-grama (Lycosa erythrognatha): menos perigosa, tem um desenho escuro em forma de seta no abdômen e não costuma subir em paredes lisas nem se apoiar nas patas traseiras da mesma forma.', 'Aranha-caçadora (família Ctenidae): muito parecida visualmente, por isso qualquer aranha grande que levante as patas dianteiras deve ser tratada como armadeira.']::text[],
  'Aranha peçonhenta muito ativa e defensiva, bastante comum na região de São Roque, especialmente no outono, quando os machos saem à procura de fêmeas. Não constrói teia para morar e sai à noite para caçar insetos.',
  'Pode atingir até 15 cm contando as pernas esticadas e tem o corpo coberto por pelos curtos acinzentados ou marrons. Quando se sente acuada, ergue as patas dianteiras, apoia-se nas traseiras (posição de ''armar o bote'') e pode dar pequenos saltos. Possui pelos avermelhados bem visíveis nas quelíceras (região da boca) e pares de manchas claras nas costas.',
  'Durante o dia, esconde-se em locais escuros como cachos de banana, bromélias, pilhas de tijolos, lenha e entulhos. Dentro de casa, é muito comum se esconder dentro de sapatos, botas, roupas no chão, atrás de cortinas e móveis.',
  'A picada causa dor intensíssima e imediata, que se espalha pelo membro atingido, acompanhada de inchaço, suor no local e vermelhidão. Em crianças e idosos, o veneno pode causar vômitos, alteração nos batimentos cardíacos, pressão alta e edema pulmonar, com risco de vida.',
  'Sacuda sempre sapatos e roupas antes de usar e não coloque a mão sem luvas em entulhos ou folhagens. Em caso de picada, lave com água e sabão, faça compressas mornas para aliviar a dor, procure atendimento médico imediato, acione o SAMU 192 ou ligue para o Disque-Intoxicação 0800 722 6001.',
  'Não tente capturar nem afastar a aranha por conta própria. Mantenha pessoas e animais longe e, se ela estiver dentro de casa, peça ajuda aos Bombeiros (193). Se aparecerem muitas no terreno, procure a Vigilância em Saúde (Zoonoses) da prefeitura.',
  'Instituto Butantan — Cartaz acidentes com aranhas',
  'https://publicacoeseducativas.butantan.gov.br/web/cartaz-acidente-aranhas-v2/pages/pdf/a5-Acidente-aranhas-v2-bx.pdf',
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Aranha-de-grama (Lycosa erythrognatha)
update public.species set slug = 'lycosa-erythrognatha'
  where scientific_name = 'Lycosa erythrognatha' and slug <> 'lycosa-erythrognatha'
  and not exists (select 1 from public.species s where s.slug = 'lycosa-erythrognatha');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'lycosa-erythrognatha',
  'Aranha-de-grama',
  'Lycosa erythrognatha',
  'harmless',
  false,
  'aranha',
  array['Aranha-de-jardim', 'Aranha-lobo', 'Tarântula-de-jardim']::text[],
  array['marrom-claro', 'cinza', 'preto', 'alaranjado']::text[],
  'Aranha marrom-acinzentada com um desenho escuro nítido em formato de seta ou ponta de flecha em cima do abdômen.',
  array['Aranha-armadeira (Phoneutria nigriventer): espécie perigosa que também tem pelos avermelhados na boca e levanta as patas da frente, mas é bem maior (até 15 cm), não tem o desenho de seta no abdômen e escala paredes lisas com facilidade.', 'Aranha-marrom (Loxosceles gaucho): espécie perigosa que é bem menor, tem cor marrom uniforme sem desenho de seta e vive escondida em teias parecidas com algodão atrás de móveis.']::text[],
  'É uma das aranhas mais comuns nos gramados e jardins residenciais do Brasil, atuando no controle de grilos e baratas. Como também possui pelos alaranjados perto da boca e levanta as patas dianteiras quando acuada, é constantemente confundida com a aranha-armadeira.',
  'Mede cerca de 3 cm de corpo e até 5 a 6 cm contando as pernas, apresentando faixas escuras no tórax e o característico desenho em forma de seta no abdômen. Não constrói teias para caçar, correndo ativamente pela grama tanto de dia quanto à noite. As fêmeas são facilmente reconhecidas quando carregam uma bolinha branca de seda (bolsa de ovos) presa na parte traseira ou dezenas de filhotinhos grudados nas costas.',
  'Vive no solo de gramados, jardins, pastos, canteiros de plantas e bordas de calçadas. Frequentemente entra por baixo das portas das casas, especialmente quando a grama do quintal é cortada ou em dias de chuva.',
  'Segundo o Instituto Butantan, embora cause acidentes com frequência quando pisada ou comprimida, seu veneno não é perigoso para o ser humano e dispensa soro. A picada provoca apenas dor leve e passageira no local, às vezes acompanhada de discreta vermelhidão.',
  'Não a mate: ela controla grilos e baratas. Só tente colocá-la para fora de casa (cobrindo com um pote e passando um papel firme por baixo) se tiver certeza de que não é uma armadeira; na dúvida, mantenha distância e trate como armadeira. Se ocorrer uma picada, lave com água e sabão e observe; se a dor for muito forte e imediata, acione o SAMU 192 ou ligue para o Disque-Intoxicação 0800 722 6001.',
  'Não necessário.',
  'Instituto Butantan',
  'https://jogoquarteto.butantan.gov.br/default.php?page=cards&subPage=aranhas-nao-peconhentas.php',
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Aranha-de-teia-amarela (Trichonephila clavipes)
update public.species set slug = 'trichonephila-clavipes'
  where scientific_name = 'Trichonephila clavipes' and slug <> 'trichonephila-clavipes'
  and not exists (select 1 from public.species s where s.slug = 'trichonephila-clavipes');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'trichonephila-clavipes',
  'Aranha-de-teia-amarela',
  'Trichonephila clavipes',
  'harmless',
  false,
  'aranha',
  array['Aranha-do-fio-de-ouro', 'Aranha-gigante-da-teia-dourada']::text[],
  array['amarelo', 'marrom', 'preto', 'branco']::text[],
  'Aranha grande de corpo alongado com pintinhas amarelas, pernas compridas com tufos de pelos pretos e uma teia enorme de fios dourados.',
  array['Aranha-prateada (Argiope argentata): também faz teia redonda em jardins e é inofensiva, mas tem o abdômen com pontas laterais e posiciona as pernas em formato de ''X''.']::text[],
  'Aranha famosa por construir teias enormes e muito resistentes, de brilho amarelado, entre árvores, postes e beirais de telhados. Por atingir grande tamanho nas épocas mais quentes do ano, causa muito medo nas pessoas, embora seja mansa e inofensiva.',
  'A fêmea tem de 3 a 4 cm de corpo e pode passar de 10 cm com as pernas esticadas; o macho é minúsculo, com menos de 1 cm, e vive na mesma teia. O abdômen da fêmea é comprido, marrom-alaranjado com pontos claros, e as pernas longas têm tufos de pelos escuros parecidos com polainas. A teia amarelada pode passar de 1 metro de largura.',
  'Muito comum em bordas de mata, trilhas, jardins arborizados, pomares, fiações e beirais de varandas em chácaras e bairros verdes da região.',
  'Segundo o Instituto Butantan, seu veneno não faz mal ao ser humano e ela nunca sai da teia para atacar pessoas. Se alguém esbarrar no rosto ou no braço contra a teia e espremer a aranha contra a pele, a picada causa apenas dor leve e vermelhidão local.',
  'Não destrua a teia nem mate a aranha; se a teia estiver atravessada exatamente no caminho de passagem de uma trilha ou porta, basta retirar a aranha com o auxílio de um galho comprido para uma árvore próxima. Em caso de picada acidental, lave o local com água e sabão e, se houver reação alérgica ou dúvida, ligue para o Disque-Intoxicação 0800 722 6001.',
  'Não necessário.',
  'Instituto Butantan',
  'https://jogoquarteto.butantan.gov.br/default.php?page=cards&subPage=aranhas-nao-peconhentas.php',
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Aranha-marrom (Loxosceles gaucho)
update public.species set slug = 'loxosceles-gaucho'
  where scientific_name = 'Loxosceles gaucho' and slug <> 'loxosceles-gaucho'
  and not exists (select 1 from public.species s where s.slug = 'loxosceles-gaucho');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'loxosceles-gaucho',
  'Aranha-marrom',
  'Loxosceles gaucho',
  'danger',
  false,
  'aranha',
  array['Aranha-violino']::text[],
  array['marrom', 'amarelo-queimado', 'bege-escuro']::text[],
  'Aranha pequena, toda marrom, de pernas finas, que faz uma teia branca irregular parecida com fiapos de algodão.',
  array['Aranha-de-canto-de-parede (Pholcus phalangioides): inofensiva, tem o corpo minúsculo com pernas extremamente longas e finas como fios de cabelo.', 'Aranha-cuspideira (Scytodes fusca): inofensiva, tem tamanho parecido, mas possui o corpo mais arredondado e manchas escuras nas pernas e no dorso.']::text[],
  'Pequena aranha peçonhenta que não é agressiva, mas causa acidentes graves quando é espremida contra o corpo dentro de roupas ou na cama. Loxosceles gaucho é a espécie de aranha-marrom predominante no interior e na Grande São Paulo.',
  'É pequena, medindo cerca de 3 cm contando as pernas (do tamanho de uma moeda de 1 real), com corpo marrom-avermelhado e abdômen parecido com uma azeitona pequena. Diferente da maioria das aranhas, possui apenas 6 olhos divididos em três pares (visíveis de perto com lupa). Sua teia não é redonda, parecendo um chumaço de algodão sujo em frestas escuras.',
  'Adapta-se muito bem ao interior das casas e galpões, escondendo-se atrás de quadros, armários, rodapés, caixas de papelão e roupas guardadas há muito tempo. No quintal, vive sob cascas de árvores, telhas empilhadas e tijolos.',
  'A picada quase não dói na hora e muitas vezes passa despercebida, mas entre 12 e 24 horas depois surge uma mancha roxa cercada por um anel claro, dor em queimação e bolhas. O veneno destrói a pele formando uma ferida profunda (necrose) de difícil cicatrização e, em casos mais raros e graves, pode destruir glóbulos vermelhos e causar insuficiência renal.',
  'Limpe periodicamente atrás de móveis e quadros, afaste camas da parede e sacuda roupas de cama e vestimentas guardadas. Se suspeitar de picada ou notar uma ferida que escurece no centro nas horas seguintes, não passe pomadas caseiras, procure um médico imediatamente e ligue para o Disque-Intoxicação 0800 722 6001 ou acione o SAMU 192.',
  'Não necessário chamar resgate ambiental; em caso de muitos indivíduos na residência, contate o setor de Zoonoses da prefeitura para orientação de manejo ambiental.',
  'Instituto Butantan — Cartaz acidentes com aranhas',
  'https://publicacoeseducativas.butantan.gov.br/web/cartaz-acidente-aranhas-v2/pages/pdf/a5-Acidente-aranhas-v2-bx.pdf',
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Aranha-prateada (Argiope argentata)
update public.species set slug = 'argiope-argentata'
  where scientific_name = 'Argiope argentata' and slug <> 'argiope-argentata'
  and not exists (select 1 from public.species s where s.slug = 'argiope-argentata');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'argiope-argentata',
  'Aranha-prateada',
  'Argiope argentata',
  'harmless',
  false,
  'aranha',
  array['Aranha-de-prata', 'Aranha-X', 'Aranha-de-jardim']::text[],
  array['prata', 'amarelo', 'preto', 'branco']::text[],
  'Aranha colorida de cabeça prateada e abdômen com pontas amarelas e pretas que fica no meio da teia com as pernas unidas duas a duas formando um ''X''.',
  array['Aranha-de-teia-amarela (Trichonephila clavipes): também inofensiva e moradora de teias grandes em jardins, mas tem o corpo comprido e não junta as pernas em forma de ''X''.']::text[],
  'Aranha tecedeira muito comum em jardins e quintais ensolarados da região. Suas cores fortes e o hábito de ficar parada bem no centro da teia costumam assustar moradores, mas ela é completamente inofensiva e captura grande quantidade de moscas e mosquitos.',
  'A fêmea tem cerca de 1,5 cm de corpo e uns 5 cm com as pernas esticadas; o macho é minúsculo, com menos de 1 cm. O tórax tem brilho prateado e o abdômen é recortado em amarelo, preto e branco. Constrói uma teia redonda entre galhos, muitas vezes com faixas brancas de seda em zigue-zague formando um "X", e passa o dia imóvel no centro com os pares de pernas alinhados em "X".',
  'Vive em arbustos, cercas-vivas, pomares, hortas e jardins residenciais, nunca saindo da teia para caminhar dentro das casas.',
  'Seu veneno serve apenas para paralisar pequenos insetos que caem na teia e não oferece nenhum perigo de intoxicação grave para seres humanos. Só pica se alguém apertá-la diretamente com a mão, causando apenas uma dor leve parecida com uma ferroada de formiga e vermelhidão passageira.',
  'Preserve a aranha e sua teia no jardim, pois ela trabalha gratuitamente no controle de insetos voadores. Caso ocorra uma picada acidental ao podar plantas, lave o local com água e sabão e observe; se surgirem sinais de alergia na pele ou dúvida na identificação, ligue para o Disque-Intoxicação 0800 722 6001.',
  'Não necessário.',
  'Instituto Butantan',
  'https://jogoquarteto.butantan.gov.br/default.php?page=cards&subPage=aranhas-nao-peconhentas.php',
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Aranha-saltadora-de-parede (Menemerus bivittatus)
update public.species set slug = 'menemerus-bivittatus'
  where scientific_name = 'Menemerus bivittatus' and slug <> 'menemerus-bivittatus'
  and not exists (select 1 from public.species s where s.slug = 'menemerus-bivittatus');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'menemerus-bivittatus',
  'Aranha-saltadora-de-parede',
  'Menemerus bivittatus',
  'harmless',
  false,
  'aranha',
  array['Aranha-papa-moscas', 'Aranha-saltadora']::text[],
  array['cinza', 'marrom', 'branco', 'preto']::text[],
  'Aranha pequena e achatada, cinza-amarronzada com faixas claras nas laterais, que anda aos pulinhos pelas paredes e tem dois olhos grandes virados para a frente.',
  array['Aranha-marrom (Loxosceles gaucho): espécie perigosa que é maior, tem cor marrom uniforme, pernas mais longas e finas, não dá pulos e só sai à noite de trás dos móveis.']::text[],
  'Pequena aranha diurna e curiosa que vive nas paredes ensolaradas, janelas e plantas das casas, caçando moscas, pernilongos e formigas no salto. Muita gente tem medo ou mata por achar que pode ser um filhote de aranha perigosa, mas ela é totalmente inofensiva.',
  'Mede cerca de 1 cm, com corpo achatado e peludo em tons de cinza e marrom, com faixas claras nas laterais. Os dois olhos centrais grandes na frente da cabeça dão a ela ótima visão durante o dia. Não faz teia para caçar: aproxima-se devagar e salta sobre moscas e mosquitos, presa a um fio de seda de segurança.',
  'Muito comum dentro de casas, em parapeitos de janelas, muros ensolarados, varandas, cortinas e folhas de plantas no jardim.',
  'É 100% inofensiva para adultos, crianças e animais domésticos. Seu tamanho minúsculo e seu veneno voltado apenas para pequenos insetos não causam qualquer problema de saúde ao ser humano.',
  'Não mate nem passe inseticida nessas pequenas aranhas saltadoras, pois elas ajudam a eliminar moscas e mosquitos da dengue dentro de casa. Se quiser retirá-la de cima de uma mesa ou cama, basta guiá-la para uma folha de papel e deixá-la na janela ou em uma planta.',
  'Não necessário.',
  'Instituto Butantan',
  'https://butantan.gov.br/noticias/maioria-das-aranhas-que-vive-nas-cidades-nao-e-venenosa--conheca-as-mais-perigosas',
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Azaleia (Rhododendron indicum)
update public.species set slug = 'rhododendron-indicum'
  where scientific_name = 'Rhododendron indicum' and slug <> 'rhododendron-indicum'
  and not exists (select 1 from public.species s where s.slug = 'rhododendron-indicum');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'rhododendron-indicum',
  'Azaleia',
  'Rhododendron indicum',
  'caution',
  false,
  'planta',
  array['Rododendro', 'Azaleia-de-jardim']::text[],
  array['rosa', 'branco', 'vermelho', 'roxo', 'verde-escuro']::text[],
  'Arbusto ramificado de folhas pequenas, escuras e meio ásperas que fica coberto de flores abertas rosas, brancas ou vermelhas no outono e inverno.',
  array['Espirradeira (Nerium oleander): arbusto altamente perigoso que também dá flores rosas e brancas, mas tem folhas muito mais compridas em forma de lança e solta seiva leitosa.', 'Quaresmeira (Pleroma granulosum) e manacá-da-serra (Pleroma mutabile): árvores nativas não tóxicas, com folhas de três a cinco nervuras curvas bem marcadas de ponta a ponta.']::text[],
  'Uma das plantas ornamentais mais tradicionais da região de São Roque, Ibiúna e Cotia, onde o clima mais frio faz com que floresça intensamente em praças, estradas, condomínios e chácaras. Pouca gente sabe que suas folhas, flores e até o néctar contêm substâncias tóxicas se forem ingeridos.',
  'Arbusto lenhoso que mede geralmente de 50 cm a 2 metros de altura, também muito vendido em vasos pequenos. Suas folhas são pequenas, ovais, verde-escuras e possuem pequenos pelinhos ásperos ao toque. As flores têm formato de sino aberto com cinco pétalas e longos fios (estames) no centro, aparecendo em grande quantidade nos meses mais frios.',
  'Extremamente comum em canteiros de praças, jardins residenciais, cercas-vivas de chácaras, entradas de sítios e vasos dentro de varandas e casas.',
  'Possui toxinas (graianotoxinas) em todas as partes da planta que afetam o aparelho digestivo e, em grandes quantidades, o sistema nervoso e o coração. A ingestão acidental de folhas ou flores por crianças ou cães causa baba excessiva, náuseas, vômitos, dor de cabeça, fraqueza e tontura, podendo evoluir em casos graves para queda de pressão e convulsões.',
  'Não deixe crianças pequenas colocarem flores caídas na boca nem cães e gatos mastigarem a planta. Se alguém mastigar ou engolir parte da planta, retire os restos da boca e enxágue-a com água, sem engolir. Não provoque vômito nem dê leite, óleo ou outros "antídotos" caseiros. Guarde um pedaço da planta para identificação e ligue para o Disque-Intoxicação 0800 722 6001; se houver inchaço na garganta ou falta de ar, acione o SAMU 192.',
  'Não necessário.',
  'Secretaria Municipal da Saúde de São Paulo',
  'https://prefeitura.sp.gov.br/web/saude/w/noticias/340114',
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Bico-de-papagaio (Euphorbia pulcherrima)
update public.species set slug = 'euphorbia-pulcherrima'
  where scientific_name = 'Euphorbia pulcherrima' and slug <> 'euphorbia-pulcherrima'
  and not exists (select 1 from public.species s where s.slug = 'euphorbia-pulcherrima');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'euphorbia-pulcherrima',
  'Bico-de-papagaio',
  'Euphorbia pulcherrima',
  'caution',
  false,
  'planta',
  array['Flor-do-natal', 'Poinsétia', 'Manhã-de-páscoa']::text[],
  array['vermelho', 'verde', 'amarelo']::text[],
  'Arbusto sem espinhos que solta leite branco ao quebrar e apresenta uma coroa de folhas grandes vermelho-vivo no topo dos ramos no outono e inverno.',
  array['Coroa-de-cristo (Euphorbia milii): parente próxima que solta o mesmo leite branco irritante, mas possui o caule todo coberto de espinhos duros.', 'Amendoim-bravo ou leiteira (Euphorbia heterophylla): planta invasora menor de terrenos baldios e lavouras que tem apenas uma mancha clara ou avermelhada na base das folhas superiores e também solta látex.']::text[],
  'Planta ornamental muito famosa na época do Natal em vasos pequenos, mas que também é muito plantada como arbusto grande nos quintais e jardins de São Roque e região. Pertence à mesma família da coroa-de-cristo e produz uma seiva leitosa branca irritante em todas as suas partes.',
  'Em vasos mede cerca de 30 a 50 cm, mas plantada no chão do quintal vira um arbusto lenhoso de até 3 metros de altura. Possui folhas verdes recortadas nas laterais e, nos meses mais frios, as folhas do topo dos galhos ficam totalmente vermelhas (ou creme/rosadas em algumas variedades) ao redor de pequenas flores amarelas e verdes no centro. Quando qualquer folha ou galho é quebrado, escorre imediatamente um leite branco (látex).',
  'Muito comum dentro de casas (em vasos decorativos no fim do ano) e plantada em quintais, jardins de chácaras, calçadas e praças da região.',
  'A toxicidade é baixa. O leite branco pode irritar a pele e os olhos, causando vermelhidão, coceira e ardência. Se mastigada, costuma provocar apenas irritação na boca e, às vezes, náuseas ou vômitos leves.',
  'Deixe vasos natalinos longe de bebês, crianças e gatos ou cães, e use luvas e proteção nos olhos quando for podar arbustos grandes no quintal. Se a seiva cair nos olhos, lave com água corrente limpa por 15 minutos; se houver ingestão, enxágue a boca com água sem engolir, não force o vômito e ligue para o Disque-Intoxicação 0800 722 6001 (ou acione o SAMU 192 em caso de sintomas intensos).',
  'Não necessário.',
  'Sinitox/Fiocruz — Plantas tóxicas',
  'https://sinitox.icict.fiocruz.br/plantas-toxicas',
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Boipeva (Xenodon merremii)
update public.species set slug = 'xenodon-merremii'
  where scientific_name = 'Xenodon merremii' and slug <> 'xenodon-merremii'
  and not exists (select 1 from public.species s where s.slug = 'xenodon-merremii');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'xenodon-merremii',
  'Boipeva',
  'Xenodon merremii',
  'harmless',
  false,
  'serpente',
  array['Capitão-do-mato', 'Jararaca-falsa', 'Pepeva']::text[],
  array['marrom', 'amarelo-queimado', 'cinza', 'preto']::text[],
  'Manchas escuras pelo corpo parecidas com as da jararaca e hábito de achatar o corpo e o pescoço contra o chão quando assustada.',
  array['Jararaca (Bothrops jararaca): serpente perigosa que possui fosseta loreal (buraquinho entre o olho e a narina) e pupila vertical, enquanto a boipeva tem pupila redonda e não tem fosseta.', 'Dormideira (Dipsas mikanii): também inofensiva e parecida com jararaca, mas é bem menor, mais fina e tem cabeça arredondada.', 'Boipeva-de-mata (Xenodon neuwiedii): espécie parecida das áreas florestadas da região, igualmente inofensiva.']::text[],
  'Serpente diurna e não peçonhenta que se alimenta quase exclusivamente de sapos, sendo uma grande aliada no controle biológico. Como sua coloração e seu comportamento de defesa imitam perfeitamente as jararacas, é muito perseguida e morta em sítios e chácaras.',
  'Pode atingir até 1,5 metro de comprimento, com corpo robusto, cauda curta e cores bastante variadas em tons de marrom, cinza e amarelado com manchas dorsais. Quando se sente ameaçada, achata o corpo contra o chão, triangulariza a cabeça e dá botes falsos (muitas vezes de boca fechada) para assustar o agressor. Possui dentes maiores apenas no fundo da boca, adaptados para furar e esvaziar sapos que se inflam.',
  'Habita o solo de bordas de mata, áreas rurais, pastagens, beiras de açudes, brejos e quintais de chácaras onde existam sapos e rãs.',
  'Não oferece risco de morte ao ser humano por ser uma serpente não peçonhenta. Porém, uma mordida defensiva pode causar dor local, pequeno sangramento, inchaço leve e infecção secundária por bactérias.',
  'Nunca tente matar a serpente nem confie apenas no olhar para diferenciá-la de uma jararaca verdadeira; afaste-se e deixe o animal ir embora. Em caso de mordida, lave com água e sabão, não faça torniquete e acione o SAMU 192 ou ligue para o Disque-Intoxicação 0800 722 6001 para avaliação médica, já que é muito fácil confundi-la com a jararaca.',
  'Se estiver em quintal murado ou dentro de casa, mantenha pessoas e animais afastados e acione os Bombeiros pelo 193.',
  'Instituto Butantan',
  'https://butantan.gov.br/bubutantan/voce-ja-ouviu-falar-das-falsas-jararacas-conheca-especies-que-imitam-a-serpente-peconhenta-mas-sao-inofensivas',
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Cachorro-do-mato (Cerdocyon thous)
update public.species set slug = 'cerdocyon-thous'
  where scientific_name = 'Cerdocyon thous' and slug <> 'cerdocyon-thous'
  and not exists (select 1 from public.species s where s.slug = 'cerdocyon-thous');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'cerdocyon-thous',
  'Cachorro-do-mato',
  'Cerdocyon thous',
  'harmless',
  false,
  'mamifero',
  array['Graxaim', 'Raposa-vinagre']::text[],
  array['cinza', 'marrom', 'preto', 'amarelado']::text[],
  'Canídeo silvestre de pequeno porte, pelagem acinzentada com tons pretos e amarelados, focinho pontudo e pernas curtas.',
  array['Cachorro doméstico sem raça definida (Canis lupus familiaris): cães errantes ou semidomésticos que andam em chácaras e podem transmitir doenças para a fauna silvestre.']::text[],
  'Pequeno canídeo nativo da Mata Atlântica e de áreas abertas, muito adaptado a viver perto de zonas rurais e chácaras. É um animal onívoro que come frutos, insetos, pequenos roedores e carniça, ajudando a controlar pragas.',
  'Pesa entre 5 e 8 kg (tamanho aproximado de um cachorro pequeno de pernas curtas), com pelagem densa grisalha, orelhas arredondadas e cauda peluda com ponta escura. Tem hábitos noturnos ou crepusculares e costuma andar sozinho ou em casais. É um animal bastante tímido que prefere fugir a enfrentar qualquer ameaça.',
  'Bordas de matas, capoeirões, plantações, pastagens e quintais de sítios e chácaras nos municípios da região.',
  'Não costuma oferecer perigo e foge ao perceber pessoas. Como qualquer mamífero silvestre, pode transmitir raiva se morder.',
  'Mantenha cães e gatos vacinados contra a raiva e não deixe ração do lado de fora à noite. Nunca tente capturar ou tocar em um cachorro-do-mato, mesmo ferido. Se houver mordida, arranhão ou contato direto com o animal, lave o local com bastante água e sabão e procure uma unidade de saúde no mesmo dia para avaliar a vacina antirrábica.',
  'Acione a Polícia Militar Ambiental ou o CETRAS se o animal for encontrado atropelado, debilitado ou preso em cercas.',
  'Revisão da equipe EcoLens',
  null,
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Caninana (Spilotes pullatus)
update public.species set slug = 'spilotes-pullatus'
  where scientific_name = 'Spilotes pullatus' and slug <> 'spilotes-pullatus'
  and not exists (select 1 from public.species s where s.slug = 'spilotes-pullatus');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'spilotes-pullatus',
  'Caninana',
  'Spilotes pullatus',
  'harmless',
  false,
  'serpente',
  array['Cobra-tigre', 'Araboia', 'Cobra-preta-e-amarela']::text[],
  array['preto', 'amarelo']::text[],
  'Serpente grande e comprida, toda desenhada com faixas e manchas diagonais pretas e amarelo-vivo bem contrastantes.',
  array['Jararacuçu (Bothrops jararacussu): espécie peçonhenta que também é preta e amarela, mas tem o corpo muito mais grosso, cabeça triangular com fosseta loreal e vive no chão, não subindo com agilidade no alto das árvores.', 'Cobra-cipó (Chironius bicarinatus): também inofensiva e arborícola, mas tem coloração oliva ou azulada sem as faixas amarelas e pretas fortes da caninana.']::text[],
  'Serpente não peçonhenta de grande porte, famosa por sua agilidade tanto no chão quanto no alto das árvores da Mata Atlântica. Carrega uma fama injusta de ser uma cobra brava e perigosa porque infla o pescoço quando se assusta, mas não possui veneno e ajuda a controlar ratos e até outras cobras.',
  'Pode ultrapassar 2 metros de comprimento, com corpo esguio, escamas grandes, olhos grandes com pupila redonda e coloração inconfundível preta com manchas amarelas. É uma serpente diurna que se desloca rapidamente entre os galhos das árvores e telhados de sítios. Quando se sente acuada, estufa a região do pescoço, vibra a cauda no chão fazendo barulho nas folhas secas e pode dar botes defensivos para conseguir fugir.',
  'Comum em matas preservadas, bordas de floresta, árvores frutíferas, pomares e telhados de paióis ou galinheiros em áreas rurais da região.',
  'Não possui veneno nem dentes inoculadores (dentição áglifa), não oferecendo nenhum risco de envenenamento ou morte. Caso seja encurralada e morda para se defender, causa apenas ferimentos superficiais pelos dentes, que precisam ser limpos para evitar infecção por bactérias.',
  'Se avistar uma caninana no quintal ou em uma árvore, mantenha distância, não a encurrale e deixe o caminho livre para que ela fuja rapidamente para a mata. Em caso de mordida acidental, lave bem o local com água e sabão, não passe produtos caseiros e procure uma unidade de saúde para limpeza do ferimento ou ligue para o Disque-Intoxicação 0800 722 6001.',
  'Acione os Bombeiros pelo 193 ou a patrulha ambiental se a serpente entrar dentro da casa, forro ou galinheiro fechado e não conseguir sair sozinha.',
  'Instituto Butantan',
  'https://jogoquarteto.butantan.gov.br/default.php?page=cards&subPage=serpentes-nao-peconhentas.php',
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Capivara (Hydrochoerus hydrochaeris)
update public.species set slug = 'hydrochoerus-hydrochaeris'
  where scientific_name = 'Hydrochoerus hydrochaeris' and slug <> 'hydrochoerus-hydrochaeris'
  and not exists (select 1 from public.species s where s.slug = 'hydrochoerus-hydrochaeris');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'hydrochoerus-hydrochaeris',
  'Capivara',
  'Hydrochoerus hydrochaeris',
  'caution',
  false,
  'mamifero',
  array['Capiuva', 'Piroca']::text[],
  array['marrom', 'castanho', 'cinza-escuro']::text[],
  'O maior roedor do mundo, de corpo robusto e barrigudo, sem cauda aparente, pelagem marrom áspera e olhos e orelhas pequenos no alto da cabeça.',
  array['Javali (Sus scrofa): mamífero exótico invasor perigoso que possui focinho pontudo, presas e orelhas maiores.']::text[],
  'Maior roedor existente na natureza, semiaquático e de hábitos pacíficos, muito encontrado em margens de rios, represas e represamentos da região. Vive em grupos familiares e é o principal hospedeiro do carrapato-estrela (Amblyomma sculptum).',
  'Pode pesar de 30 a 80 kg, com corpo pesado em formato de barril, patas curtas com membranas interdigitais para nadar com facilidade e ausência de cauda. Sua pelagem é marrom-acinzentada e rala. Alimenta-se de capim, gramíneas e plantas aquáticas, passando boa parte do dia submersa na água para se proteger do calor.',
  'Margens de represas, lagos, córregos, margens do Rio Tietê e áreas alagadas em chácaras, condomínios e parques da região.',
  'Não tem veneno e não ataca pessoas por agressividade, mas apresenta dois riscos indiretos importantes: pode morder com força se for encurralada ou acuada por cães, e hospeda o carrapato-estrela (Amblyomma sculptum), vetor da bactéria causadora da febre maculosa brasileira, doença grave transmitida pela picada do carrapato.',
  'Mantenha distância, não alimente as capivaras e, em gramados perto de lagos onde elas vivem, use calça comprida, roupas claras e repelente. Se tiver febre nos dias seguintes a uma picada de carrapato ou a uma visita a essas áreas, procure atendimento médico logo e conte sobre o contato, porque a febre maculosa precisa de tratamento rápido.',
  'Não necessário para animais saudáveis na água; acione órgãos ambientais municipais se houver atropelamentos ou animais feridos em vias públicas.',
  'Ministério da Saúde — Diretrizes para o manejo de capivaras (febre maculosa)',
  'https://www.gov.br/saude/pt-br/assuntos/saude-de-a-a-z/f/febre-maculosa/publicacoes/diretrizes-para-o-manejo-de-capivaras-em-area-de-ocorrencia-de-febre-maculosa',
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Caramujo-africano (Achatina fulica)
update public.species set slug = 'achatina-fulica'
  where scientific_name = 'Achatina fulica' and slug <> 'achatina-fulica'
  and not exists (select 1 from public.species s where s.slug = 'achatina-fulica');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'achatina-fulica',
  'Caramujo-africano',
  'Achatina fulica',
  'caution',
  true,
  'molusco',
  array['Caramujo-gigante-africano', 'Caramujo-gigante']::text[],
  array['marrom', 'amarelado', 'bege', 'preto']::text[],
  'Caracol terrestre muito grande de concha cônica alongada com listras marrons e bege alternadas.',
  array['Aruá-do-mato (Megalobulimus spp.): caramujos nativos da Mata Atlântica, com concha mais arredondada e lábio da abertura espesso; são protegidos e não devem ser recolhidos.']::text[],
  'Espécie exótica invasora de origem africana introduzida no Brasil para fins comerciais que se espalhou por hortas, jardins e terrenos de toda a região. É um vetor importante de parasitas causadores de doenças graves em humanos.',
  'Pode atingir até 15 a 20 cm de comprimento na concha, que é pontiaguda, pesada e apresenta tons castanhos e amarelados. É um animal hermafrodita com altíssima capacidade reprodutiva, botando centenas de ovos de cada vez. De dia fica escondido na sombra e sai para se alimentar de plantas, matéria orgânica em decomposição e até tintas de parede (buscando cálcio para a concha).',
  'Muito comum em quintais úmidos, hortas, jardins, canteiros de entulho, beiras de córregos e terrenos baldios cobertos de vegetação alta.',
  'O principal perigo não é o toque no animal, mas sim o fato de o muco que ele excreta (e seu tecido mole) poder conter larvas de nematódeos parasitas capazes de transmitir doenças graves como a meningite eosinofílica e a angiostrongilíase abdominal se ingeridos acidentalmente.',
  'Não toque nos caramujos com as mãos desprotegidas: use luvas e botas de borracha. Lave muito bem verduras, legumes e frutas da horta antes de comer, porque a doença costuma vir do muco que fica nos alimentos. Em caso de dor de cabeça forte, febre ou dor abdominal depois de possível contato, procure uma unidade de saúde e conte sobre o caramujo.',
  'Não é caso de resgate. Recolha caramujos e ovos com luvas, quebre as conchas e enterre-os em vala longe de poços e cisternas, cobrindo com cal virgem; sem cal, deixe-os em solução de 3 partes de água para 1 de cloro por 24 horas antes de descartar. Não use sal. Em caso de infestação, avise a Vigilância em Saúde da prefeitura.',
  'Ministério da Saúde — Nota Técnica nº 30/2022 (manejo do molusco)',
  'https://www.gov.br/saude/pt-br/centrais-de-conteudo/publicacoes/notas-tecnicas/2022/nota-tecnica-no-30-2022-cgzv-deidt-svs-ms-manejo-do-molusco-gastropode.pdf/@@download/file',
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Cascavel (Crotalus durissus)
update public.species set slug = 'crotalus-durissus'
  where scientific_name = 'Crotalus durissus' and slug <> 'crotalus-durissus'
  and not exists (select 1 from public.species s where s.slug = 'crotalus-durissus');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'crotalus-durissus',
  'Cascavel',
  'Crotalus durissus',
  'danger',
  false,
  'serpente',
  array['Boicininga', 'Maracambóia', 'Cascavel-de-quatro-ventas']::text[],
  array['marrom', 'amarelo-escuro', 'branco', 'preto']::text[],
  'Desenhos em formato de losangos escuros com bordas claras nas costas e um chocalho bem visível na ponta da cauda.',
  array['Jiboia (Boa constrictor): inofensiva, muito maior, sem chocalho na cauda e com manchas arredondadas em vez de losangos regulares.', 'Surucucu-pico-de-jaca (Lachesis muta): não ocorre na região de São Roque e tem escamas eriçadas na ponta da cauda, e não um chocalho que faz barulho.']::text[],
  'Serpente peçonhenta robusta e muito conhecida pelo chocalho na ponta da cauda, que ela vibra fazendo um som alto quando se sente ameaçada. Apesar de originalmente associada a áreas abertas, expandiu muito seu território em áreas desmatadas do interior paulista.',
  'Atinge cerca de 1 a 1,5 metro, tem o corpo grosso, escamas ásperas e cabeça triangular. Possui duas faixas longitudinais escuras no pescoço seguidas por desenhos de losangos bem marcados ao longo das costas. Na ponta da cauda, apresenta o guizo (chocalho), que ganha novos anéis a cada troca de pele.',
  'Prefere áreas mais secas, abertas e ensolaradas, como pastos, plantações, terrenos baldios, barrancos e beiras de estradas de terra da região. Costuma se abrigar sob pedras, cupinzeiros e pilhas de telhas ou madeira.',
  'O veneno é extremamente potente e ataca o sistema nervoso e os músculos, quase sem causar dor ou inchaço no local da picada. A vítima passa a apresentar pálpebras caídas, visão dupla, dificuldade para falar, dores musculares e urina escura (cor de refrigerante de cola), com risco de morte se não receber o soro.',
  'Ao ouvir o chocalho ou ver o animal, pare imediatamente, localize onde ele está e afaste-se em sentido contrário. Em caso de acidente, não amarre o membro nem coloque nada sobre o ferimento, mantenha a pessoa em repouso absoluto e acione o SAMU 192 ou ligue para o Disque-Intoxicação 0800 722 6001 para ir urgente ao hospital.',
  'Acione os Bombeiros pelo 193 ou a Polícia Militar Ambiental caso o animal seja encontrado em quintais, chácaras ou áreas de circulação de pessoas e animais domésticos.',
  'Instituto Butantan — Animais venenosos (guia educativo)',
  'https://publicacoeseducativas.butantan.gov.br/web/animais-venenosos/pages/pdf/animais_venenosos.pdf',
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Cobra-cega (Siphonops annulatus)
update public.species set slug = 'siphonops-annulatus'
  where scientific_name = 'Siphonops annulatus' and slug <> 'siphonops-annulatus'
  and not exists (select 1 from public.species s where s.slug = 'siphonops-annulatus');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'siphonops-annulatus',
  'Cobra-cega',
  'Siphonops annulatus',
  'harmless',
  false,
  'anfibio',
  array['Cecília', 'Minhocuçu-de-anel']::text[],
  array['azul-escuro', 'preto', 'branco']::text[],
  'Corpo liso, úmido e brilhante, sem patas nem escamas, de cor escura (azulada ou preta) toda marcada por anéis brancos bem desenhados.',
  array['Cobra-de-duas-cabeças (Amphisbaena alba): é um réptil subterrâneo igualmente inofensivo, mas tem a pele seca dividida em pequenos quadradinhos e cor clara ou rosada.', 'Coral-verdadeira (Micrurus corallinus): serpente perigosa que possui escamas secas e anéis vermelhos, além de pretos e brancos.']::text[],
  'Apesar do nome popular, não é uma cobra, e sim um anfíbio subterrâneo (parente dos sapos e rãs) que não possui patas. Como aparece de repente quando alguém está cavando a horta ou após chuvas fortes, muitas pessoas se assustam e matam o animal com a enxada.',
  'Mede cerca de 30 a 45 cm de comprimento e parece uma minhoca grande de cor chumbo ou azul-escura com dezenas de anéis brancos perfeitos ao longo do corpo. Sua pele é totalmente lisa, úmida e sem escamas, e seus olhos são minúsculos e cobertos por pele, servindo apenas para perceber claridade. Alimenta-se de minhocas, cupins e larvas subterrâneas, ajudando a manter o solo fértil.',
  'Vive enterrada em solos úmidos e ricos em matéria orgânica, hortas, canteiros de jardins, bananeiras, pilhas de compostagem e debaixo de troncos podres.',
  'É um animal completamente inofensivo para os seres humanos, pois não tem presas inoculadoras nem ataca pessoas. Possui apenas secreções naturais na pele úmida (como todos os anfíbios) para se proteger de bactérias e predadores, que podem irritar os olhos ou a boca se alguém manuseá-la sem luvas.',
  'Nunca mate a cobra-cega quando encontrá-la na horta ou no jardim; basta cobri-la novamente com terra úmida e folhas secas. Evite pegá-la diretamente com as mãos nuas e, caso toque no animal, lave bem as mãos com água e sabão antes de coçar os olhos; em caso de irritação ocular ou dúvida, ligue para o Disque-Intoxicação 0800 722 6001.',
  'Não necessário.',
  'Instituto Butantan',
  'https://publicacoeseducativas.butantan.gov.br/web/animais-venenosos/pages/pdf/animais_venenosos.pdf',
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Cobra-cipó (Chironius exoletus)
update public.species set slug = 'chironius-exoletus'
  where scientific_name = 'Chironius exoletus' and slug <> 'chironius-exoletus'
  and not exists (select 1 from public.species s where s.slug = 'chironius-exoletus');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'chironius-exoletus',
  'Cobra-cipó',
  'Chironius exoletus',
  'harmless',
  false,
  'serpente',
  array['Cobra-verde', 'Cipó-marrom', 'Sacaiboia']::text[],
  array['verde', 'marrom', 'oliva']::text[],
  'Corpo muito fino e comprido como um cipó, com olhos grandes e coloração que varia do marrom-esverdeado ao verde.',
  array['Cobra-verde (Philodryas olfersii): toda verde-clara com uma faixa marrom no topo da cabeça; diferente da cobra-cipó do gênero Chironius, a Philodryas pode causar inchaço e dor local importantes ao morder.', 'Jararaca (Bothrops jararaca): espécie perigosa que tem o corpo mais grosso, cabeça bem triangular e desenhos em forma de ''V'' invertido.']::text[],
  'Serpente diurna, ágil e totalmente inofensiva aos seres humanos, muito vista sobre galhos de árvores e arbustos. Por ser muito rápida na fuga ou vibrar a cauda no chão quando acuada, muitas pessoas se assustam e acabam matando o animal sem necessidade.',
  'Atinge normalmente até 1 metro de comprimento, tendo o corpo bem delgado, cauda longa e olhos grandes com pupila redonda. Sua cor varia entre tons de verde-oliva e marrom, o que garante excelente camuflagem nos galhos. Alimenta-se principalmente de rãs e pequenos lagartos, ajudando no equilíbrio ecológico do ambiente.',
  'Vive em árvores, arbustos, cercas-vivas e bordas de mata, onde costuma ser vista tomando sol de dia ou dormindo enrolada nos ramos à noite. Também atravessa estradas rurais, trilhas e gramados de chácaras.',
  'É uma serpente não peçonhenta que não possui dentes inoculadores de veneno nem toxina perigosa para o ser humano. Se for segurada, pode morder apenas para se defender, causando somente pequenos arranhões superficiais com risco de infecção por bactérias da boca.',
  'Ao avistar a cobra-cipó no jardim ou em uma árvore, apenas mantenha distância e deixe que ela siga seu caminho sozinha. Se alguém for mordido ao tentar manuseá-la, lave bem o ferimento com água e sabão e procure um posto de saúde para avaliar a vacina antitetânica, ou ligue para o Disque-Intoxicação 0800 722 6001 em caso de dúvida.',
  'Não necessário em áreas abertas ou árvores de quintal; chame os Bombeiros (193) apenas se o animal entrar dentro da residência e não conseguir sair.',
  'Instituto Butantan',
  'https://butantan.gov.br/bubutantan/conheca-a-cobra-cipo-a-serpente-que-gosta-de-viver-em-arvores-e-arbustos-',
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Cobra-de-duas-cabeças (Amphisbaena alba)
update public.species set slug = 'amphisbaena-alba'
  where scientific_name = 'Amphisbaena alba' and slug <> 'amphisbaena-alba'
  and not exists (select 1 from public.species s where s.slug = 'amphisbaena-alba');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'amphisbaena-alba',
  'Cobra-de-duas-cabeças',
  'Amphisbaena alba',
  'harmless',
  false,
  'reptil',
  array['Cobra-cega', 'Ibijara', 'Mãe-das-saúvas']::text[],
  array['marrom-claro', 'amarelado', 'rosado', 'esbranquiçado']::text[],
  'Corpo cilíndrico todo marcado por anéis como uma minhoca grande, sem patas, com a cauda grossa e arredondada igual à cabeça.',
  array['Cobra-de-vidro (Ophiodes fragilis): também inofensiva, porém tem escamas lisas e brilhantes (não anéis como minhoca) e olhos bem visíveis que piscam.', 'Cecília ou cobra-cega verdadeira (Siphonops annulatus): é um anfíbio úmido e liso de cor azul-escura com anéis brancos, igualmente subterrâneo e sem risco de picada.']::text[],
  'Apesar do nome popular, não é uma serpente e não possui duas cabeças: trata-se de um réptil subterrâneo chamado anfisbena, parente próximo dos lagartos. É frequentemente morta com enxadas quando aparece durante capinas e obras no quintal porque as pessoas acham que é uma cobra venenosa.',
  'Mede entre 40 e 60 cm, tem a pele dividida em pequenos quadradinhos formando anéis ao longo de todo o corpo e olhos minúsculos cobertos por pele, parecidos com dois pontinhos pretos. Sua cauda é curta, grossa e arredondada exatamente como a cabeça; quando ameaçada, ela levanta a cauda imitando uma cabeça para enganar predadores. Alimenta-se de formigas, cupins, larvas de besouros e minhocas debaixo da terra.',
  'Vive quase toda a vida enterrada no solo, dentro de formigueiros (especialmente de saúvas), cupinzeiros e canteiros de terra fofa. Costuma sair à superfície apenas quando chove muito e os buracos alagam, ou quando alguém revira a terra do jardim.',
  'Não possui veneno de nenhum tipo e é totalmente inofensiva se deixada em paz no jardim. Porém, se alguém tentar segurá-la com as mãos, ela pode dar um beliscão forte e dolorido com a boca para se defender.',
  'Não mate o animal, pois ele ajuda a controlar formigas e cupins no terreno e ajuda a arejar a terra do quintal. Se ela aparecer na calçada após a chuva, use uma vassoura e uma pá para colocá-la delicadamente de volta em um canteiro de terra ou jardim, sem pegá-la diretamente com as mãos.',
  'Não necessário.',
  'Instituto Butantan',
  'https://publicacoeseducativas.butantan.gov.br/web/animais-venenosos/pages/pdf/animais_venenosos.pdf',
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Cobra-de-vidro (Ophiodes fragilis)
update public.species set slug = 'ophiodes-fragilis'
  where scientific_name = 'Ophiodes fragilis' and slug <> 'ophiodes-fragilis'
  and not exists (select 1 from public.species s where s.slug = 'ophiodes-fragilis');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'ophiodes-fragilis',
  'Cobra-de-vidro',
  'Ophiodes fragilis',
  'harmless',
  false,
  'reptil',
  array['Quebra-quebra', 'Licranço']::text[],
  array['marrom-claro', 'bronze', 'cinza', 'preto']::text[],
  'Corpo brilhante e liso com listras escuras ao longo das costas, sem patas da frente e com pálpebras que piscam.',
  array['Filhotes de serpentes em geral: as serpentes verdadeiras não piscam os olhos (não têm pálpebras móveis) e não soltam pedaços da cauda como a cobra-de-vidro.', 'Cobra-de-duas-cabeças (Amphisbaena alba): também inofensiva, mas tem o corpo anelado parecido com uma minhoca grande, olhos quase invisíveis e vive debaixo da terra.']::text[],
  'Apesar do nome popular e da aparência alongada, não é uma cobra, e sim um lagarto sem patas totalmente inofensivo. Recebe o nome de cobra-de-vidro porque solta facilmente a própria cauda quando é atacado ou segurado, parecendo quebrar em pedaços.',
  'Mede geralmente entre 20 e 30 cm, tem escamas muito lisas e brilhantes em tons de bronze ou marrom-claro com listras longitudinais escuras. Não possui patas dianteiras e suas patas traseiras são reduzidas a duas pequenas abas quase invisíveis perto da cauda. Diferente das cobras, possui pálpebras móveis (consegue fechar os olhos) e abertura de ouvido visível na lateral da cabeça.',
  'Muito comum em gramados, jardins, hortas, pastos, debaixo de vasos, folhas secas e pedras em áreas urbanas e rurais. Costuma aparecer bastante quando os moradores estão cortando a grama ou limpando o quintal.',
  'É um animal 100% inofensivo que não possui veneno nem dentes capazes de ferir uma pessoa. Ao contrário do que dizem as lendas populares, os pedaços da cauda que se soltam não se juntam novamente; a cauda apenas continua se mexendo sozinha por alguns minutos para distrair predadores enquanto o lagarto foge.',
  'Não mate nem segure o animal pela cauda, pois fazê-lo perder a cauda gasta muita energia que ele precisa para sobreviver. Se ele entrar dentro de casa, basta conduzi-lo delicadamente com uma vassoura macia e uma pá de lixo de volta para a grama ou jardim.',
  'Não necessário.',
  'Instituto Butantan',
  'https://butantan.gov.br/bubutantan/quando-o-nome-engana-conheca-as-cobras-que-nao-sao-cobras',
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Cobra-verde (Philodryas olfersii)
update public.species set slug = 'philodryas-olfersii'
  where scientific_name = 'Philodryas olfersii' and slug <> 'philodryas-olfersii'
  and not exists (select 1 from public.species s where s.slug = 'philodryas-olfersii');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'philodryas-olfersii',
  'Cobra-verde',
  'Philodryas olfersii',
  'caution',
  false,
  'serpente',
  array['Cobra-cipó-verde', 'Bojobi']::text[],
  array['verde-claro', 'marrom', 'amarelado']::text[],
  'Corpo todo verde-claro brilhante com uma faixa marrom-avermelhada no topo da cabeça e ao longo do meio das costas.',
  array['Cobra-cipó (Chironius exoletus): totalmente inofensiva, tem o corpo mais fino, olhos proporcionalmente maiores e não possui a listra marrom bem marcada no topo da cabeça.', 'Jararaca-verde (Bothrops bilineatus): serpente perigosa que não ocorre na região de São Roque e possui cabeça triangular com fosseta loreal entre o olho e a narina.']::text[],
  'Serpente diurna que vive em árvores e arbustos, muito confundida com as cobras-cipó totalmente inofensivas. Embora seja classificada como não peçonhenta de interesse médico grave, possui dentes no fundo da boca capazes de injetar uma toxina que causa reação local forte.',
  'Mede geralmente entre 80 cm e 1,2 metro, com corpo alongado, cabeça ovalada, olhos com pupila redonda e escamas lisas de cor verde-viva. Apresenta uma listra cor de ferrugem ou marrom no alto da cabeça que costuma seguir como uma linha pelo dorso. Alimenta-se de pequenos pássaros, pererecas, lagartos e camundongos.',
  'Muito comum em copas de árvores, arbustos de jardins, cercas-vivas, pomares e bordas de mata em chácaras e áreas periurbanas da região.',
  'Não causa morte nem exige aplicação de soro antiofídico, mas não deve ser manuseada como se fosse inofensiva. Se morder e conseguir encaixar os dentes do fundo da boca, sua saliva tóxica provoca dor intensa, inchaço importante, vermelhidão e manchas roxas no membro atingido.',
  'Nunca tente segurar uma cobra verde achando que ela não faz mal; apenas afaste-se e deixe que ela suba nas árvores e vá embora. Em caso de mordida, lave o local com água e sabão, nunca faça torniquete nem coloque substâncias caseiras e acione o SAMU 192 ou ligue para o Disque-Intoxicação 0800 722 6001 para avaliação médica dos sintomas.',
  'Não necessário se estiver em árvores do quintal; chame os Bombeiros pelo 193 se entrar dentro da residência.',
  'Instituto Butantan — Animais venenosos (guia educativo)',
  'https://publicacoeseducativas.butantan.gov.br/web/animais-venenosos/pages/pdf/animais_venenosos.pdf',
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Comigo-ninguém-pode (Dieffenbachia seguine)
update public.species set slug = 'dieffenbachia-seguine'
  where scientific_name = 'Dieffenbachia seguine' and slug <> 'dieffenbachia-seguine'
  and not exists (select 1 from public.species s where s.slug = 'dieffenbachia-seguine');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'dieffenbachia-seguine',
  'Comigo-ninguém-pode',
  'Dieffenbachia seguine',
  'danger',
  false,
  'planta',
  array['Aninga-do-pará', 'Dieffenbachia']::text[],
  array['verde-escuro', 'branco', 'amarelo-esverdeado']::text[],
  'Planta de caule grosso em gomos e folhas largas verdes rajadas com manchas brancas ou amareladas no centro.',
  array['Café-de-salão (Aglaonema commutatum): planta ornamental parecida, porém menor e de caule mais fino, que também é tóxica e exige os mesmos cuidados.', 'Taioba-mansa (Xanthosoma taioba): planta comestível que tem folhas totalmente verdes e sem manchas brancas; nunca confunda plantas ornamentais manchadas com verduras.']::text[],
  'Planta ornamental muito cultivada dentro de casas, varandas e comércios da região pela beleza de suas folhas e pela crença popular de proteção. É apontada pelos centros de toxicologia como a principal causadora de intoxicações acidentais por plantas no Brasil, atingindo principalmente crianças pequenas e cães.',
  'É uma planta herbácea ereta que pode atingir de 50 cm a 1,5 metro de altura, com caule cilíndrico verde marcado por anéis e folhas grandes, ovais e manchadas de branco ou creme. Todas as partes da planta (folhas, caule e seiva) contêm minúsculos cristais em formato de agulha chamados oxalato de cálcio, além de substâncias irritantes. Basta uma pequena mordida na folha ou o contato da mão suja de seiva nos olhos para disparar uma reação imediata.',
  'Muito presente em vasos dentro de salas, varandas, entradas de casas, jardins sombreados, praças e estabelecimentos comerciais.',
  'Mastigar qualquer pedaço da folha ou do caule causa queimação intensa imediata, salivação excessiva (baba), feridas na boca e inchaço rápido dos lábios, da língua e da garganta. Nos casos mais graves, o inchaço da garganta pode bloquear a passagem do ar e provocar asfixia e morte em crianças ou animais domésticos, enquanto a seiva nos olhos pode causar lesão na córnea.',
  'Mantenha os vasos fora do alcance de crianças pequenas e animais e use luvas ao podar. Se alguém mastigar ou engolir parte da planta, retire os restos da boca e enxágue-a com água, sem engolir. Não provoque vômito nem dê leite, óleo ou outros "antídotos" caseiros. Guarde um pedaço da planta para identificação e ligue para o Disque-Intoxicação 0800 722 6001; se houver inchaço na garganta ou falta de ar, acione o SAMU 192.',
  'Não necessário para a planta; em caso de ingestão com dificuldade para engolir ou respirar, acione o resgate médico pelo SAMU 192.',
  'Sinitox/Fiocruz — Plantas tóxicas',
  'https://sinitox.icict.fiocruz.br/plantas-toxicas',
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Copo-de-leite (Zantedeschia aethiopica)
update public.species set slug = 'zantedeschia-aethiopica'
  where scientific_name = 'Zantedeschia aethiopica' and slug <> 'zantedeschia-aethiopica'
  and not exists (select 1 from public.species s where s.slug = 'zantedeschia-aethiopica');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'zantedeschia-aethiopica',
  'Copo-de-leite',
  'Zantedeschia aethiopica',
  'caution',
  false,
  'planta',
  array['Jarro', 'Cala-branca']::text[],
  array['branco', 'amarelo', 'verde']::text[],
  'Planta de folhas verdes em forma de seta e uma grande estrutura branca enrolada como um copo ou funil com um miolo amarelo em pé.',
  array['Lírio-da-paz (Spathiphyllum wallisii): parecido pela flor branca com espiga interna, mas a parte branca do lírio-da-paz é aberta como uma folha e não enrolada em forma de copo; ambas são tóxicas.', 'Taioba (Xanthosoma taioba): tem folhas verdes grandes que podem lembrar um pé de copo-de-leite sem flores, por isso nunca colha folhas em beiras de brejos achando que é taioba sem certeza absoluta.']::text[],
  'Planta ornamental muito apreciada no clima ameno e úmido da região de São Roque e Ibiúna, onde cresce tanto em jardins quanto espontaneamente em beiras de riachos e brejos. Seu formato atraente chama muito a atenção de crianças pequenas, sendo uma causa frequente de acidentes domésticos.',
  'Atinge entre 50 cm e 1 metro de altura, com talos grossos e esponjosos e folhas grandes de cor verde-brilhante em formato de ponta de flecha. Sua ''flor'' característica é formada por uma folha branca enrolada em cone ao redor de uma espiga amarela central. Todas as partes da planta possuem cristais pontiagudos de oxalato de cálcio que ferem a mucosa da boca e da garganta.',
  'Muito comum em canteiros úmidos de jardins, beiras de lagos, nascentes, valas de água em chácaras e também em vasos e arranjos florais dentro de casa.',
  'Mastigar qualquer parte da planta causa dor e queimação imediatas na boca, salivação intensa, inchaço nos lábios e na língua, náuseas, vômitos e dificuldade para engolir. O contato da seiva com os olhos provoca dor forte, lacrimejamento, vermelhidão e pode machucar a córnea.',
  'Ensine as crianças a não levarem o copo-de-leite à boca e lave as mãos após mexer na planta. Se alguém mastigar ou engolir parte da planta, retire os restos da boca e enxágue-a com água, sem engolir. Não provoque vômito nem dê leite, óleo ou outros "antídotos" caseiros. Guarde um pedaço da planta para identificação e ligue para o Disque-Intoxicação 0800 722 6001; se houver inchaço na garganta ou falta de ar, acione o SAMU 192.',
  'Não necessário.',
  'TOXCEN/CIATox-ES — Plantas tóxicas',
  'https://ciatox.es.gov.br/Media/toxcen/Material%20Informativo/5-Plantas%20t%C3%B3xicas.pdf',
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Coral-verdadeira (Micrurus corallinus)
update public.species set slug = 'micrurus-corallinus'
  where scientific_name = 'Micrurus corallinus' and slug <> 'micrurus-corallinus'
  and not exists (select 1 from public.species s where s.slug = 'micrurus-corallinus');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'micrurus-corallinus',
  'Coral-verdadeira',
  'Micrurus corallinus',
  'danger',
  false,
  'serpente',
  array['Cobra-coral', 'Ibiboboca']::text[],
  array['vermelho', 'preto', 'branco']::text[],
  'Anéis completos ao redor do corpo intercalando vermelho, branco, preto, branco e vermelho, com olhos bem pequenos.',
  array['Falsa-coral (Oxyrhopus guibei): não causa acidentes graves, tem a barriga toda branca (os anéis não fecham embaixo) e olhos maiores.', 'Falsa-coral (Erythrolamprus aesculapii): possui anéis completos, mas geralmente apresenta anéis pretos em pares separados por branco; na dúvida, trate toda coral como verdadeira.']::text[],
  'É a coral-verdadeira mais comum nas áreas de Mata Atlântica do estado de São Paulo. Trata-se de uma serpente tímida, de hábito subterrâneo, que não dá bote a distância e só pica se for pisada ou segurada na mão.',
  'Serpente de pequeno a médio porte (entre 50 e 80 cm), com corpo cilíndrico, cabeça arredondada que não se destaca do pescoço e cauda curta. Seus olhos são minúsculos, pretos, quase da mesma cor da mancha preta da cabeça. Como as regras populares para diferenciar da falsa-coral falham na prática, qualquer serpente colorida em anéis deve ser tratada com máximo cuidado.',
  'Vive escondida debaixo da terra fofa, folhas caídas (serapilheira), troncos podres e raízes em matas e jardins arborizados. Costuma aparecer em quintais e calçadas após dias de chuva forte ou durante serviços de jardinagem e capina.',
  'Possui um dos venenos mais letais do Brasil, que paralisa rapidamente o sistema nervoso. Os sintomas incluem dormência no local, visão turva, pálpebras caídas, dificuldade para engolir e paralisia dos músculos da respiração, podendo levar à parada respiratória em poucas horas.',
  'Nunca toque, pegue na mão ou tente examinar a barriga de uma cobra-coral para ver se é verdadeira ou falsa. Se houver picada, mesmo que não doa, trate como emergência médica máxima: mantenha a vítima deitada, acione o SAMU 192 imediatamente e ligue para o Disque-Intoxicação 0800 722 6001.',
  'Caso esteja em jardim residencial ou dentro de casa, mantenha crianças e cães longe e acione os Bombeiros (193) ou o setor de fauna municipal.',
  'Instituto Butantan',
  'https://butantan.gov.br/bubutantan/quietinha-e-mortal-conheca-o-poder-da-coral-verdadeira-uma-das-serpentes-mais-toxicas-do-brasil',
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Coroa-de-cristo (Euphorbia milii)
update public.species set slug = 'euphorbia-milii'
  where scientific_name = 'Euphorbia milii' and slug <> 'euphorbia-milii'
  and not exists (select 1 from public.species s where s.slug = 'euphorbia-milii');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'euphorbia-milii',
  'Coroa-de-cristo',
  'Euphorbia milii',
  'caution',
  false,
  'planta',
  array['Dois-irmãos', 'Bem-casados']::text[],
  array['vermelho', 'rosa', 'amarelo', 'verde', 'marrom']::text[],
  'Arbusto cheio de espinhos longos e pontiagudos nos galhos, com folhas verdes nas pontas e pequenas flores vermelhas, rosas ou amarelas.',
  array['Bico-de-papagaio (Euphorbia pulcherrima): parente próxima da mesma família que não tem espinhos, mas também solta o mesmo leite branco irritante quando quebrada.']::text[],
  'Planta espinhosa muito usada como cerca-viva de proteção sobre muros e grades em casas e chácaras da região. Além do risco de furar a pele nos espinhos, seus galhos e folhas soltam um leite branco (látex) bastante cáustico e irritante quando são quebrados ou podados.',
  'É um arbusto lenhoso e ramificado que atinge de 50 cm a 1,5 metro de altura, coberto por espinhos rígidos e afiados de 2 a 3 cm de comprimento. Apresenta folhas ovais verdes concentradas na parte superior dos ramos e pequenas estruturas florais duplas (geralmente vermelhas, rosadas ou amareladas) durante todo o ano. Qualquer corte no caule ou folha faz escorrer imediatamente uma seiva leitosa branca e pegajosa.',
  'Plantada ao longo de muros, cercas, calçadas, canteiros ensolarados e floreiras externas em áreas urbanas e rurais.',
  'O leite branco (látex) da planta causa forte irritação na pele, com vermelhidão, coceira, queimação e pequenas bolhas. Se a pessoa sujar os dedos nesse leite durante uma poda e coçar os olhos, ocorre dor intensa, inchaço nas pálpebras e lesão grave na córnea (podendo prejudicar a visão temporariamente); já a ingestão causa inchaço nos lábios e língua, náuseas, vômitos e diarreia.',
  'Use sempre luvas grossas e óculos de proteção ao podar cercas de coroa-de-cristo e lave os braços e mãos com água e sabão logo após o serviço. Se o leite cair nos olhos, lave imediatamente os olhos abertos com água corrente limpa por pelo menos 15 minutos e procure um médico oftalmologista ou pronto-socorro; em caso de ingestão ou acidente ocular, ligue para o Disque-Intoxicação 0800 722 6001 ou acione o SAMU 192.',
  'Não necessário.',
  'Sinitox/Fiocruz — Plantas tóxicas',
  'https://sinitox.icict.fiocruz.br/plantas-toxicas',
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Dormideira (Dipsas mikanii)
update public.species set slug = 'dipsas-mikanii'
  where scientific_name = 'Dipsas mikanii' and slug <> 'dipsas-mikanii'
  and not exists (select 1 from public.species s where s.slug = 'dipsas-mikanii');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'dipsas-mikanii',
  'Dormideira',
  'Dipsas mikanii',
  'harmless',
  false,
  'serpente',
  array['Jararaquinha-dormideira', 'Papa-lesma', 'Cobra-dormideira']::text[],
  array['marrom', 'bege', 'preto', 'cinza']::text[],
  'Cobra pequena e fina com manchas escuras arredondadas ou em faixas pelo corpo e cabeça pequena sem o buraquinho (fosseta) entre o olho e a narina.',
  array['Filhote de jararaca (Bothrops jararaca): espécie perigosa que possui cabeça bem triangular, fosseta loreal entre o olho e a narina e ponta da cauda branca nos filhotes.', 'Boipeva (Xenodon merremii): também inofensiva, porém tem o corpo muito mais grosso e largo que a dormideira.']::text[],
  'Pequena serpente não peçonhenta muito comum em hortas e jardins da região, onde presta um grande serviço comendo lesmas e caracóis. Infelizmente, é uma das cobras inofensivas mais mortas pelos moradores por ser confundida com filhotes de jararaca.',
  'Mede geralmente entre 30 e 50 cm, tem o corpo fino, cabeça arredondada e olhos grandes voltados para os lados. É um animal muito calmo e lento durante o dia (daí o nome dormideira), que sequer tenta morder mesmo quando tocado, limitando-se a esconder a cabeça debaixo do próprio corpo. Quando ameaçada, pode achatar um pouco a cabeça para parecer uma jararaca e afastar predadores.',
  'Muito frequente em hortas, canteiros de alface, vasos de plantas, gramados úmidos e debaixo de tijolos ou madeiras em quintais urbanos e chácaras.',
  'É totalmente inofensiva para seres humanos e animais domésticos, pois não possui veneno perigoso nem dentes inoculadores, além de raramente tentar morder. Porém, como é muito parecida com uma jararaca jovem aos olhos de quem não é especialista, nunca deve ser manuseada com as mãos.',
  'Nunca mate a dormideira: ela ajuda a controlar lesmas da horta. Como é muito parecida com filhote de jararaca, não tente tocar nem empurrar: afaste-se e deixe que ela siga seu caminho. Em caso de mordida por qualquer cobra manchada, lave com água e sabão, não faça torniquete e acione o SAMU 192 ou ligue para o Disque-Intoxicação 0800 722 6001.',
  'Não necessário se estiver no jardim ou horta; chame os Bombeiros pelo 193 caso esteja dentro de casa e você não saiba identificar se é uma jararaca.',
  'Instituto Butantan',
  'https://butantan.gov.br/bubutantan/voce-ja-ouviu-falar-das-falsas-jararacas-conheca-especies-que-imitam-a-serpente-peconhenta-mas-sao-inofensivas',
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Escorpião-amarelo (Tityus serrulatus)
update public.species set slug = 'tityus-serrulatus'
  where scientific_name = 'Tityus serrulatus' and slug <> 'tityus-serrulatus'
  and not exists (select 1 from public.species s where s.slug = 'tityus-serrulatus');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'tityus-serrulatus',
  'Escorpião-amarelo',
  'Tityus serrulatus',
  'danger',
  false,
  'escorpiao',
  array['Escorpião-amarelo-do-sudeste']::text[],
  array['amarelo-claro', 'marrom-escuro']::text[],
  'Corpo e pernas amarelo-claros, com o tronco um pouco mais escuro e pequenos espinhos (serrilha) na cauda antes do ferrão.',
  array['Escorpião-marrom (Tityus bahiensis): também perigoso, porém tem o corpo marrom-avermelhado e manchas escuras bem visíveis nas pernas e pinças.', 'Escorpião-preto-de-jardim (Bothriurus bonariensis): pouco perigoso, pequeno, todo preto e de cauda grossa sem espinho duplo sob o ferrão.']::text[],
  'É o escorpião de maior importância médica do Brasil e tem se espalhado rapidamente pelas áreas urbanas da região. Como é formado apenas por fêmeas que se reproduzem sozinhas sem precisar de macho, um único indivíduo pode gerar uma infestação na casa.',
  'Mede de 5 a 7 cm de comprimento e possui pernas, pinças e cauda de cor amarelo-palha uniforme, sem manchas escuras. O tronco (dorso) é castanho-escuro. Nos últimos anéis da cauda, apresenta pequenos dentes que formam uma serrilha visível e um espinho extra embaixo do ferrão.',
  'Muito comum em áreas urbanas, redes de esgoto, ralos, caixas de gordura, terrenos baldios com entulho e cemitérios. Entra facilmente nas casas pelos ralos do banheiro e da cozinha ou por frestas sob as portas em busca de baratas.',
  'A picada provoca dor imediata muito forte, sensação de queimação e formigamento. Em crianças pequenas (especialmente menores de 10 anos), o veneno pode ser fatal em poucas horas, causando vômitos intensos, suor excessivo, agitação, arritmia cardíaca e água no pulmão.',
  'Mantenha ralos fechados (tipo abre-fecha), vede frestas de portas e evite acúmulo de entulho que atraia baratas. Em caso de picada, lave o local com água e sabão, faça compressa morna e leve a vítima ao pronto-socorro imediatamente (principalmente se for criança); acione o SAMU 192 ou ligue para o Disque-Intoxicação 0800 722 6001.',
  'Não acione Bombeiros para captura individual, mas comunique a Vigilância Epidemiológica / Zoonoses do município sempre que encontrar escorpiões no imóvel.',
  'Instituto Butantan',
  'https://www.butantan.gov.br/bubutantan/resistentes-e-antigos-no-planeta-terra-conheca-9-curiosidades-dos-escorpioes',
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Escorpião-marrom (Tityus bahiensis)
update public.species set slug = 'tityus-bahiensis'
  where scientific_name = 'Tityus bahiensis' and slug <> 'tityus-bahiensis'
  and not exists (select 1 from public.species s where s.slug = 'tityus-bahiensis');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'tityus-bahiensis',
  'Escorpião-marrom',
  'Tityus bahiensis',
  'danger',
  false,
  'escorpiao',
  array['Escorpião-preto', 'Escorpião-do-mato']::text[],
  array['marrom-escuro', 'avermelhado', 'amarelo-queimado']::text[],
  'Corpo marrom-escuro com pernas mais claras marcadas por manchas pretas e pinças mais grossas com ponta escura.',
  array['Escorpião-amarelo (Tityus serrulatus): também perigoso, mas tem pernas e pinças totalmente amarelas, sem manchas escuras.', 'Vinagreiro ou escorpião-vinagre (Mastigoproctus sp.): inofensivo, não tem ferrão na cauda (apenas um fio fino) e solta cheiro de vinagre.']::text[],
  'Espécie nativa da Mata Atlântica e do interior paulista, muito frequente nas chácaras, sítios e bairros arborizados de São Roque e Ibiúna. Diferente do escorpião-amarelo, possui machos e fêmeas e prefere ambientes um pouco mais úmidos e com vegetação.',
  'Mede cerca de 6 a 7 cm, com o tronco marrom bem escuro ou quase preto e a cauda marrom-avermelhada. Suas pernas são amareladas com manchas pretas bem marcadas, e as pinças são um pouco mais gordinhas nas pontas com uma mancha escura. Também apresenta um pequeno espinho embaixo do ferrão.',
  'Vive em barrancos, sob cascas de árvores, pedras, cupinzeiros, pilhas de lenha e telhas em áreas rurais ou de borda de mata. Entra em casas de campo e chácaras, escondendo-se em botas de trabalho, luvas, panos de chão e frestas de madeira.',
  'Sua picada causa dor local intensa e imediata, parecida com uma queimadura ou agulhada forte, além de vermelhidão e formigamento. Embora seu veneno seja considerado um pouco menos potente que o do escorpião-amarelo, ainda pode causar quadros graves com vômitos e alterações cardíacas em crianças pequenas.',
  'Use luvas grossas de couro ao mexer em lenha, tijolos ou jardinagem e bata os calçados antes de calçar. Se for picado, lave apenas com água e sabão, aplique compressa morna para diminuir a dor e busque avaliação médica rápida; acione o SAMU 192 ou ligue para o Disque-Intoxicação 0800 722 6001.',
  'Não necessário acionar resgate; se houver aparecimento frequente na residência, solicite vistoria da Zoonoses municipal.',
  'Instituto Butantan — Animais venenosos (guia educativo)',
  'https://publicacoeseducativas.butantan.gov.br/web/animais-venenosos/pages/pdf/animais_venenosos.pdf',
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Espada-de-são-jorge (Dracaena trifasciata)
update public.species set slug = 'dracaena-trifasciata'
  where scientific_name = 'Dracaena trifasciata' and slug <> 'dracaena-trifasciata'
  and not exists (select 1 from public.species s where s.slug = 'dracaena-trifasciata');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'dracaena-trifasciata',
  'Espada-de-são-jorge',
  'Dracaena trifasciata',
  'caution',
  false,
  'planta',
  array['Língua-de-sogra', 'Rabo-de-lagarto', 'Espada-de-santa-bárbara']::text[],
  array['verde-escuro', 'verde-claro', 'amarelo']::text[],
  'Folhas duras, grossas e compridas que crescem retas para cima como espadas, rajadas em tons de verde (às vezes com bordas amarelas).',
  array['Lança-de-são-jorge (Dracaena angolensis): parente próxima da mesma família que tem folhas cilíndricas e roliças em vez de achatadas, apresentando a mesma toxicidade leve a moderada.', 'Babosa (Aloe vera): planta suculenta que tem pequenos dentes nas bordas da folha e gel transparente por dentro, enquanto a espada-de-são-jorge é fibrosa, seca e lisa nas bordas.']::text[],
  'Planta ornamental extremamente resistente e popular nas entradas de casas, apartamentos e jardins da região, muito associada à tradição popular de proteção do lar. Está na lista das plantas domésticas que causam intoxicações em crianças pequenas e principalmente em cães e gatos.',
  'Cresce em touceiras diretamente do chão ou do vaso, com folhas rígidas, fibrosas e pontiagudas que medem de 40 cm a 1 metro de altura. A variedade tradicional é rajada de verde-escuro e verde-acinzentado, enquanto a variedade chamada espada-de-santa-bárbara possui faixas amarelas nas bordas. Contém substâncias chamadas saponinas e cristais irritantes em sua seiva.',
  'Muito comum em vasos na porta de entrada das casas, salas, varandas, calçadas e canteiros de jardins urbanos e rurais.',
  'Possui toxicidade moderada: mastigar suas folhas causa irritação e ardência na boca, salivação intensa (baba), náuseas, vômitos e diarreia. Em cães e gatos que mordem as pontas das folhas por brincadeira, o quadro de vômitos e salivação é bastante frequente.',
  'Evite deixar vasos no chão em locais onde bebês engatinham ou onde filhotes de cães e gatos costumam roer plantas. Se uma criança mastigar a folha, limpe a boca com água corrente, ofereça pequenos goles de água e ligue para o Disque-Intoxicação 0800 722 6001 para orientação (ou acione o SAMU 192 se houver dificuldade para engolir ou respirar).',
  'Não necessário.',
  'Secretaria Municipal da Saúde de São Paulo',
  'https://prefeitura.sp.gov.br/web/saude/w/noticias/340114',
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Espirradeira (Nerium oleander)
update public.species set slug = 'nerium-oleander'
  where scientific_name = 'Nerium oleander' and slug <> 'nerium-oleander'
  and not exists (select 1 from public.species s where s.slug = 'nerium-oleander');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'nerium-oleander',
  'Espirradeira',
  'Nerium oleander',
  'danger',
  false,
  'planta',
  array['Oleandro', 'Louro-rosa', 'Adelfa']::text[],
  array['verde', 'rosa', 'branco', 'vermelho']::text[],
  'Arbusto lenhoso com folhas compridas e estreitas em forma de lança e cachos de flores muito vistosas cor-de-rosa, brancas ou vermelhas.',
  array['Louro-de-cozinha (Laurus nobilis): usado como tempero, tem folhas mais largas e ovais com cheiro aromático forte quando amassadas, enquanto as folhas da espirradeira são longas, estreitas e nunca devem ser usadas em alimentos ou chás.', 'Chapéu-de-napoleão (Cascabela thevetia): também é um arbusto altamente tóxico para o coração, mas tem folhas ainda mais finas e flores amarelas em forma de sino.']::text[],
  'Arbusto ornamental muito plantado em calçadas, praças, jardins e cercas-vivas de toda a região por ser rústico e florir quase o ano todo. Apesar da aparência comum e das flores bonitas, é uma das plantas mais venenosas que existem no ambiente urbano.',
  'Pode crescer como arbusto ou arvoreta de 2 a 5 metros de altura, com folhas verdes-acinzentadas duras, longas e pontiagudas que saem em grupos de três no ramo. Suas flores formam buquês nas pontas dos galhos nas cores rosa, branca ou vermelha. Todas as partes da planta — folhas, flores, galhos secos, raízes e até a fumaça de sua queima — possuem substâncias (glicosídeos cardíacos) que afetam diretamente os batimentos do coração.',
  'Muito comum em calçadas, canteiros centrais de avenidas, praças públicas, entradas de chácaras e jardins residenciais.',
  'Pequenas quantidades de folhas ou flores (ou o uso dos galhos como espeto para assar alimentos) podem causar intoxicação grave em crianças, adultos e animais. Os sintomas começam com queimação na boca, salivação, náuseas, vômitos, cólicas e diarreia e podem evoluir para arritmia cardíaca, queda de pressão e parada cardíaca.',
  'Nunca coloque flores ou folhas de espirradeira na boca, não faça chás caseiros, use luvas ao podar e jamais queime seus galhos secos nem os utilize como espeto de churrasco. Em caso de ingestão de qualquer parte da planta, não provoque vômito, leve a pessoa imediatamente ao pronto-socorro e acione o SAMU 192 ou ligue para o Disque-Intoxicação 0800 722 6001.',
  'Não necessário para a planta; em caso de ingestão, acione imediatamente o SAMU 192.',
  'Sinitox/Fiocruz — Plantas tóxicas',
  'https://sinitox.icict.fiocruz.br/plantas-toxicas',
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Falsa-coral (Oxyrhopus guibei)
update public.species set slug = 'oxyrhopus-guibei'
  where scientific_name = 'Oxyrhopus guibei' and slug <> 'oxyrhopus-guibei'
  and not exists (select 1 from public.species s where s.slug = 'oxyrhopus-guibei');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'oxyrhopus-guibei',
  'Falsa-coral',
  'Oxyrhopus guibei',
  'harmless',
  false,
  'serpente',
  array['Coral-falsa', 'Cobra-coral-falsa']::text[],
  array['vermelho', 'preto', 'branco']::text[],
  'Anéis vermelhos, pretos e brancos pelo dorso que não dão a volta completa na barriga, a qual é geralmente toda clara.',
  array['Coral-verdadeira (Micrurus corallinus): espécie perigosa com anéis completos ao redor do corpo e olhos muito pequenos; como a identificação visual pode falhar, nunca toque em nenhuma cobra de padrão coral.', 'Falsa-coral (Erythrolamprus aesculapii): outra imitadora da coral que pode causar inchaço e dor local leve se morder.']::text[],
  'Serpente não peçonhenta muito comum na Mata Atlântica e bem adaptada a áreas urbanas e periurbanas da região. Infelizmente, é uma das cobras mais mortas pela população por imitar as cores da coral-verdadeira para se proteger de predadores.',
  'Mede cerca de 60 cm a 1 metro, tem o corpo cilíndrico e apresenta conjuntos de três anéis pretos separados por anéis brancos e vermelhos. A ponta do focinho costuma ser escura e a barriga é esbranquiçada, sem o fechamento completo dos anéis. É um animal manso que passa o dia escondido e sai à noite para caçar lagartos, pequenos roedores e ovos.',
  'Ocorre em fragmentos de mata, terrenos baldios, jardins, hortas, pilhas de telhas e entulhos em áreas rurais e urbanas. Pode entrar em quintais e garagens à procura de abrigo ou alimento.',
  'Não representa risco de vida aos seres humanos, sendo considerada não peçonhenta pelo Instituto Butantan. Ainda assim, como qualquer pessoa leiga pode confundi-la com uma coral-verdadeira, o contato direto nunca deve acontecer.',
  'Nunca tente pegar na mão ou virar a serpente para olhar a barriga, tratando toda cobra com anéis coloridos à distância por precaução. Caso ocorra uma mordida, lave o local com água e sabão, não faça torniquete e acione o SAMU 192 ou ligue para o Disque-Intoxicação 0800 722 6001 para avaliação médica, pois só um profissional pode descartar acidente por coral-verdadeira.',
  'Se estiver dentro de casa ou em pátio fechado sem saída para a mata, isole o local e acione os Bombeiros pelo 193 ou a patrulha ambiental do município.',
  'Instituto Butantan',
  'https://butantan.gov.br/bubutantan/disfarcando-as-evidencias-veja-diferencas-entre-a-coral-verdadeira-e-a-falsa-coral-e-conheca-algumas-especies',
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Gambá-de-orelha-preta (Didelphis aurita)
update public.species set slug = 'didelphis-aurita'
  where scientific_name = 'Didelphis aurita' and slug <> 'didelphis-aurita'
  and not exists (select 1 from public.species s where s.slug = 'didelphis-aurita');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'didelphis-aurita',
  'Gambá-de-orelha-preta',
  'Didelphis aurita',
  'harmless',
  false,
  'mamifero',
  array['Saruê', 'Sariguê', 'Timbu', 'Mucura']::text[],
  array['preto', 'cinza', 'amarelo-esbranquiçado']::text[],
  'Mamífero peludo com orelhas grandes totalmente pretas, focinho pontudo, máscara escura no rosto e cauda longa quase sem pelos.',
  array['Ratazana (Rattus norvegicus): as pessoas confundem os dois à noite por causa da cauda pelada, mas o gambá não é um roedor, é muito maior, caminha devagar e tem bolsa (marsúpio) na barriga como os cangurus.', 'Gambá-de-orelha-branca (Didelphis albiventris): espécie parente muito parecida e igualmente inofensiva, diferenciada por ter as orelhas brancas ou rosadas e faixas brancas bem marcadas na cabeça.']::text[],
  'Mamífero marsupial nativo da Mata Atlântica e muito benéfico para os moradores: come escorpiões, insetos e até serpentes peçonhentas, como a jararaca. Infelizmente é muito morto ou atacado por cães porque as pessoas o confundem com um rato gigante ou se assustam quando ele mostra os dentes.',
  'Tem o porte aproximado de um gato pequeno a médio, pelagem grossa grisalha ou preta-amarelada, orelhas pretas sem pelos e cauda preênsil (que se enrola em galhos). As fêmeas carregam os filhotes ainda bem pequenos dentro de uma bolsa na barriga e, depois que crescem, agarrados nas costas. Quando assustado, não ataca: ele abre a boca mostrando os dentes, emite um som rouco, solta um cheiro forte ou finge estar morto até o perigo passar.',
  'Tem hábito noturno e vive em matas, árvores, forros de telhados, ocos de troncos e muros de casas e chácaras. Costuma descer aos quintais à noite atraído por árvores frutíferas, lixeiras destampadas ou potes de ração de cães e gatos.',
  'É um animal inofensivo e dócil que só morde se alguém tentar segurá-lo com as mãos. Seu papel no quintal é um verdadeiro serviço de proteção para a família, já que possui resistência natural ao veneno de jararacas e consome pragas perigosas.',
  'Nunca mate nem machuque o gambá; se encontrá-lo no quintal, prenda os cachorros dentro de casa e apague as luzes para que ele suba no muro e vá embora sozinho. Caso encontre uma fêmea morta (por atropelamento ou ataque de cão), verifique com cuidado sem tocar diretamente se há filhotes vivos na bolsa da barriga e acione o resgate de fauna.',
  'Acione a Guarda Ambiental, Polícia Ambiental ou CETRAS se o animal estiver ferido por cães, preso dentro da casa ou se forem encontrados filhotes órfãos.',
  'Instituto Butantan',
  'https://butantan.gov.br/bubutantan/gamba-e-um-dos-unicos-animais-imunes-ao-veneno-das-serpentes--saiba-por-que',
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Jararaca (Bothrops jararaca)
update public.species set slug = 'bothrops-jararaca'
  where scientific_name = 'Bothrops jararaca' and slug <> 'bothrops-jararaca'
  and not exists (select 1 from public.species s where s.slug = 'bothrops-jararaca');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'bothrops-jararaca',
  'Jararaca',
  'Bothrops jararaca',
  'danger',
  false,
  'serpente',
  array['Jararaca-da-mata', 'Jararaca-do-rabo-branco', 'Caissaca']::text[],
  array['marrom', 'bege', 'cinza', 'preto']::text[],
  'Manchas escuras triangulares pelo corpo que lembram a letra ''V'' invertida ou um gancho de telefone.',
  array['Jararacuçu-do-brejo (Palusophis bifossatus): inofensiva, tem cabeça menos triangular, olhos grandes com pupila redonda e não possui o buraquinho (fosseta loreal) entre o olho e a narina.', 'Boipeva (Xenodon merremii): inofensiva, achata o corpo contra o chão quando assustada, mas não tem fosseta loreal e tem pupila redonda.']::text[],
  'Serpente peçonhenta da Mata Atlântica e a maior causadora de acidentes com cobras no Brasil. Tem hábito principalmente noturno e passa o dia camuflada entre folhas secas.',
  'Mede geralmente entre 60 cm e 1,2 metro, com cabeça bem triangular e uma faixa escura atrás dos olhos. Possui um orifício chamado fosseta loreal entre o olho e a narina, que serve para sentir o calor das presas. Os filhotes têm a ponta da cauda clara, quase branca, usada para atrair sapos.',
  'Muito comum em bordas de mata, trilhas, chácaras, pilhas de lenha, entulhos e galinheiros. Pode entrar em garagens, varandas e quintais atrás de ratos.',
  'Sua picada é grave e causa dor forte imediata, inchaço, manchas roxas, bolhas e sangramentos na gengiva ou no local da picada. Sem tratamento rápido com soro antibotrópico, pode causar necrose, perda de tecido e complicações renais.',
  'Afaste-se devagar e nunca tente matar ou capturar a serpente, pois a maioria dos acidentes ocorre nesse momento. Em caso de picada, lave o local apenas com água e sabão, mantenha a vítima deitada e calma, nunca faça torniquete, corte ou chupe o local, e acione o SAMU 192 ou ligue para o Disque-Intoxicação 0800 722 6001 imediatamente.',
  'Se a serpente estiver dentro de casa ou em quintal fechado oferecendo risco, mantenha distância, isole o cômodo e chame os Bombeiros pelo 193 ou a Guarda Municipal Ambiental da sua cidade.',
  'Instituto Butantan',
  'https://butantan.gov.br/bubutantan/uma-jararaca-nada-comum-conheca-a-maior-causadora-de-acidentes-com-cobras-do-brasil',
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Javali (Sus scrofa)
update public.species set slug = 'sus-scrofa'
  where scientific_name = 'Sus scrofa' and slug <> 'sus-scrofa'
  and not exists (select 1 from public.species s where s.slug = 'sus-scrofa');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'sus-scrofa',
  'Javali',
  'Sus scrofa',
  'danger',
  true,
  'mamifero',
  array['Porco-monteiro', 'Javaporco']::text[],
  array['marrom-escuro', 'preto', 'acinzentado']::text[],
  'Mamífero de grande porte, corpo robusto e pelagem densa escura, com focinho alongado tipo focinho de porco e presas visíveis nos machos.',
  array['Porco doméstico criado solto (Sus domesticus): parentes muito próximos que podem ter pelagem malhada ou clara; javalis puros têm o corpo mais afilado na parte traseira e cerdas eriçadas nas costas.']::text[],
  'Mamífero exótico invasor de origem europeia e asiática que se adaptou perfeitamente às matas e áreas rurais do interior paulista, procriando em grandes bandos. É um animal de comportamento agressivo quando acossado, destruindo plantações e competindo com a fauna nativa.',
  'Pode pesar mais de 150 kg, possui cabeça grande, pescoço curto, pernas finas e fortes cerdas pretas ou marrons cobrindo o corpo. Os filhotes nascem com listras longitudinais claras no corpo (como pequenos ''pijamas''). Possui olfato e audição extremamente apurados e pode correr a grandes velocidades quando acuado ou defendendo os filhotes.',
  'Vive em matas fechadas, plantações de milho e cana, áreas de reflorestamento e bordas de riachos em zonas rurais e chácaras afastadas da região.',
  'Representa risco físico direto e grave caso alguém se aproxime de bandos com filhotes ou tente acuá-lo, pois suas presas afiadas e o peso corporal podem causar ferimentos lacerantes profundos, fraturas e hemorragias fatais.',
  'Caso aviste um javali ou um bando em trilhas ou áreas rurais, afaste-se imediatamente e procure subir em um local alto e seguro (como uma árvore resistente), pois eles podem atacar se sentirem o caminho de fuga bloqueado. Em caso de ataque com ferimentos graves e mordidas, estanque o sangramento imediato, acione o SAMU 192 ou resgate de emergência e procure um hospital cirúrgico de urgência.',
  'Acione a Polícia Militar Ambiental ou os órgãos competentes de controle de fauna para manejo de espécies invasoras em áreas rurais habitadas.',
  'Ibama',
  'https://www.gov.br/ibama/pt-br/assuntos/biodiversidade/especies-exoticas-invasoras/manejo-e-controle-do-javali',
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Jiboia (Boa constrictor)
update public.species set slug = 'boa-constrictor'
  where scientific_name = 'Boa constrictor' and slug <> 'boa-constrictor'
  and not exists (select 1 from public.species s where s.slug = 'boa-constrictor');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'boa-constrictor',
  'Jiboia',
  'Boa constrictor',
  'harmless',
  false,
  'serpente',
  array['Jiboia-constritora', 'Cobra-de-veado']::text[],
  array['marrom', 'bege', 'preto', 'avermelhado']::text[],
  'Serpente robusta e pesada com manchas ovais claras cercadas de marrom ao longo das costas e desenhos mais avermelhados perto da cauda.',
  array['Cascavel (Crotalus durissus): espécie perigosa que possui escamas ásperas, buraquinho (fosseta loreal) entre o olho e a narina e um chocalho na ponta da cauda.', 'Jararaca (Bothrops jararaca): espécie perigosa bem mais fina, com desenhos triangulares nas laterais do corpo e fosseta loreal no rosto.']::text[],
  'Serpente de grande porte, lenta e totalmente desprovida de veneno, que captura suas presas se enrolando nelas (constrição). Embora assuste pelo tamanho e pelo formato triangular da cabeça, é um animal calmo que controla populações de ratos e gambás.',
  'Pode ultrapassar 2 a 3 metros de comprimento na fase adulta, tendo o corpo grosso e musculoso coberto por escamas pequenas e macias. Sua cabeça destaca-se bastante do pescoço, formando um triângulo, mas não possui a fosseta loreal típica das cobras venenosas. Quando ameaçada, pode soltar o ar com força fazendo um barulho alto de sopro (''baforada'') para afastar curiosos.',
  'Vive tanto no chão quanto em galhos de árvores em matas, bordas de floresta e áreas rurais. Às vezes aparece em chácaras, galinheiros ou próxima a estradas da região.',
  'Não possui veneno nem dentes inoculadores (dentição áglifa) e não oferece risco de morte para seres humanos. Porém, por ser grande e ter vários dentes curvos voltados para trás, uma mordida de defesa ao tentar segurá-la causa cortes doloridos que sangram e podem infeccionar.',
  'Mantenha distância, prenda os cães e nunca tente pegar a jiboia com as mãos ou matá-la. Em caso de mordida acidental, lave bem o ferimento com água e sabão, faça curativo limpo e procure atendimento médico para avaliar risco de infecção ou ligue para o Disque-Intoxicação 0800 722 6001.',
  'Acione os Bombeiros pelo 193 ou a Polícia Ambiental sempre que encontrar uma jiboia em área residencial ou chácara, para que façam o resgate seguro.',
  'Instituto Butantan',
  'https://jogoquarteto.butantan.gov.br/default.php?page=cards&subPage=serpentes-nao-peconhentas.php',
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Lagarta-cachorrinho (Megalopyge lanata)
update public.species set slug = 'megalopyge-lanata'
  where scientific_name = 'Megalopyge lanata' and slug <> 'megalopyge-lanata'
  and not exists (select 1 from public.species s where s.slug = 'megalopyge-lanata');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'megalopyge-lanata',
  'Lagarta-cachorrinho',
  'Megalopyge lanata',
  'caution',
  false,
  'lagarta',
  array['Taturana-gatinho', 'Lagarta-de-fogo']::text[],
  array['branco', 'preto', 'vermelho', 'marrom']::text[],
  'Lagarta coberta por pelos longos e sedosos (brancos ou marrons) que parecem um chumaço de lã ou um cachorrinho peludo.',
  array['Lagarta-ursinho (família Erebidae): tem pelos curtos e escuros como uma escova, que podem dar alergia na pele, mas não têm espinhos venenosos escondidos por baixo.', 'Lagartas do gênero Podalia: são parentes diretas muito parecidas (todas marrons ou acinzentadas), também chamadas de lagarta-cachorrinho e com o mesmo risco de queimação intensa.']::text[],
  'Lagarta muito comum em jardins e pomares da região, cuja aparência fofa e peluda costuma atrair a curiosidade de crianças. Debaixo dos pelos longos e macios, ela esconde cerdas rígidas e pontiagudas cheias de veneno.',
  'Mede de 6 a 8 cm e tem o corpo dividido em gomos pretos e avermelhados, cobertos por longos pelos brancos ou castanhos que parecem fios de algodão ou pelo de cachorro. Caminha lentamente sobre folhas e muros. Quando vai virar mariposa, constrói um casulo marrom duro que ainda mantém pelos urticantes grudados por fora.',
  'Muito frequente em plantas ornamentais de jardins, cercas-vivas, muros e árvores frutíferas (mangueiras, goiabeiras, abacateiros e citros) em quintais urbanos e chácaras da região.',
  'Não causa sangramentos como a Lonomia, mas o toque provoca uma dor em queimação extremamente forte que se espalha pelo braço ou perna até a axila ou virilha (íngua dolorosa). Pode causar vermelhidão intensa, inchaço, febre, suor frio e mal-estar, sendo muito sofrido especialmente para crianças.',
  'Ensine as crianças a nunca tocarem em lagartas peludas, por mais bonitas ou fofas que pareçam. Em caso de acidente, lave o local com água fria e sabão, faça compressas frias para aliviar a dor intensa, nunca esfregue o local e procure um posto de saúde ou ligue para o Disque-Intoxicação 0800 722 6001 (ou acione o SAMU 192 se houver falta de ar ou reação forte).',
  'Não necessário; basta manter distância e aguardar que o animal siga seu ciclo na planta ou remova o galho usando luvas grossas e tesoura de poda longa.',
  'Instituto Butantan',
  'https://butantan.gov.br/noticias/criancas-sao-as-principais-vitimas-de-acidentes-com-lagartas--chegada-do-verao-e-das-ferias-escolares-acendem-sinal-de-alerta',
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Lebre-europeia (Lepus europaeus)
update public.species set slug = 'lepus-europaeus'
  where scientific_name = 'Lepus europaeus' and slug <> 'lepus-europaeus'
  and not exists (select 1 from public.species s where s.slug = 'lepus-europaeus');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'lepus-europaeus',
  'Lebre-europeia',
  'Lepus europaeus',
  'harmless',
  true,
  'mamifero',
  array['Lebre', 'Lebre-comum']::text[],
  array['marrom', 'amarelado', 'preto', 'branco']::text[],
  'Mamífero parecido com um coelho, porém muito maior, com pernas e orelhas compridas com pontas pretas, adaptado para correr em campos abertos.',
  array['Coelho-bravo ou tapiti (Sylvilagus brasiliensis): espécie nativa menor, com orelhas e pernas mais curtas, que vive na beira de matas e corre para se esconder rapidamente na vegetação densa.']::text[],
  'Espécie exótica invasora de origem europeia introduzida no Brasil para caça e que se estabeleceu em áreas agrícolas, pastagens e campos abertos da região. Compete por alimento com herbívoros nativos e pode causar prejuízos em plantações.',
  'Pode pesar entre 2 e 5 kg, apresentando pelagem marrom-acinzentada, orelhas longas com as pontas pretas marcantes e pernas traseiras extremamente longas e musculosas. Diferente dos coelhos, as lebres não cavam tocas subterrâneas; descansam sobre a superfície da terra (em depressões chamadas ninhos no capim) e confiam na camuflagem e na alta velocidade de corrida (podendo ultrapassar 70 km/h) para escapar de predadores.',
  'Campos abertos, pastagens, plantações de milho, soja, hortas rurais e beiras de estradas vicinais na zona rural dos municípios da região.',
  'Não possui veneno e não ataca seres humanos, sendo um animal arisco que foge imediatamente ao menor sinal de aproximação. O risco restringe-se a danos econômicos na agricultura e potencial vetor de ectoparasitas na zona rural.',
  'Apenas observe o animal à distância sem tentar capturá-lo, pois não oferece perigo físico direto às pessoas. Caso encontre um animal atropelado na rodovia rural, evite tocar diretamente com as mãos devido aos parasitas externos.',
  'Não necessário.',
  'Revisão da equipe EcoLens',
  null,
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Lírio-da-paz (Spathiphyllum wallisii)
update public.species set slug = 'spathiphyllum-wallisii'
  where scientific_name = 'Spathiphyllum wallisii' and slug <> 'spathiphyllum-wallisii'
  and not exists (select 1 from public.species s where s.slug = 'spathiphyllum-wallisii');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'spathiphyllum-wallisii',
  'Lírio-da-paz',
  'Spathiphyllum wallisii',
  'caution',
  false,
  'planta',
  array['Bandeira-branca', 'Espatifilo']::text[],
  array['verde-escuro', 'branco', 'amarelo-claro']::text[],
  'Touceira de folhas verdes brilhantes e alongadas com hastes que seguram uma ''pétala'' branca aberta e uma espiga clara no centro.',
  array['Copo-de-leite (Zantedeschia aethiopica): tem folhas em formato de seta e a parte branca da flor enrolada como um funil, enquanto no lírio-da-paz a parte branca é aberta como uma colher.', 'Lírio-verdadeiro (Lilium spp.): possui flores grandes com seis pétalas separadas e pólen alaranjado que solta pó, sendo extremamente letal para gatos (causa falência renal aguda nos felinos).']::text[],
  'Uma das plantas de sombra mais cultivadas dentro de salas, quartos e escritórios na região por florir mesmo com pouca luz. Apesar do nome tranquilo, faz parte da mesma família da comigo-ninguém-pode e do antúrio, causando irritação imediata se for mastigada.',
  'Mede entre 30 e 60 cm de altura, formando uma touceira densa de folhas lanceoladas (em forma de folha de árvore alongada) de cor verde-escura muito brilhante. Suas flores surgem acima da folhagem e são formadas por uma espiga creme cercada por uma folha modificada branca que vai ficando verde à medida que envelhece. Possui cristais de oxalato de cálcio em todas as suas partes.',
  'Muito presente em vasos no chão de salas, varandas sombreadas, corredores de casas, consultórios, igrejas e jardins de inverno.',
  'Quando mastigada por crianças pequenas ou animais de estimação, provoca dor e ardência imediata na boca, coceira, inchaço nos lábios e na língua e muita baba. Também pode causar dificuldade para engolir e vômitos se pedaços da planta forem engolidos.',
  'Coloque os vasos sobre suportes altos, fora do alcance de crianças pequenas e animais. Se alguém mastigar ou engolir parte da planta, retire os restos da boca e enxágue-a com água, sem engolir. Não provoque vômito nem dê leite, óleo ou outros "antídotos" caseiros. Guarde um pedaço da planta para identificação e ligue para o Disque-Intoxicação 0800 722 6001; se houver inchaço na garganta ou falta de ar, acione o SAMU 192.',
  'Não necessário.',
  'SINITOX / Fiocruz',
  'https://sinitox.icict.fiocruz.br/levantamento-revela-especies-que-mais-causam-intoxicacao-nos-pets',
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Mamona (Ricinus communis)
update public.species set slug = 'ricinus-communis'
  where scientific_name = 'Ricinus communis' and slug <> 'ricinus-communis'
  and not exists (select 1 from public.species s where s.slug = 'ricinus-communis');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'ricinus-communis',
  'Mamona',
  'Ricinus communis',
  'danger',
  false,
  'planta',
  array['Mamoneira', 'Carrapateira', 'Palma-de-cristo', 'Rícino']::text[],
  array['verde', 'avermelhado', 'marrom']::text[],
  'Arbusto alto com folhas grandes em formato de estrela (de 7 a 11 pontas) e cachos de frutos redondos cobertos por espinhos moles.',
  array['Mandioca (Manihot esculenta): também tem folhas divididas em pontas, mas os frutos da mandioca são lisos (sem espinhos) e suas folhas são mais estreitas.', 'Pinhão-roxo (Jatropha gossypiifolia): arbusto tóxico menor, com folhas arroxeadas de apenas 3 a 5 pontas e frutos lisos.']::text[],
  'Planta exótica que se espalhou por todo o Brasil e cresce espontaneamente com muita facilidade na região. As crianças costumam brincar de atirar seus frutos espinhosos (''guerra de mamona''), e o perigo ocorre quando alguém abre o fruto e mastiga as sementes de dentro, que parecem feijões rajados ou carrapatos.',
  'Arbusto grande que pode atingir de 1,5 a 4 metros de altura, com caules ocos (verdes ou avermelhados) e folhas largas recortadas em várias pontas com bordas serrilhadas. Seus frutos crescem em cachos e são cápsulas redondas cobertas por pontas macias que secam e se abrem no sol. Dentro de cada fruto ficam três sementes brilhantes e manchadas de marrom, preto e branco, onde se concentra uma toxina fortíssima chamada ricina.',
  'Muito comum em terrenos baldios, beiras de estradas, margens de córregos, entulhos, fundos de quintais e áreas rurais degradadas.',
  'As sementes são altamente venenosas quando mastigadas e engolidas, podendo ser fatais mesmo em pequena quantidade para crianças e animais. Os sintomas podem demorar algumas horas para aparecer e incluem queimadura na boca, náuseas, vômitos fortes, cólicas, diarreia com sangue, desidratação grave, convulsões, coma e morte.',
  'Oriente as crianças a nunca abrirem os frutos da mamona nem colocarem suas sementes na boca, e elimine pés de mamona de quintais onde circulem crianças pequenas ou cães. Em caso de ingestão de sementes, mesmo que a pessoa ainda não sinta nada, não provoque vômito, guarde um fruto ou folha para identificação, procure o pronto-socorro imediatamente e ligue para o Disque-Intoxicação 0800 722 6001 ou acione o SAMU 192.',
  'Não necessário para manejo da planta; acione o SAMU 192 em caso de ingestão de sementes.',
  'Sinitox/Fiocruz — Plantas tóxicas',
  'https://sinitox.icict.fiocruz.br/plantas-toxicas',
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Morcego-das-frutas (Platyrrhinus lineatus)
update public.species set slug = 'platyrrhinus-lineatus'
  where scientific_name = 'Platyrrhinus lineatus' and slug <> 'platyrrhinus-lineatus'
  and not exists (select 1 from public.species s where s.slug = 'platyrrhinus-lineatus');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'platyrrhinus-lineatus',
  'Morcego-das-frutas',
  'Platyrrhinus lineatus',
  'caution',
  false,
  'mamifero',
  array['Morcego-de-listra-branca', 'Morcego-frugívoro']::text[],
  array['marrom', 'branco', 'cinza-escuro']::text[],
  'Pequeno mamífero com asas de pele, uma linha branca nas costas e quatro listras brancas bem visíveis no rosto.',
  array['Morcego-vampiro (Desmodus rotundus): alimenta-se de sangue de animais de criação em áreas rurais; não possui listras brancas no rosto nem a pelinha em forma de folha na ponta do nariz, além de ter dentes da frente bem afiados.', 'Morcego-insetívoro-de-telhado (Molossus molossus): também não chupa sangue (come apenas insetos), é menor, todo marrom-escuro sem listras brancas e tem orelhas arredondadas.']::text[],
  'Pequeno mamífero voador que se alimenta exclusivamente de frutas, néctar e pólen, sendo fundamental para espalhar sementes e regenerar a Mata Atlântica da região. Muitas pessoas têm pavor de morcegos achando que todos chupam sangue ou se enrolam no cabelo, o que é um mito.',
  'Mede cerca de 6 a 7 cm de corpo, tem pelagem marrom-aveludada com uma listra branca fina no meio das costas e quatro faixas brancas no rosto (acima e abaixo dos olhos). Possui uma pequena aba de pele levantada na ponta do focinho (folha nasal), característica dos morcegos que comem frutas na nossa região. Durante o dia, dorme pendurado de cabeça para baixo em pequenos grupos debaixo de folhas largas de árvores.',
  'Vive abrigado sob folhas de palmeiras, bananeiras, árvores copadas e beirais tranquilos em cidades e chácaras. À noite, voa ao redor de árvores frutíferas (como figueiras, goiabeiras, nêsperas e embaúbas) e pode entrar por engano pelas janelas das casas.',
  'Não ataca pessoas e não se alimenta de sangue; seus voos rasantes perto de árvores são apenas para pegar frutas. No entanto, todo morcego (de qualquer espécie) pode morder se for segurado com a mão e, embora raramente esteja infectado, qualquer mamífero silvestre pode transmitir o vírus da raiva, doença letal se não for prevenida com vacina.',
  'Nunca toque em um morcego com as mãos, principalmente se estiver caído no chão durante o dia, e mantenha cães e gatos vacinados contra a raiva. Se ele entrar pela janela à noite, apague a luz e deixe a janela aberta para ele sair sozinho. Se houver mordida, arranhão ou contato direto com o animal, lave o local com bastante água e sabão e procure uma unidade de saúde no mesmo dia para avaliar a vacina antirrábica.',
  'Se encontrar um morcego caído no chão ou voando de dia (comportamento anormal), cubra-o com um balde ou caixa sem encostar nele e acione o setor de Controle de Zoonoses da prefeitura.',
  'Instituto Butantan — Guia para convivência com morcegos',
  'https://publicacoeseducativas.butantan.gov.br/web/morcegos/pages/pdf/morcegos.pdf',
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Morcego-de-telhado (Molossus molossus)
update public.species set slug = 'molossus-molossus'
  where scientific_name = 'Molossus molossus' and slug <> 'molossus-molossus'
  and not exists (select 1 from public.species s where s.slug = 'molossus-molossus');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'molossus-molossus',
  'Morcego-de-telhado',
  'Molossus molossus',
  'caution',
  false,
  'mamifero',
  array['Morcego-insetívoro', 'Morcego-cauda-de-rato']::text[],
  array['marrom-escuro', 'preto', 'castanho']::text[],
  'Morcego bem pequeno, todo marrom-escuro, sem listras no rosto, com orelhas arredondadas e uma pontinha da cauda solta fora da membrana de voo.',
  array['Morcego-das-frutas (Platyrrhinus lineatus): também inofensivo, porém é maior, tem listras brancas no rosto e dorme em árvores, não dentro de forros apertados.', 'Morcego-vampiro (Desmodus rotundus): maior, sem cauda aparente e com o polegar bem longo para caminhar no chão; vive principalmente em cavernas e ocos de árvores em áreas de criação de gado.']::text[],
  'É o morcego que mais vive nos forros e telhados das casas da região, saindo ao entardecer para caçar insetos em pleno voo. Apesar do medo que causa nos moradores, não chupa sangue e um único indivíduo pode devorar centenas de mosquitos, mariposas e besouros por noite.',
  'É muito pequeno, pesando cerca de 15 gramas (menor que um camundongo), com pelagem curta e aveludada de cor marrom-chocolate ou preta. Possui asas longas e estreitas para voar rápido no alto e tem dificuldade para levantar voo se cair diretamente no chão liso. Sua cauda se prolonga um pouco além da pele entre as pernas traseiras, lembrando a cauda de um ratinho.',
  'Abriga-se durante o dia em lugares quentes e escuros como forros de telhados, frestas de dilatação de prédios, caixas de persiana e cumeeiras de casas urbanas e rurais.',
  'Não ataca pessoas nem suga sangue, sendo um grande aliado no controle de insetos urbanos. O único risco ocorre se alguém tentar pegar um morcego caído no chão ou no quarto com a mão nua: assustado, ele vai morder para se defender e pode transmitir o vírus da raiva.',
  'Jamais toque em um morcego com as mãos nuas e use máscara e luvas se precisar limpar fezes no forro, borrifando água antes para não levantar poeira. Se um morcego entrar no quarto, apague a luz e abra as janelas para ele sair. Se houver mordida, arranhão ou contato direto com o animal, lave o local com bastante água e sabão e procure uma unidade de saúde no mesmo dia para avaliar a vacina antirrábica.',
  'Se encontrar um morcego caído no chão durante o dia, isole o animal cobrindo-o com um balde e chame o Centro de Controle de Zoonoses do município.',
  'Instituto Butantan — Guia para convivência com morcegos',
  'https://publicacoeseducativas.butantan.gov.br/web/morcegos/pages/pdf/morcegos.pdf',
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Onça-pintada (Panthera onca)
update public.species set slug = 'panthera-onca'
  where scientific_name = 'Panthera onca' and slug <> 'panthera-onca'
  and not exists (select 1 from public.species s where s.slug = 'panthera-onca');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'panthera-onca',
  'Onça-pintada',
  'Panthera onca',
  'danger',
  false,
  'mamifero',
  array['Onça', 'Canguçu', 'Jaguar']::text[],
  array['amarelo-dourado', 'preto', 'branco']::text[],
  'Grande felino de pelagem amarelada com manchas pretas em forma de rosetas que possuem pequenos pontos pretos dentro.',
  array['Suçuarana (Puma concolor): felino nativo de cor marrom-avermelhada uniforme, sem manchas pelo corpo.']::text[],
  'O maior felino das Américas e símbolo da Mata Atlântica, ameaçado de extinção em São Paulo. Não há registros confirmados recentes na região de São Roque; no estado, sobrevive em grandes áreas preservadas, como a Serra do Mar.',
  'Pode pesar de 60 a mais de 100 kg, com corpo robusto, musculatura poderosa, mandíbula extremamente forte e patas curtas e largas. Suas manchas (rosetas) servem como camuflagem perfeita entre as sombras da floresta tropical. Tem hábito solitário, é excelente nadadora e caça à espreita mamíferos de médio e grande porte.',
  'Grandes remanescentes de floresta contínua e bem preservada. Precisa de áreas muito extensas para sobreviver.',
  'Por ser um grande carnívoro selvagem, representa risco físico gravíssimo e letal caso haja encontro direto ou tentativa de aproximação, embora ataques a humanos sejam extremamente raros e ocorram apenas em situações excepcionais de defesa ou cativeiro ilegal.',
  'Em áreas de mata preservada, caminhe em grupo e faça barulho. Em caso de avistamento, não corra nem dê as costas: afaste-se devagar, mantendo o animal à vista, e avise os órgãos ambientais.',
  'Acione imediatamente a Polícia Militar Ambiental e órgãos de conservação de fauna (Fundação Florestal / CETRAS) em caso de aparição de felinos de grande porte em áreas habitadas ou risco a criações.',
  'ICMBio — Plano de Ação Nacional para a Conservação da Onça-pintada',
  'https://www.gov.br/icmbio/pt-br/assuntos/biodiversidade/pan/pan-onca-pintada',
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Sapo-cururu (Rhinella icterica)
update public.species set slug = 'rhinella-icterica'
  where scientific_name = 'Rhinella icterica' and slug <> 'rhinella-icterica'
  and not exists (select 1 from public.species s where s.slug = 'rhinella-icterica');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'rhinella-icterica',
  'Sapo-cururu',
  'Rhinella icterica',
  'harmless',
  false,
  'anfibio',
  array['Sapo-boi', 'Cururu']::text[],
  array['marrom', 'amarelo-queimado', 'preto', 'bege']::text[],
  'Sapo grande de pele rugosa e seca com duas bolsas salientes bem visíveis atrás dos olhos.',
  array['Sapo-cururu (Rhinella diptycha): espécie irmã muito parecida que ocorre em áreas mais abertas da região, tendo os mesmos hábitos e características.', 'Rã-pimenta (Leptodactylus labyrinthicus): anfíbio grande de pele mais lisa e pernas traseiras fortes para saltar longe, que solta uma secreção esbranquiçada apimentada se for agarrada.']::text[],
  'Anfíbio noturno muito comum nos quintais de chácaras e bairros próximos a matas e córregos da região. Sofre muitos maus-tratos (como jogar sal) por causa de mitos antigos, mas é um grande aliado dos moradores por comer baratas, besouros, moscas e até escorpiões.',
  'É um sapo grande e pesado, medindo de 10 a 18 cm, com pele áspera cheia de verrugas e manchas marrons e amareladas. Atrás dos olhos possui duas glândulas grandes e inchadas (glândulas parotoides) que guardam um veneno branco leitoso usado apenas para defesa. Ao contrário da crença popular, o sapo não esguicha veneno à distância para cegar pessoas e o xixi do sapo não transmite ''cobreiro'' (herpes-zóster).',
  'Passa o dia escondido em locais úmidos e sombreados sob vasos, pedras, entulhos e buracos. À noite, costuma ficar parado embaixo de postes e lâmpadas de varandas caçando os insetos atraídos pela luz.',
  'Para os seres humanos, o sapo no quintal é totalmente inofensivo, pois tem defesa passiva, não ataca ninguém e só libera o veneno das costas se suas glândulas forem apertadas com força. O risco real acontece com cães e gatos que abocanham ou mordem o sapo: o veneno em contato com a boca do animal doméstico causa baba intensa, vômitos e problemas cardíacos graves.',
  'Nunca jogue sal no sapo (isso causa queimaduras cruéis no animal) e não o pegue sem luvas; se quiser retirá-lo da varanda, conduza-o devagar com uma vassoura. Se uma pessoa encostar no sapo e levar a mão à boca ou aos olhos, lave imediatamente com bastante água corrente e ligue para o Disque-Intoxicação 0800 722 6001; se um cachorro morder o sapo, lave a boca do cão com mangueira apontada para fora (sem deixá-lo engolir a água) e leve-o urgente ao veterinário.',
  'Não necessário.',
  'Instituto Butantan',
  'https://butantan.gov.br/butantan-educa/tem-sapo-no-meu-quintal!-entenda-os-beneficios-de-preservar-os-sapos-pererecas-e-ras-no-ambiente-urbano',
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Suçuarana (Puma concolor)
update public.species set slug = 'puma-concolor'
  where scientific_name = 'Puma concolor' and slug <> 'puma-concolor'
  and not exists (select 1 from public.species s where s.slug = 'puma-concolor');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'puma-concolor',
  'Suçuarana',
  'Puma concolor',
  'danger',
  false,
  'mamifero',
  array['Puma', 'Onça-parda', 'Leão-baio']::text[],
  array['marrom-claro', 'castanho', 'amarelado', 'cinza']::text[],
  'Felino de médio a grande porte, com pelagem lisa de cor marrom-avermelhada ou cinzenta uniforme, sem manchas pelo corpo.',
  array['Onça-pintada (Panthera onca): felino muito maior e robusto, facilmente diferenciado pelas rosetas pretas espalhadas pelo corpo.']::text[],
  'Segundo maior felino do Brasil, muito adaptável e capaz de sobreviver em fragmentos menores de vegetação nativa do que a onça-pintada. É um predador solitário e discreto que evita o contato com seres humanos.',
  'Mede de 1 a 2 metros de comprimento (incluindo a longa cauda escura) e pesa entre 40 e 70 kg, com corpo esguio, cabeça arredondada e orelhas pequenas com fundo escuro. Sua pelagem é monocromática em tons de bege ou castanho-avermelhado. É um animal ágil que salta grandes distâncias e caça principalmente capivaras, veados e animais de criação na zona rural.',
  'Bordas de mata, capoeiras, reflorestamentos e áreas de transição entre mata e zona rural. Adapta-se a fragmentos menores de vegetação do que a onça-pintada.',
  'Felino de grande porte com potencial de causar ferimentos graves ou morte em caso de confronto direto, defesa de território ou filhotes. No entanto, o puma tem comportamento naturalmente furtivo e foge de pessoas.',
  'Mantenha animais de estimação e criações (como cabras e galinhas) em recintos fechados à noite para não atrair predadores silvestres. Se encontrar uma suçuarana, não corra de costas; mantenha contato visual, levante os braços para parecer maior e recue lentamente; em caso de incidente grave, acione o SAMU 192 e a Polícia Ambiental.',
  'Comunique a Polícia Militar Ambiental ou o CETRAS se o animal for avistado rondando galinheiros urbanos ou ferido.',
  'Revisão da equipe EcoLens',
  null,
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Tamanduá-bandeira (Myrmecophaga tridactyla)
update public.species set slug = 'myrmecophaga-tridactyla'
  where scientific_name = 'Myrmecophaga tridactyla' and slug <> 'myrmecophaga-tridactyla'
  and not exists (select 1 from public.species s where s.slug = 'myrmecophaga-tridactyla');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'myrmecophaga-tridactyla',
  'Tamanduá-bandeira',
  'Myrmecophaga tridactyla',
  'caution',
  false,
  'mamifero',
  array['Tamanduá-açu', 'Juruetê']::text[],
  array['cinza', 'preto', 'branco', 'castanho']::text[],
  'Mamífero grande de focinho tubular muito comprido, cauda enorme e peluda em forma de bandeira e listras pretas diagonais no peito.',
  array['Tamanduá-mirim (Tamandua tetradactyla): espécie menor que sobe em árvores, com cauda pelada preênsil e coloração amarelada com colete preto.']::text[],
  'O maior dos tamanduás, especializado em comer formigas e cupins. É típico do Cerrado e dos campos do interior paulista; não há registros confirmados recentes na região de São Roque.',
  'Pode atingir mais de 2 metros de comprimento do focinho à ponta da cauda e pesar até 40 kg. Possui pelagem áspera cinzenta com uma faixa preta diagonal contornada de branco nos ombros, olhos e orelhas minúsculos e garras dianteiras imensas e curvas que usa para abrir cupinzeiros duros. Anda apoiando os nós dos dedos das patas dianteiras para não gastar as unhas.',
  'Cerrado, campos abertos e bordas de mata em grandes áreas naturais. Cada vez mais raro por perda de habitat e atropelamentos.',
  'Não tem veneno e não ataca seres humanos por maldade, mas suas garras dianteiras são armas formidáveis de defesa contra cães de caça ou predadores. Se alguém tentar segurá-lo ou acuá-lo num canto, um abraço defensivo pode causar ferimentos profundos e graves.',
  'Mantenha distância do animal caso o encontre cruzando estradas rurais e pare o veículo para deixá-lo atravessar em segurança. Nunca tente tocar ou conter um tamanduá-bandeira sem equipamento especializado; se um cão de chácara atacá-lo, afaste o cachorro imediatamente para evitar que ambos saiam feridos.',
  'Acione os Bombeiros (193), a Polícia Militar Ambiental ou o CETRAS se o tamanduá for visto perdido em áreas urbanizadas ou ferido em rodovias.',
  'Revisão da equipe EcoLens',
  null,
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Tapiti (Sylvilagus brasiliensis)
update public.species set slug = 'sylvilagus-brasiliensis'
  where scientific_name = 'Sylvilagus brasiliensis' and slug <> 'sylvilagus-brasiliensis'
  and not exists (select 1 from public.species s where s.slug = 'sylvilagus-brasiliensis');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'sylvilagus-brasiliensis',
  'Tapiti',
  'Sylvilagus brasiliensis',
  'harmless',
  false,
  'mamifero',
  array['Coelho-do-mato', 'Coelho-brasileiro']::text[],
  array['marrom', 'castanho', 'bege', 'branco']::text[],
  'Pequeno mamífero com orelhas curtas, pelagem marrom-castanha e cauda curtíssima com a parte de baixo branca.',
  array['Lebre-europeia (Lepus europaeus): espécie exótica invasora muito maior, com pernas e orelhas longas e pretas na ponta, que corre em campos abertos.']::text[],
  'Coelho nativo legítimo da biodiversidade da Mata Atlântica, essencial como presa para mamíferos carnívoros e aves de rapina da região. É um animal pacífico que habita bordas de matas e quintais rurais arborizados.',
  'Mede cerca de 30 cm de comprimento e pesa entre 800g e 1,5 kg, tendo o corpo compacto, orelhas menores que as da lebre e pelos macios em tons de marrom-escuro. Diferente das lebres, o tapiti vive em locais com vegetação densa onde pode se esconder rapidamente, e as fêmeas dão à luz filhotes cegos e sem pelos em pequenos ninhos forrados com pelos próprios.',
  'Bordas de matas, capoeiras, quintais de chácaras com vegetação alta, clareiras e plantações próximas a áreas florestadas.',
  'Totalmente inofensivo para o ser humano, não apresentando qualquer agressividade e fugindo sempre ao avistar pessoas ou cães.',
  'Deixe o animal livre na natureza e mantenha animais domésticos (cães e gatos) sob controle para evitar predação da fauna nativa. Caso encontre um filhote sozinho no mato, não o leve para casa, pois a mãe geralmente está por perto procurando alimento.',
  'Não necessário; acione órgãos de fauna (CETRAS ou Polícia Ambiental) apenas se o animal for encontrado ferido por atropelamento ou ataque de cães domésticos.',
  'Revisão da equipe EcoLens',
  null,
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Taturana-oblíqua (Lonomia obliqua)
update public.species set slug = 'lonomia-obliqua'
  where scientific_name = 'Lonomia obliqua' and slug <> 'lonomia-obliqua'
  and not exists (select 1 from public.species s where s.slug = 'lonomia-obliqua');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'lonomia-obliqua',
  'Taturana-oblíqua',
  'Lonomia obliqua',
  'danger',
  false,
  'lagarta',
  array['Lagarta-de-fogo', 'Taturana']::text[],
  array['marrom', 'verde-escuro', 'branco']::text[],
  'Lagarta marrom-esverdeada com espinhos verdes parecidos com pequenos pinheirinhos e que fica em grupos grandes nos troncos de árvores.',
  array['Outras taturanas de espinhos (gênero Automeris): causam queimação forte no local, mas são geralmente verdes-vivas e ficam sozinhas nas folhas, não amontoadas no tronco.', 'Lagarta-de-mariposa inofensiva: lagartas lisas (sem cerdas nem espinhos em forma de pinheiro) não injetam veneno na pele.']::text[],
  'É a lagarta mais perigosa do Brasil e, no estado de São Paulo, a responsável pelos acidentes hemorrágicos com lagartas. O perigo surge quando alguém encosta no tronco onde elas estão agrupadas, principalmente nos meses quentes e chuvosos.',
  'Mede cerca de 5 a 6 cm, tem o corpo marrom-esverdeado com pequenas manchas brancas nas costas e é coberta por espinhos ramificados verdes que parecem pequenos pinheiros. Durante o dia, dezenas de lagartas ficam juntas, imóveis e muito bem camufladas na casca do tronco das árvores, saindo à noite para comer folhas.',
  'Encontrada em troncos de árvores frutíferas (como abacateiro, pessegueiro, ameixeira, goiabeira e pereira) e árvores nativas da Mata Atlântica, como aroeira e cedro, em chácaras, sítios e parques.',
  'Ao encostar nos espinhos, a pessoa sente dor e queimação imediatas, mas o perigo maior surge horas ou dias depois, pois o veneno impede o sangue de coagular. Podem ocorrer manchas roxas pelo corpo, sangramento na gengiva, no nariz e na urina, além de falência dos rins e hemorragia cerebral se o soro antilonômico não for aplicado a tempo.',
  'Olhe com atenção para os troncos antes de apoiar a mão ou colher frutas. Em caso de contato, lave o local com água e sabão, faça compressa fria, não passe nada em cima e procure atendimento médico imediatamente, mesmo que não haja sangramento. Se possível, fotografe a lagarta de longe para mostrar ao médico. Ligue para o Disque-Intoxicação 0800 722 6001 ou acione o SAMU 192.',
  'Se encontrar uma colônia no quintal ou escola, isole a árvore e avise a Vigilância em Saúde / Zoonoses do município (o Instituto Butantan também recebe essas lagartas para fabricar o soro).',
  'Instituto Butantan',
  'https://www.butantan.gov.br/noticias/lonomia-saiba-reconhecer-a-lagarta-que-pode-provocar-envenenamento-grave-e-o-que-fazer-em-caso-de-acidente',
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Teiú (Salvator merianae)
update public.species set slug = 'salvator-merianae'
  where scientific_name = 'Salvator merianae' and slug <> 'salvator-merianae'
  and not exists (select 1 from public.species s where s.slug = 'salvator-merianae');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'salvator-merianae',
  'Teiú',
  'Salvator merianae',
  'harmless',
  false,
  'reptil',
  array['Lagarto-teiú', 'Teju', 'Tiú', 'Teiuaçu']::text[],
  array['preto', 'branco', 'amarelo', 'verde']::text[],
  'Lagarto grande e forte, malhado de preto e branco (ou esverdeado na cabeça quando filhote), com cauda comprida listrada.',
  array['Jacaré-do-papo-amarelo (Caiman latirostris): filhotes podem assustar moradores perto de lagos, mas o jacaré tem placas ósseas altas nas costas e focinho largo.', 'Calango-verde (Ameiva ameiva): lagarto bem menor, mais fino e com coloração verde-viva e azulada.']::text[],
  'É o maior lagarto da região, muito comum em bordas de mata, condomínios e chácaras nos dias quentes e ensolarados. Embora seja inofensivo e fuja sempre que vê pessoas, às vezes é morto por medo do seu tamanho ou por invadir galinheiros em busca de ovos.',
  'Pode alcançar até 1,5 metro de comprimento contando a cauda, com corpo musculoso, garras fortes e língua bifurcada rosada que ele coloca para fora para sentir cheiros. Os adultos têm o corpo preto salpicado de manchas brancas ou amareladas formando faixas nas costas e na cauda, enquanto os filhotes nascem com a cabeça e o pescoço verde-brilhante. É um animal onívoro que come frutas caídas, insetos, aranhas, caracóis, ovos, ratos e até animais mortos, limpando o ambiente.',
  'Frequenta bordas de mata, clareiras, quintais de sítios, hortas, pomares e barrancos onde cava tocas para dormir e passar o inverno. Costuma caminhar pelo chão nos horários mais quentes do dia tomando sol.',
  'Não possui veneno e nunca ataca pessoas espontaneamente, preferindo correr para o mato ou para sua toca. Porém, se for encurralado por pessoas ou cães sem ter por onde fugir, defende-se dando chicotadas fortes com a cauda e possui uma mordida muito dolorida que pode cortar a pele.',
  'Deixe o caminho livre para o lagarto fugir e prenda os cães até que ele saia do quintal, evitando encurralá-lo em cantos de muro. Para evitar que ele visite o terreno, não deixe restos de comida, ração de animais domésticos ou ovos ao alcance no chão; se houver mordida acidental, lave bem com água e sabão e procure atendimento médico pelo risco de infecção.',
  'Acione os Bombeiros (193) ou a Guarda Ambiental somente se o lagarto estiver ferido por ataque de cães ou preso dentro de casa ou piscina vazia sem conseguir sair.',
  'Instituto Butantan',
  'https://butantan.gov.br/bubutantan/teiu-um-lagarto-tao-brasileiro-que-voce-com-certeza-ja-viu-por-ai',
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Tinhorão (Caladium bicolor)
update public.species set slug = 'caladium-bicolor'
  where scientific_name = 'Caladium bicolor' and slug <> 'caladium-bicolor'
  and not exists (select 1 from public.species s where s.slug = 'caladium-bicolor');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'caladium-bicolor',
  'Tinhorão',
  'Caladium bicolor',
  'caution',
  false,
  'planta',
  array['Coração-de-jesus', 'Tajá', 'Caládio']::text[],
  array['verde', 'rosa', 'vermelho', 'branco']::text[],
  'Planta baixa de folhas largas em formato de coração, muito coloridas com manchas fortes em rosa, vermelho e branco no centro.',
  array['Comigo-ninguém-pode (Dieffenbachia seguine): tem folhas manchadas de branco e o mesmo princípio tóxico, mas cresce em um caule grosso e alto, enquanto o tinhorão sai direto da terra em hastes finas.', 'Taioba (Xanthosoma taioba): planta comestível totalmente verde; jamais consuma folhas com manchas coloridas ou arroxeadas.']::text[],
  'Planta ornamental muito comum em vasos, varandas e canteiros de meia-sombra nas casas e praças da região. Por ter cores vibrantes que lembram brinquedos ou doces, atrai bastante a atenção de crianças pequenas e filhotes de cães.',
  'Atinge entre 30 e 60 cm de altura, crescendo a partir de uma batata subterrânea (tubérculo) com folhas finas em formato de coração ou escudo. Suas folhas exibem desenhos muito variados combinando bordas verdes com o centro branco, cor-de-rosa ou vermelho-vivo. Assim como a comigo-ninguém-pode, todas as suas partes contêm cristais microscópicos de oxalato de cálcio em formato de agulha.',
  'Cultivada em vasos dentro de residências, varandas, jardins residenciais, praças públicas e também aparece subespontânea em barrancos úmidos e sombreados.',
  'Mastigar a folha ou a batata da planta provoca dor e queimação imediatas, salivação intensa, inchaço nos lábios, na língua e na garganta, além de náuseas, vômitos e dificuldade para engolir. Se a seiva entrar em contato com os olhos, causa dor forte, lacrimejamento e pode provocar lesão na córnea.',
  'Mantenha os vasos fora do alcance de crianças pequenas e animais e lave as mãos após mexer na planta. Se alguém mastigar ou engolir parte da planta, retire os restos da boca e enxágue-a com água, sem engolir. Não provoque vômito nem dê leite, óleo ou outros "antídotos" caseiros. Guarde um pedaço da planta para identificação e ligue para o Disque-Intoxicação 0800 722 6001; se houver inchaço na garganta ou falta de ar, acione o SAMU 192.',
  'Não necessário.',
  'Sinitox/Fiocruz — Plantas tóxicas',
  'https://sinitox.icict.fiocruz.br/plantas-toxicas',
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

-- Viúva-marrom (Latrodectus geometricus)
update public.species set slug = 'latrodectus-geometricus'
  where scientific_name = 'Latrodectus geometricus' and slug <> 'latrodectus-geometricus'
  and not exists (select 1 from public.species s where s.slug = 'latrodectus-geometricus');
insert into public.species (
  slug, common_name, scientific_name, status, is_invasive, species_group, other_names, main_colors, visual_pattern, lookalikes, description, characteristics, habitat, risk_description, safety_advice, rescue_advice, source_name, source_url, is_published
) values (
  'latrodectus-geometricus',
  'Viúva-marrom',
  'Latrodectus geometricus',
  'danger',
  false,
  'aranha',
  array['Viúva-negra', 'Aranha-viúva']::text[],
  array['marrom', 'cinza', 'laranja', 'preto']::text[],
  'Aranha pequena de abdômen redondo marrom-acinzentado com desenhos claros e uma mancha alaranjada em forma de ampulheta na barriga. O saco de ovos parece uma bolinha com pontinhas, como um carrapicho.',
  array['Falsa viúva-negra (Steatoda grossa): inofensiva ou de importância menor, tem abdômen marrom-arroxeado mais abaulado e não possui as marcas vermelhas vivas no ventre.']::text[],
  'É a viúva-negra mais comum nas cidades brasileiras. Pequena e pouco agressiva, só pica quando é apertada contra o corpo, mas tem veneno que age no sistema nervoso.',
  'A fêmea tem cerca de 1 cm de corpo, pernas finas com faixas escuras e abdômen globoso. Faz teias irregulares e resistentes em cantos protegidos, onde guarda os sacos de ovos espinhosos.',
  'Comum em áreas urbanas: debaixo de móveis de jardim, em muros, cercas, beirais, vasos, latas, pneus e cantos de garagens e depósitos.',
  'A picada causa dor local que pode se espalhar, acompanhada de contrações musculares, suor, tremores e ansiedade. Casos com sintomas fortes precisam de atendimento hospitalar.',
  'Use luvas grossas e sapatos fechados ao mexer em pilhas de pedras, lenha ou capina rente ao solo. Em caso de picada, lave o local com água e sabão, procure atendimento médico imediato e ligue para o Disque-Intoxicação 0800 722 6001 ou acione o SAMU 192.',
  'Não necessário chamar resgate ambiental individual.',
  'Instituto Butantan',
  'https://butantan.gov.br/noticias/maioria-das-aranhas-que-vive-nas-cidades-nao-e-venenosa--conheca-as-mais-perigosas',
  true
)
on conflict (slug) do update set
  common_name = excluded.common_name,
  scientific_name = excluded.scientific_name,
  status = excluded.status,
  is_invasive = excluded.is_invasive,
  species_group = excluded.species_group,
  other_names = excluded.other_names,
  main_colors = excluded.main_colors,
  visual_pattern = excluded.visual_pattern,
  lookalikes = excluded.lookalikes,
  description = excluded.description,
  characteristics = excluded.characteristics,
  habitat = excluded.habitat,
  risk_description = excluded.risk_description,
  safety_advice = excluded.safety_advice,
  rescue_advice = excluded.rescue_advice,
  source_name = excluded.source_name,
  source_url = excluded.source_url,
  is_published = true;

commit;
