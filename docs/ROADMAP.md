# Roadmap

> Revisão: 2026-10-17, commit `cf72d51`. O progresso foi conferido no Git e no código. "Implementado" não quer dizer "validado": a validação está em [TEST_RESULTS.md](TEST_RESULTS.md).

| Fase | Conteúdo | Código | Validação prática |
|---|---|---|---|
| **1** | Estrutura Rojo, dados (ProfileStore), ingredientes, receitas, caldeirão, efeitos ao beber, venda, melhorias | Implementado (`1a3eb2b`) | Parcial: T07 não confirmado; T22 e T40 aprovados |
| **2** | Grimório, descoberta mundial, mutações, clima, Cometa, animação de transformação | Implementado (`1a3eb2b`) | Parcial: T40 e T31 aprovados; T14, T23, T24 pendentes |
| **3** | Respingo, Escudo, zonas seguras, loja com NPCs, troca, Caldeirão da Amizade, visitas e curtidas, diária, missões, Novo Mestre, monetização | Implementado (`1a3eb2b`) | Parcial: T09, T18, T36 aprovados; loja, missões, rebirth e compras pendentes |
| **4A** | Auditoria de qualidade e matriz de testes | Concluída (relatório; sem mudar código) | — |
| **4B.1** | Integridade dos dados: P3, P8, P9, P10, P18, interruptor de trocas, P1 documentado, `Validate.userId` | Implementado (`ea6726e`) | Rodada R1: maioria aprovada; T34 (P10) não confirmado |
| **4B.2** | Segurança e anti-spam: P4, imunidade de respingo, P17, P11, P12, lista de jogadores, listas com rolagem | Implementado (`cf72d51`) | Rodada R2: aprovada; T38 parcial |
| Documentação | Pasta `docs/` e histórico de testes | Este commit | — |
| **4B.3** | Itens pagos e Sorte VIP: PolicyService, contador de unidades pagas, regra na troca, transparência das chances | **Não iniciado** | Aguarda PD1 e PD2 ([DECISIONS.md](DECISIONS.md#pendentes-de-aprovação)) |
| **4B.4** | Desempenho: enviar cada receita uma vez só (P5) | Não iniciado | — |
| **4B.5** | Tutorial e primeiros 60 s (D10); Acelerar Preparo como carga (D14) | Não iniciado | — |
| **4B.6** | Interface mobile (P6, P7, painel do caldeirão em telas baixas) | Não iniciado | T28 antes e depois |

## Futuro (sem fase definida)
- **Prateleira dedicada** de venda e venda offline escolhida pelo jogador (D09): só depois de uma proposta específica.
- **Visual e áudio:** substituir os 19 `TODO(asset)` (estações, lojas, NPCs, cometa, itens caídos, ícones, frascos) e criar sons de transformação, respingo, cometa e música.
- **Monetização:**
  - criar os passes e produtos no [TEST];
  - resolver os IDs por universo (P22);
  - executar T16 e T17.
- **Tradução** em inglês (P20).
- **Trocas ao público:** reavaliar P1 (D12) e concluir P2.
- **Testes de lançamento:**
  - executar todos os casos pendentes de [TEST_CASES.md](TEST_CASES.md);
  - testar no [TEST] publicado com contas reais (T02, T14);
  - testar em celulares reais.
- **Testes automatizados** das funções puras (TestEZ, Jest-Lua ou similar): não há no projeto; precisa de aprovação.

O projeto **não tem data de lançamento definida** nem versionamento formal (ver [CHANGELOG.md](CHANGELOG.md)).
