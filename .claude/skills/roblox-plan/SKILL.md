---
name: roblox-plan
description: "Planejar uma funcionalidade ou atualização da versão Roblox do Fogkeeper antes de construir: perguntas para fechar a ideia, um resumo curto (PRD), divisão em fatias verticais pequenas que podem ser testadas no Studio uma a uma, e o resumo de construção de cada fatia, com estados de triagem. Evita construir tudo de uma vez e deixar tudo meio quebrado. Use quando o pedido for grande (modo novo, sistema novo, mapa novo, loja, evento, várias telas), quando o usuário pedir plano, PRD, especificação, tarefas, issues ou 'o que fazer primeiro', ou para triar bugs e ideias. EN triggers: Roblox PRD, spec, plan this feature, break into slices, vertical slices, tickets, issues, triage, what to build next, roadmap."
---

# Fogkeeper Roblox: planejar em fatias

Pedido grande vira: ideia fechada → resumo (PRD) → fatias verticais → uma
fatia por vez, cada uma testada no Studio antes da próxima. Pedido pequeno
(um ajuste, um bug claro) não precisa disto: vá direto para `roblox-code` ou
`roblox-debug`.

## Onde o plano fica

Por padrão, **na conversa**. Se o usuário quiser guardar, pergunte e use
`docs/roblox/plans/<slug>.md` (PRD + fatias num arquivo, com a lista
`[ ]` não começada · `[~]` feita e testada, esperando aprovação · `[x]`
aprovada pelo usuário, com data). Issues no GitHub (`gh`) só se o usuário pedir.

## 1. Fechar a ideia (perguntas, uma por vez)

Siga a ordem: o que o jogador faz e ganha → primeiros 30 s da novidade →
como encaixa na partida cooperativa (cada um ou o time?) → números (em
`Balance`) → salvamento → compras (se houver) → celular e controle → textos.
Para cada pergunta, dê a resposta que você recomenda. Use cenários concretos
("dois jogadores, um sai no meio do chefe: o que acontece?"). Fixe uma palavra
para cada conceito, no vocabulário do jogo. Pare quando der para escrever sem
"a definir". Confira contra `fogkeeper-dev` (a tensão atacar × coletar é o
coração do jogo) e se a regra também vale no Godot.

## 2. Resumo (PRD)

Curto, só o necessário para fatiar:
- **Promessa ao jogador** (1–2 frases).
- **Como funciona** (o laço: ação → resposta → próximo objetivo).
- **Sistemas** (servidor autoritativo × só apresentação no cliente), com os
  arquivos prováveis (`Simulation`, `Main`, `Progress`, `Ui/...`).
- **Contratos** novos ou mudados: atributos, canais, Snapshot, `ProgressJson`
  (vão para o `roblox/ARCHITECTURE.md`).
- **Salvamento:** o que sobrevive a sair e voltar.
- **Economia/compras:** fontes e gastos de óleo; regra de justiça
  (`roblox-economy`).
- **Interface:** telas tocadas e se precisam de esboço aprovado (`roblox-ui`).
- **Celular e desempenho:** limites que não podem piorar (`roblox-performance`).
- **Fora do escopo** e **riscos** (como cada risco será testado).

## 3. Fatias verticais

Cada fatia é a coisa mais fina que um jogador **sente**, passando por todas as
camadas que toca (entrada, canal, servidor, salvamento, interface), e que se
testa sozinha no Studio.
- Certo: "O anfitrião escolhe a regra nova no saguão, o servidor aplica na
  partida, todos veem o aviso." Errado: "Fazer todo o servidor do modo novo".
- A fatia 1 prova o laço de ponta a ponta com o mínimo. Depois: salvamento →
  progressão → cooperativo → compras → acabamento.
- Valor (óleo, desbloqueio, recibo) é autoritativo no servidor **desde a fatia
  1**, nunca "arruma depois".
- Tipo: **sozinha** (dá para fazer e verificar sem decisão humana) ou **humana**
  (precisa de aprovação de esboço, decisão de balanceamento, teste do usuário no
  Studio, compra real). Fatia de tela é humana até o esboço ser aprovado.

Mostre as fatias numeradas com: título · tipo · depende de · teste de aceite
(ação exata no Studio → resultado exato) · o que protege no servidor.
Pergunte se o tamanho e as dependências estão certos e ajuste.

## 4. Resumo de construção (por fatia pronta)

Descreve comportamento, não passos de teclado; nomeia sistemas e contratos,
não números de linha:
- **Categoria:** bug ou novidade · **Resumo** em uma linha.
- **Hoje** (para bug) e **Desejado**, com casos de borda e falhas.
- **Camadas e autoridade:** cliente (só entrada, previsão, tela) · servidor
  (valida e concede) · canal (nome, payload, limite de frequência) · dados
  (o que salva e quando).
- **Aceite no Studio:** [ ] ação → resultado · [ ] valor validado no servidor e
  sobrevive a sair/voltar · [ ] celular legível e tocável · [ ] sem erro novo
  no Output · [ ] `luau_blocks`, `i18n_check`, `build` limpos.
- **Fora do escopo:** o que esta fatia não pode mudar.

## Triagem (bugs, ideias, fatias)

Estados: **a triar** → **falta informação** (perguntas abertas listadas) →
**pronta para construir** (tem resumo de construção) · **precisa do usuário**
(diga por quê) · **não fazer** (motivo, para não voltar). Bug só fica pronto
com reprodução (ver `roblox-debug`). Fatia de tela só fica pronta com esboço
aprovado. Se o usuário mandar marcar como pronta, avise o que falta e obedeça.

## Pausa entre sessões

Ao parar no meio: diga (ou grave no arquivo do plano, se existir) a fatia
atual, o que foi feito, o que falta testar e a próxima ação concreta.
