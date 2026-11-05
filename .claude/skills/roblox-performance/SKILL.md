---
name: roblox-performance
description: "Desempenho e cenário da versão Roblox do Fogkeeper em celular fraco: servidor (passo de 30 Hz, MAX_ENEMIES, MAX_EMBERS), rede (Snapshot a 12 Hz, atributos), cliente (peças por criatura, PivotTo por quadro, partículas, luzes, sombras, água do Terrain, iluminação Future) e legibilidade dos cenários (server/Scenery). Use quando houver travamento, queda de FPS, lag, uso de rede ou memória alto, ao adicionar criatura, chefe, efeito, cenário ou mais peças, ou ao revisar mudanças gráficas. EN triggers: Roblox performance, lag, frame rate, FPS, mobile optimization, memory leak, network bandwidth, instance count, particles, level design readability."
---

# Fogkeeper Roblox: desempenho e cenário

Celular fraco primeiro. Meça antes de mudar e compare depois. Contratos e
regras gráficas em `roblox/ARCHITECTURE.md` (seção Gráficos). Edite seguindo
`roblox-code`.

## Os números que mandam

| Onde | Valor | Arquivo |
|---|---|---|
| Passo da simulação | `Balance.TICK = 1/30` | `shared/Balance.luau` |
| Criaturas vivas | `Balance.MAX_ENEMIES = 200` | idem |
| Brasas | `Balance.MAX_EMBERS = 220` | idem |
| Snapshot | `Balance.SNAPSHOT_RATE = 12` por s; 14 B por criatura, 6 B por brasa, 5 B por morte | `shared/Net.luau` |
| Partículas | `PARTICLE_BUDGET = 500` por s | `client/Renderer.luau` |
| Luzes de brasa | `MAX_EMBER_LIGHTS = 6`; chefe ganha uma PointLight | idem |
| Qualidade baixa | `lowQuality()` (níveis 1–3 do Roblox): menos partículas, sem luz extra | idem |

**Rede no pior caso:** 200 × 14 + 220 × 6 ≈ 4,1 KB por Snapshot × 12 ≈ 50 KB/s
por jogador, só de Snapshot. Isso já encosta numa referência comum de limite
confortável por jogador. Antes de aumentar `MAX_ENEMIES`, `MAX_EMBERS`,
`SNAPSHOT_RATE` ou o tamanho de um registro, refaça a conta; prefira cortar
campos, mandar brasas paradas com menos frequência ou baixar a taxa.

## Como medir

- No jogo (Studio ou cliente): F9 (Developer Console: Memory, Network,
  Scripts, ServerStats), MicroProfiler (Ctrl+F6), contagem de instâncias.
- Cenário de estresse: Difícil/Impossível, maré alta, Modo Chefões, 4 jogadores
  (Test > Clients and Servers) e o emulador de dispositivo num celular comum.
- Sem MCP, peça ao usuário prints do F9 (aba Network e Memory) no pico da noite.
- Com MCP: `execute_luau` para contar instâncias em `workspace`, `screen_capture`
  antes/depois.

## Cliente

- Cada criatura é um Model com peças do ArtKit (comuns: cerca de 5–12 peças),
  criado ao surgir e destruído ao morrer; o Renderer faz `PivotTo` por quadro e
  `animate` depois. Peça a mais em criatura comum custa ×200. Se o MicroProfiler
  mostrar custo em criar/destruir, um pool por arte é o próximo passo.
- Peças: `Anchored`, sem colisão/consulta/toque, `CastShadow = false` (a não ser
  as exceções do ARCHITECTURE.md), poucos materiais, pouca transparência.
- Partículas sempre pelo `Renderer.emit` (respeita orçamento, qualidade e
  `reduce_flashes`). Nada de `ParticleEmitter` contínuo por criatura.
- Luz é cara: no máximo a do chefe, as 6 de brasa e a lanterna (`FkAimLight`)
  de cada avatar. Sombras só nas peças listadas.
- UI: nada de recriar a tela a cada quadro; atualize textos quando o atributo muda
  (`GetAttributeChangedSignal`), não em `RenderStepped`.
- Conexões: tudo que conecta ao abrir uma tela desconecta ao fechar.

## Servidor

- O passo (`Heartbeat` em Main → `sim:step`) deve ficar leve: nada de
  DataStore, JSON grande ou `Instance.new` dentro dele.
- Laços sobre criaturas × feixes são o custo principal; corte cedo por
  distância antes de testar ângulo.
- Atributos replicam a cada mudança: não escreva atributo por quadro se o valor
  não mudou (o `DayCycle` já faz assim com a água).

## Cenário (server/Scenery) e legibilidade

- Os 7 mapas vêm do Godot; a ilha tem cerca de 18 studs de raio e o mar é água
  do Terrain (o fiorde é gelo). Escala `Kit.S = 0.1` e `ScaleTo(WORLD_SCALE)`.
- O mar onde as criaturas surgem fica limpo: decoração não pode esconder
  criatura, brasa nem o feixe. Criatura e brasa devem ser mais "barulhentas"
  (cor, brilho) que o fundo em todas as horas do `DayCycle`.
- Marcos altos e com silhueta própria orientam o jogador na ilha; o avatar deve
  nascer olhando para o mar, com o farol à vista.
- Detalhe pesado longe da ilha não paga o custo: menos peças, sem sombra.
- Mudou cenário? Olhe ao entardecer, à meia-noite e ao amanhecer, com qualidade
  gráfica baixa e alta.

## Relatório

Maiores riscos · evidência (números do F9/MicroProfiler, contagens, prints) ·
correções ordenadas por impacto no jogador · como verificar · trocas feitas
(o que ficou mais feio ou mais simples).
