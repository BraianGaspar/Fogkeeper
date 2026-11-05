# Fogkeeper Roblox: arquitetura e contratos

Este documento é a fonte de verdade para quem mexe em `roblox/src`. Ele vale
para pessoas e para agentes. O conteúdo é o mesmo do jogo em Godot (`scripts/`):
os números, os textos em português (que são as chaves de tradução) e as
mecânicas vêm de lá. O que muda é que o jogo é **cooperativo**: até 4
faroleiros, cada um com o próprio feixe, defendem o mesmo farol.

## Regras gerais

- **Unidades.**
  - A simulação usa as mesmas unidades do Godot. O farol fica em (0, 0); x vai
    para a direita e y para baixo na tela.
  - No mundo 3D, `(x, y)` vira `Vector3(x * S, altura, y * S)`, com
    `S = Balance.STUDS_PER_UNIT = 0.25` (ilha com ~18 studs de raio).
  - Cenários (`server/Scenery`, `Kit.S = 0.1`) e alturas fixas do Renderer
    foram desenhados em 0,1. O `World` monta tudo nessa escala e aplica
    `Model:ScaleTo(Balance.WORLD_SCALE)` em volta do farol; o Renderer
    multiplica as alturas por `WORLD_SCALE`.
  - Ângulo `a` aponta para `(cos a, sin a)`.
- **Avatares e feixes.**
  - Cada jogador anda pela ilha com o avatar do Roblox, em terceira pessoa
    (`server/Avatars.server.luau`: lanterna na mão, sem dano, mureta
    invisível, volta para a ilha se cair).
  - O feixe principal e o do Espelho saem do avatar: o servidor lê o
    `HumanoidRootPart` a cada passo e chama `sim:setOrigin(userId, x, y)`
    (unidades, presa à ilha + `Balance.ORIGIN_MARGIN`). Cada fonte de
    `sim:beamSources()` tem `ox, oy`; sem eles, a origem é o farol.
  - Lentes extras, farolete e Sinalizador continuam saindo do farol.
  - Quem testa "feixe principal sobre um ponto" usa
    `BossData.mainBeamOn`, que já considera a origem.
- **Servidor autoritativo.** Dano, vida, brasas, XP, progresso e recompensas
  ficam só no servidor. O cliente só desenha, manda comandos e prevê o giro do
  próprio feixe.
- **Números ficam em `shared/Balance.luau`.** Os números dos chefes ficam em
  `shared/BossData.luau`. Nenhum número de jogo deve aparecer solto em outro
  arquivo; valores só visuais podem.
- **Textos visíveis são em português e passam por `Text.t("...")` ou
  `Text.format("...", {args})`.**
  - Use o mesmo texto do Godot sempre que existir. Assim a tradução dos 9
    idiomas é reaproveitada, porque `shared/I18n/*.luau` é gerado a partir de
    `scripts/core/i18n.gd` e `scripts/i18n/*.gd`.
  - Um texto novo entra em `shared/I18n/extra.luau`.
- **Estilo.** Luau, comentários e nomes de texto em português, identificadores
  em inglês, tabs. Um módulo por responsabilidade.
- **Nada de obras protegidas.** A Cuca é grisalha. Nenhum visual imita filme,
  série ou outro jogo.
- **Montagem.** `roblox/build.ps1` gera `roblox/build/Fogkeeper.rbxlx`. As
  subpastas de `src/*` viram Folders; `X.server.luau` vira Script,
  `X.client.luau` vira LocalScript e `X.luau` vira ModuleScript. O serviço
  Lighting vai no XML com `Technology = 4` (Future), que não é scriptável.
- **Gráficos.**
  - **Água.** `Kit.sea(m, cor)` faz a peça "Sea" virar o fundo do mar, com o
    topo em `Kit.SEABED`, e marca o modelo com o atributo `Water`. Depois do
    `ScaleTo`, o `World` enche o mar com água do Terrain até y = 0, em studs
    finais, e limpa o Terrain ao trocar de mapa.
  - **Gelo.** `Kit.sea(m, cor, "ice")` faz uma placa de gelo, sem água (é o
    caso do fiorde).
  - **Cor da água.** `DayCycle` muda `Terrain.Water*` pela paleta (tabela
    `WATER`), e só quando o valor muda.
  - **Sombras.** Peças de cenário não fazem sombra, a não ser com
    `CastShadow = true` (árvores, casas e pedras da ilha). A lâmpada do farol
    tem `Shadows = true`.
  - **Lanterna.** O SpotLight `FkAimLight` fica num Attachment do
    `HumanoidRootPart`; o `Renderer` ajusta cor, abertura e alcance pelo
    feixe.
  - **Partículas.** Ficam no `Renderer` (`emit`), num ponto só e com limite
    por segundo. Dependem da qualidade gráfica do Roblox e de
    `reduce_flashes`.

