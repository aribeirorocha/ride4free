# 🧪 Arquitetura de Testes — Ride4Free
 
## Visão Geral
 
Este documento detalha a arquitetura de testes do projeto **Ride4Free**. A nossa suite de testes foi desenhada para garantir a máxima qualidade de código, o estrito cumprimento das regras de negócio e uma experiência de utilizador sem falhas.
 
O projeto conta com mais de **270 testes automatizados**, abrangendo as camadas de Backend (Python/FastAPI) e Frontend (Dart/Flutter), divididos em:
 
- ✅ Testes Unitários
- 🔗 Testes de Integração
- 📋 Testes de Aceitação (ATDD)
---
 
## 1. Guia de Execução Rápida
 
### 1.1. Backend (Python)
 
Os testes de backend utilizam uma base de dados SQLite temporária e isolada para cada sessão de testes, garantindo a ausência de contaminação de dados (**State Isolation**).
 
```bash
cd backend
 
# 1. Instalar dependências de teste
pip install -r requirements.txt
 
# 2. Executar toda a suite de testes do backend
pytest -v
 
# 3. Executar com relatório de cobertura de código (Coverage)
pytest --cov=database --cov=main --cov-report=term-missing
```
 
### 1.2. Frontend (Dart/Flutter)
 
O frontend utiliza a framework nativa de testes do Flutter, operando sob o paradigma de **Mock Widgets** para validar a UI de forma rápida e sem dependência de rede.
 
```bash
cd app_test
 
# 1. Atualizar pacotes
flutter pub get
 
# 2. Executar toda a suite de testes do frontend
flutter test
 
# 3. Executar ficheiros específicos (Exemplo: Testes de Integração)
flutter test test/integration_test.dart
 
# 4. Verificar cobertura de código
flutter test --coverage
```
 
---
 
## 2. Testes de Backend (Python/FastAPI)
 
> **Total de Testes do Backend: ~200+**
 
### 2.1. Camada de Base de Dados (`test_database.py` — 142 testes)
 
Estes testes focam-se exclusivamente nas funções diretas de manipulação de dados, garantindo a integridade referencial e lógica das transações SQL.
 
| Área | Descrição |
|------|-----------|
| **Hash e Verificação de Passwords** | Valida a criação de hashes com salt único e a proteção contra hashes malformadas ou tentativas de login inválidas. |
| **Normalização de Destinos** | Assegura que todas as pesquisas de destino ignoram maiúsculas/minúsculas e espaços em excesso (ex: `" FEUP "` é lido como `"feup"`), otimizando o algoritmo de matching. |
| **Gestão de Utilizadores e Sessões** | Testa a criação de contas, a normalização de emails, a prevenção rigorosa de contas duplicadas e o ciclo de vida completo dos Bearer Tokens (geração, validação e invalidação no logout). |
| **Ofertas e Pedidos de Boleia** | Valida a inserção na base de dados, a filtragem correta por destino e a alteração automática de estado (de `Open` para `Full` quando a lotação esgota). |
| **Sistema de Reservas (Bookings)** | Testa os constrangimentos vitais do sistema: bloqueia duplas reservas para o mesmo lugar, impede um utilizador de reservar a sua própria boleia e garante o registo correto do match. |
| **Listagem da Comunidade** | Garante a leitura integral dos quadros da comunidade (condutores e passageiros), incluindo informação cruzada de reservas. |
 
### 2.2. Camada de Endpoints API (`test_main.py` — 60+ testes)
 
Testes de integração focados no routing do FastAPI, simulando pedidos HTTP reais.
 
| Área | Descrição |
|------|-----------|
| **Fluxo de Autenticação** | Valida os endpoints `/users/register`, `/users/login` e `/users/logout`. Verifica códigos HTTP de resposta (`200 OK`, `400 Bad Request`, `401 Unauthorized`), validação de payloads e rejeição de tokens expirados. |
| **Endpoints de Entidades** | Testa a exposição dos endpoints REST para criação de ofertas/pedidos, assegurando que os cabeçalhos de Autorização (Bearer Token) são obrigatoriamente validados pelo middleware. |
| **Endpoints de Reservas** | Simula chamadas HTTP `POST` para efetuar reservas, garantindo a comunicação fluida e a entrega de respostas de sucesso ou erro (ex: `403 Forbidden`). |
 
---
 
## 3. Testes de Frontend (Dart/Flutter)
 
> **Total de Testes do Frontend: ~70+**
 
### 3.1. Cliente API e Componentes UI (`api_client_test.dart` & `widget_tests.dart` — 70+ testes)
 
| Área | Descrição |
|------|-----------|
| **Configuração do Cliente API** | Valida a construção de URLs base, a injeção correta de cabeçalhos HTTP (ex: `Content-Type: application/json` e tokens), e a desserialização robusta do modelo `User` a partir de respostas JSON. Testa também a captura de erros via `Ride4FreeApiException`. |
| **Renderização de Widgets** | Confirma a presença e o estado inicial (texto padrão, visibilidade de botões, barras de pesquisa) nos ecrãs fundamentais: `SearchRidePage`, `ProfilePage`, `OfferRidePage` e `CommunityBoardPage`. |
 
### 3.2. Testes Unitários de Lógica de Negócio (`unit_test.dart` & `home_shell_unit_test.dart`)
 
Estes testes isolam a matemática e o estado local sem necessitar de renderizar ecrãs complexos.
 
