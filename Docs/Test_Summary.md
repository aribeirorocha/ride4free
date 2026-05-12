# 🧪 Arquitetura de Testes — Ride4Free

## Visão Geral

Este documento detalha a arquitetura de testes do projeto **Ride4Free**, atualizada para refletir a maturidade tecnológica alcançada na Sprint 2 (transição para Backend FastAPI, SQLite e Autenticação U.Porto Sigarra). 

A nossa suite de testes foi desenhada para garantir a máxima qualidade de código, o estrito cumprimento das regras de negócio, resiliência a falhas de rede e uma experiência de utilizador sem bloqueios. O projeto conta com mais de **300 testes automatizados**, abrangendo as camadas de Backend (Python) e Frontend (Dart/Flutter), divididos em:

- ✅ Testes Unitários (Lógica de Negócio, Algoritmos Espaciais e Expressões Regulares)
- 🧩 Testes de Widget (Renderização de UI e Comportamento Isolado)
- 🔗 Testes de Integração (Fluxos End-to-End, Simulação de Hardware e HTTP)
- 📋 Testes de Aceitação (ATDD baseados no Product Backlog)

### 📊 Cobertura e Resultados (Métricas de Qualidade)

*(Nota: Imagens geradas a partir da execução da suite no nosso pipeline CI/CD)*

<img width="500" height="46" alt="image" src="https://github.com/user-attachments/assets/5a7cf1e9-f817-4d9f-8dfb-246663c8da11" />
<img width="250" height="500" alt="image" src="https://github.com/user-attachments/assets/3814cbfd-bdc8-427c-b5ec-a2186b1abf7f" />

---

## 1. Estratégias Avançadas de Teste (Sprint 2)

Para garantir a estabilidade do produto em integração contínua, a equipa implementou estratégias de *mocking* e isolamento de estado:

### 1.1. Isolamento de Estado no Backend (Python)
Para prevenir o erro de *Database Locked* e garantir que os testes não contaminam a base de dados de produção, implementámos uma *Fixture* no `pytest` que utiliza a biblioteca `tempfile` para gerar uma base de dados SQLite limpa na memória antes de cada teste, destruindo-a no final.

### 1.2. Simulação HTTP e de Hardware no Frontend (Flutter)
- **HTTP Interceptors (`MockClient`):** As chamadas de rede reais (que causavam bloqueios de segurança e erros 400 no CI) foram substituídas por um `MockClient` do pacote `http/testing`. Isto permite-nos testar o envio de cabeçalhos de autorização (`Bearer Token`) e simular erros `500 Internal Server Error` de forma previsível.
- **Mocking de Sensores (GPS):** Implementámos o `MockGeolocatorPlatform` para simular o comportamento do GPS do dispositivo, permitindo testar fluxos de permissões (`denied`, `whileInUse`) e devolver coordenadas fixas (ex: FEUP) para testar os filtros de distância.
- **Sessões Locais (`SharedPreferences`):** Utilizamos `SharedPreferences.setMockInitialValues` para injetar sessões pré-autenticadas, permitindo testar ecrãs protegidos (como o *ProfilePage*) sem ter de executar o fluxo de login em todos os testes.

---

## 2. Testes de Backend (Python/FastAPI)

> **Foco:** Persistência, Algoritmos Espaciais e Criptografia.

| Área | Descrição e Validação |
|------|-----------------------|
| **Filtros Espaciais (Haversine)** | Testa exaustivamente a fórmula matemática de Haversine (`haversine_meters`) para garantir que os passageiros apenas veem condutores dentro do seu raio de tolerância (ex: 500m a 2000m). |
| **Autenticação e Criptografia** | Valida a criação de hashes de passwords com salt único via `PBKDF2_HMAC` e o ciclo de vida dos Bearer Tokens de sessão. |
| **Sistema de Reservas e Lotação** | Testa os constrangimentos vitais do sistema SQLite: bloqueia duplas reservas, impede um utilizador de reservar a sua própria boleia e garante que o estado de `Open` passa a `Full` quando os lugares (seats) chegam a zero. |
| **Integração Relacional** | Valida a integridade referencial (`ON DELETE CASCADE`) entre `users`, `sessions`, `driver_offers` e `passenger_requests`. |

