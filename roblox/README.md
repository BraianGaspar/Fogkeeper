# Fogkeeper no Roblox

Versão cooperativa do Fogkeeper para o Roblox, escrita do zero em Luau, com o
mesmo conteúdo do jogo em Godot. Até 4 faroleiros defendem o mesmo farol, cada
um com os próprios feixes. Brasas, níveis, vida do farol e pontuação são do
time.

**Conteúdo:**
- **Mapas (7):** Baía, Fiorde, Rio Encantado, Mar dos Yōkai, Alexandria, Mar
  Egeu e Costa Celta, cada um com história antes da partida, clima e avisos ao
  longo da noite.
- **Criaturas:** papéis comuns e especiais com a arte de cada mapa:
  - ladra de brasas;
  - espelho, que reflete o feixe principal;
  - mariposa, que cresce sob a luz;
  - névoa devoradora, que apaga brasas;
  - elites a partir do Médio.
- **Chefes:** 15, cada um com mecânica própria, fúria e relíquia.
- **Faroleiros e faróis:** 5 faroleiros com regras próprias e 4 faróis (só
  aparência).
- **Habilidades:** 6. Cada jogador leva 3.
- **Melhorias:** 12, mais 5 evoluções.
  - As de feixe valem para quem escolheu; as do farol valem para o time.
  - Cada jogador tem as próprias trocas e banimentos de cartas.
- **Dificuldades e modos:**
  - 5 dificuldades e 10 marés.
  - Modos: desafio diário (o mesmo para todos no dia), Modo Chefões (os 15 em
    sequência) e modo sem fim (o time vota para seguir noite adentro ao
    amanhecer).
  - Tutorial guiado, para um jogador.
- **Progressão de cada jogador:**
  - óleo, oficina, desbloqueios por óleo ou por meta;
  - 32 conquistas, bestiário com 76 fichas e histórico das 20 últimas partidas;
  - configurações salvas.
- **Rankings mundiais:** por modo, mapa e dificuldade, e um por dia no desafio
  diário.

Este código fica separado do jogo em Godot. O Godot ignora esta pasta por causa
do `.gdignore`.

## Como abrir no Roblox Studio

1. Instale o Roblox Studio (create.roblox.com) e entre com a sua conta.
2. Gere o arquivo do jogo. No PowerShell, na pasta do repositório, rode:
   ```
   powershell -ExecutionPolicy Bypass -File roblox/build.ps1
   ```
   O arquivo sai em `roblox/build/Fogkeeper.rbxlx`.
3. No Studio, abra o arquivo em **File > Open from File**.
4. Teste:
   - **Sozinho:** clique em **Play** (F5).
   - **Em grupo:** na aba **Test**, escolha **Clients and Servers** com 2 a 4
     jogadores e clique em **Start**.
5. Se algo der erro, abra **View > Output** e copie as linhas vermelhas.

Depois de mudar o código em `roblox/src`, rode o passo 2 de novo e reabra o
arquivo. O que você mudar direto no Studio não volta para os arquivos.

Para editar com sincronização ao vivo, instale o Rojo (rojo.space) e o plugin
dele no Studio, e rode `rojo serve roblox/default.project.json`.

## Controles

| Ação | Teclado e mouse | Controle | Celular |
|---|---|---|---|
| Andar e pular | WASD ou setas; Espaço | Analógico esquerdo; A | Polegar à esquerda; botão de pular |
| Apontar a lanterna | O feixe segue o cursor no mar | O feixe aponta para onde a câmera olha (analógico direito) | Toque ou arraste fora dos botões |
| Câmera | Botão direito e rodinha (padrão do Roblox) | Analógico direito | Arrastar na tela (o mesmo toque aponta a lanterna); pinça para o zoom |
| Habilidade 1 / 2 / 3 | Q / E / R ou F | LB / RB / Y | Botões das habilidades |
| Escolher carta | 1–4 ou clique | Direcional (← ↑ → ↓) | Toque na carta |
| Trocar cartas / Banir | T / B | X / View | Botões embaixo das cartas |
| Pausa e menu | Esc ou P | B / Menu | Botão II |

