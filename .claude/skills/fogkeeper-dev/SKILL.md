---
name: fogkeeper-dev
description: "Guia de desenvolvimento do jogo Fogkeeper (Godot 4, GDScript), um survivors-like em que um farol fixo gira um feixe de luz contra criaturas da névoa. Use esta skill sempre que for mexer no projeto Fogkeeper (antes chamado Farol), mesmo em pedidos curtos: criar ou ajustar inimigos, melhorias (upgrades), chefes, balanceamento, HUD, input, efeitos visuais, áudio, salvamento, Steam (GodotSteam, conquistas, builds) ou revisar código e commits do repositório. Também use quando o usuário falar em \"o jogo do farol\", \"a luz\", \"o feixe\", \"as brasas\" ou \"a névoa\" neste contexto."
---

# Fogkeeper — guia de desenvolvimento

Fogkeeper é um jogo de sobrevivência por ondas: o jogador não se move, só gira o feixe do farol. A luz queima inimigos e também recolhe as brasas (XP) que eles deixam, então mirar é sempre uma escolha entre atacar e coletar. Essa tensão é o coração do jogo; proteja-a ao propor mudanças.

Leia `references/game-design.md` antes de propor mecânicas novas e `references/steam-release.md` antes de qualquer trabalho de publicação.

## Stack e estrutura

- Godot **4.4** (renderer GL Compatibility, para rodar em PCs fracos e no Steam Deck), GDScript com tipagem estática.
- Tudo é gerado por código: não há assets binários ainda. Visual vem de `_draw()`, sons são sintetizados em `scripts/audio/sfx.gd` e a UI é construída em código a partir de `UiTheme`.

```
scenes/main.tscn          Cena única; raiz com scripts/core/main.gd
scripts/core/
  main.gd                 Estados da partida, XP, níveis, pontuação, fim de jogo, autoplay
  balance.gd              TODOS os números: inimigos, dificuldades, pontuação
  upgrades.gd             Catálogo de melhorias + apply()
  game_input.gd           Ações de input registradas em runtime (jogo e menus)
  settings.gd             Preferências (user://settings.cfg): idioma, gráficos, volumes
  records.gd              Histórico e ranking local (user://records.json) + formatação
  day_cycle.gd            Paleta de luz ao longo da partida (crepúsculo → amanhecer)
  i18n.gd                 Traduções PT/EN/ES (chave = texto em português)
scripts/audio/sfx.gd      Sons e música sintetizados numa thread; barramentos Music/SFX/Damage
scripts/gameplay/         lighthouse, beam, enemy, ember, pulse_wave, spawner, burn_fx
scripts/world/            background (mar, ilha, cenário), fog (névoa, chuva, gaivotas, vinheta)
scripts/ui/
  hud.gd                  HUD da partida e troca de telas
  ui_theme.gd             Paleta, fontes, botões, divisores (identidade visual)
  ornate_panel.gd, ornate_bar.gd, dawn_clock.gd, choice_card.gd, card_picker.gd, icons.gd
  screens/                Uma tela por arquivo (título, dificuldade, nível, pausa, fim,
                          configurações, histórico, ranking), todas herdando MenuScreen
tools/check.sh            Carrega o projeto em headless, falha se houver erro, roda i18n_check
tools/i18n_check.sh       Falha se algum texto traduzível não estiver em i18n.gd
tools/autoplay.sh         Roda N partidas com bot e mostra a taxa de vitória
```

## Convenções

- **Identificadores em inglês, textos do jogador em português.** Comentários e docstrings (`##`) em português.
- **Todo texto visível passa por tradução.** Use `tr("texto em português")` (ou `TranslationServer.translate` em função estática) com string literal e formate depois: `tr("Nível %d") % n`. Adicione a linha `"texto": ["inglês", "espanhol"]` em `I18n.TEXTS`; textos de dados (`name`/`desc` em Balance e Upgrades, `text` em DayCycle) também. `tools/i18n_check.sh` acusa o que faltar. Labels são criados com `auto_translate_mode` desligado (via `UiTheme.label`), então traduza explicitamente.
- **UI usa `UiTheme`.** Cores, fontes, botões e painéis saem de `UiTheme`/`OrnatePanel`; não crie `StyleBoxFlat` solto nas telas. Telas novas herdam `MenuScreen`, montam o conteúdo em `_build()`, definem `default_focus` (navegação por teclado/controle) e tratam "voltar" em `go_back()`. Interações que pedem som chamam `Sfx.play(&"id")`.
- **Visual segue o dia e a qualidade.** Cenário lê cores de `DayCycle.p` e detalhe de `Settings.quality` (0 baixa, 1 média, 2 alta). Efeitos puramente visuais usam `randf()` global, nunca o `rng` da partida, para não mudar a semente do autoplay.
- **Um script por classe, com `class_name`.** Tipos explícitos em variáveis e retornos (`var x := 0.0`, `-> void`). Evite `Variant` solto exceto ao ler dicionários de dados.
- **Números ficam em `balance.gd`.** Nenhum valor de jogo (vida, dano, velocidade, tempos) deve aparecer literal em outro script; isso mantém o balanceamento em um lugar e o autoplay confiável. Ajustes puramente visuais (cores de desenho, espessuras) podem ficar no script que desenha.
- **O farol fica na origem.** O mundo é centrado em (0, 0); muita lógica usa `position.length()` e `position.angle()` como distância e ângulo até o farol. Não mova o farol nem a raiz `World`.
- **Pausa:** `Main`, `Hud`, `Sfx` e a câmera usam `PROCESS_MODE_ALWAYS`; tudo dentro de `World` é `PAUSABLE`, exceto `Background` e `Fog`, que são só visuais e continuam animando nos menus. Coisas novas de gameplay vão dentro de `World`, coisas de interface dentro do `Hud`.
- **Dificuldade é multiplicador.** `Balance.DIFFICULTIES` escala vida, dano, ritmo, XP e pontuação. "normal" fica todo em 1.0 porque é a referência do autoplay.
- **Pontuação** vem só de `Balance.score_breakdown()`; o ranking ordena por pontos, depois nível, depois data. Mudou a fórmula? Atualize o texto de regras do ranking (ele é montado a partir das constantes).
- **Colisão é matemática, não física.** O feixe testa ângulo e distância (`Beam.covers`). Mantenha assim enquanto o número de inimigos couber; só migre para áreas/física se o profiler pedir.

