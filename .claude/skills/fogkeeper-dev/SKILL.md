---
name: fogkeeper-dev
description: "Guia de desenvolvimento do jogo Fogkeeper (Godot 4, GDScript), um survivors-like em que um farol fixo gira um feixe de luz contra criaturas da névoa. Use esta skill sempre que for mexer no projeto Fogkeeper (antes chamado Farol), mesmo em pedidos curtos: mapas e histórias, criaturas, chefes, faróis, habilidades ativas, melhorias (upgrades), dificuldades, balanceamento, HUD, menus, teclas, efeitos visuais, áudio e música, histórico, ranking, salvamento, Steam (GodotSteam, conquistas, builds) ou revisar código e commits do repositório. Também use quando o usuário falar em \"o jogo do farol\", \"a luz\", \"o feixe\", \"as brasas\" ou \"a névoa\" neste contexto."
---

# Fogkeeper — guia de desenvolvimento

Fogkeeper é um jogo de sobrevivência por ondas: o jogador não se move, só gira o feixe do farol. A luz queima inimigos e também recolhe as brasas (XP) que eles deixam, então mirar é sempre uma escolha entre atacar e coletar. Essa tensão é o coração do jogo; proteja-a ao propor mudanças.

Leia `references/game-design.md` antes de propor mecânicas novas e `references/steam-release.md` antes de qualquer trabalho de publicação.

## Stack e estrutura

- Godot **4.4** (renderer GL Compatibility, para rodar em PCs fracos e no Steam Deck), GDScript com tipagem estática.
- Tudo é gerado por código: não há assets binários ainda. Visual vem de `_draw()`, sons e músicas são sintetizados em `scripts/audio/sfx.gd` e a UI é construída em código a partir de `UiTheme`.

```
scenes/main.tscn          Cena única; raiz com scripts/core/main.gd
scripts/core/
  main.gd                 Estados, XP, níveis, chefes, relíquias, pontuação, fim de jogo, modo sem fim, autoplay
  progress.gd             Progressão entre partidas (user://progress.json): óleo, oficina, desbloqueios
  achievements.gd         Conquistas locais (unlock() é o ponto único para a Steam)
  bestiary.gd             Fichas do bestiário (lendas) e quais já foram vistas
  damage_stats.gd         Dano por fonte e brasas da partida (resumo do fim)
  steam_service.gd        Ponte com a Steam (GodotSteam); sem o plugin, não faz nada
  tutorial.gd             Tutorial guiado em passos (as dicas de teclas só aparecem aqui)
  trailer.gd              Trailer roteirizado (--trailer=en|pt com --write-movie)
  balance.gd              TODOS os números: criaturas, chefes, habilidades, dificuldades, pontuação
  maps.gd                 Mapas: nome, história, aparência de cada papel de criatura, chefes
  keepers.gd              Faróis selecionáveis (só aparência)
  upgrades.gd             Melhorias, evoluções, relíquias (apply_relic) e oficina (apply_meta)
  game_input.gd           Ações de input; teclas configuráveis (REBINDABLE)
  settings.gd             Preferências (user://settings.cfg): idioma, gráficos, áudio, teclas
  records.gd              Histórico e ranking local (user://records.json) + formatação ("1º lugar")
  day_cycle.gd            Paleta de luz por mapa (entardecer → amanhecer) e relógio 18:00–06:00
  (Balance também tem HEROES, TIDES, as habilidades novas e os números do Modo Chefões)
  i18n.gd                 Traduções PT/EN/ES (chave = texto em português) e carga dos outros idiomas
scripts/i18n/             FR, DE, RU, zh_CN, JA, KO: um arquivo por idioma (const T, mesmas chaves)
scripts/audio/sfx.gd      Sons, trilha dinâmica (calma por mapa, tensão, batalha), grupos de som
scripts/gameplay/
  enemy.gd                Criatura: papel + arte do mapa, elite, atordoamento e os papéis especiais
                          (thief, mirror, moth, fogbank)
  creature_art.gd         Desenho de cada criatura (espectro, draugr, saci, mapinguari...)
  bosses/                 Boss (base) e um script por chefe: leviathan, kraken, jotunn, fenrir,
                          iara, boitata, cuca, umibozu, kyubi, sphinx, apep
  lighthouse.gd, lighthouse_art.gd, beam, ember, pulse_wave, spawner, abilities, burn_fx, ring_fx
scripts/world/            background (Baía), fjord_background (Fiorde), river_background (Rio), japan_background, desert_background,
                          fog (névoa, chuva, neve, aurora, vaga-lumes)
scripts/ui/
  hud.gd                  HUD, barra do chefe, habilidades, fila de avisos, registro e troca de telas
  ui_theme.gd             Paleta, fontes, botões, divisores (identidade visual)
  ornate_*, dawn_clock, ability_bar, choice_card, card_picker, icons
  screens/                Uma tela por arquivo (título, mapa, farol, dificuldade, história, nível,
                          pausa, fim, configurações, histórico, ranking, oficina, conquistas,
                          confirmação), todas herdando MenuScreen
tools/check.sh            Carrega o projeto em headless, falha se houver erro, roda i18n_check
tools/i18n_check.sh       Falha se algum texto traduzível não estiver em i18n.gd
tools/autoplay.sh         N partidas com bot: autoplay.sh 10 --difficulty=hard --map=fjord
tools/export.sh           Gera icon.ico e exporta build/windows/Fogkeeper.exe (atalho da área de trabalho)
tools/store_art.gd         Gera a arte da loja da Steam em docs/store/ (precisa de janela)
```

