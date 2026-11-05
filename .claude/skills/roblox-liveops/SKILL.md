---
name: roblox-liveops
description: "Operação da versão Roblox do Fogkeeper depois de publicada: o que medir (AnalyticsService: funil de primeira sessão, economia do óleo, progressão, compras), métricas do Creator Dashboard (retenção D1/D7, sessão, conversão), calendário de atualizações e eventos (mapas, chefes, modos, noites temáticas), ganchos sociais do cooperativo (convidar amigos, servidor privado, rankings), divulgação (vídeo, anúncios, criadores) e triagem de opinião dos jogadores. Use ao planejar atualização ou evento, instrumentar métricas, ler números, responder feedback ou divulgar o jogo no Roblox. EN triggers: Roblox live ops, analytics, AnalyticsService, KPIs, retention D1 D7, funnel, update cadence, event plan, roadmap, player feedback, community, marketing, sponsored ads, invite friends."
---

# Fogkeeper Roblox: operação ao vivo

Primeiro medir, depois mudar. Planejamento de cada novidade em fatias:
`roblox-plan`. Publicação: `roblox-release`.

## O que medir

Ainda não há eventos de analytics no código. Quando instrumentar, use
`AnalyticsService` **no servidor** (`server/Main.server.luau` e
`server/Monetization.luau`), com nomes estáveis e sem dado pessoal:

- **Funil da primeira sessão** (`LogOnboardingFunnelStepEvent`): entrou no
  saguão → começou a 1ª partida → 1ª carta escolhida → meia-noite → 1º chefe
  derrotado → amanhecer. Tutorial: passos concluídos e abandono.
- **Economia** (`LogEconomyEvent`): óleo ganho (partida, VIP, barril, reviver
  tardio) e gasto (oficina, desbloqueio), com o id do item.
- **Progressão** (`LogProgressionEvent` ou `LogCustomEvent`): partida terminada
  com mapa, modo, dificuldade, maré, vitória, duração e número de jogadores.
- **Compras:** loja aberta, compra tentada e concluída por chave; reviver
  oferecido e comprado.

Não registre eventos por brasa ou por abate (muito volume); agregue por partida.

## Como ler

Creator Dashboard (Analytics): retenção D1/D7, tempo de sessão, novos
jogadores, conversão de pagantes, receita por usuário. Perguntas úteis:
- Onde o funil cai? (Antes da 1ª partida = saguão/UX; antes da meia-noite =
  dificuldade inicial; muitos saem no chefe = balanceamento.)
- Jogam sozinhos ou em grupo? Grupos ficam mais tempo?
- O óleo sobra (nada para comprar) ou falta (oficina inalcançável)?
Mudança de números de jogo segue `fogkeeper-dev` (Balance) e `roblox-economy`.

## Calendário de atualizações

- Ritmo sustentável (ex.: algo novo a cada 2–4 semanas) vale mais que uma
  grande e depois silêncio.
- Conteúdo que o jogo já sabe receber: mapa novo (receita do `fogkeeper-dev`,
  portado para `Maps`/`Scenery`/`Art`), chefe novo, faroleiro, habilidade,
  conquistas, marés, regras do desafio diário.
- Eventos temáticos curtos (uma "noite especial" com mapa ou regra diferente,
  cosméticos só visuais), anunciados com data real de fim.
- Primeira semana do jogador: Dia 1 diversão rápida e óleo; Dia 2 desafio
  diário; Dia 3 novo mapa aberto por meta; Dia 7 algo visível desde o início
  (ex. Modo Chefões ou um farol).

## Ganchos sociais do cooperativo

- Convidar amigos (`SocialService:PromptGameInvite`) no saguão quando há vaga
  livre; ainda não existe no código.
- Comemoração pública de chefe derrotado e amanhecer para todo o grupo.
- Servidores privados (Creator Dashboard) para grupos fixos.
- Rankings que valorizam participação (diário) além de recorde absoluto.
- Sem troca de itens entre jogadores (não há o que trocar; evita golpes).

## Divulgação

- Vídeo e imagens só da versão Roblox (o trailer existente é da versão Godot).
  Mostrar em 3 s a luz queimando criaturas com amigos.
- Anúncios patrocinados do Roblox: começar pequeno, testar 2–3 miniaturas e
  comparar a taxa de clique e a retenção de quem chegou.
- Criadores de conteúdo: o gancho é "cooperativo de mitologia contra a névoa";
  parceria paga declarada (ver `roblox-policy`).
- A promessa do anúncio tem que bater com a primeira noite.

## Opinião dos jogadores

Classifique cada relato por impacto, clareza para reproduzir, frequência, risco
(retenção, receita, segurança) e esforço. Destino: correção urgente
(`roblox-debug`) · próxima atualização · experimento · lista de espera ·
recusado com motivo. Responda sem prometer datas que não existem e cite nas
notas de versão o que veio de relatos.

## Relatório

Fase atual · próximo marco com critério de aceite · métricas a olhar e a meta
de cada uma · riscos para retenção, justiça e desempenho no celular.
