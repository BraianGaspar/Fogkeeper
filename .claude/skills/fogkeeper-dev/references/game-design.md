# Fogkeeper — documento de design

## Pitch
Você é um farol numa ilha cercada de névoa. Não pode se mover: só gira o feixe. As criaturas temem a luz, mas são muitas. Sobreviva 10 minutos até o amanhecer.

## Pilares
1. **Mirar é decidir.** O feixe queima e também recolhe brasas (XP). Nunca torne a coleta automática demais (o raio de atração deve continuar pequeno) para não matar essa escolha.
2. **Imobilidade como identidade.** Nada de mover o farol. Mobilidade vem de luz: mais feixes, feixes automáticos, pulsos.
3. **Legível no caos.** Inimigos escuros com contorno claro; tudo que é luz usa mistura aditiva e cores quentes; o jogador deve entender a tela em meio a centenas de inimigos.
4. **Sessões curtas.** Uma partida dura no máximo 10 minutos.
5. **A noite conta uma história.** A partida vai do crepúsculo ao amanhecer; o cenário muda junto e o relógio do topo mostra quanto falta.

## Estado atual (v0.2)
- Feixe principal controlado por mouse, teclado ou controle, com velocidade de giro limitada.
- Inimigos: Névoa (básico), Corredor (rápido, a partir de 0:45), Colosso (resistente, a partir de 2:00), Leviatã (chefe aos 5:00 e 9:00, com aviso e trompa).
- Inimigos iluminados ficam mais lentos. Brasas somem após 14 s se não forem recolhidas.
- 10 melhorias + "Óleo fresco" quando tudo estiver no máximo. Escolha em cartas com ícone, níveis e navegação por mouse, A/D, setas, 1-3, Enter ou controle.
- Dificuldades Fácil, Normal e Difícil (multiplicadores em `Balance.DIFFICULTIES`; Normal é a referência).
- Ciclo da noite: crepúsculo → noite de lua → tempestade (≈4:30–6:30, chuva e relâmpagos; o primeiro Leviatã chega no meio dela) → madrugada → amanhecer; na vitória o sol nasce e as criaturas se desfazem.
- Cenário: ilha com casa do faroleiro, cais e barco, rochedos com espuma, naufrágio, boias piscando, reflexos da lua, gaivotas.
- Áudio sintetizado em código: trilha ambiente, mar, queima, brasas, dano, pulso, chefe, trovão, menus.
- Menus: título, dificuldade, configurações (idioma PT/EN/ES, qualidade, tela cheia, VSync, tremor, volumes geral/música/efeitos/dano), pausa, fim de partida.
- Histórico de partidas com detalhes e ranking local com pontuação explicada.

## Pontuação
Criaturas queimadas (10 Névoa, 12 Corredor, 40 Colosso, 750 Leviatã) + 5 por segundo vivo + 5.000 pela vitória + até 2.000 pela vida restante ao amanhecer, tudo multiplicado pela dificuldade (×0,5 / ×1 / ×1,6). Empates: maior nível, depois quem fez primeiro.

## Próximos passos sugeridos (ordem de valor)
1. **Playtest humano das dificuldades** e ajuste fino de Fácil/Difícil (o bot só mede o Normal).
2. **Variedade de inimigos com mecânica:** um que se esconde da luz (recua e volta), um que se divide, um que apaga o feixe temporariamente ao morrer.
3. **Sinergias entre melhorias** (estilo "evolução"): ex. Lente extra no máximo + Pulso → feixes disparam pulsos nas pontas.
4. **Meta-progressão leve** entre partidas: moeda (pérolas) para desbloquear faroleiros com habilidades iniciais diferentes. Salvar com `ConfigFile` em `user://`.
5. **Ranking online** via leaderboards da Steam (ver `docs/STEAM.md`), mantendo o local para jogo offline.
6. **Modo infinito** depois do amanhecer, para placar.
7. **Áudio e arte finais:** os sons sintetizados servem de base; trocar por gravações/composição melhora muito. Manter o estilo vetorial é uma opção legítima.