## Convenções

- **Identificadores em inglês, textos do jogador em português.** Comentários e docstrings (`##`) em português.
- **Todo texto visível passa por tradução.** Use `tr("texto em português")` (ou `TranslationServer.translate("...")` em função estática) com string literal e formate depois: `tr("Nível %d") % n`. Adicione `"texto": ["inglês", "espanhol"]` em `I18n.TEXTS`; textos de dados (`name`, `desc`, `story`, `tagline`, nomes de criaturas, ações e grupos de som) também. `tools/i18n_check.sh` acusa o que faltar. Labels são criados com `auto_translate_mode` desligado (via `UiTheme.label`), então traduza explicitamente. Texto novo também precisa entrar em cada `scripts/i18n/*.gd` (o i18n_check confere); para gerar a lista de chaves, despeje `I18n.TEXTS` em JSON e traduza por idioma.
- **UI usa `UiTheme`.** Cores, fontes, botões e painéis saem de `UiTheme`/`OrnatePanel`. Telas novas herdam `MenuScreen`, montam o conteúdo em `_build()`, definem `default_focus` e tratam "voltar" em `go_back()`. Interações que pedem som chamam `Sfx.play(&"id")`; todo som novo entra num grupo de `Sfx.SOUND_GROUP` (o jogador pode desligá-lo).
- **Avisos vão por `Hud.announce()`.** Eles entram numa fila, aparecem numa camada acima de qualquer menu e ficam no registro de eventos. Avisos de chefe usam `big = true`; a escolha de melhoria espera ~2 s depois deles (`Hud.alert_blocking()`).
- **Visual segue mapa, dia e configurações.** Cenário lê `DayCycle.p` e `Settings.quality`/`particles`/`weather`/`lightning_flash`. Efeitos puramente visuais usam `randf()` global, nunca o `rng` da partida.
- **Um script por classe, com `class_name`.** Tipos explícitos em variáveis e retornos. Valores lidos de dicionários precisam de tipo explícito (`var x: float = d["k"]`), senão o GDScript não infere.
- **Números ficam em `balance.gd`.** Nenhum valor de jogo (vida, dano, velocidade, tempos, recargas) deve aparecer literal em outro script. Ajustes puramente visuais podem ficar no script que desenha.
- **Criaturas: estatística por papel, aparência por mapa.** `Balance.ENEMIES` tem os papéis (basic, fast, brute, thief, mirror, moth, fogbank, tentacle, boulder); `Maps.LIST[mapa].creatures` diz qual arte cada papel usa. Assim um mapa novo não exige rebalancear tudo.
- **O farol fica na origem.** O mundo é centrado em (0, 0). Não mova o farol nem a raiz `World` (é a câmera que desliza no menu).
- **Pausa:** `Main`, `Hud`, `Sfx` e a câmera usam `PROCESS_MODE_ALWAYS`; tudo dentro de `World` é `PAUSABLE`, exceto cenário e névoa, que continuam animando nos menus.
- **Dificuldade muda regras, não só números.** `Balance.DIFFICULTIES` tem multiplicadores e regras (elites, duração das brasas, fúria dos chefes, chefe extra, vida do farol, névoa). "normal" é a referência do autoplay.
- **Pontuação** vem só de `Balance.score_breakdown()` (criaturas, tempo, chefes, vitória, vida → subtotal × dificuldade). O texto de regras do ranking é montado das constantes; confira a tela se mudar a fórmula.
- **Colisão é matemática, não física.** O feixe testa ângulo e distância (`Beam.covers`); quem está `invulnerable` ignora a luz. `take_light(amount, reflect)`: só o feixe principal passa `reflect = true` (espelhos devolvem parte dele). Quem é imune à luz agora responde `immune_to_light()` (o bot mira em outro).
- **Progressão é leve e opcional para o balanceamento.** `Progress.enabled` é falso no autoplay (sem bônus da oficina, tudo liberado) e `read_only` nas capturas `--ui`. Bônus permanentes entram em `Upgrades.apply_meta()` e em `Progress.level()`; desbloqueios em `Balance.UNLOCKS`.
- **Dicas de teclas só no tutorial.** As telas normais não mostram "A/D ou ←/→..."; o tutorial (`Tutorial._refresh`) e a escolha de melhoria com `show_hints` mostram, com as teclas reais de `Settings.controls`.
- **Golpes fortes têm peso.** Use `Main._ring_fx()`, `_hit_stop()` (respeita `Settings.hit_stop`) e `_shake`; nada disso roda no autoplay.

