# Decisões de produto e arquitetura

> Revisão: 2026-10-17, commit `cf72d51`.
> As datas seguem o relógio das sessões de desenvolvimento. As decisões de 2026-10-16 vieram das respostas do dono do projeto à auditoria 4A e ao plano da 4B.
>
> **Aprovada ≠ implementada ≠ proposta.** A coluna "Status" diz qual é o caso.

## Status possíveis
| Status | Significado |
|---|---|
| **Implementada** | Aprovada e presente no código (commit indicado). |
| **Aprovada, não implementada** | O dono aprovou, mas o código ainda não tem. |
| **Vigente** | Uma regra de processo ou um risco aceito em vigor. |
| **Proposta** | Ideia futura; precisa de uma proposta específica e de aprovação. |
| **Decisão técnica** | Escolha feita na implementação, comunicada ao dono, sem aprovação formal registrada. |

## Decisões de produto
| ID | Decisão | Data | Motivação | Consequência | Status |
|---|---|---|---|---|---|
| D01 | Ranking pelo **total de receitas no Grimório** | 2026-10-16 | Mais acessível para quem entra depois do lançamento | `DiscoveryService` grava o total de descobertas | Implementada (`1a3eb2b`) |
| D02 | Mutação sorteada **na coleta** | 2026-10-16 | Permite a estratégia de esperar um clima especial | `CauldronService` sorteia ao coletar com o clima atual | Implementada (`1a3eb2b`) |
| D03 | Virada diária às **00:00 UTC** | 2026-10-16 | Igual para todos os servidores | Diária, missões, curtidas; 21:00 em Brasília | Implementada (`1a3eb2b`) |
| D04 | Cometa **competitivo**: quem coleta legitimamente primeiro leva | 2026-10-16 | Gera competição | Corrigir a P4 sem mudar a regra | Implementada (regra em `1a3eb2b`; validação em `cf72d51`) |
| D05 | Respingo **pode substituir** um efeito Eterna | 2026-10-16 | Simplicidade; o Escudo protege quem não quer | Comportamento atual do `EffectService` | Implementada (`1a3eb2b`) |
| D06 | **Imunidade de 10 s** depois de receber um respingo (não impede beber) | 2026-10-16 | Evitar spam | `Social.splashImmunity = 10` | Implementada (`cf72d51`) |
| D07 | **Permitir trocar poções beneficiadas pela Sorte VIP**, respeitando as políticas do Roblox (opção C: mutação causada pela VIP conta como item pago) | 2026-10-16 | Não dividir o mercado; cumprir as políticas | Depende do contador de itens pagos (D15) | Aprovada, não implementada (4B.3) |
| D08 | **Não exigir** que os dois jogadores tenham Sorte VIP | 2026-10-16 | Jogadores gratuitos podem receber poções VIP quando a política permitir | Regra de troca por política individual | Aprovada, não implementada (4B.3) |
| D09 | **Prateleira dedicada** à venda (também offline), escolhida pelo jogador | 2026-10-16 | Jogador decide o que vender | Só depois da P3; antes, uma proposta simples para iniciantes | Proposta |
| D10 | **Tutorial guiado**: seta até o caldeirão, destaque para Pena + Mel, primeira poção rápida (Abelha Rainha), ensinar a experimentar o efeito; **Dourada garantida no 2º preparo, uma vez por jogador**; botão **Pular**; pular automático para quem já tinha progresso; **a Diária não interrompe** a primeira experiência; progresso salvo | 2026-10-16 | Primeiros 60 segundos | Campo novo no perfil e mudanças no `CauldronService`, no `DailyUI` e na interface | Aprovada, não implementada (4B.5) |
| D11 | Interruptor para desligar as trocas | 2026-10-16 | Desligar enquanto houver riscos | `Social.tradingEnabled` | Implementada (`ea6726e`) |
| D12 | **Aceitar o risco P1** temporariamente | 2026-10-16 | Recuperação durável é complexa | **Reavaliar antes de liberar trocas ao público** | Vigente |
| D13 | Experiência de **testes separada** da oficial | 2026-10-16 | Não estragar dados reais | [TEST] (`10771365236`); DEBUG restrito a ele | Implementada (DEBUG em `cf72d51`) |
| D14 | **Acelerar Preparo vira carga persistente** (guardada e gasta só quando usada com sucesso) | 2026-10-16 | Não perder Robux sem preparo ativo (P13) | Campo novo no perfil e mudança no `grant` e na interface | Aprovada, não implementada |
| D15 | **Contador de unidades pagas**: ingredientes de pacotes e poções feitas com eles; pagas consumidas primeiro; trocas gratuitas mantidas quando permitidas | 2026-10-16 | Cumprir `IsPaidItemTradingAllowed` sem bloquear trocas grátis (P2) | Campo `paid` no perfil; cerca de 8 pontos de consumo | Aprovada, não implementada (4B.3b) |
| D16 | Sorte VIP **mostra as chances e vantagens** e respeita `ArePaidRandomItemsRestricted` e `IsPaidItemTradingAllowed` | 2026-10-16 | Transparência e conformidade | Tabela de chances na Loja VIP; bônus desligado onde houver restrição | Aprovada, não implementada (4B.3a) |
| D17 | Manter `tradingEnabled = true` no commit da 4B.1 | 2026-10-17 | Continuar testando trocas | — | Implementada (`ea6726e`) |

