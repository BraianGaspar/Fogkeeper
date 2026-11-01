# Direitos, licenças e conformidade

Este guia lista o que o Fogkeeper precisa cumprir para ser publicado sem infringir direitos de terceiros nem regras das lojas. **Não é aconselhamento jurídico:** para o registro de marca e o contrato de venda, vale uma consulta com um advogado de propriedade intelectual.

## 1. Direitos do jogo (seus)
- `LICENSE`: todos os direitos reservados ao autor. O repositório deve continuar privado.
- **Marca "Fogkeeper":** antes de abrir a página da Steam, pesquise o nome no INPI (Brasil), no USPTO (EUA) e no EUIPO (Europa), na Steam, na Google Play e no Google. Se estiver livre, registre no INPI na classe 9 (software de jogo) e, se possível, na 41 (entretenimento).
- **Conteúdo gerado com IA:** código, desenhos procedurais, sons sintetizados, textos e traduções foram feitos com ajuda de IA (Claude). Isso tem duas consequências:
  - **Steam:** o formulário de conteúdo do Steamworks exige declarar conteúdo gerado por IA. Declare "conteúdo pré-gerado por IA" e descreva que o código, a arte procedural, o áudio sintetizado e as traduções foram criados com assistência de IA e revisados pelo desenvolvedor. Isso não impede a venda; omitir é que viola as regras.
  - **Direito autoral:** em vários países (como nos EUA), material puramente gerado por IA tem proteção autoral limitada. A seleção, organização, revisão e direção criativa feitas por você continuam sendo suas. Guarde o histórico do repositório como prova de autoria.

## 2. Conteúdo de terceiros (já em ordem)
| Item | Situação |
|---|---|
| Motor Godot (MIT) | Créditos e licença completa no jogo (Configurações → Geral → Créditos e licenças) e em `THIRD_PARTY_NOTICES.md`. A licença MIT exige que esse aviso acompanhe o jogo, e ele acompanha. |
| Fonte Cinzel (SIL OFL 1.1) | Incluída em `assets/fonts/` com o `OFL.txt`. A OFL permite uso comercial e embutir a fonte no jogo; só proíbe vender a fonte sozinha. |
| Fontes do sistema (reserva para chinês, japonês, coreano e cirílico) | Não são copiadas para o jogo, só lidas do sistema do jogador. Para Linux e Steam Deck, use Noto Sans CJK (OFL) se for embutir. |
| Arte, sons e músicas | Todos feitos em código dentro do projeto; nenhum arquivo de terceiros. |
| Imagens da loja | Desenhadas com a arte do jogo e a fonte Cinzel (OFL): livres de direitos de terceiros. |

## 3. Mitologia e folclore
- Leviatã, Kraken, Jötunn, Fenrir, Iara, Boitatá, Cuca, Saci, Curupira, Mapinguari, os yōkai e os deuses egípcios são **domínio público**: mitos e lendas não têm dono.
- **Cuidado com versões modernas:** representações específicas criadas por obras protegidas têm dono. A Cuca de jacaré **com cabelo amarelo** é o visual da série de TV do *Sítio do Picapau Amarelo*; por isso o jogo usa cabelo grisalho, da lenda popular. Evite também referências diretas a outros produtos, como nomes, visuais ou bordões de séries, filmes, animes e jogos.
- **Respeito cultural:** o folclore brasileiro tem raízes indígenas e afro-brasileiras, e os deuses egípcios e nórdicos são de religiões antigas. O jogo trata todos como lendas, sem zombaria nem estereótipos. Mantenha assim, e considere uma frase na página da loja: "inspirado em mitos e lendas de cinco culturas".

## 4. Regras da Steam
- **Formulário de conteúdo:** violência de fantasia contra criaturas, sem sangue, sem conteúdo sexual, sem apostas, sem compras dentro do jogo e sem conteúdo gerado por usuários. Cabe na categoria "Fantasy Violence" sem nenhum aviso de conteúdo adulto.
- **Declaração de IA:** ver item 1.
- **Página da loja:** só imagens e vídeo do próprio jogo; nada de logotipos de outras marcas nem frases como "melhor que Vampire Survivors".
- **Idiomas:** marque como suportados só os idiomas revisados (ver `docs/STEAM.md`).
- **Fotossensibilidade:** o jogo tem relâmpagos e clarões. Já existe a opção "Reduzir efeitos piscantes" em Gráficos. Coloque na descrição da loja: "Contém luzes piscantes; dá para reduzi-las nas configurações."

## 5. Regras da Google Play
- **Política de privacidade:** obrigatória mesmo sem coletar dados. Use `docs/PRIVACY.md`, publicada num link público (página do GitHub Pages, site ou Google Sites). Antes, preencha o e-mail de contato.
- **Formulário "Segurança dos dados":** responda que nenhum dado é coletado nem compartilhado.
- **Classificação indicativa (IARC):** questionário dentro do Play Console. Respostas: violência de fantasia leve, sem sangue, sem interação entre usuários, sem compras. O resultado esperado é "Livre" ou "10 anos", conforme o país.
- **Público-alvo:** marque 13 anos ou mais para não cair nas regras de apps para crianças ("Família"), que são bem mais rígidas.
- **Permissões:** o app não pede nenhuma.

## 6. Classificação indicativa no Brasil
Na Steam vale a autoclassificação do formulário. Para a Google Play, o IARC já gera a classificação brasileira (ClassInd). A expectativa é "Livre" ou "10 anos" (violência fantasiosa).

## 7. Segurança do jogo
- O jogo não usa internet, não executa código baixado e só lê e grava os próprios arquivos (`settings.cfg`, `records.json`, `progress.json`).
- Arquivos corrompidos ou editados à mão não travam o jogo: são validados ao carregar e, se inválidos, o jogo recomeça do zero com um aviso no log.
- O ranking local pode ser editado por quem mexer nos arquivos. Isso só afeta o próprio jogador; o ranking online da Steam é que vale para todos.
- Builds para a loja: exportar sempre em modo release (`tools/export.sh`) e nunca colocar senhas ou chaves no repositório. A chave de release do Android deve ficar fora do projeto, com cópia de segurança: sem ela não dá para atualizar o app.

## Checklist antes de publicar
- [ ] Pesquisar e registrar a marca "Fogkeeper"
- [ ] Preencher o e-mail em `docs/PRIVACY.md` e publicá-la num link
- [ ] Declarar o uso de IA no Steamworks
- [ ] Revisar as traduções com falantes nativos
- [ ] Aviso de luzes piscantes na descrição da loja
- [ ] Criar a chave de release do Android e guardar a cópia de segurança
