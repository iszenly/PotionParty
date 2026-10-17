# Potion Party

Jogo Roblox de poções: misture ingredientes num caldeirão, descubra receitas (e seja o primeiro do mundo a criá-las), transforme o seu avatar e o dos amigos e cuide da sua própria loja de poções.

Feito em **Luau (`--!strict`)** e sincronizado com o Roblox Studio pelo **Rojo**. Os dados são salvos com o **ProfileStore**.

> **Estado:** em desenvolvimento (Fase 4B). Ainda não está pronto para lançamento. Veja [docs/PROJECT_STATUS.md](docs/PROJECT_STATUS.md).

## Principais funcionalidades
- **Caldeirão:** até 3 ingredientes; 17 receitas especiais e todas as outras combinações geradas por regra fixa (a mesma combinação dá sempre a mesma poção).
- **Transformações:** gigante, mini, sapo, fantasma, voar, quicar, brilhar…; beber ou **jogar como respingo** em outros jogadores (com Modo Escudo e zonas seguras).
- **Grimório e Descoberta Mundial:** quem cria uma receita primeiro fica registrado para todos os servidores; ranking e receitas secretas da semana.
- **Mutações e clima:** Dourada, Arco-íris, Eterna, Dupla, Eletrificada (Tempestade) e Assombrada (Lua Cheia).
- **Evento do Cometa:** ingredientes raros espalhados e uma barra de energia coletiva.
- **Loja tycoon:** clientes NPC com pedidos, melhorias, venda offline com teto, visitas e curtidas.
- **Social:** trocas seguras, Caldeirão da Amizade e bônus de moedas por amigo.
- **Retenção:** recompensa diária com sequência, missões diárias e Novo Mestre (rebirth).
- **Monetização:** Game Passes e Developer Products (IDs ainda não configurados).

## Requisitos
- Roblox Studio
- Git
- [Rokit](https://github.com/rojo-rbx/rokit), que instala Rojo, StyLua, Selene, luau-lsp e luau nas versões de [rokit.toml](rokit.toml)

## Instalação rápida
```sh
git clone https://github.com/iszenly/PotionParty.git
cd PotionParty
rokit install          # instala as ferramentas nas versões certas
rojo plugin install    # instala o plugin do Rojo no Studio
rojo serve             # inicia a sincronização (porta 34872)
```
No Studio, abra a experiência de **testes** e clique em **Plugins → Rojo → Connect**.

Passo a passo completo: [docs/DEVELOPMENT_SETUP.md](docs/DEVELOPMENT_SETUP.md).

## Comandos principais
```sh
stylua --check src                                    # formatação (use "stylua src" para corrigir)
selene src                                            # lint
rojo build default.project.json -o build-teste.rbxl   # confere se o projeto monta
rojo sourcemap default.project.json -o sourcemap.json
luau-lsp analyze --platform=roblox --sourcemap=sourcemap.json --definitions=<globalTypes.d.luau> --ignore="Packages/**" src
```
As definições para o `luau-lsp` estão em `https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau` ([detalhes](docs/DEVELOPMENT_SETUP.md#5-verificações-de-qualidade)).

## ⚠️ Ambientes de teste
- **Teste sempre no Potion Party [TEST]** (GameId `10771365236`). Confirme pela Command Bar com `print(game.GameId)` antes de qualquer teste que salve dados.
- **Não use a experiência oficial** (GameId `10771336495`) para testes destrutivos, moedas de teste, passes falsos ou experimentos com dados.
- O **painel DEBUG** só aparece no Studio do [TEST].
- **Sincronizar com o Rojo não publica o jogo.** Publicar é uma ação separada (**File → Publish to Roblox**) e vale para a experiência aberta naquela janela.

Guia completo para iniciantes: [docs/TESTING_GUIDE.md](docs/TESTING_GUIDE.md).

## Documentação
| Documento | Conteúdo |
|---|---|
| [docs/README.md](docs/README.md) | Índice e convenções |
| [docs/PROJECT_STATUS.md](docs/PROJECT_STATUS.md) | Estado real de cada sistema |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Estrutura do código e comunicação cliente-servidor |
| [docs/SYSTEMS.md](docs/SYSTEMS.md) | Regras de gameplay, balanceamento e como adicionar ingredientes e receitas |
| [docs/DATA_AND_PERSISTENCE.md](docs/DATA_AND_PERSISTENCE.md) | Perfil do jogador, salvamento e riscos |
| [docs/SECURITY_AND_MONETIZATION.md](docs/SECURITY_AND_MONETIZATION.md) | Validações, anti-spam, DEBUG, passes, produtos e recibos |
| [docs/DEVELOPMENT_SETUP.md](docs/DEVELOPMENT_SETUP.md) | Configuração do ambiente e publicação segura |
| [docs/TESTING_GUIDE.md](docs/TESTING_GUIDE.md) | Como testar no Studio, passo a passo |
| [docs/TEST_CASES.md](docs/TEST_CASES.md) | Casos de teste T01 a T43 |
| [docs/TEST_RESULTS.md](docs/TEST_RESULTS.md) | Histórico real dos testes |
| [docs/KNOWN_ISSUES.md](docs/KNOWN_ISSUES.md) | Problemas e riscos conhecidos |
| [docs/DECISIONS.md](docs/DECISIONS.md) | Decisões de produto e arquitetura |
| [docs/ROADMAP.md](docs/ROADMAP.md) | Progresso das fases |
| [docs/CHANGELOG.md](docs/CHANGELOG.md) | Mudanças por commit |

## Notas rápidas
- **Onde mexer no balanceamento:** [src/shared/Config/](src/shared/Config/) e [src/server/Config/](src/server/Config/) (tabela completa em [docs/SYSTEMS.md](docs/SYSTEMS.md#onde-mexer-no-balanceamento)).
- **Tamanho do servidor:** o mapa tem **6 terrenos de loja**. Use Server Size 6 em **Game Settings → Places**, ou aumente `Shop.plotCount` e as posições em `ShopService.luau`.
- **Trocas:** não são duráveis se o servidor cair (risco aceito P1). Podem ser desligadas com `tradingEnabled = false` em [src/shared/Config/Social.luau](src/shared/Config/Social.luau).