## Decisões técnicas
| ID | Decisão | Data | Motivação | Status |
|---|---|---|---|---|
| D18 | Usar **ProfileStore** (cópia fixa em `Packages/`) | 2026-10-16 (Fase 1) | Session locking, autosave e `BindToClose` prontos | Implementada (`1a3eb2b`) |
| D19 | Receitas fixas, nomes e segredos **só no servidor** (`src/server/Config`) | 2026-10-16 (Fase 1) | Impede descobrir receitas lendo os arquivos do cliente | Implementada (`1a3eb2b`) |
| D20 | **Para preparar basta ter o ingrediente**; "liberar" só dá acesso ao Mercado | 2026-10-16 (Fase 2) | Permitir usar ingredientes do Cometa e da Diária | Decisão técnica (`1a3eb2b`) |
| D21 | Recibos **sem remoção por idade**; limite de 1000 | 2026-10-17 (4B.2) | O dono pediu verificar se 60 dias seria seguro. A análise concluiu que não, porque o Roblox reenvia recibos não confirmados sem prazo garantido. | Implementada (`cf72d51`) |
| D22 | `lastLogout` passa a significar "até quando o tempo offline já foi contado" | 2026-10-17 (4B.1) | Correção P3 com consistência na gravação | Implementada (`ea6726e`) |

## Pendentes de aprovação
| ID | Assunto | Proposta | Desde |
|---|---|---|---|
| PD1 | **Regra exata da mutação VIP** | É "paga" só se o número sorteado ficou entre a chance normal e a chance com VIP. A análise mostra que isso é exato em todos os cenários atuais ([TEST_RESULTS.md](TEST_RESULTS.md#e-análises-e-cálculos)). | 2026-10-17 |
| PD2 | Falha na consulta ao **PolicyService** | Tratar como restrito (itens pagos não trocáveis e bônus VIP desligado) e tentar de novo a cada 60 s; trocas grátis continuam. | 2026-10-17 |
| PD3 | IDs de monetização por universo (P22) | Ainda sem proposta: precisa decidir como separar os IDs do [TEST] e os da oficial. | 2026-10-17 |
| PD4 | Prateleira dedicada (D09) | Proposta a ser apresentada depois da 4B.3 a 4B.6 | — |
| PD5 | Tempos acelerados só no Studio do [TEST] (P21) | Usar `Debug.enabled()` em `Debug.time` | 2026-10-17 |