## Pastas e donos

| Caminho | Conteúdo |
|---|---|
| `shared/Balance.luau` | Criaturas (papéis), elites, especiais, dificuldades (5), marés, faroleiros (heróis), habilidades (6), pulso, farolete, combustão, oficina (META), desbloqueios, pontuação, modos |
| `shared/BossData.luau` | Números dos 15 chefes, relíquias, horários, fúria |
| `shared/Maps.luau` | 7 mapas: nome, tagline, história, arte de cada papel, chefes, paleta do dia, clima; `ARTS` (lista ordenada de ids de arte); nomes de criaturas e títulos de chefes |
| `shared/Upgrades.luau` | Melhorias, evoluções e sorteio |
| `shared/Achievements.luau` | Conquistas (id, nome, descrição) |
| `shared/Bestiary.luau` | Fichas do bestiário (por mapa) e lendas |
| `shared/Keepers.luau` | Faróis (aparência): classic, stone, iron, crystal |
| `shared/Net.luau` | Canais e formato do Snapshot (**congelado**, ver abaixo) |
| `shared/Text.luau` + `shared/I18n/*.luau` | Tradução |
| `server/Main.server.luau` | Saguão, votações, partidas, modos, recompensas |
| `server/Simulation.luau` | Regras da partida (papéis, feixes, brasas, níveis, melhorias, habilidades, relíquias, marés, sem fim, Modo Chefões) |
| `server/Bosses/<id>.luau` | Mecânica de cada chefe (interface abaixo) |
| `server/Progress.luau` | DataStore por jogador: óleo, oficina, desbloqueios, conquistas, bestiário, estatísticas, configurações, histórico |
| `server/Scores.luau` | Rankings (DataStores ordenados) |
| `server/World.luau` + `server/Scenery/<mapa>.luau` | Cenário de cada mapa e o farol (com a aparência do farol escolhido) |
| `client/Client.client.luau` | Liga câmera, entrada, renderizador, interface, ciclo do dia e sons |
| `client/Renderer.luau` | Criaturas, chefes, brasas, feixes e efeitos |
| `client/Art/<grupo>.luau` | Modelos das criaturas (um arquivo por mapa) e dos chefes (`Bosses.luau`) |
| `client/DayCycle.luau` | Luz, cor, água do Terrain e clima por mapa e hora |
| `client/Sounds.luau` | Sons por id de asset (configuráveis; vazios = silêncio) |
| `client/Ui/*.luau` | Telas: uma por arquivo, mais `Theme.luau` (cores, fontes, peças) e `Hud.luau` |
| `client/Input.luau` | Mouse, teclado, toque e controle |

## Interface dos chefes (`server/Bosses/<id>.luau`)

```lua
local Boss = {}
-- Chamado ao surgir. `e` já tem id, kind (=id), art (=id), hp, maxHp,
-- radius, damage, speed, boss (= BossData[id]), rate() e campos livres.
function Boss.begin(sim, e, angle: number) end
-- Mecânica a cada passo. Use apenas a API pública da simulação (abaixo).
function Boss.step(sim, e, dt: number) end
-- Opcional: multiplicador do dano de luz recebido (0 = imune).
-- `beam` = {owner = userId|nil, main = bool, angle, half, range}.
function Boss.lightFactor(sim, e, beam): number return 1 end
-- Opcional: chamado quando o chefe morre (antes da relíquia).
function Boss.died(sim, e) end
return Boss
```

**API pública da simulação para os chefes:**
- `sim:spawnMinion(role, x, y) -> e`: criatura com o papel dado e a arte do mapa atual.
- `sim:spawnArt(art, role, x, y) -> e`: criatura com arte própria, por exemplo
  `"scylla_head"`. Use `e.parent = chefe` e `e.noScore = true` para partes do chefe.
- `sim:damageLighthouse(amount)`.
- `sim:fx(name, data)` e `sim:announce(text, args, color, big)`.
- `sim.beams`: tabela userId → feixe. `sim:beamSources()` lista os feixes
  ativos, incluindo lentes, faroletes e habilidades.
- `sim:petrify(seconds, turnFactor)`, `sim:ink(seconds, rangeFactor)`,
  `sim:sleep(seconds, power)`, `sim:charm(...)` e similares. Os efeitos sobre
  os feixes são aplicados a todos os jogadores. Quem precisar de um efeito
  novo o adiciona em Simulation com nome claro.
- `sim.embers`: lista de brasas (`x`, `y`, `pulled`, `life`), que pode ser
  empurrada.
- `sim.rng`, `sim.t`, `sim.difficulty` e `sim.mapId`.
- `e.rate()`: 1, ou `BossData.ENRAGE_SPEED` com o chefe enfurecido.
- `e.litFactor()`: o quanto a luz freia o chefe.

