# Product Backlog Refinement & User Feedback (End of Sprint 3)

## 1. Metodologia de Validação Híbrida
Com a conclusão da Sprint 3 e a aplicação a atingir o estado de *Release* funcional (com infraestrutura remota via Cloudflare, Chat bidirecional e Autenticação Sigarra), o nosso objetivo de recolha de feedback focou-se na validação do incremento atual e na construção do *Roadmap* futuro (v2.0). 

Para garantir o máximo rigor, adotámos uma estratégia de validação em duas fases (Qualitativa e Quantitativa):
1. **Sessões Qualitativas (Demos):** Realizámos **3 Demonstrações Interativas** onde estudantes universitários testaram a aplicação nos seus telemóveis, gerando *insights* profundos sobre a usabilidade.
2. **Validação Quantitativa (Surveys):** Para termos a certeza das afirmações recolhidas nas Demos e apurarmos estas necessidades de forma mais rápida e global, lançámos um **Inquérito via Google Forms** à comunidade académica, obtendo **34 respostas** válidas.(https://docs.google.com/forms/u/0/d/e/1FAIpQLSenXuD_IIUCzkgu1y6IIGeN42EqzPMQreP201z3Q3almD0BRQ/formResponse)

## 2. Técnicas de Facilitação e Avaliação
Para extrair dados acionáveis e fugir do "feedback genérico", aplicámos duas técnicas recomendadas pelas boas práticas da *Scrum.org*:
* **Nas Demos (Buy a Feature):** Apresentámos aos 3 utilizadores um "orçamento" de 100 moedas fictícias e pedimos que o investissem nas futuras funcionalidades que mais queriam ver construídas.
* **Nos Inquéritos (Kano Analysis):** Utilizamos o Google Forms para inquirir a comunidade mais alargada, pedindo-lhes para classificar as funcionalidades vencedoras da Demo em três categorias: *Basic Needs*, *Performance Needs* ou *Delighters*.

## 3. Feedback Recolhido e Cruzamento de Dados
O cruzamento dos dados das 34 respostas revelou um alinhamento claro entre a intenção de uso e a criticidade das funcionalidades:

| Funcionalidade | Classificação Principal | Feedback / Justificação |
| :--- | :--- | :--- |
| **Notificações Push** | *Basic Need* | 45,5% essencial; 48,5% desejável. Essencial para evitar desencontros. |
| **Trust & Reviews** | *Performance Need* | 63,6% consideram essencial para a segurança na partilha. |
| **Pagamentos (MBWay)** | *Delighter/Indiferente* | 75,8% indiferentes; a maioria prefere resolver de forma informal. |
## 4. Refinamento do Product Backlog (PBL) para o Futuro Roadmap
Com base nesta dupla validação empírica, o nosso *Product Backlog* sofreu um refinamento formal e fundamentado em dados, alinhando a estratégia do produto com o conceito Ágil de *Value-Driven Development*:
## 4. Refinamento do Product Backlog (PBL)
A análise consolidou a nossa estratégia para as próximas iterações:

### Adição de Novos PBIs
* **US7: Push Notifications.** Como utilizador, quero receber notificações nativas no telemóvel quando recebo uma nova mensagem no chat, para ser alertado instantaneamente sem ter de manter a app aberta.

### Reordenação de Prioridades
* **Prioridade Máxima:** **US7 (Push Notifications)** promovida ao topo. Validada como *Basic Need*.
* **Prioridade Média:** **Sistema de Reviews.** Validado como fator crítico de confiança.
* **Despriorização Estratégica:** **Integração de Pagamentos.** Movida para o *Icebox*. Os dados provaram que o esforço técnico de integrar *gateways* não traria o Retorno de Investimento (ROI) imediato necessário nesta fase.

## 5. Conclusão
O fecho da Sprint 3 não marca o fim do produto, mas a sua validação no mercado. Com uma nota de utilidade muito elevada (61,8% dos inquiridos deram pontuação máxima), confirmámos que o nosso foco deve manter-se na **fiabilidade da comunicação** e na **confiança interpessoal**, em vez de infraestruturas financeiras complexas. O nosso PBL reflete agora as necessidades reais da comunidade académica.
