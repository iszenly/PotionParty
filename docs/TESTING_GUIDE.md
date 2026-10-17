# Guia de testes (para iniciantes)

> Revisão: 2026-10-17, commit `cf72d51`. Os nomes de menus são os do Roblox Studio usado nos testes de outubro de 2026. Se um menu não estiver onde o guia diz, use a **busca do Studio** (o campo de pesquisa ou a lupa no topo da janela) e digite o nome da ferramenta.

## Sumário
- [Antes de qualquer teste](#antes-de-qualquer-teste)
- [Como saber em qual experiência você está](#como-saber-em-qual-experiência-você-está)
- [Como abrir o [TEST] no Studio](#como-abrir-o-test-no-studio)
- [Janela Output e Command Bar](#janela-output-e-command-bar)
- [API Services (DataStore no Studio)](#api-services-datastore-no-studio)
- [Ambiente A: Studio / Play](#ambiente-a-studio--play)
- [Ambiente B: Studio / Server & Clients](#ambiente-b-studio--server--clients)
- [Ambiente C: emulador de dispositivos](#ambiente-c-emulador-de-dispositivos)
- [Ambiente D: [TEST] publicado](#ambiente-d-test-publicado)
- [Ambiente E: experiência oficial](#ambiente-e-experiência-oficial)
- [Painel DEBUG](#painel-debug)
- [Compras de teste](#compras-de-teste)
- [Avisos do Output que podem ser ignorados](#avisos-do-output-que-podem-ser-ignorados)
- [Como relatar um problema](#como-relatar-um-problema)

## Antes de qualquer teste
1. Rode `rojo serve` na pasta do projeto ([DEVELOPMENT_SETUP.md](DEVELOPMENT_SETUP.md#4-sincronizar-com-o-studio)).
2. Abra o **[TEST]** no Studio e **confirme o GameId** (próxima seção).
3. Clique em **Plugins → Rojo → Connect** e espere aparecer **Connected**.
4. Se o Studio já estava em Play quando você mudou o código, aperte **Stop** e depois **Play**. Scripts só recarregam ao iniciar de novo.
5. Abra a janela **Output** antes de apertar Play.

## Como saber em qual experiência você está

| Experiência | Nome no Studio | GameId (universo) | PlaceId (lugar inicial) | Pode testar? |
|---|---|---|---|---|
| Potion Party **[TEST]** | Festa de Poções [TESTE] | `10771365236` | `122266248638560` | **Sim** |
| Experiência **oficial** | Festa de Poções | `10771336495` | `132178473915484` | Só testes de leitura, sem API Services |

- **GameId** é o id do **universo** (a experiência inteira, com as DataStores dela). É ele que o painel DEBUG confere (`Debug.testGameIds` em [Debug.luau](../src/shared/Config/Debug.luau)).
- **PlaceId** é o id de um **lugar** dentro do universo. Uma experiência pode ter vários lugares.
- Os ids da tabela foram observados na Command Bar e no MCP do Studio em 2026-10-16 e 2026-10-17. O GameId do [TEST] é o que está em `Debug.testGameIds`.

**Para conferir:**
1. Abra **View → Command Bar**. Aparece uma barra de texto embaixo da tela.
2. Cole `print(game.Name, game.PlaceId, game.GameId)` e aperte **Enter**.
3. Veja o resultado no **Output**. O último número é o GameId.

## Como abrir o [TEST] no Studio
1. No navegador, abra https://create.roblox.com/dashboard/creations/experiences/10771365236/overview
2. Clique em **Edit in Studio**. O Studio abre uma janela com o lugar do [TEST].
3. Confira o GameId (seção anterior). Se aparecer `10771336495`, você está na **oficial**: feche a janela.
4. O lugar pode parecer vazio: o mapa é criado pelo código ao dar Play.

A página da oficial é https://create.roblox.com/dashboard/creations/experiences/10771336495/overview. Abra-a só quando precisar.

## Janela Output e Command Bar
- **Output:** **View → Output**. Mostra as mensagens do jogo:
  - linhas brancas são informação;
  - **amarelas** são avisos;
  - **vermelhas** são erros.
  - Cada linha indica a origem: **Servidor**, **Cliente** ou **Studio**.
  - Para copiar: selecione as linhas, clique com o botão direito e escolha **Copy**.
- **Command Bar:** **View → Command Bar**. Roda uma linha de código no Studio.
  - **Use só para conferir informações**, como `print(game.GameId)`.
  - Não rode comandos que alterem dados.

## API Services (DataStore no Studio)
- **Sem API Services:** o jogo funciona, mas **nada é salvo** entre um Play e outro. O Output mostra `[ProfileStore]: Roblox API services unavailable - data will not be saved`.
- **Com API Services:** os dados são salvos na DataStore **daquela experiência**. O Output mostra `Roblox API services available - data will be saved`.
- **Para ligar (só no [TEST]):** **Home → Game Settings → Security → Enable Studio Access to API Services → Save**.
- **Na experiência oficial:** deixe **desligado**. Se for abrir a oficial só para olhar algo, confira antes em Game Settings → Security.

## Ambiente A: Studio / Play
**Para:** testes de um jogador só, gameplay e interface.
1. Aba **Test** (ou **Home**) → botão **Play**, ou a tecla **F5**.
2. Você controla um personagem. Os testes que salvam dados precisam do API Services ligado no [TEST].
3. Para parar: **Stop** (ou **Shift+F5**).
- Os tempos de clima e cometa ficam **4x mais curtos** no Studio (`Debug.studioTimeScale`).

## Ambiente B: Studio / Server & Clients
**Para:** testes com 2 ou mais jogadores simulados (troca, respingo, Caldeirão da Amizade, lista de jogadores). **Não precisa de outra conta Roblox.**
1. Aba **Test** → grupo **Clients and Servers**. Escolha o número de jogadores (ex.: **2 Players**) e clique em **Start**.
2. Abrem várias janelas: **Server** e uma por jogador (**Player1**, **Player2**…). Cada janela tem o próprio Output.
3. Para mover um jogador, clique na janela dele.
4. Para encerrar, clique em **Cleanup** (ou **Stop**) na janela do servidor.

**Limitações deste ambiente:**
- **Os jogadores de teste têm UserId negativo** (`-1`, `-2`…). Os perfis deles são salvos no [TEST] e reaproveitados nos próximos testes.
- **Eles não são amigos do Roblox entre si:** o bônus de amigos e o bônus de sorte do Caldeirão da Amizade não podem ser testados aqui (P23).
- **Tudo roda num único servidor:** a descoberta mundial entre servidores **não** é testada aqui.

## Ambiente C: emulador de dispositivos
**Para:** ver a interface em telas de celular e tablet (testes T28).
1. Aba **Test** → **Device**. Se não achar, procure "Device Emulator" na busca do Studio.
2. No topo da área do jogo aparece uma lista de dispositivos. Escolha, por exemplo, **iPhone SE**, **iPhone 14** ou **iPad**, e gire para **paisagem**.
3. Dê **Play** e use o mouse como se fosse o dedo.
- O emulador **não** substitui um celular de verdade (desempenho, toque real), mas mostra cortes e sobreposições.

## Ambiente D: [TEST] publicado
**Para:** testes com servidores reais (descoberta mundial entre servidores, reconexão, sessão em dois servidores, contas reais).
1. Na janela do [TEST] no Studio, confira o GameId e use **File → Publish to Roblox**. Isso publica **só no [TEST]**.
2. Deixe o [TEST] **privado** no Creator Hub.
3. Entre pelo **aplicativo Roblox** ou pelo site: página do [TEST] → **Play**.
4. Para testes com 2 jogadores reais, é preciso **uma segunda conta Roblox**, com permissão para entrar numa experiência privada (no Creator Hub, **Collaborators** ou **Access**).
5. Para ver mensagens: no jogo, aperte **F9** para abrir o **Developer Console**. As abas mostram o Log do cliente e o do servidor (para quem tem permissão).

**Diferenças em relação ao Studio:**
- **O painel DEBUG não existe** no jogo publicado, nem no [TEST]: ele só aparece no Studio. Não procure por ele.
- Os tempos de clima e cometa são os **reais**: cometa a cada 10 min, clima de 3 a 5 min entre eventos.
- **Compras no jogo publicado gastam Robux de verdade.** Veja [Compras de teste](#compras-de-teste).

## Ambiente E: experiência oficial
- **Não use para:** testes destrutivos, simulação de moedas, passes falsos, dados de teste ou experimentos.
- O painel DEBUG **não** funciona lá (T30). Mesmo assim, deixe o API Services do Studio **desligado** nessa experiência.
- Só recebe publicação de versões aprovadas ([DEVELOPMENT_SETUP.md](DEVELOPMENT_SETUP.md#publicar-sem-errar-o-universo)).

## Painel DEBUG
- **Onde aparece:** **só no Studio, no [TEST]**, ou num lugar ainda não publicado. É o botão vermelho **DEBUG** no canto inferior esquerdo; tocar nele abre e fecha a lista.
- **Comandos:**
  - ⛈️ Tempestade, 🌕 Lua Cheia, ☀️ Céu limpo;
  - ☄️ Cometa agora;
  - 🪙 +5000, 💰 +100.000, 🧺 +10 de cada;
  - ⏩ Terminar preparos;
  - ✨ Próx.: Dourada, 🌈 Próx.: Arco-íris, ♾️ Próx.: Eterna;
  - 🎁 Diária de novo, 🎯 Novas missões, 🏪 Simular 2h offline;
  - 🎫 Pass: Auto-venda, Sorte VIP, Loja Maior, Caldeirão (liga e desliga).
- **Os comandos mexem nos dados salvos do perfil de teste** quando o API Services está ligado. É esperado no [TEST].
- No Output aparece `[PotionParty] modo DEBUG ativo (só no Studio)` quando o painel está disponível.

## Compras de teste
- **No Studio**, comprar um Pass ou Developer Product com **ID real** abre uma compra de **teste**, que **não cobra Robux**. É o jeito certo de testar o ProcessReceipt (T16 e T17).
- Hoje todos os IDs estão em `0`, então não há o que comprar ([SECURITY_AND_MONETIZATION.md](SECURITY_AND_MONETIZATION.md#game-passes-e-developer-products)).
- **No jogo publicado, as compras são reais.** Não faça compras com Robux reais sem necessidade e sem aprovação.

## Avisos do Output que podem ser ignorados
Estas mensagens apareceram nos testes de 2026-10-17 e **não vêm do código do Potion Party**:

| Mensagem | Origem |
|---|---|
| `[UIBlox - Warning] - FoundationProvider not found…` (com várias linhas `CorePackages…`) | Interface interna do Roblox (Cliente) |
| `ContentId: rbxassetid://203785492 failed due to: Asset type does not match requested type` | Studio (o id não existe no projeto) |
| `Disconnect from 127.0.0.1|…` | O Studio encerrando a simulação |

Um problema do jogo aparece em **vermelho** com o nome de um arquivo nosso. Por exemplo: `TradeService:123`.

## Como relatar um problema
Envie:
1. O **ID do teste** ([TEST_CASES.md](TEST_CASES.md)) e o número do passo.
2. O **ambiente** (A, B, C, D) e em qual janela aconteceu: Play, Server, Player1…
3. O **GameId** confirmado.
4. As linhas **vermelhas e amarelas** do Output, copiadas da janela Server e da janela do jogador.
5. Um **print** da tela, se for algo visual.
6. O que você esperava e o que aconteceu.

Depois, registre a execução em [TEST_RESULTS.md](TEST_RESULTS.md) usando o [modelo](TEST_RESULTS.md#modelo-de-registro-de-execução).