- **Modos da partida:** `Main.mode` é "normal", "daily" ou "boss_rush"; o registro guarda `mode`, `hero`, `tide` e o ranking separa por modo (`Records.ranking(dif, mapa, modo, dia)`). Regras fixas do diário vêm de `Records.daily_rules()`.
- **Legal:** nada de nomes, visuais ou bordões de obras protegidas (por isso a Cuca é grisalha). Fontes e bibliotecas novas precisam de licença compatível e entrada em `THIRD_PARTY_NOTICES.md` e na tela de créditos. Ver `docs/LEGAL.md`.

## Receitas

**Nova criatura comum (num mapa)**
1. Desenhe a arte em `CreatureArt` (novo caso no `match` e função `_nome`), com +x apontando para o farol e usando `c()` para a cor de queima.
2. Aponte o papel para ela em `Maps.LIST[mapa].creatures`; nome visível em `Maps.CREATURE_NAMES` + tradução.
3. Papel novo (comportamento ou números diferentes)? Entrada em `Balance.ENEMIES` e em `spawn_weights()`.

**Novo chefe**
1. Números em `Balance.BOSSES[id]` (vida, raio, dano, XP e os da mecânica) e relíquia em `Balance.RELICS[id]` + caso em `Upgrades.apply_relic()`.
2. Script em `scripts/gameplay/bosses/` estendendo `Boss`: `begin(angle)` posiciona, `_move(delta)` é a mecânica, `_draw()` a arte. Use `rate()` (fúria) e `lit_factor()`; lacaios via `spawn_request.emit(papel, posição)`; telegrafe ataques fortes no desenho.
3. Registre em `Spawner.BOSS_SCRIPTS`, coloque em `Maps.LIST[mapa].bosses` e nomes em `CREATURE_NAMES`/`BOSS_TITLES`.
4. Inspecione com `--ui=boss --map=...` e rode o autoplay no mapa.

**Novo mapa**
Entrada em `Maps.LIST` e em `Maps.ORDER` (história curta: como o faroleiro chegou ali; ela aparece antes da partida), arte de todos os papéis, paleta em `DayCycle.PALETTES` + `EVENTS`, cenário (classe que estende `Background`, ligada ao `scenery` em `Main._set_map`), desbloqueio em `Balance.UNLOCKS`, trilha calma em `Sfx._synthesize_all` (`music_<id>`), clima em `Fog`, prévia em `MapScreen.draw_preview`.

