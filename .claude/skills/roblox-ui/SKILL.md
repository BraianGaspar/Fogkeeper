---
name: roblox-ui
description: "Interface, UX, tradução, acessibilidade e sensação (feedback) da versão Roblox do Fogkeeper: telas em client/Ui (App, Theme, Hud, LevelUp, Shop, Workshop...), HUD da partida, celular (toque, áreas seguras, polegar), controle (GuiService.SelectedObject), Text.t e I18n com i18n_check.ps1, tamanho de texto, filtro de daltonismo, reduzir efeitos piscantes, sons e efeitos de recompensa. Use ao criar ou mudar tela, botão, aviso, HUD, loja, onboarding/tutorial, texto visível ou feedback visual/sonoro na versão Roblox. EN triggers: Roblox UI, HUD, ScreenGui, menu, mobile UI, touch controls, safe area, gamepad UI, localization, translation, accessibility, game feel, juice, VFX feedback."
---

# Fogkeeper Roblox: interface e sensação

Princípio: a interface serve a partida. O jogador entra rápido na noite, entende
o que acontece sem ler muito e joga bem no celular, no PC e no controle.
Edite seguindo `roblox-code`; atributos que a interface lê estão no
`roblox/ARCHITECTURE.md` ("Estado replicado").

## Como a interface é montada

- `client/Ui/App.luau`: um `ScreenGui` (`IgnoreGuiInset = true`,
  `AutoLocalize = false`), pilha de telas (`App.open/replace/back`), avisos
  (`App.announce`, `App.toast`), configurações (`App.setSetting`) e um `UIScale`
  que adapta a tela de referência **1280×720** ao tamanho real.
- `client/Ui/Theme.luau`: cores (`GOLD`, `PANEL`, `TEXT`, `DANGER`...), fontes
  (`HEAD`, `BODY`, `BOLD`) e peças prontas (`panel`, `label`, `button`,
  `smallButton`, `selector`, `toggle`, `slider`, `scroll`, `bar`, `screen`,
  `backButton`, `statRow`, `setSelected`, `setDisabled`). Use sempre o Theme;
  nada de cor ou fonte solta.
- Uma tela por arquivo, `return function(app, params) ... end`, como
  `TitleScreen.luau`. Dados de jogo para telas vêm de `Ui/Data.luau`.
- O cliente nunca decide valor: botão de comprar/liberar manda
  `Lobby("buy"|"meta"|..., id)` e a tela se atualiza quando o atributo
  (`Oil`, `ProgressJson`, `Passes`) muda.

## Receita: tela nova

1. Arquivo em `client/Ui/`, montado com o Theme, dentro da referência 1280×720.
2. Ponto de entrada (botão no saguão ou no menu) com `app.open("NomeTela")`.
3. Foco do controle definido (o App usa `GuiService.SelectedObject`) e "voltar"
   funcionando (B, Esc, botão).
4. Estados: normal, vazio (nada desbloqueado), carregando (`ProgressJson` ainda
   não chegou), indisponível (produto com `id = 0`) e bloqueado.
5. Todo texto com `Text.t`/`Text.format`; os novos em `shared/I18n/extra.luau`.
6. Telas grandes ou que mudam a partida: descreva o esboço (o que aparece, onde,
   estados, no celular) e confirme com o usuário antes de construir.

## Celular e controle

- Tudo funciona por toque e por controle; nada só de teclado. Dicas de tecla
  trocam para botões do controle quando ele é usado (já existe; mantenha).
- Alvos de toque grandes (perto de 44 px reais ou mais) e afastados entre si.
- Com `IgnoreGuiInset = true`, a interface vai até o topo: deixe a faixa de
  cima (botões do Roblox) e os cantos livres de botões importantes, e respeite
  o entalhe em paisagem.
- O toque fora dos botões aponta a lanterna e gira a câmera: botões da partida
  (habilidades, pausa, cartas) não podem cobrir o mar à frente do farol.
- As cartas aparecem num canto e a partida não pausa: devem caber sem esconder
  criaturas, com toque fácil.
- Textos não podem estourar caixas no menor celular e com o maior
  `text_scale` (`Theme.TEXT_SCALES`).

## Tradução

- Chave = texto em português. Use o mesmo texto do Godot quando existir (os 9
  idiomas vêm de lá). Novos em `extra.luau`, com todas as línguas.
- Rode `powershell -ExecutionPolicy Bypass -File roblox/tools/i18n_check.ps1`.
- Deixe folga: alemão e russo ficam ~30% maiores; chinês, japonês e coreano
  precisam de altura, não de largura.
- Frases curtas e diretas, sem trocadilho que não traduz; números e tempos
  formatados por `Text.format`.

## Acessibilidade (já existe; respeite em tudo novo)

- `text_scale`: toda fonte passa por `Theme.textScale`.
- `colorblind`: nunca informe estado só por cor (use ícone, forma ou texto).
- `reduce_flashes`: flashes, neon e fagulhas novos checam a opção (o Renderer e
  `App.flashScreen` já checam). `shake`: tremor de câmera só se ligado.
- Contraste: texto claro sobre `PANEL`, nunca sobre o mar ou o céu sem fundo.

## Sensação e feedback

- Camadas: som (`client/Sounds.luau`), efeito (`Renderer.emit`), interface
  (barras enchem, números sobem, aviso) e mundo (criatura reage à luz).
- Cada momento importante tem resposta clara e curta: brasa coletada, nível,
  carta, chefe surgindo (`boss_warning`, aviso grande), chefe derrotado,
  relíquia, conquista, desbloqueio, compra (`Fx "purchase"`).
- Feedback esclarece o estado, não o esconde. Raridade diferente com o mesmo
  vocabulário de som e cor. Tudo dentro do orçamento de `roblox-performance`.
- Avisos pela fila (`App.announce`), não por popup que bloqueia a partida.

## Onboarding

O tutorial (`server/Tutorial.luau`, um jogador) ensina fazendo. Fora dele, nada
de parede de texto: o jogador deve estar mirando a luz em poucos segundos depois
de começar. A história do mapa pode ser pulada.

## Verificação

Rodar o roteiro de `roblox-playtest` (parte de celular e controle) e mandar
prints em 3 tamanhos: celular pequeno em paisagem, tablet e PC.

## Antipadrões

- Tela que só funciona com mouse; botão sem foco de controle.
- Texto literal sem `Text.t`; cor/fonte fora do Theme.
- Interface que concede valor ou confia no próprio estado em vez do atributo.
- Popup de loja durante a partida (exceto o reviver, que é do momento).