| Grupo | Descrição |
|-------|-----------|
| **Modelo Profile (PM-U)** | Valida a inicialização de valores por defeito, a mutabilidade do número de estrelas, e a atribuição de IDs únicos para a lista da comunidade. |
| **Cálculo de Recompensas (RW-U)** | Assegura que o algoritmo de recompensas (`lugares * 10`) produz as strings corretas (ex: `"+20 Creditos"`) e reage a reduções de lotação. |
| **Validação de Lotação (SP-U)** | Testa a lógica do `SeatPicker`, garantindo a proteção matemática contra números negativos e o bloqueio estrito de viagens com 0 lugares (evitando submissões fantasma). |
| **Iniciais do Avatar (IN-U)** | Valida expressões regulares utilizadas para extrair iniciais de nomes compostos e complexos para a UI (ex: `"Alex Rivera"` → `"AR"`). |
| **Filtros Locais (FL-U)** | Garante que o painel de "Perfis Avaliados" filtra corretamente arrays de objetos, excluindo utilizadores com 0 estrelas. |
 
### 3.3. Testes de Integração End-to-End (`integration_test.dart`)
 
Garante que múltiplos componentes visuais partilham o mesmo estado corretamente e interagem sem overflows.
 
| Grupo | Descrição |
|-------|-----------|
| **Navegação (NAV-IT)** | Confirma que a `BottomNavigationBar` alterna fluidamente as tabs no `IndexedStack` sem perder o estado de cada ecrã (ex: texto já introduzido). |
| **Fluxo de Oferta (OF-IT)** | Valida o dinamismo do botão "Publicar Viagem" face à interação com o contador de lugares, e a aparição de Snackbars de erro quando faltam permissões de rede/autenticação. |
| **Fluxo de Avaliação (RT-IT)** | Testa exaustivamente o ciclo de vida do `BottomSheet` de rating: scroll em listas renderizadas, persistência de dados após clique em botões e injeção do resultado no Summary Card do ecrã parente. |
 
---
 
## 4. Testes de Aceitação / User Stories (ATDD)
 
Esta camada de testes mapeia diretamente o código final com os critérios de aceitação do Figma e os requisitos do Product Backlog.
 
### US1 — Oferecer Boleia (`us1_publish_ride_acceptance_test.dart`)
 
| Teste | Descrição |
|-------|-----------|
| **PR-1 a PR-3** | Garante que o condutor recebe feedback justo e em tempo real sobre a recompensa de créditos, valida a entrada de texto livre para destinos e confirma o bloqueio visual do formulário se a lotação for zero. |
 
### US2 & US4 — Pesquisar e Reservar Boleia (`us2_...` & `us4_...`)
 
| Teste | Descrição |
|-------|-----------|
| **SB-1 / SS-1** | Confirma a usabilidade do Slider de "Raio de Tolerância" e a renderização correta das listas de condutores disponíveis. |
| **SS-2** | Valida o caso de teste crítico de falha: exige o aparecimento de um **Empty State** visual (ícone de aviso + texto em vermelho) informando de forma empática quando não existem matches no raio indicado. |
 
### US3 — Sistema de Avaliação Comunitária (`us3_rating_system_acceptance_test.dart`)
 
| Grupo | Testes | Descrição |
|-------|--------|-----------|
| **Gestão de Perfis** | PM-1 a PM-4 | Testa a inserção manual de utilizadores a avaliar e rejeita inputs vazios ou com espaços. |
| **Avaliação Visual** | SR-1 a SR-4 | Confirma a transição do estado do ícone das estrelas (de `outline` para `filled`) em resposta direta ao toque do utilizador. |
| **Fluxo de Decisão** | SC-1 a SC-4 | Garante que o cancelamento de uma ação não gera dados residuais e que o erro "Zero Estrelas" é tratado sem quebras de aplicação. |
 
---
 
## 5. Integração Contínua (CI/CD)
 
O repositório está desenhado para suportar fluxos de trabalho DevOps em plataformas como **GitHub Actions** ou **GitLab CI**. A execução automática previne regressões a cada novo Commit ou Pull Request.
 
**Exemplo de Workflow (GitHub Actions):**
 
```yaml
jobs:
  test_backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Python
        uses: actions/setup-python@v4
      - run: cd backend && pip install -r requirements.txt && pytest -v
 
  test_frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
      - run: cd app_test && flutter pub get && flutter test
```
 
---
 
## 6. Resolução de Problemas Comuns
 
### ❌ Falhas nos Testes de Backend
 
| Problema | Solução |
|----------|---------|
| **Erro de Dependências** | Garanta que está a utilizar Python 3.8+ e que as dependências mais recentes de teste estão instaladas: `pip install -r requirements.txt` |
| **Conflito de Base de Dados** | Em caso de interrupção abrupta, garanta a limpeza da base de dados local: `rm -f ride4free.db*` (apesar de a maioria dos testes utilizar uma BD na memória para isolamento). |
 
### ❌ Falhas nos Testes de Frontend
 
| Problema | Solução |
|----------|---------|
| **Ficheiros Fantasma no Explorador (Mac/Git)** | Devido à case-insensitivity nativa do macOS, renomear ficheiros pode quebrar o Test Explorer. Solução: `flutter clean && flutter pub get` via terminal, seguido de um reinício do Editor. |
| **RenderFlex Overflow** | Testes virtuais usam tamanhos de ecrã restritos. Caso um ecrã com Mapa ou `ListView` falhe durante um teste, garanta que os componentes que preenchem muito ecrã estão devidamente envolvidos em widgets `Expanded` ou `SingleChildScrollView`. |