**Nova melhoria**
1. Entrada em `Upgrades.LIST` com `id`, `name`, `desc` e `max`; caso em `Upgrades.apply()`. Atributo novo no farol → inicialize em `Lighthouse.reset()`.
2. Melhorias que adicionam fontes de luz chamam `lh.rebuild_beams()`.
3. Traduza `name` e `desc` e desenhe um ícone em `Icons.draw()`.

**Nova evolução**
Entrada em `Upgrades.EVOLUTIONS` com `needs` (duas melhorias que precisam estar no máximo), caso em `Upgrades.apply()` (efeito costuma ser uma flag no farol), ícone em `Icons._evolution()` e traduções.

**Nova conquista**
Entrada em `Achievements.LIST` e um `Achievements.unlock("id")` no momento certo (ou em `check_run()` se depender do resultado). Traduza nome e descrição.

**Nova habilidade ativa**
Entrada em `Balance.ABILITIES` (id, nome, descrição, recarga), caso em `Abilities.use()`, ícone em `Icons.draw()`, ação `ability_N` em `GameInput.REBINDABLE` e `ACTION_NAMES`, e um espaço a mais em `AbilityBar`.

**Nova tela de menu**
Classe em `scripts/ui/screens/` herdando `MenuScreen`; `show_*()` em `Hud`; caso em `Main._open_debug_ui()` para capturas.

**Novo som**
Função `_s_nome(t) -> float` em `Sfx`, registrada em `_synthesize_all()`, com grupo em `SOUND_GROUP`. Sons frequentes entram em `THROTTLE`.

**Mudança de balanceamento**
Mude só `balance.gd` e rode `tools/autoplay.sh 8 --difficulty=D` para cada dificuldade afetada. O bot mira no mais próximo, escolhe melhorias ao acaso e usa habilidades de forma simples. Faixas-alvo do bot (Baía): Fácil ~80%, Normal ~40%, Médio ~20%, Difícil ~5–10%, Impossível 0%. O bot é só termômetro: decisões finais vêm de playtest humano.

## Verificação obrigatória

Depois de qualquer mudança em código, rode:

```bash
GODOT=/caminho/do/godot tools/check.sh
GODOT=/caminho/do/godot tools/autoplay.sh 5
godot --headless --path . --fixed-fps 20 -- --autoplay --tutorial   # o bot faz o tutorial inteiro (passos não podem travar)
```

Se não houver Godot no ambiente, baixe a versão 4.4.1 (release oficial em github.com/godotengine/godot) para rodar em headless. Não rode o jogo em janela ao mesmo tempo que lotes de autoplay: uma instância já travou esperando a outra.

Mudou algo visual? Gere capturas e olhe para elas (`user://screenshot.png`; no Windows, `%APPDATA%/Godot/app_userdata/Fogkeeper/`). Sem monitor, prefixe com `xvfb-run -a` e use `--audio-driver Dummy`:

```bash
godot --path . --resolution 1280x720 -- --ui=boss --map=fjord --screenshot=4   # telas: map, keeper, difficulty, settings, history, ranking, workshop, achievements, story,
                                                                                 # tutorial, pause, levelup, end, victory, boss, endless
godot --path . --resolution 1280x720 --fixed-fps 20 -- --autoplay --seed=2 --map=fjord --cycle=180 --screenshot=45   # cenário numa hora do dia
```

Com `--ui` ou `--cycle` o jogo fecha sozinho depois da captura, e partidas de `--ui` não entram no histórico. Para ver histórico/ranking com dados, grave um `records.json` de exemplo na pasta de dados do usuário e apague-o depois; nunca deixe dados falsos no histórico do jogador.

## Commits

Mensagens em português, no formato `tipo: resumo curto` (`feat`, `fix`, `balance`, `ui`, `art`, `audio`, `steam`, `docs`, `refactor`, `chore`). Mudanças de balanceamento citam o resultado do autoplay no corpo do commit.
