# Potion Party

Jogo Roblox de poções: misture até 3 ingredientes num caldeirão, descubra receitas e transforme seu avatar.

## Ferramentas

As ferramentas ficam fixadas no [rokit.toml](rokit.toml):

| Ferramenta | Para quê |
|---|---|
| Rojo | sincroniza os arquivos `.luau` com o Roblox Studio |
| StyLua | formata o código |
| Selene | aponta erros comuns (lint) |
| luau-lsp | checa os tipos (`--!strict`) |
| luau | roda trechos de Luau fora do Studio |

### Instalação (uma vez só)

1. Instale o [Rokit](https://github.com/rojo-rbx/rokit) (no Windows, baixe o instalador na página de releases).
2. Na pasta do projeto, rode `rokit install`. Ele baixa as versões certas de todas as ferramentas.
3. No Roblox Studio, instale o plugin do Rojo. O jeito mais fácil é rodar `rojo plugin install`.

## Sincronizando com o Studio

1. Na pasta do projeto, rode `rojo serve`. Deve aparecer `listening on port 34872`.
2. Abra o Studio com um lugar **Baseplate**.
3. Na aba **Plugins**, abra o **Rojo** e clique em **Connect**.
4. Pronto: tudo que você salvar em `src/` aparece no Studio na hora.

> Edite sempre os arquivos `.luau`, não os scripts dentro do Studio. O Rojo sobrescreve o que estiver no Studio.

### Salvar dados no Studio (API Services)

Sem isso, o jogo funciona, mas os dados **não são salvos** entre testes (aparece no Output: `data will not be saved`).

1. Publique o lugar: **File → Publish to Roblox**.
2. Vá em **Home → Game Settings → Security**.
3. Ative **Enable Studio Access to API Services** e clique em **Save**.

## Estrutura

```
src/
  shared/            (ReplicatedStorage.Shared) usado por servidor e cliente
    Config/          ← BALANCEAMENTO: ingredientes, traços, economia, melhorias, limites
    Locale/          textos da interface (ptBR.luau, en.luau)
    Util/            funções puras (chave de receita, hash, formatação, cálculos)
    Types.luau       tipos compartilhados
  server/            (ServerScriptService.Server)
    Config/          receitas especiais e peças de nomes (ficam escondidas do cliente)
    Services/        lógica do jogo (dados, caldeirão, efeitos, vendas...)
    Net.luau         Remotes com rate limit e respostas padrão
    Main.server.luau inicia tudo
  client/            (StarterPlayerScripts.Client)
    UI/              telas (montadas por código, mobile-first)
    Controllers/     estações do mapa, voo, arco-íris
    Main.client.luau inicia tudo
Packages/
  ProfileStore.luau  biblioteca de dados (session locking, autosave)
```

## Balanceamento: onde mexer

| O quê | Arquivo |
|---|---|
| Ingredientes (preço, raridade, atributos) | [src/shared/Config/Ingredients.luau](src/shared/Config/Ingredients.luau) |
| Raridades e tempo de preparo extra | [src/shared/Config/Rarities.luau](src/shared/Config/Rarities.luau) |
| Traços (gigante, voar, brilho...) e intensidade | [src/shared/Config/Traits.luau](src/shared/Config/Traits.luau) |
| Moedas iniciais, durações, multiplicadores | [src/shared/Config/Economy.luau](src/shared/Config/Economy.luau) |
| Melhorias e preços | [src/shared/Config/Upgrades.luau](src/shared/Config/Upgrades.luau) |
| Limite de chamadas por segundo (anti-exploit) | [src/shared/Config/Remotes.luau](src/shared/Config/Remotes.luau) |
| Receitas especiais | [src/server/Config/Recipes.luau](src/server/Config/Recipes.luau) |
| Palavras do gerador de nomes | [src/server/Config/NameParts.luau](src/server/Config/NameParts.luau) |
| Mutações (chance, preço, efeito extra) | [src/shared/Config/Mutations.luau](src/shared/Config/Mutations.luau) |
| Clima (eventos, duração, visual do céu) | [src/shared/Config/Weather.luau](src/shared/Config/Weather.luau) |
| Cometa (intervalo, itens, barra de energia) | [src/shared/Config/Comet.luau](src/shared/Config/Comet.luau) |
| Receitas secretas da semana e dicas | [src/server/Config/SecretRecipes.luau](src/server/Config/SecretRecipes.luau) |
| Atalhos de teste no Studio | [src/shared/Config/Debug.luau](src/shared/Config/Debug.luau) |
| Loja (clientes NPC, pedidos, venda offline) | [src/shared/Config/Shop.luau](src/shared/Config/Shop.luau) |
| Amigos, respingo, troca, Caldeirão da Amizade | [src/shared/Config/Social.luau](src/shared/Config/Social.luau) |
| Missões diárias | [src/shared/Config/Missions.luau](src/shared/Config/Missions.luau) |
| Recompensa diária (sequência) | [src/shared/Config/Daily.luau](src/shared/Config/Daily.luau) |
| Novo Mestre (rebirth) | [src/shared/Config/Rebirth.luau](src/shared/Config/Rebirth.luau) |
| Game Passes, Developer Products e cosméticos | [src/shared/Config/Monetization.luau](src/shared/Config/Monetization.luau) |

## Configurando a monetização

1. Em [create.roblox.com](https://create.roblox.com), abra o jogo e vá em **Monetização**.
2. Crie os **Passes** e os **Developer Products**, defina os preços e copie cada ID para o campo `id` em `Monetization.luau`.
3. Itens com `id = 0` aparecem como "Em breve" e não podem ser comprados.
4. No Studio, compras com IDs reais são **de teste** (não cobram Robux).
5. Para testar os passes sem configurar IDs, use o painel DEBUG.

Nenhum item pago compra Descoberta Mundial, posição no ranking ou vantagem em troca e respingo.

## Tamanho do servidor

O mapa tem **6 terrenos de loja**. Em **Game Settings → Places → Server Size**, use 6 (ou aumente `Shop.plotCount` e as posições em `ShopService.luau`).

## Testando no Studio

- Durante o **Play** aparece o botão vermelho **DEBUG** no canto inferior esquerdo. Ele força clima e cometa, dá moedas e ingredientes, termina os preparos e força a mutação da próxima poção.
- No Studio, os tempos de clima e cometa ficam 4x mais curtos (`Debug.studioTimeScale`).
- Para testar com os tempos reais, mude `fastTimersInStudio` para `false`. O painel de debug nunca existe em servidores reais.
- A **Descoberta Mundial**, o **ranking** e o anúncio entre servidores dependem do **API Services** ligado. Sem ele, as receitas ficam como "Registrando…" no Grimório e são registradas na próxima vez que o jogador entrar num servidor com acesso.

## Riscos conhecidos

- **P1: troca não é durável se o servidor cair.** A troca move os itens na memória e depois salva os dois perfis em duas gravações separadas. Se o servidor cair *de repente* (crash) entre as duas gravações, um item pode duplicar ou sumir.
  - Um desligamento normal e as falhas temporárias do DataStore **não** causam isso: o ProfileStore tenta de novo e salva tudo ao fechar.
  - **Decisão atual:** risco aceito. **Reavaliar antes de liberar as trocas ao público.** Para desligar as trocas, use `tradingEnabled = false` em [src/shared/Config/Social.luau](src/shared/Config/Social.luau).

## Como adicionar um ingrediente

1. Em `Ingredients.luau`, copie um bloco e troque o `id`. O `id` fica em inglês, é único e **nunca muda depois de lançado**.
2. Preencha `name`, `rarity`, `color`, `price`, `sellValue` e `unlockPrice` (use `0` para já começar liberado).
3. Em `traits`, coloque os atributos e seus pesos, por exemplo `{ Fly = 2, Glow = 1 }`. Os ids válidos estão em `Traits.luau`.
4. (Opcional) Para traduzir, adicione `["ingredient.SeuId"] = "English name"` em `Locale/en.luau`.

## Como adicionar uma receita especial

Em `src/server/Config/Recipes.luau`:

```lua
recipe({ "Feather", "Pepper", "Cloud" }, {
	name = "Poção do Galo Foguete",
	movement = "Fly",
	visual = "Fire",
})
```

- A ordem dos ingredientes não importa.
- Ingredientes repetidos valem (`{ "Mushroom", "Mushroom" }`).
- Se um id estiver errado, o servidor avisa no Output ao iniciar.

Toda combinação **sem** receita especial vira uma poção **procedural**. Os atributos dos ingredientes são somados e, em cada categoria (tamanho, forma, movimento, visual), vence o traço mais forte. O nome é sorteado com uma semente fixa (o hash da receita), então a mesma combinação gera sempre a mesma poção em qualquer servidor.

## Comandos úteis

```sh
stylua src                       # formata
selene src                       # lint
rojo sourcemap default.project.json -o sourcemap.json
luau-lsp analyze --platform=roblox --sourcemap=sourcemap.json --definitions=<globalTypes.d.luau> --ignore="Packages/**" src
```

O arquivo de definições para o `luau-lsp` está em
`https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau`.
A extensão **Luau Language Server** do VS Code baixa esse arquivo sozinha.
