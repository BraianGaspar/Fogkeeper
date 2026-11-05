---
name: roblox-policy
description: "Revisão de políticas e riscos de plataforma da versão Roblox do Fogkeeper: Padrões da Comunidade, questionário de maturidade, regras de monetização (Game Passes, Developer Products, reviver pago, itens aleatórios pagos), propriedade intelectual (mitologia, Cuca grisalha, áudio licenciado), privacidade, textos de jogadores, links externos e anúncios. Use antes de publicar, ao criar produto/passe/oferta, ao adicionar áudio, modelo, texto digitado por jogador, link ou propaganda, ou quando perguntarem se algo é permitido no Roblox. EN triggers: Roblox policy, compliance, is this allowed, maturity questionnaire, age rating, paid random items, IP, privacy, text filtering, ads rules."
---

# Fogkeeper Roblox: políticas e conformidade

As regras do Roblox mudam. Para conselho final, confira as fontes oficiais
atuais (create.roblox.com/docs e en.help.roblox.com: Community Standards, Terms
of Use, regras de monetização e de anúncios, questionário de maturidade). Se não
der para consultar agora, diga que é uma revisão de risco, não final. Não é
aconselhamento jurídico; `docs/LEGAL.md` tem o lado de direitos do projeto.

## Checklist do Fogkeeper

**Maturidade.** Preencher o questionário no Creator Dashboard (sem ele a
experiência não aparece para todos). O jogo: violência de fantasia contra
criaturas, sem sangue, sem linguagem forte, clima de noite e névoa (algum
susto leve, chefes grandes). Responda com honestidade; o README sugere
"Minimal" ou "Mild". Mudou o tom (chefe assustador, efeito de sangue)? Revise.

**Monetização.**
- Nenhum item aleatório pago (sem obrigação de mostrar chances). Se um dia
  houver, chances visíveis antes da compra e checagem com `PolicyService`
  (`ArePaidRandomItemsRestricted`) para quem não pode comprar.
- Cada passe/produto entrega exatamente o que a descrição diz. O reviver
  explica as limitações (uma vez, só Normal, sai do ranking) e, se chegar tarde,
  dá óleo (`REVIVE_LATE_OIL`): mantenha esse texto em sincronia com o código.
- Nada de prometer Robux, itens do catálogo do Roblox ou recompensa fora do jogo.
- Sem pressão enganosa (escassez falsa, cronômetro falso). Ver `roblox-economy`.

**Propriedade intelectual.**
- Mitos e lendas são domínio público; versões modernas protegidas não (a Cuca
  é grisalha, não a do Sítio). Nada que imite filme, série, anime ou jogo.
- Áudio: só do Creator Store com permissão para a experiência, ou enviado pelo
  dono da conta. Música famosa "remixada" não.
- Modelos/imagens de terceiros: ver `roblox-assets` (licença e auditoria).
- Ícone, miniaturas e trailer: só imagem do próprio jogo, sem logo de outra marca.

**Privacidade e textos.**
- O jogo mostra só `DisplayName` (saguão, pausa, ranking) e não guarda dado
  pessoal além do progresso por `UserId`. Mantenha assim.
- Hoje não há texto digitado por jogador visível a outros. Se surgir (nome de
  time, mensagem), passa por `TextService:FilterStringAsync` no servidor antes
  de aparecer para qualquer pessoa.
- `docs/PRIVACY.md` descreve a versão Steam (dados só no dispositivo). Se a
  política for citada para o Roblox, ela precisa de uma seção própria
  (progresso em DataStore do Roblox, rankings com nome de exibição).

**Links e anúncios.**
- Nenhum link externo dentro do jogo. Redes sociais, só pelos campos oficiais da
  página da experiência (e `PolicyService` decide quem pode ver referências).
- Anúncios patrocinados e criadores de conteúdo: seguir as regras de anúncios
  do Roblox; vídeo e imagem mostram jogo real; parceria paga é declarada.

## Como revisar uma mudança

1. Descreva a mudança: o que o jogador vê, paga, digita ou recebe.
2. Para cada área acima que ela toca, cite a regra oficial atual (com link).
3. Liste riscos com nível (baixo/médio/alto) e a mudança de texto ou design
   que resolve.
4. Se o risco pode voltar, adicione um item ao portão de `roblox-release`.

## Relatório

Áreas checadas · nível de risco · mudanças obrigatórias e recomendadas ·
dúvidas em aberto · fontes oficiais consultadas (ou o aviso de que não deu).
