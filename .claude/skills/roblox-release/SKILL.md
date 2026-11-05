---
name: roblox-release
description: "Publicação e lançamento da versão Roblox do Fogkeeper: portão antes de publicar (verificações, teste completo, políticas, ids de passes/produtos/sons), configurações da experiência (4 jogadores, API Services, questionário de maturidade), página (nome, ícone 512×512, miniaturas 16:9, descrição) a partir de docs/store mas com imagens da versão Roblox, notas de versão, como voltar atrás (histórico de versões do lugar) e o que vigiar depois. Use ao publicar, atualizar a experiência, preparar a página, escrever notas de versão ou lidar com problema logo após uma atualização. EN triggers: Roblox publish, release checklist, launch, update the experience, store page, icon, thumbnail, game description, release notes, rollback, hotfix."
---

# Fogkeeper Roblox: publicação e lançamento

Os passos de publicação do zero estão no `roblox/README.md` ("Como publicar" e
"Monetização"). Esta skill é o portão e o roteiro em volta deles.

## Portão (tudo precisa passar)

1. **Código:** `luau_blocks.pl`, `i18n_check.ps1` e `build.ps1` limpos (ver
   `roblox-code`). Árvore do Git limpa e o commit que vai ser publicado anotado.
2. **Teste:** roteiro completo de `roblox-playtest` (blocos 0–9), sem erro
   vermelho no Output, com celular e cooperativo.
3. **Salvamento e compras:** bloco 5 numa experiência publicada (privada) com
   API Services; recibo não duplica (`roblox-data-security`).
4. **Ids:** passes e produtos em `shared/Monetization.luau` (o que ficar `0`
   aparece "Indisponível", de propósito); sons em `client/Sounds.luau` (vazio =
   silêncio: decida se é aceitável); imagens dos passes enviadas.
5. **Políticas:** checklist de `roblox-policy` (questionário de maturidade
   preenchido, descrições de produtos fiéis, nada aleatório pago, só arte própria).
6. **Configurações da experiência:** máximo 4 jogadores; Enable Studio Access
   to API Services; gêneros; dispositivos (celular, tablet, PC, console se o
   controle passou no teste); servidores privados com preço, se desejado.

## Página da experiência

- **Nome:** "Fogkeeper" + algo buscável se o usuário quiser (ex. termo de
  gênero). Sem nome de outros jogos.
- **Ícone 512×512:** um assunto só (o farol com o feixe na névoa), alto
  contraste, legível pequeno, sem texto miúdo. `docs/store/` tem a identidade
  (cores, logotipo), mas nenhum arquivo ali é 512×512: faça um novo.
- **Miniaturas 1920×1080:** **capturas da versão Roblox** (avatares com
  lanterna, criaturas 3D, chefes, cooperativo). As de
  `docs/store/screenshots/` são da versão Godot (2D) e não representam este
  jogo; usá-las seria propaganda enganosa. Primeira miniatura = a promessa
  (feixe contra criaturas da névoa, com amigos).
- **Descrição:** as primeiras linhas dizem o que se faz e por que voltar
  ("Até 4 faroleiros giram a luz contra criaturas de 7 mitologias até o
  amanhecer"). Depois: mapas, chefes, modos, conquistas. Preço e efeito dos
  passes sem exagero. Traduções da descrição para os idiomas do jogo.
- A primeira noite precisa cumprir o que ícone e miniaturas prometem.

## Notas de versão

Curto, em linguagem de jogador: novidades · equilíbrio · correções · problemas
conhecidos (se houver) · prazo de evento, se houver. Em português e inglês no
mínimo. Guarde-as junto do commit publicado (mensagem ou tag).

## Atualizar uma experiência no ar

- Publicar troca o lugar; servidores antigos continuam com a versão anterior
  até reiniciar. Para forçar, use a migração para a versão nova (reinício
  suave) no Creator Dashboard, de preferência em horário de pouco movimento.
- Mudança de formato do progresso (`ProgressJson`, recibos) é a parte
  arriscada: precisa funcionar com dados antigos (`normalize`) e não pode
  depender de voltar atrás.
- Mudança grande de economia ou de compras: teste antes num lugar privado de
  teste, não direto no público.

## Voltar atrás

- Histórico de versões do lugar (Creator Dashboard ou Studio): restaure a última
  versão boa e publique; depois corrija no Git (o histórico do lugar não volta
  para `roblox/src`).
- Progresso de jogador afetado: gerenciador de Data Stores do Creator Dashboard,
  com registro do que foi mudado e por quê. Sem comandos de admin no jogo.

## Depois de publicar (primeiras 24–72 h)

Erros no Output dos servidores ao vivo (Creator Dashboard, erros), compras que
falham ou não entregam, relatos de progresso perdido, queda de jogadores no
primeiro minuto, reclamações de celular. Bug ao vivo → `roblox-debug`;
números e retenção → `roblox-liveops`.

## Relatório

Prontidão (pronto / bloqueado) · bloqueios · plano de teste · plano de volta ·
lista do que vigiar.
