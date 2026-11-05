# Economia, progressão e monetização (versão Roblox)

Auditoria feita com as skills `roblox-economy` e `roblox-liveops`. Números de
`shared/Balance.luau` (óleo, `META`, `UNLOCKS`) e `shared/Monetization.luau`.
Este documento **propõe**; o que já foi aplicado no código está marcado como
"Aplicado". Preços em Robux são sugestões para o Creator Dashboard (os `id`
ainda são `0`).

## 1. De onde vem a pontuação (e o óleo)

Óleo no fim da partida = `max(OIL_MIN, round(pontos × OIL_PER_SCORE × (1 + 0,1 × nível de Sorte do pescador)))`,
× `VIP_OIL` (2) com o VIP. `OIL_PER_SCORE = 0,005` (0,5%), `OIL_MIN = 5`.
Abandonar (`quit`) não dá nada. Tutorial não dá óleo (no Godot dá 50).
No cooperativo **cada jogador recebe o óleo da pontuação do time inteiro**.

### Medido (bot do Godot, mesmas fórmulas, Baía, sem oficina)

| Dificuldade | Tempo | Mortes | Pontos | Óleo |
|---|---|---|---|---|
| Normal | 4:52 | 633 | 9.336 | 47 |
| Normal | 5:46 | 883 | 13.476 | 67 |
| Normal | 5:48 | 899 | 13.694 | 68 |
| Médio | 3:30 | 353 | 6.582 | 33 |
| Médio | 3:46 | 416 | 7.695 | 38 |
| Médio | 5:37 | 889 | 18.004 | 90 |

O modelo de surgimento (`spawnInterval`, `groupSize`) prevê ≈ 1.010 criaturas
até 5:46; o bot queimou 883 (o resto estava vivo). O modelo serve para estimar
o que o bot não alcança:

### Estimado (vitória = 10 min)

| Situação | Criaturas | Pontos | Óleo (sem VIP) | Com VIP |
|---|---|---|---|---|
| Derrota de iniciante (~5 min, Normal) | ~700–900 | 9–14 mil | **~55** | ~110 |
| Amanhecer no Normal, sozinho | ~3.800–4.400 (≈15 pts cada) | 70–80 mil | **~375** | ~750 |
| Amanhecer no Médio, sozinho | ×1,08 + elites, pontos ×1,3 | ~105 mil | **~525** | ~1.050 |
| Amanhecer no Normal, 4 jogadores | ×2,5 surgimento (teto de 200 vivas) | ~140 mil | **~700 cada** | ~1.400 cada |

Partida vencida ≈ 11 min com história, tela final e saguão.

## 2. Para onde vai o óleo

| Gasto | Total |
|---|---|
| Oficina (`META`, custo do nível n = `cost × n`) | **5.390** |
| — Lente polida (dano, 5 níveis) | 1.200 |
| — Paredes de granito (vida, 5) | 900 |
| — Sorte do pescador (óleo, 3) | 600 |
| — Segunda opinião (trocas, 3) | 540 |
| — Engrenagens finas (giro, 3) | 420 |
| — Olhar atento (4ª carta) | 400 |
| — Pavio longo, Ímã de cobre, Lista negra | 360 cada |
| — Pavio aceso (melhoria inicial) | 250 |
| Desbloqueios (`UNLOCKS`) | **4.820** |
| — 6 mapas (também abrem por meta) | 2.650 |
| — faroleiros (Monge, Pirata, Astrônoma, Pescador) | 750 |
| — habilidades (Espelho, Maré, Sinalizador) | 540 |
| — faróis (Pedra, Ferro, Cristal; Cristal também por meta) | 480 |
| — melhorias (Combustão, Brasas vitais) | 400 |
| **Tudo, abrindo os mapas por meta** | **7.560** |
| Tudo comprando com óleo | 10.210 |

## 3. Ritmo de progressão

Partidas até "tudo liberado" (7.560 de óleo, mapas por meta):

| Perfil | Óleo/partida | Partidas | Tempo de jogo |
|---|---|---|---|
| Só derrotas de iniciante (Normal) | ~55 | ~137 | ~16 h (não acontece: a oficina o faz vencer antes) |
| Vence no Normal, sozinho | ~375 | ~20 | ~3,7 h |
| Vence no Normal, sozinho, VIP | ~750 | ~10 | ~1,9 h |
| Vence no Médio, sozinho | ~525 | ~14 | ~2,6 h |
| 4 amigos, Normal | ~700 | ~11 | ~2 h |
| 4 amigos, Normal, VIP | ~1.400 | ~5–6 | **~1 h** |

Primeiros passos de um jogador novo (Normal, ~55 de óleo por derrota):

