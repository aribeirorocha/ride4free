# 🧪 Arquitetura de Testes — Ride4Free

## Visão Geral

Este documento detalha a arquitetura de testes do projeto **Ride4Free**, atualizada para refletir a maturidade tecnológica alcançada no Sprint 3 (transição para Backend FastAPI, SQLite e Autenticação U.Porto Sigarra). 

A nossa suite de testes foi desenhada para garantir a máxima qualidade de código, o estrito cumprimento das regras de negócio, a resiliência a falhas de rede e uma experiência de utilizador sem bloqueios. O projeto conta com uma robusta infraestrutura de testes automatizados, dividida entre o ecossistema Backend (Python) e Frontend (Dart/Flutter).

No ecossistema Flutter, a suite totaliza **1129 testes passados com sucesso** (executados em apenas 31.4s), organizados estrategicamente em 4 pastas estruturais:
* **`test/unit/`** – Validação de lógica pura, mutações de estado e parsers.
* **`test/widget/`** – Renderização e comportamento isolado de componentes de UI.
* **`test/api/`** – Contratos de comunicação, parsing de JSON e integração com endpoints.
* **`test/integration/`** – Fluxos completos do utilizador (*End-to-End*) e gestão de estado global.

No ecossistema Backend, a suite em **Python/FastAPI** valida as transações na base de dados, algoritmos de geolocalização e regras de segurança.

---

## 1. Estrutura Detalhada da Suite de Testes (Flutter)

A suite de testes do Flutter encontra-se modularizada para garantir alta coesão e baixo acoplamento:

### 1.1. Testes Unitários (`test/unit/`)
Focados em lógica de negócio isolada, helpers, cálculo de estado e lógica de infraestrutura.
* **`main_test.dart`:** Garante o bootstrapping correto da aplicação e inicialização de dependências.
* **`ride_notification_service_test.dart` & `ride_notification1_test.dart`:** Valida o ciclo de vida das notificações de boleias (pedidos pendentes, vistos, e limpezas de histórico).
* **`ride4free_api_test.dart` & `ride4free_api_extended_test.dart`:** Garante o mapeamento correto das respostas brutas de rede para os modelos Dart da aplicação.
* **`sigarra_auth_test.dart`:** Valida as Expressões Regulares (`RegExp`) utilizadas no scraping do Sigarra para extrair nomes e fotos de perfil a partir do HTML.
* **`university_session_test.dart` & `session_validation_extended_test.dart`:** Controla a expiração de tokens e persistência de sessões.

### 1.2. Testes de Componentes/Widgets (`test/widget/`)
Validam se os elementos visuais reagem corretamente às interações do utilizador.
* **`widgets_main_test.dart`:** Valida os componentes transversais e genéricos da aplicação.
* **Formatação e Inputs:** Testes dedicados a inputs específicos (como `_InputLike widget`, `TickRow widget`, validação de campos de login e formatação de linhas de diálogo).
* **Componentes de UI Específicos:** Testes de ecrãs e cartões isolados como `ProfileCard`, `RideCard`, `RewardPanel`, `TopTitleBar`, `HomeShell` e `PedidosPage widget`.

### 1.3. Testes de API (`test/api/`)
Testam a camada de comunicação cliente-servidor sem fazer pedidos reais à internet.
* **`api_client_test.dart`:** Garante que o cliente HTTP injeta os cabeçalhos corretos (ex: `Authorization: Bearer <token>`).
* **`coverage_test.dart`:** Testes utilitários para garantir que todos os caminhos críticos da camada de dados possuem cobertura de código.

