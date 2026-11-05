---
name: roblox-assets
description: "Assets da versão Roblox do Fogkeeper: sons e músicas (ids em client/Sounds.luau), imagens (ícone, miniaturas, imagens de passes, decals), malhas e modelos de terceiros, e a auditoria de segurança de qualquer coisa vinda do Creator Store/Toolbox antes de confiar nela. Explica como levar um asset para o código versionado (por id), já que o build.ps1 só monta scripts. Use ao escolher ou trocar sons, enviar imagens, inserir modelo ou malha, usar algo do Toolbox, ou suspeitar de script malicioso. EN triggers: Roblox assets, Creator Store, Toolbox, free model, is this asset safe, audit model, insert asset, sound ids, upload image, decal, mesh."
---

# Fogkeeper Roblox: assets

O visual do Fogkeeper é feito em código (peças do `client/ArtKit.luau`,
cenários em `server/Scenery/`), e o `roblox/build.ps1` só monta scripts. Por
isso, **todo asset entra no jogo por id dentro do código**, nunca como objeto
solto colocado no Studio (que se perde na próxima montagem).

## Ordem de escolha

1. Dá para fazer com peças e cores do ArtKit/Kit? Faça assim (zero risco, já
   versionado, combina com o resto).
2. Asset seu (enviado pela conta/grupo dono da experiência) por id:
   `Sound.SoundId`, `ImageLabel.Image`, `Decal.Texture`, `SpecialMesh.MeshId`.
3. Asset do Creator Store com licença para uso na experiência, por id, depois
   da auditoria abaixo se tiver qualquer script.
4. Com Studio MCP: buscar (`search_asset`) e gerar (`generate_mesh`,
   `generate_material`) são opções, mas o resultado precisa virar id usado no
   código. Peça consentimento antes de usar asset de outro dono.

Modelos prontos (`.rbxm`) não são suportados pelo `build.ps1` hoje. Se forem
mesmo necessários, combine com o usuário antes como versioná-los (o Rojo do
`default.project.json` aceita `.rbxm`; o `build.ps1` precisaria do mesmo).

## Sons (`client/Sounds.luau`)

- `Sounds.IDS` lista cada id de som (interface, partida, chefes); vazio = silêncio.
- Preencha com `rbxassetid://<número>`. Antes, confira que o áudio permite uso na
  sua experiência (o Roblox bloqueia áudio sem permissão e ele fica mudo).
- Mantenha a linguagem sonora coerente: sucesso, perigo, raridade e progresso
  sempre com o mesmo tipo de som. Sons frequentes (`hit`, `burn`) curtos e
  baixos. Som novo = id novo em `Sounds.IDS` e o evento que o toca.

## Imagens

- Base: `docs/store/` (capas, ícone da comunidade, `screenshots/`). Ícone e
  miniaturas da página: ver `roblox-release`.
- Imagens dos Game Passes (uma por passe, quadrada) e de produtos: envie pelo
  Creator Dashboard; o id do passe vai em `shared/Monetization.luau`.

## Auditoria de asset de terceiros (obrigatória se tiver script)

Trate todo modelo/pacote do Toolbox como suspeito.
1. Inserir num lugar isolado (pasta de quarentena), num arquivo de teste, não no
   `Fogkeeper.rbxlx` que vai ser publicado.
2. Não ligar HTTP, API Services nem nada que o asset "peça".
3. Listar todo `Script`, `LocalScript` e `ModuleScript` dentro dele, inclusive
   escondidos, desligados ou com nome enganoso.
4. Procurar: `require(` com número, `getfenv`, `setfenv`, `loadstring`,
   `HttpService`, `InsertService`, `GetObjects`, `MarketplaceService`,
   `DataStore`, `TeleportService`, `MessagingService`, criação de
   `RemoteEvent`, `string.char`, `string.reverse`, texto ofuscado, `while true`.
5. Sinais fortes: nomes como `AntiLag`, `Loader`, `MainModule`, `Handler`,
   `Fix`, `Free`, admin; código que se reparenta, se clona ou apaga coisas.
6. Ficar só com a parte visual (malhas, texturas, sons) e remover os scripts.

Veredito: **só visual** · **scripts revisados e necessários** · **quarentena**
(suspeito, não publicar) · **rejeitar**. Registre nome, id, criador, onde entrou
e o veredito na resposta ao usuário.

## Orçamento

- Criaturas comuns hoje têm cerca de 5 a 12 peças, e podem existir até
  `Balance.MAX_ENEMIES = 200` ao mesmo tempo. Peça a mais numa criatura comum
  pesa 200 vezes. Chefe pode ter mais.
- Peças decorativas: `Anchored`, `CanCollide/CanQuery/CanTouch = false`,
  `CastShadow = false` (exceto o que o ARCHITECTURE.md lista).
- Texturas pequenas, poucos materiais diferentes, sem transparência empilhada.
- Depois de uma leva de assets, rode a checagem de `roblox-performance`.

## Créditos

Asset de terceiros com licença que pede atribuição: entrada em
`THIRD_PARTY_NOTICES.md` e na tela de créditos (`client/Ui/CreditsScreen.luau`).
