# Casos de teste

> Revisão: 2026-10-17, commit `cf72d51`.
> - **T01 a T29** vêm da matriz da auditoria 4A e mantêm os mesmos ids.
> - **T30 a T43** cobrem as mudanças das Fases 4B.1 e 4B.2 e cenários que só podem ser verificados por revisão técnica.
> - Os resultados ficam em [TEST_RESULTS.md](TEST_RESULTS.md); este arquivo descreve **como** testar.
> - Ambientes A a E: [TESTING_GUIDE.md](TESTING_GUIDE.md). Sempre confirme o GameId `10771365236` ([TEST]) antes de testes que salvam dados.

## Sumário
| ID | Nome | Ambiente |
|---|---|---|
| [T01](#t01--persistência-ao-sair-e-voltar) | Persistência ao sair e voltar | A + API |
| [T02](#t02--troca-rápida-de-servidor-session-lock) | Troca rápida de servidor (session lock) | D |
| [T03](#t03--migração-v1--v2) | Migração v1 → v2 | Revisão técnica |
| [T04](#t04--salvamento-ao-desligar) | Salvamento ao desligar | A + API / D |
| [T05](#t05--determinismo-das-receitas) | Determinismo das receitas | A, D |
| [T06](#t06--ingredientes-repetidos-e-consumo) | Ingredientes repetidos e consumo | A |
| [T07](#t07--ciclo-completo-da-poção) | Ciclo completo da poção | A |
| [T08](#t08--efeito-ao-morrer) | Efeito ao morrer | A |
| [T09](#t09--troca-normal) | Troca normal | B |
| [T10](#t10--troca-mudança-de-oferta) | Troca: mudança de oferta | B |
| [T11](#t11--troca-item-oferecido-some) | Troca: item oferecido some | B |
| [T12](#t12--troca-desconexão) | Troca: desconexão | B |
| [T13](#t13--troca-prateleira-cheia) | Troca: prateleira cheia | B |
| [T14](#t14--descoberta-mundial-concorrente) | Descoberta mundial concorrente | D (2 contas) |
| [T15](#t15--descoberta-sem-api-services) | Descoberta sem API Services | A |
| [T16](#t16--recibo-idempotente) | Recibo idempotente | A (IDs reais) |
| [T17](#t17--recibo-com-fechamento-imediato) | Recibo com fechamento imediato | A (IDs reais) |
| [T18](#t18--respingo-básico) | Respingo básico | B |
| [T19](#t19--escudo-e-zonas-seguras) | Escudo e zonas seguras | B |
| [T20](#t20--intervalo-e-alcance-do-respingo) | Intervalo e alcance do respingo | B |
| [T21](#t21--pedidos-da-loja) | Pedidos da loja | A |
| [T22](#t22--venda-offline-sem-pagamento-duplo) | Venda offline sem pagamento duplo | A + API |
| [T23](#t23--cometa-barra-de-energia-coletiva) | Cometa: barra de energia coletiva | B |
| [T24](#t24--clima-e-mutação) | Clima e mutação | A |
| [T25](#t25--diária-e-missões) | Diária e missões | A |
| [T26](#t26--novo-mestre) | Novo Mestre | A |
| [T27](#t27--spam-de-remotes) | Spam de Remotes | Revisão técnica / MCP |
| [T28](#t28--celular-e-resoluções) | Celular e resoluções | C |
| [T29](#t29--regressão) | Regressão | Ferramentas + A/B |
| [T30](#t30--debug-só-no-test) | DEBUG só no [TEST] | A (duas experiências) |
| [T31](#t31--cometa-coleta-com-distância-válida) | Cometa: coleta com distância válida | A |
| [T32](#t32--imunidade-de-respingo-10-s) | Imunidade de respingo (10 s) | B |
| [T33](#t33--caldeirão-extra-que-sumiu-p18) | Caldeirão extra que sumiu (P18) | A |
| [T34](#t34--caldeirão-da-amizade) | Caldeirão da Amizade | B |
| [T35](#t35--interruptor-de-trocas) | Interruptor de trocas | B |
| [T36](#t36--visitar-loja) | Visitar loja | B |
| [T37](#t37--lista-de-jogadores-sem-duplicar) | Lista de jogadores sem duplicar | B (3) |
| [T38](#t38--cores-dos-avisos) | Cores dos avisos | A / B |
| [T39](#t39--listas-com-rolagem-sem-corte) | Listas com rolagem sem corte | A |
| [T40](#t40--descoberta-fluxo-normal) | Descoberta: fluxo normal | A + API |
| [T41](#t41--inicialização-sem-erros) | Inicialização sem erros | A |
| [T42](#t42--p9-registro-repetido-sem-anúncio) | P9: registro repetido sem anúncio | Revisão técnica |
| [T43](#t43--p3-queda-do-servidor) | P3: queda do servidor | Revisão técnica |

**Campos de cada caso:**
- **Objetivo**
- **Arquivos**
- **Ambiente**
- **Pré-requisitos**
- **Jogadores / contas**
- **Passos**
- **Esperado**
- **Evidência** (o que coletar)
- **Limitações**
- **Aprovação**: critério para considerar o teste aprovado

---

### T01 — Persistência ao sair e voltar
- **Objetivo:** confirmar que moedas, poções, ingredientes, melhorias e Grimório continuam iguais depois de sair e voltar.
- **Arquivos:** [DataService.luau](../src/server/Services/DataService.luau)
- **Ambiente:** A (Play) no [TEST] com API Services ligado.
- **Pré-requisitos:** Output mostrando `data will be saved`.
- **Jogadores / contas:** 1 / sua conta.
- **Passos:**
  1. Dê Play.
  2. Anote as moedas e a quantidade de 2 ingredientes.
  3. Prepare e colete 1 poção, compre 1 melhoria e venda 1 poção. Anote os valores novos.
  4. Clique em **Stop**.
  5. Dê **Play** de novo.
  6. Confira moedas, ingredientes, poções (🧪), melhorias (⬆️) e Grimório (📖).
- **Esperado:** tudo igual ao anotado no passo 3.
- **Evidência:** os valores anotados antes e depois, e as linhas do Output.
- **Limitações:** no Studio, Stop e Play no mesmo computador. Não testa outro servidor (veja T02).
- **Aprovação:** todos os valores iguais e nenhum erro vermelho.

### T02 — Troca rápida de servidor (session lock)
- **Objetivo:** ao sair de um servidor e entrar logo em outro, os dados carregados são os mais recentes.
- **Arquivos:** [DataService.luau](../src/server/Services/DataService.luau), [ProfileStore.luau](../Packages/ProfileStore.luau)
- **Ambiente:** D ([TEST] publicado).
- **Pré-requisitos:** [TEST] publicado e privado; 2 servidores abertos (por exemplo, outra conta mantendo um deles aberto).
- **Jogadores / contas:** 1 jogador testado; uma 2ª conta ajuda a manter servidores abertos.
- **Passos:**
  1. Entre, ganhe moedas (venda poções) e anote o total.
  2. Saia e, em seguida, entre de novo, preferindo cair num servidor diferente.
  3. Confira as moedas.
- **Esperado:** as moedas são as anotadas. Pode haver alguns segundos de "carregando" enquanto a trava da sessão anterior é liberada. Nunca deve aparecer um valor antigo.
- **Evidência:** valores e o horário de cada entrada.
- **Limitações:** não dá para escolher o servidor; o Roblox pode colocar você no mesmo.
- **Aprovação:** nenhum retrocesso de dados em 3 tentativas.

### T03 — Migração v1 → v2
- **Objetivo:** um perfil antigo com `discovered` numérico é convertido sem erro.
- **Arquivos:** `migrate` em [DataService.luau](../src/server/Services/DataService.luau)
- **Ambiente:** revisão técnica ou instrumentação. Exige criar um perfil no formato v1 numa DataStore de teste.
- **Pré-requisitos:** uma ferramenta para gravar um perfil v1 no [TEST]. Não existe no projeto.
- **Jogadores / contas:** 1.
- **Passos:**
  1. Gravar um perfil v1 no [TEST] (por exemplo, com uma ferramenta de DataStore).
  2. Entrar.
  3. Abrir o Grimório.
- **Esperado:** as receitas aparecem e o Output não mostra erro.
- **Evidência:** o Output e o Grimório.
- **Limitações:** **nunca** fazer na experiência oficial.
- **Aprovação:** conversão confirmada.

### T04 — Salvamento ao desligar
- **Objetivo:** dados salvos quando o servidor fecha.
- **Arquivos:** `BindToClose` dentro de [ProfileStore.luau](../Packages/ProfileStore.luau)
- **Ambiente:** A no [TEST] com API, ou D (Creator Hub → servidores → desligar).
- **Jogadores / contas:** 1.
- **Passos:**
  1. Ganhe moedas e anote o total.
  2. **A:** clique em Stop logo em seguida, sem sair do personagem antes. **D:** desligue os servidores pelo Creator Hub.
  3. Entre de novo e confira.
- **Esperado:** as moedas anotadas.
- **Evidência:** valores anotados e Output.
- **Aprovação:** valores iguais.

### T05 — Determinismo das receitas
- **Objetivo:** a mesma combinação gera sempre o mesmo nome e efeito, em qualquer ordem e em qualquer servidor.
- **Arquivos:** [RecipeService.luau](../src/server/Services/RecipeService.luau), [RecipeKey.luau](../src/shared/Util/RecipeKey.luau), [Hash.luau](../src/shared/Util/Hash.luau)
- **Ambiente:** A (ordem) e D (dois servidores).
- **Jogadores / contas:** 1.
- **Passos:**
  1. Prepare **Pimenta + Gelo + Pedra** e anote o nome e os efeitos.
  2. Prepare **Pedra + Pimenta + Gelo** (ordem diferente).
  3. Repita em outro servidor (D) ou depois de Stop e Play (A).
- **Esperado:** nome e efeitos idênticos em todas as vezes.
- **Evidência:** prints da revelação.
- **Aprovação:** tudo idêntico.

### T06 — Ingredientes repetidos e consumo
- **Objetivo:** receitas com ingrediente repetido funcionam e gastam a quantidade certa.
- **Arquivos:** [CauldronService.luau](../src/server/Services/CauldronService.luau), [IngredientService.luau](../src/server/Services/IngredientService.luau)
- **Ambiente:** A.
- **Jogadores / contas:** 1.
- **Passos:**
  1. Anote quantos Cogumelos você tem (o caldeirão mostra "xN").
  2. Coloque Cogumelo + Cogumelo e prepare.
  3. Confira o novo número.
  4. Gaste os Cogumelos até sobrar 1 e tente colocar 2 no caldeirão.
- **Esperado:** no passo 3, o número diminui 2 e a poção é "Poção do Cogumelo Gigantesco". No passo 4, a interface não deixa colocar o 2º (o bloco fica cinza, "x0").
- **Evidência:** prints.
- **Limitações:** a proteção do servidor contra pedidos falsos não é testável sem exploit (revisão técnica: `IngredientService.consume`).
- **Aprovação:** os dois resultados esperados.

### T07 — Ciclo completo da poção
- **Objetivo:** preparar, coletar, beber, ver o efeito acabar e vender.
- **Arquivos:** [CauldronService.luau](../src/server/Services/CauldronService.luau), [PotionService.luau](../src/server/Services/PotionService.luau), [EffectService.luau](../src/server/Services/EffectService.luau)
- **Ambiente:** A.
- **Jogadores / contas:** 1.
- **Passos:**
  1. No caldeirão, prepare **Pena + Mel**.
  2. Espere e toque em **Coletar!**
  3. Na revelação, toque em **Beber**.
  4. Observe o efeito (mini, voar, brilhar) e o contador no topo da tela.
  5. Espere o contador zerar.
  6. Prepare outra poção, vá até o Balcão de Vendas e venda 1.
- **Esperado:**
  - no passo 2 aparece a "Poção da Abelha Rainha";
  - no passo 5 o personagem volta **exatamente** ao normal (tamanho, cores, roupas);
  - no passo 6 as moedas sobem.
- **Evidência:** prints antes e depois do efeito, e o Output.
- **Aprovação:** todos os passos como esperado e sem erro vermelho.

### T08 — Efeito ao morrer
- **Objetivo:** morrer com efeito ativo não quebra o personagem.
- **Arquivos:** [EffectService.luau](../src/server/Services/EffectService.luau)
- **Ambiente:** A.
- **Jogadores / contas:** 1.
- **Passos:**
  1. Beba uma poção com Gigante (ex.: Cogumelo + Cogumelo).
  2. Aperte **Esc → Reset Character → Reset**.
  3. Espere renascer.
- **Esperado:** renasce com tamanho e aparência normais; o contador de efeito some; nenhum erro.
- **Evidência:** print e Output.
- **Aprovação:** como esperado.

### T09 — Troca normal
- **Objetivo:** dois jogadores trocam itens com sucesso.
- **Arquivos:** [TradeService.luau](../src/server/Services/TradeService.luau), [TradeUI.luau](../src/client/UI/TradeUI.luau)
- **Ambiente:** B (2 Players).
- **Pré-requisitos:** os dois com pelo menos 1 poção e 1 ingrediente. Se precisar, use DEBUG **🧺 +10 de cada** e prepare uma poção.
- **Jogadores / contas:** 2 simulados / nenhuma conta extra.
- **Passos:**
  1. Player1: **☰ Menu → 👥 Jogadores → 🤝 Trocar** (na linha do Player2).
  2. Player2: **Aceitar**.
  3. Cada um toca 1 poção e 1 ingrediente em **Seus itens**.
  4. Os dois tocam **Pronto!**, esperam a contagem e tocam **Confirmar**.
- **Esperado:** "Troca concluída! 🤝" nos dois, e os itens mudam de dono (confira em 🧪 Poções).
- **Evidência:** prints antes e depois.
- **Limitações:** UserIds negativos, normal no Studio.
- **Aprovação:** itens corretos nos dois inventários.

### T10 — Troca: mudança de oferta
- **Objetivo:** mudar a oferta desmarca o "Pronto" dos dois.
- **Ambiente:** B (2 Players).
- **Passos:**
  1. Faça os passos 1 a 3 do T09.
  2. Os dois tocam **Pronto!**
  3. Antes de confirmar, o Player1 toca num item da **Sua oferta** para tirá-lo.
- **Esperado:** os dois voltam a "não pronto"; o botão Confirmar some.
- **Evidência:** print.
- **Aprovação:** como esperado.

### T11 — Troca: item oferecido some
- **Objetivo:** a troca é cancelada se um item oferecido sair do inventário.
- **Ambiente:** B (2 Players).
- **Passos:**
  1. Player1 oferece uma poção.
  2. Player1 abre **🧪 Poções** pelo HUD e **bebe** essa poção.
- **Esperado:** em até ~1 s os dois veem "Troca cancelada: um item oferecido mudou".
- **Evidência:** print e Output.
- **Aprovação:** cancelada e nenhum item duplicado.

### T12 — Troca: desconexão
- **Objetivo:** se um jogador sair, a troca é cancelada sem perda de itens.
- **Ambiente:** B (2 Players).
- **Passos:**
  1. Abra uma troca com ofertas dos dois lados.
  2. Feche a janela do **Player2**.
- **Esperado:** Player1 vê "Troca cancelada: o outro jogador saiu", e os itens do Player1 continuam com ele.
- **Limitações:** não está confirmado se fechar a janela de um cliente remove o jogador nesta versão do Studio. Se não remover, registre como Bloqueado e use o ambiente D.
- **Aprovação:** como esperado.

### T13 — Troca: prateleira cheia
- **Objetivo:** a troca é recusada se quem recebe não tiver espaço.
- **Ambiente:** B (2 Players).
- **Pré-requisitos:** Player2 com a prateleira cheia (20 poções sem melhorias; use DEBUG para ingredientes e ⏩ para acelerar).
- **Passos:** Player1 oferece 1 poção, Player2 não oferece poção, e os dois confirmam.
- **Esperado:** "Troca cancelada: não cabe na prateleira de alguém"; nada é trocado.
- **Aprovação:** como esperado.

### T14 — Descoberta mundial concorrente
- **Objetivo:** duas pessoas criando a mesma receita nova em servidores diferentes resultam em um único "1º do mundo".
- **Arquivos:** [DiscoveryService.luau](../src/server/Services/DiscoveryService.luau)
- **Ambiente:** D, com **2 contas em 2 servidores diferentes**.
- **Passos:**
  1. Combinem uma receita que ninguém fez.
  2. Preparem e coletem quase ao mesmo tempo.
- **Esperado:** só um vê "Você foi o 1º do mundo!"; o outro vê "1º do mundo: <nome do primeiro>". O banner sai uma vez em cada servidor.
- **Limitações:** coordenar o mesmo segundo é difícil. A atomicidade do `UpdateAsync` é garantida pelo Roblox (revisão técnica).
- **Aprovação:** um único dono.

### T15 — Descoberta sem API Services
- **Objetivo:** sem API Services, nada quebra.
- **Ambiente:** A no [TEST] com API Services **desligado**.
- **Passos:**
  1. Desligue o API Services.
  2. Dê Play e crie uma receita nova.
- **Esperado:** a revelação mostra "Registrando no Grimório Mundial…"; o Output mostra só avisos de DataStore indisponível, sem erros vermelhos do jogo.
- **Limitações:** sem API nada é salvo, então a parte "registrar no próximo login" não pode ser verificada aqui.
- **Aprovação:** sem erros e com a mensagem de "Registrando".

### T16 — Recibo idempotente
- **Objetivo:** cada compra é entregue exatamente uma vez.
- **Arquivos:** [MonetizationService.luau](../src/server/Services/MonetizationService.luau)
- **Ambiente:** A no [TEST], com **IDs reais configurados**. A compra é de teste e não cobra Robux.
- **Pré-requisitos:** produtos criados no [TEST] e IDs em [Monetization.luau](../src/shared/Config/Monetization.luau). Hoje está **Bloqueado**.
- **Passos:**
  1. Anote os ingredientes.
  2. Na **💎 Loja VIP**, compre o Pacote de Ingredientes.
  3. Confira os ingredientes.
  4. Stop, Play e confira de novo.
- **Esperado:** +3 de Raio, Nuvem, Bolha e Pizza **uma vez**; nada a mais ao voltar.
- **Aprovação:** como esperado.

### T17 — Recibo com fechamento imediato
- **Objetivo:** fechar o jogo logo depois de comprar não perde nem duplica a compra.
- **Ambiente:** A no [TEST], com IDs reais (hoje Bloqueado).
- **Passos:**
  1. Compre um pacote e clique em **Stop** em menos de 2 s.
  2. Dê Play e confira.
- **Esperado:** o pacote entregue **uma** vez, já ou no próximo Play.
- **Aprovação:** nem perda nem duplicação em 3 tentativas.

### T18 — Respingo básico
- **Objetivo:** jogar uma poção transforma o outro jogador por 8 s, e só ele.
- **Arquivos:** [SplashService.luau](../src/server/Services/SplashService.luau)
- **Ambiente:** B (2 Players).
- **Passos:**
  1. Player1 com poções.
  2. Leve os dois para **fora do chão verde** (atrás do spawn, onde o cometa cai), perto um do outro.
  3. Player1: **🧪 Poções → 💦 Jogar**.
- **Esperado:** Player2 se transforma e vê "💦 Player1 te acertou com um respingo!"; Player1 não é afetado; o efeito some em ~8 s.
- **Aprovação:** como esperado.

### T19 — Escudo e zonas seguras
- **Objetivo:** proteções contra respingo.
- **Ambiente:** B (2 Players).
- **Passos:**
  1. **Escudo:** Player2 vai em **☰ Menu → ⚙️ Ajustes → Modo Escudo → Ligado**. Player1 joga nele fora do lobby.
  2. **Alvo na zona segura:** Player2 desliga o escudo e fica **dentro** do chão verde. Player1, de fora (na beira), joga nele.
  3. **Lançar de dentro:** Player1 entra no chão verde e tenta jogar.
- **Esperado:**
  - passos 1 e 2: Player1 vê "🛡️ Player2 está protegido!" (cor neutra), e Player2 não é afetado;
  - passo 3: "Respingos não funcionam na zona segura!", em vermelho.
- **Aprovação:** os três casos.

### T20 — Intervalo e alcance do respingo
- **Ambiente:** B (2 Players).
- **Passos:**
  1. Player1 joga duas vezes seguidas, a menos de 2 s.
  2. Afaste os jogadores para mais de 46 studs (bem longe) e jogue.
- **Esperado:** no passo 1, a 2ª jogada recusa com "Espere um pouquinho para jogar de novo." No passo 2, com o outro fora do alcance, o frasco cai à frente sem acertar ninguém.
- **Limitações:** a mira automática só procura alvos dentro de 40 studs.
- **Aprovação:** como esperado.

### T21 — Pedidos da loja
- **Arquivos:** [ShopService.luau](../src/server/Services/ShopService.luau), [ShopUI.luau](../src/client/UI/ShopUI.luau)
- **Ambiente:** A.
- **Passos:**
  1. **☰ Menu → 🏪 Minha Loja → 🏠 Ir para minha loja**.
  2. Espere ~20 s até chegar um cliente.
  3. Entregue uma poção que sirva (botão "Entregar").
  4. Tente entregar de longe (saia da loja e use a fichinha 🛎️ do HUD).
- **Esperado:** no passo 3, moedas = preço × multiplicador do pedido, o cliente sai 😊 e o contador "atendidos" sobe. No passo 4, "Vá até o balcão da sua loja!"
- **Aprovação:** como esperado.

### T22 — Venda offline sem pagamento duplo
- **Objetivo:** a venda offline paga uma única vez.
- **Arquivos:** [ShopService.luau](../src/server/Services/ShopService.luau), [DataService.luau](../src/server/Services/DataService.luau)
- **Ambiente:** A no [TEST] com API Services.
- **Pré-requisitos:** 3 ou mais poções comuns, sem mutação.
- **Passos:**
  1. DEBUG → **🏪 Simular 2h offline**. Em ~6 s aparece o banner da venda offline.
  2. Stop e Play na hora.
  3. Stop, **espere 6 minutos** e dê Play.
  4. Stop e Play na hora.
- **Esperado:**
  - passo 1: banner, moedas sobem e poções diminuem;
  - passo 2: **nenhum** banner;
  - passo 3: banner com **1** poção;
  - passo 4: **nenhum** banner.
- **Limitações:** não cobre queda do servidor (T43).
- **Aprovação:** como esperado.

### T23 — Cometa: barra de energia coletiva
- **Arquivos:** [CometService.luau](../src/server/Services/CometService.luau)
- **Ambiente:** B (2 Players).
- **Passos:**
  1. DEBUG → **☄️ Cometa agora**.
  2. Depois da queda, os dois usam o prompt **Carregar energia** do núcleo várias vezes, pelo menos 3 cada, até encher (energia = 20 + 15 × 2 = 50).
- **Esperado:** banner "Energia cheia!" e cada um recebe 1 Poeira de Cometa (confira no Mercado ou no caldeirão).
- **Aprovação:** os dois recebem.

### T24 — Clima e mutação
- **Arquivos:** [WeatherService.luau](../src/server/Services/WeatherService.luau), [MutationService.luau](../src/server/Services/MutationService.luau)
- **Ambiente:** A.
- **Passos:**
  1. DEBUG → **⛈️ Tempestade**.
  2. Prepare e colete ~8 poções (⏩ acelera).
- **Esperado:** céu escuro, chuva e banner; cerca de 1 em cada 4 poções sai **Eletrificada**.
- **Limitações:** é sorte; com 8 poções, ver de 0 a 4 Eletrificadas é normal.
- **Aprovação:** pelo menos 1 Eletrificada em até 12 coletas, e nenhuma Eletrificada com céu limpo.

### T25 — Diária e missões
- **Arquivos:** [MissionService.luau](../src/server/Services/MissionService.luau)
- **Ambiente:** A.
- **Passos:**
  1. Pegue a Diária (abre sozinha ou **☰ Menu → 🎁 Diária**).
  2. Tente pegar de novo.
  3. DEBUG → **🎁 Diária de novo** e pegue.
  4. Abra **🎯 Missões**, complete uma e toque em **Pegar!**
- **Esperado:**
  - passo 2: "Você já pegou essa recompensa!";
  - passo 3: a sequência avança para o dia 2;
  - passo 4: as moedas da missão são somadas.
- **Aprovação:** como esperado.

### T26 — Novo Mestre
- **Arquivos:** [RebirthService.luau](../src/server/Services/RebirthService.luau)
- **Ambiente:** A.
- **Passos:**
  1. DEBUG → **💰 +100.000**.
  2. Deixe um preparo em andamento e tente **🧙 Renascer**, tocando duas vezes.
  3. Colete tudo e tente de novo.
- **Esperado:**
  - passo 2: "Esvazie seus caldeirões…";
  - passo 3: moedas = 100, melhorias zeradas, receitas e poções mantidas, multiplicador x1.5.
- **Aprovação:** como esperado.

### T27 — Spam de Remotes
- **Objetivo:** chamadas acima do limite são recusadas e o servidor continua estável.
- **Ambiente:** revisão técnica, ou execução por desenvolvedor ou IA via MCP (`execute_luau` no Client do [TEST]). **Não recomendado para iniciante.**
- **Passos:** chamar um Remote (ex.: `GetRanking`) 20 vezes seguidas pelo cliente.
- **Esperado:** depois do limite (2 rápidas e depois 0,2/s), respostas `error.rateLimited`, sem erros no servidor.
- **Aprovação:** como esperado.

### T28 — Celular e resoluções
- **Objetivo:** nada cortado nem sobreposto ao direcional e ao botão de pulo.
- **Ambiente:** C (emulador).
- **Passos:**
  1. Para cada dispositivo (**iPhone SE**, **iPhone 14**, **iPad**, um Android médio), em **paisagem**:
     - dê Play;
     - abra cada janela: Caldeirão, Poções, Mercado, Melhorias, Grimório, Menu e as janelas dele.
  2. Observe o HUD com 4 ou mais fichinhas visíveis.
- **Esperado:** textos legíveis; botões dentro da tela; nada sobre o direcional (esquerda embaixo) nem o botão de pulo (direita embaixo).
- **Evidência:** um print por dispositivo e por tela.
- **Limitações:** os problemas conhecidos P6 e P7 devem aparecer em telas pequenas.
- **Aprovação:** nenhum corte ou sobreposição.

### T29 — Regressão
- **Objetivo:** depois de qualquer mudança de código, confirmar que o principal continua funcionando.
- **Ambiente:** ferramentas (automatizável) + A/B (manual).
- **Passos:**
  1. Rode `stylua --check src`, `selene src`, `luau-lsp analyze` e `rojo build` ([DEVELOPMENT_SETUP.md](DEVELOPMENT_SETUP.md#5-verificações-de-qualidade)).
  2. Execute T41, T07, T09 e T18.
- **Esperado:** ferramentas sem erros e os 4 testes aprovados.
- **Aprovação:** tudo aprovado.

### T30 — DEBUG só no [TEST]
- **Objetivo:** o painel DEBUG aparece no [TEST] e não aparece na experiência oficial.
- **Arquivos:** [Debug.luau](../src/shared/Config/Debug.luau), [DebugService.luau](../src/server/Services/DebugService.luau)
- **Ambiente:** A, nas duas experiências.
- **Pré-requisitos:** na **oficial**, API Services **desligado**.
- **Passos:**
  1. No [TEST], dê Play.
  2. Na oficial, dê Play.
- **Esperado:**
  - passo 1: Output `modo DEBUG ativo` e botão **DEBUG** visível;
  - passo 2: Output `painel DEBUG desligado: GameId 10771336495…` e nenhum botão.
- **Aprovação:** como esperado.

### T31 — Cometa: coleta com distância válida
- **Objetivo:** pegar itens do Cometa andando continua funcionando depois da checagem de distância (P4).
- **Arquivos:** [CometService.luau](../src/server/Services/CometService.luau)
- **Ambiente:** A.
- **Passos:**
  1. DEBUG → **☄️ Cometa agora**.
  2. Depois da queda, ande e encoste em 3 ou 4 itens. Opcional: repita com o efeito Gigante.
- **Esperado:** "Você pegou …!" e o item some, em todos.
- **Limitações:** o bloqueio de toque falsificado (exploit) não é testável manualmente.
- **Aprovação:** todos coletados normalmente.

### T32 — Imunidade de respingo (10 s)
- **Arquivos:** [SplashService.luau](../src/server/Services/SplashService.luau)
- **Ambiente:** B (2 Players).
- **Passos:**
  1. Faça o T18.
  2. ~3 s depois, Player1 joga de novo.
  3. Durante a imunidade, Player2 bebe uma poção própria.
  4. Mais de 10 s depois do 1º acerto, Player1 joga de novo.
- **Esperado:**
  - passo 2: Player1 vê "⏳ Player2 acabou de levar um respingo…", e Player2 não muda;
  - passo 3: funciona;
  - passo 4: acerta.
- **Aprovação:** como esperado.

### T33 — Caldeirão extra que sumiu (P18)
- **Arquivos:** [PlayerStats.luau](../src/shared/Util/PlayerStats.luau), [CauldronService.luau](../src/server/Services/CauldronService.luau)
- **Ambiente:** A.
- **Passos:**
  1. DEBUG → **🎫 Pass: Caldeirão** (liga).
  2. Prepare uma poção na **última** aba do caldeirão.
  3. DEBUG → **🎫 Pass: Caldeirão** (desliga).
  4. Reabra o caldeirão.
  5. DEBUG → **⏩ Terminar preparos** e **Coletar!**
- **Esperado:** no passo 4 a aba continua com o preparo; no passo 5 a coleta funciona e a aba some.
- **Aprovação:** como esperado.

### T34 — Caldeirão da Amizade
- **Arquivos:** [FriendshipService.luau](../src/server/Services/FriendshipService.luau)
- **Ambiente:** B (2 Players).
- **Passos:**
  1. Cada jogador entra num lado do caldeirão rosa (atrás do caldeirão principal) pelo prompt.
  2. Cada um escolhe 2 ingredientes e toca **Pronto!**
  3. Repita, mas o Player2 **se afasta** (mais de 14 studs) antes de marcar Pronto.
- **Esperado:** no passo 2, **os dois** veem a revelação e cada um perde só os próprios 2 ingredientes. No passo 3, nada é preparado e ninguém perde ingredientes.
- **Evidência:** contagem de ingredientes antes e depois, nos dois.
- **Aprovação:** como esperado, com as contagens anotadas.

### T35 — Interruptor de trocas
- **Arquivos:** [Social.luau](../src/shared/Config/Social.luau), [SocialUI.luau](../src/client/UI/SocialUI.luau)
- **Ambiente:** B (2 Players).
- **Passos:**
  1. Mude `tradingEnabled` para `false` e salve.
  2. Inicie 2 Players e abra **Menu → Jogadores**.
  3. **Volte para `true`** e salve.
- **Esperado:** no passo 2 só aparece **Visitar**, sem **Trocar**.
- **Aprovação:** como esperado, e o arquivo de volta a `true`.

### T36 — Visitar loja
- **Ambiente:** B (2 Players).
- **Passos:** Player1: **Menu → Jogadores → 🏪 Visitar** (Player2).
- **Esperado:** Player1 é teleportado para a loja do Player2; Player2 vê "Player1 está visitando sua loja!"
- **Aprovação:** como esperado.

### T37 — Lista de jogadores sem duplicar
- **Ambiente:** B (**3 Players**).
- **Passos:** em Player1 e Player2, abra e feche **Menu → Jogadores** 5 vezes.
- **Esperado:** cada jogador aparece uma única vez.
- **Aprovação:** nenhuma duplicação.

### T38 — Cores dos avisos
- **Arquivos:** [Banner.luau](../src/client/UI/Banner.luau)
- **Ambiente:** A (e B para o respingo).
- **Passos:**
  1. Na sua loja, use **❤️ Curtir loja** na placa.
  2. Provoque um erro: por exemplo, tente vender longe do Balcão.
- **Esperado:** no passo 1, um aviso **neutro** (roxo claro); no passo 2, **vermelho**; mensagens de sucesso em verde.
- **Aprovação:** cores corretas.

### T39 — Listas com rolagem sem corte
- **Arquivos:** [Components.luau](../src/client/UI/Components.luau) (`UI.list`)
- **Ambiente:** A.
- **Passos:**
  1. Abra o painel **DEBUG** e role.
  2. Abra o **Mercado** e role.
  3. Abra **🧪 Poções** com várias poções.
  4. Abra o **📖 Grimório**.
- **Esperado:** as listas começam no topo do painel e chegam ao fim rolando, sem itens acima da área visível.
- **Aprovação:** como esperado.

### T40 — Descoberta: fluxo normal
- **Arquivos:** [DiscoveryService.luau](../src/server/Services/DiscoveryService.luau)
- **Ambiente:** A no [TEST] com API Services.
- **Passos:**
  1. Crie uma receita que você nunca fez.
  2. Stop, Play e abra o Grimório.
- **Esperado:** no passo 1, "Registrando…" vira "Você foi o 1º do mundo!" (ou o nome do primeiro), com o banner dourado **uma vez**. No passo 2, a receita está registrada e não aparece banner novo.
- **Aprovação:** como esperado.

### T41 — Inicialização sem erros
- **Ambiente:** A.
- **Passos:** dê Play com o Output aberto.
- **Esperado:** `[PotionParty] servidor iniciado`, `modo DEBUG ativo` (no [TEST]) e `Roblox API services available…` (com API), sem linhas vermelhas do jogo. Os avisos listados no [TESTING_GUIDE.md](TESTING_GUIDE.md#avisos-do-output-que-podem-ser-ignorados) podem ser ignorados.
- **Aprovação:** sem erros do jogo.

### T42 — P9: registro repetido sem anúncio
- **Objetivo:** quando o registro mundial já é do próprio jogador, não há novo anúncio.
- **Ambiente:** **revisão técnica**. Reproduzir exige que o `UpdateAsync` grave e o Grimório não seja salvo, o que não é controlável com segurança.
- **Verificação:** `claimAsync` retorna `wroteNow = false` quando `existing` já existe, e `processEntry` só chama `announceWorldFirst` se `wroteNow`.
- **Aprovação:** código conforme descrito (revisão).

### T43 — P3: queda do servidor
- **Objetivo:** depois de uma queda, a venda offline não paga de novo.
- **Ambiente:** **revisão técnica**, ou teste controlado num lugar descartável. Nunca no oficial.
- **Verificação:** em `DataService`, `lastLogout = os.time()` é atribuído antes de `loaded:Fire`, sem `yield` entre isso e `ShopService.offlineSales`; o `OnSave` também atualiza. Veja [DATA_AND_PERSISTENCE.md](DATA_AND_PERSISTENCE.md#lastlogout-e-a-venda-offline-correção-p3).
- **Aprovação:** revisão conforme; teste controlado opcional.