---

## 3. Testes de Frontend (Dart/Flutter)

> **Foco:** Reatividade da UI, Validação de Formulários e Fluxos Assíncronos.

### 3.1. Testes Unitários e de Widget
Isolam a lógica matemática e de estado local.

| Grupo | Descrição |
|-------|-----------|
| **Parsing Sigarra (Auth)** | Valida as Expressões Regulares (`RegExp`) utilizadas no scraping do Sigarra para extrair corretamente nomes limpos e fotos de perfil a partir do HTML cru. |
| **Cálculo de Recompensas** | Assegura que o algoritmo dinâmico de recompensas (`lugares * 10`) funciona perfeitamente, garantindo que o multiplicador é imediato. |
| **Validação de Inputs** | Testa a introdução manual de horas (HH:mm) bloqueando formatos impossíveis como `25:99` ou `08:60`, disparando as mensagens de erro adequadas na UI. |

### 3.2. Testes de Integração End-to-End
Garante que a comunicação entre vários ecrãs e a gestão de estado ocorrem sem falhas.

| Desafio Resolvido | Estratégia Implementada |
|-------------------|-------------------------|
| **Matching de Textos Ricos** | Como a recompensa "+30 Créditos" é desenhada dinamicamente usando interpolação, o Flutter converte-a em `RichText`. Implementámos `find.text(..., findRichText: true)` e `find.byWidgetPredicate` para encontrar strings escondidas em Spans complexos. |
| **Timers Infinitos (Timeouts)** | O quadro da comunidade utiliza um `Timer.periodic` para atualizar dados de 3 em 3 segundos. O uso de `pumpAndSettle()` causava *timeouts*. Resolvemos o problema utilizando controlo manual de frames: `tester.pump(const Duration(milliseconds: 500))`. |
| **Navegação com Estado** | Confirma que a `BottomNavigationBar` (agora otimizada com `IndexedStack`) alterna fluidamente as tabs sem destruir o que o utilizador já preencheu nos campos de origem/destino. |

---

## 4. Testes de Aceitação / User Stories (ATDD)

Mapeamento direto do código com os critérios de aceitação do Product Backlog:

### US1 & US3 — Oferecer Boleia e Filtros de Distância
* **Validação de Interface do Mapa:** Garante que os mapas interativos renderizam com os raios corretos (0m para oferta, variável para pesquisa) e respondem a eventos `onTap` para definir `LatLng`.
* **Proteção de Submissão:** Confirma o bloqueio visual do botão "Publicar Viagem" (fica cinzento/desativado) se a lotação for zero ou a hora for inválida.

### US5 — Autenticação Universitária (Sigarra)
* **Prevenção de Bypass:** Valida que a aplicação intercepta qualquer tentativa de navegação para a *HomeShell* se o token da sessão local estiver nulo, redirecionando o utilizador para a `UniversityLoginPage` e mostrando a notificação: *"Inicie sessão no perfil"*.

---

## 5. Integração Contínua (CI/CD) e Resolução de Problemas

O repositório utiliza **GitHub Actions** para bloquear *Pull Requests* que não passem na nossa grelha de qualidade.

### 🛠️ Troubleshooting de CI/CD Comum (Erros em Pipeline)

| Erro / Problema | Causa e Solução Implementada |
|-----------------|------------------------------|
| **`flutter analyze` falha (Exit Code 1)** | O pipeline exige código perfeito. Avisos menores (como *unused imports* ou *ifs* sem chavetas) chumbam a *build*. **Solução:** Limpeza sistemática de código e uso de `--no-fatal-warnings` quando justificável. |
| **Database Locked (Python)** | Exceções durante a escrita trancavam o SQLite. **Solução:** Implementação generalizada de `@contextmanager` e do bloco `with get_connection()` para garantir o *rollback* ou fecho automático da base de dados. |
| **Erro 400 Bad Request no Flutter** | Os testes tentavam atingir a API externa sem rede. **Solução:** Injeção de Dependências. Os testes passam a injetar um `http.Client` simulado (`MockClient`) no construtor do serviço, contornando a necessidade de rede. |
