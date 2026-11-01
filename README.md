# Fogkeeper

Um farol fixo numa ilha cercada de névoa. Gire o feixe, queime as criaturas e resista do crepúsculo até o amanhecer.

Survivors-like feito em **Godot 4.4** (GDScript). Visual, interface e sons são todos gerados por código; ainda não há arquivos de arte ou áudio.

![Fogkeeper](docs/screenshot.png)

## Como rodar
1. Instale o [Godot 4.4](https://godotengine.org/download) (versão padrão, não a .NET).
2. Abra o Godot, clique em **Importar** e selecione o `project.godot` desta pasta.
3. Aperte **F5**.

## Controles
| Ação | Teclado/mouse | Controle |
|---|---|---|
| Girar o feixe | Mouse, A/D, setas ou Q/E | Analógico direito (mira) ou esquerdo (gira) |
| Navegar nas cartas (melhoria, dificuldade) | A/D, ←/→ ou mouse | D-pad |
| Escolher | Enter, Espaço, 1-3 ou clique | A |
| Navegar nos menus | Setas, Tab ou mouse | D-pad + A |
| Pausar / voltar | Esc ou P | Start / B |

## O que tem no jogo
- Dificuldades Fácil, Normal e Difícil.
- Uma noite em 10 minutos: crepúsculo, lua, tempestade, madrugada e amanhecer.
- Configurações de idioma (português, inglês, espanhol), gráficos e volumes separados para música, efeitos e som de dano.
- Histórico de partidas com detalhes e ranking local com a regra de pontuação na própria tela.

Preferências e histórico ficam na pasta de dados do Godot (`%APPDATA%/Godot/app_userdata/Fogkeeper/` no Windows).

## Ferramentas
```bash
GODOT=/caminho/do/godot tools/check.sh        # carrega o projeto, acusa erros e textos sem tradução
GODOT=/caminho/do/godot tools/autoplay.sh 10  # 10 partidas com bot (Normal), mostra taxa de vitória
godot --path . -- --ui=levelup --screenshot=3 # abre uma tela e salva user://screenshot.png
```
O bot mira no inimigo mais próximo e escolhe melhorias ao acaso; serve como termômetro de balanceamento. Outras opções de linha de comando estão no topo de `scripts/core/main.gd`.

## Documentação
- `docs/GAME_DESIGN.md`: pilares, estado atual, pontuação e próximos passos.
- `docs/STEAM.md`: roteiro de publicação.
- `.claude/skills/fogkeeper-dev/`: skill com as orientações do projeto para o Claude (Claude Code carrega automaticamente).

## Licença
Defina uma licença antes de tornar o repositório público. Para um jogo comercial, o mais comum é manter o código fechado ("todos os direitos reservados").
