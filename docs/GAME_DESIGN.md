# Fogkeeper — documento de design

## Pitch
Você é um farol numa ilha cercada de névoa. Não pode se mover: só gira o feixe. Criaturas mitológicas temem a luz, mas são muitas. Sobreviva da noite (18:00) até o amanhecer (06:00), que na partida são 10 minutos.

## Pilares
1. **Mirar é decidir.** O feixe queima e também recolhe brasas (XP). Nunca torne a coleta automática demais (o raio de atração deve continuar pequeno) para não matar essa escolha. O Sino da Névoa é a exceção controlada: forte, mas com recarga longa.
2. **Imobilidade como identidade.** Nada de mover o farol. Mobilidade vem de luz: mais feixes, feixes automáticos, pulsos, habilidades.
3. **Legível no caos.** Criaturas escuras com contorno claro; tudo que é luz usa mistura aditiva e cores quentes; ataques fortes de chefes são telegrafados.
4. **Sessões curtas.** Uma partida dura no máximo 10 minutos.
5. **Cada mapa é um lugar.** Mapa tem história, clima, criaturas e chefes próprios, inspirados numa mitologia; a noite muda de cara ao longo da partida.

## Mapas
| Mapa | Mitologia | Criaturas | Chefes (5:00 / 9:00) | Clima |
|---|---|---|---|---|
| Baía da Névoa | Mar e lendas gregas/bíblicas | Espectro da névoa, Sereia, Caranguejo de Karkinos | Leviatã, Kraken | Tempestade com relâmpagos |
| Fiorde Congelado | Nórdica | Draugr, Lobo de gelo, Troll de gelo | Jötunn, Fenrir | Nevasca e aurora boreal |

Os papéis (comum, rápido, robusto) têm as mesmas estatísticas nos dois mapas; mudam aparência, nome, chefes e clima.

## Chefes
- **Leviatã:** serpente segmentada que circula a ilha em espiral e mergulha (invulnerável) para ressurgir adiante. Só a cabeça recebe dano. Relíquia: Escama do Leviatã (+40 de vida máxima e cura total).
- **Kraken:** fica na borda, lança tentáculos que rastejam até o farol e cospe tinta que encurta o feixe. Relíquia: Olho do Kraken (+20% de alcance).
- **Jötunn:** para a distância e arremessa pedras de gelo, que precisam ser queimadas no ar; avança a cada arremesso. Relíquia: Coração de Gelo (luz deixa criaturas ainda mais lentas).
- **Fenrir:** corre em círculos, foge da luz e investe depois de marcar uma linha vermelha até o farol. Relíquia: Presa de Fenrir (giro +30%, dano +15%).

Todo chefe: aviso 8 s antes (faixa vermelha, trompa, música de tensão), barra de vida própria, música de batalha, cura de 25 e bônus de pontos ao ser derrotado. No Difícil e no Impossível, enfurece com metade da vida.

## Habilidades ativas
| Habilidade | Efeito | Recarga |
|---|---|---|
| Clarão | Fere e atordoa tudo num raio de 230 | 24 s |
| Sobrecarga | Feixe principal ×2,5 de dano, +30% de alcance, mais estreito, por 5 s | 20 s |
| Sino da Névoa | Puxa todas as brasas e cura 10 | 30 s |

## Dificuldades
| Modo | O que muda além dos números |
|---|---|
| Fácil | Farol +20% de vida, brasas duram 16 s |
| Normal | Referência |
| Médio | Elites (4%), brasas duram 11 s, XP por nível +10% |
| Difícil | Elites (8%), brasas duram 9 s, chefes enfurecem, XP +20% |
| Impossível | Elites (15%), brasas duram 6 s, chefes enfurecem, chefe extra às 7:00, farol −25%, névoa densa, XP +35% |

O XP necessário por nível subiu em todos os modos na v0.3 (a progressão estava rápida demais).

## Pontuação
Criaturas queimadas (10 a 40 por criatura; elites valem 3×) + 5 por segundo vivo + 1.500 por chefe + 5.000 pela vitória + até 2.000 pela vida restante, e o subtotal é multiplicado pela dificuldade (×0,5 / ×1 / ×1,3 / ×1,7 / ×2,5). Empates: maior nível, depois quem fez primeiro.

## Estado atual (v0.3)
- Fluxo: título → mapa (com história) → farol (prévia) → dificuldade → partida.
- Configurações: idioma (PT/EN/ES); controles com troca de teclas, conflito resolvido por troca e "redefinir padrão"; gráficos (qualidade, modo de tela, resolução, VSync, tremor, partículas, clima, relâmpagos, névoa); áudio (volumes, dispositivo de saída, 9 grupos de som liga/desliga).
- Avisos em fila numa camada acima dos menus, registro de eventos no HUD e na pausa; a escolha de melhoria espera o aviso de chefe ser lido.
- Fim de partida com horário da derrota na história, quanto faltava, próximo marco, pontuação por critério e posição ("1º lugar").
- Histórico e ranking com mapa e farol; ranking filtrável por dificuldade e mapa.

## Próximos passos sugeridos (ordem de valor)
1. **Playtest humano** das cinco dificuldades e dos quatro chefes (o bot não reage a telegrafias).
2. **Mais um mapa** (ex.: deserto de sal / mitologia egípcia, ou pântano / folclore brasileiro com Boitatá e Mapinguari).
3. **Sinergias entre melhorias** (estilo "evolução").
4. **Meta-progressão leve:** pérolas para desbloquear faróis com habilidades iniciais diferentes (hoje eles são só visuais, de propósito).
5. **Ranking online** via leaderboards da Steam (`docs/STEAM.md`).
6. **Áudio e arte finais:** sons e músicas sintetizados são base; composição gravada melhora muito.
