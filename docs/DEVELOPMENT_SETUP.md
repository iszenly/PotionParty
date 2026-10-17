# Configuração do ambiente de desenvolvimento

> Revisão: 2026-10-17, commit `cf72d51`. Guia para quem vai configurar o projeto num computador novo. Os comandos foram usados neste projeto no Windows, com Git Bash e PowerShell.

## Sumário
- [Requisitos](#requisitos)
- [1. Baixar o projeto](#1-baixar-o-projeto)
- [2. Instalar as ferramentas (Rokit)](#2-instalar-as-ferramentas-rokit)
- [3. Plugin do Rojo no Studio](#3-plugin-do-rojo-no-studio)
- [4. Sincronizar com o Studio](#4-sincronizar-com-o-studio)
- [5. Verificações de qualidade](#5-verificações-de-qualidade)
- [Entendendo as camadas: código, Rojo, Studio e publicação](#entendendo-as-camadas-código-rojo-studio-e-publicação)
- [Publicar sem errar o universo](#publicar-sem-errar-o-universo)
- [Configurar IDs de monetização no [TEST]](#configurar-ids-de-monetização-no-test)
- [Integração opcional: MCP do Roblox Studio](#integração-opcional-mcp-do-roblox-studio)

## Requisitos
- Windows com **Roblox Studio** instalado e logado na conta dona das experiências.
- **Git** (o Git Bash vem junto no Windows).
- **Rokit**, o gerenciador das ferramentas do projeto: [github.com/rojo-rbx/rokit](https://github.com/rojo-rbx/rokit).
- Opcional: **VS Code** com a extensão **Luau Language Server**, que mostra erros de tipo enquanto você digita.

## 1. Baixar o projeto
```sh
git clone https://github.com/iszenly/PotionParty.git
cd PotionParty
```
Para os seus commits saírem com o seu nome **só neste projeto** (sem `--global`):
```sh
git config user.name "seu-usuario"
git config user.email "seu-email-do-github"
```

## 2. Instalar as ferramentas (Rokit)
As versões ficam fixadas em [rokit.toml](../rokit.toml):

| Ferramenta | Versão | Para quê |
|---|---|---|
| Rojo | 7.7.1 | sincroniza os arquivos com o Studio e gera builds |
| StyLua | 2.6.0 | formata o código |
| Selene | 0.32.0 | lint (erros comuns) |
| luau-lsp | 1.70.1 | checagem de tipos `--!strict` |
| luau | 0.743.0 | roda trechos de Luau fora do Studio |

Na pasta do projeto, rode:
```sh
rokit install
```
Se o Rokit perguntar se confia numa ferramenta, responda que sim. Para conferir a instalação: `rojo --version`, `stylua --version` e `selene --version`.

## 3. Plugin do Rojo no Studio
```sh
rojo plugin install
```
Abra o Studio: na aba **Plugins** deve aparecer o botão **Rojo**.

## 4. Sincronizar com o Studio
1. Na pasta do projeto, rode `rojo serve`. Deve aparecer `Rojo server listening` com `Port: 34872`.
   - Se aparecer o erro de porta em uso (`os error 10048`), já existe um `rojo serve` rodando. Use o que está aberto.
2. No Studio, abra a experiência certa. Para testes, use **sempre o [TEST]**: [TESTING_GUIDE.md](TESTING_GUIDE.md#como-abrir-o-test-no-studio).
3. **Plugins → Rojo → Connect**. Deve aparecer **Connected**.
4. A partir daí, tudo que você **salvar** em `src/` aparece no Studio na hora.

**Importante:** edite **sempre** os arquivos `.luau` no VS Code ou no editor, nunca os scripts dentro do Studio. O Rojo sobrescreve o que estiver no Studio.

**Mapeamento das pastas:** veja [ARCHITECTURE.md](ARCHITECTURE.md#pastas-e-mapeamento-do-rojo).

## 5. Verificações de qualidade
Rode antes de cada commit. Nenhum destes comandos altera o jogo publicado ou dados de jogadores.

```sh
stylua --check src          # só confere a formatação (use "stylua src" para corrigir)
selene src                  # lint
rojo build default.project.json -o build-teste.rbxl   # confere se o projeto monta (*.rbxl está no .gitignore)
```

**Checagem de tipos (luau-lsp):**
1. Baixe uma vez as definições de tipos do Roblox para **fora** do repositório:
   ```sh
   curl -sSL -o "$TEMP/globalTypes.d.luau" https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau
   ```
2. Gere o sourcemap. `sourcemap.json` já está no `.gitignore`.
   ```sh
   rojo sourcemap default.project.json -o sourcemap.json
   ```
3. Rode a análise. O `Packages/` fica de fora porque é código de terceiros.
   ```sh
   luau-lsp analyze --platform=roblox --sourcemap=sourcemap.json --definitions="$TEMP/globalTypes.d.luau" --ignore="Packages/**" src
   ```
Sem nenhuma linha de erro, está tudo certo. Se o VS Code tiver a extensão Luau Language Server, ela baixa as definições sozinha.

Os resultados registrados dessas verificações ficam em [TEST_RESULTS.md](TEST_RESULTS.md).

## Entendendo as camadas: código, Rojo, Studio e publicação

| Camada | O que é | Quem vê |
|---|---|---|
| **Código local** | Os arquivos `.luau` no seu computador (VS Code, Claude Code) | Só você |
| **Git / GitHub** | O histórico salvo do código (`git commit`, `git push`) | Quem acessa o repositório |
| **Sincronização do Rojo** | Copia o código local para **o lugar aberto no seu Studio** enquanto `rojo serve` está conectado | Só você, naquela janela do Studio |
| **Studio (Play / Server & Clients)** | Simula o jogo no seu computador | Só você |
| **Publicação** (**File → Publish to Roblox**) | Envia **o lugar aberto no Studio** para a experiência dele no Roblox | Todo mundo que puder entrar nessa experiência |

**Sincronizar com o Rojo NÃO publica o jogo.** Os jogadores só recebem uma versão nova quando alguém **publica** pelo Studio, e os servidores já abertos continuam na versão antiga até fecharem.

**Experiência oficial × experiência de testes:**
- **Potion Party [TEST]** (GameId `10771365236`): para todos os testes, inclusive com DataStore e painel DEBUG.
- **Experiência oficial** (GameId `10771336495`): só recebe publicação de versões aprovadas. Não usar para testes destrutivos.

As DataStores são separadas por experiência: testar no [TEST] não mexe nos dados da oficial.

## Publicar sem errar o universo
1. **Antes de publicar**, abra **View → Command Bar**, rode `print(game.Name, game.PlaceId, game.GameId)` e confira no **Output** se o GameId é o da experiência que você quer.
2. Para publicar no [TEST]: com a janela do [TEST] aberta, use **File → Publish to Roblox**.
3. **Nunca** use **File → Publish to Roblox As…** escolhendo a experiência oficial a partir de uma janela de teste. Isso substitui o lugar oficial pelo conteúdo de teste.
4. Deixe o [TEST] **privado** no Creator Hub, para nenhum jogador entrar por acaso.
5. Publicar na oficial é uma decisão de lançamento: só depois dos testes registrados em [TEST_RESULTS.md](TEST_RESULTS.md).

## Configurar IDs de monetização no [TEST]
Ainda não foi feito. Todos os IDs estão em `0`.
1. No [Creator Hub](https://create.roblox.com), abra o **[TEST]** → **Monetização**. Crie os Passes e os Developer Products listados em [SECURITY_AND_MONETIZATION.md](SECURITY_AND_MONETIZATION.md#game-passes-e-developer-products).
2. Copie cada ID para o campo `id` em [Monetization.luau](../src/shared/Config/Monetization.luau).
3. No Studio, compras com IDs reais são **compras de teste** e não cobram Robux. No jogo publicado, as compras são **reais**.

**Atenção (P22):** passes e produtos pertencem a **uma** experiência. Hoje [Monetization.luau](../src/shared/Config/Monetization.luau) só tem **um** ID por item, então não dá para ter ao mesmo tempo os IDs do [TEST] e os da oficial sem mudar o código. Isso precisa de decisão antes de configurar as duas.

## Integração opcional: MCP do Roblox Studio
- O arquivo [.mcp.json](../.mcp.json) configura o servidor MCP do Roblox Studio para o Claude Code. Ele permite que a IA leia o estado do Studio, como o Output e a interface.
- Ele só funciona com o Studio aberto e o recurso de MCP do Studio habilitado.
- **Antes de pedir à IA que aperte Play** pelo MCP, confirme que a janela aberta é o [TEST].