**Para o desenho:**
- `e.visual` (0–255): fase, por exemplo olho aberto, olhar ou mergulho.
- `e.aux` (0–255): dado extra, por exemplo número de cabeças.
- `e.hidden = true`: invulnerável e não desenhado, como no mergulho.
- `e.facing`: ângulo para onde o modelo olha, opcional.

## Snapshot (`Net.encode` / `Net.decode`), congelado

O Snapshot vai em um `RemoteEvent` confiável, 12 vezes por segundo, como
buffer. Cada lista vem precedida da quantidade, em u16.

| Lista | Campos e tamanho |
|---|---|
| Criaturas (14 bytes cada) | `id` u16, `art` u8 (índice em `Maps.ARTS`), `x` i16, `y` i16, `hp` u8 (fração × 255), `flags` u8, `visual` u8, `aux` u8, `facing` u16 (ângulo × 10000 mod 2π), `scale` u8 (× 50) |
| Brasas (6 bytes cada) | `id` u16, `x` i16, `y` i16 |
| Mortes (5 bytes cada) | `x` i16, `y` i16, `big` u8 |

**Flags:** 1 iluminada, 2 atordoada, 4 escondida, 8 elite, 16 enfeitiçada
(Iara), 32 refletindo (espelho fechado).

## Estado replicado

**Atributos de `ReplicatedStorage.FogkeeperNet.State`:**
- `Phase`: `lobby`, `story`, `playing` ou `ended`.
- Configuração da partida: `Mode` (`normal`, `daily`, `boss_rush` ou
  `tutorial`), `Map`, `Keeper`, `Difficulty` e `Tide`.
- Relógio: `RunStart` (hora do servidor), `RunSeconds`, `StoryEnd` e `CycleSeconds` (segundos da noite atual para o relógio e o céu, já tratando o modo sem fim, o Modo Chefões e o tutorial).
- Situação: `Hp`, `MaxHp`, `Level`, `Xp`, `XpNeeded`, `Kills`, `Score`,
  `Endless`, `Night`, `Ink`, `Petrified`, `Asleep` e `Charmed`.
- Chefe e relíquias: `BossName`, `BossHp`, `NextBoss`, `NextBossAt` e
  `Relics` (ids separados por vírgula).
- Fim de partida: `Result`, `ResultJson` (pontuação, estatísticas, dano por
  fonte e brasas), `ReturnAt` e `EndlessVotes`.
- Pausa: `Paused` e `PausedBy` (nome de quem pausou). Qualquer faroleiro pausa e retoma; em grupo a pausa acaba sozinha em `Balance.PAUSE_MAX`.
- Reacender (Robux): `Reviving` (noite congelada esperando compra) e `ReviveUntil` (hora do servidor em que a janela fecha).
- Outros: `TopJson` e `TopKey` (chave do ranking exibido), `DailyJson` (regras do dia), `TutorialStep` e `TutorialJson`.

**Atributos de cada `Player`:**
- Escolhas: `Slot`, `Hero`, `Loadout` (3 ids) e `Ready`.
- Feixe: `AimAngle`, `BeamHalf`, `BeamRange`, `TurnSpeed` e `Overcharge`.
- `BeamsJson`: feixes extras desse jogador, como lista `[{a, h, r, k}]`, em
  que `k` é o tipo (`lens`, `sweeper`, `mirror`, `beacon`).
- Habilidades e cartas: `Cd1`, `Cd2`, `Cd3` (hora do servidor em que fica
  pronta), `Pending`, `Offer` (ids separados por vírgula), `Rerolls` e
  `Banishes`.
- Contas: `Best`, `Oil` e `ProgressJson` (meta, desbloqueios, conquistas,
  bestiário, estatísticas, configurações, histórico curto).
- Compras (server/Monetization): `Passes` (chaves dos Game Passes possuídos, separadas por vírgula), `Vip` (bool) e `BeamColor` (Color3 escolhida com o passe Arco-íris; sem ela, cor da vaga).

## Canais (`Net.event(nome)`)

**Do cliente para o servidor:**
- `Aim(angle)`: sem garantia de entrega.
- `Ability(i)`, com i de 1 a 3.
- `Pick(id)`, `Reroll()` e `Banish(id)`.
- `Lobby(action, value, extra)`. As ações são `map`, `keeper`, `difficulty`,
  `tide`, `mode`, `hero`, `loadout` (value = vaga 1..3, extra = id), `start`,
  `skip_story`, `pause` (true pausa, false retoma), `endless` (voto para continuar), `buy` (id de desbloqueio),
  `meta` (id da oficina), `settings` (json), `tutorial`, `ready` e `cosmetic` (value = "beam", extra = chave da cor em `Monetization.BEAM_COLORS`; exige o passe).

