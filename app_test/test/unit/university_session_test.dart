// =============================================================================
// UNIT TESTS — UniversitySessionStore (Com Injeção de Dependências)
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app_test/session/university_session_store.dart';
import 'package:app_test/sigarra/sigarra_auth_service.dart';
import 'package:app_test/ride4free_api.dart';

// 1. Criamos a "API Falsa" (não precisamos do MockAuthResponse porque a API devolve um Record nativo do Dart)
class MockRide4FreeApi extends Mock implements Ride4FreeApi {}

void main() {
  group('Unit Tests - UniversitySessionStore', () {
    late UniversitySessionStore sessionStore;
    late MockRide4FreeApi mockApi;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      Ride4FreeAuth.token = null;
      
      // Instanciamos a API falsa
      mockApi = MockRide4FreeApi();
      
      // INJEÇÃO DE DEPENDÊNCIA: Passamos a API falsa para a store
      sessionStore = UniversitySessionStore(api: mockApi);
      
      // Registamos fallbacks para o mocktail perceber os tipos nomeados opcionais
      registerFallbackValue('');
    });

    test('SESS-U1: markLoggedIn regista o utilizador com sucesso na API Falsa', () async {
      // Arranjo: Preparamos a Identidade do Sigarra
      final mockIdentity = UniversityIdentity(
        username: 'up123456789',
        displayName: 'Engenheiro Teste',
      );

      // Arranjo: Preparamos o Utilizador Falso que a API vai devolver
      final utilizadorFalso = Ride4FreeUser(
        id: 1,
        email: 'up123456789@fe.up.pt',
        name: 'Engenheiro Teste',
      );

      // Arranjo: Dizemos à API falsa para devolver um Record de Sucesso no Registo
      when(() => mockApi.register(
            email: any(named: 'email'),
            password: any(named: 'password'),
            name: any(named: 'name'),
          )).thenAnswer((_) async => (user: utilizadorFalso, token: 'token_falso_gerado'));

      // Ação: Corremos a função 
      await sessionStore.markLoggedIn(mockIdentity);

      // Asserção 1: O Token Global da App foi atualizado?
      expect(Ride4FreeAuth.token, 'token_falso_gerado');

      // Asserção 2: Os dados foram guardados no telemóvel?
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('university_logged_in'), isTrue);
      expect(prefs.getString('university_username'), 'up123456789');
    });

    test('SESS-U2: markLoggedIn faz fallback para .login() se o .register() falhar', () async {
      final mockIdentity = UniversityIdentity(
        username: 'up987654321',
        displayName: 'Veterano',
      );

      final utilizadorFalso = Ride4FreeUser(
        id: 2,
        email: 'up987654321@fe.up.pt',
        name: 'Veterano',
      );

      // 1. Forçamos o .register() a dar Erro (simulando que o utilizador já está na BD)
      when(() => mockApi.register(
            email: any(named: 'email'),
            password: any(named: 'password'),
            name: any(named: 'name'),
          )).thenThrow(Exception('User already exists'));

      // 2. Preparamos a resposta de sucesso para o .login() (O Record correto)
      when(() => mockApi.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => (user: utilizadorFalso, token: 'token_de_login_falso'));

      // Ação
      await sessionStore.markLoggedIn(mockIdentity);

      // Asserção: O token guardado tem de ser o do login!
      expect(Ride4FreeAuth.token, 'token_de_login_falso');
    });
    test('SESS-U3: clear() apaga todos os dados locais e limpa o token global', () async {
      // 1. ARRANJO: Simulamos que o utilizador tem sessão iniciada
      SharedPreferences.setMockInitialValues({
        'university_logged_in': true,
        'university_username': 'up123456789',
        'university_display_name': 'André Rocha',
        'university_photo_url': 'https://foto.pt/perfil.jpg',
      });
      // Fingimos que o token da API também está ativo
      Ride4FreeAuth.token = 'token_super_secreto_ativo';

      // 2. AÇÃO: O utilizador clica em "Terminar Sessão"
      await sessionStore.clear();

      // 3. ASSERÇÃO: Verificamos se a memória do telemóvel ficou limpa
      final prefs = await SharedPreferences.getInstance();
      
      expect(prefs.getBool('university_logged_in'), isNull, 
          reason: 'A chave do login devia ter sido apagada');
      expect(prefs.getString('university_username'), isNull);
      expect(prefs.getString('university_display_name'), isNull);
      expect(prefs.getString('university_photo_url'), isNull);

      // 4. ASSERÇÃO: Verificamos se o token de segurança da API foi destruído
      expect(Ride4FreeAuth.token, isNull, 
          reason: 'O token global devia ser nulo para proteger a conta após o logout');
    });
  });
  
}