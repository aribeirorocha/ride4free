# Relatório de Execução: Sprint 2 — Ride4Free 

## 1. Revisão da Sprint (Sprint Review)
**Demonstração do Incremento do Produto:**
Nesta segunda iteração, a equipa focou-se em refinar a experiência do utilizador e expandir as capacidades centrais da plataforma. Entregámos com sucesso a **US3 (Filtro Avançado de Boleias)** e um novo requisito identificado durante o ciclo, a **US5 (Integração de Autenticação Universitária)**. 

Inicialmente, o fluxo de autenticação estava aglomerado num requisito de login genérico. Contudo, durante a fase de descoberta técnica, a equipa apercebeu-se de que o *Single Sign-On* (SSO) da universidade era funcional e arquiteturalmente distinto. Abraçando o princípio Ágil de *responder à mudança em vez de seguir um plano rígido*, criámos dinamicamente a US5 para isolar esta integração. Adicionalmente, a implementação da lógica dinâmica de filtros (US3) permite agora aos utilizadores refinar as boleias disponíveis com base no tempo, raio de tolerância e destino, melhorando drasticamente a usabilidade da aplicação.

**Feedback e Adaptação:**
Em resposta à dívida técnica e aos desafios de integração identificados na Sprint 1, a rigorosa separação da lógica de sessão (US5) resultou numa arquitetura muito mais limpa e modular, que adere estritamente ao Princípio de Responsabilidade Única (*Single Responsibility Principle*). O ambiente de testes também foi estabilizado em conformidade com as novas *features*.

---

## 2. Planeamento e Organização da Sprint (Sprint Planning)
**Planeamento de Esforço:**
Aplicando o padrão *Yesterday's Weather*, a equipa utilizou a velocidade registada na Sprint 1 para guiar o compromisso atual. A equipa comprometeu-se e entregou com sucesso um total de **32 pontos de esforço**. Esta capacidade cobriu adequadamente as complexidades de integrar a lógica de autenticação externa e os desafios algorítmicos do novo sistema de filtros.

**Estrutura da Equipa e Marcos (Milestones):**
Para maximizar a eficiência e garantir que a *Definition of Done* (DoD) era rigorosamente cumprida, a equipa de 4 elementos foi dividida em dois subgrupos especializados a trabalhar em paralelo:
1. **Subgrupo de Qualidade e Testes (2 elementos):** Dedicados exclusivamente à criação da suite de automação de testes (Integração e Unidade). Foram responsáveis por validar o algoritmo de filtros, garantir a cobertura dos fluxos de erro da UI e assegurar que o código era validado imediatamente após ser escrito (*Shift-Left Testing*).
2. **Subgrupo de Implementação e Desenvolvimento (2 elementos):** Focados na escrita do código de produção. Esta dupla lidou com a ligação da UI em Flutter, os *endpoints* de filtragem e a complexa gestão de estado (*State Management*) exigida pelo novo fluxo de autenticação.

---

## 3. Padrões Ágeis Aplicados
* **Resposta à Mudança (Responding to Change):** A criação dinâmica da US5 a meio do projeto, quando se tornou evidente que o login universitário exigia o seu próprio épico, garantiu que o *Product Backlog* refletia constantemente o verdadeiro estado do produto.
* **Divisão em Pequenos Itens (Small Items):** A US3 (Filtros) foi decomposta em fatias horizontais mais pequenas (ex: implementação do Slider na UI, lógica de pesquisa local), permitindo que os dois subgrupos trabalhassem sem se bloquearem mutuamente.
* **Yesterday's Weather:** Limitação do nosso compromisso a 32 pontos com base em evidências empíricas da sprint anterior, mantendo um ritmo de desenvolvimento sustentável.
* **Estimativas "Pigs" (Pigs Estimate):** As estimativas para a nova US5 e para a US3 foram feitas exclusivamente pelos programadores e *testers* que iam colocar a "mão na massa", garantindo um planeamento realista.
* **Qualidade Embutida (Built-in Quality):** Ao dedicar metade da equipa estritamente aos testes, assegurámos que a qualidade foi construída no produto desde o primeiro dia, em vez de ser inspecionada apenas no fim.

---

## 4. Retrospectiva da Sprint (Sprint Retrospective)
**Data:** 11 de Maio de 2026

**Evidência Visual do Scrumboard:**
*Abaixo encontra-se o estado final do nosso quadro Kanban após a conclusão da Sprint 2, demonstrando o fluxo das User Stories desde o Product Backlog até à coluna "Done".*

`[ INSERIR IMAGEM DO SCRUMBOARD AQUI ]`

**Notas da Reunião:**

* **O que correu bem (Did Well):**
    * **Sinergia entre Subgrupos:** A divisão 2-Dev / 2-QA foi altamente eficaz. A coordenação permitiu que a equipa de desenvolvimento avançasse com a UI e a lógica de filtros de forma contínua, enquanto a equipa de testes garantia a estabilidade da *app*.
    * **Modularidade Arquitetural:** Desacoplar a lógica genérica de sessão do Login Universitário específico (US5) tornou a base de código muito mais testável e robusta contra regressões.

* **O que fazer diferente (Do Differently):**
    * **Refinamento de Critérios de Aceitação:** Alguns *edge cases* na lógica de filtragem (ex: como a UI deve reagir exatamente quando o raio de tolerância retorna zero resultados) só foram descobertos durante a integração. 
    * *Ação:* Vamos implementar a estratégia dos "Três Amigos" (*Three Amigos* - Dev, QA, e Product Owner) durante o *Backlog Refinement* para debater *edge cases* antes de o código começar a ser escrito.

* **Dúvidas e Incertezas (Puzzles):**
    * **Escalabilidade da Base de Dados com Filtros Múltiplos:** Atualmente, a filtragem de boleias (US3) é processada de forma eficiente. No entanto, à medida que a base de dados crescer, debatemos se será necessário implementar indexação espacial (como R-Trees) para manter os tempos de resposta da pesquisa instantâneos.
    * **Gestão de Expiração de Sessão:** Ainda precisamos de validar de forma extensiva como a aplicação Flutter lida de forma elegante com a expiração inesperada do token de utilizador (US5) durante uma pesquisa ativa de boleias.