### 1.4. Testes de Integração (`test/integration/`)
Simulam fluxos completos de utilização cruzando múltiplos ecrãs e lógica de estado síncrona/assíncrona.
* **`api_integration_test.dart`:** Simula fluxos completos de chamadas à API usando ambientes controlados.
* **`auth_integration_test.dart`:** Fluxo completo desde o ecrã de login, validação de credenciais até à entrada na aplicação.
* **`main_integration_test.dart`:** Garante que a árvore de widgets principal inicializa e recupera estados prévios sem crashar.
* **Fluxos por User Story / Ecrã:**
  * **`Integration — Navegação e Estrutura`:** Valida a troca de abas e navegação fluida.
  * **`Integration — Main & Bootstrapping`:** Valida validações de campos vazios, fluxos de logout e tratamento de sessões existentes.
  * **`Integration — ProfilePage`:** Garante que os dados do perfil (nome, username, estatuto premium, botões de logout) carregam e renderizam nos locais corretos.
  * **`Integration — CommunityBoardPage`:** Valida a listagem da comunidade, troca de secções e comportamento do `SegmentedButton`.
  * **`Integration — SearchRidePage`:** Garante o funcionamento dos filtros de pesquisa de boleias.

---
#### Test Coverage do flutter
<img width="238" height="277" alt="Captura de ecrã 2026-05-27, às 03 38 14" src="https://github.com/user-attachments/assets/9d72c75e-13a2-446b-8c5b-090ff2663402" />

## 2. Testes de Backend (Python/FastAPI)

A camada de Backend do **Ride4Free**, desenvolvida em **Python** com a framework **FastAPI** e persistência em **SQLite**, é validada de forma rigorosa por uma suite de testes automatizados com o `pytest`. Estes testes asseguram a integridade relacional da base de dados, a segurança dos endpoints protegidos e o cumprimento estrito de todas as regras de negócio críticas.

Para garantir que a execução dos testes é completamente isolada, rápida e livre de efeitos secundários (como bases de dados corrompidas ou tabelas trancadas), implementámos uma arquitetura assente em *fixtures* dinâmicas do `pytest`. Cada teste gera uma base de dados SQLite limpa num ficheiro temporário único através da biblioteca `tempfile`, executando as migrações e inicializações necessárias (`db.init_db()`), e destruindo o ficheiro de forma segura no encerramento do teste (`os.unlink(path)`).

A suite de testes do Backend divide-se estruturalmente em três grandes módulos complementares:

---

### 2.1. Testes de Base de Dados e Persistência (`test_database.py`)
> **Foco:** Validação de hashing criptográfico, integridade relacional, restrições transacionais e persistência de dados.

Este módulo isola as funções de manipulação direta do SQLite através da camada de dados (`database.py`), validando a robustez do esquema relacional sem a sobrecarga do servidor HTTP.

* **Autenticação, Hashing e Segurança:**
    * `test_hash_password_creates_salted_hash`: Garante que a password do utilizador nunca é guardada em texto limpo. Valida que o algoritmo gera uma string cifrada composta por um *salt* único de 16 bytes (32 caracteres hexadecimais) e o respetivo *digest* SHA-256 separados por um delimitador `$`.
    * `test_verify_password_correct`: Confirma que a validação de credenciais funciona perfeitamente ao recomputar o hash com o mesmo salt para uma password correta.
    * `test_verify_password_incorrect`: Assegura a rejeição imediata de passwords incorretas ou vazias.
* **Gestão de Sessões Universitárias:**
    * Valida a criação e armazenamento de tokens de sessão únicos associados ao ID do utilizador e mapeia o ciclo de vida da sessão.
* **Gestão de Pedidos de Passageiros (`passenger_requests`):**
    * `test_insert_passenger_request_saves_fields`: Verifica que os pedidos de boleia salvaguardam todos os campos vitais (ID do utilizador, destino, número de lugares solicitados e o estado inicial padrão `'open'`).
    * `test_list_community_passengers_excludes_cancelled`: Garante a higiene visual do quadro da comunidade, certificando que pedidos atualizados para o estado `'cancelled'` deixam de ser listados para outros condutores.
    * `test_fulfilled_passenger_has_booking_info`: Valida o fluxo relacional em que um pedido satisfeito passa a conter o identificador da reserva (`booking_id`) e expõe o nome do condutor que aceitou o pedido (`booked_by_name`).
    * `test_open_and_fulfilled_both_visible`: Garante a integridade dos filtros de listagem mista, mantendo pedidos abertos e reservados devidamente acessíveis no histórico do ecossistema.

---

### 2.2. Testes de Endpoints e Contratos de API (`test_api_endpoints.py`)
> **Foco:** Contratos de input/output, códigos de estado HTTP, tratamento de erros e integridade dos payloads (JSON).

