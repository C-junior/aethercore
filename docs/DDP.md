Documento de Design de Personagens: "Spirit Guardians" (MVP)
1. O Framework de Balanceamento: "Power Budget" (Orçamento de Poder)
Para garantir que o jogo não quebre quando escalarmos de 5 para 100 personagens, utilizaremos um sistema matemático de "Custo de Poder", baseado nas práticas de balanceamento de RPGs por turnos e simulações de dinâmica de sistemas.
Cada personagem tem um "orçamento" de pontos para gastar em seus atributos e habilidades. Se um personagem tem muita Vida, ele deve "pagar" por isso tendo menos Ataque ou uma Habilidade mais fraca.
Fórmula Base (MVP)
Pontuação Total = (HP / 10) + (Dano * Velocidade de Ataque) + Valor da Habilidade
Tiers de Evolução e Orçamento
Conforme o Kādomon e outros jogos do gênero, as unidades evoluem. A evolução aumenta o orçamento disponível.
• Tier 1 (Base): Orçamento de ~25 Pontos. (Foco: Identidade básica).
• Tier 2 (Evoluída): Orçamento de ~50 Pontos. (Foco: Especialização).
• Tier 3 (Suprema): Orçamento de ~90 Pontos. (Foco: Dominância e Habilidade Ultimate).

--------------------------------------------------------------------------------
2. Estilos de Habilidades (Ability Archetypes)
Para o MVP, usaremos três arquétipos de habilidades que cobrem a "trindade" dos RPGs (Tanque, DPS, Suporte) e testam o sistema de grid:
1. Gatilho Passivo (On-Hit/On-Hurt): Ativa quando a unidade bate ou apanha.
	◦ Ex: "Ao receber dano, reflete 10% de volta." (Bom para Tanques).
2. Gatilho de Tempo (Cooldown): Ativa a cada X segundos ou ataques.
	◦ Ex: "A cada 3 ataques, o próximo causa dano crítico." (Bom para DPS).
3. Aura de Posicionamento (Grid Synergy): Afeta aliados adjacentes.
	◦ Ex: "Aliados atrás desta unidade ganham +5 de Ataque." (Essencial para estratégia de posicionamento).

--------------------------------------------------------------------------------
3. As 5 Personagens do MVP (Com Evolução)
Aqui estão 5 exemplos cobrindo os elementos básicos (Fogo, Água, Terra, Ar, Natureza) para testar o sistema de "Pedra-Papel-Tesoura" e sinergias.
1. Elemento Fogo (DPS Explosivo)
Conceito Visual: Mulher-Raposa (Kitsune). Caudas em chamas, ágil, vestes leves.
• Função: Dano alto, pouca vida. Deve ser protegida.
• Evolução:
	◦ T1: Embera (1 cauda).
		▪ Habilidade: Faísca. A cada 3 ataques, causa 10 de dano extra.
	◦ T2: Vulpyre (3 caudas).
		▪ Habilidade: Incendiar. Seus ataques queimam o inimigo (dano por segundo).
	◦ T3: Kyuubi (9 caudas, flutuando).
		▪ Habilidade Ultimate: Explosão Solar. Ao matar um inimigo, causa dano em área a todos os adjacentes.
	◦ Hyper Evolution (Secreta): Se segurar o item Tocha Espiritual ao evoluir -> Amaterasu (Dano sagrado que ignora defesa).
