---
name: roblox-code
description: "Fluxo de trabalho e arquitetura do código Luau da versão Roblox do Fogkeeper (roblox/src, build.ps1, ARCHITECTURE.md): onde cada coisa fica (shared/server/client), contratos de rede (Net, Snapshot, atributos), módulos, refatoração segura, verificação sem Luau executável e teste no Roblox Studio (com ou sem Studio MCP). Use sempre que for criar, mudar, revisar ou refatorar código em roblox/src, ou quando o usuário falar em Luau, Roblox Studio, rbxlx, Rojo, RemoteEvent, ModuleScript, ReplicatedStorage, \"versão Roblox\". EN triggers: Roblox Luau code, module boundaries, remotes, refactor Roblox scripts, Studio MCP, where should this script go."
---

# Fogkeeper Roblox: código e fluxo

O código vive **no Git**, em `roblox/src`, e não na nuvem do Roblox. O Studio só
recebe uma cópia montada. Tudo o que for mudado direto no Studio se perde na
próxima montagem, então **toda mudança de código entra pelos arquivos**.

Antes de mexer, leia `roblox/ARCHITECTURE.md` (fonte de verdade: unidades,
contratos, atributos, canais, formatos JSON) e, para o uso, `roblox/README.md`.
O conteúdo (números, textos, mecânicas) vem do jogo em Godot (`scripts/`); a
skill `fogkeeper-dev` explica o design.

## Mapa antes de mexer

Se a área é desconhecida, primeiro monte o mapa (sem editar): a tabela "Pastas e
donos" do ARCHITECTURE.md, depois `Grep` pelo nome do atributo, canal ou função
em `roblox/src`, listando quem escreve e quem lê. Use o vocabulário do jogo
(farol, feixe, brasas, óleo, oficina, maré, faroleiro, relíquia), não nomes
genéricos.

## Onde cada coisa fica

| Precisa de... | Vai em |
|---|---|
| Número de jogo (vida, dano, tempo, custo) | `shared/Balance.luau` (chefes: `shared/BossData.luau`) |
| Regra da partida, dano, brasas, XP | `server/Simulation.luau` (sem peças, só dados) |
| Saguão, votos, fases, recompensas, canais do cliente | `server/Main.server.luau` |
| Mecânica de um chefe | `server/Bosses/<id>.luau` com a interface do ARCHITECTURE.md |
| Salvar por jogador | `server/Progress.luau`; rankings em `server/Scores.luau` |
| Robux | catálogo em `shared/Monetization.luau`, lógica em `server/Monetization.luau` |
| Cenário 3D | `server/World.luau` + `server/Scenery/<mapa>.luau` (escala `Kit.S = 0.1`) |
| Desenho de criaturas, brasas, feixes, partículas | `client/Renderer.luau`, `client/Art/<mapa>.luau`, `client/ArtKit.luau` |
| Telas e HUD | `client/Ui/<Tela>.luau`, peças em `client/Ui/Theme.luau` |
| Texto visível | `Text.t("texto em PT")`; texto novo em `shared/I18n/extra.luau` |

Montagem (`roblox/build.ps1`): `X.server.luau` = Script, `X.client.luau` =
LocalScript, `X.luau` = ModuleScript; subpastas viram Folders. `shared` →
`ReplicatedStorage.Fogkeeper`, `server` → `ServerScriptService.Fogkeeper`,
`client` → `StarterPlayerScripts.Fogkeeper`. Nunca edite `roblox/build/`.

## Regras de arquitetura

- **Servidor autoritativo.** Dano, vida, brasas, XP, óleo, desbloqueios,
  conquistas, recibos e rankings são decididos só no servidor. O cliente desenha,
  manda intenção e prevê o giro do próprio feixe. Qualquer coisa que dê valor
  passa pela skill `roblox-data-security`.
