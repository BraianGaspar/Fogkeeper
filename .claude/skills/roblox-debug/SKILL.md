---
name: roblox-debug
description: "Diagnóstico e correção de bugs da versão Roblox do Fogkeeper: montar uma forma repetível de reproduzir, hipóteses ranqueadas, instrumentação marcada, correção mínima em roblox/src e verificação, tanto com Studio MCP quanto pedindo Output e prints ao usuário. Use quando algo quebrar, der erro vermelho no Output, travar (infinite yield), não aparecer, dessincronizar entre jogadores, perder progresso ou piorar o desempenho na versão Roblox. EN triggers: Roblox bug, error in Output, not working in Studio, desync, regression, debug Luau."
---

# Fogkeeper Roblox: depuração

Objetivo: ir do sintoma à correção verificada sem chutar. Leia `roblox/ARCHITECTURE.md`
e siga o fluxo de `roblox-code` para editar e montar.

## 1. Um jeito repetível de reproduzir (o mais importante)

Gaste esforço aqui antes de mexer em qualquer coisa. Opções, da melhor para a pior:

1. **Passos exatos no Studio.** Modo (Play solo, ou Test > Clients and Servers
   com 2–4 jogadores), mapa, dificuldade, modo (normal, diário, Modo Chefões,
   tutorial) e o que fazer até o erro. Pedir ao usuário a linha exata do Output
   (com o caminho `ServerScriptService.Fogkeeper.X:linha`).
2. **Atalho para o estado.** Encurtar o caminho até o bug: por exemplo, um valor
   temporário em Balance (`RUN_DURATION` curto, chefe mais cedo) ou um comando
   de teste marcado (veja 4). Desfaça depois.
3. **Com MCP:** `execute_luau` para chamar a função suspeita com dados fixos e
   ler o resultado, `inspect_instance` para ver atributos de
   `ReplicatedStorage.FogkeeperNet.State` e do `Player`.
4. **Bug intermitente:** aumente a taxa (repita, mais criaturas, mais jogadores)
   até ficar reproduzível em boa parte das tentativas.

Sem forma de reproduzir, pare e diga o que tentou; peça ao usuário o Output
completo, prints ou um vídeo com o momento do erro. Não chute sem dados.

## 2. Hipóteses

Liste 3–5 causas possíveis, ranqueadas, cada uma falseável ("se for X, mudar Y
faz sumir"). Mostre ao usuário antes de testar: ele costuma saber o que mudou.

## 3. Instrumentar

- Uma sonda por hipótese, uma variável por vez.
- Todo `print`/`warn` temporário leva um prefixo único, ex. `[DEBUG-a4f2]`;
  no fim, `Grep "DEBUG-a4f2" roblox/src` deve voltar vazio.
- Desempenho: meça antes (F9 > Memory/Network/Scripts, MicroProfiler com
  Ctrl+F6, contagem de instâncias) em vez de espalhar prints.

## 4. Classes de bug comuns aqui

- **Infinite yield:** `WaitForChild` de nome que mudou, ou módulo que ainda não
  foi montado (rode `build.ps1` de novo; confira o nome do arquivo).
- **Cliente e servidor discordam:** atributo escrito com um nome e lido com
  outro; Snapshot com campo fora da ordem do ARCHITECTURE.md; arte com índice
  fora de `Maps.ARTS`.
- **Só quebra com 2+ jogadores:** estado por jogador guardado em variável global
  do Main; feixe/origem de outro jogador; vaga (`Slot`) que não libera ao sair.
- **Studio sem API Services:** DataStore indisponível, progresso só na memória
  (é esperado, `Progress.luau` avisa); rankings vazios.
- **Corrida no início:** personagem, interface e `ProgressJson` chegam em ordens
  diferentes; a tela lê atributo ainda `nil`.
- **Conexões duplicadas:** `Connect` a cada abertura de tela sem `Disconnect`,
  efeitos que dobram a cada partida.
- **Compras:** produto com `id = 0` aparece como "Indisponível" (correto);
  `ProcessReceipt` devolvendo `NotYetGranted` porque o progresso não carregou.
- **Texto sem tradução** aparece em português nos outros idiomas: rode
  `roblox/tools/i18n_check.ps1`.

## 5. Corrigir e travar

- A menor correção na causa raiz, nos arquivos de `roblox/src`; nada de
  esconder o erro com `pcall` mudo (se precisar de `pcall`, faça `warn` com contexto).
- Sem refatoração junto. Validação extra perto da fronteira de confiança.
- Rode a verificação de `roblox-code` (luau_blocks, i18n_check, build) e repita
  a reprodução. Sem novos erros no Output.
- Se der, transforme a reprodução num passo do roteiro de `roblox-playtest`.

## Relatório

Reprodução · causa raiz (qual hipótese se confirmou) · arquivos mudados ·
verificação feita (ou o que o usuário precisa testar) · riscos que sobram ·
o que teria evitado o bug (se for arquitetura, sugerir `roblox-code` depois).
