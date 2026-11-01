# Farol

Um farol fixo numa ilha cercada de névoa. Gire o feixe, queime as criaturas e resista até o amanhecer.

Survivors-like feito em **Godot 4.4** (GDScript), com todo o visual gerado por código.

## Como rodar
1. Instale o [Godot 4.4](https://godotengine.org/download) (versão padrão, não a .NET).
2. Abra o Godot, clique em **Importar** e selecione o `project.godot` desta pasta.
3. Aperte **F5**.

## Controles
| Ação | Teclado/mouse | Controle |
|---|---|---|
| Girar o feixe | Mouse, A/D, setas ou Q/E | Analógico direito (mira) ou esquerdo (gira) |
| Escolher melhoria | 1, 2, 3 ou clique | D-pad + A |
| Pausar | Esc ou P | Start |

## Ferramentas
```bash
GODOT=/caminho/do/godot tools/check.sh        # carrega o projeto e acusa erros de script
GODOT=/caminho/do/godot tools/autoplay.sh 10  # 10 partidas com bot, mostra taxa de vitória
```
O bot mira no inimigo mais próximo e escolhe melhorias ao acaso; serve como termômetro de balanceamento.

## Documentação
- `docs/GAME_DESIGN.md`: pilares, estado atual e próximos passos.
- `docs/STEAM.md`: roteiro de publicação.
- `.claude/skills/farol-dev/`: skill com as orientações do projeto para o Claude (Claude Code carrega automaticamente).

## Licença
Defina uma licença antes de tornar o repositório público. Para um jogo comercial, o mais comum é manter o código fechado ("todos os direitos reservados").