- **Contratos congelados.** O formato do Snapshot (`Net.encode/decode`, 12 Hz,
  14 bytes por criatura) e os nomes de atributos/canais estão no ARCHITECTURE.md.
  Mudou um? Atualize servidor, cliente **e** o documento no mesmo trabalho.
- **Canais estreitos.** Uma ação com nome claro (`Lobby("buy", id)`), payload
  checado com `typeof`, limites (`#value`, inteiros) e limite de frequência
  (`throttled(player)` em Main) quando a ação mexe em progresso ou é cara.
  Nada de RemoteFunction que o servidor espere do cliente.
- **Módulos profundos.** Muita lógica atrás de uma interface pequena e estável.
  Teste da deleção: se apagar o módulo só move a complexidade de lugar, ele era
  um repasse (incorpore); se a complexidade se espalharia por vários chamadores,
  ele se paga (aprofunde). Não crie indireção para uma implementação só.
- **Um módulo por responsabilidade.** Comentários e textos em português,
  identificadores em inglês, tabs. Nada de número solto fora de Balance/BossData
  (visual puro pode ficar no arquivo que desenha).
- **Paridade com o Godot.** Mudança de regra que também vale no Godot? Diga ao
  usuário; não diverja em silêncio.

## Refatoração segura

- Leia todos os arquivos afetados antes; `Grep` todos os chamadores.
- Não misture limpeza com mudança de comportamento no mesmo commit.
- Preserve contratos de rede, a não ser que a migração seja o objetivo.
- Alvos típicos: constantes duplicadas entre cliente e servidor, número mágico
  que devia estar em Balance, conexão de evento repetida sem `Disconnect`,
  responsabilidade que vaza pelo limite cliente/servidor, código morto.
- Para cada oportunidade, diga: arquivos, atrito hoje, mudança, benefício.

## Verificação (sempre, antes de dizer que terminou)

1. Blocos e parênteses:
   `find roblox/src -name '*.luau' -print0 | xargs -0 perl roblox/tools/luau_blocks.pl | grep -v ': OK$'`
   (sem saída = ok; não pega erro de tipo nem de nome, então releia o diff).
2. Traduções: `powershell -ExecutionPolicy Bypass -File roblox/tools/i18n_check.ps1`.
3. Montagem: `powershell -ExecutionPolicy Bypass -File roblox/build.ps1`.
   Se `roblox/build/Fogkeeper.rbxlx.lock` existir, o Studio está com o arquivo
   aberto: avise que é preciso reabrir.
4. Teste no Studio, por um destes caminhos:
   - **Com Studio MCP** (ferramentas `mcp__Roblox_Studio__*` disponíveis; se
     estiverem adiadas, carregue com ToolSearch): `list_roblox_studios` →
     `get_studio_state` → `start_stop_play` → `get_console_output`, com
     `screen_capture` para o visual. Use o MCP para **inspecionar e testar**;
     correções vão nos arquivos de `roblox/src` e numa nova montagem, nunca só
     no Studio (`multi_edit`/`execute_luau` não voltam para o Git).
   - **Sem MCP:** peça ao usuário para reabrir o `.rbxlx`, rodar o roteiro da
     skill `roblox-playtest` (ou só os passos que importam) e mandar as linhas
     vermelhas de View > Output e prints. Diga exatamente o que clicar e o que
     deveria aparecer.

## Commits

Português, `tipo: resumo` (`feat`, `fix`, `ui`, `art`, `balance`, `refactor`,
`docs`, `chore`), sem linha Co-Authored-By. Só faça commit quando o usuário pedir.

## Antipadrões

- Editar no Studio e esquecer os arquivos.
- Cliente decidir dano, recompensa ou posse de passe.
- Mudar o Snapshot ou um atributo sem atualizar o ARCHITECTURE.md.
- Criar "Manager"/"Handler" genérico que só repassa chamadas.
- Dizer "pronto" sem rodar luau_blocks, i18n_check e build.
