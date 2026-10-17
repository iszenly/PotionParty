# Dados e salvamento

> Revisão: 2026-10-17, commit `cf72d51`. Documento prioritário: **leia antes de mudar qualquer coisa que seja salva.**

## Sumário
- [Visão geral](#visão-geral)
- [DataStores usadas](#datastores-usadas)
- [Estrutura do perfil do jogador](#estrutura-do-perfil-do-jogador)
- [Ciclo de vida do perfil (ProfileStore)](#ciclo-de-vida-do-perfil-profilestore)
- [Migrações](#migrações)
- [lastLogout e a venda offline (correção P3)](#lastlogout-e-a-venda-offline-correção-p3)
- [Descobertas mundiais e ranking](#descobertas-mundiais-e-ranking)
- [Trocas: limitação de durabilidade (P1)](#trocas-limitação-de-durabilidade-p1)
- [Recibos de compra](#recibos-de-compra)
- [O que NUNCA mudar sem planejamento](#o-que-nunca-mudar-sem-planejamento)
- [Testar persistência sem estragar dados reais](#testar-persistência-sem-estragar-dados-reais)

## Visão geral
- **Dados do jogador:** salvos com o **ProfileStore** ([Packages/ProfileStore.luau](../Packages/ProfileStore.luau), da MAD STUDIO/loleris), uma cópia fixa dentro do repositório.
- **Quem lê e escreve:** só o **servidor**. O ponto central é [DataService.luau](../src/server/Services/DataService.luau). Os outros serviços pegam a tabela com `DataService.get(player)`, alteram e chamam `SyncService.push(player)`.
- **O que o cliente recebe:** uma **cópia** (snapshot). Ele nunca escreve nos dados.

## DataStores usadas

| Nome (código) | Tipo | Chave | Conteúdo | Onde |
|---|---|---|---|---|
| `PotionParty_PlayerData_v1` | DataStore via ProfileStore | `Player_<UserId>` | Perfil do jogador | [DataService.luau](../src/server/Services/DataService.luau) |
| `PotionParty_WorldDiscoveries_v1` | DataStore global | chave da receita (até 50 caracteres; se passar, corta e soma um hash) | Primeiro descobridor do mundo | [DiscoveryService.luau](../src/server/Services/DiscoveryService.luau) |
| `PotionParty_DiscoveryRanking_v1` | OrderedDataStore | `tostring(UserId)` | Total de receitas no Grimório | [DiscoveryService.luau](../src/server/Services/DiscoveryService.luau) |
| Tópico `PP_WorldDiscovery` | MessagingService (não guarda nada) | — | Anúncio de descoberta entre servidores | [DiscoveryService.luau](../src/server/Services/DiscoveryService.luau) |

As DataStores ficam **separadas por experiência (universo)**. O [TEST] e a experiência oficial têm dados independentes, mesmo usando os mesmos nomes.

## Estrutura do perfil do jogador

O tipo completo é `PlayerData` em [Types.luau](../src/shared/Types.luau), e o molde inicial é `buildTemplate()` em [DataService.luau](../src/server/Services/DataService.luau). A versão atual dos dados é `DATA_VERSION = 2`.

| Campo | Conteúdo | Observação |
|---|---|---|
| `version` | número da versão dos dados | usado pelas migrações |
| `coins` | moedas | começa com 100 |
| `ingredients` | `{ [idIngrediente] = quantidade }` | 5 de cada básico no início |
| `unlocked` | `{ [idIngrediente] = true }` | pode comprar no Mercado |
| `potions` | `{ [chaveDaPilha] = quantidade }` | chave = `receita` ou `receita#mutação` |
| `upgrades` | `{ [idMelhoria] = nível }` | |
| `cauldrons` | `{ ["1"] = { key, startedAt, finishAt } }` | chaves em texto para o DataStore aceitar buracos |
| `discovered` | `{ [chaveReceita] = { t, by?, byId?, first? } }` | `by = nil` quer dizer registro mundial pendente |
| `worldFirsts` | quantas receitas o jogador descobriu primeiro no mundo | |
| `weekly` | `{ week, claimed = { [chave] = true } }` | segredos premiados na semana |
| `streak` | `{ count, lastClaimDay }` | Diária |
| `missions` | `{ day, list = { { id, target, progress, reward, claimed } } }` | |
| `rebirths` | quantos Novo Mestre | |
| `lastLogout` | `os.time()`: **até quando o tempo offline já foi contado** | veja [abaixo](#lastlogout-e-a-venda-offline-correção-p3) |
| `settings` | `{ shield }` | Modo Escudo |
| `stats` | `{ brewed, sold, drunk, coinsEarned }` | |
| `shop` | `{ likes, visits, served }` | |
| `likesGiven` | `{ day, users = { [UserId] = true } }` | curtidas dadas hoje |
| `passes` | `{ [chavePass] = true }` | **cópia**: a verdade é o Roblox, conferido ao entrar |
| `receipts` | `{ [PurchaseId] = os.time() }` | compras já entregues |
| `cosmetics` | `{ owned = { [id] = true }, trail? }` | |

O ProfileStore só aceita números, textos, booleanos e tabelas, e as tabelas não podem misturar índices numéricos com chaves de texto.

## Ciclo de vida do perfil (ProfileStore)

Valores do ProfileStore copiado ([ProfileStore.luau](../Packages/ProfileStore.luau)):
- `AUTO_SAVE_PERIOD = 300`: salva automaticamente a cada ~5 min.
- `SESSION_STEAL = 40`: um servidor que espera pela trava "rouba" a sessão depois de 40 s.
- `ASSUME_DEAD = 630`: uma sessão sem atualização por 630 s é tratada como de um servidor que caiu.

```mermaid
sequenceDiagram
    participant P as Jogador
    participant DS as DataService
    participant PS as ProfileStore
    P->>DS: entra (PlayerAdded)
    DS->>PS: StartSessionAsync("Player_<UserId>") com Cancel se sair
    alt não conseguiu
        DS->>P: Kick("kick.loadFailed")
    else saiu enquanto carregava
        DS->>PS: EndSession() (lastLogout NÃO é mexido)
    else carregou
        DS->>DS: Reconcile + migrate
        DS->>DS: lastSeen = lastLogout; lastLogout = agora
        DS->>DS: OnSave/OnLastSave atualizam lastLogout
        DS-->>DS: loaded(player, data, lastSeen)
    end
    Note over PS: autosave ~5 min; Save() manual em trocas e compras
    P->>DS: sai (PlayerRemoving)
    DS->>DS: releasing(player, data); lastLogout = agora
    DS->>PS: EndSession() (salva e libera a trava)
```

- **Session locking:** o ProfileStore impede que dois servidores escrevam no mesmo perfil. Se outro servidor tomar a sessão, `OnSessionEnd` dispara e o jogador recebe o kick `kick.sessionEnded`.
- **Reconcile:** preenche **campos que faltam** usando o molde, inclusive dentro de tabelas (é recursivo, só para chaves de texto). Campos novos aparecem sozinhos nos perfis antigos. Ele **não apaga** campos que não existem mais.
- **Desligamento do servidor:** o próprio ProfileStore registra `game:BindToClose` e salva todos os perfis ativos.
- **Falha temporária do DataStore:** o ProfileStore tenta de novo com espera crescente, e os dados continuam em memória.
- **Sem API Services (Studio):** o ProfileStore usa um DataStore falso (mock). O jogo funciona, mas nada é salvo; o Output mostra `data will not be saved`.
- **`DataService.save(player)`:** pede um salvamento imediato (`profile:Save()`) **sem esperar** terminar. É usado depois de trocas.

## Migrações

`migrate(data)` em [DataService.luau](../src/server/Services/DataService.luau) roda depois do `Reconcile`.

| De → para | O que faz |
|---|---|
| v1 → v2 | `discovered[chave]` era um número (horário) e virou `{ t = número }` |

**Como fazer uma migração nova:**
1. Aumente `DATA_VERSION`.
2. Adicione um bloco `if data.version < N then ... end`.
3. Teste com um perfil antigo, no [TEST], antes de publicar. O teste T03 ainda não foi executado.

## lastLogout e a venda offline (correção P3)

**Significado atual:** `lastLogout` é "até quando o tempo offline já foi contabilizado". Apesar do nome, não é só o horário de saída.

**Como funciona desde a 4B.1** (`ea6726e`):
1. Ao carregar, `DataService` guarda `lastSeen = data.lastLogout`, que é o valor salvo da sessão anterior.
2. **Antes** de qualquer pagamento offline, marca `data.lastLogout = os.time()`.
3. Dispara `loaded(player, data, lastSeen)`. O `ShopService.offlineSales(player, data, lastSeen)` calcula a venda offline com o `lastSeen`.
4. Daí em diante, **cada salvamento** (`profile.OnSave`) e o último salvamento (`OnLastSave`) atualizam `lastLogout = os.time()`.

**Por que não paga duas vezes:**
- Os passos 2 e 3 rodam **sem pausas** (`task.wait` ou chamadas que esperam). Nenhum salvamento acontece entre eles.
- Por isso, toda gravação que tiver as moedas da venda offline também terá o `lastLogout` novo. Se o servidor cair depois, o próximo login não repete o pagamento.

**Risco residual:**
- Se o servidor cair, o tempo entre o último salvamento e a queda (até ~5 min) é contado como offline no próximo login. Isso vale no máximo ~1 venda.
- No caso extremo de algum salvamento acontecer entre os passos 2 e 3 (não esperado), o jogador **perde** aquela venda offline; ele nunca recebe em dobro.

**Testes:**
- O fluxo normal está aprovado (T22).
- O cenário de queda do servidor não é reproduzível com segurança no Studio (T43, Bloqueado).
- A garantia contra a queda vem da revisão do código acima.

## Descobertas mundiais e ranking

**Registro mundial:**
- `claimAsync` faz `UpdateAsync` na DataStore global. A função de transformação **não grava** se já houver dono (retorna `nil`) e é recalculada se houver conflito.
- O `UpdateAsync` é atômico: dois servidores ao mesmo tempo resultam em um único dono. Isso ainda não foi testado com servidores reais (T14, Bloqueado).
- O registro do dono fica no Grimório do jogador (`by`, `byId`, `first`), então abrir o Grimório não lê a DataStore global.
- Se o jogador sair antes de o registro terminar, a entrada continua com `by = nil` e é refeita no próximo login, até 5 por login.
- **Correção P9 (4B.1):** quando o registro global já é do próprio jogador (uma tentativa anterior gravou, mas o Grimório não foi salvo), o Grimório é marcado **sem anunciar de novo**. O contador `worldFirsts` só sobe quando `by` ainda era `nil`, então não duplica.

**Ranking:**
- `SetAsync(UserId, total de receitas no Grimório)` a cada 60 s para quem descobriu algo, e ao sair.
- Ao desligar o servidor, essa gravação não é esperada (P16): o ranking pode ficar desatualizado até a próxima atualização.

## Trocas: limitação de durabilidade (P1)

- **A troca atual NÃO é uma transação durável.** Em [TradeService.luau](../src/server/Services/TradeService.luau), a função `execute`:
  1. confere de novo posse e capacidade;
  2. move os itens dos dois perfis **em memória**, sem pausas;
  3. pede `DataService.save` para os dois perfis, em duas gravações **independentes**.
- **O risco:** se o servidor **cair de repente** (crash) depois de gravar um perfil e antes do outro, um lado pode ficar com itens duplicados e o outro perdê-los.
- **O que não causa isso:** um desligamento normal (o `BindToClose` salva os dois) e falhas temporárias do DataStore (o ProfileStore tenta de novo).
- **Status:** risco **aceito durante o desenvolvimento** (D12), com reavaliação obrigatória antes de liberar as trocas ao público. O interruptor `tradingEnabled` em [Social.luau](../src/shared/Config/Social.luau) desliga as trocas.

## Recibos de compra

Implementação em [MonetizationService.luau](../src/server/Services/MonetizationService.luau); detalhes em [SECURITY_AND_MONETIZATION.md](SECURITY_AND_MONETIZATION.md#processreceipt-e-recibos).
- `data.receipts[PurchaseId] = os.time()` é gravado **junto** com a entrega, sem pausas no meio.
- **Limite:** `MAX_RECEIPTS = 1000`. Os mais antigos só saem quando o jogador passa de 1000 recibos. **Não há remoção por idade** (decisão da 4B.2).
- **Risco residual:** se o Roblox reenviar um recibo tão antigo que já foi removido (mais de 1000 compras depois), o item seria entregue de novo. É considerado muito improvável, mas não impossível.

## O que NUNCA mudar sem planejamento

| Mudança | Consequência |
|---|---|
| Nome `PotionParty_PlayerData_v1` | **Todos os jogadores recomeçam do zero**; os dados antigos ficam inacessíveis |
| Nome das DataStores de descoberta e ranking | O registro mundial e o ranking recomeçam |
| `id` de ingrediente, mutação, trait ou melhoria | Inventários, chaves de poção (`receita#mutação`) e Grimórios param de corresponder |
| Formato da chave da receita (`RecipeKey`) | Todas as poções e descobertas salvas ficam inválidas |
| Definição de uma receita existente (fixa ou procedural) | Nome, efeito e valor mudam para quem já tem a poção (os dados não quebram) |
| Remover um campo do molde | O `Reconcile` não apaga o campo: a migração precisa limpar |
| Prefixo `Player_` da chave do perfil | Os perfis não são encontrados |

## Testar persistência sem estragar dados reais

1. **Use sempre o universo [TEST]** (GameId `10771365236`). Confirme antes pela Command Bar ([TESTING_GUIDE.md](TESTING_GUIDE.md#como-saber-em-qual-experiência-você-está)).
2. **API Services** só fica ligado no [TEST]. Na experiência oficial, deixe desligado no Studio.
3. **Jogadores do Server & Clients** têm UserId negativo (`-1`, `-2`…). Os perfis deles (`Player_-1`…) são **reaproveitados entre testes** no [TEST].
4. **Para recomeçar um perfil de teste:**
   - **não existe** um comando de "apagar perfil" no painel DEBUG (só há atalhos como moedas, ingredientes e passes falsos). Criar esse comando seria uma mudança de código e precisa de aprovação;
   - o caminho possível hoje é o gerenciador de Data Stores do Creator Hub, se disponível na sua conta. Ainda não usado neste projeto.
5. **Nunca use** "+100.000", passes falsos ou outros comandos DEBUG na experiência oficial. O painel nem aparece lá desde a 4B.2 (P17).
6. **Cenários de crash** não são simulados no universo oficial. Ficam como revisão técnica ou teste controlado (T43).