## Receitas

**Novo inimigo**
1. Adicione uma entrada em `Balance.ENEMIES` (`hp`, `speed`, `radius`, `damage`, `xp`, `score`, `color`; `"boss": true` para chefes).
2. Inclua o tipo em `Balance.spawn_weights()` (a partir de que tempo e com que peso) ou em `BOSS_TIMES` para eventos.
3. Se ele tiver comportamento próprio, prefira uma subclasse de `Enemy` sobrescrevendo `_process`/`_draw` e ajuste `Spawner.spawn()` para instanciá-la; não encha `enemy.gd` de `if kind ==`.
4. Rode `tools/autoplay.sh 10` antes e depois e reporte a diferença.

**Nova melhoria**
1. Entrada em `Upgrades.LIST` com `id`, `name`, `desc` (curta, no imperativo ou descritiva, cabendo em uma linha) e `max`.
2. Caso correspondente em `Upgrades.apply()`. Se criar um novo atributo no farol, inicialize-o em `Lighthouse.reset()`.
3. Melhorias que adicionam fontes de luz chamam `lh.rebuild_beams()`.
4. Traduza `name` e `desc` em `I18n.TEXTS` e desenhe um ícone para o `id` em `Icons.draw()` (aparece na carta de escolha).

**Nova tela de menu**
1. Classe em `scripts/ui/screens/` herdando `MenuScreen`; monte tudo em `_build()` com `centered_panel()`, `title()`, `text()`, `add_button()`, `stat_row()`.
2. Defina `default_focus` e, se a tela não puder ser fechada com Esc, sobrescreva `go_back()` retornando `false`.
3. Adicione um `show_*()` em `Hud` e, para inspeção visual, um caso em `Main._open_debug_ui()`.

**Novo som**
Escreva uma função `_s_nome(t) -> float` em `Sfx` (amostra no tempo `t`, entre -1 e 1), registre em `_synthesize_all()` e toque com `Sfx.play(&"nome")`. Sons que podem disparar muitas vezes por segundo entram em `THROTTLE`. Som de dano usa o barramento `Damage` (volume próprio nas configurações).

**Mudança de balanceamento**
Mude só `balance.gd`, rode `tools/autoplay.sh 10` e mostre a taxa de vitória e o tempo médio de morte. Referência atual: o bot (mira no mais próximo, escolhas aleatórias) vence cerca de 4 em 10. Um bot vencendo quase sempre significa que o jogo ficou fácil para humanos; quase nunca, que ficou punitivo. O bot é só um termômetro: decisões finais vêm de playtest humano.

## Verificação obrigatória

Depois de qualquer mudança em código, rode:

```bash
GODOT=/caminho/do/godot tools/check.sh
GODOT=/caminho/do/godot tools/autoplay.sh 5
```

Se não houver Godot no ambiente, baixe a versão 4.4.1 (release oficial em github.com/godotengine/godot) para rodar em headless.

Mudou algo visual? Gere capturas e olhe para elas (`user://screenshot.png`; no Windows, `%APPDATA%/Godot/app_userdata/Fogkeeper/`). Sem monitor, prefixe com `xvfb-run -a` e use `--audio-driver Dummy`:

```bash
godot --path . --resolution 1280x720 -- --ui=levelup --screenshot=3        # telas: difficulty, settings, history, ranking, pause, levelup, end (sem --ui = título)
godot --path . --resolution 1280x720 --fixed-fps 20 -- --autoplay --seed=2 --cycle=320 --screenshot=45   # cenário numa hora do dia (320 = tempestade)
```

Com `--ui` ou `--cycle` o jogo fecha sozinho depois da captura, e partidas de `--ui` não entram no histórico. Para ver histórico/ranking com dados, grave um `records.json` de exemplo na pasta de dados do usuário e apague-o depois; nunca deixe dados falsos no histórico do jogador.

## Commits

Mensagens em português, no formato `tipo: resumo curto` (`feat`, `fix`, `balance`, `ui`, `art`, `audio`, `steam`, `docs`, `refactor`, `chore`). Mudanças de balanceamento citam o resultado do autoplay no corpo do commit.
