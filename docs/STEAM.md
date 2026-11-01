# Publicação na Steam

Confirme valores e regras no Steamworks antes de agir: estas notas refletem o conhecimento até meados de 2026.

## Nome
- Nome principal na loja: **Fogkeeper** (inglês alcança mais público). Use o nome localizado da Steam para mostrar **Farol** na loja em português.
- Antes de abrir a página: busque o nome na Steam e no Google, confira domínio e redes sociais, e consulte o INPI (e o USPTO, se for vender nos EUA).

## Conta e taxa
- Conta no Steamworks com dados fiscais e bancários.
- Taxa do Steam Direct: US$ 100 por jogo, recuperável após US$ 1.000 de receita bruta. Também vale para jogos gratuitos.
- A página da loja precisa ficar visível como "em breve" por um período antes do lançamento; abra a página cedo para acumular lista de desejos (wishlists), que é o principal motor de visibilidade no lançamento.

## Plano de lançamento
1. **Arte final da capa.** `docs/store/` tem uma versão gerada com a arte do jogo (`tools/store_art.gd`), boa para abrir a página. Antes do lançamento, vale contratar um artista para a capa e o logo: é o que mais muda a taxa de cliques.
2. **Página "em breve"** com capa, 5+ capturas, trailer e descrição. Abrir o quanto antes.
3. **Demo gratuita** (um mapa, Normal) no **Steam Next Fest** mais próximo.
4. **Steam Deck Verificado** (controle e texto legível em 1280x800 já existem).
5. **Criadores de conteúdo:** chaves para canais de survivors-like; no Brasil, o Rio Encantado é o gancho (folclore brasileiro).
6. **Lançamento** com 10–20% de desconto na primeira semana.

## Preço
- **US$ 4,99** com o conteúdo atual (5 mapas, 14 chefes, oficina, evoluções, modo sem fim). Abaixo de US$ 2,99 parece descartável; acima de US$ 6,99 compete diretamente com *Vampire Survivors* e *Brotato*.
- **Preços regionais:** use os recomendados pelo Steamworks (a ferramenta converte o preço base pelo poder de compra de cada região). Ordem de grandeza para US$ 4,99: € 4,99, £ 4,29, Brasil ~R$ 20–25. Argentina, Turquia e parte da América Latina e do Oriente Médio compram em dólar, numa faixa regional mais barata. No Brasil, ficar no recomendado ou um pouco abaixo ajuda as avaliações em português.
- **Países:** todos (padrão da Steam). Não há motivo para restringir.

## Idiomas
Português, inglês, espanhol, francês, alemão, russo, chinês simplificado, japonês e coreano (`scripts/core/i18n.gd` e `scripts/i18n/`). As traduções novas foram feitas por IA: antes do lançamento, peça revisão de um nativo pelo menos para chinês, japonês e coreano (os maiores públicos dessa lista). Marque na Steam só os idiomas revisados como "Interface e legendas".

Chinês, japonês e coreano usam as fontes do sistema (o Windows já tem). Para Linux/Steam Deck, embuta uma fonte com esses caracteres (ex.: Noto Sans CJK, licença OFL) como fallback em `UiTheme`.

## Arte da loja (`docs/store/`)
Gerada por `godot --path . --script tools/store_art.gd` (precisa de janela):

| Arquivo | Tamanho | Uso |
|---|---|---|
| header_capsule.png | 920×430 | Topo da página e listas |
| small_capsule.png | 462×174 | Buscas e listas pequenas |
| main_capsule.png | 1232×706 | Destaque da página inicial |
| vertical_capsule.png | 748×896 | Promoções sazonais |
| library_capsule.png | 600×900 | Biblioteca |
| library_hero.png | 3840×1240 | Fundo da biblioteca (sem texto) |
| library_logo.png | 1280×720 | Logo transparente sobre o hero |
| community_icon.png | 184×184 | Ícone da comunidade |

Capturas (1920×1080): `godot --path . --resolution 1920x1080 -- --ui=boss --map=japan --screenshot=7` (troque mapa e tela).

## Trailer
`Trailer` (scripts/core/trailer.gd) grava ~45 s com o bot jogando cada mapa, legendas e o logo final:

