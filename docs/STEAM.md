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
- Conquistas sugeridas: primeira vitória, derrotar o Leviatã, vencer sem Paredes reforçadas, 5.000 criaturas queimadas no total.
- Steam Cloud para o save de meta-progressão (um arquivo em `user://`).

## Builds
- Exportar Windows e Linux (Linux ajuda no Steam Deck). Templates de exportação da mesma versão do editor (4.4.1).
- Enviar com SteamCMD + `app_build.vdf`; manter o script de build em `tools/` sem credenciais (credenciais ficam fora do repositório).
- Testar no Steam Deck: o renderer GL Compatibility e o suporte a controle já estão prontos; confira o tamanho dos textos em 1280x800.

## Gratuito ou pago
- Pago (US$ 2–5) combina com o escopo atual depois de som, mais inimigos e meta-progressão.
- Gratuito é bom para ganhar público e feedback; uma demo gratuita separada, lançada antes, junta wishlists para a versão paga (os festivais Steam Next Fest são feitos para isso).
