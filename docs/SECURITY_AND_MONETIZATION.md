# Segurança e monetização

> Revisão: 2026-10-17, commit `cf72d51`.

## Sumário
- [Princípios](#princípios)
- [Camadas de proteção dos Remotes](#camadas-de-proteção-dos-remotes)
- [Remotes e validações](#remotes-e-validações)
- [Interações fora dos Remotes](#interações-fora-dos-remotes)
- [Painel DEBUG](#painel-debug)
- [Game Passes e Developer Products](#game-passes-e-developer-products)
- [ProcessReceipt e recibos](#processreceipt-e-recibos)
- [Sorte VIP: comportamento atual](#sorte-vip-comportamento-atual)
- [Itens pagos e PolicyService](#itens-pagos-e-policyservice)
- [Decisões aprovadas aguardando implementação](#decisões-aprovadas-aguardando-implementação)

## Princípios
- **O servidor decide tudo que tem valor:** moedas, itens, receitas, descobertas, trocas e compras.
- **O cliente só pede.** O servidor confere tipo, valor, posse, distância e frequência de cada pedido.
- **Nenhum item pago compra Descoberta Mundial nem posição no ranking.** Nenhum produto em [Monetization.luau](../src/shared/Config/Monetization.luau) mexe nesses sistemas.

## Camadas de proteção dos Remotes

1. **Limite de frequência** ([RateLimiter.luau](../src/server/Util/RateLimiter.luau)):
   - "balde de fichas" por jogador e por Remote; cada chamada gasta 1 ficha, e elas voltam aos poucos (`rate` por segundo, até `burst`);
   - valores em [Remotes.luau](../src/shared/Config/Remotes.luau), com padrão de 4/s e rajada de 8;
   - passar do limite gera `error.rateLimited`.
2. **`pcall` no handler** ([src/server/Net.luau](../src/server/Net.luau)): um erro vira `error.generic` e é registrado no Output do servidor.
3. **Validação de argumentos** ([Validate.luau](../src/server/Util/Validate.luau)):
   - `integer` rejeita NaN e infinito e confere o intervalo;
   - `text` confere tamanho máximo;
   - `ingredientId` exige um ingrediente existente;
   - `ingredientList` aceita de 1 a N ids e recusa tabelas com chaves estranhas;
   - `userId` aceita qualquer inteiro diferente de 0, porque o Studio usa UserIds negativos. Um id de alguém que não está no servidor é recusado ao procurar o jogador.
4. **Regras de cada ação:** posse do item, moedas, estado (preparo pronto, troca aberta) e distância da estação (`MapService.isNear`, raio de 16 studs, `Economy.stationRadius`).

## Remotes e validações

28 RemoteFunctions, todas com limite próprio em [Remotes.luau](../src/shared/Config/Remotes.luau). Valores na forma "rate/burst".

| Remote | Principais validações | Distância exigida | Limite |
|---|---|---|---|
| `GetSnapshot` | dados carregados | — | 2/5 |
| `StartBrew` | slot inteiro até o nº de caldeirões; 1 a 3 ingredientes válidos; slot livre; posse | Caldeirão (16) | 2/4 |
| `CollectBrew` | slot até os caldeirões visíveis; preparo pronto; espaço na prateleira | Caldeirão (16) | 3/6 |
| `DrinkPotion` | chave de até 160 caracteres; posse; personagem vivo | — | 1/2 |
| `SellPotion` | chave; quantidade de 1 a 9999; posse | Balcão (16) | 4/8 |
| `BuyIngredient` | id válido; quantidade de 1 a 50; não é só do Cometa; liberado; moedas | Mercado (16) | 4/8 |
| `UnlockIngredient` | id válido; não é só do Cometa; ainda não liberado; moedas | Mercado (16) | 1/3 |
| `BuyUpgrade` | id existente; não está no máximo; moedas | — | 2/4 |
| `GetGrimoireInfo` | dados carregados | — | 0,5/3 |
| `GetRanking` | — (resultado em cache de 60 s) | — | 0,2/2 |
| `ClaimMission` | índice válido; missão completa; não pega | — | 1/3 |
| `ClaimDaily` | não pegou hoje (dia UTC) | — | 0,5/2 |
| `SetShield` | booleano | — | 1/3 |
| `EquipTrail` | `""` ou um cosmético que o jogador possui | — | 1/3 |
| `ThrowPotion` | chave; posse; UserId opcional; intervalo de 2 s; vivo; **fora de zona segura**; alvo a até 46 studs | — | 1/2 |
| `ShopDeliver` | id do cliente; chave; ter loja; poção atende o pedido | Balcão da **própria** loja (22) | 3/6 |
| `VisitShop` | UserId; o alvo tem loja | — | 0,5/2 |
| `TradeRequest` | `tradingEnabled`; UserId; não é você; ninguém já em troca; dados carregados | — | 0,5/3 |
| `TradeRespond` | `tradingEnabled`; convite pendente do mesmo UserId, com até 20 s | — | 1/3 |
| `TradeSetOffer` | formato (até 6 tipos, quantidades de 1 a 9999); **posse antes de resolver receitas** (P8) | — | 4/8 |
| `TradeSetReady` | troca aberta | — | 2/4 |
| `TradeConfirm` | `tradingEnabled`; os dois prontos; 3 s de espera | — | 1/3 |
| `TradeCancel` | — | — | 1/3 |
| `FriendshipPick` | estar num lado; exatamente 2 ingredientes válidos; posse | (sai do lado se ficar a mais de 14) | 3/6 |
| `FriendshipReady` | estar num lado; 2 escolhidos | (idem) | 2/4 |
| `FriendshipLeave` | — | — | 1/3 |
| `Rebirth` | moedas suficientes para o custo; caldeirões vazios | — | 0,2/1 |
| `Debug` | **só existe** quando `Debug.enabled()` | — | 2/4 |

RemoteEvents (do servidor para o cliente): `Sync`, `Announce`, `Transformed`, `Splash`, `Trade` e `Friendship`. Não existe nenhum RemoteEvent do cliente para o servidor.

## Interações fora dos Remotes

Todas são tratadas no servidor:

| Interação | Proteção | Arquivo |
|---|---|---|
| Pegar item do Cometa (`Touched`) | personagem vivo e a até **10 studs** do item (P4, 4B.2); só o primeiro leva | [CometService.luau](../src/server/Services/CometService.luau) |
| Toque no núcleo do Cometa (ProximityPrompt) | 0,35 s entre toques por jogador e até 20 studs | [CometService.luau](../src/server/Services/CometService.luau) |
| Lados do Caldeirão da Amizade (ProximityPrompt) | lado livre e dados carregados | [FriendshipService.luau](../src/server/Services/FriendshipService.luau) |
| Curtir loja (ProximityPrompt) | não pode curtir a própria; 1 por loja por dia | [ShopService.luau](../src/server/Services/ShopService.luau) |
| Respingo atingindo alguém | zona segura, Modo Escudo e **imunidade de 10 s** (4B.2) | [SplashService.luau](../src/server/Services/SplashService.luau) |

## Painel DEBUG

[DebugService.luau](../src/server/Services/DebugService.luau), [DebugUI.luau](../src/client/UI/DebugUI.luau) e [Debug.luau](../src/shared/Config/Debug.luau).
- **Onde existe:** `Debug.enabled()` exige estar **no Studio** e, além disso, `game.GameId == 0` (lugar não publicado) **ou** o GameId estar em `Debug.testGameIds`. Hoje a lista só tem `10771365236`, o Potion Party [TEST].
- **Fora disso:** o Remote `Debug` nem é criado, o botão não aparece e o servidor escreve no Output: `painel DEBUG desligado: GameId … não está em Debug.testGameIds`. Validado no teste T30.
- **No jogo publicado** (mesmo o [TEST] aberto pelo aplicativo Roblox) o painel **não existe**, porque não é Studio.
- **Comandos:**
  - clima (Tempestade, Lua Cheia, céu limpo) e Cometa agora;
  - +5000 e +100.000 moedas; +10 de cada ingrediente;
  - terminar preparos; forçar a próxima mutação (Dourada, Arco-íris, Eterna);
  - Diária de novo; novas missões; simular 2 h offline;
  - ligar e desligar passes (Auto-venda, Sorte VIP, Loja Maior, Caldeirão).
- **Passes ligados pelo DEBUG** (passes com `id = 0`) são **removidos** ao entrar em qualquer lugar onde o DEBUG não está ativo (`MonetizationService.refreshPasses`).
- **Tempos acelerados no Studio:** `fastTimersInStudio` vale em **qualquer** Studio, inclusive na experiência oficial. Só muda tempos de clima e cometa e não grava nada (P21 em [KNOWN_ISSUES.md](KNOWN_ISSUES.md)).

## Game Passes e Developer Products

Fonte: [Monetization.luau](../src/shared/Config/Monetization.luau). **Todos os IDs estão em `0` (não configurados).** Com `id = 0`, a Loja VIP mostra "Em breve" e nada pode ser comprado.

| Tipo | Chave | Nome | O que dá | ID |
|---|---|---|---|---|
| Pass | `ExtraCauldron` | Caldeirão Extra | +1 caldeirão | 0 |
| Pass | `AutoSell` | Auto-venda | atende os pedidos sozinho; dobra os tetos da venda offline | 0 |
| Pass | `VipLuck` | Sorte VIP | sorte 2 nas mutações | 0 |
| Pass | `BigShop` | Loja Maior | +2 clientes ao mesmo tempo | 0 |
| Produto | `IngredientPackSmall` | Pacote de Ingredientes | 3x Raio, Nuvem, Bolha e Pizza | 0 |
| Produto | `IngredientPackBig` | Baú de Ingredientes Raros | 3x Lua, Lava e Ímã; 2x Fantasma e Estrela | 0 |
| Produto | `BrewSkip` | Acelerar Preparo | termina todos os caldeirões agora | 0 |
| Produto | `TrailSparkle` | Trilha Brilhante | cosmético (trilha) | 0 |
| Produto | `TrailRainbow` | Trilha Arco-íris | cosmético (trilha) | 0 |

**Game Passes** ([MonetizationService.luau](../src/server/Services/MonetizationService.luau)):
- Ao carregar o jogador, cada pass com ID é conferido com `UserOwnsGamePassAsync`, e o resultado é copiado para `data.passes`. Se a consulta falhar, mantém o valor anterior.
- Comprar dentro do jogo (`PromptGamePassPurchaseFinished`) libera o pass na hora.

**Compras:** o cliente abre a janela de compra (`MarketplaceService:Prompt…` em [StoreUI.luau](../src/client/UI/StoreUI.luau)); quem entrega é sempre o servidor.

**Como configurar:** veja [DEVELOPMENT_SETUP.md](DEVELOPMENT_SETUP.md#configurar-ids-de-monetização-no-test).

## ProcessReceipt e recibos

Função `processReceipt` em [MonetizationService.luau](../src/server/Services/MonetizationService.luau):

1. **Produto desconhecido** (ID não está na config): responde `NotProcessedYet`.
2. **Jogador fora do servidor**, ou dados que não carregam em 10 s: responde `NotProcessedYet`. O Roblox tenta de novo depois.
3. **Recibo novo** (`data.receipts[PurchaseId]` vazio): entrega **e** grava o recibo no mesmo passo, sem pausas. Depois limpa os recibos excedentes.
4. Pede `profile:Save()` e espera até 15 s o `profile.LastSavedData` conter o recibo.
   - O `LastSavedData` é o valor devolvido pelo DataStore depois de gravar. No modo mock é uma cópia profunda, conferida no código do ProfileStore na auditoria 4A.
5. **Só então** responde `PurchaseGranted`. Se não confirmar a tempo, responde `NotProcessedYet`; na próxima tentativa, o passo 3 vê o recibo e **não entrega de novo**.

**Retenção (P12, 4B.2):** `MAX_RECEIPTS = 1000`. Não há remoção por idade, porque o Roblox pode reenviar um recibo não confirmado muito tempo depois.

**Riscos residuais (não comprovados como impossíveis):**
- reenvio de um recibo mais antigo que as últimas 1000 compras do jogador;
- comprar Acelerar Preparo sem nada preparando: a interface tenta impedir, mas o servidor aceita e não entrega nada (P13);
- comprar um cosmético já possuído: a interface mostra "Comprado ✓", mas o servidor aceitaria a compra.

**Testes:** T16 e T17 estão **Bloqueados**, porque não há produtos configurados no [TEST].

## Sorte VIP: comportamento atual

- **Efeito:** com `data.passes.VipLuck`, `PlayerStats.luck` devolve **2** e todas as chances de mutação dobram. Números reais em [SYSTEMS.md](SYSTEMS.md#mutações).
- **No Caldeirão da Amizade:** entre amigos do Roblox, multiplica também por 1,5.
- **Na troca:** **ainda não existe** nenhuma marcação de "item pago". Hoje uma poção mutada com ajuda da VIP é tratada igual a qualquer outra.
- **`ArePaidRandomItemsRestricted`:** ainda não é consultado. A Loja VIP não mostra a tabela de chances.

## Itens pagos e PolicyService

- **Estado atual:** o código **não usa `PolicyService`** (conferido por busca nesta revisão). As trocas não distinguem itens comprados com Robux (P2, em aberto).
- **Decisão de produto (D07, D08):** permitir trocar poções beneficiadas pela Sorte VIP, sem exigir que os dois tenham o pass, **respeitando as políticas do Roblox** (`IsPaidItemTradingAllowed` e `ArePaidRandomItemsRestricted`). **Isso ainda não está implementado.**

## Decisões aprovadas aguardando implementação
Detalhes e status em [DECISIONS.md](DECISIONS.md).

| Item | Status |
|---|---|
| Contador de unidades pagas (ingredientes de pacotes, poções feitas com eles); pagas consumidas primeiro (D15) | Aprovado; não implementado (4B.3b) |
| Mutações causadas pela VIP contam como item pago (opção C, D07) | Aprovado no geral; **regra exata aguardando aprovação** |
| Regra exata proposta: paga só se o número sorteado ficou entre a chance normal e a chance com VIP | Proposta em 2026-10-17; aguardando aprovação |
| Se a consulta ao PolicyService falhar: tratar como restrito e tentar de novo a cada 60 s | Proposta; aguardando aprovação |
| Loja VIP mostra as chances e respeita `ArePaidRandomItemsRestricted` | Aprovado; não implementado (4B.3a) |
| Acelerar Preparo vira carga persistente (D14) | Aprovado; não implementado |