Este módulo valida o comportamento dos endpoints expostos pelo FastAPI, garantindo que a aplicação responde com as estruturas de dados corretas (`Pydantic schemas`) e lida de forma graciosa com inputs malformados.

* **Gestão de Ofertas de Condutores (`/driver/offers`):**
    * `test_create_driver_offer_success`: Valida o fluxo feliz onde um condutor autenticado submete um destino válido e lugares disponíveis, recebendo uma confirmação bem-sucedida e o registo imediato na aplicação.
* **Controlo de Erros e Casos de Fronteira (`TestErrorHandling`):**
    * `test_missing_auth_header`: Protege a aplicação contra acessos não autorizados, garantindo que qualquer chamada a rotas privadas (como `/users/me`) sem o cabeçalho HTTP adequado resulta num erro `401 Unauthorized`.
    * `test_invalid_auth_token`: Assegura o Micro-Bloqueio imediato com `401 Unauthorized` caso o token Bearer fornecido seja inválido ou aleatório (`invalid_token_xyz`).
    * `test_malformed_auth_header`: Rejeita cabeçalhos de autorização que não sigam o formato padrão internacional `Bearer <token>`.
    * `test_missing_required_fields_in_offer`: Valida a camada de tipagem e validação do FastAPI. Se um utilizador submeter um formulário omitindo dados obrigatórios (como o número de lugares `available_seats`), a API interseta o pedido com um erro `422 Unprocessable Entity`, protegendo a base de dados de dados corrompidos ou nulos.
    * `test_invalid_json_body`: Garante a resiliência do servidor a payloads de texto corrompido que não correspondam a uma estrutura JSON válida.

---

### 2.3. Testes de Integração de Fluxos de Negócio (`test_main.py`)
> **Foco:** Fluxos completos ponta-a-ponta (*End-to-End*), matching de boleias, concorrência e filtros avançados.

Este módulo simula a interação real dos clientes (Frontend) com a API do sistema, validando a sincronização perfeita entre múltiplos utilizadores (Passageiros e Condutores) e o impacto dinâmico nas tabelas relacionais.

* **Ciclo de Vida do Utilizador e Perfil:**
    * `test_health_check`: Valida a disponibilidade básica do serviço.
    * `test_register_and_login_flow`: Testa o encadeamento lógico de criação de conta seguido da geração de um Bearer Token válido para sessões posteriores.
    * `test_get_current_user`: Confirma que a API extrai o token do cabeçalho de autorização de forma correta e devolve com precisão os dados privados do utilizador autenticado.
* **Fluxo Completo de Reserva e Lotação de Boleias:**
    * `test_book_passenger_request_updates_status`: Simula o fluxo crítico da aplicação: um passageiro publica um pedido de boleia (`/passenger/requests`), um condutor visualiza e aceita esse pedido (`/bookings/passenger-request`). O teste valida que o estado do pedido transita automaticamente de `'open'` para reservado, e que a listagem da comunidade reflete instantaneamente o estado de `booked` como `True`.
* **Filtros de Pesquisa Avançados:**
    * `test_community_drivers_destination_filter_in_response`: Testa o algoritmo de filtragem por destino. Garante que ao pesquisar por uma localização específica (ex: `"FEUP"`), a API restringe os resultados e inclui os metadados do filtro no payload de resposta para sincronização visual do Frontend.
    * `test_community_passengers_destination_filter_none_when_absent`: Certifica que o comportamento por defeito da listagem devolve dados globais sem restrições arbitrárias quando nenhum parâmetro de destino é explicitamente passado na query string.
## 3. Testes de Backend (Python/FastAPI)

> **Foco:** Persistência, Algoritmos Espaciais e Criptografia.

