---
name: roblox-economy
description: "Economia, progressão e monetização da versão Roblox do Fogkeeper: óleo (fontes e gastos), oficina (META), desbloqueios por óleo ou meta, conquistas, bestiário, desafio diário, Game Passes (VIP, Arco-íris, Lanterna dourada, Faróis lendários), Developer Products (barris de óleo, Reacender o farol) e servidores privados, sem pagar para vencer. Use ao criar ou mexer em preço, recompensa, produto, passe, oferta, loja, meta de retorno, conquista ou ritmo de desbloqueio na versão Roblox. EN triggers: Roblox economy, monetization, game pass, developer product, pricing, Robux, daily reward, retention, progression pacing, pay-to-win."
---

# Fogkeeper Roblox: economia e monetização

Monetizar sem quebrar a confiança nem o ranking. Catálogo em
`roblox/src/shared/Monetization.luau`, números em `shared/Balance.luau`, regras
e tabelas no `roblox/README.md` (seção Monetização). Código de compra e
salvamento: `roblox-data-security`. Regras da plataforma: `roblox-policy`.

## Mapa da economia (óleo)

| Fontes | Gastos |
|---|---|
| Fim de partida: `score × OIL_PER_SCORE` (mín. `OIL_MIN`), × `VIP_OIL` com o VIP, + "Sorte do pescador" na oficina | Oficina `Balance.META`: custo do nível n = `cost × n`; tudo no máximo ≈ 5.400 de óleo |
| Barris (`oil_small/medium/large`: 150/450/1.200) | Desbloqueios `Balance.UNLOCKS` (mapas, faróis, faroleiros, habilidades, melhorias) ≈ 4.800; mapas também abrem por meta (`goal`) |
| `REVIVE_LATE_OIL` quando o reviver chega tarde | |

Recalcule esses totais se mudar Balance: eles dizem quantas partidas (e quantos
barris) separam um jogador novo do "tudo liberado".

## Regras de justiça deste jogo

- **Nada aleatório pago.** Nenhum produto entrega item sorteado (evita exigência
  de mostrar probabilidades e risco de política). Mantenha.
- **Visual não dá vantagem.** Arco-íris, Lanterna dourada e Faróis lendários são
  só aparência. Qualquer passe novo "só visual" tem que ser só visual mesmo.
- **Ranking não se compra.** Partida reacendida sai do ranking mundial; o
  reviver vale uma vez por partida e só no modo Normal.
- **Ponto de atenção:** óleo comprado vira bônus permanente da oficina (vida,
  dano, giro, cartas). No **desafio diário a oficina não vale** (`infoFor` em
  Main passa `meta = {}`; a tela do diário avisa), então ali todos jogam iguais.
  No ranking normal ela vale, porque se ganha jogando e tem teto (≈ 5.400 de
  óleo para tudo). Qualquer aumento de teto, barril maior ou bônus novo de META
  deve ser avaliado contra isso; se virar problema, tetos menores ou ranking
  normal sem oficina.
- **VIP** dobra o óleo: conveniência, não poder novo; não deixe o VIP abrir
  conteúdo que não se consegue jogando.
- Preço visível antes da compra, sempre pela janela oficial do Roblox, e o texto
  de `desc` descrevendo exatamente o que é entregue (inclusive as limitações).

## Retenção e metas (já existe; use antes de inventar)

- Curto prazo: cartas de melhoria, relíquia de chefe, conquista na hora.
- Sessão: óleo no fim, próximo desbloqueio visível na oficina, história do mapa.
- Vários dias: desafio diário com ranking próprio, 32 conquistas, bestiário
  com 76 fichas, marés (até 10), 7 mapas abertos por meta.
- Longo prazo: rankings por modo/mapa/dificuldade, Modo Chefões, modo sem fim.
- Social: cooperativo até 4; brasas e nível são do time; servidor privado.

Ao propor meta nova: o progresso é contado no servidor (`Progress.addStat`,
`checkGoals`, `checkRunAchievements`), a recompensa é idempotente (marcar
antes de entregar, como as conquistas), e o texto aparece traduzido.

## Ofertas: onde e como

- Nada de oferta antes da primeira partida terminar. A loja fica no saguão.
- Reviver: o botão só aparece no momento de necessidade (luz apagada, janela de
  `REVIVE_WINDOW`), para todos, e some sozinho; nunca bloqueia a tela de fim.
- Escada de preços: um item barato (barril pequeno), um médio e um âncora (VIP
  ou tonel). Barris maiores com desconto leve, nunca "só hoje" falso.
- Botão de compra separado de botões de jogo (evita toque acidental no celular)
  e com estado "Indisponível" quando `id = 0`.

## Saída esperada

Para cada proposta: lugar no ciclo do jogador · efeito no Dia 1/3/7 · fontes e
gastos de óleo afetados (com números) · riscos de justiça e de ranking · eventos
para medir (`roblox-liveops`) · mudanças de código (catálogo, Balance, Progress,
Monetization, tela) e textos para `extra.luau`.

## Antipadrões

- Vender pulo do jogo principal ("libera todos os mapas") ou poder no ranking.
- Escassez falsa, contagem regressiva fictícia, "último dia" que não é.
- Popup de compra no meio da partida (fora o reviver) ou logo ao entrar.
- Nova moeda premium: o jogo tem uma moeda só (óleo); mantenha simples.
