# Documentação do Potion Party

Índice central da documentação técnica. Para a apresentação do projeto e a instalação rápida, veja o [README principal](../README.md).

> **Revisão:** 2026-10-17. **Commit de referência:** `cf72d5115399f55b29e15ddec6b6de634e9c9872` (Fase 4B.2).
> Tudo o que está aqui foi conferido contra o código desse commit. Se o código mudar, atualize os documentos afetados e esta linha.

## Por onde começar

| Você quer… | Leia |
|---|---|
| Saber o que existe e o que já foi testado | [PROJECT_STATUS.md](PROJECT_STATUS.md) |
| Configurar o projeto num computador novo | [DEVELOPMENT_SETUP.md](DEVELOPMENT_SETUP.md) |
| Aprender a testar no Roblox Studio (iniciante) | [TESTING_GUIDE.md](TESTING_GUIDE.md) |
| Executar um teste específico | [TEST_CASES.md](TEST_CASES.md) |
| Registrar ou consultar resultados de testes | [TEST_RESULTS.md](TEST_RESULTS.md) |

## Todos os documentos

| Documento | Responsabilidade |
|---|---|
| [PROJECT_STATUS.md](PROJECT_STATUS.md) | Estado real de cada sistema: implementado, verificado e testado |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Estrutura do código, mapeamento do Rojo, inicialização e comunicação cliente-servidor |
| [SYSTEMS.md](SYSTEMS.md) | Regras de gameplay de cada sistema, com os valores atuais das configurações |
| [DATA_AND_PERSISTENCE.md](DATA_AND_PERSISTENCE.md) | Perfil do jogador, ProfileStore, DataStores, salvamento e riscos |
| [SECURITY_AND_MONETIZATION.md](SECURITY_AND_MONETIZATION.md) | Validações no servidor, anti-spam, DEBUG, Game Passes, produtos e recibos |
| [DEVELOPMENT_SETUP.md](DEVELOPMENT_SETUP.md) | Instalação das ferramentas, Rojo, verificações e publicação segura |
| [TESTING_GUIDE.md](TESTING_GUIDE.md) | Ambientes de teste passo a passo (Studio, Server & Clients, emulador, [TEST] publicado) |
| [TEST_CASES.md](TEST_CASES.md) | Casos de teste reproduzíveis (T01 a T43) |
| [TEST_RESULTS.md](TEST_RESULTS.md) | Histórico auditável do que foi realmente executado e do resultado |
| [KNOWN_ISSUES.md](KNOWN_ISSUES.md) | Problemas e riscos conhecidos (P1 a P26) e seu estado |
| [DECISIONS.md](DECISIONS.md) | Decisões de produto e arquitetura, com motivação e status |
| [ROADMAP.md](ROADMAP.md) | Progresso das fases e o que falta |
| [CHANGELOG.md](CHANGELOG.md) | Mudanças por commit |

## Convenções usadas em toda a documentação

**Estado de uma funcionalidade:**

| Termo | Significado |
|---|---|
| **Implementado** | Existe no código. Não quer dizer que foi testado. |
| **Verificado estaticamente** | Código inspecionado ou ferramentas de análise (StyLua, Selene, luau-lsp, `rojo build`) executadas sem erro. Não prova que funciona no jogo. |
| **Aprovado em teste manual** | Testado no Roblox Studio ou no jogo publicado, com resultado confirmado e registrado em [TEST_RESULTS.md](TEST_RESULTS.md). |

Os status de teste (Aprovado, Falhou, Bloqueado, Não executado, Não confirmado) estão definidos em [TEST_RESULTS.md](TEST_RESULTS.md#legenda-de-status).

**Identificadores:** testes são `T01`, `T02`…; problemas são `P1`, `P2`…; decisões são `D01`, `D02`…; rodadas de teste são `R1`, `R2`…

**Caminhos:** os links apontam para os arquivos do repositório, a partir desta pasta (`../src/...`).

## Ambientes (resumo)

| Experiência | GameId (universo) | Uso |
|---|---|---|
| **Potion Party [TEST]**, no Studio aparece como "Festa de Poções [TESTE]" | `10771365236` | Testes, inclusive com DataStore e painel DEBUG |
| **Experiência oficial**, no Studio aparece como "Festa de Poções" | `10771336495` | Produção. Nunca usar para testes destrutivos |

Detalhes e como conferir em qual experiência você está: [TESTING_GUIDE.md](TESTING_GUIDE.md#como-saber-em-qual-experiência-você-está).
