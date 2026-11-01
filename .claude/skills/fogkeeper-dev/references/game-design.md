# Fogkeeper — documento de design

## Pitch
Você é um farol numa ilha cercada de névoa. Não pode se mover: só gira o feixe. Criaturas mitológicas temem a luz, mas são muitas. Sobreviva da noite (18:00) até o amanhecer (06:00), que na partida são 10 minutos — e, se quiser, continue noite adentro no modo sem fim.

## Pilares
1. **Mirar é decidir.** O feixe queima e também recolhe brasas (XP). Nunca torne a coleta automática demais (o raio de atração deve continuar pequeno) para não matar essa escolha. O Sino da Névoa e a evolução Maré de Brasas são as exceções controladas.
2. **Imobilidade como identidade.** Nada de mover o farol. Mobilidade vem de luz: mais feixes, feixes automáticos, pulsos, habilidades.
3. **Legível no caos.** Criaturas escuras com contorno claro; tudo que é luz usa mistura aditiva e cores quentes; ataques fortes de chefes são telegrafados.
4. **Sessões curtas.** Uma noite dura no máximo 10 minutos.
5. **Cada mapa é um lugar.** Mapa tem história, clima, criaturas e chefes próprios, inspirados numa mitologia; a noite muda de cara ao longo da partida.
6. **Toda partida rende algo.** Mesmo a derrota dá óleo para a oficina; o progresso permanente é leve e nunca substitui a habilidade de mirar.

## Mapas
| Mapa | Mitologia | Criaturas (comum, rápida, robusta) | Chefes (5:00 / 9:00 / extra) | Clima |
|---|---|---|---|---|
| Baía da Névoa | Mar e lendas gregas/bíblicas | Espectro da névoa, Sereia, Caranguejo de Karkinos | Leviatã, Kraken | Tempestade com relâmpagos |
| Fiorde Congelado | Nórdica | Draugr, Lobo de gelo, Troll de gelo | Jötunn, Fenrir | Nevasca e aurora boreal |
| Rio Encantado | Folclore brasileiro | Corpo-seco, Curupira, Mapinguari | Iara, Boitatá, Cuca (extra no Impossível e no modo sem fim) | Temporal tropical e vaga-lumes |

Os papéis têm as mesmas estatísticas em todos os mapas; mudam aparência, nome, chefes e clima. A Baía é sempre liberada; o Fiorde libera ao sobreviver até a meia-noite (ou por 150 de óleo) e o Rio ao derrotar um chefe (ou por 300).

## Criaturas especiais
Aparecem com o passar da noite em todos os mapas e mexem na escolha entre queimar e recolher:
| Papel | Baía / Fiorde / Rio | Comportamento |
|---|---|---|
| Ladra (1:30) | Gaivota-fantasma / Corvo de Odin / Saci | Não ataca: rouba brasas soltas e foge. Queimada, devolve o roubo |
| Espelho (2:40) | Ostra abissal / Escudo de gelo / Jabuti encantado | Fechada, a luz não fere e 8% do feixe principal volta para o farol; abre a cada ~2,6 s. O Clarão a abre na hora |
| Mariposa (3:30) | Água-viva / Mariposa de geada / Mula sem cabeça | A luz a alimenta: cresce, acelera e bate mais forte, mas vale mais brasas |
| Névoa devoradora (2:30, a cada 70 s) | Névoa devoradora / de Niflheim / da Matinta | Nuvem que atravessa o mapa apagando as brasas por onde passa; a luz a dissipa |

## Chefes
- **Leviatã:** serpente segmentada que circula a ilha em espiral e mergulha (invulnerável). Só a cabeça recebe dano. Relíquia: +40 de vida máxima e cura total.
- **Kraken:** fica na borda, lança tentáculos e cospe tinta que encurta o feixe. Relíquia: +20% de alcance.
- **Jötunn:** arremessa pedras de gelo que precisam ser queimadas no ar; avança a cada arremesso. Relíquia: luz deixa criaturas ainda mais lentas.
- **Fenrir:** corre em círculos, foge da luz e investe depois de marcar uma linha vermelha. Relíquia: giro +30%, dano +15%.
- **Iara:** nada em volta da ilha; ao cantar, puxa o feixe na direção dela, fica protegida por uma bolha e manda botos por outros lados. Relíquia: brasas puxadas de 50% mais longe e regeneração.
- **Boitatá:** cobra de fogo imune à luz enquanto arde; de tempos em tempos a chama baixa e ela leva dano extra. O Clarão a apaga na hora. Cospe fogos-fátuos. Relíquia: +25% de dano.
- **Cuca:** conjura um feitiço de sono marcado por runas; dano suficiente durante a conjuração a interrompe, senão o feixe adormece (35% de força) por alguns segundos. Some e reaparece. Relíquia: habilidades recarregam 30% mais rápido.

