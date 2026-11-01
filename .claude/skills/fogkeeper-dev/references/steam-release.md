# Publicação na Steam

Confirme valores e regras no Steamworks antes de agir: estas notas refletem o conhecimento até meados de 2026.

## Nome
- Nome principal na loja: **Fogkeeper** (inglês alcança mais público). Use o nome localizado da Steam para mostrar **Farol** na loja em português.
- Antes de abrir a página: busque o nome na Steam e no Google, confira domínio e redes sociais, e consulte o INPI (e o USPTO, se for vender nos EUA).

## Conta e taxa
- Conta no Steamworks com dados fiscais e bancários.
- Taxa do Steam Direct: US$ 100 por jogo, recuperável após US$ 1.000 de receita bruta. Também vale para jogos gratuitos.
- A página da loja precisa ficar visível como "em breve" por um período antes do lançamento; abra a página cedo para acumular lista de desejos (wishlists), que é o principal motor de visibilidade no lançamento.

## Integração técnica
- Use **GodotSteam** (addon GDExtension, ou a build pré-compilada do editor). Crie um autoload `SteamService` que inicializa a Steam e falha de forma silenciosa quando o jogo roda fora da Steam (dev, autoplay, CI). Nunca deixe o jogo depender da Steam para iniciar.
- Durante o desenvolvimento, use o app id de teste 480 (Spacewar); troque pelo seu app id antes de enviar builds.
- Conquistas: as 20 já existem localmente (`Achievements.LIST`). Cadastre os mesmos ids no Steamworks e chame `Steam.setAchievement(id)` + `storeStats()` dentro de `Achievements.unlock()`, o ponto único de desbloqueio.
- Steam Cloud para `user://settings.cfg`, `user://records.json` e `user://progress.json` (óleo, oficina, desbloqueios e conquistas).
- Leaderboards: uma por mapa e dificuldade (`fogkeeper_<mapa>_<dificuldade>`, ex. `fogkeeper_bay_hard`), enviando `score` ao fim de cada partida em `Main._end_run()`. A pontuação já é calculada só em `Balance.score_breakdown()`, então basta enviar o total; o ranking local continua para jogo offline.

## Exportar o .exe
O jogo é exportado para `build/windows/Fogkeeper.exe` (um arquivo só, com o .pck embutido; `/build/` está no `.gitignore`) pelo preset "Windows Desktop" de `export_presets.cfg`:

```bash
GODOT=/caminho/do/godot tools/export.sh
```

O script gera `icon.ico` a partir de `icon.svg` (`tools/make_icon.gd`) e exporta em modo release. Requer os templates 4.4.1 em `%APPDATA%/Godot/export_templates/4.4.1.stable/` (Editor → Gerenciar modelos de exportação). O atalho "Fogkeeper" da área de trabalho aponta para esse .exe; rode o script de novo depois de mudar o jogo.

Pendente: o ícone embutido no próprio .exe. O Godot 4.4 usa o `rcedit` para isso: baixe-o, configure em Editor → Configurações do Editor → Exportar → Windows → rcedit e ligue `application/modify_resources` no preset. Sem ele, o .exe mostra o ícone do Godot no Explorer, mas a janela e o atalho já usam o do farol. Antes de distribuir, teste numa máquina sem Godot instalado e repita para Linux.

## Builds
- Exportar Windows e Linux (Linux ajuda no Steam Deck). Templates de exportação da mesma versão do editor (4.4.1).
- Enviar com SteamCMD + `app_build.vdf`; manter o script de build em `tools/` sem credenciais (credenciais ficam fora do repositório).
- Testar no Steam Deck: o renderer GL Compatibility e o suporte a controle já estão prontos; confira o tamanho dos textos em 1280x800.

## Gratuito ou pago
- Pago (US$ 2–5) combina com o escopo atual depois de som, mais inimigos e meta-progressão.
- Gratuito é bom para ganhar público e feedback; uma demo gratuita separada, lançada antes, junta wishlists para a versão paga (os festivais Steam Next Fest são feitos para isso).
