Aqui está o **Support Paper Game Design Document (GDD)** completo para **AetherCore: Spirit Tactics**.

Este documento expande o MVP anterior para um jogo completo, incorporando dados profundos sobre meta-game, evolução secreta e arquitetura de sistemas extraídos das análises de *Kādomon* e da teoria acadêmica de RPGs.

---

# Game Design Document: AetherCore: Spirit Tactics

## 1. Identidade do Produto
*   **Título:** AetherCore: Spirit Tactics
*   **Gênero:** Auto Battler / Roguelike / Monster Tamer
*   **Conceito Central:** Um jogo de estratégia onde o jogador recruta e posiciona "Spirit Guardians" (Heroínas Antropomórficas) em um grid tático. O foco não é a batalha em si (que é automática), mas a **preparação** (Shop Phase) e a **exploração** do mapa.
*   **Target Audience:** Fãs de estratégia profunda (*Slay the Spire*), colecionadores (*Pokémon*) e entusiastas de estética anime.

---

## 2. Estrutura de Gameplay (Core Loop & Systems)

O jogo opera em um ciclo *Roguelike* dividido em Atos. O sucesso depende do conhecimento do jogador sobre o "Meta" (interações ocultas e counters).

### 2.1. O Campo de Batalha (The Grid)
*   **Formato:** Padrão **Ziguezague/Losango** (2-3-2 ou similar).
    *   *Motivo:* Baseado na análise de *Kādomon*, este formato maximiza a importância de "adjacências", permitindo que uma unidade central buffe até 6 aliados, ao contrário de 4 em um grid quadrado.
*   **Limite de Unidades:** O jogador começa com 1 slot. Deve gastar Ouro para comprar XP de Jogador e liberar até 4 slots ativos.

### 2.2. A Bancada (The Bench/Box) - *Mecânica Crítica*
Diferente de outros Auto Battlers onde o banco é apenas espera, aqui ele é ativo:
1.  **Ganho de XP Passivo:** Unidades no banco ganham XP após cada batalha. Isso incentiva o jogador a comprar unidades cedo para "cozinhá-las" para o late game,.
2.  **Rotação Estratégica:** O jogador deve manter unidades específicas no banco para counterar chefes.
    *   *Exemplo de Design:* O Chefe do Ato 2 pune times que usam muitos buffs. O jogador deve ter uma unidade de "Gelo/Slow" no banco para trocar antes dessa luta específica,.

### 2.3. Exploração e Mapa
*   **Pathing Determinístico:** O mapa mostra quais Tipos (Fogo, Água, Planta) aparecerão nos próximos nós.
    *   *Estratégia:* O jogador não explora aleatoriamente; ele "caça" os tipos necessários para fechar sua Sinergia,.
*   **Eventos de Acampamento:** Locais para curar ou alterar o tipo elemental de uma Guardiã (ex: Adicionar o tipo "Fogo" a uma unidade de Água para criar sinergias duplas).

---

## 3. Personagens: Spirit Guardians (Data-Driven Design)

O jogo completo terá ~180 Guardiãs. Para gerenciar isso, utilizaremos o sistema de **Classes e Arquétipos** definidos na tese de RPG.

### 3.1. Estrutura de Evolução Complexa
A evolução não é apenas "Nível". Baseado nos segredos de *Kādomon*, implementaremos 4 métodos:

1.  **Evolução Padrão:** Ganhar XP (Batalha ou Banco) até atingir o limite.
2.  **Fusão (Tier Up):** 3 cópias da mesma unidade = 1 unidade de Tier superior (Status base aumentados).
3.  **Hyper Evolution (Mecânica Secreta):**
    *   *Condição:* Uma Guardiã Tier 3 deve segurar um **Item Específico** ao ganhar XP,.
    *   *Exemplo:* A Guardiã *Kitsune* (Tier 3) segurando o item *Cursed Mask* evolui para *Nine-Tailed Empress*.
4.  **Split Evolution (Sinergia):**
    *   *Condição:* A evolução muda dependendo da Sinergia ativa no time no momento da evolução.
    *   *Exemplo:* Uma Guardiã do tipo *Planta* evolui para *Espírito da Floresta* (Healer) se houver sinergia de **Natureza (4)**, ou para *Espinho Venenoso* (DPS) se houver sinergia de **Veneno (4)**.

### 3.2. Exemplos de Personagens (Baseado no Guia de Evolução)

#### **Starter A: Ignis (Fogo)**
*   **Conceito:** Garota Salamandra.
*   **Base:** *Ember* (Ataca rápido).
*   **Evolução Padrão:** *Pyromancer*.
*   **Hyper Evolution:** Se segurar o item *Eternal Flame*, vira **Inferna** (Ataque em área massivo).

#### **Starter B: Tides (Água)**
*   **Conceito:** Garota Sereia/Tubarão.
*   **Base:** *Finny*.
*   **Split Evolution:**
    *   Com Sinergia Água (4) -> **Tsunami** (Empurra inimigos).
    *   Com Sinergia Gelo (2) -> **Glaciera** (Congela inimigos).

#### **Unidade Técnica: Mimic (Sombra)**
*   **Conceito:** Garota Bau.
*   **Mecânica:** Baseada no *Mushiki* de *Kādomon*. Invoca minions fracos que aplicam "Slow" ao morrer. Essencial para chefes que batem muito forte e rápido.