| Marco | Quando |
|---|---|
| 1ª compra (Paredes de granito 1 = 60, Pavio longo 1 = 60) | 2ª partida |
| Farol de Pedra (80) | 2ª–3ª partida |
| Fiorde (meta: chegar a 5:00) | 1ª–3ª partida (bot: 2 de 3) |
| Rio (meta: derrotar um chefe) | quando vencer o 1º chefe (~5:00) |
| Japão + Farol de Cristal (meta: amanhecer) | 1º amanhecer |
| Egito, Egeu e Celta (meta: amanhecer no Médio) | 1º amanhecer no Médio; abre 1.800 de óleo em mapas de uma vez |
| Oficina inteira | ~15 vitórias no Normal |

Leitura: a distância entre perder (~55) e vencer (~375) é de quase 7×, então o
iniciante sente a oficina devagar e o veterano termina em poucas horas. Nada a
mudar no número base sem dados (subir `OIL_PER_SCORE` encurta ainda mais o fim);
as alavancas certas são as propostas da seção 6.

`OIL_MIN` fica em 5: deixar o farol cair de propósito leva ~50 s + 30 s de telas;
com mínimo 15 isso renderia ~11 de óleo/min sem jogar (metade de uma vitória),
convite a farm parado.

## 4. Catálogo e preços sugeridos

| Chave | O que entrega | Preço sugerido | Justificativa |
|---|---|---|---|
| `vip` (passe) | 2× óleo + selo | **299 R$** | Âncora. Poupa ~3.780 de óleo até "tudo liberado" (≈ 3 Tonéis ≈ 900 R$); conveniência, não abre nada exclusivo |
| `rainbow` (passe) | 6 cores de feixe | **149 R$** | Visual que todos veem na partida; preço de cosmético médio |
| `golden_lantern` (passe) | brasas douradas no avatar | **99 R$** | Visual pequeno, compra de impulso |
| `legendary_lighthouses` (passe) | Farol de Ouro e de Obsidiana | **149 R$** | Dois faróis, mas só valem quando o comprador é o anfitrião |
| `oil_small` (produto) | 150 de óleo | **49 R$** (3,1 óleo/R$) | Item barato: ~3 derrotas ou 40% de uma vitória |
| `oil_medium` (produto) | 450 de óleo | **129 R$** (3,5 óleo/R$, +14%) | ~1,2 vitória no Normal |
| `oil_large` (produto) | 1.200 de óleo | **299 R$** (4,0 óleo/R$, +31%) | ~3 vitórias; 22% da oficina |
| `revive` (produto) | reacende o farol uma vez | **49 R$** | Mesmo preço do Barril pequeno; se chegar tarde vira os mesmos 150 de óleo |
| Servidor privado | mensal | **50 R$/mês** | Barato para manter grupos fixos (o jogo é cooperativo) |

Quantidades dos barris mantidas: a escada 150/450/1.200 já dá desconto leve e
crescente com esses preços.

**Aplicado:** `Balance.REVIVE_LATE_OIL` 300 → 150. Qualquer cliente pode abrir a
compra do produto `revive` a qualquer hora; fora da janela ele virava 300 de
óleo, o dobro de um Barril pequeno pelo mesmo preço: o "reviver atrasado de
propósito" seria o jeito mais barato de comprar óleo. Com 150 os dois valem o
mesmo. **Aplicado:** a descrição do reviver agora diz o que acontece quando a
compra chega tarde (regra da skill: `desc` descreve tudo o que é entregue,
inclusive limitações), com os 8 idiomas em `I18n/extra.luau`.

## 5. Pagar para vencer?

| O que o dinheiro compra | Efeito na partida | Ranking afetado |
|---|---|---|
| Passes visuais | nenhum | nenhum |
| VIP | mais óleo (mais rápido até o teto) | indireto, mesmo teto de quem joga |
| Barris | oficina mais cedo: até +50 de vida, +25% de dano, +18% de giro, 4ª carta, melhoria inicial | **Normal e Modo Chefões** (a oficina vale); diário não |
| Reviver | segunda chance | nenhum: partida reacendida sai do ranking mundial |

Teto pago: oficina inteira ≈ 4,5 Tonéis ≈ 1.350 R$, ou ~15 vitórias jogando.
O teto existe e se alcança jogando, então é aceitável, mas é o ponto fraco.
Propostas (não aplicadas):
- Mostrar no ranking o nível total da oficina de cada entrada, ou um filtro
  "sem oficina"; o diário continua sendo a tabela justa.
- Não aumentar tetos de `META`, nem criar barril maior que o Tonel, sem rever
  esta tabela.
- Conquista `oil_1000` conta `oil_total`, que inclui óleo comprado: dá para
  comprar a conquista com um Tonel. Contar só óleo de partida
  (`server/Progress.luau`, área de segurança).

## 6. Metas de retorno e propostas (só documentadas)