**Do servidor para os clientes:**
- `Snapshot(buffer)`.
- `Fx(name, data)`. Os nomes são `flash`, `pulse`, `hit`, `splash`, `ink`,
  `boss_down`, `level`, `tide`, `beacon`, `relic`, `achievement`, `unlock`,
  `boss_warning` e `petrify`, além de efeitos próprios dos chefes.
  `purchase` vai só para o comprador (`{userId, key, oil}`) quando um pacote de óleo é entregue.
- `Announce(text, args, color, big)`.

## Regras do modo cooperativo

- **Níveis e cartas:**
  - Brasas, XP e nível são do time.
  - A cada nível, cada jogador ganha uma escolha. As cartas aparecem num canto
    da tela e a partida não pausa.
  - Melhorias com `scope = "own"` valem para o feixe de quem escolheu; as
    `shared` valem para o farol e para todos. As evoluções seguem o escopo das
    melhorias que exigem.
- **Habilidades e faroleiros:**
  - Cada jogador escolhe 3 habilidades liberadas (`Loadout`) e um faroleiro
    (`Hero`).
  - Os efeitos do faroleiro valem para o próprio feixe e para as próprias
    habilidades. Bônus de vida do farol somam a média.
- **Saguão:**
  - O primeiro da fila de vagas (`Slot` 1) escolhe mapa, farol, dificuldade,
    maré e modo.
  - Os outros escolhem só o próprio faroleiro e as habilidades.
  - Os mapas, faróis e marés que se pode escolher são os liberados pelo
    anfitrião.
- **Recompensas:** óleo, desbloqueios, conquistas e bestiário são de cada
  jogador. Todos que terminam a partida recebem.
- **Fim da partida:**
  - Modo sem fim: ao amanhecer, os jogadores votam por 15 s; se a maioria
    quiser, a noite continua.
  - Desafio diário: as regras do dia vêm de `Scores.dailyRules(data)`, com a
    mesma semente para o servidor inteiro. Tem ranking próprio.
- **Tutorial:** só com um jogador, no servidor dele. Os passos são os mesmos do
  Godot (`scripts/core/tutorial.gd`).
- **História do mapa:** aparece antes de cada partida (fase `story`). Qualquer
  jogador pode pular, ou ela termina sozinha.

## Formatos JSON (atributos)

- **`ProgressJson`** (do jogador):
  ```json
  {"oil": 0, "meta": {"granite": 2}, "unlocked": {"fjord": true}, "achievements": {"first_dawn": true},
   "seen": {"wraith": true}, "stats": {"runs": 0, "kills": 0, "bosses": 0, "dawns": 0, "tide_max": 0, "tutorial_done": false},
   "settings": {"locale": "", "colorblind": 0, "text_scale": 0, "reduce_flashes": false, "music": 80, "sfx": 100, "shake": true},
   "history": [{"date": "2026-11-04", "map": "bay", "mode": "normal", "difficulty": "normal", "tide": 0,
                "score": 0, "victory": false, "seconds": 0, "level": 1}]}
  ```
  O histórico guarda as 20 últimas partidas. `locale` vazio significa usar o
  idioma da conta.
- **`ResultJson`** (fim da partida):
  ```json
  {"victory": false, "map": "bay", "mode": "normal", "difficulty": "normal", "tide": 0, "seconds": 0,
   "nights": 0, "kills": 0, "level": 1, "bosses": 0, "relics": ["kraken"],
   "score": {"kills": 0, "survival": 0, "endless": 0, "bosses": 0, "victory": 0, "health": 0,
             "subtotal": 0, "multiplier": 1, "total": 0},
   "damage": [["beam", 0.7], ["pulse", 0.2]], "embers": [0, 0],
   "rewards": {"<userId>": {"oil": 0, "unlocks": ["texto"], "achievements": ["texto"]}}}
  ```
- **`DailyJson`**: `{"date": "2026-11-04", "seed": 123, "map": "japan", "hero": "monk", "tide": 2}`.
- **`TutorialJson`**: `{"title": "...", "body": "...", "progress": "2 / 3"}`.
  Os textos já vêm em português e o cliente traduz com `Text.t`. Argumentos,
  como as teclas, vêm em `args`.
- **`TopJson`**: `[{"name": "...", "score": 0}]`, para o ranking em
  `TopKey` (`"modo|mapa|dificuldade"`, ou `"daily|AAAA-MM-DD"`). Para trocar
  o ranking exibido, o cliente manda `Lobby("ranking", "modo|mapa|dificuldade")`.

## Para quem testa

O guia de uso está em `roblox/README.md`. Os erros aparecem em View > Output,
ou no F9 dentro do jogo.
