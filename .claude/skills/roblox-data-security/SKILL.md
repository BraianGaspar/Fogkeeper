---
name: roblox-data-security
description: "Salvamento (DataStore) e segurança do que tem valor na versão Roblox do Fogkeeper: server/Progress.luau (óleo, oficina, desbloqueios, conquistas, bestiário, histórico, recibos), server/Scores.luau (rankings), server/Monetization.luau (ProcessReceipt, Game Passes) e a validação dos canais em Main.server.luau. Use ao adicionar campo ao progresso, mudar como algo é salvo, criar recompensa, compra ou canal novo, investigar perda de progresso, compra entregue duas vezes ou trapaça. EN triggers: DataStore, save data, data loss, ProcessReceipt, receipt, anti-exploit, server authority, remote validation, leaderboard OrderedDataStore."
---

# Fogkeeper Roblox: salvamento e segurança

Regra de ouro: tudo o que dá, gasta, salva ou compra valor é decidido **no
servidor**. O cliente só pede. Formatos em `roblox/ARCHITECTURE.md`
(`ProgressJson`, atributos `Oil`, `Passes`, `Vip`). Edite seguindo `roblox-code`.

## O que tem valor aqui

Óleo e `oil_total`, níveis da oficina (`meta`), desbloqueios (`unlocked`),
conquistas, bestiário (`seen`), estatísticas, histórico, **recibos** de compras
(`receipts`), posse de Game Passes e as pontuações dos rankings.

## Como o salvamento funciona hoje (confira no código antes de mudar)

- `Progress.load`: `GetAsync` com até 3 tentativas. Se falhar, `loaded = false`
  e a sessão **nunca grava** (não sobrescreve progresso bom com vazio). Mantenha.
- Formato: `blank()` define os campos e os padrões; `normalize()` completa o que
  falta ou veio com tipo errado. Campo novo = entrada em `blank()` (e nas tabelas
  internas que `normalize` percorre) + `ProgressJson` no ARCHITECTURE.md.
  Mudança de significado de um campo existente (não só campo novo) pede
  migração explícita em `normalize` e, se ficar complexo, um `version` no perfil.
- `Progress.save(player, release?)`: `UpdateAsync` em segundo plano, gravando a
  tabela da memória. Chamado ao comprar desbloqueio/oficina, mudar
  configurações, terminar partida/tutorial e ao sair do jogo (`release = true`
  solta a trava). `Progress.autosave` roda a cada `Balance.AUTOSAVE_EVERY`.
- **Trava de sessão:** o perfil salvo tem `lock = {job, at}` (JobId do servidor
  dono). `Progress.load` pega a trava dentro de `UpdateAsync`; se outro servidor
  ainda a tem (jogador acabou de sair de lá), espera até `SESSION_LOCK_WAIT` e
  depois assume. Toda gravação confere a trava dentro do `UpdateAsync` e não
  grava se ela for de outro servidor. Trava sem renovar há mais de
  `SESSION_LOCK_TIMEOUT` é de servidor que caiu. `lock` fica fora do `ProgressJson`.
- **Fechamento:** `BindToClose` chama `Progress.flush`, que grava todos, solta as
  travas e espera as gravações terminarem (até `SHUTDOWN_SAVE_WAIT`).
- `Progress.saveNow(player, purchaseId)`: grava e espera; usado nos recibos.
- `receipts` fica fora do `ProgressJson` publicado e é limpo acima de 300.
- Rankings: um OrderedDataStore por chave (`modo|mapa|dificuldade` ou
  `daily|data`); `UpdateAsync` só grava se for recorde. Partida reacendida com
  Robux (`run.revived`) não vai para o ranking.

## Pontos a revisar sempre que mexer nisso

- **Nada de gravar fora de `write()`:** qualquer gravação nova do perfil passa
  pela checagem da trava; um `SetAsync` direto anularia a proteção.
- **Orçamento de requisições:** DataStores têm limite por minuto que cresce com
  o número de jogadores. Não grave a cada brasa ou abate; agrupe e grave nos
  momentos acima. Rankings já têm cache (`Balance.TOP_CACHE`).
- **Tamanho:** o histórico guarda 20 partidas (`Balance.HISTORY_SIZE`); não
  guarde estado de interface nem dados da partida em andamento no perfil.

## Compras (ProcessReceipt)

Ordem que **não pode** mudar em `server/Monetization.luau`:
1. Jogador presente e progresso carregado; senão `NotYetGranted` (o Roblox tenta de novo).
2. `PurchaseId` já em `receipts` → `PurchaseGranted` sem entregar de novo.
3. Entregar (óleo, ou reacender; janela fechada → `REVIVE_LATE_OIL`).
4. `saveNow` com o recibo. Falhou → desfaz o óleo e devolve `NotYetGranted`.
5. Só então `PurchaseGranted`.

Produto novo: entrada em `shared/Monetization.luau` (`id = 0` até existir no
Creator Dashboard), caso em `processReceipt`, texto traduzido e a checagem de
políticas em `roblox-policy`. Game Pass: posse vem de `UserOwnsGamePassAsync`
(com cache) e de `PromptGamePassPurchaseFinished`; o cliente nunca afirma posse.

## Canais vindos do cliente

Todo payload é suspeito. Padrão de `Main.server.luau`:
- `typeof` em cada argumento, faixa e inteiro conferidos (`index == 1 or 2 or 3`,
  `#value < 2000`, `Scores.validKey`). `Sim:setAim` já descarta NaN e infinito.
- Fase certa (`phase == "lobby"`, partida rodando, não pausada, não reacendendo).
- Permissão: ações de anfitrião só para a menor vaga (`HOST_ACTIONS`);
  desbloqueio checado com `Progress.isUnlocked`; cor de feixe só com o passe.
- Frequência: `throttled(player)` (balde de fichas, `Balance.LOBBY_COOLDOWN`)
  em tudo que grava progresso ou é caro. Canal novo que mexe em valor sem
  `throttled` é bug.
- O servidor calcula o preço e o efeito; o cliente manda só o id.

## Ferramentas de suporte

Não há comandos de administrador no jogo. Para recuperar progresso de um
jogador, prefira o gerenciador de Data Stores do Creator Dashboard. Se um dia
criar comando de admin: checagem por `UserId` no servidor, nada no cliente,
registro de quem fez, quando, alvo e valor antes/depois.

## Antipadrões

- `SetAsync` cego sobre dados que não carregaram.
- Confirmar compra (`PurchaseGranted`) antes de salvar o recibo.
- Recompensa calculada no cliente ou passe conferido só na interface.
- Gravar no DataStore dentro do passo da simulação.
- `pcall` que engole erro de save sem `warn`.

## Relatório

Valores protegidos · fronteira de confiança · validações · abusos evitados ·
riscos que sobram · testes manuais (compras de teste no Studio, sair e voltar,
servidor publicado com API Services ligado).