| # | Proposta | Lugar no ciclo | Efeito D1/D3/D7 | Óleo | Onde mexer |
|---|---|---|---|---|---|
| P1 | Tutorial dá 50 de óleo na 1ª vez (`OIL_TUTORIAL`, igual ao Godot) | 1ª sessão | D1: 1ª compra logo depois do tutorial | +50 uma vez | `Balance` + `finishTutorial` em Main |
| P2 | Bônus do 1º desafio diário do dia (+100 de óleo, sem sequência que pune quem falta) | todo dia | D2–D7: motivo para voltar | ~+100/dia | Main `reward` (marcar `stats.daily_paid = data` antes de pagar) |
| P3 | Conquistas pagam óleo (25 comuns, 100 de chefe/maré, 250 difíceis) | sessão/semanas | D3–D7: metas visíveis | ~+2.000 no total | `Progress.unlockAchievement` + texto na tela |
| P4 | Óleo do cooperativo: manter bônus de grupo, mas `pontos / (1 + 0,15 × (jogadores − 1))` no cálculo do óleo | partida | evita "tudo em 1 hora" (4 amigos VIP); o grupo de 4 ainda rende ~1,3× o solo (~480) | −31% no grupo de 4 | Main `reward` |
| P5 | Gasto de óleo sem poder depois do teto (títulos, cores do selo, molduras do bestiário) | veterano | D30: óleo continua valendo; VIP e barris não perdem sentido | novo gasto | catálogo novo em Balance + tela |
| P6 | Convite de amigos (`SocialService:PromptGameInvite`) no saguão com vaga livre | saguão | crescimento | — | client/Ui + Main |

Antes de P4/P5, medir (seção 7): se a mediana de "tudo liberado" passar de
2 semanas, P4 não é necessária.

## 7. Instrumentação (AnalyticsService, só no servidor)

Nomes estáveis, sem dado pessoal, um evento por partida (nunca por brasa ou
abate). Conferir assinaturas da API na hora de implementar.

| Evento | Chamada | Onde | Campos |
|---|---|---|---|
| Funil 1ª sessão | `LogOnboardingFunnelStepEvent` | Main | 1 saguão · 2 1ª partida iniciada · 3 1ª carta · 4 meia-noite · 5 1º chefe · 6 amanhecer |
| Tutorial | `LogOnboardingFunnelStepEvent` (funil próprio) ou `LogCustomEvent("tutorial_step")` | server/Tutorial | passo, concluiu/abandonou |
| Óleo ganho | `LogEconomyEvent(Source, "Oil", qtd, saldo, Gameplay, sku)` | Main `reward` | sku: `run_normal`, `run_daily`, `run_rush`, `vip_bonus` (parte do VIP separada) |
| Óleo comprado | `LogEconomyEvent(Source, "Oil", qtd, saldo, IAP, key)` | server/Monetization | `oil_small/medium/large`, `revive_late` |
| Óleo gasto | `LogEconomyEvent(Sink, "Oil", custo, saldo, Shop, id)` | Progress `buyMeta`/`buyUnlock` | id da oficina ou do desbloqueio |
| Partida | `LogProgressionCompleteEvent` / `LogProgressionFailEvent` | Main `finishRun` | caminho `mapa/modo/dificuldade`, nível = maré; custom: duração, jogadores, revivida |
| Desbloqueio por meta | `LogCustomEvent("goal_unlock")` | Main `reward` | id |
| Loja | `LogCustomEvent("shop_open")`, `("purchase_prompt")`, `("purchase_done")` | Main / server/Monetization | key |
| Reviver | `LogCustomEvent("revive_offered")`, `("revive_bought")` | Main | jogadores, minuto da noite |

Perguntas que esses eventos respondem: onde o funil cai; óleo médio por partida
por perfil (confirma a seção 1); tempo até cada marco da seção 3; conversão
por item; quantos chegam ao teto e ficam com óleo parado (P5).

Metas iniciais (Creator Dashboard): D1 ≥ 20%, D7 ≥ 6%, sessão ≥ 15 min,
≥ 60% dos novos chegam à meia-noite na 1ª partida, conversão ≥ 1,5%.

## 8. Plano de atualizações e eventos

| Semana | Entrega | Meta de retorno | Medir |
|---|---|---|---|
| 0 (lançamento) | IDs dos passes/produtos com os preços acima; eventos da seção 7 | — | funil, D1 |
| 2 | P1 (óleo do tutorial) e P2 (bônus do diário) | D1, D2 | % que joga o diário 2 dias seguidos |
| 4 | P3 (óleo de conquistas) + 4 conquistas novas (ex.: 3 diários, 10 chefes no cooperativo) | D7 | conquistas/jogador |
| 6 | "Noite especial" de fim de semana (regra do diário diferente, data real de fim, cosmético só visual por conquista) | D7 | participação |
| 8 | Convite de amigos (P6) + comemoração pública de chefe/amanhecer | crescimento | % de partidas em grupo, convites |
| 10–12 | Mapa ou chefe novo (receita do `fogkeeper-dev`) + P5 se houver óleo parado | D30 | retorno de inativos |

Ritmo: algo novo a cada 2–4 semanas. Sem escassez falsa, sem "último dia" que
não é, nada aleatório pago.