| Área | Descrição e Validação |
|------|-----------------------|
| **Filtros Espaciais (Haversine)** | Testa exaustivamente a fórmula matemática de Haversine (`haversine_meters`) para garantir que os passageiros apenas veem condutores dentro do seu raio de tolerância (ex: 500m a 2000m). |
| **Autenticação e Criptografia** | Valida a criação de hashes de passwords com salt único via `PBKDF2_HMAC` e o ciclo de vida dos Bearer Tokens de sessão. |
| **Sistema de Reservas e Lotação** | Testa os constrangimentos vitais do sistema SQLite: bloqueia duplas reservas, impede um utilizador de reservar a sua própria boleia e garante que o estado de `Open` passa a `Full` quando os lugares (*seats*) chegam a zero. |
| **Integração Relacional** | Valida a integridade referencial (`ON DELETE CASCADE`) entre `users`, `sessions`, `driver_offers` e `passenger_requests`. |

---

## 4. Testes de Aceitação / User Stories (ATDD)

Mapeamento direto do código com os critérios de aceitação do Product Backlog:

### US1 & US3 — Oferecer Boleia e Filtros de Distância
* **Validação de Interface do Mapa:** Garante que os mapas interativos renderizam com os raios corretos (0m para oferta, variável para pesquisa) e respondem a eventos `onTap` para definir `LatLng`.
* **Proteção de Submissão:** Confirma o bloqueio visual do botão "Publicar Viagem" (fica cinzento/desativado) se a lotação for zero ou a hora for inválida.

### US5 — Autenticação Universitária (Sigarra)
* **Prevenção de Bypass:** Valida que a aplicação intercepta qualquer tentativa de navegação para a *HomeShell* se o token da sessão local estiver nulo, redirecionando o utilizador para a `UniversityLoginPage` e mostrando a notificação: *"Inicie sessão no perfil"*.

---

## 5. Estado do Pipeline de CI/CD (GitHub Actions)

O repositório está configurado com um *workflow* automatizado no **GitHub Actions** que executa três validações críticas a cada *Pull Request*:
1. **Verificação estática de código:** Garante que o código não tem problemas de sintaxe ou formatação (`flutter analyze`).
2. **Execução da Suite Flutter:** Corre os **1129 testes** distribuídos pelas pastas `unit`, `widget`, `api` e `integration`.
3. **Execução da Suite Python:** Corre os testes unitários e de integração de base de dados e endpoints do Backend.

### ⚠️ Nota de Execução do Pipeline (Esgotamento de Minutos)

> **Importante:** Devido ao limite estrito de **2000 minutos mensais** disponibilizados gratuitamente pelo plano do GitHub para repositórios privados, os *runners* automáticos da nossa organização atingiram o teto de consumo. Por este motivo, as ações automatizadas (*workflows/actions*) encontram-se temporariamente suspensas pelo GitHub, impossibilitando o disparo automático no servidor.
>
> De forma a **comprovar a total integridade, conformidade e inocência do código** desenvolvido em relação a falhas, a suite foi corrida localmente num ambiente idêntico ao do *runner*. Abaixo encontram-se as evidências fotográficas que provam que **100% dos 1129 testes estão operacionais e a passar com sucesso**.

##### Verificação estática de código:
<img width="697" height="284" alt="Captura de ecrã 2026-05-27, às 04 04 55" src="https://github.com/user-attachments/assets/88a44652-666f-41d5-a871-364a2f79cbe5" />


##### Teste Flutter(1129/1129 Passados)
<img width="282" height="753" alt="Captura de ecrã 2026-05-27, às 03 36 43" src="https://github.com/user-attachments/assets/6122b65c-03e5-47e6-befa-0c1fb391c8cc" />


##### Testes Pytohn
<img width="568" height="134" alt="Captura de ecrã 2026-05-27, às 03 52 17" src="https://github.com/user-attachments/assets/5276ba9d-6b9c-448e-952b-b69cd9743f38" />
<img width="568" height="134" alt="Captura de ecrã 2026-05-27, às 03 48 57" src="https://github.com/user-attachments/assets/23fb695e-6daa-4992-bd0a-c70a93f68b6a" />
<img width="568" height="134" alt="Captura de ecrã 2026-05-27, às 03 39 56" src="https://github.com/user-attachments/assets/4e094619-1c1e-40ad-963e-e15bfc5901c1" />

<!-- Inserir aqui: image_f79668.jpg / Captura de ecrã 2026-05-27, às 04.03.37.jpg -->
