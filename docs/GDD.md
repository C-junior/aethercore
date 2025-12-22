
# Game Design Document: Aether Core: Spirit Tactics
## 1. Visão Geral do Jogo
**Título:** Aether Core: Spirit Tactics
**Gênero:** Auto Battler / Roguelike / Monster Tamer (Coleção de Monstros)
**Plataforma:** PC (Steam)
**Resumo:** Um jogo de batalha automática  combinando aspectos de *Pokémon*, *Slay the Spire* e *Super Auto Pets*. O jogador coleciona e evolui mais de 180 criaturas , montando equipes estratégicas para enfrentar chefes e completar o "Kadodex".
## 2. Mecânicas Principais (Core Mechanics)
### 2.1. Loop de Gameplay
O jogo segue um ciclo *roguelike*:
1. **Seleção Inicial:** O jogador escolhe um entre três iniciais: **Beleaf** (Planta), **Monku** ou **Creeze**.
2. **Exploração:** Navegação por um mapa com caminhos ramificados que determinam os tipos de Aether Spirits encontrados e eventos.
3. **Preparação (Loja/Equipe):** Compra de unidades, reroll da loja, posicionamento no grid e gerenciamento de itens,.
4. **Batalha Automática:** O combate ocorre sem interferência direta do jogador após o início.
5. **Recompensa:** Ouro, XP e a captura de unidades derrotadas.
### 2.2. Sistema de Batalha
* **Formato do Campo:** O campo de batalha utiliza um padrão de losango ou ziguezague. O posicionamento é crucial, pois habilidades podem afetar aliados adjacentes.
* **Tamanho da Equipe:** O jogador pode ter até 4 Aether Spirits ativos no campo (limitado pelo nível de XP do jogador/loja) e uma reserva (banco),.
* **Tipos e Sinergias:** Cada Aether Spirits possui tipos (Fogo, Água, Terra, etc.). Ter múltiplas unidades do mesmo tipo ativo concede bônus de sinergia (ex: regeneração, dano),.
* **Automação:** As unidades atacam e usam habilidades baseadas em seus status e posição. O jogador não controla as ações durante a luta.
### 2.3. Evolução e Hiper Evolução
* **Evolução Padrão:** Aether Spiritss ganham XP em batalhas e evoluem para formas mais fortes, melhorando ataque e habilidades.
* **Combinação de Unidades:** Adquirir 3 unidades iguais as combina em uma unidade de nível (tier) superior.
* **Hiper Evolução (Hyper Evolution):** Uma mecânica secreta onde um Aether Spirits de nível 3, segurando um item específico, evolui para uma forma especial ao ganhar XP (seja em batalha ou via itens de XP),.
* *Exemplos:*
* **Drillagan** + Item *Heaven Piercer*.
* **Obsimian** + Item *Flame Belt*.
* **Tentesla** + Item *Toxic Lamp*.
### 2.4. A Caixa (Reserva)
Unidades não ativas ficam armazenadas na "caixa". Elas são úteis para:
* **Sinergias:** Manter unidades para completar bônus futuros.
* **Counters Específicos:** Guardar unidades que combatem chefes específicos (ex: usar *Mushiki* para aplicar lentidão no chefe *Gnocking*),.
* **Ganho de XP:** Unidades na caixa também ganham experiência passiva,.
## 3. Elementos de RPG e Progressão
### 3.1. Itens
Existem dois tipos principais de itens:
* **Itens Equipáveis:** Adicionam efeitos ao portador ou aliados próximos (ex: *Lucky Coin* para economia),. Essenciais para Hiper Evoluções.
* **Consumíveis:** Poções que aumentam status permanentemente ou dão XP imediato,.
### 3.2. Economia
* **Ouro:** Usado para comprar novas unidades, rerrolar a loja e comprar XP para aumentar o limite de unidades em campo.
* **Venda:** Unidades podem ser vendidas para recuperar ouro. Vender unidades evoluídas concede mais recursos.
### 3.3. Roguelike e Meta-game
* **Escalonamento (Scaling):** É crítico ter uma equipe completa de 4 unidades até o andar 4 e pelo menos uma unidade nível 3/4 antes do chefe *Gnocking*.
* **Bosses:**
* *Queenstruction*: Requer ao menos um Aether Spirits nível 2.
* *Gnocking*: Um chefe difícil que countera certas builds (especialmente buffs) e pode matar a equipe inteira com um golpe se não houver a estratégia correta (ex: usar lentidão/frost),.
* *Chefe Final*: Invoca unidades que o jogador vendeu durante a run.
* **Kadodex:** O objetivo de longo prazo é encontrar e registrar todas as variações, incluindo os raros "Misprints" (versões com cores alternativas/shinies),.
## 4. Personagens e Unidades (Exemplos)
O jogo possui mais de 180 criaturas. Exemplos de design e evolução incluem:
* **Iniciais:**
* *Beleaf*: Mais difícil de usar contra o chefe Gnocking.
* **Evoluções Especiais:**
* *Creeze* evolui para *Drownaught* se houver Sinergia de Ar (4).
* *Monku* evolui para *Houtshot* se houver Sinergia Física (4).
* **Secretos:**
* Existem Aether Spiritss secretos desbloqueáveis através de sequências de runas ou condições de morte específicas (ex: deixar Beleaf morrer e vendê-lo para obter *Demoleize*).
## 5. Interface e User Experience (UI/UX)
Baseado nos padrões do gênero e na análise técnica:
* **Lado Direito:** Mostra o ouro atual, botão de compra de XP e loja de unidades.
* **Lado Esquerdo:** Exibe as sinergias (Traits) ativas e quantos unidades de cada tipo o jogador possui.
* **Centro/Baixo:** O "Banco" (Bench) onde as unidades compradas aguardam ou são reordenadas.
* **Interação:** Sistema de "Drag and Drop" (arrastar e soltar) para mover unidades entre a loja, o banco e o campo de batalha, com destaque visual para sinergias ativas,.
## 6. Considerações Técnicas e Balanceamento
* **RNG vs Estratégia:** O jogo deve equilibrar a aleatoriedade da loja com a estratégia de posicionamento. O jogador deve ser capaz de mitigar o azar através do uso inteligente de itens e adaptação da equipe.
* **Curva de Dificuldade:** O Ato 1 deve evitar minibosses se a equipe for fraca, enquanto o Ato 2 incentiva minibosses para obter tickets de loja. O Ato 3 possui pouco espaço para escalonamento, exigindo que o jogador já tenha sua build definida,.
* **Balanceamento de Atributos:** O sistema deve calcular dano e defesa considerando tipos e itens. A venda de unidades deve retornar recursos de forma dinâmica baseada no tier da unidade.
---
*Este documento consolida as mecânicas, estratégias e estruturas identificadas nas fontes, servindo como um guia para o desenvolvimento ou análise de Aether Spirits.*