---

## 4. Balanceamento e "Power Budget"

Para evitar o "Power Creep" (novas unidades serem fortes demais), usaremos a fórmula de custo derivada das fontes acadêmicas,.

**Fórmula de Custo (Power Cost):**
$$Custo = (HP / 10) + (Dano \times Velocidade) + (Valor Habilidade) - (Penalidade)$$

*   **Tier 1:** Orçamento de 25 pontos.
*   **Tier 2:** Orçamento de 50 pontos.
*   **Tier 3 (Hyper):** Orçamento de 90 pontos.

**Regra de Ouro do Scaling:**
O jogo deve verificar o poder do jogador em pontos de checagem específicos:
*   **Floor 4:** O jogador DEVE ter 4 unidades em campo.
*   **Boss Ato 1:** Pelo menos 1 unidade Tier 2.
*   **Boss Ato 2:** Pelo menos 1 unidade Tier 3/Hyper.
*   *Design Note:* Se o jogador não cumprir isso, a matemática do jogo garante a derrota (Soft lock).

---

## 5. Itens e Economia

A economia gerencia o risco/recompensa.

### 5.1. Categorias de Itens
1.  **Held Items (Equipáveis):**
    *   *Stat Boosters:* Espada (+Atk), Escudo (+HP).
    *   *Evolutionary Keys:* Itens que não dão status, mas ativam Hyper Evolutions (ex: *Broken Rock*, *Toxic Lamp*). O jogador sacrifica poder imediato por uma evolução futura (Investimento).
2.  **Consumíveis:**
    *   *XP Candy:* Dá XP instantâneo.
    *   *Type Change:* Adiciona/Remove tipos elementais (Raro).

### 5.2. Dinâmica de Venda
*   Vender uma unidade evoluída retorna mais recursos (Gold + XP itens) do que o custo inicial. Isso permite "pivotar" (trocar de estratégia) no meio do jogo sem perder todo o progresso.

---

## 6. Arquitetura Técnica (Full Game)

Baseado nas práticas de *Godot* para escalabilidade,.

### 6.1. Dados (Resource-Based)
Não use herança de classes para monstros. Use **Composição** e **Resources**.
*   `CharacterData.tres`:
    *   `ID`: string
    *   `BaseStats`: Dictionary {HP, Atk, Spd}
    *   `EvolutionTree`: Array de Condições (Item Check, Synergy Check).
    *   `AbilityScript`: Referência a um script de componente.

### 6.2. Componentes (Scenes/Nodes)
*   **Game State Manager:** Controla `PreparationPhase` vs `BattlePhase`. Impede venda de unidades durante o combate.
*   **Unit Combiner:** Um script dedicado a verificar se o jogador tem 3 cópias no banco/campo e fundi-las automaticamente.
*   **Synergy Manager:** Um singleton que recalcula os buffs globais toda vez que uma unidade entra/sai do grid ou muda de tipo.

### 6.3. IA de Batalha (Simples & Previsível)
A IA deve ser determinística para que o jogador possa planejar.
*   **Regra:** Atacar o inimigo mais próximo.
*   **Tie-breaker:** Inimigo com menos HP ou Inimigo na linha superior.

---

## 7. Meta-Game e Rejogabilidade (The Hook)

### 7.1. SpiritDex (O Colecionismo)
*   O jogo deve rastrear quais Guardiãs o jogador já encontrou e quais *Hyper Evolutions* desbloqueou.
*   **Misprints (Shinies):** 1% de chance de encontrar uma unidade com coloração alternativa e +10% de status base.

### 7.2. Segredos e Puzzles
*   **Puzzle de Runas:** Baseado em *Kādomon*, o mapa pode ter runas. Se o jogador ativar runas em ordem específica (ex: 1 -> 4 -> 2), desbloqueia um chefe secreto ou uma unidade lendária.
*   **Condição de Derrota:** Certas evoluções exigem que uma unidade específica morra em batalha e depois seja vendida na loja (Sacrifício).

---

## 8. Planejamento de Conteúdo (Roadmap)

### Fase 1: Fundação (MVP Refinado)
*   Sistema de Grid e Batalha Automática.
*   30 Guardiãs (3 Facções).
*   Evolução Simples (Tier Up).

### Fase 2: Profundidade (Alpha)
*   Implementação do Banco Ativo (XP Passivo).
*   Sistema de Itens e Hyper Evolutions.
*   60 Guardiãs adicionais.

### Fase 3: Meta & Polish (Beta/Release)
*   **Bosses com Gimmicks:** Chefe que inverte o grid, Chefe que rouba buffs (Counter do Meta).
*   Misprints e SpiritDex.
*   Total de 180+ Guardiãs.

---

## 9. Riscos e Mitigação

*   **Risco:** O jogador achar que é apenas "RNG" (Sorte).
*   **Mitigação:** Implementar a mecânica de **Map Preview** clara. O jogador deve ver que se ele for para o Norte, encontrará unidades de Fogo. A sorte existe, mas a decisão é do jogador,.
*   **Risco:** Combate visualmente confuso.
*   **Mitigação:** Usar setas de "alvo" quando o mouse passa sobre uma unidade no modo de preparação, mostrando quem ela atacará primeiro.