```bash
godot --path . --resolution 1920x1080 --fixed-fps 30 --write-movie build/trailer_en.avi -- --trailer=en
godot --path . --resolution 1920x1080 --fixed-fps 30 --write-movie build/trailer_pt.avi -- --trailer=pt
```

O Godot grava AVI (MJPEG + som). Converta para MP4 H.264 antes de enviar (HandBrake, ou `ffmpeg -i trailer_en.avi -c:v libx264 -crf 18 -c:a aac trailer_en.mp4`).

## Tamanho e requisitos
- **Tamanho:** o .exe tem ~98 MB, quase tudo do motor (não há arquivos de arte ou áudio). Na Steam, o download comprimido fica em torno de 30–40 MB. Dá para chegar perto de 20 MB compilando um template do Godot sem os módulos 3D e de física.
- **Requisitos mínimos (sugestão):** Windows 10 64-bit; processador dual-core de 2 GHz; 2 GB de RAM; placa de vídeo com OpenGL 3.3 (Intel HD 4000 ou melhor, ou qualquer GPU dedicada desde ~2012); 150 MB de espaço. Os sons são gerados ao abrir o jogo (alguns segundos de CPU).
- **Recomendado:** quad-core, 4 GB de RAM, qualquer GPU dedicada.

## Plataformas
- **Windows:** pronto (`tools/export.sh`).
- **Linux / Steam Deck:** o Godot exporta direto; falta baixar os templates de Linux e criar o preset. O renderer GL Compatibility já roda no Deck.
- **macOS:** exportável pelo Godot, mas assinar e notarizar exige um Mac e conta de desenvolvedor Apple (US$ 99/ano).
- **Navegador (itch.io, demo):** o Godot exporta para Web; boa vitrine gratuita.
- **Celular (Android/iOS):** o código já aceita toque (mirar arrastando o dedo, tocar nas habilidades, botão de pausa). Falta: preset Android (Android SDK + JDK + templates), testar o tamanho da interface em telas pequenas e ajustar o desempenho. iOS precisa de Mac e conta Apple. No celular o modelo costuma ser grátis com anúncios/compra única de US$ 2–3; dá para lançar depois da Steam.

## Integração técnica
- Use **GodotSteam** (addon GDExtension, ou a build pré-compilada do editor). Crie um autoload `SteamService` que inicializa a Steam e falha de forma silenciosa quando o jogo roda fora da Steam (dev, autoplay, CI). Nunca deixe o jogo depender da Steam para iniciar.
- Durante o desenvolvimento, use o app id de teste 480 (Spacewar); troque pelo seu app id antes de enviar builds.
- Conquistas: as 24 já existem localmente (`Achievements.LIST`). Cadastre os mesmos ids no Steamworks e chame `Steam.setAchievement(id)` + `storeStats()` dentro de `Achievements.unlock()`, o ponto único de desbloqueio.
- Steam Cloud para `user://settings.cfg`, `user://records.json` e `user://progress.json` (óleo, oficina, desbloqueios e conquistas).
- Leaderboards: uma por mapa e dificuldade (`fogkeeper_<mapa>_<dificuldade>`, ex. `fogkeeper_bay_hard`), enviando `score` ao fim de cada partida em `Main._end_run()`. A pontuação já é calculada só em `Balance.score_breakdown()`, então basta enviar o total; o ranking local continua para jogo offline.

## Exportar o .exe
O jogo é exportado para `build/windows/Fogkeeper.exe` (um arquivo só, com o .pck embutido; `/build/` está no `.gitignore`) pelo preset "Windows Desktop" de `export_presets.cfg`:

```bash
GODOT=/caminho/do/godot tools/export.sh
```

O script gera `icon.ico` a partir de `icon.svg` (`tools/make_icon.gd`) e exporta em modo release. Requer os templates 4.4.1 em `%APPDATA%/Godot/export_templates/4.4.1.stable/`. O atalho "Fogkeeper" da área de trabalho aponta para esse .exe; rode o script de novo depois de mudar o jogo.

Pendente: o ícone embutido no próprio .exe (precisa do `rcedit`, configurado em Editor → Configurações do Editor → Exportar → Windows, e de `application/modify_resources` ligado no preset).

## Builds
- Enviar com SteamCMD + `app_build.vdf`; manter o script de build em `tools/` sem credenciais (credenciais ficam fora do repositório).
- Testar no Steam Deck: confira o tamanho dos textos em 1280x800.
