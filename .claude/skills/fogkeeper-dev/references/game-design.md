# Fogkeeper — documento de design

## Pitch
Você é um farol numa ilha cercada de névoa. Não pode se mover: só gira o feixe. As criaturas temem a luz, mas são muitas. Sobreviva 10 minutos até o amanhecer.

## Pilares
1. **Mirar é decidir.** O feixe queima e também recolhe brasas (XP). Nunca torne a coleta automática demais (o raio de atração deve continuar pequeno) para não matar essa escolha.
2. **Imobilidade como identidade.** Nada de mover o farol. Mobilidade vem de luz: mais feixes, feixes automáticos, pulsos.
3. **Legível no caos.** Inimigos escuros com contorno claro; tudo que é luz usa mistura aditiva e cores quentes; o jogador deve entender a tela em meio a centenas de inimigos.
4. **Sessões curtas.** Uma partida dura no máximo 10 minutos.

## Estado atual (v0.1)
- Feixe principal controlado por mouse, teclado ou controle, com velocidade de giro limitada.
- Inimigos: Névoa (básico), Corredor (rápido, a partir de 0:45), Colosso (resistente, a partir de 2:00), Leviatã (chefe aos 5:00 e 9:00).
- Inimigos iluminados ficam mais lentos.
- 10 melhorias + "Óleo fresco" quando tudo estiver no máximo.
- Brasas somem após 14 s se não forem recolhidas.

## Próximos passos sugeridos (ordem de valor)
1. **Feedback e "juice":** som (ambiente de mar, chiado de queima, sino de nível), partículas de brasa, tremor ao matar chefes. É o que mais aumenta a sensação de qualidade por hora de trabalho.
2. **Variedade de inimigos com mecânica:** um que se esconde da luz (recua e volta), um que se divide, um que apaga o feixe temporariamente ao morrer.
3. **Sinergias entre melhorias** (estilo "evolução"): ex. Lente extra no máximo + Pulso → feixes disparam pulsos nas pontas.
4. **Meta-progressão leve** entre partidas: moeda (pérolas) para desbloquear faroleiros com habilidades iniciais diferentes. Salvar com `ConfigFile` em `user://`.
5. **Modo infinito** depois do amanhecer, para placar.
6. **Arte final:** manter o estilo vetorial atual é uma opção legítima e barata; se trocar, preservar a leitura (contorno claro nos inimigos, luz aditiva).
