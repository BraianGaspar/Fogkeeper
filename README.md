# Fogkeeper

Um farol fixo numa ilha cercada de névoa. Gire o feixe, queime as criaturas e resista do crepúsculo até o amanhecer.

Survivors-like feito em **Godot 4.4** (GDScript). Visual, interface e sons são todos gerados por código; ainda não há arquivos de arte ou áudio.

![Fogkeeper](docs/screenshot.png)

## Como rodar
1. Instale o [Godot 4.4](https://godotengine.org/download) (versão padrão, não a .NET).
2. Abra o Godot, clique em **Importar** e selecione o `project.godot` desta pasta.
3. Aperte **F5**.

## Controles
Teclas do teclado podem ser trocadas em **Configurações → Controles**.

| Ação | Teclado/mouse (padrão) | Controle |
|---|---|---|
| Girar o feixe | Mouse, A/D ou ←/→ | Analógico direito (mira) ou esquerdo (gira) |
| Clarão | Espaço ou Q | LB |
| Sobrecarga | Shift, E ou botão direito do mouse | RB |
| Sino da Névoa | R ou F | Y |
| Navegar nas cartas (mapa, farol, dificuldade, melhoria) | A/D, ←/→ ou mouse | D-pad |
| Escolher | Enter, Espaço, 1-5 ou clique | A |
| Pausar / voltar | Esc ou P | Start / B |

## O que tem no jogo
- Dois mapas com história própria: **Baía da Névoa** (Leviatã e Kraken) e **Fiorde Congelado** (Jötunn e Fenrir), cada um com criaturas, clima e trilha diferentes.
- Quatro faróis para escolher (só aparência).
- Cinco dificuldades: Fácil, Normal, Médio, Difícil e Impossível, com regras próprias (elites, fúria dos chefes, chefe extra).
- Habilidades ativas com recarga, chefes com mecânicas e relíquias, música que muda antes e durante as lutas.
- Uma noite em 10 minutos, das 18:00 às 06:00, com tempestade ou nevasca no meio.
- Configurações de idioma (PT/EN/ES), controles, gráficos e áudio (inclusive dispositivo de saída e sons individuais).
- Histórico de partidas e ranking local com posição ("1º lugar") e a regra de pontuação na tela.

Preferências e histórico ficam na pasta de dados do Godot (`%APPDATA%/Godot/app_userdata/Fogkeeper/` no Windows).

## Ferramentas
```bash
GODOT=/caminho/do/godot tools/check.sh        # carrega o projeto, acusa erros e textos sem tradução
GODOT=/caminho/do/godot tools/autoplay.sh 10 --difficulty=hard --map=fjord  # partidas com bot
godot --path . -- --ui=levelup --screenshot=3 # abre uma tela e salva user://screenshot.png
```
O bot mira no inimigo mais próximo e escolhe melhorias ao acaso; serve como termômetro de balanceamento. Outras opções de linha de comando estão no topo de `scripts/core/main.gd`.

## Documentação
- `docs/GAME_DESIGN.md`: pilares, estado atual, pontuação e próximos passos.
- `docs/STEAM.md`: roteiro de publicação.
- `.claude/skills/fogkeeper-dev/`: skill com as orientações do projeto para o Claude (Claude Code carrega automaticamente).

## Licença
Defina uma licença antes de tornar o repositório público. Para um jogo comercial, o mais comum é manter o código fechado ("todos os direitos reservados").