Todo chefe: aviso 8 s antes, barra de vida, música de batalha, entrada com anel e tremor, pausa de impacto e anel de luz ao morrer, cura de 25 e bônus de pontos. No Difícil e no Impossível, enfurece com metade da vida.

## Melhorias e evoluções
Dez melhorias básicas mais duas liberadas na oficina (Combustão, Brasas vitais). Quando duas melhorias chegam ao máximo, a evolução aparece na próxima escolha, com carta roxa:
| Evolução | Requer | Efeito |
|---|---|---|
| Lente de Fresnel | Longo alcance + Chama intensa | Feixe principal em brasa branca, +30% de dano, +25% de alcance |
| Coroa de Luz | Lente extra + Farolete | Lentes extras com dano total, farolete com dois braços |
| Maré de Brasas | Pulso + Correntes quentes | Cada pulso puxa todas as brasas |
| Bastião | Paredes + Faroleiro dedicado | +50 de vida, cura total, regeneração dobrada |
| Leque de Luz | Lente ampla + Engrenagens | Feixe 50% mais largo e luz que desacelera mais |

Em cada escolha dá para **trocar** a mão (T; 1 por partida + oficina) e **banir** uma carta da partida (B; só com a oficina).

## Progressão (oficina)
Óleo = 0,5% da pontuação de cada partida (mínimo 5; tutorial dá 50 na primeira vez). Melhorias permanentes pequenas (vida, dano, giro, duração e atração das brasas, trocas, banimentos, quarta carta, melhoria inicial, mais óleo) e desbloqueios (mapas, faróis, cartas). O autoplay roda sem progressão: o balanceamento mede o jogo puro.

## Habilidades ativas
| Habilidade | Efeito | Recarga |
|---|---|---|
| Clarão | Fere e atordoa tudo num raio de 230 (abre espelhos, apaga o Boitatá) | 24 s |
| Sobrecarga | Feixe principal ×2,5 de dano, +30% de alcance, mais estreito, por 5 s | 20 s |
| Sino da Névoa | Puxa todas as brasas e cura 10 | 30 s |

## Dificuldades
| Modo | O que muda além dos números |
|---|---|
| Fácil | Farol +15% de vida, brasas duram 15 s |
| Normal | Referência |
| Médio | Elites (4%), brasas duram 11 s, XP por nível +8% |
| Difícil | Elites (8%), brasas duram 9 s, chefes enfurecem, XP +15% |
| Impossível | Elites (15%), brasas duram 6 s, chefes enfurecem, chefe extra às 7:00, farol −25%, névoa densa, XP +35% |

## Modo sem fim
Depois do amanhecer, "Continuar noite adentro": a névoa volta, a noite recomeça às 18:00, um chefe do mapa a cada 2:30 em rodízio (incluindo o extra) e as criaturas continuam ficando mais fortes. Cada segundo depois do amanhecer vale 10 pontos e cada noite extra completa, 4.000. A partida do amanhecer é atualizada no histórico quando a luz se apaga (ou ao sair pelo menu).

## Pontuação
Criaturas queimadas (10 a 50 por criatura; elites valem 3×) + 5 por segundo até o amanhecer + modo sem fim + 1.500 por chefe + 5.000 pela vitória + até 2.000 pela vida restante, e o subtotal é multiplicado pela dificuldade (×0,5 / ×1 / ×1,3 / ×1,7 / ×2,5). Empates: maior nível, depois quem fez primeiro.

## Conquistas
20 conquistas locais (primeira partida, tutorial, amanhecer em cada dificuldade alta, nos três mapas, sem paredes, intocado, noite sem fim, evolução, ladra, totais e uma por chefe). `Achievements.unlock()` é o ponto único para ligar às conquistas da Steam.

## Tutorial e dicas
O tutorial (menu principal, e oferecido na primeira vez que se clica em Jogar) ensina em 8 passos: girar, queimar, recolher, subir de nível (com as teclas da escolha), habilidades, ladra, espelho e um Leviatã enfraquecido. As dicas de teclas só aparecem no tutorial; as telas normais ficam limpas.

## Sensação dos golpes
Tremor de tela, pausa de impacto (hit-stop) em elites e chefes, anéis de luz em mortes grandes, entradas de chefe e subidas de nível, faíscas subindo de quem está queimando e bordas vermelhas quando o farol leva dano. Tremor e pausa de impacto podem ser desligados.

## Próximos passos sugeridos (ordem de valor)
1. **Playtest humano** de tudo que é novo: espelho, mariposa, ladra, névoa, os três chefes do Rio e o modo sem fim (o bot não reage a telegrafias).
2. **Arte de capa e página da Steam**, abrir a lista de desejos e preparar uma demo para o Next Fest.
3. **Ranking online e conquistas da Steam** via GodotSteam (`docs/STEAM.md`).
4. **Desafio diário** com semente compartilhada.
5. **Áudio e arte finais:** sons e músicas sintetizados são base; composição gravada melhora muito.
