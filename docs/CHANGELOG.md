# Changelog

O projeto **não usa versionamento semântico** e ainda não teve lançamento público. As versões são identificadas pelo **SHA do commit**. As datas abaixo são as do próprio commit no Git (fuso -03:00).

## [não publicado] Documentação
- Criada a pasta `docs/` com índice, estado do projeto, arquitetura, sistemas, dados, segurança e monetização, setup, guia de testes, casos de teste (T01 a T43), resultados de testes (rodadas R1 e R2), problemas conhecidos (P1 a P26), decisões, roadmap e este changelog.
- O README principal foi reorganizado como porta de entrada, com links para `docs/`. A seção "Testando no Studio" desatualizada sobre o DEBUG (P19) foi movida e corrigida.
- **Nenhuma mudança de código ou de comportamento do jogo.**

## `cf72d51`: Fase 4B.2, segurança e anti-spam (2026-10-17 01:07)
- P4: a coleta do Cometa confere vida e distância (10 studs) no servidor.
- Imunidade de 10 s a novos respingos (`Social.splashImmunity`).
- P17: painel DEBUG só no Studio do [TEST] (`Debug.testGameIds`) ou de um lugar não publicado; passes do DEBUG removidos fora dele.
- P11: toasts de erro em vermelho e avisos neutros (`toastInfo`).
- P12: recibos sem remoção por idade, limite de 1000.
- P25: lista de jogadores não duplica (`task.defer`).
- P26: listas verticais alinhadas ao topo (`UI.list`).

## `ea6726e`: Fase 4B.1, integridade dos dados (2026-10-17 00:34)
- P3: venda offline não paga duas vezes (`lastSeen` no `DataService.loaded`; `lastLogout` marcado antes do pagamento e atualizado em `OnSave`).
- P9: anúncio mundial só quando o servidor grava o registro.
- P10: Caldeirão da Amizade confere a amizade antes de gastar ingredientes.
- P8: a troca só resolve receitas de itens possuídos; o cache guarda só receitas válidas.
- P18: dá para coletar de um caldeirão extra que sumiu (`PlayerStats.visibleCauldronCount`).
- `Social.tradingEnabled` para desligar trocas; risco P1 documentado no README.
- P24: `Validate.userId` aceita os UserIds negativos do Studio (troca, visita, respingo).
- Primeiro commit com o autor `iszenly`.

## `1a3eb2b`: Fases 1 a 3 (2026-10-16 19:25)
- Estrutura Rojo, Luau `--!strict`, StyLua, Selene, ProfileStore.
- **Fase 1:** ingredientes, receitas determinísticas (fixas e procedurais), caldeirão, efeitos ao beber, venda, melhorias.
- **Fase 2:** Grimório, descoberta mundial (UpdateAsync + MessagingService), ranking, receitas secretas da semana, mutações, clima, Cometa, animação de transformação, painel DEBUG.
- **Fase 3:** respingo, Modo Escudo e zonas seguras, loja com clientes NPC e venda offline, troca, Caldeirão da Amizade, amigos, visitas e curtidas, diária, missões, Novo Mestre, Game Passes e Developer Products (IDs a configurar).
- Commit criado com o autor `zenarkgroup`, antes da configuração local do Git para `iszenly`.
