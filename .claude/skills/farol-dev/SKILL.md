---
name: farol-dev
description: "Guia de desenvolvimento do jogo Farol (Godot 4, GDScript), um survivors-like em que um farol fixo gira um feixe de luz contra criaturas da névoa. Use esta skill sempre que for mexer no projeto Farol, mesmo em pedidos curtos: criar ou ajustar inimigos, melhorias (upgrades), chefes, balanceamento, HUD, input, efeitos visuais, áudio, salvamento, Steam (GodotSteam, conquistas, builds) ou revisar código e commits do repositório. Também use quando o usuário falar em \"o jogo do farol\", \"a luz\", \"o feixe\", \"as brasas\" ou \"a névoa\" neste contexto."
---

# Farol — guia de desenvolvimento

Farol é um jogo de sobrevivência por ondas: o jogador não se move, só gira o feixe do farol. A luz queima inimigos e também recolhe as brasas (XP) que eles deixam, então mirar é sempre uma escolha entre atacar e coletar. Essa tensão é o coração do jogo; proteja-a ao propor mudanças.

Leia `references/game-design.md` antes de propor mecânicas novas e `references/steam-release.md` antes de qualquer trabalho de publicação.

## Stack e estrutura

- Godot **4.4** (renderer GL Compatibility, para rodar em PCs fracos e no Steam Deck), GDScript com tipagem estática.
- Tudo é gerado por código: não há assets binários ainda. Visual vem de `_draw()`; UI é construída em `scripts/ui/hud.gd`.

```
scenes/main.tscn          Cena única; raiz com scripts/core/main.gd
scripts/core/
  main.gd                 Estados da partida, XP, níveis, fim de jogo, autoplay
  balance.gd              TODOS os números de balanceamento
  upgrades.gd             Catálogo de melhorias + apply()
  game_input.gd           Ações de input registradas em runtime
scripts/gameplay/         lighthouse, beam, enemy, ember, pulse_wave, spawner
scripts/world/            background (mar e ilha), fog (névoa e vinheta)
scripts/ui/hud.gd         HUD e todas as telas (título, pausa, nível, fim)
tools/check.sh            Carrega o projeto em headless e falha se houver erro
tools/autoplay.sh         Roda N partidas com bot e mostra a taxa de vitória
```

## Convenções

- **Identificadores em inglês, textos do jogador em português.** Comentários e docstrings (`##`) em português. Quando chegar a hora de traduzir, os textos visíveis passam por `tr()`; ao criar texto novo, deixe-o fácil de extrair (strings literais, sem concatenação complexa).
- **Um script por classe, com `class_name`.** Tipos explícitos em variáveis e retornos (`var x := 0.0`, `-> void`). Evite `Variant` solto exceto ao ler dicionários de dados.
- **Números ficam em `balance.gd`.** Nenhum valor de jogo (vida, dano, velocidade, tempos) deve aparecer literal em outro script; isso mantém o balanceamento em um lugar e o autoplay confiável. Ajustes puramente visuais (cores de desenho, espessuras) podem ficar no script que desenha.
- **O farol fica na origem.** O mundo é centrado em (0, 0); muita lógica usa `position.length()` e `position.angle()` como distância e ângulo até o farol. Não mova o farol nem a raiz `World`.
- **Pausa:** `Main`, `Hud` e a câmera usam `PROCESS_MODE_ALWAYS`; tudo dentro de `World` é `PAUSABLE`. Coisas novas de gameplay vão dentro de `World`, coisas de interface dentro do `Hud`.
- **Colisão é matemática, não física.** O feixe testa ângulo e distância (`Beam.covers`). Mantenha assim enquanto o número de inimigos couber; só migre para áreas/física se o profiler pedir.

## Receitas

**Novo inimigo**
1. Adicione uma entrada em `Balance.ENEMIES` (`hp`, `speed`, `radius`, `damage`, `xp`, `color`; `"boss": true` para chefes).
2. Inclua o tipo em `Balance.spawn_weights()` (a partir de que tempo e com que peso) ou em `BOSS_TIMES` para eventos.
3. Se ele tiver comportamento próprio, prefira uma subclasse de `Enemy` sobrescrevendo `_process`/`_draw` e ajuste `Spawner.spawn()` para instanciá-la; não encha `enemy.gd` de `if kind ==`.
4. Rode `tools/autoplay.sh 10` antes e depois e reporte a diferença.

**Nova melhoria**
1. Entrada em `Upgrades.LIST` com `id`, `name`, `desc` (curta, no imperativo ou descritiva, cabendo em uma linha) e `max`.
2. Caso correspondente em `Upgrades.apply()`. Se criar um novo atributo no farol, inicialize-o em `Lighthouse.reset()`.
3. Melhorias que adicionam fontes de luz chamam `lh.rebuild_beams()`.

**Mudança de balanceamento**
Mude só `balance.gd`, rode `tools/autoplay.sh 10` e mostre a taxa de vitória e o tempo médio de morte. Referência atual: o bot (mira no mais próximo, escolhas aleatórias) vence cerca de 4 em 10. Um bot vencendo quase sempre significa que o jogo ficou fácil para humanos; quase nunca, que ficou punitivo. O bot é só um termômetro: decisões finais vêm de playtest humano.

## Verificação obrigatória

Depois de qualquer mudança em código, rode:

```bash
GODOT=/caminho/do/godot tools/check.sh
GODOT=/caminho/do/godot tools/autoplay.sh 5
```

Se não houver Godot no ambiente, baixe a versão 4.4.1 (release oficial em github.com/godotengine/godot) para rodar em headless. Para inspecionar o visual sem monitor: `xvfb-run -a godot --path . --audio-driver Dummy --fixed-fps 20 --quit-after 520 -- --autoplay --seed=2 --screenshot=25` salva `user://screenshot.png`.

## Commits

Mensagens em português, no formato `tipo: resumo curto` (`feat`, `fix`, `balance`, `ui`, `art`, `audio`, `steam`, `docs`, `refactor`, `chore`). Mudanças de balanceamento citam o resultado do autoplay no corpo do commit.
