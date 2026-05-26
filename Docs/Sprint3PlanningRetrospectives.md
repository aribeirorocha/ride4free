# Relatório de Execução: Sprint 3 (Sprint Final) — Ride4Free 

## 1. Revisão da Sprint (Sprint Review)

**Demonstração do Incremento Final do Produto:**
Nesta terceira e última iteração do projeto, a equipa não só fechou o escopo planeado com o fecho de duas histórias de utilizador críticas, como elevou a maturidade da arquitetura de software para um nível de prontidão de produção (*Production-Ready*). Fizemos 52 créditos.

As grandes entregas funcionais deste incremento centraram-se na **US6 (User-Chat)** — que passou a permitir a comunicação bidirecional em tempo real entre condutores e passageiros — e na **US7 (Notifications)**, que introduziu um sistema inteligente de alertas visuais (badges na navegação) e notificações locais no dispositivo para garantir que nenhuma mensagem ou alteração de estado de boleia passa despercebida.

O grande marco arquitetural desta Sprint foi a **migração do ambiente de desenvolvimento estritamente local (*localhost*) para uma infraestrutura remota utilizando túneis da Cloudflare (*Cloudflare Tunnels*)**. Esta evolução foi o catalisador ideal para a US7, permitindo testar o fluxo de notificações assíncronas e distribuídas sem o bloqueio crítico de partilhar a mesma rede local ou máquina física. O servidor passou a estar acessível globalmente, viabilizando simulações em dispositivos físicos reais através de redes móveis (4G/5G) e validações cruzadas por qualquer membro da equipa. 

Em paralelo, executámos uma refatoração profunda de UI/UX, isolando lógicas complexas de visualização (ex: as pílulas de estado e a *Zona de Informação Extra*) em *Widgets* imutáveis, e desacoplámos o motor de notificações num serviço centralizado (*RideNotificationHub*), garantindo a robustez, consistência visual e fiabilidade no tratamento de erros do ecossistema.
---

## 2. Planeamento e Organização da Sprint (Sprint Planning)

**Evidência Visual do Scrumboard (Início da Sprint):**
*O nosso planeamento inicial, mostrando as tarefas decompostas para a US6, os épicos de UI/UX refinement e as tasks de infraestrutura do servidor.*

<img width="2940" height="1390" alt="image" src="https://github.com/user-attachments/assets/26ade138-d2f6-4a4c-ac4e-fcba87b418cd" />


**Dinâmica de Comunicação e Rastreabilidade:**
Para esta Sprint final, a nossa gestão de projeto atingiu a sua maturidade máxima. Centralizámos a rastreabilidade de *bugs* estruturais (especialmente *flaky tests* e falhas de CORS/rede) em **GitHub Issues** altamente descritivas. O nosso grupo de comunicação interno transcendeu os meros "pontos de situação"; foi a nossa "sala de guerra" para *pair programming* assíncrono. Discutimos exaustivamente detalhes de implementação, delineámos soluções para bloqueios de *Mocking* e coordenámos os arranques do servidor remoto, mantendo a equipa perfeitamente sincronizada face aos desafios de infraestrutura.

---

## 3. Padrões Ágeis Aplicados

* **Resposta a Impedimentos Técnicos:** A necessidade de testar o Chat (US6) em múltiplos dispositivos simultaneamente evidenciou a limitação do servidor local. A decisão ágil de implementar um *Reverse Proxy* via Cloudflare no meio do ciclo de desenvolvimento foi uma adaptação crítica para garantir a validação da *User Story*.
* **Gestão de Dívida Técnica (Technical Debt Management):** Aplicámos *Refactoring* contínuo, extraindo componentes acoplados (como as *BottomSheets* privadas) para módulos públicos. Isto garantiu o princípio da Responsabilidade Única (SRP) e viabilizou a automação de testes de UI.
* **Qualidade Embutida (Built-In Quality):** A utilização de *MockClients* nos testes de integração assegurou que a nossa *Pipeline* não falhava por timeouts de rede, isolando a verificação da lógica de negócio das flutuações do nosso recém-criado servidor remoto.

---

## 4. Retrospectiva da Sprint (Sprint Retrospective)

**Data:** 25 de Maio de 2026

**Evidência Visual do Scrumboard (Fim da Sprint):**
*Abaixo encontra-se o estado final do nosso quadro Kanban após a conclusão do projeto, com o Chat, o servidor remoto e o polimento final na coluna "Done". Sentimos a necessidade de criar uma US7 para as notificações.*

<img width="2156" height="1118" alt="image" src="https://github.com/user-attachments/assets/3ffdadda-ce62-4774-afbf-d94a539af959" />


**Notas da Reunião (Análise Crítica do Encerramento do Projeto):**

* **O que correu bem (Did Well):**
  * **Exploração de Infraestrutura e Redes:** A configuração do servidor com Cloudflare foi um enorme salto no nosso conhecimento empírico. Sendo a primeira vez da equipa a expor uma API local para a internet de forma segura, a curva de aprendizagem foi acentuada. No entanto, o sucesso desta tarefa ampliou substancialmente as nossas competências em DevOps, gestão de portos e túneis seguros.
  * **Maturidade em Testes de UI:** Dominámos a gestão de assincronia no Flutter (ex: ciclo de vida de `ScaffoldMessengers`) e injeção de dependências para isolar a API nos testes. O produto final é entregue com uma base de código resiliente e fortemente coberta.
  * * **Refatoração Agressiva e Controlo de Dívida Técnica:** A integração de *features* complexas e assíncronas como o Chat (US6) e Notificações (US7) num ambiente remoto tinha tudo para gerar "código esparguete". O nosso grande mérito foi ter a disciplina de pagar a dívida técnica acumulada, aplicando rigorosamente o *Single Responsibility Principle* (SRP). Desacoplámos lógicas de negócio da UI, transformámos *widgets* massivos em componentes isolados e entregámos uma arquitetura verdadeiramente resiliente e *Production-Ready*.

* **O que fazer diferente (Do Differently):**
  * **Mitigação de Heterogeneidade de Sistemas Operativos:** A configuração inicial do servidor e do ambiente de desenvolvimento revelou atritos severos e perdas de tempo devido aos diferentes Sistemas Operativos usados pela equipa (Windows vs. macOS). As diferenças nas variáveis de ambiente e caminhos de ficheiros causaram bloqueios que não prevemos. 
  * *Lição para o futuro:* Em projetos futuros, adotaremos desde o Sprint 0 uma abordagem agnóstica de SO (utilizando *Docker* ou *scripts* multiplataforma rigorosos) para garantir que o ambiente "corre na minha máquina" da mesma forma para todos.

* **Dúvidas e Incertezas Críticas (Puzzles):**
  * **WebSockets vs. Polling num Ambiente Remoto:** Com a API alojada através da Cloudflare, o nosso chat (US6) baseia-se em chamadas HTTP. O nosso maior *puzzle* de arquitetura é avaliar se o tráfego gerado pelo *polling* escalaria de forma sustentável na nossa infraestrutura atual, ou se o custo/complexidade de migrar para *WebSockets* (para latência real-time) seria mandatório num cenário de lançamento em produção com centenas de viagens simultâneas.
  * **Gestão Global de Estado (*State Management*):** Com a introdução do servidor remoto e dependências instanciadas através da árvore de *widgets*, o código começou a mostrar sinais de densidade. Continuamos a debater se a adoção de um *Dependency Injector* (como `get_it`) ou um gestor global (como `Riverpod`) teria compensado a curva de aprendizagem exigida numa fase inicial do projeto, face ao ganho de legibilidade a longo prazo.
