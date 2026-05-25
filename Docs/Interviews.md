# Product Backlog Refinement & User Feedback (End of Sprint 3)

## 1. Metodologia de Validação Híbrida
Com a conclusão da Sprint 3 e a aplicação a atingir o estado de *Release* funcional (com infraestrutura remota via Cloudflare, Chat bidirecional e Autenticação Sigarra), o nosso objetivo de recolha de feedback focou-se na validação do incremento atual e na construção do *Roadmap* futuro (v2.0). 

Para garantir o máximo rigor, adotámos uma estratégia de validação em duas fases (Qualitativa e Quantitativa):
1. **Sessões Qualitativas (Demos):** Realizámos **3 Demonstrações Interativas** onde estudantes universitários testaram a aplicação nos seus telemóveis, gerando *insights* profundos sobre a usabilidade.
2. **Validação Quantitativa (Surveys):** Para termos a certeza das afirmações recolhidas nas Demos e apurarmos estas necessidades de forma mais rápida e global, lançámos um **Inquérito via Google Forms** à comunidade académica, obtendo **12 respostas** válidas.

## 2. Técnicas de Facilitação e Avaliação
Para extrair dados acionáveis e fugir do "feedback genérico", aplicámos duas técnicas recomendadas pelas boas práticas da *Scrum.org*:
* **Nas Demos (Buy a Feature):** Apresentámos aos 3 utilizadores um "orçamento" de 100 moedas fictícias e pedimos que o investissem nas futuras funcionalidades que mais queriam ver construídas.
* **Nos Inquéritos (Kano Analysis):** Utilizamos o Google Forms (com capturas de ecrã da *app* atual) para inquirir a comunidade mais alargada, pedindo-lhes para classificar as funcionalidades vencedoras da Demo em três categorias: *Basic Needs*, *Performance Needs* ou *Delighters*.

## 3. Feedback Recolhido e Cruzamento de Dados
O cruzamento dos dados das Demos com os resultados globais do Google Forms revelou um alinhamento perfeito, contrariando algumas das nossas suposições técnicas iniciais:

1. **Notificações Push (Fora da App):** * *Nas Demos:* Recebeu a esmagadora maioria do investimento (150/300 moedas).
   * *No Google Forms:* Mais de 85% (10 em 12) dos inquiridos classificaram-na como uma **Basic Need**. A justificação transversal foi que o In-App Chat (US6) é excelente, mas sem notificações nativas do SO, o risco de desencontros mantém-se caso fechem a *app*.
2. **Sistema de Trust & Reviews (Estrelas):** * *Nas Demos:* Recebeu um forte investimento (100/300 moedas) associado à segurança.
   * *No Google Forms:* Cerca de 75% classificaram-no como uma **Performance Need**, indicando que a confiança e a distinção de bons condutores é vital para a adoção em massa da plataforma.
3. **Integração de Pagamento In-App (ex: MBWay):** * *Nas Demos:* Recebeu apenas 50/300 moedas.
   * *No Google Forms:* Apenas 2 utilizadores a consideraram essencial. A grande maioria classificou-a como um **Delighter** ou algo indiferente, preferindo resolver a divisão de custos de forma informal, desde que a comunicação e a boleia estejam garantidas.

## 4. Refinamento do Product Backlog (PBL) para o Futuro Roadmap
Com base nesta dupla validação empírica, o nosso *Product Backlog* sofreu um refinamento formal e fundamentado em dados, alinhando a estratégia do produto com o conceito Ágil de *Value-Driven Development*:

* **Adição de Novos PBIs (New Entries):**
  * **[Adicionado] US7: Push Notifications.** Como utilizador, quero receber notificações nativas no telemóvel quando recebo uma nova mensagem no chat, para ser alertado instantaneamente sem ter de manter a app aberta.

* **Reordenação de Prioridades (Reordering):**
  * A **US7 (Push Notifications)** foi promovida imediatamente para o Topo do Backlog, tornando-se a prioridade técnica absoluta para uma eventual Sprint 4, validada por ambas as métricas como uma *Basic Need* para a sobrevivência do ecossistema de comunicação.
  * O épico de **Integração de Pagamentos**, que estava provisoriamente planeado para o topo das próximas iterações, foi **despriorizado e removido do Backlog**, pois os dados provaram claramente que o esforço técnico de integrar *gateways* de pagamento não traria o Retorno de Investimento (ROI) imediato que a comunidade procura nesta fase do produto.

**Conclusão:** O fecho da Sprint 3 não marca o fim do produto, mas sim a sua validação no mercado. O nosso PBL reflete agora as necessidades reais da comunidade académica, garantindo que o desenvolvimento futuro se mantém estritamente focado na maximização de valor contínuo (*Value-Driven Development*).
