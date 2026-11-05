---
name: roblox-playtest
description: "Roteiro de teste da versão Roblox do Fogkeeper no Roblox Studio: sozinho, cooperativo com 2–4 jogadores (Clients and Servers), modos (normal, desafio diário, Modo Chefões, sem fim, tutorial), compras de teste (passes, óleo, reacender o farol), salvamento ao sair e voltar, celular (emulador de dispositivo), controle e desempenho. Funciona com Studio MCP ou guiando o usuário e lendo prints e o Output. Use para verificar uma mudança, preparar uma versão, testar no celular ou quando perguntarem se a versão Roblox funciona. EN triggers: Roblox playtest, QA, test in Studio, mobile playtest, device emulator, touch test, multiplayer test, does it work."
---

# Fogkeeper Roblox: teste

Um teste prova comportamento **e** sensação. Rode só os blocos que a mudança
toca, mais o bloco 0; antes de publicar, rode todos. Não marque nada como
pronto sem o "ok" do usuário, mesmo com o teste passando.

## Como executar

- **Com Studio MCP:** `list_roblox_studios` → `set_active_studio` se houver mais
  de um → `get_studio_state` → `start_stop_play`; mova com
  `character_navigation`, use `user_keyboard_input`/`user_mouse_input`, confira
  estado com `inspect_instance` (atributos de `FogkeeperNet.State` e do
  `Player`), registre com `screen_capture` e leia `get_console_output` no fim.
- **Sem MCP:** mande ao usuário só os passos necessários, numerados, com o
  resultado esperado de cada um, e peça: as linhas vermelhas e amarelas de
  View > Output, prints dos momentos-chave e o que pareceu estranho.

## Roteiro

**0. Montar e abrir.** `powershell -ExecutionPolicy Bypass -File roblox/build.ps1`,
reabrir `roblox/build/Fogkeeper.rbxlx`, deixar View > Output aberto. Sem API
Services, o aviso "progresso ... não carregou" ou o progresso só na memória é
esperado.

**1. Sozinho (Play, F5).** Saguão abre com o menu completo · Jogar → mapa,
farol, dificuldade, maré → história (pular funciona) → partida. Em poucos
segundos o jogador está mirando a luz. Feixe segue o cursor, Q/E/R usam
habilidades, nível abre cartas (1–4), T troca, B bane. Chefe aparece com aviso,
barra e relíquia ao morrer. Fim mostra pontuação e óleo; oficina e desbloqueio
gastam óleo certo. Configurações: idioma, tamanho do texto, daltonismo, reduzir
piscantes e volume mudam na hora.

**2. Cooperativo (Test > Clients and Servers, 2 a 4 jogadores).** Só a vaga 1
(👑) escolhe mapa/dificuldade/maré/modo; os outros escolhem faroleiro e
habilidades e marcam Pronto. Cada feixe sai do próprio avatar. Cada um recebe
a própria escolha de cartas sem pausar. Qualquer um pausa e retoma; a pausa
acaba sozinha em `Balance.PAUSE_MAX`. Um jogador sai no meio: a noite continua
e a vaga libera. Sem fim: votação ao amanhecer. Todos recebem recompensas.

**3. Modos.** Desafio diário com as mesmas regras em todos os clientes e
ranking próprio · Modo Chefões (os 15 em sequência) · maré alta · tutorial
completo (só um jogador; libera a conquista).

**4. Compras** (só com ids reais em `shared/Monetization.luau`; com `id = 0`, a
loja deve mostrar "Indisponível"). No Studio as compras são de teste. Passe
comprado aparece em `Passes` e libera o efeito (cor do feixe, selo VIP, brasas
douradas, faróis lendários só para o anfitrião). Barril soma o óleo certo uma
vez só. **Reacender:** deixe o farol cair no Normal → noite congela por
`REVIVE_WINDOW` s, todos veem o botão → compra volta com metade da vida e
criaturas atordoadas → partida não entra no ranking. Não aparece no diário,
no Modo Chefões nem no tutorial; compra tardia vira óleo.

**5. Salvamento** (experiência publicada com API Services ligado). Ganhar óleo,
comprar na oficina, mudar configuração → sair e voltar: tudo igual. Compra não
é entregue duas vezes. Ranking mostra a pontuação.

**6. Celular** (Test > Device, emulador). Um celular pequeno em paisagem e um
tablet: toque fora dos botões aponta a lanterna; botões de habilidade, pausa
(II) e cartas alcançáveis com o polegar e sem cobrir o mar; textos cabem com o
maior tamanho de texto; nada importante sob a barra do Roblox ou o entalhe;
menus rolam. Nenhuma ação exige teclado.

**7. Controle** (emulador de controle ou um real). Navegação dos menus com foco
visível, A confirma, B volta; LB/RB/Y nas habilidades; direcional nas cartas;
dicas de tecla mudam para botões do controle.

**8. Desempenho.** Difícil ou Impossível, maré alta, 4 jogadores, perto do pico
da noite: F9 (Network e Memory) e sensação de fluidez no emulador de celular.
Detalhes em `roblox-performance`.

**9. Output.** Nenhum erro vermelho novo em servidor e clientes; nenhum
"Infinite yield".

## Relatório

O que foi testado (blocos e como) · evidências (prints, trechos do Output) ·
passou/falhou por bloco · bugs por impacto no jogador (cada um vira trabalho
para `roblox-debug`) · próximo teste recomendado.
