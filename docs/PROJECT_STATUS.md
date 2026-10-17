# Estado atual do projeto

> **Revisão:** 2026-10-17. **Commit de referência:** `cf72d5115399f55b29e15ddec6b6de634e9c9872` (Fase 4B.2). Na revisão, o `git status` não tinha mudanças locais.

## Sumário
- [Resumo](#resumo)
- [Situação por sistema](#situação-por-sistema)
- [O que mudou na Fase 4B](#o-que-mudou-na-fase-4b)
- [Pendências principais](#pendências-principais)
- [Próximos passos](#próximos-passos)

## Resumo

- **Fases 1, 2 e 3:** implementadas (commit `1a3eb2b`). A maior parte dos sistemas ainda **não tem teste manual registrado**. Testes manuais feitos antes da Fase 4B não foram documentados com procedimento e resultado e aparecem como **Não confirmado**.
- **Fase 4B.1** (integridade dos dados, `ea6726e`) e **4B.2** (segurança e anti-spam, `cf72d51`): implementadas. Os testes manuais das duas rodadas estão em [TEST_RESULTS.md](TEST_RESULTS.md#c-testes-manuais-confirmados).
- **Fases 4B.3 a 4B.6:** ainda não implementadas. Veja o [ROADMAP.md](ROADMAP.md).
- **Verificações estáticas no commit de referência:** StyLua, Selene, luau-lsp e `rojo build` passaram nesta revisão ([TEST_RESULTS.md](TEST_RESULTS.md#b-verificações-executadas-nesta-revisão)).
- **O jogo não está pronto para lançamento.** Itens abertos que pesam nisso:
  - P2 (troca de itens pagos sem PolicyService);
  - IDs de monetização não configurados;
  - ausência de tutorial;
  - layout mobile não validado;
  - risco P1 aceito apenas durante o desenvolvimento.

## Situação por sistema

Legenda da coluna **Testes**: veja [TEST_RESULTS.md](TEST_RESULTS.md#legenda-de-status). "Aprovado" sempre se refere a um teste registrado.

| Sistema | Estado | Arquivos principais | Limitações conhecidas | Testes |
|---|---|---|---|---|
| Ingredientes e desbloqueios | Implementado | [Ingredients.luau](../src/shared/Config/Ingredients.luau), [IngredientService.luau](../src/server/Services/IngredientService.luau), [MarketUI.luau](../src/client/UI/MarketUI.luau) | 17 ingredientes (6 básicos, 10 desbloqueáveis, 1 só do Cometa). Ícones são bolinhas coloridas. | Não confirmado |
| Receitas especiais e procedurais | Implementado | [RecipeService.luau](../src/server/Services/RecipeService.luau), [Recipes.luau](../src/server/Config/Recipes.luau), [NameParts.luau](../src/server/Config/NameParts.luau) | 17 receitas fixas; o resto é procedural. Pode haver nomes procedurais repetidos. | T05: Não executado (só funções auxiliares testadas fora do Studio) |
| Caldeirão e tempo de preparo | Implementado | [CauldronService.luau](../src/server/Services/CauldronService.luau), [CauldronUI.luau](../src/client/UI/CauldronUI.luau) | Não dá para cancelar um preparo. Layout em telas baixas não validado (P7). | T07: Não confirmado; T33 (caldeirão extra, P18): Aprovado |
| Inventário e consumo de poções | Implementado | [PotionService.luau](../src/server/Services/PotionService.luau), [InventoryUI.luau](../src/client/UI/InventoryUI.luau) | Linha do inventário quebra em telas estreitas (P6). | T07: Não confirmado |
| Transformações e efeitos | Implementado | [EffectService.luau](../src/server/Services/EffectService.luau), [EffectController.luau](../src/client/Controllers/EffectController.luau), [Traits.luau](../src/shared/Config/Traits.luau) | Formas são cor e material com peças simples. `ScaleTo` com roupas em camadas não validado. | T08: Não executado |
| Grimório e descobertas mundiais | Implementado | [DiscoveryService.luau](../src/server/Services/DiscoveryService.luau), [GrimoireUI.luau](../src/client/UI/GrimoireUI.luau) | Anúncio entre servidores não testado com servidores reais. | T40: Aprovado; T14: Bloqueado |
| Mutações e clima | Implementado | [MutationService.luau](../src/server/Services/MutationService.luau), [Mutations.luau](../src/shared/Config/Mutations.luau), [WeatherService.luau](../src/server/Services/WeatherService.luau), [WeatherController.luau](../src/client/Controllers/WeatherController.luau) | A mutação é sorteada ao coletar (decisão D02). | T24: Não executado |
| Evento do Cometa | Implementado | [CometService.luau](../src/server/Services/CometService.luau), [CometController.luau](../src/client/Controllers/CometController.luau), [Comet.luau](../src/shared/Config/Comet.luau) | Coleta competitiva (D04). | T31 (coleta com distância): Aprovado; T23 (barra de energia): Não confirmado |
| Loja e clientes NPC | Implementado | [ShopService.luau](../src/server/Services/ShopService.luau), [ShopUI.luau](../src/client/UI/ShopUI.luau), [Shop.luau](../src/shared/Config/Shop.luau) | NPCs deslizam (placeholder). Máximo de 6 lojas por servidor. | T21: Não executado |
| Vendas offline | Implementado (corrigido na 4B.1) | [ShopService.luau](../src/server/Services/ShopService.luau), [DataService.luau](../src/server/Services/DataService.luau) | Vende automaticamente as poções mais baratas sem mutação (a prateleira dedicada, D09, ainda não existe). | T22: Aprovado; T43 (queda do servidor): Bloqueado |
| Melhorias e economia | Implementado | [Upgrades.luau](../src/shared/Config/Upgrades.luau), [UpgradeService.luau](../src/server/Services/UpgradeService.luau), [PlayerStats.luau](../src/shared/Util/PlayerStats.luau), [Economy.luau](../src/shared/Config/Economy.luau) | Economia não balanceada com dados reais. | Não confirmado |
| Respingo, escudo e zonas seguras | Implementado (imunidade na 4B.2) | [SplashService.luau](../src/server/Services/SplashService.luau), [SplashController.luau](../src/client/Controllers/SplashController.luau), [MapService.luau](../src/server/Services/MapService.luau), [SettingsService.luau](../src/server/Services/SettingsService.luau) | Mira automática no jogador mais próximo. | T18, T32: Aprovado; T19: Não confirmado (zona segura não testada); T20: Não executado |
| Trocas entre jogadores | Implementado | [TradeService.luau](../src/server/Services/TradeService.luau), [TradeUI.luau](../src/client/UI/TradeUI.luau) | **P1** (não é durável em crash, risco aceito) e **P2** (sem PolicyService). Interruptor `Social.tradingEnabled`. | T09, T10, T35: Aprovado; T11 a T13: Não executado |
| Caldeirão da Amizade | Implementado (corrigido na 4B.1) | [FriendshipService.luau](../src/server/Services/FriendshipService.luau), [FriendshipUI.luau](../src/client/UI/FriendshipUI.luau) | Só 1 caldeirão por servidor. | T34: Não confirmado |
| Amigos, visitas e curtidas | Implementado | [FriendService.luau](../src/server/Services/FriendService.luau), [ShopService.luau](../src/server/Services/ShopService.luau), [SocialUI.luau](../src/client/UI/SocialUI.luau) | Bônus de amigos não testado (os jogadores de teste do Studio não são amigos). | T36, T37: Aprovado; T38: Não confirmado (só a cor neutra observada) |
| Recompensa diária e missões | Implementado | [MissionService.luau](../src/server/Services/MissionService.luau), [DailyUI.luau](../src/client/UI/DailyUI.luau), [MissionsUI.luau](../src/client/UI/MissionsUI.luau) | Virada às 00:00 UTC (D03). A Diária abre sozinha aos 2 s (vai mudar com o tutorial, D10). | T25: Não executado |
| Novo Mestre (rebirth) | Implementado | [RebirthService.luau](../src/server/Services/RebirthService.luau), [RebirthUI.luau](../src/client/UI/RebirthUI.luau), [Rebirth.luau](../src/shared/Config/Rebirth.luau) | Exige caldeirões vazios. | T26: Não executado |
| Game Passes e Developer Products | Implementado, **IDs não configurados** | [MonetizationService.luau](../src/server/Services/MonetizationService.luau), [Monetization.luau](../src/shared/Config/Monetization.luau), [StoreUI.luau](../src/client/UI/StoreUI.luau) | Todos os `id = 0`. Sem PolicyService (P2). Acelerar Preparo sem preparo ativo (P13). | T16, T17: Bloqueado |
| Interface, mobile e traduções | Implementado | [src/client/UI/](../src/client/UI/), [Locale/](../src/shared/Locale/) | P6 e P7 em aberto. Inglês com 20 de 222 chaves; detecção de idioma desligada. | T28: Não executado; T39: Aprovado |
| Tutorial | **Ausente** | — | Aprovado para implementar na 4B.5 (D10). | — |
| Ferramentas DEBUG e ambientes | Implementado (restrito na 4B.2) | [DebugService.luau](../src/server/Services/DebugService.luau), [DebugUI.luau](../src/client/UI/DebugUI.luau), [Debug.luau](../src/shared/Config/Debug.luau) | Só funciona no Studio do [TEST] (GameId `10771365236`) ou num lugar não publicado. | T30: Aprovado |

## O que mudou na Fase 4B

### 4B.1: integridade dos dados (`ea6726e`)
| Problema | Correção no código | Teste |
|---|---|---|
| P3, venda offline em dobro | `DataService` guarda o `lastSeen` ao carregar, marca `lastLogout = agora` antes da venda offline e atualiza o horário a cada salvamento (`OnSave`). `ShopService.offlineSales` usa o `lastSeen`. | T22 Aprovado; o cenário de queda do servidor (T43) está Bloqueado |
| P9, anúncio mundial repetido | `DiscoveryService.claimAsync` retorna `wroteNow`; só anuncia quando gravou o registro. | Fluxo normal Aprovado (T40); a repetição não é reproduzível manualmente (T42) |
| P10, Caldeirão da Amizade | `areFriends` roda antes de gastar ingredientes; o estado é conferido de novo depois da espera. | T34 Não confirmado |
| P8, cache de receitas | `TradeService` só resolve receitas depois de confirmar a posse; `RecipeService` só guarda receitas válidas no cache. | Fluxo normal de troca Aprovado (T09) |
| P18, caldeirão extra que sumiu | `PlayerStats.visibleCauldronCount`; dá para coletar de um caldeirão "sobrando". | T33 Aprovado |
| Interruptor de trocas | `Social.tradingEnabled`. | T35 Aprovado |
| UserIds negativos do Studio | `Validate.userId` (troca, visita, respingo). Foi achado no teste de troca. | T09, T36 Aprovado |

### 4B.2: segurança e anti-spam (`cf72d51`)
| Problema | Correção no código | Teste |
|---|---|---|
| P4, coleta do Cometa | O servidor exige personagem vivo e distância de até 10 studs (`PICKUP_RADIUS`). | T31 Aprovado (a proteção contra exploit em si não é testável manualmente) |
| Imunidade de respingo | 10 s (`Social.splashImmunity`). | T32 Aprovado |
| P17, DEBUG em produção | `Debug.enabled()` exige Studio e GameId do [TEST] ou lugar não publicado. | T30 Aprovado |
| P11, cores dos avisos | Estilos `toast` (vermelho para `error.*`) e `toastInfo` (neutro). | T38 Não confirmado (só o tom neutro foi observado) |
| P12, retenção de recibos | Limite de 1000 recibos e nenhuma remoção por idade. | Bloqueado (sem produtos configurados) |
| Lista de jogadores duplicada | `SocialUI` redesenha com `task.defer`. | T37 Aprovado |
| Listas cortadas no topo | `UI.list` alinha listas verticais ao topo. | T39 Aprovado |

## Pendências principais
- **4B.3, itens pagos e Sorte VIP:** design aprovado (D07, D08, D15). Ainda **aguardam aprovação**: a regra exata de identificação da mutação VIP e o comportamento quando a consulta ao PolicyService falha ([DECISIONS.md](DECISIONS.md#pendentes-de-aprovação)).
- **4B.4:** tamanho da sincronização (P5).
- **4B.5:** tutorial (D10) e Acelerar Preparo como carga guardada (D14).
- **4B.6:** mobile (P6, P7).
- **Configurar IDs de monetização** no [TEST] antes de testar compras.
- **Reavaliar P1** antes de liberar trocas ao público (D12).

## Próximos passos
1. Executar os testes prioritários listados em [TEST_RESULTS.md](TEST_RESULTS.md#próximos-testes-recomendados).
2. Aprovar as duas decisões pendentes da 4B.3 e implementá-la.
3. Seguir o [ROADMAP.md](ROADMAP.md).