2. Elemento Água (Controle/Off-Tank)
Conceito Visual: Mulher-Tubarão. Pele azulada, barbatana nas costas, dentes afiados, armadura de coral.
• Função: Linha de frente ofensiva.
• Evolução:
	◦ T1: Sharka (Pequena, com uma lança de coral).
		▪ Habilidade: Frenesi. Ganha +10% de velocidade de ataque se o inimigo tiver <50% de vida.
	◦ T2: Mawtide (Armadura mais pesada).
		▪ Habilidade: Mordida. O 4º ataque cura ela em 15 de HP.
	◦ T3: Megalana (Montada em uma onda d'água).
		▪ Habilidade Ultimate: Tsunami. Empurra o inimigo para trás no grid, bagunçando o posicionamento dele.
3. Elemento Terra (Tanque Puro)
Conceito Visual: Mulher-Urso (Ursa). Alta, robusta, orelhas redondas, manoplas de pedra gigantes.
• Função: Absorver dano na linha de frente.
• Evolução:
	◦ T1: Cubbi (Pequena e fofa).
		▪ Habilidade: Pele Dura. Reduz todo dano recebido em 2.
	◦ T2: Ursala (Crescida, com placas de pedra nos ombros).
		▪ Habilidade: Provocar. Obriga inimigos adjacentes a atacarem ela.
	◦ T3: Terrabear (Corpo coberto de cristais).
		▪ Habilidade Ultimate: Fortaleza. No início da batalha, concede Escudo (Shield) igual a 50% da sua Vida para ela e aliados atrás dela.
4. Elemento Ar (Suporte/Velocidade)
Conceito Visual: Mulher-Harpia/Pássaro. Asas nos braços, pés com garras, penas no cabelo.
• Função: Flanco e Buff de velocidade.
• Evolução:
	◦ T1: Tweety (Pequena, voando baixo).
		▪ Habilidade: Vento de Cauda. Aliados na mesma linha atacam 10% mais rápido.
	◦ T2: Galea (Asas maiores, armadura de couro).
		▪ Habilidade: Esquiva. Tem 20% de chance de ignorar um ataque físico.
	◦ T3: Zephyra (Tornado na base dos pés).
		▪ Habilidade Ultimate: Ciclone. Aumenta a velocidade de todo o time em 50% por 5 segundos no início da luta.
5. Elemento Natureza (Invocadora/Especial)
Conceito Visual: Mulher-Abelha (Queen). Antenas, asas translúcidas, abdômen listrado estilizado como vestido.
• Função: Multiplicação numérica (Zerg rush).
• Evolução:
	◦ T1: Beezu (Carrega um pote de mel).
		▪ Habilidade: Mel. Cura o aliado com menos vida a cada 4 segundos.
	◦ T2: Hivea (Comanda pequenas abelhas).
		▪ Habilidade: Ferroada. Aplica veneno (dano lento) ao atacar.
	◦ T3: Queenopi (Coroa real, cetro de cera).
		▪ Habilidade Ultimate: Enxame Real. Ao morrer, invoca 2 Beezus (Tier 1) para continuar lutando no lugar dela. (Similar à mecânica de Mushiki em Kādomon).

--------------------------------------------------------------------------------
4. Aplicação do "Power Budget" (Exemplo Prático)
Vamos aplicar a fórmula no Tier 1 da Raposa (Embera) vs a Ursa (Cubbi) para ver se estão balanceadas. Orçamento Alvo: 25 Pontos.
Embera (Tier 1 - Fogo/DPS):
• HP: 80 (Custo: 8 pontos)
• Ataque: 12
• Velocidade: 1.0 atq/seg
• Custo de Dano: 12 * 1.0 = 12 pontos.
• Habilidade (Faísca): Dano extra condicional (Valor estimado: 5 pontos).
• Total: 8 + 12 + 5 = 25 Pontos. (Balanceada).
Cubbi (Tier 1 - Terra/Tanque):
• HP: 150 (Custo: 15 pontos - Investimento alto em vida).
• Ataque: 5
• Velocidade: 0.8 atq/seg (Lenta).
• Custo de Dano: 5 * 0.8 = 4 pontos.
• Habilidade (Pele Dura): Redução de dano passiva (Valor estimado: 6 pontos - muito forte).
• Total: 15 + 4 + 6 = 25 Pontos. (Balanceada).
Conclusão do Teste: A Embera matará rápido, mas morrerá rápido. A Cubbi quase não dá dano, mas tanca muito. Ambas custam o mesmo para o sistema ("Power Budget"), garantindo que nenhuma seja inerentemente "melhor", apenas diferentes em função.
