# Resultados de testes

> Registro auditável do que foi **realmente executado**. Atualize depois de cada rodada usando o [modelo](#modelo-de-registro-de-execução).
> **Qualidade estática (ferramentas) ≠ funcionamento real (teste manual).** Uma não substitui a outra.

## Sumário
- [Legenda de status](#legenda-de-status)
- [A. Verificações históricas](#a-verificações-históricas)
- [B. Verificações executadas nesta revisão](#b-verificações-executadas-nesta-revisão)
- [C. Testes manuais confirmados](#c-testes-manuais-confirmados)
- [D. Status de todos os casos](#d-status-de-todos-os-casos)
- [E. Análises e cálculos](#e-análises-e-cálculos)
- [Próximos testes recomendados](#próximos-testes-recomendados)
- [Modelo de registro de execução](#modelo-de-registro-de-execução)

## Legenda de status
| Status | Significado |
|---|---|
| **Aprovado** | Executado conforme o procedimento, com o resultado esperado confirmado pelo executor ou por evidência (log, print, inspeção). |
| **Falhou** | Executado, com problema observado. Fica registrado mesmo que tenha sido corrigido depois. |
| **Bloqueado** | Não pode ser executado ainda por causa de uma dependência ou limitação. |
| **Não executado** | Planejado, nunca executado. |
| **Não confirmado** | Há um relato ou execução parcial, mas sem informação suficiente para aprovar. |
| **Revisão técnica** | Cenário que não se reproduz com segurança. A verificação é feita lendo o código. |

**Sobre a evidência "relato":**
- O executor, que é o dono do projeto, informou o resultado na conversa de desenvolvimento.
- O procedimento seguido era o roteiro detalhado entregue na mesma conversa, que corresponde aos casos de [TEST_CASES.md](TEST_CASES.md).
- Quando o relato é incerto, como "acho que passou", o status fica **Não confirmado**.

## A. Verificações históricas

São resultados **de quando foram executados**. Não valem automaticamente para o código atual.

### A1. Auditoria da Fase 4A: 2026-10-16, commit `1a3eb2b`
| Verificação | Resultado na época | Ressalvas |
|---|---|---|
| `stylua --check src` | sem problemas (exit 0) | — |
| `selene src` | 0 erros, 0 avisos | — |
| `luau-lsp analyze --platform=roblox` | sem erros de tipo | `Packages/` ignorado; definições `globalTypes.d.luau` baixadas na hora |
| `rojo build default.project.json` | build ok (183 KB) | build gerado fora do repositório |
| Ciclos de `require` entre serviços (`tsort`) | nenhum | só `script.Parent.X` dentro de `Services/` |
| Remotes (servidor × cliente × limites) | sem inconsistências | 4 "nunca chamados" eram falso positivo (helper local `request`) |
| Chaves de texto (Locale) | só `station.safeZone*` sem texto | busca por padrão; `ui.buy1`/`ui.sell1` eram falso positivo |
| `--!strict` | 91 de 91 arquivos | — |
| Teste em tempo de execução | **não executado** na auditoria | — |

### A2. Testes de lógica fora do Studio (executados pela IA com o interpretador `luau`)
| Data | Commit da época | O que | Resultado |
|---|---|---|---|
| 2026-10-16 (Fase 1) | antes de `1a3eb2b` | FNV-1a contra valores de referência (`""`, `"a"`, `"foobar"`); `Format.number`; ordenação da chave de receita | Aprovado |
| 2026-10-16 (Fase 2) | antes de `1a3eb2b` | `totalCombinations(17,3) = 1139`; virada da semana na segunda 00:00 UTC | Aprovado |

Esses testes usaram **cópias** das funções num script avulso, não os módulos carregados no jogo.

## B. Verificações executadas nesta revisão

**Data:** 2026-10-17 01:14 (-03:00). **Commit:** `cf72d5115399f55b29e15ddec6b6de634e9c9872`. **Árvore:** limpa (`git status` vazio). Saídas geradas no diretório temporário, fora do repositório.

| Comando | Resultado real |
|---|---|
| `stylua --check src` (StyLua 2.6.0) | exit 0 |
| `selene src` (Selene 0.32.0) | 0 errors, 0 warnings, 0 parse errors |
| `rojo sourcemap` + `luau-lsp analyze --platform=roblox --ignore="Packages/**" src` (luau-lsp 1.70.1) | exit 0, nenhum erro |
| `rojo build default.project.json -o <temp>` (Rojo 7.7.1) | build ok |
| Contagem de `--!strict` | 91 de 91 arquivos em `src/` |
| Ciclos de `require` entre serviços (`tsort`, 75 arestas) | nenhum |
| Remotes | 28 RemoteFunctions, todas chamadas pelo cliente e todas com limite próprio; 6 RemoteEvents, todos com ouvinte |
| Chaves de texto | 218 usadas, 222 definidas; faltando: `station.safeZone` e `station.safeZone.action` (caminho não usado, P15); não usadas: `ui.close`, `ui.coins`, `ui.ingredientsList`, `ui.leave`, `ui.loading`, `ui.noIngredients` |
| Módulos sem `require` | nenhum |
| Uso de `PolicyService` | nenhum (confirma P2 em aberto) |
| `TODO(asset)` | 19 ocorrências |

**Limitações:** as checagens de Remotes, chaves e módulos são buscas por texto e podem ter falso positivo ou negativo. Nenhuma verificação desta seção executa o jogo.

## C. Testes manuais confirmados

### Relatos gerais anteriores à Fase 4B
O executor informou que testou manualmente as Fases 1 a 3 e que "diversos sistemas estão funcionando". **Não há procedimento nem resultado por caso**, então nenhum T01 a T29 foi marcado como aprovado com base nisso: o status desses é **Não confirmado** ou **Não executado**.

### R1: Fase 4B.1, 2026-10-17 (entre ~00:03 e ~00:20 -03:00, pelos logs)
- **Executor:** dono do projeto.
- **Versão:** a árvore de trabalho que virou o commit `ea6726e`. A correção `Validate.userId` entrou durante a rodada, antes do commit.
- **Ambiente:** Studio, Play e Server & Clients, numa experiência com API Services ativo (log `Roblox API services available - data will be saved`).
- **Ressalva de ambiente:** o GameId **não foi impresso nesta rodada**. Na rodada seguinte (R2) o Studio aberto foi confirmado como [TESTE] pelo MCP. Para R1, o [TEST] é o ambiente provável, mas **não confirmado por GameId**.

| Passo da rodada | Caso | Status | Evidência e observações |
|---|---|---|---|
| Teste 1: inicialização e ciclo rápido | T41 | **Aprovado** | Log enviado: `modo DEBUG ativo`, `servidor iniciado`, `API services available`; só avisos internos do Roblox |
| Teste 2: venda offline (DEBUG + espera de 6 min) | T22 | **Aprovado** | Relato "Teste 1 e 2 passaram" |
| Teste 3: caldeirão extra que sumiu | T33 | **Aprovado** | Relato "Teste 3 passou" |
| Teste 4: Caldeirão da Amizade | T34 | **Não confirmado** | Relato "Acho que o teste 4 passou"; o log só tem avisos internos do Roblox |
| Teste 5 (1ª execução): troca | T09 | **Falhou** | Relato "deu pedido inválido nos 2 players". **Causa:** os jogadores do Server & Clients têm UserId negativo e o `Validate.integer(…, 1, …)` recusava. **Correção:** `Validate.userId` |
| Teste 5 (2ª execução): troca | T09 | **Aprovado** | Relato "Teste 5 agora passou" |
| Teste 5, passo extra: mudar oferta | T10 | **Não confirmado** | O relato não detalha se o passo extra foi feito |
| Teste 5b: visitar loja | T36 | **Aprovado** | Relato "Teste 5b passou" |
| Teste 6: interruptor de trocas | T35 | **Aprovado** | 1ª tentativa bloqueada pela falha do Teste 5; depois relato "Teste 6 passou". O arquivo ficou em `false` e voltou para `true` antes do commit, por decisão do dono |
| Teste 7: descoberta normal + Grimório depois de Stop/Play | T40 | **Aprovado** | Relato "Teste 7 Passou" |
| Observação do executor | — | **Falhou** (corrigido na R2) | "em alguns casos o player 1 e player 2 estava aparecendo duplicado" na lista de jogadores, virou T37 |

### R2: Fase 4B.2, 2026-10-17 (~00:50 a ~01:05 -03:00)
- **Executor:** dono do projeto.
- **Versão:** a árvore de trabalho que virou o commit `cf72d51`. A correção de `UI.list` entrou durante a rodada.
- **Ambiente:** Studio do **[TEST] confirmado**. O MCP listou "Festa de Poções [TESTE] (placeId 122266248638560)" e `execute_luau` no Client retornou `GameId=10771365236`. O log tem `modo DEBUG ativo`, o que só é possível no [TEST] depois do P17.

| Passo da rodada | Caso | Status | Evidência e observações |
|---|---|---|---|
| Teste 1: DEBUG aparece no [TEST] | T41, T30 (parte 1) | **Aprovado** | Log enviado (`modo DEBUG ativo`, `servidor iniciado`, `API services available`) e relato |
| Teste 2: DEBUG some na oficial | T30 (parte 2) | **Aprovado** | Relato "Teste 1 e 2 passaram" |
| Teste 3 (1ª execução): Cometa | T31 | **Falhou** | Relato "Menu de debug bugado… passando o limite". Inspeção pelo MCP (só leitura): 1º botão do DEBUG em `Y=-86`, conteúdo de 822 px num painel de 300 px. **Causa:** `UI.list` centralizava listas verticais. **Correção:** alinhar ao topo |
| Teste 4 (1ª execução): imunidade e escudo | T32 | **Bloqueado** | Mesmo problema do painel DEBUG |
| Teste 3 (2ª execução) | T31 | **Aprovado** | Relato "Teste 3 Passou" |
| Teste 4 (2ª execução): passos 3 e 4 | T18 | **Aprovado** | Relato "Teste 4 Passou" (o roteiro incluía o respingo básico) |
| Teste 4 (2ª execução): passos 5 a 10 | T32 | **Aprovado** | Idem (imunidade e beber durante a imunidade) |
| Teste 4 (2ª execução): passos 11 e 12 | T19 (só o escudo) | **Aprovado (parcial)** | Idem. Zona segura e "lançar de dentro" **não** fizeram parte da rodada |
| Teste 5: lista de jogadores (3 Players) | T37 | **Aprovado** | Relato "Teste 5 Passou" |
| Teste 6: curtir a própria loja (cor neutra) | T38 | **Aprovado (parcial)** | Relato "Teste 6 passou". A cor vermelha de erro não foi observada nesta rodada |
| Conferência de listas: Mercado, Poções, Grimório | T39 | **Aprovado** | Relato "tinha algumas uis bugadas mas agora tá tudo funcionando sem nada cortado em cima". Antes da correção havia telas cortadas (falha registrada) |

## D. Status de todos os casos
Atualizado em 2026-10-17. Use os IDs de [TEST_CASES.md](TEST_CASES.md).

| ID | Status | Ambiente | Última evidência | Problema ou dependência | Próximo passo |
|---|---|---|---|---|---|
| T01 | Não confirmado | A + API | R1 (T40 mostrou Grimório preservado) | moedas, poções e melhorias não conferidas explicitamente | executar T01 completo |
| T02 | Não executado | D | — | [TEST] publicado; servidores diferentes | quando publicar o [TEST] |
| T03 | Bloqueado | Revisão técnica | — | sem ferramenta para criar perfil v1 | decidir se vale criar a ferramenta |
| T04 | Não executado | A + API | — | — | executar |
| T05 | Não executado | A, D | A2 (só funções auxiliares) | — | executar a parte A |
| T06 | Não executado | A | — | — | executar |
| T07 | Não confirmado | A | R1 Teste 1 (preparar, coletar, beber e vender) | "efeito acaba e personagem volta ao normal" não verificado | executar T07 completo |
| T08 | Não executado | A | — | — | executar |
| T09 | **Aprovado** | B | R1 (2ª execução) | — | regressão |
| T10 | Não confirmado | B | R1 | passo extra sem confirmação | executar |
| T11 | Não executado | B | — | — | executar |
| T12 | Não executado | B | — | fechar janela de cliente pode não remover o jogador | executar; se não der, usar D |
| T13 | Não executado | B | — | encher a prateleira | executar |
| T14 | Bloqueado | D | — | [TEST] publicado + 2 contas | planejar |
| T15 | Não executado | A | — | desligar API Services | executar |
| T16 | Bloqueado | A | — | IDs de monetização = 0 | configurar IDs no [TEST] |
| T17 | Bloqueado | A | — | idem | idem |
| T18 | **Aprovado** | B | R2 | — | regressão |
| T19 | Não confirmado | B | R2 (escudo aprovado) | zona segura e "lançar de dentro" não testados | executar os passos 2 e 3 |
| T20 | Não executado | B | — | — | executar |
| T21 | Não executado | A | — | — | executar |
| T22 | **Aprovado** | A + API | R1 | queda do servidor não coberta (T43) | — |
| T23 | Não executado | B | — | — | executar |
| T24 | Não executado | A | — | — | executar |
| T25 | Não executado | A | — | — | executar |
| T26 | Não executado | A | — | — | executar |
| T27 | Não executado | Revisão técnica / MCP | — | precisa de desenvolvedor ou IA | planejar |
| T28 | Não executado | C | — | P6 e P7 esperados | executar antes da 4B.6 |
| T29 | Não confirmado | Ferramentas + A/B | B (ferramentas ok) + R1/R2 (T09, T18, T41) | T07 ainda não aprovado | completar após T07 |
| T30 | **Aprovado** | A | R2 | — | — |
| T31 | **Aprovado** | A | R2 (2ª execução) | exploit só por revisão | — |
| T32 | **Aprovado** | B | R2 (2ª execução) | — | — |
| T33 | **Aprovado** | A | R1 | — | — |
| T34 | Não confirmado | B | R1 ("acho que passou") | contagem de ingredientes não registrada | repetir anotando contagens |
| T35 | **Aprovado** | B | R1 | — | — |
| T36 | **Aprovado** | B | R1 | — | — |
| T37 | **Aprovado** | B | R2 | — | — |
| T38 | Não confirmado | A | R2 (cor neutra aprovada) | cor vermelha não observada | executar o passo 2 |
| T39 | **Aprovado** | A | R2 | — | — |
| T40 | **Aprovado** | A + API | R1 | — | — |
| T41 | **Aprovado** | A | R1, R2 (logs) | — | regressão |
| T42 | Revisão técnica | — | revisão do código em 2026-10-17 (`claimAsync` e `processEntry`) | não reproduzível | — |
| T43 | Revisão técnica | — | revisão do código em 2026-10-17 (`DataService`) | não reproduzível com segurança | teste controlado opcional |

**Contagem:** 13 Aprovados, 7 Não confirmados, 4 Bloqueados, 17 Não executados, 2 Revisão técnica (43 casos).

## E. Análises e cálculos

| Data | O que | Como | Resultado |
|---|---|---|---|
| 2026-10-17 | Probabilidades exatas das mutações (normal × VIP; clima; bônus de amizade) | script avulso em `luau`, replicando a ordem e as chances de [Mutations.luau](../src/shared/Config/Mutations.luau) | Tabela em [SYSTEMS.md](SYSTEMS.md#mutações). Em todos os cenários, 50% das mutações de um VIP são causadas pelo bônus. Base da regra proposta para a 4B.3 |

## Próximos testes recomendados
Ordem sugerida para um iniciante, do mais simples e importante ao mais trabalhoso. Todos no **[TEST]**, com o GameId confirmado.

1. **T41 + T01:** iniciar sem erros e conferir persistência ao sair e voltar (Play, 1 jogador, API Services ligado).
2. **T07:** ciclo completo da poção, prestando atenção ao personagem voltar ao normal.
3. **T08:** efeito ao morrer (Esc → Reset Character).
4. **T34:** Caldeirão da Amizade de novo, **anotando** as contagens de ingredientes (Server & Clients, 2 Players).
5. **T19, passos 2 e 3:** zona segura (2 Players).
6. **T38, passo 2:** cor vermelha de erro (1 jogador).
7. **T10, T11 e T13:** casos negativos da troca (2 Players).
8. **T21:** pedidos da loja (1 jogador).
9. **T25 e T26:** Diária, missões e Novo Mestre (1 jogador).
10. **T24 e T23:** clima e mutação; energia do Cometa.
11. **T28:** emulador de celular. Isso ajuda a planejar a 4B.6.

## Modelo de registro de execução
Copie para a seção C (nova rodada) e preencha:

```markdown
### Rn: <assunto>, AAAA-MM-DD (hh:mm -03:00)
- **Executor:**
- **Versão:** commit `<sha>` (ou "árvore de trabalho antes de <sha>")
- **Ambiente:** A / B / C / D, GameId confirmado: `<id>`; API Services: ligado / desligado

| Caso | Passos realizados | Esperado | Observado | Status | Evidência |
|---|---|---|---|---|---|
| Txx | 1 a N | ... | ... | Aprovado / Falhou / ... | log, print, relato |
```

Depois, atualize a linha do caso na [tabela D](#d-status-de-todos-os-casos) e, se for o caso, o [KNOWN_ISSUES.md](KNOWN_ISSUES.md).
