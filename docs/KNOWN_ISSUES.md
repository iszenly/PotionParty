# Problemas e riscos conhecidos

> Revisão: 2026-10-17, commit `cf72d51`.
> - **P1 a P18** vêm da auditoria da Fase 4A (2026-10-16).
> - **P19 a P23** foram encontrados nesta revisão de documentação.
> - **P24 a P26** foram encontrados e corrigidos durante os testes da Fase 4B.
>
> Uma correção no código **não encerra** o problema enquanto o cenário não for testado: veja a coluna "Validação".

## Estados
| Estado | Significado |
|---|---|
| **Em aberto** | Sem correção no código. |
| **Corrigido no código** | Há correção num commit. A validação aparece na coluna própria. |
| **Risco aceito** | Decisão consciente de não corrigir agora (com motivo e prazo de reavaliação). |
| **Dependente de teste** | Só um teste prático confirma se o problema existe. |

## Resumo
| ID | Gravidade | Estado | Commit | Validação |
|---|---|---|---|---|
| [P1](#p1--troca-não-é-durável-em-crash) | Alta | **Risco aceito** (D12) | — | — |
| [P2](#p2--troca-de-itens-pagos-sem-policyservice) | Alta | **Em aberto** (planejado na 4B.3) | — | — |
| [P3](#p3--venda-offline-paga-duas-vezes-após-queda) | Média | Corrigido no código | `ea6726e` | T22 Aprovado; T43 revisão técnica |
| [P4](#p4--coleta-do-cometa-sem-checar-distância) | Média | Corrigido no código | `cf72d51` | T31 Aprovado (fluxo legítimo); exploit por revisão técnica |
| [P5](#p5--snapshot-cresce-com-as-descobertas) | Média | Em aberto (4B.4) | — | precisa de medição |
| [P6](#p6--linha-do-inventário-em-telas-estreitas) | Média | Em aberto, dependente de teste (4B.6) | — | T28 Não executado |
| [P7](#p7--hud-sobre-os-controles-do-celular) | Média | Em aberto, dependente de teste (4B.6) | — | T28 Não executado |
| [P8](#p8--cache-de-receitas-alimentado-pelo-cliente) | Média | Corrigido no código | `ea6726e` | T09 Aprovado (regressão); exploit por revisão técnica |
| [P9](#p9--anúncio-mundial-repetido) | Baixa | Corrigido no código | `ea6726e` | T40 Aprovado; T42 revisão técnica |
| [P10](#p10--caldeirão-da-amizade-gasta-antes-de-esperar) | Baixa | Corrigido no código, **pendente de validação** | `ea6726e` | T34 Não confirmado |
| [P11](#p11--cores-dos-avisos) | Baixa | Corrigido no código, validação parcial | `cf72d51` | T38 Não confirmado (só o neutro observado) |
| [P12](#p12--retenção-de-recibos) | Baixa | Corrigido no código | `cf72d51` | T16/T17 Bloqueados |
| [P13](#p13--acelerar-preparo-sem-preparo-ativo) | Baixa | Em aberto (decisão D14) | — | — |
| [P14](#p14--total-do-grimório-sem-as-receitas-da-amizade) | Baixa | Em aberto | — | — |
| [P15](#p15--textos-faltando-ou-sem-uso) | Baixa | Em aberto | — | — |
| [P16](#p16--ranking-não-salvo-no-desligamento) | Baixa | Em aberto (por design) | — | — |
| [P17](#p17--debug-podia-gravar-dados-na-oficial) | Média | Corrigido no código | `cf72d51` | T30 Aprovado |
| [P18](#p18--caldeirão-extra-inacessível-após-reembolso) | Baixa | Corrigido no código | `ea6726e` | T33 Aprovado |
| [P19](#p19--readme-desatualizado-sobre-o-debug) | Baixa | Corrigido nesta revisão (documentação) | este commit | — |
| [P20](#p20--tradução-em-inglês-incompleta) | Baixa | Em aberto | — | — |
| [P21](#p21--tempos-acelerados-em-qualquer-studio) | Baixa | Em aberto | — | — |
| [P22](#p22--um-único-id-de-monetização-para-dois-universos) | Média | Em aberto (**exige decisão**) | — | — |
| [P23](#p23--limitações-do-ambiente-de-teste) | Baixa | Limitação conhecida | — | — |
| [P24](#p24--userid-negativo-recusado-no-studio) | Média | Corrigido no código | `ea6726e` | T09, T36 Aprovados |
| [P25](#p25--jogadores-duplicados-na-lista) | Baixa | Corrigido no código | `cf72d51` | T37 Aprovado |
| [P26](#p26--listas-com-rolagem-cortadas-no-topo) | Média | Corrigido no código | `cf72d51` | T39 Aprovado |

---

### P1 — Troca não é durável em crash
- **Onde:** `execute` em [TradeService.luau](../src/server/Services/TradeService.luau); `DataService.save` em [DataService.luau](../src/server/Services/DataService.luau).
- **Problema:** os itens são movidos em memória e os dois perfis são salvos em duas gravações independentes.
- **Cenário:** troca concluída → o servidor **cai** (não é um desligamento normal) depois de gravar um perfil e antes do outro → um lado fica com itens duplicados e o outro os perde.
- **Mitigação atual:** desligamento normal e falhas temporárias são cobertos pelo ProfileStore. Existe o interruptor `Social.tradingEnabled`.
- **Decisão:** risco aceito durante o desenvolvimento; **reavaliar antes de liberar as trocas ao público** (D12).

### P2 — Troca de itens pagos sem PolicyService
- **Onde:** [TradeService.luau](../src/server/Services/TradeService.luau). Não há nenhum uso de `PolicyService` no projeto (conferido em 2026-10-17).
- **Problema:** ingredientes de pacotes pagos e poções feitas com eles podem ser trocados sem consultar `IsPaidItemTradingAllowed`.
- **Cenário:** um jogador de uma região com restrição troca ingredientes vindos de um pacote.
- **Plano aprovado (4B.3):** contador de unidades pagas, pagas consumidas primeiro, poções derivadas pagas, mutações causadas pela VIP pagas (D07, D08, D15). Ainda **aguardam aprovação** a regra exata da VIP e o comportamento quando a consulta falha.
- **Observação relacionada:** a Loja VIP ainda não mostra as chances da Sorte VIP, e `ArePaidRandomItemsRestricted` não é consultado.

### P3 — Venda offline paga duas vezes após queda
- **Correção (`ea6726e`):** `lastSeen` é guardado ao carregar, `lastLogout = agora` é marcado antes do pagamento, e `OnSave` e `OnLastSave` atualizam o horário. Detalhes em [DATA_AND_PERSISTENCE.md](DATA_AND_PERSISTENCE.md#lastlogout-e-a-venda-offline-correção-p3).
- **Risco residual:** até ~5 min (do último salvamento até a queda) contados como offline; ou perda, nunca duplicação, se houver um salvamento inesperado entre a marcação e o pagamento.
- **Validação:** fluxo normal aprovado (T22); queda não reproduzível (T43, revisão técnica).

### P4 — Coleta do Cometa sem checar distância
- **Correção (`cf72d51`):** o `Touched` exige personagem vivo e distância de até 10 studs (`PICKUP_RADIUS` em [CometService.luau](../src/server/Services/CometService.luau)).
- **Validação:** coleta legítima aprovada (T31). A proteção contra toque falsificado só é verificável por revisão.

### P5 — Snapshot cresce com as descobertas
- **Onde:** `SyncService.build` em [SyncService.luau](../src/server/Services/SyncService.luau).
- **Problema:** cada envio leva o perfil inteiro e um `RecipeInfo` por receita descoberta.
- **Cenário:** um jogador com centenas de receitas reenvia dezenas de KB a cada venda, missão ou cliente, o que pode causar lag.
- **Plano:** Fase 4B.4 (enviar cada receita uma vez só). Precisa de medição.

### P6 — Linha do inventário em telas estreitas
- **Onde:** [InventoryUI.luau](../src/client/UI/InventoryUI.luau). O nome da poção reserva `1, -76 - 430` px; desde a Fase 3 a área de botões tem 420 px.
- **Cenário:** em 568×320 (iPhone SE deitado), o nome fica com largura negativa ou some.
- **Validação:** T28 não executado. Plano: 4B.6.

### P7 — HUD sobre os controles do celular
- **Onde:** [HUD.luau](../src/client/UI/HUD.luau). A coluna da direita tem 4 botões de 56 px; as fichinhas da esquerda descem até cerca de y = 256 (5 fichinhas a partir de y = 62).
- **Cenário:** em telas com ~320 px de altura, os botões cobrem o pulo e as fichinhas cobrem o direcional. O painel do caldeirão também pode sobrepor texto e botões em telas baixas.
- **Validação:** T28 não executado. Plano: 4B.6.

### P8 — Cache de receitas alimentado pelo cliente
- **Correção (`ea6726e`):** `TradeSetOffer` só resolve receitas depois de confirmar a posse, e `RecipeService.resolve` só guarda receitas válidas no cache.
- **Validação:** troca normal aprovada (T09). Envio de chaves inventadas: revisão técnica.

### P9 — Anúncio mundial repetido
- **Correção (`ea6726e`):** `claimAsync` retorna `wroteNow`; só há anúncio quando esta chamada gravou o registro.
- **Validação:** fluxo normal aprovado (T40); repetição por revisão técnica (T42).

### P10 — Caldeirão da Amizade gasta antes de esperar
- **Correção (`ea6726e`):** `FriendService.areFriends` é chamado antes de gastar ingredientes, e o estado (lados, prontos, escolhas) é conferido de novo depois.
- **Validação:** **pendente**. T34 está Não confirmado ("acho que passou"). Repetir anotando as contagens.

### P11 — Cores dos avisos
- **Correção (`cf72d51`):** em [Banner.luau](../src/client/UI/Banner.luau), o estilo `toast` fica vermelho para chaves `error.*` e verde para o resto; `toastInfo` é neutro.
- **Validação:** o neutro foi aprovado; o vermelho vindo do servidor não foi observado (T38).

### P12 — Retenção de recibos
- **Correção (`cf72d51`):** `MAX_RECEIPTS` subiu de 100 para 1000, sem remoção por idade ([MonetizationService.luau](../src/server/Services/MonetizationService.luau)).
- **Risco residual:** um reenvio de recibo mais antigo que as últimas 1000 compras do jogador entregaria de novo. Muito improvável, mas não comprovado como impossível.
- **Validação:** bloqueada (sem produtos configurados).

### P13 — Acelerar Preparo sem preparo ativo
- **Onde:** `grant` em [MonetizationService.luau](../src/server/Services/MonetizationService.luau); a proteção existe só na interface ([StoreUI.luau](../src/client/UI/StoreUI.luau)).
- **Cenário:** o preparo termina entre o toque e a confirmação da compra; o jogador paga e nada acontece. O mesmo vale para recomprar um cosmético já possuído.
- **Decisão:** transformar em uma carga persistente (D14). Ainda não implementado.

### P14 — Total do Grimório sem as receitas da Amizade
- **Onde:** `GetGrimoireInfo` em [DiscoveryService.luau](../src/server/Services/DiscoveryService.luau) (`totalCombinations` com no máximo 3 ingredientes).
- **Problema:** o contador "N/1.139" conta descobertas de 4 ingredientes no N, mas não no total.

### P15 — Textos faltando ou sem uso
- **Faltando:** `station.safeZone` e `station.safeZone.action`, usados por `MapService.addSafeZone` só quando `showLabel` é verdadeiro, o que hoje nunca acontece.
- **Sem uso:** `ui.close`, `ui.coins`, `ui.ingredientsList`, `ui.leave`, `ui.loading`, `ui.noIngredients` em [ptBR.luau](../src/shared/Locale/ptBR.luau).

### P16 — Ranking não salvo no desligamento
- **Onde:** [DiscoveryService.luau](../src/server/Services/DiscoveryService.luau). A gravação do ranking ao sair é disparada sem esperar, e não há `BindToClose`.
- **Efeito:** o ranking fica desatualizado até a próxima atualização. Os registros mundiais pendentes são refeitos no login (por design).

### P17 — DEBUG podia gravar dados na oficial
- **Correção (`cf72d51`):** `Debug.enabled()` exige Studio e (GameId 0 ou GameId em `testGameIds`). Os passes do DEBUG são removidos fora dele.
- **Validação:** T30 aprovado.

### P18 — Caldeirão extra inacessível após reembolso
- **Correção (`ea6726e`):** `PlayerStats.visibleCauldronCount`; dá para coletar de um caldeirão "sobrando".
- **Validação:** T33 aprovado.

### P19 — README desatualizado sobre o DEBUG
- **Problema:** o README dizia que o painel DEBUG aparece em qualquer Play no Studio. Desde a 4B.2 ele só aparece no [TEST] ou num lugar não publicado.
- **Estado:** corrigido nesta revisão. As instruções de teste foram movidas para [TESTING_GUIDE.md](TESTING_GUIDE.md).

### P20 — Tradução em inglês incompleta
- **Onde:** [en.luau](../src/shared/Locale/en.luau) tem 20 chaves (de 222 em português). `AUTO_DETECT_LANGUAGE = false` em [Main.client.luau](../src/client/Main.client.luau). Nomes de poções são só em português.
- **Efeito:** com a detecção ligada, a interface ficaria misturada. Hoje é tudo em português.

### P21 — Tempos acelerados em qualquer Studio
- **Onde:** `Debug.time` em [Debug.luau](../src/shared/Config/Debug.luau) usa só `RunService:IsStudio()`, e não `Debug.enabled()`.
- **Efeito:** no Studio da experiência oficial, clima e cometa também ficam 4x mais rápidos. Não grava dados; é só uma inconsistência. Não corrigido (precisa de aprovação).

### P22 — Um único ID de monetização para dois universos
- **Onde:** [Monetization.luau](../src/shared/Config/Monetization.luau) tem um `id` por item.
- **Problema:** passes e produtos pertencem a **uma** experiência. Para testar compras no [TEST] e vender na oficial, são necessários IDs diferentes por universo.
- **Exige decisão:** por exemplo, IDs por GameId, ou trocar os IDs só no momento de publicar.

### P23 — Limitações do ambiente de teste
- **Server & Clients:**
  - os jogadores têm UserId negativo e não são amigos do Roblox;
  - por isso, bônus de amigos e sorte do Caldeirão da Amizade entre amigos **não são testáveis** no Studio;
  - `IsFriendsWithAsync` falha na hora para esses ids, e isso causou o P25.
- **Perfil de teste:** não existe um comando DEBUG para apagar o perfil.

### P24 — UserId negativo recusado no Studio
- **Encontrado:** R1, Teste 5 (troca deu "Pedido inválido").
- **Causa:** `Validate.integer(targetUserId, 1, 2^52)` recusava os UserIds negativos do Server & Clients.
- **Correção (`ea6726e`):** `Validate.userId`, usado em troca, visita e respingo.
- **Validação:** T09 e T36 aprovados.

### P25 — Jogadores duplicados na lista
- **Encontrado:** relato durante a R1.
- **Causa:** em [SocialUI.luau](../src/client/UI/SocialUI.luau), a checagem de amizade falhava na hora (P23) e redesenhava a lista no meio do desenho anterior.
- **Correção (`cf72d51`):** redesenho com `task.defer`.
- **Validação:** T37 aprovado.

### P26 — Listas com rolagem cortadas no topo
- **Encontrado:** R2, Teste 3. O painel DEBUG tinha o 1º botão em `Y=-86`, visto pela inspeção via MCP.
- **Causa:** `UI.list` em [Components.luau](../src/client/UI/Components.luau) centralizava verticalmente.
- **Correção (`cf72d51`):** listas verticais alinhadas ao topo.
- **Validação:** T39 aprovado (Mercado, Poções, Grimório e DEBUG).