Cada faroleiro é o avatar do jogador, em terceira pessoa. O feixe sai da
lanterna na mão dele: andar pela ilha muda de onde a luz parte. Espaço, Shift
(trava do mouse) e o botão direito ficam com os controles do Roblox.

Nos menus, o controle navega pelos botões, A confirma e B volta. As dicas de
tecla trocam sozinhas para os botões do controle quando ele é usado.

## Telas

- **Saguão:** menu inicial com Jogar, Desafio diário, Modo Chefões, Oficina,
  Bestiário, Conquistas, Ranking, Histórico, Tutorial, Configurações e
  Créditos, mais o painel com os jogadores e a partida preparada.
- **Preparar a partida:**
  - O **anfitrião** (👑, a menor vaga) escolhe o mapa, o farol, a dificuldade e
    a maré, e começa a partida.
  - Os **outros** escolhem o próprio faroleiro e as habilidades, e marcam
    **Pronto**.
- **Durante a partida:**
  - O jogo não pausa, porque é cooperativo.
  - O menu (Esc ou ≡) só abre as Configurações e o Bestiário.
  - Para sair, use o menu do próprio Roblox; a noite continua para os outros.
- **Sons e música:** veja a seção [Sons](#sons). Até os ids serem
  preenchidos, o jogo fica em silêncio.

## Sons

A trilha e os efeitos são os mesmos do jogo em Godot, exportados para
`roblox/audio/*.ogg` (40 arquivos, com os mesmos nomes dos ids do `Sfx`). O
Roblox não sintetiza áudio: cada arquivo precisa ser enviado como asset, e o
número do asset vai em `src/shared/SoundIds.luau` (0 = ainda não enviado; o
som fica em silêncio, sem erro). Quem toca é `src/client/Sounds.luau` (canais,
grupos e trilha dinâmica). O jogador ajusta tudo em Configurações > Áudio.

**Regenerar os .ogg** (depois de mudar um som em `scripts/audio/sfx.gd`), na
raiz do repositório:
`GODOT=/caminho/do/godot FFMPEG=/caminho/do/ffmpeg tools/export_audio.sh`.
Som alterado = enviar de novo e trocar o id.

**Envio automático (Open Cloud):**

1. Em [create.roblox.com](https://create.roblox.com) > **Creator Dashboard >
   Open Cloud > API Keys**, crie uma chave com a API **Assets** (Read e Write)
   para o mesmo dono da experiência: a sua conta ou o grupo. Guarde a chave
   fora do Git.
2. No PowerShell, na raiz do repositório:
   ```powershell
   powershell -ExecutionPolicy Bypass -File roblox\tools\upload_audio.ps1 -ApiKey "SUA_CHAVE" -UserId 123456
   # ou, se a experiência é de um grupo:
   powershell -ExecutionPolicy Bypass -File roblox\tools\upload_audio.ps1 -ApiKey "SUA_CHAVE" -GroupId 7654321
   ```
   O script envia cada `.ogg` que ainda está com 0 em `SoundIds.luau`, espera
   o Roblox terminar o processamento e grava o id no arquivo. Pode rodar de
   novo: os que já têm id são pulados (útil se a cota do mês acabar no meio).
3. Remonte (`build.ps1`) e teste no Studio.

**Limites do Roblox:** enviar áudio é gratuito, mas há uma cota a cada 30 dias.
Pela regra mais recente que conhecemos, contas com **ID verificado** enviam até
**100 áudios por mês** e contas sem verificação bem menos (cerca de **10**);
cada arquivo pode ter até 7 minutos e cerca de 20 MB. Os 40 arquivos cabem na
cota de uma conta verificada. **Confira a regra atual** na documentação de
áudio em create.roblox.com antes de enviar, porque ela muda. Todo áudio passa
pela moderação; se um id ficar mudo, veja o status do asset.

**Envio manual (alternativa):** Creator Hub > **Development Items > Audio** >
Upload Asset (um por vez), ou no Studio, **View > Asset Manager > Bulk Import**
com vários `.ogg` de uma vez. Depois copie o número de cada asset
("Copy Asset ID") e cole na linha certa de `src/shared/SoundIds.luau` (por
exemplo `music_bay = 1234567890,`).

**Permissão e saída:** o áudio precisa pertencer ao mesmo dono da experiência
(conta ou grupo) ou ter permissão de uso nela; sem isso o Roblox bloqueia e o
som fica mudo. O dispositivo de saída (fone ou alto-falante) é escolhido pelo
jogador no menu do Roblox ou no Windows; o jogo não tem acesso a isso.

## Como publicar

1. Com o arquivo aberto no Studio, vá em **File > Publish to Roblox** e crie
   uma experiência nova.
2. Em **Home > Game Settings**:
   - **Places:** número máximo de jogadores = **4**.
   - **Security:** ligue **Enable Studio Access to API Services**. Sem isso, os
     recordes não funcionam nos testes do Studio.
   - **Basic Info:** gênero, ícone, imagens e descrição. As artes de
     `docs/store/` servem de base.
   - **Avatar:** o jogo usa o avatar de cada jogador (terceira pessoa). Deixe o tipo de avatar livre (R6 ou R15); a lanterna se ajusta aos dois.
3. Preencha o **questionário de maturidade** (Experience Questionnaire) no
   Creator Dashboard. Sem ele, a experiência não aparece para todos. Fantasia
   leve, sem sangue, deve ficar em "Mild" ou "Minimal".
4. Deixe a experiência **pública** quando terminar os testes.

## Estrutura

| Pasta | Vai para | O que tem |
|---|---|---|
| `src/shared` | ReplicatedStorage.Fogkeeper | `Balance` (todos os números), `Upgrades`, `Text` (traduções), `Net` (rede e formato dos envios) |
| `src/server` | ServerScriptService.Fogkeeper | `Main` (saguão, partida, recordes), `Simulation` (regras do jogo, sem peças), `World` (cenário 3D), `Scores` (DataStores) |
| `src/client` | StarterPlayerScripts.Fogkeeper | `Client` (câmera e ligação de tudo), `Input`, `Renderer` (criaturas, brasas, feixes), `Models`, `Ui` |

**Como as partes se comunicam:**
- **Servidor:** roda a partida num passo fixo de 30 vezes por segundo. É ele
  quem decide dano, vida e brasas, para ninguém trapacear.
- **Criaturas e brasas:** vão para os jogadores 12 vezes por segundo (10 com a tela cheia), num
  pacote compacto (`Net.encode`). O cliente suaviza o movimento entre um
  envio e outro.
- **Feixe:** cada jogador gira o próprio feixe na hora, sem esperar a rede. O
  servidor só aceita giros até a velocidade máxima do feixe.
- **Resto do estado:** vida, nível, relógio e chefe ficam em atributos da pasta
  `ReplicatedStorage.FogkeeperNet.State`.

## Gráficos

- **Luz:** `Lighting.Technology = Future`, gravada pelo `build.ps1` no XML
  (não dá para mudar por script). Céu com estrelas e lua do próprio Roblox,
  sombras ligadas e reflexos suaves (`server/World.luau`, `setupLighting`).
  Em aparelho fraco, o Roblox reduz luz e sombras sozinho.
- **Água:** o mar é água do Terrain, enchida pelo `World` depois da escala
  (uma camada de 4 studs, da altura -4 até 0). A peça "Sea" virou o fundo do
  mar. O `DayCycle` muda cor, ondas, transparência e reflexo por mapa e hora.
  O fiorde continua com o mar de gelo, sem água.
- **Sombras:** só a lâmpada do farol faz sombra, e só árvores, casas, pedras da
  ilha e avatares projetam sombra. O resto do cenário não projeta, por
  desempenho.
- **Lanterna:** cada avatar tem um SpotLight (`FkAimLight`, no
  `HumanoidRootPart`) que aponta para onde o feixe aponta. A cor, a abertura e
  o alcance acompanham o feixe.
- **Efeitos:** fagulhas e fumaça quando uma criatura morre ou queima,
  fagulhas quando uma brasa some e respingos quando uma criatura surge do mar.
  Há um limite de partículas por segundo, e no máximo 6 brasas têm luz. Nos
  níveis 1 a 3 da qualidade gráfica do Roblox, há menos partículas e nenhuma
  luz extra. A opção "reduzir efeitos piscantes" deixa o brilho do neon mais
  fraco e diminui as fagulhas.

## Monetização

O jogo é gratuito e rende Robux de quatro formas. Nada é prêmio aleatório,
os preços aparecem antes da compra e toda compra passa pela janela oficial do
Roblox. O catálogo fica em `src/shared/Monetization.luau`. Enquanto um ID
estiver em `0`, o item aparece como "Indisponível" e o jogo funciona normalmente.

**Game Passes** (compra única):

| Chave | Nome | O que faz |
|---|---|---|
| `vip` | VIP do Farol | Dobro de óleo em cada partida (`Balance.VIP_OIL`), selo [VIP] no saguão e acima do avatar |
| `rainbow` | Feixes Arco-íris | Escolha da cor do feixe na Loja (6 cores). Só visual |
| `golden_lantern` | Lanterna dourada | Brasas douradas em volta do avatar. Só visual |
| `legendary_lighthouses` | Faróis lendários | Libera o Farol de Ouro e o de Obsidiana para quando você for o anfitrião. Só visual |

**Developer Products** (compra repetível):

| Chave | Nome | O que faz |
|---|---|---|
| `oil_small`, `oil_medium`, `oil_large` | Barris de óleo | +150, +450 e +1.200 de óleo para a oficina |
| `revive` | Reacender o farol | Veja abaixo |

**Reacender o farol:**
- Vale só no modo Normal. Não vale no desafio diário nem no Modo Chefões, que
  têm ranking competitivo, nem no tutorial, onde o farol já volta sozinho.
- Quando a vida chega a 0, a noite congela por `Balance.REVIVE_WINDOW`
  segundos e todos veem um botão de compra. Se alguém comprar, o farol volta
  com metade da vida (`REVIVE_HP`) e as criaturas ficam atordoadas por 3 s.
- Vale uma vez por partida. A partida reacendida **não entra no ranking
  mundial**, para ninguém comprar posição.
- Se a compra chegar depois que a janela fechou, o comprador recebe
  `REVIVE_LATE_OIL` de óleo no lugar.
- A entrega é idempotente. Cada recibo fica salvo no progresso do jogador
  antes de o jogo confirmar a compra ao Roblox, então uma mesma compra nunca é
  entregue duas vezes.

**Como configurar:**
1. Publique o jogo (Arquivo → Publicar no Roblox).
2. No Creator Dashboard (create.roblox.com), abra a experiência e vá em
   **Monetização → Passes**. Crie os 4 passes, cada um com imagem, nome,
   descrição e preço, e coloque cada um **à venda**.
3. Em **Monetização → Produtos do desenvolvedor**, crie os 4 produtos com
   nome e preço.
4. Copie o número (ID) de cada um e cole no campo `id` da entrada
   correspondente em `src/shared/Monetization.luau`.
5. Gere o arquivo de novo (`build.ps1`), abra no Studio e publique.

As compras no Studio são de teste e não cobram Robux.

**Servidores privados:** não precisam de código. No Creator Dashboard, vá em
**Monetização → Servidores privados**, ligue e defina o preço mensal em Robux.

**Premium Payouts:** são automáticos. O Roblox paga pelo tempo que assinantes
Premium passam no jogo.

**Sacar dinheiro (DevEx):** é preciso ter 13 anos ou mais, conta verificada e
um mínimo de Robux ganhos. Confira as regras atuais em create.roblox.com.
